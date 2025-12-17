// ===== lib/screens/acheteur/address_management_screen.dart =====
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../providers/auth_provider_firebase.dart';
import '../../services/firebase_service.dart';
import 'package:social_business_pro/config/constants.dart';
import 'package:social_business_pro/widgets/system_ui_scaffold.dart';

class AddressManagementScreen extends StatefulWidget {
  const AddressManagementScreen({super.key});

  @override
  State<AddressManagementScreen> createState() => _AddressManagementScreenState();
}

class _AddressManagementScreenState extends State<AddressManagementScreen> {
  List<Address> _addresses = [];
  bool _isLoading = true;
  Timer? _refreshTimer;
  final _refreshInterval = const Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    _loadAddresses();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(_refreshInterval, (timer) {
      if (mounted) {
        debugPrint('🔄 Auto-refresh addresses');
        _loadAddresses();
      }
    });
  }

  Future<void> _loadAddresses() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;

      if (user != null && user.profile['addresses'] != null) {
        final addressesList = user.profile['addresses'] as List<dynamic>;
        setState(() {
          _addresses =
              addressesList.map((addr) => Address.fromMap(addr as Map<String, dynamic>)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _addresses = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement adresses: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addOrEditAddress({Address? existingAddress}) async {
    final result = await showModalBottomSheet<Address>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddressFormSheet(address: existingAddress),
    );

    if (result != null) {
      setState(() {
        if (existingAddress != null) {
          // Modifier l'adresse existante
          final index = _addresses.indexWhere((a) => a.id == existingAddress.id);
          if (index != -1) {
            _addresses[index] = result;
          }
        } else {
          // Ajouter nouvelle adresse
          _addresses.add(result);
        }
      });

      _saveAddresses();
    }
  }

  Future<void> _deleteAddress(Address address) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'adresse'),
        content: Text('Voulez-vous vraiment supprimer "${address.label}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _addresses.removeWhere((a) => a.id == address.id);
      });
      _saveAddresses();
    }
  }

  Future<void> _setDefaultAddress(Address address) async {
    setState(() {
      // Retirer le défaut de toutes les adresses
      _addresses = _addresses.map((a) {
        return Address(
          id: a.id,
          label: a.label,
          street: a.street,
          commune: a.commune,
          city: a.city,
          postalCode: a.postalCode,
          coordinates: a.coordinates,
          isDefault: a.id == address.id,
        );
      }).toList();
    });

    _saveAddresses();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adresse par défaut mise à jour')),
      );
    }
  }

  Future<void> _saveAddresses() async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id;

      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      final addressesList = _addresses.map((a) => a.toMap()).toList();

      // Sauvegarder dans Firestore
      await FirebaseService.updateDocument(
        collection: FirebaseCollections.users,
        docId: userId,
        data: {
          'profile.addresses': addressesList,
        },
      );

      // Recharger l'utilisateur dans le provider pour synchroniser
      await authProvider.loadUserFromFirebase();

      debugPrint('✅ Adresses sauvegardées: ${_addresses.length}');

      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('✅ Adresse enregistrée avec succès'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Erreur sauvegarde adresses: $e');
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildAddressCard(Address address) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          address.isDefault ? Icons.location_on : Icons.location_on_outlined,
          color: address.isDefault ? AppColors.primary : AppColors.textSecondary,
          size: 30,
        ),
        title: Row(
          children: [
            Text(
              address.label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (address.isDefault) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Par défaut',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(address.street),
            Text('${address.commune}, ${address.city}'),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Modifier'),
                ],
              ),
            ),
            if (!address.isDefault)
              const PopupMenuItem(
                value: 'default',
                child: Row(
                  children: [
                    Icon(Icons.check_circle),
                    SizedBox(width: 8),
                    Text('Définir par défaut'),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Supprimer', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _addOrEditAddress(existingAddress: address);
                break;
              case 'default':
                _setDefaultAddress(address);
                break;
              case 'delete':
                _deleteAddress(address);
                break;
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SystemUIScaffold(
      appBar: AppBar(
        title: const Text('Mes adresses'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _addresses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_off,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune adresse enregistrée',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _addOrEditAddress(),
                        icon: const Icon(Icons.add),
                        label: const Text('Ajouter une adresse'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      '${_addresses.length} adresse${_addresses.length > 1 ? "s" : ""}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._addresses.map(_buildAddressCard),
                  ],
                ),
      floatingActionButton: _addresses.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _addOrEditAddress(),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter'),
              backgroundColor: AppColors.primary,
            )
          : null,
    );
  }
}

// ===== FORMULAIRE D'ADRESSE =====
class AddressFormSheet extends StatefulWidget {
  final Address? address;

  const AddressFormSheet({super.key, this.address});

  @override
  State<AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<AddressFormSheet> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _streetController = TextEditingController();
  final _communeController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _searchController = TextEditingController();

  LocationCoords? _coordinates;
  GoogleMapController? _mapController;
  late TabController _tabController;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    if (widget.address != null) {
      _labelController.text = widget.address!.label;
      _streetController.text = widget.address!.street;
      _communeController.text = widget.address!.commune;
      _cityController.text = widget.address!.city;
      _postalCodeController.text = widget.address!.postalCode ?? '';
      _coordinates = widget.address!.coordinates;

      if (_coordinates != null) {
        _latController.text = _coordinates!.latitude.toStringAsFixed(6);
        _lngController.text = _coordinates!.longitude.toStringAsFixed(6);
      }
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _streetController.dispose();
    _communeController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _searchController.dispose();
    _tabController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      // Vérifier si les permissions sont toujours refusées
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Permission de localisation refusée. Veuillez l\'activer dans les paramètres de l\'application.',
            ),
            duration: Duration(seconds: 4),
          ),
        );
        debugPrint('⚠️ Permission géolocalisation refusée par l\'utilisateur');
        return;
      }

      Position position = await Geolocator.getCurrentPosition();

      setState(() {
        _coordinates = LocationCoords(
          latitude: position.latitude,
          longitude: position.longitude,
        );
        _latController.text = position.latitude.toStringAsFixed(6);
        _lngController.text = position.longitude.toStringAsFixed(6);
      });

      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(position.latitude, position.longitude),
          ),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Position actuelle récupérée'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint('Erreur géolocalisation: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la récupération de la position: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _updateCoordinatesFromManualInput() {
    final lat = double.tryParse(_latController.text);
    final lng = double.tryParse(_lngController.text);

    if (lat != null && lng != null && lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180) {
      setState(() {
        _coordinates = LocationCoords(latitude: lat, longitude: lng);
      });

      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(LatLng(lat, lng)),
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Coordonnées mises à jour'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Coordonnées invalides'),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _searchAddress() async {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Veuillez saisir une adresse'),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _isSearching = true);

    try {
      // Recherche avec geocoding - on ajoute "Abidjan, Côte d'Ivoire" si pas présent
      final searchQuery =
          query.toLowerCase().contains('abidjan') ? query : '$query, Abidjan, Côte d\'Ivoire';

      final locations = await locationFromAddress(searchQuery);

      if (locations.isNotEmpty) {
        final location = locations.first;

        setState(() {
          _coordinates = LocationCoords(
            latitude: location.latitude,
            longitude: location.longitude,
          );
          _latController.text = location.latitude.toStringAsFixed(6);
          _lngController.text = location.longitude.toStringAsFixed(6);
          _isSearching = false;
        });

        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(location.latitude, location.longitude),
              16, // Zoom level
            ),
          );
        }

        // Récupérer les détails de l'adresse
        try {
          final placemarks = await placemarkFromCoordinates(
            location.latitude,
            location.longitude,
          );

          if (placemarks.isNotEmpty) {
            final placemark = placemarks.first;

            // Remplir automatiquement les champs d'adresse
            if (_streetController.text.isEmpty && placemark.street != null) {
              _streetController.text = placemark.street!;
            }
            if (_communeController.text.isEmpty && placemark.subLocality != null) {
              _communeController.text = placemark.subLocality!;
            }
            if (_cityController.text.isEmpty && placemark.locality != null) {
              _cityController.text = placemark.locality!;
            }
            if (_postalCodeController.text.isEmpty && placemark.postalCode != null) {
              _postalCodeController.text = placemark.postalCode!;
            }
          }
        } catch (e) {
          debugPrint('⚠️ Erreur récupération détails adresse: $e');
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Adresse trouvée'),
              duration: Duration(seconds: 2),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        setState(() => _isSearching = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Adresse introuvable. Essayez avec plus de détails.'),
              backgroundColor: AppColors.error,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isSearching = false);
      debugPrint('❌ Erreur recherche adresse: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur lors de la recherche: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _saveAddress() {
    if (_formKey.currentState!.validate()) {
      final address = Address(
        id: widget.address?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        label: _labelController.text,
        street: _streetController.text,
        commune: _communeController.text,
        city: _cityController.text,
        postalCode: _postalCodeController.text.isEmpty ? null : _postalCodeController.text,
        coordinates: _coordinates,
        isDefault: widget.address?.isDefault ?? false,
      );

      Navigator.pop(context, address);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // En-tête
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.address == null ? 'Nouvelle adresse' : 'Modifier l\'adresse',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Onglets
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(icon: Icon(Icons.edit_location), text: 'Adresse'),
              Tab(icon: Icon(Icons.map), text: 'Carte'),
              Tab(icon: Icon(Icons.gps_fixed), text: 'GPS'),
            ],
          ),

          // Contenu des onglets
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAddressTab(),
                _buildMapTab(),
                _buildGPSTab(),
              ],
            ),
          ),

          // Bouton Sauvegarder avec safe area pour éviter les boutons système
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveAddress,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text('Sauvegarder l\'adresse'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== ONGLET 1: ADRESSE =====
  Widget _buildAddressTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _labelController,
              decoration: const InputDecoration(
                labelText: 'Libellé *',
                hintText: 'Ex: Domicile, Bureau, etc.',
                prefixIcon: Icon(Icons.label),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez saisir un libellé';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _streetController,
              decoration: const InputDecoration(
                labelText: 'Rue / Quartier *',
                hintText: 'Ex: Cocody Riviera, Lot 123',
                prefixIcon: Icon(Icons.home),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez saisir l\'adresse';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _communeController,
              decoration: const InputDecoration(
                labelText: 'Commune *',
                hintText: 'Ex: Cocody, Yopougon, etc.',
                prefixIcon: Icon(Icons.location_city),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez saisir la commune';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: 'Ville *',
                hintText: 'Ex: Abidjan',
                prefixIcon: Icon(Icons.location_on),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez saisir la ville';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _postalCodeController,
              decoration: const InputDecoration(
                labelText: 'Code postal (optionnel)',
                prefixIcon: Icon(Icons.pin),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),

            // Résumé position GPS
            if (_coordinates != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.success),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Position GPS enregistrée',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Lat: ${_coordinates!.latitude.toStringAsFixed(6)}, Lng: ${_coordinates!.longitude.toStringAsFixed(6)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Utilisez l\'onglet "Carte" ou "GPS" pour définir la position',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Récupérer l'adresse depuis les coordonnées
  Future<void> _getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _streetController.text = '${place.street ?? ''} ${place.subLocality ?? ''}'.trim();
          _communeController.text = place.locality ?? '';
          _cityController.text = place.administrativeArea ?? 'Abidjan';
          _postalCodeController.text = place.postalCode ?? '';
        });
      }
    } catch (e) {
      debugPrint('Erreur geocoding: $e');
    }
  }

  // Ouvrir la carte en plein écran
  Future<LocationCoords?> _openFullScreenMap() async {
    return await Navigator.push<LocationCoords>(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenMapPicker(
          initialCoordinates: _coordinates,
          onLocationSelected: (coords) {
            setState(() {
              _coordinates = coords;
              _latController.text = coords.latitude.toStringAsFixed(6);
              _lngController.text = coords.longitude.toStringAsFixed(6);
            });
            _getAddressFromCoordinates(coords.latitude, coords.longitude);
          },
        ),
      ),
    );
  }

  // ===== ONGLET 2: CARTE INTERACTIVE =====
  Widget _buildMapTab() {
    return Stack(
      children: [
        // Carte Google Maps
        _coordinates != null
            ? GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    _coordinates!.latitude,
                    _coordinates!.longitude,
                  ),
                  zoom: 15,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId('address'),
                    position: LatLng(
                      _coordinates!.latitude,
                      _coordinates!.longitude,
                    ),
                    draggable: true,
                    infoWindow: const InfoWindow(
                      title: 'Votre adresse',
                      snippet: 'Glissez pour déplacer',
                    ),
                    onDragEnd: (newPosition) {
                      setState(() {
                        _coordinates = LocationCoords(
                          latitude: newPosition.latitude,
                          longitude: newPosition.longitude,
                        );
                        _latController.text = newPosition.latitude.toStringAsFixed(6);
                        _lngController.text = newPosition.longitude.toStringAsFixed(6);
                      });
                      _getAddressFromCoordinates(newPosition.latitude, newPosition.longitude);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('📍 Position mise à jour'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                },
                onMapCreated: (controller) {
                  _mapController = controller;
                },
                onTap: (position) {
                  setState(() {
                    _coordinates = LocationCoords(
                      latitude: position.latitude,
                      longitude: position.longitude,
                    );
                    _latController.text = position.latitude.toStringAsFixed(6);
                    _lngController.text = position.longitude.toStringAsFixed(6);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('📍 Position sélectionnée'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: true,
                rotateGesturesEnabled: true,
                scrollGesturesEnabled: true,
                tiltGesturesEnabled: true,
                zoomGesturesEnabled: true,
              )
            : Container(
                color: Colors.grey[200],
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.map_outlined, size: 80, color: AppColors.textSecondary),
                      const SizedBox(height: 16),
                      const Text(
                        'Aucune position sélectionnée',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Recherchez une adresse ou utilisez votre position',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _getCurrentLocation,
                        icon: const Icon(Icons.my_location),
                        label: const Text('Ma position actuelle'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

        // Barre de recherche compacte
        Positioned(
          top: 8,
          left: 16,
          right: 80, // Laisser de la place pour le bouton fullscreen
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  // Champ de recherche compact
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Rechercher une adresse...',
                        hintStyle: const TextStyle(fontSize: 13),
                        prefixIcon: const Icon(Icons.search, color: AppColors.primary, size: 20),
                        suffixIcon: _isSearching
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: Padding(
                                  padding: EdgeInsets.all(10),
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : (_searchController.text.isNotEmpty
                                ? IconButton(
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {});
                                    },
                                  )
                                : null),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _searchAddress(),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),

                  // Bouton rechercher compact
                  IconButton(
                    onPressed: _isSearching ? null : _searchAddress,
                    icon: const Icon(Icons.send, size: 20),
                    color: AppColors.primary,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Boutons de contrôle de la carte
        if (_coordinates != null) ...[
          // Bouton plein écran - positionné en haut à droite
          Positioned(
            top: 16,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'fullscreen_map',
              onPressed: _openFullScreenMap,
              backgroundColor: AppColors.primary,
              elevation: 6,
              child: const Icon(Icons.fullscreen, color: Colors.white, size: 28),
            ),
          ),

          // Bouton position actuelle
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'current_location',
              onPressed: _getCurrentLocation,
              backgroundColor: Colors.white,
              elevation: 4,
              child: const Icon(Icons.my_location, color: AppColors.primary),
            ),
          ),

          // Bouton zoom +
          Positioned(
            bottom: 80,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: 'zoom_in',
              onPressed: () {
                _mapController?.animateCamera(CameraUpdate.zoomIn());
              },
              backgroundColor: Colors.white,
              elevation: 4,
              child: const Icon(Icons.add, color: AppColors.primary),
            ),
          ),

          // Bouton zoom -
          Positioned(
            bottom: 130,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: 'zoom_out',
              onPressed: () {
                _mapController?.animateCamera(CameraUpdate.zoomOut());
              },
              backgroundColor: Colors.white,
              elevation: 4,
              child: const Icon(Icons.remove, color: AppColors.primary),
            ),
          ),
        ],
      ],
    );
  }

  // ===== ONGLET 3: SAISIE GPS MANUELLE =====
  Widget _buildGPSTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Saisie manuelle des coordonnées GPS',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Entrez les coordonnées latitude et longitude au format décimal',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),

          // Latitude
          TextFormField(
            controller: _latController,
            decoration: const InputDecoration(
              labelText: 'Latitude *',
              hintText: 'Ex: 5.345317',
              prefixIcon: Icon(Icons.north),
              helperText: 'Valeur entre -90 et 90',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
          ),
          const SizedBox(height: 16),

          // Longitude
          TextFormField(
            controller: _lngController,
            decoration: const InputDecoration(
              labelText: 'Longitude *',
              hintText: 'Ex: -4.024429',
              prefixIcon: Icon(Icons.east),
              helperText: 'Valeur entre -180 et 180',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
          ),
          const SizedBox(height: 24),

          // Bouton valider
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _updateCoordinatesFromManualInput,
              icon: const Icon(Icons.check),
              label: const Text('Valider les coordonnées'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Bouton position actuelle
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _getCurrentLocation,
              icon: const Icon(Icons.my_location),
              label: const Text('Utiliser ma position actuelle'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Informations et exemples
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'Exemples de coordonnées à Abidjan',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildLocationExample('Plateau', '5.319447', '-4.012869'),
                const SizedBox(height: 8),
                _buildLocationExample('Cocody', '5.347850', '-3.987284'),
                const SizedBox(height: 8),
                _buildLocationExample('Yopougon', '5.335950', '-4.086730'),
                const SizedBox(height: 8),
                _buildLocationExample('Marcory', '5.294183', '-3.994370'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Guide d'utilisation
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.help_outline, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Comment obtenir mes coordonnées ?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildHelpItem('1', 'Ouvrez Google Maps sur votre téléphone'),
                _buildHelpItem('2', 'Appuyez longuement sur votre position'),
                _buildHelpItem('3', 'Les coordonnées s\'affichent en haut'),
                _buildHelpItem('4', 'Copiez et collez ici'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationExample(String name, String lat, String lng) {
    return InkWell(
      onTap: () {
        setState(() {
          _latController.text = lat;
          _lngController.text = lng;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📍 Coordonnées de $name copiées'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            const Icon(Icons.location_on, size: 16, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$name: $lat, $lng',
                style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
              ),
            ),
            const Icon(Icons.content_copy, size: 16, color: Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ===== CARTE EN PLEIN ÉCRAN (Style Yango) =====
class FullScreenMapPicker extends StatefulWidget {
  final LocationCoords? initialCoordinates;
  final Function(LocationCoords) onLocationSelected;

  const FullScreenMapPicker({
    super.key,
    this.initialCoordinates,
    required this.onLocationSelected,
  });

  @override
  State<FullScreenMapPicker> createState() => _FullScreenMapPickerState();
}

class _FullScreenMapPickerState extends State<FullScreenMapPicker> {
  GoogleMapController? _mapController;
  LocationCoords? _selectedCoordinates;
  final _searchController = TextEditingController();
  bool _isSearching = false;
  String? _addressText;

  @override
  void initState() {
    super.initState();
    _selectedCoordinates = widget.initialCoordinates;
    if (_selectedCoordinates != null) {
      _getAddressFromCoordinates(
        _selectedCoordinates!.latitude,
        _selectedCoordinates!.longitude,
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permission de localisation refusée'),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition();

      setState(() {
        _selectedCoordinates = LocationCoords(
          latitude: position.latitude,
          longitude: position.longitude,
        );
      });

      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude),
            16,
          ),
        );
      }

      _getAddressFromCoordinates(position.latitude, position.longitude);
    } catch (e) {
      debugPrint('❌ Erreur géolocalisation: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> _getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _addressText =
              '${place.street ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? 'Abidjan'}'
                  .trim();
        });
      }
    } catch (e) {
      debugPrint('⚠️ Erreur geocoding: $e');
      setState(() {
        _addressText = 'Lat: ${latitude.toStringAsFixed(6)}, Lng: ${longitude.toStringAsFixed(6)}';
      });
    }
  }

  Future<void> _searchAddress() async {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Veuillez saisir une adresse')),
      );
      return;
    }

    setState(() => _isSearching = true);

    try {
      final searchQuery =
          query.toLowerCase().contains('abidjan') ? query : '$query, Abidjan, Côte d\'Ivoire';

      final locations = await locationFromAddress(searchQuery);

      if (locations.isNotEmpty) {
        final location = locations.first;

        setState(() {
          _selectedCoordinates = LocationCoords(
            latitude: location.latitude,
            longitude: location.longitude,
          );
          _isSearching = false;
        });

        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(location.latitude, location.longitude),
              16,
            ),
          );
        }

        _getAddressFromCoordinates(location.latitude, location.longitude);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Adresse trouvée'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        setState(() => _isSearching = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Adresse introuvable'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isSearching = false);
      debugPrint('❌ Erreur recherche: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Erreur: $e')),
        );
      }
    }
  }

  void _confirmLocation() {
    if (_selectedCoordinates != null) {
      widget.onLocationSelected(_selectedCoordinates!);
      Navigator.pop(context, _selectedCoordinates);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Veuillez sélectionner une position sur la carte'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SystemUIScaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Carte Google Maps en plein écran
          _selectedCoordinates != null
              ? GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      _selectedCoordinates!.latitude,
                      _selectedCoordinates!.longitude,
                    ),
                    zoom: 15,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId('selected_location'),
                      position: LatLng(
                        _selectedCoordinates!.latitude,
                        _selectedCoordinates!.longitude,
                      ),
                      draggable: true,
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                      infoWindow: InfoWindow(
                        title: 'Position sélectionnée',
                        snippet: _addressText ?? 'Glissez pour déplacer',
                      ),
                      onDragEnd: (newPosition) {
                        setState(() {
                          _selectedCoordinates = LocationCoords(
                            latitude: newPosition.latitude,
                            longitude: newPosition.longitude,
                          );
                        });
                        _getAddressFromCoordinates(
                          newPosition.latitude,
                          newPosition.longitude,
                        );
                      },
                    ),
                  },
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  onTap: (position) {
                    setState(() {
                      _selectedCoordinates = LocationCoords(
                        latitude: position.latitude,
                        longitude: position.longitude,
                      );
                    });
                    _getAddressFromCoordinates(
                      position.latitude,
                      position.longitude,
                    );
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  compassEnabled: true,
                  mapToolbarEnabled: false,
                )
              : Container(
                  color: Colors.grey[200],
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.map_outlined, size: 100, color: AppColors.textSecondary),
                        const SizedBox(height: 24),
                        const Text(
                          'Aucune position sélectionnée',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: _getCurrentLocation,
                          icon: const Icon(Icons.my_location),
                          label: const Text('Utiliser ma position actuelle'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

          // Barre de recherche en haut
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header avec bouton retour
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: 'Rechercher une adresse...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 8),
                            ),
                            onSubmitted: (_) => _searchAddress(),
                          ),
                        ),
                        if (_isSearching)
                          const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.search, color: AppColors.primary),
                            onPressed: _searchAddress,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Affichage de l'adresse sélectionnée
          if (_addressText != null)
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.location_on, color: AppColors.primary, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Position sélectionnée',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _addressText!,
                        style: const TextStyle(fontSize: 13),
                      ),
                      if (_selectedCoordinates != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Lat: ${_selectedCoordinates!.latitude.toStringAsFixed(6)}, Lng: ${_selectedCoordinates!.longitude.toStringAsFixed(6)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

          // Boutons de contrôle à droite
          if (_selectedCoordinates != null) ...[
            // Bouton position actuelle
            Positioned(
              bottom: 180,
              right: 16,
              child: FloatingActionButton(
                heroTag: 'fullscreen_current_location',
                onPressed: _getCurrentLocation,
                backgroundColor: Colors.white,
                elevation: 4,
                child: const Icon(Icons.my_location, color: AppColors.primary),
              ),
            ),

            // Bouton zoom +
            Positioned(
              bottom: 250,
              right: 16,
              child: FloatingActionButton.small(
                heroTag: 'fullscreen_zoom_in',
                onPressed: () {
                  _mapController?.animateCamera(CameraUpdate.zoomIn());
                },
                backgroundColor: Colors.white,
                elevation: 4,
                child: const Icon(Icons.add, color: AppColors.primary),
              ),
            ),

            // Bouton zoom -
            Positioned(
              bottom: 300,
              right: 16,
              child: FloatingActionButton.small(
                heroTag: 'fullscreen_zoom_out',
                onPressed: () {
                  _mapController?.animateCamera(CameraUpdate.zoomOut());
                },
                backgroundColor: Colors.white,
                elevation: 4,
                child: const Icon(Icons.remove, color: AppColors.primary),
              ),
            ),
          ],

          // Bouton de confirmation en bas avec SafeArea
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: _confirmLocation,
                  icon: const Icon(Icons.check),
                  label: const Text('Confirmer cette position'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
