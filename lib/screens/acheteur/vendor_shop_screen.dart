// ===== lib/screens/acheteur/vendor_shop_screen.dart =====
// Boutique d'un vendeur avec ses produits

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider_firebase.dart';
import '../../services/review_service.dart';
import '../../services/product_service.dart';
import 'product_detail_screen.dart';

class VendorShopScreen extends StatefulWidget {
  final String vendorId;

  const VendorShopScreen({
    super.key,
    required this.vendorId,
  });

  @override
  State<VendorShopScreen> createState() => _VendorShopScreenState();
}

class _VendorShopScreenState extends State<VendorShopScreen> {
  final ReviewService _reviewService = ReviewService();
  final ProductService _productService = ProductService();

  Map<String, dynamic>? _vendorData;
  List<ProductModel> _products = [];
  bool _isLoading = true;
  bool _isFavorite = false;
  String? _error;

  double _rating = 0.0;
  int _reviewsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadVendorData();
  }

  Future<void> _loadVendorData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Charger les données du vendeur
      final vendorDoc = await FirebaseFirestore.instance
          .collection(FirebaseCollections.users)
          .doc(widget.vendorId)
          .get();

      if (!vendorDoc.exists) {
        throw Exception('Vendeur introuvable');
      }

      _vendorData = vendorDoc.data();

      // Charger la note et les avis
      _rating = await _reviewService.getAverageRating(widget.vendorId, 'vendor');
      final reviews = await _reviewService.getReviewsByVendor(widget.vendorId);
      _reviewsCount = reviews.length;

      // Charger les produits du vendeur
      _products = await _productService.getVendorProducts(widget.vendorId);

      // Vérifier si le vendeur est en favoris
      await _checkIfFavorite();

      setState(() {
        _isLoading = false;
      });

      debugPrint('✅ Boutique chargée: ${_products.length} produits');
    } catch (e) {
      debugPrint('❌ Erreur chargement boutique: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _checkIfFavorite() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.user?.id;

      if (userId == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection(FirebaseCollections.users)
          .doc(userId)
          .get();

      final userData = userDoc.data();
      final profile = userData?['profile'] as Map<String, dynamic>?;
      final acheteurProfile = profile?['acheteurProfile'] as Map<String, dynamic>?;
      final favoriteVendors = acheteurProfile?['favoriteVendors'] as List<dynamic>?;

      setState(() {
        _isFavorite = favoriteVendors?.contains(widget.vendorId) ?? false;
      });
    } catch (e) {
      debugPrint('❌ Erreur vérification favori: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.user?.id;

      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vous devez être connecté'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final userRef = FirebaseFirestore.instance
          .collection(FirebaseCollections.users)
          .doc(userId);

      if (_isFavorite) {
        // Retirer des favoris
        await userRef.update({
          'profile.acheteurProfile.favoriteVendors': FieldValue.arrayRemove([widget.vendorId])
        });
      } else {
        // Ajouter aux favoris
        await userRef.update({
          'profile.acheteurProfile.favoriteVendors': FieldValue.arrayUnion([widget.vendorId])
        });
      }

      setState(() {
        _isFavorite = !_isFavorite;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isFavorite ? 'Ajouté aux favoris' : 'Retiré des favoris'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      debugPrint('❌ Erreur toggle favori: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_vendorData?['displayName'] ?? 'Boutique'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
            onPressed: _toggleFavorite,
            tooltip: _isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorView()
              : _buildShopContent(),
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
              onPressed: _loadVendorData,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopContent() {
    final profile = _vendorData?['profile'] as Map<String, dynamic>?;
    final vendeurProfile = profile?['vendeurProfile'] as Map<String, dynamic>?;
    final shopName = vendeurProfile?['shopName'] ?? _vendorData?['displayName'] ?? 'Boutique';
    final description = vendeurProfile?['description'] ?? '';

    return CustomScrollView(
      slivers: [
        // En-tête de la boutique
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // Photo et nom
                CircleAvatar(
                  radius: 50,
                  backgroundImage: _vendorData?['photoURL'] != null
                      ? NetworkImage(_vendorData!['photoURL'])
                      : null,
                  child: _vendorData?['photoURL'] == null
                      ? const Icon(Icons.store, size: 50)
                      : null,
                ),
                const SizedBox(height: 16),

                Text(
                  shopName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Note
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, size: 20, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      _rating > 0
                          ? '${_rating.toStringAsFixed(1)} ($_reviewsCount avis)'
                          : 'Nouveau vendeur',
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Description
                if (description.isNotEmpty)
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
        ),

        // Titre produits
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Produits (${_products.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Liste des produits
        _products.isEmpty
            ? SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'Aucun produit disponible',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final product = _products[index];
                      return _buildProductCard(product);
                    },
                    childCount: _products.length,
                  ),
                ),
              ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(productId: product.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image du produit
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  color: Colors.grey[200],
                ),
                child: product.images.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: Image.network(
                          product.images.first,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                            );
                          },
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.image, size: 40, color: Colors.grey),
                      ),
              ),
            ),

            // Informations produit
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${product.price.toStringAsFixed(0)} FCFA',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
