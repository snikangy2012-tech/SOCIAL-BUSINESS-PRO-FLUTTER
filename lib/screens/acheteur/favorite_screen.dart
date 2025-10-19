import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../providers/auth_provider_firebase.dart' as auth;

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  bool _isLoading = false;
  
  // Données mock des favoris
  final List<Map<String, dynamic>> _favorites = [
    {
      'id': '1',
      'name': 'iPhone 15 Pro Max',
      'price': 850000,
      'oldPrice': 950000,
      'image': 'https://via.placeholder.com/150',
      'vendorName': 'Tech Store CI',
      'rating': 4.8,
      'reviews': 156,
      'inStock': true,
      'discount': 10,
    },
    {
      'id': '2',
      'name': 'Samsung Galaxy S24 Ultra',
      'price': 750000,
      'oldPrice': 850000,
      'image': 'https://via.placeholder.com/150',
      'vendorName': 'Mobile Shop',
      'rating': 4.7,
      'reviews': 89,
      'inStock': true,
      'discount': 12,
    },
    {
      'id': '3',
      'name': 'MacBook Pro M3',
      'price': 1500000,
      'oldPrice': null,
      'image': 'https://via.placeholder.com/150',
      'vendorName': 'Apple Store Abidjan',
      'rating': 4.9,
      'reviews': 234,
      'inStock': false,
      'discount': 0,
    },
    {
      'id': '4',
      'name': 'AirPods Pro 2',
      'price': 180000,
      'oldPrice': 200000,
      'image': 'https://via.placeholder.com/150',
      'vendorName': 'Audio Express',
      'rating': 4.6,
      'reviews': 67,
      'inStock': true,
      'discount': 10,
    },
  ];

  void _removeFavorite(String id) {
    setState(() {
      _favorites.removeWhere((item) => item['id'] == id);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Produit retiré des favoris'),
        backgroundColor: AppColors.info,
        action: SnackBarAction(
          label: 'Annuler',
          textColor: Colors.white,
          onPressed: () {
            // TODO: Restaurer le favori
          },
        ),
      ),
    );
  }

  String _formatPrice(num price) {
    return '${price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    )} FCFA';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<auth.AuthProvider>();
    final isAuthenticated = authProvider.isAuthenticated;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mes Favoris',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              '${_favorites.length} produit(s)',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          if (_favorites.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Tout supprimer',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Vider les favoris'),
                    content: const Text(
                      'Êtes-vous sûr de vouloir supprimer tous vos favoris ?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Annuler'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() => _favorites.clear());
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Tous les favoris ont été supprimés'),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                        ),
                        child: const Text('Supprimer'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: !isAuthenticated
          ? _buildLoginPrompt()
          : _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _favorites.isEmpty
                  ? _buildEmptyState()
                  : _buildFavoritesList(),
    );
  }

  // Invite à se connecter
  Widget _buildLoginPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_outline,
              size: 100,
              color: Colors.grey[300],
            ),
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
              'Enregistrez vos produits préférés et retrouvez-les facilement',
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // État vide
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 100,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 24),
            const Text(
              'Aucun favori pour le moment',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Explorez nos produits et ajoutez vos articles préférés',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.shopping_bag),
              label: const Text('Découvrir les produits'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Liste des favoris
  Widget _buildFavoritesList() {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _isLoading = true);
        await Future.delayed(const Duration(seconds: 1));
        setState(() => _isLoading = false);
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _favorites.length,
        itemBuilder: (context, index) {
          final product = _favorites[index];
          return _buildProductCard(product);
        },
      ),
    );
  }

  // Carte produit
  Widget _buildProductCard(Map<String, dynamic> product) {
    final bool inStock = product['inStock'] as bool;
    final int discount = product['discount'] as int;
    
    return InkWell(
      onTap: () {
        context.push('/product/${product['id']}');
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.05),
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
                // Image
                Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.image_outlined,
                      size: 60,
                      color: Colors.grey[300],
                    ),
                  ),
                ),
                
                // Badge réduction
                if (discount > 0)
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
                      child: Text(
                        '-$discount%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                
                // Bouton favori
                Positioned(
                  top: 8,
                  right: 8,
                  child: InkWell(
                    onTap: () => _removeFavorite(product['id']),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha:0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: AppColors.error,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                
                // Badge stock
                if (!inStock)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha:0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Rupture de stock',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            
            // Informations
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom produit
                    Text(
                      product['name'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Vendeur
                    Text(
                      product['vendorName'],
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 6),
                    
                    // Note
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 14,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${product['rating']}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          ' (${product['reviews']})',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    
                    const Spacer(),
                    
                    // Prix
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (product['oldPrice'] != null)
                          Text(
                            _formatPrice(product['oldPrice']),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        Text(
                          _formatPrice(product['price']),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Bouton Ajouter au panier
            if (inStock)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${product['name']} ajouté au panier',
                          ),
                          backgroundColor: AppColors.success,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.shopping_cart_outlined, size: 16),
                    label: const Text(
                      'Ajouter',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}