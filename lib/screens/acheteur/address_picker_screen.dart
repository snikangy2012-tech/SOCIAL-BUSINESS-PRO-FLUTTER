// ===== lib/screens/acheteur/address_picker_screen.dart =====
// Écran de sélection d'adresse avec carte interactive - SOCIAL BUSINESS Pro

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';

import '../../config/constants.dart';
import '../../models/user_model.dart';
import '../../widgets/system_ui_scaffold.dart';

/// Écran de sélection d'adresse avec 2 options :
/// 1. Sélectionner parmi les adresses enregistrées
/// 2. Choisir une nouvelle adresse via carte interactive
class AddressPickerScreen extends StatefulWidget {
  final List<Address> savedAddresses;
  final Address? currentAddress;

  const AddressPickerScreen({
    super.key,
    required this.savedAddresses,
    this.currentAddress,
  });

  @override
  State<AddressPickerScreen> createState() => _AddressPickerScreenState();
}

class _AddressPickerScreenState extends State<AddressPickerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Carte
  GoogleMapController? _mapController;
  Position? _currentPosition;
  LatLng? _selectedLocation;
  String? _selectedAddressText;
  bool _isLoadingAddress = false;
  bool _isLoadingLocation = false;
  Set<Marker> _markers = {};

  // Adresse sélectionnée
  Address? _selectedSavedAddress;

  // Recherche
  final TextEditingController _searchController = TextEditingController();
  List<Location> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedSavedAddress = widget.currentAddress;

    debugPrint('📍 AddressPicker init with ${widget.savedAddresses.length} saved addresses');
    for (var addr in widget.savedAddresses) {
      debugPrint('  - ${addr.label}: GPS=${addr.coordinates != null}');
    }

    // Charger la position actuelle pour la carte
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _mapController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Obtenir la position actuelle
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      // Vérifier les permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('Permission de localisation refusée');
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showError('Permission de localisation refusée définitivement');
        setState(() => _isLoadingLocation = false);
        return;
      }

      // Obtenir la position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _selectedLocation = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });

      // Mettre à jour la carte
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_selectedLocation!, 15),
      );

      // Ajouter un marqueur
      _updateMarker(_selectedLocation!);

      // Obtenir l'adresse
      _getAddressFromCoordinates(_selectedLocation!);
    } catch (e) {
      debugPrint('❌ Erreur localisation: $e');
      _showError('Impossible d\'obtenir votre position');
      setState(() => _isLoadingLocation = false);
    }
  }

  // Obtenir l'adresse à partir des coordonnées
  Future<void> _getAddressFromCoordinates(LatLng location) async {
    setState(() => _isLoadingAddress = true);

    try {
      final placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final address = [
          if (place.street != null && place.street!.isNotEmpty) place.street,
          if (place.subLocality != null && place.subLocality!.isNotEmpty) place.subLocality,
          if (place.locality != null && place.locality!.isNotEmpty) place.locality,
          if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) place.administrativeArea,
        ].join(', ');

        setState(() {
          _selectedAddressText = address;
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Erreur geocoding: $e');
      setState(() {
        _selectedAddressText = 'Adresse non trouvée';
        _isLoadingAddress = false;
      });
    }
  }

  // Mettre à jour le marqueur sur la carte
  void _updateMarker(LatLng location) {
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('selected_location'),
          position: location,
          draggable: true,
          onDragEnd: (newPosition) {
            setState(() => _selectedLocation = newPosition);
            _getAddressFromCoordinates(newPosition);
          },
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      };
    });
  }

  // Rechercher une adresse
  Future<void> _searchAddress(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);

    try {
      final locations = await locationFromAddress(query);

      setState(() {
        _searchResults = locations;
        _isSearching = false;
      });
    } catch (e) {
      debugPrint('❌ Erreur recherche: $e');
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      _showError('Aucune adresse trouvée');
    }
  }

  // Sélectionner un résultat de recherche
  void _selectSearchResult(Location location) {
    final latLng = LatLng(location.latitude, location.longitude);

    setState(() {
      _selectedLocation = latLng;
      _searchResults = [];
      _searchController.clear();
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(latLng, 15),
    );

    _updateMarker(latLng);
    _getAddressFromCoordinates(latLng);
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SystemUIScaffold(
      appBar: AppBar(
        title: const Text('Adresse de livraison'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.list),
              text: 'Mes adresses',
            ),
            Tab(
              icon: Icon(Icons.map),
              text: 'Carte',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSavedAddressesTab(),
          _buildMapTab(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _confirmAddress,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'Confirmer l\'adresse',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  // Onglet des adresses enregistrées
  Widget _buildSavedAddressesTab() {
    if (widget.savedAddresses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Aucune adresse enregistrée',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Utilisez la carte pour ajouter une adresse',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _tabController.animateTo(1),
              icon: const Icon(Icons.map),
              label: const Text('Utiliser la carte'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.savedAddresses.length,
      itemBuilder: (context, index) {
        final address = widget.savedAddresses[index];
        final isSelected = _selectedSavedAddress?.id == address.id;

        return Card(
          elevation: isSelected ? 4 : 1,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: InkWell(
            onTap: () => setState(() => _selectedSavedAddress = address),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getAddressIcon(address.label),
                        color: AppColors.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          address.label,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (address.isDefault)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Par défaut',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Radio<Address>(
                        value: address,
                        groupValue: _selectedSavedAddress,
                        onChanged: (value) => setState(() => _selectedSavedAddress = value),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${address.street}, ${address.commune}, ${address.city}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  if (address.coordinates != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.gps_fixed, size: 14, color: Colors.green[700]),
                        const SizedBox(width: 4),
                        Text(
                          'GPS disponible',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Onglet de la carte
  Widget _buildMapTab() {
    return Stack(
      children: [
        // Carte Google Maps
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _selectedLocation ?? const LatLng(5.3167, -4.0333), // Abidjan par défaut
            zoom: 15,
          ),
          onMapCreated: (controller) {
            _mapController = controller;
          },
          onTap: (latLng) {
            setState(() => _selectedLocation = latLng);
            _updateMarker(latLng);
            _getAddressFromCoordinates(latLng);
          },
          markers: _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
        ),

        // Barre de recherche
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Column(
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher une adresse...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchResults = []);
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onSubmitted: _searchAddress,
                ),
              ),

              // Résultats de recherche
              if (_searchResults.isNotEmpty)
                Card(
                  margin: const EdgeInsets.only(top: 8),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _searchResults.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final location = _searchResults[index];
                      return ListTile(
                        leading: const Icon(Icons.location_on, color: AppColors.primary),
                        title: Text('${location.latitude}, ${location.longitude}'),
                        onTap: () => _selectSearchResult(location),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),

        // Informations sur l'adresse sélectionnée
        if (_selectedLocation != null)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: AppColors.primary),
                        const SizedBox(width: 8),
                        const Text(
                          'Adresse sélectionnée',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_isLoadingAddress)
                      const Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Chargement de l\'adresse...'),
                        ],
                      )
                    else
                      Text(
                        _selectedAddressText ?? 'Déplacez le marqueur pour sélectionner une adresse',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      '📍 ${_selectedLocation!.latitude.toStringAsFixed(6)}, ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Bouton "Ma position"
        Positioned(
          right: 16,
          bottom: _selectedLocation != null ? 180 : 96,
          child: FloatingActionButton(
            heroTag: 'my_location',
            onPressed: _getCurrentLocation,
            backgroundColor: Colors.white,
            child: _isLoadingLocation
                ? const CircularProgressIndicator(strokeWidth: 2)
                : const Icon(Icons.my_location, color: AppColors.primary),
          ),
        ),
      ],
    );
  }

  IconData _getAddressIcon(String label) {
    final lowerLabel = label.toLowerCase();
    if (lowerLabel.contains('domicile') || lowerLabel.contains('maison')) {
      return Icons.home;
    } else if (lowerLabel.contains('bureau') || lowerLabel.contains('travail')) {
      return Icons.work;
    } else {
      return Icons.location_on;
    }
  }

  void _confirmAddress() {
    final tabIndex = _tabController.index;

    if (tabIndex == 0) {
      // Onglet "Mes adresses"
      if (_selectedSavedAddress == null) {
        _showError('Veuillez sélectionner une adresse');
        return;
      }

      if (_selectedSavedAddress!.coordinates == null) {
        _showError('Cette adresse n\'a pas de coordonnées GPS');
        return;
      }

      Navigator.pop(context, _selectedSavedAddress);
    } else {
      // Onglet "Carte"
      if (_selectedLocation == null) {
        _showError('Veuillez sélectionner une position sur la carte');
        return;
      }

      // Créer une nouvelle adresse temporaire avec les coordonnées
      final newAddress = Address(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        label: 'Position personnalisée',
        street: _selectedAddressText ?? 'Adresse sur carte',
        commune: 'À définir',
        city: 'Abidjan',
        coordinates: LocationCoords(
          latitude: _selectedLocation!.latitude,
          longitude: _selectedLocation!.longitude,
        ),
        isDefault: false,
      );

      Navigator.pop(context, newAddress);
    }
  }
}
