// ===== lib/screens/acheteur/acheteur_home.dart =====
// Page d'accueil acheteur - SOCIAL BUSINESS Pro
// 🎨 VERSION COMPLÈTE ET CORRIGÉE

import 'package:flutter/material.dart';

import 'package:shimmer/shimmer.dart';
import 'dart:async';

import '../../config/constants.dart';

import '../../models/product_model.dart';
import '../../services/product_service.dart';
import '../../services/analytics_service.dart';

class AcheteurHome extends StatefulWidget {
  const AcheteurHome({super.key});

  @override
  State<AcheteurHome> createState() => _AcheteurHomeState();
}

class _AcheteurHomeState extends State<AcheteurHome> {
  final TextEditingController _searchController = TextEditingController();
  final ProductService _productService = ProductService();
  final AnalyticsService _analytics = AnalyticsService();
  final PageController _bannerController = PageController();

  List<ProductModel> _products = [];
  List<ProductModel> _flashSaleProducts = [];
  List<ProductModel> _newProducts = [];
  bool _isLoading = true;
  final int _currentBannerIndex = 0;
  Timer? _bannerTimer;

  // ✅ Bannières promotionnelles (corrigé)
  final List<String> _banners = [
    'https://picsum.photos/800/300?random=1',
    'https://picsum.photos/800/300?random=2',
    'https://picsum.photos/800/300?random=3',
  ];

  @override
  void initState() {
    super.initState();

    // ✅ Logger la vue de l'écran
    _analytics.logScreenView('AcheteurHome');

    _loadProducts();
    _startBannerTimer();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bannerController.dispose();
    _bannerTimer?.cancel(); // ✅ CORRECTION : Annuler le timer
    super.dispose();
  }

  // Charger les produits
  Future<void> _loadProducts() async {
    if (!mounted) return; // ✅ Vérifier mounted avant setState

    setState(() => _isLoading = true);

    try {
      final products = await _productService.getProducts();

      if (!mounted) return; // ✅ Vérifier mounted après async

      setState(() {
        _products = products;
        _flashSaleProducts = products.where((p) => p.isFlashSale).toList();
        _newProducts = products.where((p) => p.isNew).toList();
      });
    } catch (e) {
      debugPrint('Erreur chargement produits: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement: ${e.toString()}'),
            backgroundColor: AppColors.error,
            action: SnackBarAction(
              label: 'Réessayer',
              textColor: Colors.white,
              onPressed: _loadProducts,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Timer pour le carousel de bannières
  void _startBannerTimer() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_bannerController.hasClients) {
        final nextPage = (_currentBannerIndex + 1) % _banners.length;
        _bannerController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadProducts,
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ✅ HEADER MODERNE AVEC GRADIENT
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: AppColors.primary,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withValues(alpha: 0.8),
                        AppColors.secondary.withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Logo et Slogan
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.storefront,
                                  color: AppColors.primary,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'SOCIAL BUSINESS',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    Text(
                                      'Achetez et vendez facilement',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Barre de recherche moderne
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Rechercher un produit...',
                                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.tune, color: AppColors.primary),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Filtres')),
                                    );
                                  },
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 15,
                                ),
                              ),
                              onSubmitted: (value) {
                                // TODO: Recherche
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ✅ BANNIÈRE PROMOTIONNELLE
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                height: 200, // ✅ Augmenté à 200 pour éviter l'overflow définitivement
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.secondary,
                      AppColors.secondary.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      bottom: -30,
                      child: Icon(
                        Icons.shopping_bag,
                        size: 150,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20), // ✅ Réduit de 24 à 20
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warning,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '🔥 OFFRE SPÉCIALE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10), // ✅ Réduit de 12 à 10
                          const Text(
                            'Jusqu\'à -50%',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'sur tous les smartphones',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 10), // ✅ Réduit de 12 à 10
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.secondary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Découvrir'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ✅ CATÉGORIES RAPIDES
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Text(
                      'Catégories populaires',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 100,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: [
                        _buildQuickCategory('Électronique', Icons.devices, AppColors.primary),
                        _buildQuickCategory('Mode', Icons.shopping_bag, AppColors.secondary),
                        _buildQuickCategory('Maison', Icons.home, AppColors.success),
                        _buildQuickCategory('Beauté', Icons.face, AppColors.warning),
                        _buildQuickCategory('Sport', Icons.sports_soccer, AppColors.info),
                        _buildQuickCategory('Livres', Icons.menu_book, AppColors.error),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ✅ TITRE PRODUITS
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Produits recommandés',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Voir tout',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ✅ SECTION FLASH SALE
            if (_flashSaleProducts.isNotEmpty) ...[
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.flash_on, color: AppColors.error, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Ventes Flash',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        // TODO: Navigation vers page flash sale
                      },
                      child: const Text('Voir tout'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 240,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _flashSaleProducts.length,
                  itemBuilder: (context, index) {
                    final product = _flashSaleProducts[index];
                    return _buildHorizontalProductCard(product);
                  },
                ),
              ),
            ],

            // ✅ SECTION NOUVEAUTÉS
            if (_newProducts.isNotEmpty) ...[
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.new_releases, color: AppColors.success, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Nouveautés',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        // TODO: Navigation vers page nouveautés
                      },
                      child: const Text('Voir tout'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 240,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _newProducts.length,
                  itemBuilder: (context, index) {
                    final product = _newProducts[index];
                    return _buildHorizontalProductCard(product);
                  },
                ),
              ),
            ],

            // ✅ GRILLE PRODUITS MODERNE
            _isLoading
                ? SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.7,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildProductSkeleton(),
                        childCount: 6,
                      ),
                    ),
                  )
                : _products.isEmpty
                    ? SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: 80,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Aucun produit disponible',
                                  style: TextStyle(fontSize: 18),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
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
                              return _buildModernProductCard(product);
                            },
                            childCount: _products.length,
                          ),
                        ),
                      ),
          ],
        ),
      ),
    );
  }

  // Widget catégorie rapide
  Widget _buildQuickCategory(String name, IconData icon, Color color) {
    return Container(
      width: 80,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Skeleton loading moderne
  Widget _buildProductSkeleton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 140,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 80,
                    height: 12,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Carte produit moderne
  Widget _buildModernProductCard(dynamic product) {
    return InkWell(
      onTap: () {
        // TODO: Navigation vers détail
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              // ignore: deprecated_member_use
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
                Container(
                  height: 140,
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
                ),
                
                // Badge réduction
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '-20%',
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
                      Icons.favorite_border,
                      size: 18,
                      color: Colors.grey[600],
                    ),
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
                    Text(
                      product['name'] ?? 'Produit',
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
                    const Spacer(),
                    const Text(
                      '125 000 FCFA',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
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

  // Carte produit horizontale
  Widget _buildHorizontalProductCard(ProductModel product) {
    return Container(
      width: 160,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: () {
          // TODO: Navigation vers détail produit
        },
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
                  Container(
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
                  ),
                  
                  // Badge flash sale ou new
                  if (product.isFlashSale)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '🔥 FLASH',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  
                  if (product.isNew && !product.isFlashSale)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'NEW',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  
                  // Bouton favori
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
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
                        Icons.favorite_border,
                        size: 16,
                        color: Colors.grey[600],
                      ),
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
                    const SizedBox(height: 4),
                    Text(
                      '${product.price.toStringAsFixed(0)} F',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    if (product.originalPrice != null)
                      Text(
                        '${product.originalPrice!.toStringAsFixed(0)} F',
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
      ),
    );
  }
}