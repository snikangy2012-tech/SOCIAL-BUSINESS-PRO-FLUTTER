// ===== lib/screens/acheteur/order_detail_screen.dart =====
// Détail d'une commande pour l'acheteur - SOCIAL BUSINESS Pro

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import 'package:social_business_pro/config/constants.dart';
import '../../models/order_model.dart';
import '../../models/delivery_model.dart';
import '../../services/order_service.dart';
import '../../services/delivery_service.dart';
import '../../services/review_service.dart';
import '../../widgets/review_dialog.dart';
import '../../utils/order_status_helper.dart';
import '../../utils/number_formatter.dart';
import 'request_refund_screen.dart';
import '../widgets/system_ui_scaffold.dart';

class AcheteurOrderDetailScreen extends StatefulWidget {
  final String orderId;

  const AcheteurOrderDetailScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<AcheteurOrderDetailScreen> createState() => _AcheteurOrderDetailScreenState();
}

class _AcheteurOrderDetailScreenState extends State<AcheteurOrderDetailScreen> {
  OrderModel? _order;
  DeliveryModel? _delivery;
  bool _isLoading = true;
  bool _isLoadingDelivery = true;

  @override
  void initState() {
    super.initState();
    _loadOrder();
    _loadDelivery();
  }

  // Charger la commande
  Future<void> _loadOrder() async {
    setState(() => _isLoading = true);

    try {
      final order = await OrderService.getOrderById(widget.orderId);

      setState(() {
        _order = order;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Erreur chargement commande: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement: $e'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  // Charger la livraison associée
  Future<void> _loadDelivery() async {
    setState(() => _isLoadingDelivery = true);

    try {
      final delivery = await DeliveryService.getDeliveryByOrderId(widget.orderId);

      if (mounted) {
        setState(() {
          _delivery = delivery;
          _isLoadingDelivery = false;
        });
      }
    } catch (e) {
      debugPrint('⚠️ Pas de livraison trouvée pour cette commande: $e');
      if (mounted) {
        setState(() => _isLoadingDelivery = false);
      }
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy à HH:mm').format(date);
  }

  Color _getStatusColor(String status) {
    return OrderStatusHelper.getStatusColor(status);
  }

  String _getStatusLabel(String status) {
    return OrderStatusHelper.getStatusLabel(status);
  }

  Widget _buildStatusTimeline() {
    if (_order == null) return const SizedBox.shrink();

    final currentStatus = _order!.status.toLowerCase();
    final statuses = ['pending', 'confirmed', 'preparing', 'in_delivery', 'delivered'];

    int currentIndex = statuses.indexOf(currentStatus);
    if (currentIndex == -1) currentIndex = 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Suivi de commande',
              style: TextStyle(
                fontSize: AppFontSizes.lg,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ...List.generate(statuses.length, (index) {
              final status = statuses[index];
              final isCompleted = index <= currentIndex;
              final isCurrent = index == currentIndex;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Indicateur
                  Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? AppColors.primary
                              : AppColors.border.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isCompleted ? AppColors.primary : AppColors.border,
                            width: 2,
                          ),
                        ),
                        child: isCompleted
                            ? const Icon(
                                Icons.check,
                                size: 18,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      if (index < statuses.length - 1)
                        Container(
                          width: 2,
                          height: 40,
                          color: isCompleted
                              ? AppColors.primary
                              : AppColors.border.withValues(alpha: 0.3),
                        ),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.md),
                  // Label
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getStatusLabel(status),
                            style: TextStyle(
                              fontSize: AppFontSizes.md,
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                              color: isCompleted
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                          if (isCurrent && _order!.updatedAt != null)
                            Text(
                              _formatDate(_order!.updatedAt!),
                              style: const TextStyle(
                                fontSize: AppFontSizes.xs,
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SystemUIScaffold(
        appBar: AppBar(
          title: const Text('Détail de la commande'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_order == null) {
      return SystemUIScaffold(
        appBar: AppBar(
          title: const Text('Détail de la commande'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Commande introuvable'),
        ),
      );
    }

    return SystemUIScaffold(
      appBar: AppBar(
        title: const Text('Détail de la commande'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _loadOrder,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec numéro et statut
              Card(
                color: _getStatusColor(_order!.status).withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Commande ${_order!.displayNumber}',
                                  style: const TextStyle(
                                    fontSize: AppFontSizes.xl,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  _formatDate(_order!.createdAt),
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(_order!.status),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _getStatusLabel(_order!.status),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: AppFontSizes.sm,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Timeline de statut
              _buildStatusTimeline(),

              const SizedBox(height: AppSpacing.lg),

              // Articles commandés
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Articles',
                        style: TextStyle(
                          fontSize: AppFontSizes.lg,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ..._order!.items.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: Row(
                              children: [
                                // Image produit
                                if (item.productImage != null)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      item.productImage!,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          width: 50,
                                          height: 50,
                                          color: AppColors.border,
                                          child: const Icon(Icons.image, size: 24),
                                        );
                                      },
                                    ),
                                  )
                                else
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: AppColors.border,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.shopping_bag, size: 24),
                                  ),
                                const SizedBox(width: AppSpacing.md),
                                // Infos produit
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.productName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        'Quantité: ${item.quantity}',
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: AppFontSizes.sm,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Prix
                                Flexible(
                                  child: Text(
                                    formatPriceWithCurrency(item.price * item.quantity, currency: 'FCFA'),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: AppFontSizes.md,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Informations de livraison
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Livraison',
                        style: TextStyle(
                          fontSize: AppFontSizes.lg,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              _order!.deliveryAddress,
                              style: const TextStyle(fontSize: AppFontSizes.md),
                            ),
                          ),
                        ],
                      ),
                      if (_order!.notes != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        const Divider(),
                        const SizedBox(height: AppSpacing.sm),
                        const Text(
                          'Note de livraison:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: AppFontSizes.sm,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _order!.notes!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: AppFontSizes.sm,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Informations vendeur
              if (_order!.vendeurShopName != null || _order!.vendeurName != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Vendeur',
                          style: TextStyle(
                            fontSize: AppFontSizes.lg,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Nom de la boutique
                        if (_order!.vendeurShopName != null) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.store,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Boutique',
                                      style: TextStyle(
                                        fontSize: AppFontSizes.sm,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      _order!.vendeurShopName!,
                                      style: const TextStyle(
                                        fontSize: AppFontSizes.md,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],

                        // Nom du vendeur
                        if (_order!.vendeurName != null) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.person,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Vendeur',
                                      style: TextStyle(
                                        fontSize: AppFontSizes.sm,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      _order!.vendeurName!,
                                      style: const TextStyle(
                                        fontSize: AppFontSizes.md,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],

                        // Téléphone
                        if (_order!.vendeurPhone != null) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.phone,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Téléphone',
                                      style: TextStyle(
                                        fontSize: AppFontSizes.sm,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      _order!.vendeurPhone!,
                                      style: const TextStyle(
                                        fontSize: AppFontSizes.md,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.call, color: AppColors.primary),
                                onPressed: () {
                                  // TODO: Implement phone call
                                },
                                tooltip: 'Appeler',
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],

                        // Localisation
                        if (_order!.vendeurLocation != null)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Localisation',
                                      style: TextStyle(
                                        fontSize: AppFontSizes.sm,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      _order!.vendeurLocation!,
                                      style: const TextStyle(
                                        fontSize: AppFontSizes.md,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),

              if (_order!.vendeurShopName != null || _order!.vendeurName != null)
                const SizedBox(height: AppSpacing.lg),

              // Résumé de paiement
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Résumé',
                        style: TextStyle(
                          fontSize: AppFontSizes.lg,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Sous-total'),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              formatPriceWithCurrency(_order!.subtotal, currency: 'FCFA'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Frais de livraison'),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              formatPriceWithCurrency(_order!.deliveryFee, currency: 'FCFA'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                      if (_order!.discount > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Réduction',
                              style: TextStyle(color: AppColors.success),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                '- ${formatPriceWithCurrency(_order!.discount, currency: 'FCFA')}',
                                style: const TextStyle(color: AppColors.success),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontSize: AppFontSizes.lg,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              formatPriceWithCurrency(_order!.totalAmount, currency: 'FCFA'),
                              style: const TextStyle(
                                fontSize: AppFontSizes.lg,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Bouton de demande de retour si commande peut être retournée
              if (_order!.canBeReturned && !_order!.hasRefundPending)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RequestRefundScreen(order: _order!),
                        ),
                      );

                      if (result == true && mounted) {
                        _loadOrder(); // Recharger la commande
                      }
                    },
                    icon: const Icon(Icons.assignment_return),
                    label: const Text('Demander un retour'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.warning,
                      side: const BorderSide(color: AppColors.warning),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),

              // Afficher le statut du remboursement si en cours
              if (_order!.hasRefundPending) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: AppColors.info.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.info),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Demande de retour en cours',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.info,
                              ),
                            ),
                            if (_order!.refundStatus != null)
                              Text(
                                RefundStatus.values
                                    .firstWhere(
                                      (s) => s.value == _order!.refundStatus,
                                      orElse: () => RefundStatus.demandeEnvoyee,
                                    )
                                    .label,
                                style: const TextStyle(fontSize: 12),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Bouton de suivi si en livraison
              if (_order!.status.toLowerCase() == 'in_delivery') ...[
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.push('/acheteur/order/${_order!.id}/tracking');
                    },
                    icon: const Icon(Icons.location_on),
                    label: const Text('Suivre ma livraison'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],

              // Boutons de notation si commande livrée
              if (_order!.status.toLowerCase() == 'delivered') ...[
                const SizedBox(height: AppSpacing.md),

                // Noter les produits
                ..._order!.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final reviewService = ReviewService();

                      // Vérifier si déjà noté
                      final hasReviewed = await reviewService.hasUserReviewed(
                        _order!.buyerId,
                        item.productId,
                        'product',
                      );

                      if (!mounted) return;

                      if (hasReviewed) {
                        // Charger l'avis existant pour modification
                        final existingReview = await reviewService.getUserReview(
                          _order!.buyerId,
                          item.productId,
                          'product',
                        );

                        if (!mounted) return;

                        final result = await ReviewDialog.show(
                          context,
                          targetId: item.productId,
                          targetType: 'product',
                          targetName: item.productName,
                          existingReview: existingReview,
                        );

                        if (result == true && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Avis modifié avec succès'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } else {
                        // Nouveau avis
                        final result = await ReviewDialog.show(
                          context,
                          targetId: item.productId,
                          targetType: 'product',
                          targetName: item.productName,
                        );

                        if (result == true && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Avis publié avec succès'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.star_rate),
                    label: Text('Noter ${item.productName}'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.warning,
                      side: const BorderSide(color: AppColors.warning),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                )),

                // Noter le vendeur
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final reviewService = ReviewService();

                      final hasReviewed = await reviewService.hasUserReviewed(
                        _order!.buyerId,
                        _order!.vendeurId,
                        'vendor',
                      );

                      if (!mounted) return;

                      if (hasReviewed) {
                        final existingReview = await reviewService.getUserReview(
                          _order!.buyerId,
                          _order!.vendeurId,
                          'vendor',
                        );

                        if (!mounted) return;

                        final result = await ReviewDialog.show(
                          context,
                          targetId: _order!.vendeurId,
                          targetType: 'vendor',
                          targetName: 'Le vendeur',
                          existingReview: existingReview,
                        );

                        if (result == true && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Avis sur le vendeur modifié avec succès'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } else {
                        final result = await ReviewDialog.show(
                          context,
                          targetId: _order!.vendeurId,
                          targetType: 'vendor',
                          targetName: 'Le vendeur',
                        );

                        if (result == true && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Avis sur le vendeur publié avec succès'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.store_outlined),
                    label: const Text('Noter le vendeur'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.info,
                      side: const BorderSide(color: AppColors.info),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),

                // Noter le livreur (si livraison assignée)
                if (_delivery != null && _delivery!.livreurId != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final reviewService = ReviewService();

                        final hasReviewed = await reviewService.hasUserReviewed(
                          _order!.buyerId,
                          _delivery!.livreurId!,
                          'livreur',
                        );

                        if (!mounted) return;

                        if (hasReviewed) {
                          final existingReview = await reviewService.getUserReview(
                            _order!.buyerId,
                            _delivery!.livreurId!,
                            'livreur',
                          );

                          if (!mounted) return;

                          final result = await ReviewDialog.show(
                            context,
                            targetId: _delivery!.livreurId!,
                            targetType: 'livreur',
                            targetName: 'Le livreur',
                            existingReview: existingReview,
                          );

                          if (result == true && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Avis sur le livreur modifié avec succès'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        } else {
                          final result = await ReviewDialog.show(
                            context,
                            targetId: _delivery!.livreurId!,
                            targetType: 'livreur',
                            targetName: 'Le livreur',
                          );

                          if (result == true && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Avis sur le livreur publié avec succès'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.delivery_dining),
                      label: const Text('Noter le livreur'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.success,
                        side: const BorderSide(color: AppColors.success),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
