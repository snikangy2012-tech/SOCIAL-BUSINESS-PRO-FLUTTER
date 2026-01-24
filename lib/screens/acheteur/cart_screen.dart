// ===== lib/screens/acheteur/cart_screen.dart =====
// Écran du panier - SOCIAL BUSINESS Pro

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:social_business_pro/config/constants.dart';
import '../../providers/cart_provider.dart';
import '../../services/analytics_service.dart';
import '../../utils/number_formatter.dart';
import '../../widgets/system_ui_scaffold.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final AnalyticsService _analytics = AnalyticsService();

  @override
  void initState() {
    super.initState();
    _analytics.logScreenView('CartScreen');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        final items = cartProvider.items;
        final isEmpty = items.isEmpty;

        return SystemUIScaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  context.go('/acheteur-home');
                }
              },
              tooltip: 'Retour',
            ),
        title: const Text('Mon Panier'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            actions: [
              if (!isEmpty)
                TextButton(
                  onPressed: () async {
                    // Demander confirmation avant de vider
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Vider le panier'),
                        content: const Text(
                          'Voulez-vous vraiment supprimer tous les articles du panier ?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Annuler'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.error,
                            ),
                            child: const Text('Vider'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await cartProvider.clearCart();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Panier vidé'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text(
                    'Vider',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
            ],
          ),
          body: cartProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : isEmpty
                  ? _buildEmptyCart()
                  : _buildCartContent(cartProvider),
          bottomNavigationBar: isEmpty ? null : _buildBottomBar(cartProvider),
        );
      },
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
  Widget _buildCartContent(CartProvider cartProvider) {
    final items = cartProvider.items;

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
                '${items.length} article(s) - ${cartProvider.totalQuantity} unité(s)',
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
            itemCount: items.length,
            separatorBuilder: (context, index) => const Divider(height: 24),
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildCartItem(item, cartProvider);
            },
          ),
        ),

        // Résumé
        _buildSummary(cartProvider),
      ],
    );
  }

  // Article du panier
  Widget _buildCartItem(CartItem item, CartProvider cartProvider) {
    return Row(
      children: [
        // Image
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.backgroundSecondary,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: item.productImage.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Image.network(
                    item.productImage,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.image,
                        color: AppColors.textLight,
                        size: 40,
                      );
                    },
                  ),
                )
              : const Icon(
                  Icons.image,
                  color: AppColors.textLight,
                  size: 40,
                ),
        ),

        const SizedBox(width: AppSpacing.md),

        // Détails
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.productName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                formatPriceWithCurrency(item.price, currency: 'FCFA'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Total: ${formatPriceWithCurrency(item.total, currency: 'FCFA')}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
              color: item.quantity < item.maxStock ? AppColors.primary : AppColors.textLight,
              onPressed: item.quantity < item.maxStock
                  ? () async {
                      try {
                        await cartProvider.incrementQuantity(item.productId);
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
                    }
                  : null,
            ),

            // Quantité
            Text(
              '${item.quantity}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            // Bouton -
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              color: item.quantity > 1 ? AppColors.primary : AppColors.textLight,
              onPressed: item.quantity > 1
                  ? () async {
                      try {
                        await cartProvider.decrementQuantity(item.productId);
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
                    }
                  : null,
            ),
          ],
        ),

        // Supprimer
        IconButton(
          icon: const Icon(Icons.delete_outline),
          color: AppColors.error,
          onPressed: () async {
            // Demander confirmation
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Supprimer'),
                content: Text(
                  'Voulez-vous retirer "${item.productName}" du panier ?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Annuler'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                    child: const Text('Supprimer'),
                  ),
                ],
              ),
            );

            if (confirm == true) {
              try {
                await cartProvider.removeItem(item.productId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Article retiré du panier'),
                      duration: Duration(seconds: 1),
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
            }
          },
        ),
      ],
    );
  }

  // Résumé
  Widget _buildSummary(CartProvider cartProvider) {
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
          _buildSummaryRow('Sous-total', cartProvider.subtotal),
          const SizedBox(height: AppSpacing.sm),
          _buildSummaryRow('Frais de livraison', cartProvider.deliveryFee),
          const Divider(height: 24),
          _buildSummaryRow(
            'Total',
            cartProvider.total,
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
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            formatPriceWithCurrency(amount, currency: 'FCFA'),
            style: TextStyle(
              fontSize: isLarge ? 18 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: isBold ? AppColors.primary : AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  // Barre du bas avec bouton Commander
  Widget _buildBottomBar(CartProvider cartProvider) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: () {
            _analytics.logBeginCheckout(
              value: cartProvider.total,
              itemCount: cartProvider.items.length,
            );
            context.push('/acheteur/checkout');
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: AppColors.primary,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Commander',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                formatPriceWithCurrency(cartProvider.total, currency: 'FCFA'),
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

