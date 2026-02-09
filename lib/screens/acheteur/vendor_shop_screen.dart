// ===== lib/screens/acheteur/vendor_shop_screen.dart =====
// Boutique d'un vendeur avec ses produits - Version améliorée

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/constants.dart';
import '../../models/product_model.dart';
import '../../models/review_model.dart';
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

class _VendorShopScreenState extends State<VendorShopScreen> with SingleTickerProviderStateMixin {
  final ReviewService _reviewService = ReviewService();
  final ProductService _productService = ProductService();

  Map<String, dynamic>? _vendorData;
  List<ProductModel> _products = [];
  List<ReviewModel> _reviews = [];
  bool _isLoading = true;
  bool _isFavorite = false;
  bool _isFollowing = false;
  String? _error;

  double _rating = 0.0;
  int _reviewsCount = 0;
  int _followersCount = 0;
  int _salesCount = 0;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadVendorData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
      _reviews = await _reviewService.getReviewsByVendor(widget.vendorId);
      _reviewsCount = _reviews.length;

      // Charger les produits du vendeur
      _products = await _productService.getVendorProducts(widget.vendorId);

      // Charger les statistiques
      await _loadVendorStats();

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

  Future<void> _loadVendorStats() async {
    try {
      // Compter le nombre de ventes (commandes livrées)
      final ordersSnapshot = await FirebaseFirestore.instance
          .collection(FirebaseCollections.orders)
          .where('vendeurId', isEqualTo: widget.vendorId)
          .where('status', isEqualTo: 'livree')
          .get();

      _salesCount = ordersSnapshot.docs.length;

      // Pour le MVP, on simule le nombre de followers (sera implémenté plus tard)
      _followersCount = (_salesCount * 1.5).round();
    } catch (e) {
      debugPrint('❌ Erreur chargement stats: $e');
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

  Future<void> _toggleFollow() async {
    setState(() {
      _isFollowing = !_isFollowing;
      if (_isFollowing) {
        _followersCount++;
      } else {
        _followersCount--;
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              _isFollowing ? 'Vous suivez cette boutique' : 'Vous ne suivez plus cette boutique'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _contactVendor() async {
    final profile = _vendorData?['profile'] as Map<String, dynamic>?;
    final phoneNumber = profile?['phoneNumber'] ?? _vendorData?['phoneNumber'];

    if (phoneNumber == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Numéro de téléphone non disponible'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    // Format WhatsApp URL (supprime les espaces et caractères spéciaux)
    final cleanNumber = phoneNumber.toString().replaceAll(RegExp(r'[^\d+]'), '');
    final whatsappUrl = Uri.parse('https://wa.me/$cleanNumber');

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('WhatsApp non installé');
      }
    } catch (e) {
      debugPrint('❌ Erreur ouverture WhatsApp: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossible d\'ouvrir WhatsApp: $e'),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/acheteur');
            }
          },
          tooltip: 'Retour',
        ),
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

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          // En-tête amélioré avec statistiques
          SliverToBoxAdapter(
            child: _buildEnhancedHeader(shopName, description),
          ),
          // CTA Buttons (Suivre, Contacter, Partager)
          SliverToBoxAdapter(
            child: _buildCTAButtons(),
          ),
          // Barre d'onglets sticky
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyTabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'Produits'),
                  Tab(text: 'Avis'),
                  Tab(text: 'À propos'),
                ],
              ),
            ),
          ),
        ];
      },
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProductsTab(),
          _buildReviewsTab(),
          _buildAboutTab(shopName, description),
        ],
      ),
    );
  }

  Widget _buildEnhancedHeader(String shopName, String description) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          // Photo avec badge vérifié
          Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 56,
                  backgroundImage: _vendorData?['photoURL'] != null
                      ? NetworkImage(_vendorData!['photoURL'])
                      : null,
                  child:
                      _vendorData?['photoURL'] == null ? const Icon(Icons.store, size: 50) : null,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(
                    Icons.verified,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Nom de la boutique
          Text(
            shopName,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Statistiques (Note, Followers, Ventes)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatChip(
                icon: Icons.star,
                label: _rating > 0 ? _rating.toStringAsFixed(1) : 'Nouveau',
                color: Colors.amber,
              ),
              const SizedBox(width: 16),
              _buildStatChip(
                icon: Icons.people,
                label: '$_followersCount',
                color: AppColors.info,
              ),
              const SizedBox(width: 16),
              _buildStatChip(
                icon: Icons.shopping_bag,
                label: '$_salesCount ventes',
                color: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Badge KYC vérifié
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_user,
                  size: 16,
                  color: AppColors.success,
                ),
                const SizedBox(width: 6),
                Text(
                  'KYC Vérifié',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCTAButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _toggleFollow,
              icon: Icon(
                _isFollowing ? Icons.check : Icons.person_add,
                size: 18,
              ),
              label: Text(_isFollowing ? 'Abonné' : 'Suivre'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isFollowing ? AppColors.success : AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: OutlinedButton.icon(
              onPressed: _contactVendor,
              icon: const Icon(Icons.chat, size: 18),
              label: const Text('WhatsApp'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green,
                side: const BorderSide(color: Colors.green),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () {
              // TODO: Implémenter le partage
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fonction de partage bientôt disponible')),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Icon(Icons.share, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    return CustomScrollView(
      slivers: [
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
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      // ✅ Créer une ligne de 2 produits (grille flexible avec hauteur auto)
                      final startIndex = index * 2;
                      if (startIndex >= _products.length) return null;

                      final product1 = _products[startIndex];
                      final product2 =
                          startIndex + 1 < _products.length ? _products[startIndex + 1] : null;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildProductCard(product1)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: product2 != null
                                  ? _buildProductCard(product2)
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: (_products.length / 2).ceil(),
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

            // Infos produit (sans Expanded pour hauteur flexible)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
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
                  const SizedBox(height: 8),
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
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsTab() {
    if (_reviews.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.rate_review_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Aucun avis pour le moment',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'Soyez le premier à laisser un avis!',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Note globale avec breakdown
          _buildReviewsBreakdown(),
          const SizedBox(height: 24),

          // Liste des avis
          const Text(
            'Avis des clients',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _reviews.length,
            separatorBuilder: (context, index) => const Divider(height: 24),
            itemBuilder: (context, index) {
              final review = _reviews[index];
              return _buildReviewCard(review);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsBreakdown() {
    // Calculer la distribution des notes
    final starsDistribution = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final review in _reviews) {
      final rating = review.rating.round().clamp(1, 5);
      starsDistribution[rating] = (starsDistribution[rating] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.all(16),
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
          // Note globale
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Text(
                  _rating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return Icon(
                      index < _rating.round() ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 20,
                    );
                  }),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_reviewsCount avis',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Distribution des étoiles
          Expanded(
            flex: 2,
            child: Column(
              children: [
                for (int stars = 5; stars >= 1; stars--)
                  _buildStarBar(stars, starsDistribution[stars] ?? 0, _reviewsCount),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarBar(int stars, int count, int total) {
    final percentage = total > 0 ? (count / total) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$stars',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.star, size: 12, color: Colors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 30,
            child: Text(
              '$count',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(ReviewModel review) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Text(
                review.reviewerName.isNotEmpty ? review.reviewerName[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review.reviewerName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Row(
                    children: [
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < review.rating.round() ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 14,
                          );
                        }),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatReviewDate(review.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        if (review.comment.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            review.comment,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }

  String _formatReviewDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 30) {
      return 'Il y a ${(difference.inDays / 30).floor()} mois';
    } else if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else {
      return 'À l\'instant';
    }
  }

  Widget _buildAboutTab(String shopName, String description) {
    final profile = _vendorData?['profile'] as Map<String, dynamic>?;
    final vendeurProfile = profile?['vendeurProfile'] as Map<String, dynamic>?;
    final createdAt = _vendorData?['createdAt'] as Timestamp?;
    final memberSince = createdAt != null ? createdAt.toDate() : DateTime.now();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section À propos
          const Text(
            'À propos de la boutique',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          if (description.isNotEmpty)
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
                height: 1.5,
              ),
            )
          else
            Text(
              'Aucune description disponible.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
          const SizedBox(height: 24),

          // Statistiques détaillées
          const Text(
            'Informations',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          _buildInfoCard(
            icon: Icons.calendar_today,
            title: 'Membre depuis',
            value: '${_getMonthName(memberSince.month)} ${memberSince.year}',
          ),
          const SizedBox(height: 8),
          _buildInfoCard(
            icon: Icons.inventory,
            title: 'Produits en vente',
            value: '${_products.length}',
          ),
          const SizedBox(height: 8),
          _buildInfoCard(
            icon: Icons.star,
            title: 'Note moyenne',
            value: _rating > 0 ? '${_rating.toStringAsFixed(1)}/5.0' : 'Nouveau vendeur',
          ),
          const SizedBox(height: 8),
          _buildInfoCard(
            icon: Icons.access_time,
            title: 'Temps de réponse',
            value: 'Moins de 24h',
          ),
          const SizedBox(height: 24),

          // Politiques
          const Text(
            'Politiques',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          _buildPolicyCard(
            icon: Icons.local_shipping,
            title: 'Livraison',
            description:
                'Livraison disponible dans toute la Côte d\'Ivoire. Frais calculés selon la distance.',
          ),
          const SizedBox(height: 8),
          _buildPolicyCard(
            icon: Icons.sync,
            title: 'Retours',
            description:
                'Retours acceptés dans les 7 jours suivant la réception. Produit non utilisé.',
          ),
          const SizedBox(height: 8),
          _buildPolicyCard(
            icon: Icons.payment,
            title: 'Paiement',
            description: 'Orange Money, MTN MoMo, Moov Money et Wave acceptés.',
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre'
    ];
    return months[month - 1];
  }

  Widget _buildInfoCard({required IconData icon, required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyCard(
      {required IconData icon, required String title, required String description}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: AppColors.info),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Delegate pour rendre la TabBar sticky
class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _StickyTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return false;
  }
}

