// ===== lib/screens/acheteur/product_detail_screen.dart =====
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:social_business_pro/config/constants.dart';
import '../../models/product_model.dart';
import '../../models/review_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/auth_provider_firebase.dart';
import '../../services/product_service.dart';
import '../../services/review_service.dart';
import '../../widgets/custom_widgets.dart';
import '../../widgets/rating_stars.dart';
import '../../widgets/review_list.dart';
import '../../widgets/review_dialog.dart';
import '../../utils/number_formatter.dart';
import '../../widgets/system_ui_scaffold.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ProductService _productService = ProductService();
  final ReviewService _reviewService = ReviewService();

  ProductModel? _product;
  bool _isLoading = true;
  String? _errorMessage;
  int _quantity = 1;
  int _selectedImageIndex = 0;

  // Avis
  List<ReviewModel> _reviews = [];
  bool _isLoadingReviews = true;
  double _averageRating = 0.0;
  int _totalReviews = 0;
  Map<int, int> _ratingDistribution = {};

  @override
  void initState() {
    super.initState();
    _loadProduct();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      setState(() => _isLoadingReviews = true);

      final reviews = await _reviewService.getReviewsByProduct(widget.productId);
      final avgRating = await _reviewService.getAverageRating(widget.productId, 'product');
      final distribution = await _reviewService.getRatingDistribution(widget.productId, 'product');

      if (mounted) {
        setState(() {
          _reviews = reviews;
          _averageRating = avgRating;
          _totalReviews = reviews.length;
          _ratingDistribution = distribution;
          _isLoadingReviews = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement avis: $e');
      if (mounted) {
        setState(() => _isLoadingReviews = false);
      }
    }
  }

  Future<void> _loadProduct() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final product = await _productService.getProduct(widget.productId);

      if (mounted) {
        setState(() {
          _product = product;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur de chargement du produit';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addToCart() async {
    if (_product == null) return;

    try {
      final cartProvider = context.read<CartProvider>();
      await cartProvider.addProduct(_product!, quantity: _quantity);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$_quantity ${_product!.name} ajouté(s) au panier'),
            backgroundColor: AppColors.success,
            action: SnackBarAction(
              label: 'Voir',
              textColor: Colors.white,
              onPressed: () => context.push('/acheteur/cart'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _buyNow() async {
    if (_product == null) return;

    try {
      final cartProvider = context.read<CartProvider>();
      await cartProvider.clearCart();
      await cartProvider.addProduct(_product!, quantity: _quantity);

      if (mounted) {
        context.push('/acheteur/checkout');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SystemUIScaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildError()
              : _product == null
                  ? _buildNotFound()
                  : _buildContent(),
      bottomNavigationBar: _product != null ? _buildBottomBar() : null,
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: AppSpacing.md),
          Text(
            _errorMessage!,
            style: const TextStyle(
              fontSize: AppFontSizes.lg,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          CustomButton(
            text: 'Réessayer',
            icon: Icons.refresh,
            onPressed: _loadProduct,
          ),
        ],
      ),
    );
  }

  Widget _buildNotFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Produit introuvable',
            style: TextStyle(
              fontSize: AppFontSizes.lg,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          CustomButton(
            text: 'Retour',
            icon: Icons.arrow_back,
            onPressed: () => context.pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return CustomScrollView(
      slivers: [
        _buildAppBar(),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageGallery(),
              _buildProductInfo(),
              _buildVendorInfo(),
              _buildDescription(),
              _buildReviews(),
              const SizedBox(height: 100), // Space for bottom bar
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/acheteur');
            }
          },
          tooltip: 'Retour',
        ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          onPressed: () {
            if (_product != null) {
              final shareText = '''
🛍️ ${_product!.name}

💰 Prix: ${formatPriceWithCurrency(_product!.price)}${_product!.originalPrice != null ? '\n🏷️ Prix d\'origine: ${formatPriceWithCurrency(_product!.originalPrice!)}' : ''}

📝 ${_product!.description}

🏪 Vendeur: ${_product!.vendeurName}
📦 Stock disponible: ${_product!.stock} unité(s)

Découvrez ce produit sur Social Business Pro!
''';
              Share.share(
                shareText,
                subject: _product!.name,
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Produit non chargé, veuillez réessayer'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
        ),
        Consumer<FavoriteProvider>(
          builder: (context, favoriteProvider, _) {
            if (_product == null) {
              return const SizedBox.shrink();
            }

            final isFavorite = favoriteProvider.isFavorite(_product!.id);

            return IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: Colors.white,
              ),
              onPressed: () async {
                try {
                  await favoriteProvider.toggleFavorite(
                    _product!.id,
                    _product!.name,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isFavorite ? 'Retiré des favoris' : 'Ajouté aux favoris',
                        ),
                        duration: const Duration(seconds: 1),
                        backgroundColor: isFavorite ? AppColors.textSecondary : AppColors.success,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildImageGallery() {
    final images =
        _product!.images.isNotEmpty ? _product!.images : ['https://via.placeholder.com/400'];

    return Container(
      height: 400,
      color: Colors.white,
      child: Column(
        children: [
          // Image principale
          Expanded(
            child: PageView.builder(
              itemCount: images.length,
              onPageChanged: (index) {
                setState(() => _selectedImageIndex = index);
              },
              itemBuilder: (context, index) {
                return Image.network(
                  images[index],
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppColors.backgroundSecondary,
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image, size: 64, color: AppColors.textSecondary),
                          SizedBox(height: AppSpacing.sm),
                          Text('Image non disponible'),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Indicateurs
          if (images.length > 1)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  images.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _selectedImageIndex == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _selectedImageIndex == index ? AppColors.primary : AppColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductInfo() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Prix
          Row(
            children: [
              Text(
                formatPriceWithCurrency(_product!.price, currency: 'FCFA'),
                style: const TextStyle(
                  fontSize: AppFontSizes.xxl,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              if (_product!.originalPrice != null &&
                  _product!.originalPrice! > _product!.price) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(
                  formatPriceWithCurrency(_product!.originalPrice!, currency: 'FCFA'),
                  style: const TextStyle(
                    fontSize: AppFontSizes.md,
                    decoration: TextDecoration.lineThrough,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '-${((((_product!.originalPrice! - _product!.price) / _product!.originalPrice!) * 100)).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: AppFontSizes.sm,
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Nom
          Text(
            _product!.name,
            style: const TextStyle(
              fontSize: AppFontSizes.xl,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // Catégorie et note
          Row(
            children: [
              Chip(
                label: Text(_product!.category),
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                labelStyle: const TextStyle(color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (_totalReviews > 0)
                RatingBadge(
                  rating: _averageRating,
                  reviewCount: _totalReviews,
                  onTap: () {
                    // Scroll vers la section avis
                    // TODO: Implémenter le scroll automatique
                  },
                ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Stock
          Row(
            children: [
              Icon(
                _product!.stock > 0 ? Icons.check_circle : Icons.cancel,
                color: _product!.stock > 0 ? AppColors.success : AppColors.error,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                _product!.stock > 0
                    ? 'En stock (${_product!.stock} disponibles)'
                    : 'Rupture de stock',
                style: TextStyle(
                  color: _product!.stock > 0 ? AppColors.success : AppColors.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Sélecteur de quantité
          if (_product!.stock > 0) ...[
            const Text(
              'Quantité :',
              style: TextStyle(
                fontSize: AppFontSizes.md,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                IconButton(
                  onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                  icon: const Icon(Icons.remove_circle_outline),
                  color: AppColors.primary,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    _quantity.toString(),
                    style: const TextStyle(
                      fontSize: AppFontSizes.lg,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _quantity < _product!.stock ? () => setState(() => _quantity++) : null,
                  icon: const Icon(Icons.add_circle_outline),
                  color: AppColors.primary,
                ),
                const Spacer(),
                Text(
                  'Max: ${_product!.stock}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVendorInfo() {
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.lg),
      color: Colors.white,
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary,
            child: Text(
              _product!.vendeurName.isNotEmpty ? _product!.vendeurName[0].toUpperCase() : 'V',
              style: const TextStyle(
                color: Colors.white,
                fontSize: AppFontSizes.lg,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _product!.vendeurName,
                  style: const TextStyle(
                    fontSize: AppFontSizes.md,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Row(
                  children: [
                    Icon(Icons.star, size: 16, color: Colors.amber),
                    SizedBox(width: 4),
                    Text('4.8 (120 avis)'),
                  ],
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              // TODO: Voir profil vendeur
            },
            child: const Text('Voir'),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.lg),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Description',
            style: TextStyle(
              fontSize: AppFontSizes.lg,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            _product!.description,
            style: const TextStyle(
              fontSize: AppFontSizes.md,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviews() {
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.lg),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Avis clients',
                style: TextStyle(
                  fontSize: AppFontSizes.lg,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_totalReviews > 0)
                TextButton.icon(
                  onPressed: () async {
                    final authProvider = context.read<AuthProvider>();
                    final hasOrdered = await _checkIfUserOrderedProduct(authProvider.user?.id);

                    if (!mounted) return;

                    if (hasOrdered) {
                      final result = await ReviewDialog.show(
                        context,
                        targetId: widget.productId,
                        targetType: 'product',
                        targetName: _product?.name ?? 'Produit',
                      );

                      if (result == true) {
                        _loadReviews();
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Vous devez commander ce produit pour laisser un avis'),
                          backgroundColor: AppColors.warning,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Laisser un avis'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Résumé des avis
          if (_isLoadingReviews)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_totalReviews > 0) ...[
            ReviewSummary(
              averageRating: _averageRating,
              totalReviews: _totalReviews,
              distribution: _ratingDistribution,
            ),
            const SizedBox(height: AppSpacing.lg),
            const Divider(),
            const SizedBox(height: AppSpacing.md),

            // Liste des avis (3 premiers)
            ReviewList(
              reviews: _reviews.take(3).toList(),
              showResponseField: false,
            ),

            if (_reviews.length > 3) ...[
              const SizedBox(height: AppSpacing.md),
              Center(
                child: TextButton(
                  onPressed: () {
                    // TODO: Navigation vers écran complet des avis
                  },
                  child: Text('Voir les ${_reviews.length - 3} autres avis'),
                ),
              ),
            ],
          ] else
            Center(
              child: Column(
                children: [
                  const Text(
                    'Aucun avis pour le moment',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final authProvider = context.read<AuthProvider>();
                      final hasOrdered = await _checkIfUserOrderedProduct(authProvider.user?.id);

                      if (!mounted) return;

                      if (hasOrdered) {
                        final result = await ReviewDialog.show(
                          context,
                          targetId: widget.productId,
                          targetType: 'product',
                          targetName: _product?.name ?? 'Produit',
                        );

                        if (result == true) {
                          _loadReviews();
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Vous devez commander ce produit pour laisser un avis'),
                            backgroundColor: AppColors.warning,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.rate_review),
                    label: const Text('Soyez le premier à donner votre avis'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Vérifie si l'utilisateur a commandé ce produit
  Future<bool> _checkIfUserOrderedProduct(String? userId) async {
    if (userId == null) return false;

    try {
      // Logique pour vérifier si l'utilisateur a déjà commandé ce produit
      // Pour l'instant, on retourne true pour permettre les tests
      // TODO: Implémenter la vérification réelle dans OrderService
      return true;
    } catch (e) {
      debugPrint('❌ Erreur vérification commande: $e');
      return false;
    }
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
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
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'Ajouter au panier',
                icon: Icons.shopping_cart_outlined,
                isOutlined: true,
                backgroundColor: AppColors.primary,
                onPressed: _product!.stock > 0 ? _addToCart : null,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: CustomButton(
                text: 'Acheter',
                icon: Icons.shopping_bag,
                backgroundColor: AppColors.primary,
                onPressed: _product!.stock > 0 ? _buyNow : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
