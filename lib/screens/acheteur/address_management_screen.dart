// ===== lib/screens/acheteur/address_management_screen.dart =====
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../providers/auth_provider_firebase.dart';
import '../../services/firebase_service.dart';
import '../../config/constants.dart';

class AddressManagementScreen extends StatefulWidget {
  const AddressManagementScreen({super.key});

  @override
  State<AddressManagementScreen> createState() => _AddressManagementScreenState();
}

class _AddressManagementScreenState extends State<AddressManagementScreen> {
  List<Address> _addresses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;

      if (user != null && user.profile['addresses'] != null) {
        final addressesList = user.profile['addresses'] as List<dynamic>;
        setState(() {
          _addresses = addressesList
              .map((addr) => Address.fromMap(addr as Map<String, dynamic>))
              .toList();
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

      debugPrint('✅ Adresses sauvegardées: ${_addresses.length}');
    } catch (e) {
      debugPrint('❌ Erreur sauvegarde adresses: $e');
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
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
    return Scaffold(
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

class _AddressFormSheetState extends State<AddressFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _streetController = TextEditingController();
  final _communeController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();

  LocationCoords? _coordinates;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();

    if (widget.address != null) {
      _labelController.text = widget.address!.label;
      _streetController.text = widget.address!.street;
      _communeController.text = widget.address!.commune;
      _cityController.text = widget.address!.city;
      _postalCodeController.text = widget.address!.postalCode ?? '';
      _coordinates = widget.address!.coordinates;
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _streetController.dispose();
    _communeController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      Position position = await Geolocator.getCurrentPosition();

      setState(() {
        _coordinates = LocationCoords(
          latitude: position.latitude,
          longitude: position.longitude,
        );
      });

      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(position.latitude, position.longitude),
          ),
        );
      }
    } catch (e) {
      debugPrint('Erreur géolocalisation: $e');
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

          // Formulaire
          Expanded(
            child: SingleChildScrollView(
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

                    // Carte
                    const Text(
                      'Position GPS (optionnel)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _coordinates != null
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
                                  });
                                },
                              )
                            : const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.map, size: 40, color: AppColors.textSecondary),
                                    SizedBox(height: 8),
                                    Text('Aucune position sélectionnée'),
                                  ],
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton.icon(
                        onPressed: _getCurrentLocation,
                        icon: const Icon(Icons.my_location),
                        label: const Text('Utiliser ma position actuelle'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bouton Sauvegarder
          Container(
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
        ],
      ),
    );
  }
}