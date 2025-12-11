// ===== lib/screens/acheteur/favorite_screen.dart =====
// Écran des favoris avec onglets Produits et Vendeurs - SOCIAL BUSINESS Pro

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:social_business_pro/config/constants.dart';
import '../../providers/auth_provider_firebase.dart' as auth;
import '../../providers/favorite_provider.dart';
import '../../models/product_model.dart';
import '../../models/user_model.dart';
import '../../services/product_service.dart';
import '../../services/firebase_service.dart';
import '../../utils/number_formatter.dart';
import 'vendors_list_screen.dart';
import 'vendor_shop_screen.dart';
import '../widgets/system_ui_scaffold.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ProductService _productService = ProductService();
  Timer? _refreshTimer;
  final _refreshInterval = const Duration(seconds: 30);

  List<ProductModel> _favoriteProducts = [];
  List<UserModel> _favoriteVendors = [];
  bool _isLoadingProducts = false;
  bool _isLoadingVendors = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFavorites();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(_refreshInterval, (timer) {
      if (mounted) {
        debugPrint('🔄 Auto-refresh favorites');
        _loadFavorites();
      }
    });
  }

  Future<void> _loadFavorites() async {
    final favoriteProvider = context.read<FavoriteProvider>();

    // Charger les produits favoris
    setState(() => _isLoadingProducts = true);
    try {
      final allProducts = await _productService.getProducts();
      _favoriteProducts = allProducts
          .where((p) => favoriteProvider.isFavorite(p.id))
          .toList();
    } catch (e) {
      debugPrint('❌ Erreur chargement produits favoris: $e');
    } finally {
      if (mounted) setState(() => _isLoadingProducts = false);
    }

    // Charger les vendeurs favoris
    setState(() => _isLoadingVendors = true);
    try {
      final vendorsList = <UserModel>[];
      for (final vendorId in favoriteProvider.favoriteVendorIds) {
        try {
          final vendor = await FirebaseService.getUserData(vendorId);
          if (vendor != null && vendor.userType == UserType.vendeur) {
            vendorsList.add(vendor);
          }
        } catch (e) {
          debugPrint('❌ Erreur chargement vendeur $vendorId: $e');
        }
      }
      _favoriteVendors = vendorsList;
    } catch (e) {
      debugPrint('❌ Erreur chargement vendeurs favoris: $e');
    } finally {
      if (mounted) setState(() => _isLoadingVendors = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<auth.AuthProvider>();
    final favoriteProvider = context.watch<FavoriteProvider>();
    final isAuthenticated = authProvider.isAuthenticated;

    return SystemUIScaffold(
      appBar: AppBar(
        title: const Text('Mes Favoris'),
        backgroundColor: AppColors.primary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: [
            Tab(
              icon: const Icon(Icons.favorite),
              text: 'Produits (${favoriteProvider.productCount})',
            ),
            Tab(
              icon: const Icon(Icons.store),
              text: 'Vendeurs (${favoriteProvider.vendorCount})',
            ),
          ],
        ),
      ),
      body: !isAuthenticated
          ? _buildLoginPrompt()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildProductsTab(favoriteProvider),
                _buildVendorsTab(favoriteProvider),
              ],
            ),
    );
  }

  // ===== ONGLET PRODUITS =====
  Widget _buildProductsTab(FavoriteProvider favoriteProvider) {
    if (_isLoadingProducts) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_favoriteProducts.isEmpty) {
      return _buildEmptyState(
        icon: Icons.favorite_outline,
        title: 'Aucun produit favori',
        message: 'Les produits que vous ajoutez aux favoris apparaîtront ici',
        actionLabel: 'Découvrir des produits',
        onAction: () => context.go('/'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFavorites,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _favoriteProducts.length,
        itemBuilder: (context, index) {
          final product = _favoriteProducts[index];
          return _buildProductCard(product, favoriteProvider);
        },
      ),
    );
  }

  Widget _buildProductCard(ProductModel product, FavoriteProvider favoriteProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => context.push('/product/${product.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 100,
                  height: 100,
                  color: AppColors.backgroundSecondary,
                  child: product.images.isNotEmpty
                      ? Image.network(
                          product.images.first,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 40),
                        )
                      : const Icon(Icons.image, size: 40),
                ),
              ),
              const SizedBox(width: 12),
              // Infos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.vendeurName,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formatPriceWithCurrency(product.price, currency: 'FCFA'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Badge de stock
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: product.isOutOfStock
                            ? AppColors.error.withValues(alpha: 0.1)
                            : product.isLowStock
                                ? AppColors.warning.withValues(alpha: 0.1)
                                : AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            product.isOutOfStock
                                ? Icons.cancel_outlined
                                : product.isLowStock
                                    ? Icons.warning_amber_outlined
                                    : Icons.check_circle_outlined,
                            size: 14,
                            color: product.isOutOfStock
                                ? AppColors.error
                                : product.isLowStock
                                    ? AppColors.warning
                                    : AppColors.success,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            product.isOutOfStock
                                ? 'Rupture de stock'
                                : product.isLowStock
                                    ? 'Stock faible (${product.availableStock})'
                                    : '${product.availableStock} en stock',
                            style: TextStyle(
                              fontSize: 12,
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
              ),
              // Bouton supprimer
              IconButton(
                icon: const Icon(Icons.favorite, color: AppColors.error),
                onPressed: () async {
                  try {
                    await favoriteProvider.toggleFavorite(product.id, product.name);
                    _loadFavorites();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Retiré des favoris'),
                          duration: Duration(seconds: 1),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== ONGLET VENDEURS =====
  Widget _buildVendorsTab(FavoriteProvider favoriteProvider) {
    if (_isLoadingVendors) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_favoriteVendors.isEmpty) {
      return _buildEmptyState(
        icon: Icons.store_outlined,
        title: 'Aucun vendeur favori',
        message: 'Les vendeurs que vous ajoutez aux favoris apparaîtront ici',
        actionLabel: 'Découvrir des vendeurs',
        onAction: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const VendorsListScreen(),
            ),
          );
        },
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFavorites,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _favoriteVendors.length,
        itemBuilder: (context, index) {
          final vendor = _favoriteVendors[index];
          return _buildVendorCard(vendor, favoriteProvider);
        },
      ),
    );
  }

  Widget _buildVendorCard(UserModel vendor, FavoriteProvider favoriteProvider) {
    // Extraire les données du profil vendeur depuis le Map
    final profileData = vendor.profile;
    if (profileData.isEmpty) return const SizedBox.shrink();

    // Récupérer les données du profil vendeur
    final vendeurProfileData = profileData['vendeurProfile'] as Map<String, dynamic>?;
    if (vendeurProfileData == null) return const SizedBox.shrink();

    final businessName = vendeurProfileData['businessName'] as String? ?? vendor.displayName;
    final businessCategory = vendeurProfileData['businessCategory'] as String? ?? 'Commerce';
    final stats = vendeurProfileData['stats'] as Map<String, dynamic>? ?? {};
    final averageRating = (stats['averageRating'] as num?)?.toDouble() ?? 0.0;
    final totalProducts = stats['totalProducts'] as int? ?? 0;

    // Protection contre businessName vide
    final initial = businessName.isEmpty ? '?' : businessName.substring(0, 1).toUpperCase();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              // Avatar
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Infos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      businessName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      businessCategory,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star, color: AppColors.warning, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          averageRating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$totalProducts produits',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Bouton supprimer
              IconButton(
                icon: const Icon(Icons.favorite, color: AppColors.error),
                onPressed: () async {
                  try {
                    await favoriteProvider.toggleFavoriteVendor(
                      vendor.id,
                      businessName,
                    );
                    _loadFavorites();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Vendeur retiré des favoris'),
                          duration: Duration(seconds: 1),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== ÉTAT VIDE =====
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 100, color: Colors.grey[300]),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.shopping_bag),
              label: Text(actionLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== INVITE À SE CONNECTER =====
  Widget _buildLoginPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_outline, size: 100, color: Colors.grey[300]),
            const SizedBox(height: 24),
            const Text(
              'Connectez-vous pour voir vos favoris',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Enregistrez vos produits et vendeurs préférés',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.push('/login'),
              icon: const Icon(Icons.login),
              label: const Text('Se connecter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
