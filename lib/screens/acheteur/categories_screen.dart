// ===== lib/screens/acheteur/categories_screen.dart =====
// Écran catégories style Jumia - SOCIAL BUSINESS Pro

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:social_business_pro/config/constants.dart';
import '../../config/product_categories.dart';
import '../../config/product_subcategories.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart';
import '../../services/analytics_service.dart';
import '../../providers/cart_provider.dart';
import '../../providers/favorite_provider.dart';
import '../../widgets/custom_widgets.dart';
import '../../utils/image_helper.dart';
import '../../utils/number_formatter.dart';
import '../../widgets/system_ui_scaffold.dart';

class CategoriesScreen extends StatefulWidget {
  final String? initialCategory;

  const CategoriesScreen({super.key, this.initialCategory});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final ProductService _productService = ProductService();
  final AnalyticsService _analytics = AnalyticsService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _selectedCategory = 'mode';
  String _selectedSubcategory = 'Toutes'; // Filtre par sous-catégorie
  bool _isLoading = true;
  String _searchQuery = '';
  List<ProductModel> _allProducts = [];
  Map<String, int> _categoryCounts = {};
  Map<String, int> _subcategoryCounts = {}; // Compteur par sous-catégorie

  @override
  void initState() {
    super.initState();
    // Utiliser la catégorie initiale si fournie
    if (widget.initialCategory != null && widget.initialCategory!.isNotEmpty) {
      _selectedCategory = widget.initialCategory!;
    }
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await _productService.getProducts();

      // Calculer le nombre de produits par catégorie et sous-catégorie
      final counts = <String, int>{};
      final subCounts = <String, int>{};

      for (var product in products) {
        counts[product.category] = (counts[product.category] ?? 0) + 1;

        // Compter par sous-catégorie (avec clé "categorie:souscategorie")
        if (product.subCategory != null && product.subCategory!.isNotEmpty) {
          final key = '${product.category}:${product.subCategory}';
          subCounts[key] = (subCounts[key] ?? 0) + 1;
        }
      }

      setState(() {
        _allProducts = products;
        _categoryCounts = counts;
        _subcategoryCounts = subCounts;
        _isLoading = false;
      });

      debugPrint('✅ ${products.length} produits chargés');
      debugPrint('📊 Répartition: $_categoryCounts');
      debugPrint('📊 Sous-catégories: $_subcategoryCounts');
    } catch (e) {
      debugPrint('❌ Erreur chargement produits: $e');
      setState(() => _isLoading = false);
    }
  }

  List<ProductModel> _getProductsForCategory(String categoryId, {String? subcategory}) {
    var filtered =
        _allProducts.where((product) => product.category.toLowerCase() == categoryId.toLowerCase());

    // Filtrer par sous-catégorie si spécifiée
    if (subcategory != null && subcategory != 'Toutes') {
      filtered = filtered
          .where((product) => product.subCategory?.toLowerCase() == subcategory.toLowerCase());
    }

    return filtered.toList();
  }

  int _getSubcategoryCount(String categoryId, String subcategory) {
    if (subcategory == 'Toutes') {
      return _categoryCounts[categoryId] ?? 0;
    }
    final key = '$categoryId:$subcategory';
    return _subcategoryCounts[key] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return SystemUIScaffold(
      key: _scaffoldKey,
      appBar: _buildAppBar(),
      drawer: _buildCategoryDrawer(),
      body: Column(
        children: [
          _buildSearchBar(), // ✅ AJOUTER
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  // ===== APP BAR =====
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: AppColors.primary,
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      title: const Text(
        'Catégories',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            // Navigation vers l'écran de recherche
            context.push('/acheteur/search');
          },
        ),
      ],
    );
  }

  // ===== BARRE DE RECHERCHE =====
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: Colors.white,
      child: TextField(
        onChanged: (value) {
          setState(() => _searchQuery = value.toLowerCase());
        },
        decoration: InputDecoration(
          hintText: 'Rechercher une catégorie...',
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.backgroundSecondary,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
        ),
      ),
    );
  }

  // ===== DRAWER - MENU LATÉRAL =====
  Widget _buildCategoryDrawer() {
    return Drawer(
      child: Column(
        children: [
          // En-tête du drawer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 50,
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: AppSpacing.lg,
            ),
            color: AppColors.primary,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.category, color: Colors.white, size: 32),
                SizedBox(height: AppSpacing.sm),
                Text(
                  'Toutes les catégories',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Liste des catégories
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: ProductCategories.allCategories.map((category) {
                final isSelected = _selectedCategory == category.id;
                return ListTile(
                  leading: Text(
                    category.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(
                    category.name,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  selected: isSelected,
                  selectedTileColor: AppColors.primaryLight.withValues(alpha: 0.3),
                  onTap: () {
                    setState(() {
                      _selectedCategory = category.id;
                      _selectedSubcategory = 'Toutes'; // Reset sous-catégorie
                    });
                    Navigator.pop(context); // Fermer le drawer
                    _analytics.logSearch(category.name, category.id);
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ===== CORPS DE LA PAGE =====
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final selectedCategoryData =
        ProductCategories.allCategories.firstWhere((cat) => cat.id == _selectedCategory);

    // Obtenir les sous-catégories disponibles pour cette catégorie
    final availableSubcategories =
        ['Toutes'] + ProductSubcategories.getSubcategories(_selectedCategory);

    final categoryProducts = _getProductsForCategory(
      _selectedCategory,
      subcategory: _selectedSubcategory,
    );

    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: categoryProducts.isEmpty
          ? _buildEmptyState(selectedCategoryData)
          : CustomScrollView(
              slivers: [
                // En-tête de la catégorie sélectionnée
                SliverToBoxAdapter(
                  child: _buildCategoryHeader(selectedCategoryData),
                ),

                // Filtre par sous-catégories
                SliverToBoxAdapter(
                  child: _buildSubcategoryFilter(availableSubcategories),
                ),

                // Titre de la section
                SliverToBoxAdapter(
                  child: _buildSectionHeader(
                    _selectedSubcategory == 'Toutes'
                        ? 'Produits ${selectedCategoryData.name}'
                        : _selectedSubcategory,
                    '${categoryProducts.length} article${categoryProducts.length > 1 ? "s" : ""}',
                  ),
                ),

                // Grille de produits réels
                SliverPadding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: AppSpacing.md,
                      mainAxisSpacing: AppSpacing.md,
                      childAspectRatio:
                          0.55, // ✅ CORRECTION: 0.55 pour carte complète avec tous les éléments
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildProductCard(categoryProducts[index]),
                      childCount: categoryProducts.length,
                    ),
                  ),
                ),

                // Espace en bas
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.xl),
                ),
              ],
            ),
    );
  }

  // ===== FILTRE SOUS-CATÉGORIES =====
  Widget _buildSubcategoryFilter(List<String> subcategories) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: subcategories.length,
        itemBuilder: (context, index) {
          final subcategory = subcategories[index];
          final isSelected = _selectedSubcategory == subcategory;
          final count = _getSubcategoryCount(_selectedCategory, subcategory);

          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: FilterChip(
              label: Text('$subcategory ($count)'),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedSubcategory = subcategory;
                });
                _analytics.logSearch(subcategory, _selectedCategory);
              },
              backgroundColor: Colors.white,
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.border,
              ),
            ),
          );
        },
      ),
    );
  }

  // ===== EN-TÊTE DE CATÉGORIE =====
  Widget _buildCategoryHeader(ProductCategory category) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.7),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                category.icon,
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_categoryCounts[category.id] ?? 0} produits disponibles',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===== TITRE DE SECTION =====
  Widget _buildSectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ===== ÉTAT VIDE =====
  Widget _buildEmptyState(ProductCategory category) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            category.icon,
            style: const TextStyle(fontSize: 80),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Aucun produit dans ${category.name}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Les produits seront affichés ici dès qu\'ils seront ajoutés',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ===== CARTE PRODUIT =====
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Prix actuel
                            Text(
                              formatPriceWithCurrency(product.price, currency: 'FCFA'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            // Prix original barré si promo
                            if (product.hasPromotion)
                              Text(
                                formatPriceWithCurrency(product.originalPrice!, currency: 'FCFA'),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                          ],
                        ),
                        Consumer<CartProvider>(
                          builder: (context, cartProvider, _) {
                            return GestureDetector(
                              onTap: () async {
                                try {
                                  await cartProvider.addProduct(product);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Ajouté au panier'),
                                        duration: Duration(seconds: 1),
                                        backgroundColor: AppColors.success,
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
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.shopping_cart_outlined,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
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
