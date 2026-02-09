// ===== lib/screens/acheteur/nearby_vendors_screen.dart =====
// Liste des vendeurs à proximité avec calcul de distance GPS

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../config/constants.dart';
import '../../widgets/custom_widgets.dart';
import '../../widgets/system_ui_scaffold.dart';
import '../../services/geolocation_service.dart';

class NearbyVendorsScreen extends StatefulWidget {
  const NearbyVendorsScreen({super.key});

  @override
  State<NearbyVendorsScreen> createState() => _NearbyVendorsScreenState();
}

class _NearbyVendorsScreenState extends State<NearbyVendorsScreen> {
  final GeolocationService _geoService = GeolocationService();

  List<VendorWithDistance> _vendors = [];
  Position? _currentPosition;
  bool _isLoading = true;
  String? _error;
  double _maxDistance = 10.0; // km

  @override
  void initState() {
    super.initState();
    _loadNearbyVendors();
  }

  Future<void> _loadNearbyVendors() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 1. Obtenir la position actuelle
      _currentPosition = await GeolocationService.getCurrentPosition();

      if (_currentPosition == null) {
        throw Exception('Impossible d\'obtenir votre position GPS');
      }

      debugPrint('📍 Position: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');

      // 2. Récupérer tous les vendeurs actifs
      final vendorsSnapshot = await FirebaseFirestore.instance
          .collection(FirebaseCollections.users)
          .where('userType', isEqualTo: UserType.vendeur.value)
          .where('isActive', isEqualTo: true)
          .get()
          .timeout(const Duration(seconds: 15));

      debugPrint('✅ ${vendorsSnapshot.docs.length} vendeurs trouvés');

      // 3. Calculer la distance pour chaque vendeur
      final vendorsWithDistance = <VendorWithDistance>[];

      for (var doc in vendorsSnapshot.docs) {
        final data = doc.data();
        final profile = data['profile'] as Map<String, dynamic>?;

        // Récupérer l'adresse principale du vendeur
        final addresses = profile?['addresses'] as List<dynamic>?;
        if (addresses == null || addresses.isEmpty) continue;

        final mainAddress = addresses.firstWhere(
          (addr) => addr['isDefault'] == true,
          orElse: () => addresses.first,
        ) as Map<String, dynamic>;

        final lat = mainAddress['latitude'] as double?;
        final lng = mainAddress['longitude'] as double?;

        if (lat == null || lng == null) continue;

        // Calculer la distance
        final distance = GeolocationService.calculateDistance(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          lat,
          lng,
        );

        // Filtrer par distance maximale
        if (distance <= _maxDistance) {
          vendorsWithDistance.add(VendorWithDistance(
            id: doc.id,
            data: data,
            distance: distance,
          ));
        }
      }

      // 4. Trier par distance
      vendorsWithDistance.sort((a, b) => a.distance.compareTo(b.distance));

      setState(() {
        _vendors = vendorsWithDistance;
        _isLoading = false;
      });

      debugPrint('✅ ${_vendors.length} vendeurs à proximité (< ${_maxDistance}km)');

    } catch (e) {
      debugPrint('❌ Erreur chargement vendeurs: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SystemUIScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/acheteur-home');
            }
          },
          tooltip: 'Retour',
        ),
        title: const Text('Vendeurs à proximité'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          // Filtre de distance
          PopupMenuButton<double>(
            icon: const Icon(Icons.tune),
            tooltip: 'Filtrer par distance',
            onSelected: (value) {
              setState(() {
                _maxDistance = value;
              });
              _loadNearbyVendors();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 5.0,
                child: Text('< 5 km'),
              ),
              const PopupMenuItem(
                value: 10.0,
                child: Text('< 10 km'),
              ),
              const PopupMenuItem(
                value: 20.0,
                child: Text('< 20 km'),
              ),
              const PopupMenuItem(
                value: 50.0,
                child: Text('< 50 km'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorView()
              : _vendors.isEmpty
                  ? _buildEmptyView()
                  : _buildVendorsList(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            const Text(
              'Erreur de chargement',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Une erreur est survenue',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadNearbyVendors,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Aucun vendeur à proximité',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Essayez d\'augmenter le rayon de recherche',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _maxDistance = _maxDistance * 2;
                });
                _loadNearbyVendors();
              },
              icon: const Icon(Icons.zoom_out_map),
              label: Text('Chercher jusqu\'à ${(_maxDistance * 2).toInt()} km'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVendorsList() {
    return RefreshIndicator(
      onRefresh: _loadNearbyVendors,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // En-tête
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_vendors.length} vendeur(s) dans un rayon de ${_maxDistance.toInt()} km',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Liste des vendeurs
          ..._vendors.map((vendorData) => _buildVendorCard(vendorData)),
        ],
      ),
    );
  }

  Widget _buildVendorCard(VendorWithDistance vendorData) {
    final profile = vendorData.data['profile'] as Map<String, dynamic>?;
    final shopName = profile?['businessName'] ??
                     vendorData.data['displayName'] ??
                     'Boutique';
    final description = profile?['description'] ?? '';

    // Pas de badges pour simplifier (les retirer)
    final isVerified = vendorData.data['verificationStatus'] == 'verified';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          context.push('/vendor/${vendorData.id}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Photo du vendeur
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: vendorData.data['photoURL'] != null
                        ? NetworkImage(vendorData.data['photoURL'])
                        : null,
                    child: vendorData.data['photoURL'] == null
                        ? const Icon(Icons.store, size: 30)
                        : null,
                  ),
                  const SizedBox(width: 12),

                  // Infos
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shopName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star, size: 16, color: Colors.amber),
                            const SizedBox(width: 4),
                            const Text(
                              '4.5',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const Text(' (89 avis)'),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Distance
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: AppColors.success),
                        const SizedBox(width: 4),
                        Text(
                          vendorData.distance < 1
                              ? '${(vendorData.distance * 1000).toInt()}m'
                              : '${vendorData.distance.toStringAsFixed(1)}km',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],

              // Badge vérifié
              if (isVerified) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.verified, size: 16, color: AppColors.primary),
                    const SizedBox(width: 4),
                    const Text(
                      'Vendeur vérifié',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
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
  }
}

// Classe pour stocker vendeur + distance
class VendorWithDistance {
  final String id;
  final Map<String, dynamic> data;
  final double distance;

  VendorWithDistance({
    required this.id,
    required this.data,
    required this.distance,
  });
}

