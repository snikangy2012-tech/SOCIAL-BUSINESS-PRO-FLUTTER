// ===== lib/screens/acheteur/acheteur_home.dart =====
// Page d'accueil acheteur - SOCIAL BUSINESS Pro
// 🎨 VERSION COMPLÈTE ET CORRIGÉE

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

import 'package:social_business_pro/config/constants.dart';
import 'package:social_business_pro/config/product_categories.dart';

import '../../models/product_model.dart';
import '../../services/product_service.dart';
import '../../services/analytics_service.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider_firebase.dart';
import '../../widgets/filter_drawer.dart';
import '../../widgets/main_drawer.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/custom_widgets.dart';
import '../../widgets/vendor_card_gradient.dart';
import '../../widgets/category_filter_chips.dart';
import '../../widgets/social_share_button.dart';
import '../../widgets/category_banner.dart';
import '../../utils/image_helper.dart';
import '../../utils/number_formatter.dart';
import '../../widgets/system_ui_scaffold.dart';

class AcheteurHome extends StatefulWidget {
  const AcheteurHome({super.key});

  @override
  State<AcheteurHome> createState() => _AcheteurHomeState();
}

class _AcheteurHomeState extends State<AcheteurHome> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  final ProductService _productService = ProductService();
  final AnalyticsService _analytics = AnalyticsService();
  final PageController _bannerController = PageController();

  List<ProductModel> _products = [];
  List<ProductModel> _flashSaleProducts = [];
  List<ProductModel> _newProducts = [];
  bool _isLoading = true;
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;
  String? _selectedCategory = ProductCategories.allCategories.first.id; // ✅ Première catégorie sélectionnée par défaut

  // ✅ Bannières de catégories avec images du carrousel et textes attractifs
  final List<Map<String, dynamic>> _banners = [
    {
      'categoryId': 'mode',
      'title': 'Mode & Style',
      'subtitle': 'Exprimez votre personnalité',
      'buttonText': 'Découvrir',
      'imagePath': 'assets/BANNIERE ET CATEGORIE/CARROUSSEL ACCUEIL/portrait-de-toute-la-longueur-de-la-belle-femme-brune-souriante-mignonne-heureuse-dans-des-vetements-d-ete-decontractes-hipster-vert-isole-sur-blanc-ecouter-de-la-musique-dans-un-smartphone-avec-un-casque.jpg',
    },
    {
      'categoryId': 'electronique',
      'title': 'High-Tech',
      'subtitle': 'Technologie de pointe',
      'buttonText': 'Explorer',
      'imagePath': 'assets/BANNIERE ET CATEGORIE/CARROUSSEL ACCUEIL/ELECTRONIQUE 2.jpg',
    },
    {
      'categoryId': 'alimentation',
      'title': 'Produits Frais',
      'subtitle': 'Qualité & Fraîcheur',
      'buttonText': 'Commander',
      'imagePath': 'assets/BANNIERE ET CATEGORIE/CARROUSSEL ACCUEIL/ALIMENTAIRE 2.jpg',
    },
    {
      'categoryId': 'beaute',
      'title': 'Beauté & Soins',
      'subtitle': 'Révélez votre éclat',
      'buttonText': 'Découvrir',
      'imagePath': 'assets/BANNIERE ET CATEGORIE/CARROUSSEL ACCUEIL/BEAUTE ET SOINS (2).jpg',
    },
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
      // ✅ Charger les produits avec filtre de catégorie si sélectionnée
      final products = await _productService.getProducts(
        category: _selectedCategory,
        isActive: true,
      );

      if (!mounted) return; // ✅ Vérifier mounted après async

      setState(() {
        // Séparer les produits spéciaux des produits généraux
        _flashSaleProducts = products.where((p) => p.isFlashSale).toList();

        // Nouveautés = produits créés dans les 7 derniers jours
        final now = DateTime.now();
        final sevenDaysAgo = now.subtract(const Duration(days: 7));
        _newProducts = products.where((p) {
          return p.createdAt.isAfter(sevenDaysAgo);
        }).toList();

        debugPrint('🆕 ${_newProducts.length} nouveautés (< 7 jours)');

        // Filtrer la liste principale pour exclure les produits déjà affichés
        // dans les sections spéciales (ventes flash et nouveautés)
        final specialProductIds = {
          ..._flashSaleProducts.map((p) => p.id),
          ..._newProducts.map((p) => p.id),
        };

        _products = products
            .where((p) => !specialProductIds.contains(p.id))
            .toList();

        debugPrint('📦 ${_flashSaleProducts.length} ventes flash, ${_newProducts.length} nouveautés, ${_products.length} autres produits${_selectedCategory != null ? ' (catégorie: $_selectedCategory)' : ''}');
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
    return SystemUIScaffold(
      key: _scaffoldKey,
      drawer: const MainDrawer(),
      endDrawer: const FilterDrawer(),
      body: RefreshIndicator(
        onRefresh: _loadProducts,
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ✅ HEADER STYLE DESIGN DE RÉFÉRENCE
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              leading: IconButton(
                icon: const Icon(Icons.menu_rounded, color: Colors.white),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              title: const Row(
                children: [
                  Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 32),
                  SizedBox(width: 8),
                  Text(
                    'SOCIAL BUSINESS',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              centerTitle: false,
              actions: [
                // Badge notification
                Consumer<NotificationProvider>(
                  builder: (context, notifProvider, child) {
                    final unreadCount = notifProvider.unreadCount;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                          onPressed: () {
                            // TODO: Navigation vers page notifications
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Notifications')),
                            );
                          },
                          tooltip: 'Notifications',
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            right: 4,
                            top: 4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              child: Text(
                                unreadCount > 9 ? '9+' : '$unreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
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
                // Bouton panier avec badge
                Consumer<CartProvider>(
                  builder: (context, cartProvider, child) {
                    final itemCount = cartProvider.totalQuantity;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                          onPressed: () => context.push('/acheteur/cart'),
                          tooltip: 'Panier',
                        ),
                        if (itemCount > 0)
                          Positioned(
                            right: 4,
                            top: 4,
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
                          
                          const SizedBox(height: 8),

                          // ✅ CORRECTION: Barre de recherche supprimée ici
                          // La barre de recherche pinnée en bas suffit
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ✅ BARRE DE RECHERCHE ÉPINGLÉE
            SliverAppBar(
              pinned: true,
              elevation: 2,
              backgroundColor: Colors.white,
              toolbarHeight: 80,
              automaticallyImplyLeading: false,
              actions: const [SizedBox.shrink()], // ✅ Empêche la génération automatique du bouton endDrawer
              flexibleSpace: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Rechercher un produit...',
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.tune_rounded, color: AppColors.primary),
                        onPressed: () {
                          _scaffoldKey.currentState?.openEndDrawer();
                        },
                        tooltip: 'Filtres',
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                    ),
                    onSubmitted: (value) {
                      context.push('/acheteur/search');
                    },
                    onTap: () {
                      context.push('/acheteur/search');
                    },
                    readOnly: true,
                  ),
                ),
              ),
            ),

            // ✅ BANNIÈRES DÉFILANTES (Carousel style Smarter)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                height: 180,
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: _bannerController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentBannerIndex = index;
                        });
                      },
                      itemCount: _banners.length,
                      itemBuilder: (context, index) {
                        return _buildBannerItem(_banners[index]);
                      },
                    ),
                    // Indicateurs de pagination
                    Positioned(
                      bottom: 12,
                      right: 20,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          _banners.length,
                          (index) => Container(
                            width: _currentBannerIndex == index ? 24 : 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: _currentBannerIndex == index
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ✅ GRILLE DE CATÉGORIES
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Catégories',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 4,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.85,
                      children: ProductCategories.allCategories.map((category) {
                        return _buildCategoryCard(category);
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            // ✅ VENDEURS PRÈS DE CHEZ VOUS
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 0, 16),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Vendeurs Près de Chez Vous',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              context.push('/acheteur/nearby-vendors');
                            },
                            child: const Text('Voir tout'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 220,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(left: 16),
                        itemCount: 5, // Pour démo
                        itemBuilder: (context, index) {
                          // Données de démo
                          final demoVendors = [
                            {'name': 'Fashion House', 'rating': 4.8, 'reviews': 156, 'distance': 0.5},
                            {'name': 'Tech Store CI', 'rating': 4.6, 'reviews': 89, 'distance': 1.2},
                            {'name': 'Bio Market', 'rating': 4.9, 'reviews': 203, 'distance': 0.8},
                            {'name': 'Électronique Pro', 'rating': 4.7, 'reviews': 134, 'distance': 1.5},
                            {'name': 'Beauté Express', 'rating': 4.5, 'reviews': 67, 'distance': 1.8},
                          ];

                          final vendor = demoVendors[index % demoVendors.length];
                          final badges = getVendorBadges(
                            isVerified: true,
                            rating: vendor['rating'] as double,
                            totalSales: vendor['reviews'] as int,
                            averageDeliveryTime: 25,
                            distance: vendor['distance'] as double,
                          );

                          return NearbyVendorCard(
                            vendorId: 'vendor_$index',
                            vendorName: vendor['name'] as String,
                            shopName: vendor['name'] as String,
                            rating: vendor['rating'] as double,
                            reviewsCount: vendor['reviews'] as int,
                            distance: vendor['distance'] as double,
                            badges: badges,
                            onTap: () {
                              context.push('/vendor/vendor_$index');
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ✅ SÉPARATEUR VISUEL
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(
                      thickness: 1,
                      color: Colors.grey[300],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),

            // ✅ SECTION FLASH SALE (déplacée AVANT Produits recommandés)
            if (_flashSaleProducts.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
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
                      height: 270, // ✅ CORRECTION: 270px pour éviter l'overflow (était 250px)
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
                ),
              ),
            ],

            // ✅ SECTION NOUVEAUTÉS
            if (_newProducts.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Column(
                  children: [
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
                      height: 270, // ✅ CORRECTION: 270px pour éviter l'overflow (était 250px)
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
                ),
              ),
            ],

            // Espacement entre sections
            const SliverToBoxAdapter(
              child: SizedBox(height: 24),
            ),

            // ✅ TITRE PRODUITS RECOMMANDÉS
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Produits recommandés',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    InkWell(
                      onTap: () => context.push('/categories'),
                      child: const Text(
                        'Voir tout',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ✅ MENU HORIZONTAL DES CATÉGORIES (dans section Produits recommandés)
            SliverToBoxAdapter(
              child: Container(
                height: 60,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary,
                    ],
                  ),
                ),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    // Catégories disponibles (sans l'option "Tous")
                    ...ProductCategories.allCategories.map((category) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildCategoryChip(
                          label: category.name,
                          icon: category.icon,
                          isSelected: _selectedCategory == category.id,
                          onTap: () {
                            setState(() {
                              _selectedCategory = category.id;
                            });
                            _loadProducts();
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // ✅ GRILLE PRODUITS MODERNE
            _isLoading
                ? SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.55, // ✅ CORRECTION: 0.55 pour carte complète avec tous les éléments
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
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                        sliver: SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.55, // ✅ CORRECTION: 0.55 pour carte complète avec tous les éléments
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
              height: 150, // ✅ Augmenté de 10px pour éviter l'overflow
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
  Widget _buildModernProductCard(ProductModel product) {
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
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
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
                          color: Colors.grey[200],
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 50,
                            color: Colors.grey[400],
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
                                    isFavorite
                                      ? 'Retiré des favoris'
                                      : 'Ajouté aux favoris',
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

                // Bouton de partage viral
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: ShareButton(
                    compact: true,
                    shareCount: product.shareCount,
                    onPressed: () {
                      _showShareDialog(product);
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
                        // Badge vérifié compact (pour démo - à remplacer par vraie logique)
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
                        Expanded(
                          child: Column(
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
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
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

  // Carte produit horizontale
  Widget _buildHorizontalProductCard(ProductModel product) {
    return Container(
      width: 160,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
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
                  // ✅ CORRECTION: Image avec placeholder valide au lieu de placeholder gris
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: Image.network(
                      ImageHelper.getValidImageUrl(
                        imageUrl: product.images.isNotEmpty ? product.images.first : null,
                        category: product.category,
                        index: product.hashCode % 4, // Variation d'image basée sur le produit
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
                  
                  // Badge FLASH SALE - Rouge attractif avec % de réduction
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

                  // Badge NEW (seulement si pas Flash Sale)
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

                  // Bouton favori (en haut à droite)
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
                                      isFavorite
                                          ? 'Retiré des favoris'
                                          : 'Ajouté aux favoris',
                                    ),
                                    duration: const Duration(seconds: 1),
                                    backgroundColor: isFavorite
                                        ? AppColors.textSecondary
                                        : AppColors.success,
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

                  // Bouton de partage en bas
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: ShareButton(
                      compact: true,
                      shareCount: product.shareCount,
                      onPressed: () {
                        _showShareDialog(product);
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
                    // Stats: Ventes + Rating (style design moderne)
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
      ),
    );
  }

  // Widget carte de catégorie
  Widget _buildCategoryCard(ProductCategory category) {
    // Définir les couleurs pour chaque catégorie
    final Map<String, Color> categoryColors = {
      'mode': const Color(0xFFE91E63),
      'electronique': const Color(0xFF2196F3),
      'alimentation': const Color(0xFF4CAF50),
      'maison': const Color(0xFFFF9800),
      'beaute': const Color(0xFF9C27B0),
      'sport': const Color(0xFFFF5722),
      'auto': const Color(0xFF607D8B),
      'services': const Color(0xFF00BCD4),
    };

    final color = categoryColors[category.id] ?? AppColors.primary;

    return InkWell(
      onTap: () {
        context.push('/categories', extra: category.id);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icône moderne Material (IconData)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                category.icon,
                size: 28,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            // Nom de la catégorie
            Text(
              category.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog de partage viral
  void _showShareDialog(ProductModel product) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Barre de titre
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Titre
            const Text(
              'Partager ce produit',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),

            // Options de partage
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildShareOption(
                  icon: Icons.message,
                  label: 'WhatsApp',
                  color: const Color(0xFF25D366),
                  onTap: () async {
                    Navigator.pop(context);
                    final message = '🛍️ Découvrez ce produit: ${product.name}\n💰 Prix: ${product.price.toStringAsFixed(0)} FCFA\n\n📱 Commandez sur SOCIAL BUSINESS Pro!';
                    final whatsappUrl = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(message)}');
                    if (await canLaunchUrl(whatsappUrl)) {
                      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('WhatsApp non disponible')),
                        );
                      }
                    }
                  },
                ),
                _buildShareOption(
                  icon: Icons.camera_alt,
                  label: 'TikTok',
                  color: Colors.black,
                  onTap: () async {
                    Navigator.pop(context);
                    final message = '🛍️ ${product.name} - ${product.price.toStringAsFixed(0)} FCFA sur SOCIAL BUSINESS Pro!';
                    await Share.share(message);
                  },
                ),
                _buildShareOption(
                  icon: Icons.photo_camera,
                  label: 'Instagram',
                  color: const Color(0xFFE4405F),
                  onTap: () async {
                    Navigator.pop(context);
                    final message = '🛍️ ${product.name} - ${product.price.toStringAsFixed(0)} FCFA sur SOCIAL BUSINESS Pro!';
                    await Share.share(message);
                  },
                ),
                _buildShareOption(
                  icon: Icons.facebook,
                  label: 'Facebook',
                  color: const Color(0xFF1877F2),
                  onTap: () async {
                    Navigator.pop(context);
                    final message = '🛍️ ${product.name} - ${product.price.toStringAsFixed(0)} FCFA sur SOCIAL BUSINESS Pro!';
                    await Share.share(message);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Bouton copier le lien
            TextButton.icon(
              onPressed: () async {
                final text = '🛍️ ${product.name} - ${product.price.toStringAsFixed(0)} FCFA\n📱 Commandez sur SOCIAL BUSINESS Pro!';
                await Clipboard.setData(ClipboardData(text: text));
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lien copié !')),
                  );
                }
              },
              icon: const Icon(Icons.link),
              label: const Text('Copier le lien'),
            ),
          ],
        ),
      ),
    );
  }

  // Widget option de partage
  Widget _buildShareOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Widget pour chip de catégorie horizontale
  // ✅ WIDGET POUR BANNIÈRE DÉFILANTE - Bannières avec images du carrousel
  Widget _buildBannerItem(Map<String, dynamic> banner) {
    final categoryId = banner['categoryId'] as String;
    final gradientColors = CategoryBannerConfig.getGradient(categoryId);
    final carouselImagePath = banner['imagePath'] as String?;

    return GestureDetector(
      onTap: () {
        context.push('/acheteur/products?category=$categoryId');
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Image du carrousel en plein écran
              if (carouselImagePath != null)
                Positioned.fill(
                  child: Image.asset(
                    carouselImagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // Si l'image n'existe pas, afficher le gradient
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: gradientColors,
                          ),
                        ),
                      );
                    },
                  ),
                )
              else
                // Gradient de fond si pas d'image
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradientColors,
                    ),
                  ),
                ),

              // Overlay gradient pour améliorer la lisibilité du texte
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.black.withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),

              // Contenu de la bannière
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      banner['title']!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 2),
                            blurRadius: 8,
                            color: Colors.black54,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      banner['subtitle']!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 1),
                            blurRadius: 4,
                            color: Colors.black45,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.push('/acheteur/products?category=$categoryId');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: gradientColors.first,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 6,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            banner['buttonText']!,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward, size: 18),
                        ],
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

  Widget _buildCategoryChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          // Inversé: blanc quand sélectionné, transparent sinon
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              // Inversé: vert quand sélectionné, blanc sinon
              color: isSelected ? AppColors.primary : Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                // Inversé: vert quand sélectionné, blanc sinon
                color: isSelected ? AppColors.primary : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}