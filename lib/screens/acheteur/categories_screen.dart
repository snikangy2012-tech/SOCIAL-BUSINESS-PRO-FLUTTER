// ===== lib/screens/acheteur/categories_screen.dart =====
// Écran catégories - Design SmarterVision - SOCIAL BUSINESS Pro

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:social_business_pro/config/constants.dart';
import '../../config/product_categories.dart';
import '../../config/product_subcategories.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider_firebase.dart';
import '../../widgets/system_ui_scaffold.dart';
import '../../widgets/main_drawer.dart';
import '../../widgets/filter_drawer.dart';
import '../../widgets/category_banner.dart'; // Pour les couleurs uniquement

class CategoriesScreen extends StatefulWidget {
  final String? initialCategory;

  const CategoriesScreen({super.key, this.initialCategory});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return SystemUIScaffold(
      key: _scaffoldKey,
      drawer: const MainDrawer(),
      endDrawer: const FilterDrawer(),
      body: CustomScrollView(
        slivers: [
          // AppBar
          SliverAppBar(
            floating: true,
            pinned: true,
            backgroundColor: AppColors.primary,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.white),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            title: const Text(
              'Categories',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
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
                              style: const TextStyle(
                                color: AppColors.primary,
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
                            ? const Icon(Icons.person_rounded, color: AppColors.primary, size: 20)
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ],
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
                    suffixIcon: IconButton(
                      icon: Icon(Icons.tune_rounded, color: Colors.grey[600]),
                      onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
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

          // Liste des catégories
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final category = ProductCategories.allCategories[index];
                  final subcategories = ProductSubcategories.getSubcategories(category.id);
                  final isEven = index % 2 == 0;

                  return _buildCategoryCard(
                    category: category,
                    subcategories: subcategories,
                    imageOnLeft: isEven,
                  );
                },
                childCount: ProductCategories.allCategories.length,
              ),
            ),
          ),

          // Espace en bas
          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard({
    required ProductCategory category,
    required List<String> subcategories,
    required bool imageOnLeft,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Image/Icône à gauche ou droite
            if (imageOnLeft) _buildCategoryImage(category),

            // Sous-catégories
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: subcategories
                      .where((subcat) => !subcat.toLowerCase().contains('autre'))
                      .take(8)
                      .map((subcat) {
                    return InkWell(
                      onTap: () {
                        // Navigation vers les produits de cette sous-catégorie
                        context.push('/acheteur/products?category=${category.id}&subcategory=$subcat');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Text(
                          subcat,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Image/Icône à droite si pas à gauche
            if (!imageOnLeft) _buildCategoryImage(category),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryImage(ProductCategory category) {
    // Utiliser les couleurs des bannières pour uniformiser
    final gradientColors = CategoryBannerConfig.getGradient(category.id);

    return InkWell(
      onTap: () {
        // Navigation vers tous les produits de cette catégorie
        context.push('/acheteur/products?category=${category.id}');
      },
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              category.icon,
              size: 48,
              color: Colors.white,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                category.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
