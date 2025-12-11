// ===== lib/screens/acheteur/vendors_list_screen.dart =====
// Liste des vendeurs triés par note

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../config/constants.dart';
import '../../services/review_service.dart';
import 'vendor_shop_screen.dart';
import '../widgets/system_ui_scaffold.dart';

class VendorsListScreen extends StatefulWidget {
  const VendorsListScreen({super.key});

  @override
  State<VendorsListScreen> createState() => _VendorsListScreenState();
}

class _VendorsListScreenState extends State<VendorsListScreen> {
  final ReviewService _reviewService = ReviewService();
  final TextEditingController _searchController = TextEditingController();

  List<VendorWithRating> _allVendors = [];
  List<VendorWithRating> _filteredVendors = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadVendors();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filterVendors();
    });
  }

  void _filterVendors() {
    if (_searchQuery.isEmpty) {
      _filteredVendors = _allVendors;
    } else {
      _filteredVendors = _allVendors.where((vendor) {
        final shopNameMatch = vendor.shopName.toLowerCase().contains(_searchQuery);
        final nameMatch = vendor.name.toLowerCase().contains(_searchQuery);
        final descriptionMatch = vendor.description.toLowerCase().contains(_searchQuery);
        return shopNameMatch || nameMatch || descriptionMatch;
      }).toList();
    }
  }

  Future<void> _loadVendors() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Récupérer tous les vendeurs
      final snapshot = await FirebaseFirestore.instance
          .collection(FirebaseCollections.users)
          .where('userType', isEqualTo: UserType.vendeur.value)
          .get();

      final List<VendorWithRating> vendors = [];

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          final profile = data['profile'] as Map<String, dynamic>?;
          final vendeurProfile = profile?['vendeurProfile'] as Map<String, dynamic>?;

          if (vendeurProfile == null) continue;

          // Récupérer la note moyenne du vendeur
          final rating = await _reviewService.getAverageRating(doc.id, 'vendor');
          final reviewsCount = (await _reviewService.getReviewsByVendor(doc.id)).length;

          vendors.add(VendorWithRating(
            id: doc.id,
            name: data['displayName'] ?? 'Vendeur',
            shopName: vendeurProfile['shopName'] ?? data['displayName'] ?? 'Boutique',
            description: vendeurProfile['description'] ?? '',
            photoUrl: data['photoURL'],
            rating: rating,
            reviewsCount: reviewsCount,
            shopLocation: vendeurProfile['shopLocation'] as Map<String, dynamic>?,
          ));
        } catch (e) {
          debugPrint('⚠️ Erreur traitement vendeur ${doc.id}: $e');
          continue;
        }
      }

      // Trier par note décroissante
      vendors.sort((a, b) => b.rating.compareTo(a.rating));

      setState(() {
        _allVendors = vendors;
        _filteredVendors = vendors;
        _isLoading = false;
      });

      debugPrint('✅ ${_allVendors.length} vendeur(s) chargé(s)');
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
        title: const Text('Découvrir les vendeurs'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Barre de recherche
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un vendeur...',
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
                filled: true,
                fillColor: AppColors.backgroundSecondary,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Résultats
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildErrorView()
                    : _allVendors.isEmpty
                        ? _buildEmptyView()
                        : _buildVendorsList(),
          ),
        ],
      ),
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
              onPressed: _loadVendors,
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.store, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Aucun vendeur disponible',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Il n\'y a aucun vendeur enregistré pour le moment',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadVendors,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualiser'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVendorsList() {
    if (_filteredVendors.isEmpty && _searchQuery.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Aucun résultat',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Aucun vendeur ne correspond à "$_searchQuery"',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadVendors,
      child: Column(
        children: [
          // Compteur de résultats
          if (_searchQuery.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.backgroundSecondary,
              child: Row(
                children: [
                  Text(
                    '${_filteredVendors.length} vendeur(s) trouvé(s)',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          // Liste des vendeurs
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredVendors.length,
              itemBuilder: (context, index) {
                final vendor = _filteredVendors[index];
                return _buildVendorCard(vendor);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorCard(VendorWithRating vendor) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VendorShopScreen(vendorId: vendor.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Photo du vendeur
              CircleAvatar(
                radius: 35,
                backgroundImage: vendor.photoUrl != null
                    ? NetworkImage(vendor.photoUrl!)
                    : null,
                child: vendor.photoUrl == null
                    ? const Icon(Icons.store, size: 35)
                    : null,
              ),
              const SizedBox(width: 16),

              // Informations du vendeur
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom de la boutique
                    Text(
                      vendor.shopName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Nom du vendeur
                    if (vendor.shopName != vendor.name)
                      Text(
                        vendor.name,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    const SizedBox(height: 8),

                    // Note et nombre d'avis
                    Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          vendor.rating > 0
                              ? '${vendor.rating.toStringAsFixed(1)} (${vendor.reviewsCount} avis)'
                              : 'Nouveau vendeur',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Description si disponible
                    if (vendor.description.isNotEmpty)
                      Text(
                        vendor.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),

              // Flèche
              const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Classe pour un vendeur avec sa note
class VendorWithRating {
  final String id;
  final String name;
  final String shopName;
  final String description;
  final String? photoUrl;
  final double rating;
  final int reviewsCount;
  final Map<String, dynamic>? shopLocation;

  VendorWithRating({
    required this.id,
    required this.name,
    required this.shopName,
    required this.description,
    this.photoUrl,
    required this.rating,
    required this.reviewsCount,
    this.shopLocation,
  });
}
