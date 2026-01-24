// ===== lib/screens/acheteur/category_products_screen.dart =====
// Page de produits d'une catégorie - Design SmarterVision - SOCIAL BUSINESS Pro

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:social_business_pro/config/constants.dart';
import '../../config/product_categories.dart';
import '../../config/product_subcategories.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart';
import '../../providers/cart_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/auth_provider_firebase.dart';
import '../../widgets/system_ui_scaffold.dart';
import '../../widgets/filter_drawer.dart';
import '../../widgets/category_banner.dart';
import '../../utils/number_formatter.dart';
import '../../utils/image_helper.dart';

class CategoryProductsScreen extends StatefulWidget {
  final String categoryId;
  final String? subcategory;

  const CategoryProductsScreen({
    super.key,
    required this.categoryId,
    this.subcategory,
  });

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  final ProductService _productService = ProductService();

  String? _selectedSubcategory;
  bool _isLoading = true;
  bool _isGridView = true;
  List<ProductModel> _products = [];
  List<ProductModel> _filteredProducts = [];

  @override
  void initState() {
    super.initState();
    _selectedSubcategory = widget.subcategory;
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final allProducts = await _productService.getProducts();
      final categoryProducts = allProducts
          .where((p) => p.category.toLowerCase() == widget.categoryId.toLowerCase())
          .toList();

      setState(() {
        _products = categoryProducts;
        _filterProducts();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Erreur chargement produits: $e');
      setState(() => _isLoading = false);
    }
  }

  void _filterProducts() {
    if (_selectedSubcategory == null) {
      _filteredProducts = _products;
    } else {
      _filteredProducts = _products
          .where((p) => p.subCategory?.toLowerCase() == _selectedSubcategory!.toLowerCase())
          .toList();
    }
  }

  ProductCategory get _category {
    return ProductCategories.allCategories.firstWhere((cat) => cat.id == widget.categoryId);
  }

  @override
  Widget build(BuildContext context) {
    final subcategories = ProductSubcategories.getSubcategories(widget.categoryId)
        .where((subcat) => !subcat.toLowerCase().contains('autre'))
        .toList();

    return SystemUIPopScaffold(
      endDrawer: const FilterDrawer(),
      canPop: true,
      body: CustomScrollView(
        slivers: [
          // Header avec bannière colorée
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: CategoryBannerConfig.getGradient(widget.categoryId).first,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  context.go('/acheteur-home');
                }
              },
              tooltip: 'Retour',
            ),
            actions: [
              // Panier avec badge
              Consumer<CartProvider>(
                builder: (context, cart, child) {
                  final itemCount = cart.totalQuantity;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                        onPressed: () => context.push('/acheteur/cart'),
                      ),
                      if (itemCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Text(
                              itemCount > 9 ? '9+' : '$itemCount',
                              style: TextStyle(
                                color: CategoryBannerConfig.getGradient(widget.categoryId).first,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(width: 8),
              // Avatar utilisateur
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    final user = authProvider.user;
                    return GestureDetector(
                      onTap: () => context.push('/acheteur/profile'),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white,
                        backgroundImage: user?.profile['photoURL'] != null
                            ? NetworkImage(user!.profile['photoURL'])
                            : null,
                        child: user?.profile['photoURL'] == null
                            ? Icon(
                                Icons.person_rounded,
                                color: CategoryBannerConfig.getGradient(widget.categoryId).first,
                                size: 20,
                              )
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _buildCategoryHeader(),
            ),
          ),

          // Sous-catégories horizontales avec couleur de la catégorie
          if (subcategories.isNotEmpty)
            SliverToBoxAdapter(
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: CategoryBannerConfig.getGradient(widget.categoryId),
                  ),
                ),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: subcategories.length,
                  itemBuilder: (context, index) {
                    final subcat = subcategories[index];
                    final isSelected = _selectedSubcategory == subcat;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedSubcategory = isSelected ? null : subcat;
                          _filterProducts();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: isSelected
                              ? const Border(
                                  bottom: BorderSide(color: Colors.white, width: 3),
                                )
                              : null,
                        ),
                        child: Text(
                          subcat.replaceAll('Category', '').replaceAll('category', '').trim(),
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.7),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          // Barre de recherche
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[400]),
                    suffixIcon: Builder(
                      builder: (BuildContext scaffoldContext) {
                        return IconButton(
                          icon: Icon(Icons.tune_rounded, color: Colors.grey[600]),
                          onPressed: () => Scaffold.of(scaffoldContext).openEndDrawer(),
                        );
                      },
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onTap: () => context.push('/acheteur/search'),
                  readOnly: true,
                ),
              ),
            ),
          ),

          // Titre avec icônes de vue
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(_category.icon, color: AppColors.primary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${_selectedSubcategory ?? _category.name} ',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.view_list_rounded,
                      color: !_isGridView ? AppColors.primary : Colors.grey,
                    ),
                    onPressed: () => setState(() => _isGridView = false),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.grid_view_rounded,
                      color: _isGridView ? AppColors.primary : Colors.grey,
                    ),
                    onPressed: () => setState(() => _isGridView = true),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Grille ou liste de produits
          _isLoading
              ? const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              : _filteredProducts.isEmpty
                  ? SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_category.icon, size: 80, color: Colors.grey),
                            const SizedBox(height: 16),
                            const Text(
                              'Aucun produit disponible',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _isGridView
                      ? SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                // ✅ Grille flexible avec hauteur auto
                                final startIndex = index * 2;
                                if (startIndex >= _filteredProducts.length) return null;

                                final product1 = _filteredProducts[startIndex];
                                final product2 = startIndex + 1 < _filteredProducts.length
                                    ? _filteredProducts[startIndex + 1]
                                    : null;

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(child: _buildProductCard(product1)),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: product2 != null
                                            ? _buildProductCard(product2)
                                            : const SizedBox.shrink(),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              childCount: (_filteredProducts.length / 2).ceil(),
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => _buildProductListItem(_filteredProducts[index]),
                              childCount: _filteredProducts.length,
                            ),
                          ),
                        ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  // Header avec bannière colorée et image
  Widget _buildCategoryHeader() {
    final gradientColors = CategoryBannerConfig.getGradient(widget.categoryId);
    final imagePath = CategoryBannerConfig.getImage(widget.categoryId);

    return Stack(
      children: [
        // Gradient de fond
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
          ),
        ),

        // Image de la catégorie si disponible
        if (imagePath != null)
          Positioned(
            right: -40,
            bottom: -20,
            top: 0,
            child: Opacity(
              opacity: 0.3,
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                width: 250,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),

        // Contenu de la bannière
        Positioned(
          left: 20,
          right: 20,
          bottom: 30,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icône de la catégorie
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _category.icon,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              // Nom de la catégorie
              Text(
                _category.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 2),
                      blurRadius: 8,
                      color: Colors.black26,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              // Nombre de produits
              Text(
                '${_filteredProducts.length} produit${_filteredProducts.length > 1 ? 's' : ''} disponible${_filteredProducts.length > 1 ? 's' : ''}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  shadows: const [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 4,
                      color: Colors.black26,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return InkWell(
      onTap: () => context.push('/product/${product.id}'),
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image avec badges
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: Image.network(
                    ImageHelper.getValidImageUrl(
                      imageUrl: product.images.isNotEmpty ? product.images.first : null,
                      category: product.category,
                      index: product.hashCode % 4,
                    ),
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 120,
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
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 40,
                            color: Colors.grey[400],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Badge FLASH SALE
                if (product.isFlashSale)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.error,
                            AppColors.error.withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.error.withValues(alpha: 0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '🔥',
                            style: TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 4),
                          if (product.originalPrice != null)
                            Text(
                              '-${((1 - product.price / product.originalPrice!) * 100).toInt()}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          else
                            const Text(
                              'FLASH',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                // Badge NEW
                if (product.isNew && !product.isFlashSale)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.success.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text(
                        '✨ NEW',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                            await favoriteProvider.toggleFavorite(
                              product.id,
                              product.name,
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isFavorite ? 'Retiré des favoris' : 'Ajouté aux favoris',
                                  ),
                                  duration: const Duration(seconds: 1),
                                  backgroundColor:
                                      isFavorite ? AppColors.textSecondary : AppColors.success,
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
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
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

            // Infos
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
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Stats: Ventes + Rating
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: 14,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '4.5',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.shopping_bag_outlined,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${(product.stock * 0.3).toInt()} vendus',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Barre de progression du stock
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Stock',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${product.stock} restant${product.stock > 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: 10,
                              color: product.stock > 10
                                  ? AppColors.success
                                  : product.stock > 0
                                      ? AppColors.warning
                                      : AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: product.stock > 100 ? 1.0 : product.stock / 100,
                          minHeight: 6,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            product.stock > 20
                                ? AppColors.success
                                : product.stock > 5
                                    ? AppColors.warning
                                    : AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatPriceWithCurrency(product.price),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  if (product.originalPrice != null)
                    Text(
                      formatPriceWithCurrency(product.originalPrice!),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                        decoration: TextDecoration.lineThrough,
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

  Widget _buildProductListItem(ProductModel product) {
    return InkWell(
      onTap: () => context.push('/product/${product.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              child: Image.network(
                ImageHelper.getValidImageUrl(
                  imageUrl: product.images.isNotEmpty ? product.images.first : null,
                  category: product.category,
                  index: product.hashCode % 4,
                ),
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
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
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatPriceWithCurrency(product.price, currency: 'FCFA'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (product.availableStock > 0)
                          Text(
                            '${product.availableStock} en stock',
                            style: TextStyle(
                              fontSize: 12,
                              color: product.isLowStock ? Colors.orange : Colors.grey[600],
                            ),
                          )
                        else
                          Text(
                            'Rupture',
                            style: TextStyle(fontSize: 12, color: Colors.red[600]),
                          ),
                        const SizedBox(width: 8),
                        if (product.viewCount > 0) ...[
                          Icon(Icons.remove_red_eye_outlined, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 2),
                          Text(
                            '${product.viewCount}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
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
