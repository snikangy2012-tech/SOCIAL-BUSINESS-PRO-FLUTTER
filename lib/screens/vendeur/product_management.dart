// ===== lib/screens/vendeur/product_management.dart =====
// Écran de gestion des produits pour vendeurs - SOCIAL BUSINESS Pro

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:social_business_pro/providers/auth_provider_firebase.dart';

import 'package:social_business_pro/config/constants.dart';
import '../../models/product_model.dart';
import '../../models/audit_log_model.dart';
import '../../services/product_service.dart';
import '../../services/audit_service.dart';
import '../../config/product_categories.dart';
import '../../widgets/system_ui_scaffold.dart';

class ProductManagement extends StatefulWidget {
  const ProductManagement({super.key, required String storeId});

  @override
  State<ProductManagement> createState() => _ProductManagementState();
}

class _ProductManagementState extends State<ProductManagement> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _refreshTimer;
  final _refreshInterval = const Duration(seconds: 30);

  List<ProductModel> _products = [];
  List<ProductModel> _filteredProducts = [];
  bool _isLoading = true;
  String _selectedCategory = 'all';
  ProductStats? _stats;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterProducts);
    // Charger les produits après que le widget soit construit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProducts();
    });
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(_refreshInterval, (timer) {
      if (mounted) {
        debugPrint('🔄 Auto-refresh products');
        _loadProducts();
      }
    });
  }

  Future<void> _loadProducts() async {
    debugPrint('🔄 Début chargement produits');

    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final user = authProvider.user;

      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      // ✅ Option 1 : Charger depuis Firestore
      final products = await ProductService().getVendorProducts(user.id);

      if (mounted) {
        setState(() {
          _products = products;
          _filteredProducts = products;
        });
      }

      // ✅ Option 2 : Données MOCK pour les tests (DÉSACTIVÉ)
      /*
    await Future.delayed(const Duration(seconds: 1));
    
    if (!mounted) return;
    
    setState(() {
      _products = [
        ProductModel(
          id: '1',
          name: 'iPhone 15 Pro',
          description: 'Smartphone Apple dernière génération avec puce A17 Pro',
          price: 850000,
          originalPrice: 950000,
          category: 'Électronique',
          subCategory: 'Smartphones',
          brand: 'Apple',
          images: [
            'https://via.placeholder.com/300',
          ],
          stock: 10,
          sku: 'IPHONE-15-PRO-001',
          tags: ['smartphone', 'apple', 'nouveau', '5g'],
          isActive: true,
          isFeatured: true,
          isFlashSale: false,
          isNew: true,
          vendeurId: user.id,
          vendeurName: user.displayName,
          specifications: {
            'Écran': '6.1 pouces OLED',
            'Processeur': 'A17 Pro',
            'RAM': '8 GB',
            'Stockage': '256 GB',
            'Caméra': '48 MP',
          },
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
          updatedAt: DateTime.now(),
        ),
        
        ProductModel(
          id: '2',
          name: 'MacBook Pro M3',
          description: 'Ordinateur portable Apple avec puce M3',
          price: 1500000,
          originalPrice: null,
          category: 'Électronique',
          subCategory: 'Ordinateurs',
          brand: 'Apple',
          images: [
            'https://via.placeholder.com/300',
          ],
          stock: 5,
          sku: 'MACBOOK-PRO-M3-001',
          tags: ['ordinateur', 'laptop', 'apple', 'm3'],
          isActive: true,
          isFeatured: false,
          isFlashSale: false,
          isNew: false,
          vendeurId: user.id,
          vendeurName: user.displayName,
          specifications: {
            'Écran': '14 pouces Retina',
            'Processeur': 'Apple M3',
            'RAM': '16 GB',
            'Stockage': '512 GB SSD',
          },
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          updatedAt: DateTime.now(),
        ),
        
        ProductModel(
          id: '3',
          name: 'Samsung Galaxy S24 Ultra',
          description: 'Smartphone Samsung flagship avec S Pen',
          price: 650000,
          originalPrice: 750000,
          category: 'Électronique',
          subCategory: 'Smartphones',
          brand: 'Samsung',
          images: [
            'https://via.placeholder.com/300',
          ],
          stock: 8,
          sku: 'GALAXY-S24-ULTRA-001',
          tags: ['smartphone', 'samsung', 'android', '5g'],
          isActive: true,
          isFeatured: false,
          isFlashSale: true,
          isNew: false,
          vendeurId: user.id,
          vendeurName: user.displayName,
          specifications: {
            'Écran': '6.8 pouces AMOLED',
            'Processeur': 'Snapdragon 8 Gen 3',
            'RAM': '12 GB',
            'Stockage': '256 GB',
            'Caméra': '200 MP',
          },
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
          updatedAt: DateTime.now(),
        ),
        
        ProductModel(
          id: '4',
          name: 'AirPods Pro 2',
          description: 'Écouteurs sans fil Apple avec réduction de bruit',
          price: 180000,
          originalPrice: 200000,
          category: 'Électronique',
          subCategory: 'Audio',
          brand: 'Apple',
          images: [
            'https://via.placeholder.com/300',
          ],
          stock: 15,
          sku: 'AIRPODS-PRO-2-001',
          tags: ['écouteurs', 'audio', 'apple', 'wireless'],
          isActive: true,
          isFeatured: true,
          isFlashSale: true,
          isNew: false,
          vendeurId: user.id,
          vendeurName: user.displayName,
          specifications: {
            'Type': 'Sans fil',
            'Réduction de bruit': 'Active',
            'Autonomie': '6 heures',
            'Boîtier': '30 heures',
          },
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          updatedAt: DateTime.now(),
        ),
      ];

      _filteredProducts = _products;
    });
    */

      debugPrint('✅ Produits chargés: ${_products.length}');
    } catch (e) {
      debugPrint('❌ Erreur chargement produits: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      // ✅ TOUJOURS arrêter le loading
      debugPrint('🏁 Arrêt loading produits');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Filtrer les produits selon la recherche et la catégorie
  void _filterProducts() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _filteredProducts = _products.where((product) {
        // Filtrer par recherche
        final matchesSearch = query.isEmpty ||
            product.name.toLowerCase().contains(query) ||
            product.description.toLowerCase().contains(query) ||
            product.category.toLowerCase().contains(query);

        // Filtrer par catégorie
        final matchesCategory = _selectedCategory == 'all' || product.category == _selectedCategory;

        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  // Basculer le statut actif/inactif d'un produit
  Future<void> _toggleProductStatus(String productId, bool newStatus) async {
    try {
      debugPrint('🔄 Modification statut produit $productId: $newStatus');

      // TODO: Mettre à jour dans Firestore
      // await ProductService().updateProduct(productId, {'isActive': newStatus});

      // Simuler pour le moment
      await Future.delayed(const Duration(milliseconds: 300));

      // Mettre à jour localement
      if (mounted) {
        setState(() {
          final index = _products.indexWhere((p) => p.id == productId);
          if (index != -1) {
            // Créer une copie avec le nouveau statut
            _products[index] = ProductModel(
              id: _products[index].id,
              name: _products[index].name,
              description: _products[index].description,
              price: _products[index].price,
              originalPrice: _products[index].originalPrice,
              category: _products[index].category,
              subCategory: _products[index].subCategory,
              brand: _products[index].brand,
              images: _products[index].images,
              stock: _products[index].stock,
              sku: _products[index].sku,
              tags: _products[index].tags,
              isActive: newStatus, // ✅ Nouveau statut
              isFeatured: _products[index].isFeatured,
              isFlashSale: _products[index].isFlashSale,
              isNew: _products[index].isNew,
              vendeurId: _products[index].vendeurId,
              vendeurName: _products[index].vendeurName,
              specifications: _products[index].specifications,
              createdAt: _products[index].createdAt,
              updatedAt: DateTime.now(),
            );

            // Mettre à jour aussi la liste filtrée
            _filterProducts();
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus ? 'Produit activé' : 'Produit désactivé',
            ),
            backgroundColor: newStatus ? AppColors.success : Colors.grey,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      debugPrint('✅ Statut modifié');
    } catch (e) {
      debugPrint('❌ Erreur modification statut: $e');

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

// Supprimer un produit
  Future<void> _deleteProduct(String productId, String productName) async {
    try {
      debugPrint('🗑️ Suppression produit $productId');

      // Récupérer authProvider avant les appels async
      final authProvider = context.read<AuthProvider>();

      // TODO: Supprimer de Firestore
      // await ProductService().deleteProduct(productId);

      // Simuler pour le moment
      await Future.delayed(const Duration(milliseconds: 500));

      // Logger la suppression du produit
      if (authProvider.user != null) {
        await AuditService.log(
          userId: authProvider.user!.id,
          userType: authProvider.user!.userType.value,
          userEmail: authProvider.user!.email,
          userName: authProvider.user!.displayName,
          action: 'product_deleted',
          actionLabel: 'Suppression de produit',
          category: AuditCategory.userAction,
          severity: AuditSeverity.medium,
          description: 'Suppression du produit "$productName"',
          targetType: 'product',
          targetId: productId,
          targetLabel: productName,
          metadata: {
            'productId': productId,
            'productName': productName,
          },
        );
      }

      // Supprimer localement
      if (mounted) {
        setState(() {
          _products.removeWhere((p) => p.id == productId);
          _filteredProducts.removeWhere((p) => p.id == productId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produit supprimé'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }

      debugPrint('✅ Produit supprimé');
    } catch (e) {
      debugPrint('❌ Erreur suppression: $e');

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
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        title: const Text('Mes Produits'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadProducts,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Statistiques
                _buildStatsSection(),

                // Filtres et recherche
                _buildFiltersSection(),

                // Liste des produits
                Expanded(
                  child: _filteredProducts.isEmpty ? _buildEmptyState() : _buildProductsList(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/vendeur/add-product');
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
    );
  }

  // Section statistiques
  Widget _buildStatsSection() {
    if (_stats == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStatItem('Total', '${_stats!.totalProducts}', AppColors.primary),
          _buildStatItem('Actifs', '${_stats!.activeProducts}', AppColors.success),
          _buildStatItem('Rupture', '${_stats!.outOfStock}', AppColors.error),
          _buildStatItem('Stock faible', '${_stats!.lowStock}', AppColors.warning),
        ],
      ),
    );
  }

  Widget _buildProductsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: AppFontSizes.lg,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: AppFontSizes.sm,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // Section filtres
  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        children: [
          // Barre de recherche
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher un produit...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Filtres catégories
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryFilter('all', 'Tous'),
                ...ProductCategories.allCategories
                    .map((category) => _buildCategoryFilter(category.id, category.name)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter(String categoryId, String name) {
    final isSelected = _selectedCategory == categoryId;

    return Container(
      margin: const EdgeInsets.only(right: AppSpacing.sm),
      child: FilterChip(
        label: Text(name),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = categoryId;
            _filterProducts();
          });
        },
        backgroundColor: Colors.white,
        selectedColor: AppColors.primary.withValues(alpha: 0.2),
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  // Liste des produits
  Widget _buildProductCard(ProductModel product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          context.push('/vendeur/edit-product/${product.id}');
        },
        onLongPress: () {
          _showProductMenu(context, product);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: product.images.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          product.images.first,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.image_not_supported,
                            color: Colors.grey[400],
                          ),
                        ),
                      )
                    : Icon(Icons.image, color: Colors.grey[400]),
              ),

              const SizedBox(width: 12),

              // ✅ WRAPPED IN EXPANDED
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Catégorie
                    Text(
                      product.category,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Prix et Stock
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${product.price.toStringAsFixed(0)} F',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: product.stock > 0
                                ? AppColors.success.withValues(alpha: 0.1)
                                : AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Stock: ${product.stock}',
                            style: TextStyle(
                              fontSize: 10,
                              color: product.stock > 0 ? AppColors.success : AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Switch
              Switch(
                value: product.isActive,
                onChanged: (value) async {
                  await _toggleProductStatus(product.id, value);
                },
                activeThumbColor: AppColors.success,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Menu contextuel du produit
  void _showProductMenu(BuildContext context, ProductModel product) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // En-tête
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(),

            // Modifier
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.info),
              title: const Text('Modifier'),
              onTap: () {
                Navigator.pop(context);
                context.push('/vendeur/products/edit/${product.id}');
              },
            ),

            // Dupliquer
            ListTile(
              leading: const Icon(Icons.copy, color: AppColors.primary),
              title: const Text('Dupliquer'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fonctionnalité bientôt disponible')),
                );
              },
            ),

            // Partager
            ListTile(
              leading: const Icon(Icons.share, color: AppColors.secondary),
              title: const Text('Partager'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lien copié dans le presse-papier')),
                );
              },
            ),

            const Divider(),

            // ✅ SUPPRIMER (UTILISE _deleteProduct)
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.error),
              title: const Text(
                'Supprimer',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () async {
                Navigator.pop(context);

                // Confirmation
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Supprimer le produit'),
                    content: Text(
                      'Êtes-vous sûr de vouloir supprimer "${product.name}" ?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Annuler'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                        ),
                        child: const Text('Supprimer'),
                      ),
                    ],
                  ),
                );

                if (confirm == true && mounted) {
                  // ✅ APPELER LA MÉTHODE
                  await _deleteProduct(product.id, product.name);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // État vide
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'Aucun produit trouvé',
            style: TextStyle(
              fontSize: AppFontSizes.lg,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Commencez par ajouter vos premiers produits',
            style: TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton.icon(
            onPressed: () {
              context.push('/vendeur/add-product');
            },
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un produit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.md,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
