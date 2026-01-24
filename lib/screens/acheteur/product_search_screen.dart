// ===== lib/screens/acheteur/product_search_screen.dart =====
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/product_model.dart';
import '../../services/product_service.dart';
import 'package:social_business_pro/config/constants.dart';
import '../../config/product_categories.dart';
import '../../utils/number_formatter.dart';
import '../../widgets/system_ui_scaffold.dart';

class ProductSearchScreen extends StatefulWidget {
  const ProductSearchScreen({super.key});

  @override
  State<ProductSearchScreen> createState() => _ProductSearchScreenState();
}

class _ProductSearchScreenState extends State<ProductSearchScreen> {
  final ProductService _productService = ProductService();
  final TextEditingController _searchController = TextEditingController();

  List<ProductModel> _allProducts = [];
  List<ProductModel> _filteredProducts = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  String? _selectedCategory;
  double _minPrice = 0;
  double _maxPrice = 1000000;
  String _sortBy = 'recent'; // recent, price_low, price_high, popular

  @override
  void initState() {
    super.initState();
    _loadAllProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllProducts() async {
    setState(() => _isLoading = true);

    try {
      final products = await _productService.getProducts();
      setState(() {
        _allProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _performSearch() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _hasSearched = true;
      _filteredProducts = _allProducts.where((product) {
        // Filtre par texte de recherche
        final matchesQuery = query.isEmpty ||
            product.name.toLowerCase().contains(query) ||
            product.description.toLowerCase().contains(query) ||
            product.category.toLowerCase().contains(query);

        // Filtre par catégorie
        final matchesCategory = _selectedCategory == null || product.category == _selectedCategory;

        // Filtre par prix
        final matchesPrice = product.price >= _minPrice && product.price <= _maxPrice;

        return matchesQuery && matchesCategory && matchesPrice;
      }).toList();

      // Tri
      switch (_sortBy) {
        case 'price_low':
          _filteredProducts.sort((a, b) => a.price.compareTo(b.price));
          break;
        case 'price_high':
          _filteredProducts.sort((a, b) => b.price.compareTo(a.price));
          break;
        case 'recent':
          _filteredProducts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
        default:
          break;
      }
    });
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFilterSheet(),
    );
  }

  Widget _buildFilterSheet() {
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // En-tête
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filtres',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setModalState(() {
                          _selectedCategory = null;
                          _minPrice = 0;
                          _maxPrice = 1000000;
                          _sortBy = 'recent';
                        });
                      },
                      child: const Text('Réinitialiser'),
                    ),
                  ],
                ),
              ),

              // Contenu
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Catégories
                      const Text(
                        'Catégorie',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilterChip(
                            label: const Text('Toutes'),
                            selected: _selectedCategory == null,
                            onSelected: (selected) {
                              setModalState(() {
                                _selectedCategory = null;
                              });
                            },
                          ),
                          ...ProductCategories.allCategories.map(
                            (category) => FilterChip(
                              label: Text(category.name),
                              selected: _selectedCategory == category.id,
                              onSelected: (selected) {
                                setModalState(() {
                                  _selectedCategory = selected ? category.id : null;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Fourchette de prix
                      const Text(
                        'Prix',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      RangeSlider(
                        values: RangeValues(_minPrice, _maxPrice),
                        min: 0,
                        max: 1000000,
                        divisions: 100,
                        labels: RangeLabels(
                          formatPriceWithCurrency(_minPrice, currency: 'FCFA'),
                          formatPriceWithCurrency(_maxPrice, currency: 'FCFA'),
                        ),
                        onChanged: (values) {
                          setModalState(() {
                            _minPrice = values.start;
                            _maxPrice = values.end;
                          });
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            formatPriceWithCurrency(_minPrice, currency: 'FCFA'),
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            formatPriceWithCurrency(_maxPrice, currency: 'FCFA'),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Tri
                      const Text(
                        'Trier par',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        leading: Radio<String>(
                          value: 'recent',
                          groupValue: _sortBy,
                          onChanged: (value) {
                            setModalState(() {
                              _sortBy = value!;
                            });
                          },
                        ),
                        title: const Text('Plus récents'),
                        onTap: () {
                          setModalState(() {
                            _sortBy = 'recent';
                          });
                        },
                      ),
                      ListTile(
                        leading: Radio<String>(
                          value: 'price_low',
                          groupValue: _sortBy,
                          onChanged: (value) {
                            setModalState(() {
                              _sortBy = value!;
                            });
                          },
                        ),
                        title: const Text('Prix croissant'),
                        onTap: () {
                          setModalState(() {
                            _sortBy = 'price_low';
                          });
                        },
                      ),
                      ListTile(
                        leading: Radio<String>(
                          value: 'price_high',
                          groupValue: _sortBy,
                          onChanged: (value) {
                            setModalState(() {
                              _sortBy = value!;
                            });
                          },
                        ),
                        title: const Text('Prix décroissant'),
                        onTap: () {
                          setModalState(() {
                            _sortBy = 'price_high';
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Bouton Appliquer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        // Les filtres sont déjà appliqués via setModalState
                      });
                      Navigator.pop(context);
                      _performSearch();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: AppColors.primary,
                    ),
                    child: const Text('Appliquer les filtres'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/product/${product.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image avec badge de stock
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: product.images.isNotEmpty
                      ? Image.network(
                          product.images.first,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.image, size: 50),
                          ),
                        )
                      : Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image, size: 50),
                        ),
                ),
                // Badge de stock
                if (product.isOutOfStock || product.isLowStock)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: product.isOutOfStock ? AppColors.error : AppColors.warning,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            product.isOutOfStock
                                ? Icons.cancel_outlined
                                : Icons.warning_amber_outlined,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            product.isOutOfStock ? 'Rupture' : 'Stock: ${product.availableStock}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // Informations
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatPriceWithCurrency(product.price, currency: 'FCFA'),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (product.originalPrice != null)
                    Text(
                      formatPriceWithCurrency(product.originalPrice!, currency: 'FCFA'),
                      style: const TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.store, size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          product.vendeurName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
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

  @override
  Widget build(BuildContext context) {
    return SystemUIScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/acheteur');
            }
          },
          tooltip: 'Retour',
        ),
        title: const Text('Rechercher'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _showFilters,
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un produit...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppColors.background,
              ),
              onChanged: (value) {
                setState(() {});
                _performSearch();
              },
              onSubmitted: (value) => _performSearch(),
            ),
          ),

          // Résultats
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : !_hasSearched
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search,
                              size: 80,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Recherchez des produits',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _filteredProducts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.shopping_bag_outlined,
                                  size: 80,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Aucun produit trouvé',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _selectedCategory = null;
                                      _minPrice = 0;
                                      _maxPrice = 1000000;
                                      _sortBy = 'recent';
                                    });
                                    _performSearch();
                                  },
                                  child: const Text('Réinitialiser la recherche'),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              // Nombre de résultats
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                color: AppColors.background,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${_filteredProducts.length} produit${_filteredProducts.length > 1 ? "s" : ""} trouvé${_filteredProducts.length > 1 ? "s" : ""}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (_selectedCategory != null ||
                                        _minPrice > 0 ||
                                        _maxPrice < 1000000)
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            _selectedCategory = null;
                                            _minPrice = 0;
                                            _maxPrice = 1000000;
                                          });
                                          _performSearch();
                                        },
                                        child: const Text('Effacer filtres'),
                                      ),
                                  ],
                                ),
                              ),

                              // Grille de produits
                              Expanded(
                                child: GridView.builder(
                                  padding: const EdgeInsets.all(16),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio:
                                        0.55, // ✅ CORRECTION: 0.55 pour carte complète avec tous les éléments
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                  ),
                                  itemCount: _filteredProducts.length,
                                  itemBuilder: (context, index) {
                                    return _buildProductCard(_filteredProducts[index]);
                                  },
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

