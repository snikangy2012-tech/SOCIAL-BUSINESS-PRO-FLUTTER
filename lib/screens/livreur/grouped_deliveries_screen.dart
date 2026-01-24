// ===== lib/screens/livreur/grouped_deliveries_screen.dart =====
// Écran pour gérer les livraisons groupées par vendeur

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../config/constants.dart';
import '../../models/delivery_model.dart';
import '../../services/delivery_grouping_service.dart';
import '../../widgets/system_ui_scaffold.dart';

class GroupedDeliveriesScreen extends StatelessWidget {
  final List<DeliveryModel> deliveries;
  final String vendeurId;

  const GroupedDeliveriesScreen({
    super.key,
    required this.deliveries,
    required this.vendeurId,
  });

  @override
  Widget build(BuildContext context) {
    // Calculer les statistiques
    final stats = DeliveryGroupingService.calculateGroupStats(deliveries);

    // Optimiser l'itinéraire
    final optimizedRoute = DeliveryGroupingService.optimizeRoute(deliveries);

    // Calculer les distances
    final optimizedDistance = DeliveryGroupingService.calculateOptimizedDistance(optimizedRoute);
    final timeSaved = DeliveryGroupingService.estimateTimeSaved(deliveries);

    return SystemUIScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/livreur');
            }
          },
          tooltip: 'Retour',
        ),
        title: const Text('Tournée Groupée'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // En-tête avec statistiques
          _buildHeader(stats, optimizedDistance, timeSaved),

          // Liste des livraisons optimisées
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: optimizedRoute.length,
              itemBuilder: (context, index) {
                final delivery = optimizedRoute[index];
                final isFirst = index == 0;
                final isLast = index == optimizedRoute.length - 1;

                return _buildDeliveryCard(
                  context,
                  delivery,
                  index + 1,
                  isFirst,
                  isLast,
                );
              },
            ),
          ),

          // Bouton d'action
          _buildActionButton(context),
        ],
      ),
    );
  }

  Widget _buildHeader(DeliveryGroupStats stats, double optimizedDistance, int timeSaved) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nom du vendeur
          Text(
            stats.vendeurName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${stats.totalDeliveries} livraisons à effectuer',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Statistiques
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Distance',
                  '${optimizedDistance.toStringAsFixed(1)} km',
                  Icons.route,
                  Colors.white,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildStatCard(
                  'Gain de temps',
                  '$timeSaved min',
                  Icons.timer,
                  Colors.greenAccent,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildStatCard(
                  'Total',
                  '${NumberFormat('#,##0').format(stats.totalFee)} F',
                  Icons.monetization_on,
                  Colors.amberAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryCard(
    BuildContext context,
    DeliveryModel delivery,
    int position,
    bool isFirst,
    bool isLast,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      elevation: 2,
      child: Column(
        children: [
          // Numéro de position dans l'itinéraire
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isFirst
                  ? AppColors.success.withValues(alpha: 0.1)
                  : isLast
                      ? AppColors.info.withValues(alpha: 0.1)
                      : AppColors.primary.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppRadius.md),
                topRight: Radius.circular(AppRadius.md),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isFirst
                        ? AppColors.success
                        : isLast
                            ? AppColors.info
                            : AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      position.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    isFirst
                        ? 'Première livraison'
                        : isLast
                            ? 'Dernière livraison'
                            : 'Livraison $position',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isFirst
                          ? AppColors.success
                          : isLast
                              ? AppColors.info
                              : AppColors.primary,
                    ),
                  ),
                ),
                Text(
                  '${delivery.deliveryFee.toStringAsFixed(0)} FCFA',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          // Détails de la livraison
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Point de récupération (boutique)
                Row(
                  children: [
                    const Icon(
                      Icons.store,
                      size: 18,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Récupération:',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            delivery.pickupAddress['shopName'] as String? ??
                                delivery.pickupAddress['address'] as String? ??
                                'Boutique',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.sm),

                // Adresse de livraison
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 20,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Livraison:',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            delivery.deliveryAddress['address'] as String? ??
                                delivery.deliveryAddress['city'] as String? ??
                                'Adresse non disponible',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.sm),

                // Package
                Row(
                  children: [
                    const Icon(
                      Icons.inventory_2_outlined,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        delivery.packageDescription,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.sm),

                // Distance
                Row(
                  children: [
                    const Icon(
                      Icons.straighten,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '${delivery.distance.toStringAsFixed(1)} km depuis la boutique',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _startGroupedDelivery(context),
            icon: const Icon(Icons.navigation, size: 20),
            label: const Text(
              'Démarrer la tournée',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _startGroupedDelivery(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Démarrer la tournée'),
        content: Text(
          'Vous allez démarrer une tournée de ${deliveries.length} livraisons.\n\n'
          'L\'itinéraire a été optimisé pour minimiser votre temps de trajet.\n\n'
          'Voulez-vous continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Démarrer'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      // Naviguer vers le premier point de livraison
      final firstDelivery = DeliveryGroupingService.optimizeRoute(deliveries).first;
      context.push('/livreur/delivery-detail/${firstDelivery.id}');
    }
  }
}

