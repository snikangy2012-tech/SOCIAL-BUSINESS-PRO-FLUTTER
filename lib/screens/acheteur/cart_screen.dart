// ===== lib/screens/acheteur/cart_screen.dart =====
// Écran du panier - SOCIAL BUSINESS Pro

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/constants.dart';
import '../../services/analytics_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final AnalyticsService _analytics = AnalyticsService();
  
  // TODO: Remplacer par CartProvider
  List<Map<String, dynamic>> _cartItems = [];

  @override
  void initState() {
    super.initState();
    _analytics.logScreenView('CartScreen');
    _loadCart();
  }

  void _loadCart() {
    // TODO: Charger le panier depuis CartProvider ou localStorage
    setState(() {
      _cartItems = [];
    });
  }

  double get _subtotal {
    return _cartItems.fold(
      0.0,
      (sum, item) => sum + (item['price'] * item['quantity']),
    );
  }

  double get _deliveryFee {
    return _cartItems.isEmpty ? 0 : 1500;  // 1500 FCFA frais de livraison
  }

  double get _total {
    return _subtotal + _deliveryFee;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Panier'),
        actions: [
          if (_cartItems.isNotEmpty)
            TextButton(
              onPressed: () {
                // Vider le panier
                setState(() => _cartItems.clear());
              },
              child: const Text(
                'Vider',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _cartItems.isEmpty ? _buildEmptyCart() : _buildCartContent(),
      bottomNavigationBar: _cartItems.isEmpty
          ? null
          : _buildBottomBar(),
    );
  }

  // Panier vide
  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: AppColors.textLight,
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'Votre panier est vide',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Ajoutez des produits pour commencer',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton.icon(
            onPressed: () {
              // Navigation vers les catégories de produits
              context.push('/categories');
            },
            icon: const Icon(Icons.shopping_bag),
            label: const Text('Découvrir les produits'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Contenu du panier
  Widget _buildCartContent() {
    return Column(
      children: [
        // En-tête
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          color: AppColors.backgroundSecondary,
          child: Row(
            children: [
              const Icon(
                Icons.shopping_cart,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${_cartItems.length} article(s)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        // Liste des articles
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: _cartItems.length,
            separatorBuilder: (context, index) => const Divider(height: 24),
            itemBuilder: (context, index) {
              final item = _cartItems[index];
              return _buildCartItem(item, index);
            },
          ),
        ),

        // Résumé
        _buildSummary(),
      ],
    );
  }

  // Article du panier
  Widget _buildCartItem(Map<String, dynamic> item, int index) {
    return Row(
      children: [
        // Image
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.backgroundSecondary,
            borderRadius: BorderRadius.circular(AppRadius.md),
            image: item['image'] != null
                ? DecorationImage(
                    image: NetworkImage(item['image']),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: item['image'] == null
              ? const Icon(Icons.image, color: AppColors.textLight)
              : null,
        ),

        const SizedBox(width: AppSpacing.md),

        // Détails
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item['name'] ?? 'Produit',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${item['price'].toStringAsFixed(0)} FCFA',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),

        // Quantité
        Column(
          children: [
            // Bouton +
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              color: AppColors.primary,
              onPressed: () {
                setState(() {
                  _cartItems[index]['quantity']++;
                });
              },
            ),
            
            // Quantité
            Text(
              '${item['quantity']}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            // Bouton -
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              color: item['quantity'] > 1 ? AppColors.primary : AppColors.textLight,
              onPressed: item['quantity'] > 1
                  ? () {
                      setState(() {
                        _cartItems[index]['quantity']--;
                      });
                    }
                  : null,
            ),
          ],
        ),

        // Supprimer
        IconButton(
          icon: const Icon(Icons.delete_outline),
          color: AppColors.error,
          onPressed: () {
            setState(() {
              _cartItems.removeAt(index);
            });
          },
        ),
      ],
    );
  }

  // Résumé
  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.backgroundSecondary,
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        children: [
          _buildSummaryRow('Sous-total', _subtotal),
          const SizedBox(height: AppSpacing.sm),
          _buildSummaryRow('Frais de livraison', _deliveryFee),
          const Divider(height: 24),
          _buildSummaryRow(
            'Total',
            _total,
            isBold: true,
            isLarge: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    double amount, {
    bool isBold = false,
    bool isLarge = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isLarge ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          '${amount.toStringAsFixed(0)} FCFA',
          style: TextStyle(
            fontSize: isLarge ? 18 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: isBold ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  // Barre du bas avec bouton Commander
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: () {
            _analytics.logBeginCheckout(
              value: _total,
              itemCount: _cartItems.length,
            );
            context.push('/checkout');
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Commander',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${_total.toStringAsFixed(0)} FCFA',
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}