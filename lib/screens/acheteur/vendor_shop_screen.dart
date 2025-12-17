// ===== lib/screens/acheteur/vendor_shop_screen.dart =====
// Boutique d'un vendeur avec ses produits

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../config/constants.dart';
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../services/review_service.dart';
import '../../services/product_service.dart';
import '../../widgets/custom_widgets.dart';
import '../../utils/image_helper.dart';
import '../../utils/number_formatter.dart';
import '../../widgets/system_ui_scaffold.dart';

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
      final favoriteProvider = context.read<FavoriteProvider>();
      setState(() {
        _isFavorite = favoriteProvider.isFavoriteVendor(widget.vendorId);
      });
    } catch (e) {
      debugPrint('❌ Erreur vérification favori: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      final favoriteProvider = context.read<FavoriteProvider>();

      // Utiliser le FavoriteProvider pour gérer les favoris vendeurs
      await favoriteProvider.toggleFavoriteVendor(
        widget.vendorId,
        _vendorData?['businessName'] as String? ?? 'Vendeur',
      );

      setState(() {
        _isFavorite = favoriteProvider.isFavoriteVendor(widget.vendorId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFavorite ? 'Ajouté aux favoris' : 'Retiré des favoris'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Erreur toggle favori: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SystemUIScaffold(
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
                  child:
                      _vendorData?['photoURL'] == null ? const Icon(Icons.store, size: 50) : null,
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
                    childAspectRatio:
                        0.55, // ✅ CORRECTION: 0.55 pour carte complète avec tous les éléments
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
    return InkWell(
      onTap: () {
        context.push('/product/${product.id}');
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image avec badges
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    ImageHelper.getValidImageUrl(
                      imageUrl: product.images.isNotEmpty ? product.images.first : null,
                      category: product.category,
                      index: product.hashCode % 4,
                    ),
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 150,
                        color: Colors.grey[200],
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 50,
                            color: Colors.grey[300],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Badge réduction dynamique
                if (product.isDiscountActive)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: DiscountBadge(
                      discountPercentage: product.discountPercentage,
                      isActive: product.isDiscountActive,
                      size: 50,
                    ),
                  ),

                // Bouton favori
                Positioned(
                  top: 8,
                  right: 8,
                  child: Consumer<FavoriteProvider>(
                    builder: (context, favoriteProvider, _) {
                      final isFavorite = favoriteProvider.isFavorite(product.id);

                      return GestureDetector(
                        onTap: () async {
                          try {
                            await favoriteProvider.toggleFavorite(product.id, product.name);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isFavorite ? 'Retiré des favoris' : 'Ajouté aux favoris',
                                  ),
                                  duration: const Duration(seconds: 1),
                                  backgroundColor: isFavorite ? AppColors.info : AppColors.success,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Erreur: $e'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            size: 18,
                            color: isFavorite ? AppColors.error : Colors.grey[600],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            // Infos produit
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom du vendeur avec badge vérifié
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.vendeurName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const VendorBadge(
                          type: VendorBadgeType.verified,
                          compact: true,
                          iconSize: 12,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Nom du produit
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: AppColors.warning),
                        const SizedBox(width: 4),
                        Text(
                          '4.5 (89)',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Badge de stock
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: product.isOutOfStock
                                ? AppColors.error.withValues(alpha: 0.1)
                                : product.isLowStock
                                    ? AppColors.warning.withValues(alpha: 0.1)
                                    : AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                product.isOutOfStock
                                    ? Icons.cancel_outlined
                                    : product.isLowStock
                                        ? Icons.warning_amber_outlined
                                        : Icons.check_circle_outlined,
                                size: 12,
                                color: product.isOutOfStock
                                    ? AppColors.error
                                    : product.isLowStock
                                        ? AppColors.warning
                                        : AppColors.success,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                product.isOutOfStock
                                    ? 'Rupture'
                                    : product.isLowStock
                                        ? 'Stock faible (${product.availableStock})'
                                        : '${product.availableStock} en stock',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: product.isOutOfStock
                                      ? AppColors.error
                                      : product.isLowStock
                                          ? AppColors.warning
                                          : AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Prix et bouton
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            formatPriceWithCurrency(product.price, currency: 'FCFA'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Consumer<CartProvider>(
                          builder: (context, cartProvider, _) {
                            return IconButton(
                              onPressed: () async {
                                await cartProvider.addProduct(product);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Produit ajouté au panier'),
                                      duration: Duration(seconds: 1),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.add_shopping_cart),
                              color: AppColors.primary,
                              iconSize: 22,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
