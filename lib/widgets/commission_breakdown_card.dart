// ===== lib/widgets/commission_breakdown_card.dart =====
// Widget d'affichage détaillé des commissions - SOCIAL BUSINESS Pro

import 'package:flutter/material.dart';
import '../config/constants.dart';
import '../utils/number_formatter.dart';

/// Card affichant la décomposition des commissions d'une livraison
class CommissionBreakdownCard extends StatelessWidget {
  final Map<String, dynamic> commissionData;
  final bool showDetails;

  const CommissionBreakdownCard({
    super.key,
    required this.commissionData,
    this.showDetails = true,
  });

  @override
  Widget build(BuildContext context) {
    final orderAmount = (commissionData['orderAmount'] as num?)?.toDouble() ?? 0.0;
    final baseRate = (commissionData['baseRate'] as num?)?.toDouble() ?? 0.0;
    final trustBonus = (commissionData['trustBonus'] as num?)?.toDouble() ?? 0.0;
    final performanceBonus = (commissionData['performanceBonus'] as num?)?.toDouble() ?? 0.0;
    final finalRate = (commissionData['finalRate'] as num?)?.toDouble() ?? 0.0;
    final commissionAmount = (commissionData['commissionAmount'] as num?)?.toDouble() ?? 0.0;
    final livreurEarnings = (commissionData['livreurEarnings'] as num?)?.toDouble() ?? 0.0;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Détails de commission',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Montant de la commande
            _buildInfoRow(
              'Montant commande',
              formatPriceWithCurrency(orderAmount, currency: 'FCFA'),
              isHighlight: false,
            ),
            const Divider(height: 24),

            if (showDetails) ...[
              // Détails du calcul
              const Text(
                'Calcul de la commission:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),

              // Taux de base
              _buildRateRow(
                'Taux de base (abonnement)',
                baseRate,
                null,
              ),

              // Bonus niveau de confiance
              if (trustBonus != 0)
                _buildRateRow(
                  'Bonus niveau de confiance',
                  trustBonus,
                  trustBonus < 0 ? Colors.green : Colors.orange,
                ),

              // Bonus performance
              if (performanceBonus != 0)
                _buildRateRow(
                  'Bonus performance (note)',
                  performanceBonus,
                  performanceBonus < 0 ? Colors.green : Colors.orange,
                ),

              const Divider(height: 24),
            ],

            // Taux final
            _buildRateRow(
              'Taux final appliqué',
              finalRate,
              AppColors.primary,
              isBold: true,
            ),
            const SizedBox(height: 16),

            // Commission plateforme
            _buildAmountRow(
              'Commission plateforme',
              commissionAmount,
              AppColors.error,
              icon: Icons.remove_circle_outline,
            ),
            const SizedBox(height: 8),

            // Vos gains
            _buildAmountRow(
              'Vos gains',
              livreurEarnings,
              AppColors.success,
              icon: Icons.add_circle_outline,
              isBold: true,
            ),

            // Info supplémentaire
            if (showDetails && commissionData.containsKey('trustLevel')) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.info,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Niveau: ${_getTrustLevelLabel(commissionData['trustLevel'] as String?)} • '
                        'Note: ${(commissionData['averageRating'] as num?)?.toStringAsFixed(1) ?? "N/A"}★',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isHighlight ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: isHighlight ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
            color: isHighlight ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildRateRow(String label, double rate, Color? color, {bool isBold = false}) {
    final percentage = (rate * 100).toStringAsFixed(1);
    final isNegative = rate < 0;
    final displayText = '${isNegative ? '' : '+'}$percentage%';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          Text(
            displayText,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountRow(
    String label,
    double amount,
    Color color, {
    IconData? icon,
    bool isBold = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: color,
              ),
            ),
          ),
          Text(
            formatPriceWithCurrency(amount, currency: 'FCFA'),
            style: TextStyle(
              fontSize: isBold ? 16 : 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _getTrustLevelLabel(String? level) {
    switch (level) {
      case 'debutant':
        return 'Débutant';
      case 'confirme':
        return 'Confirmé';
      case 'expert':
        return 'Expert';
      case 'vip':
        return 'VIP';
      default:
        return 'Inconnu';
    }
  }
}

/// Widget affichant la comparaison des gains selon les niveaux
class CommissionComparisonCard extends StatelessWidget {
  final Map<String, dynamic> simulationData;

  const CommissionComparisonCard({
    super.key,
    required this.simulationData,
  });

  @override
  Widget build(BuildContext context) {
    final orderAmount = (simulationData['orderAmount'] as num?)?.toDouble() ?? 0.0;
    final scenarios = simulationData['scenarios'] as Map<String, dynamic>? ?? {};

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.trending_up,
                    color: AppColors.success,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Gagnez plus en montant de niveau',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Pour une commande de ${formatPriceWithCurrency(orderAmount, currency: 'FCFA')}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),

            // Liste des niveaux
            ...['debutant', 'confirme', 'expert', 'vip'].map((level) {
              final scenario = scenarios[level] as Map<String, dynamic>?;
              if (scenario == null) return const SizedBox.shrink();

              final earnings = (scenario['livreurEarnings'] as num?)?.toDouble() ?? 0.0;
              final savings = (scenario['savingsVsDebutant'] as num?)?.toDouble() ?? 0.0;

              return _buildLevelRow(
                level,
                earnings,
                savings,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelRow(String level, double earnings, double savings) {
    final levelData = _getLevelData(level);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: levelData['color'].withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: levelData['color'].withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Badge niveau
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: levelData['color'],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              levelData['label'],
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Gains
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatPriceWithCurrency(earnings, currency: 'FCFA'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (savings > 0)
                  Text(
                    '+${formatPriceWithCurrency(savings, currency: 'FCFA')} vs Débutant',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),

          // Icône
          if (savings > 0)
            Icon(
              Icons.arrow_upward,
              color: AppColors.success,
              size: 18,
            ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getLevelData(String level) {
    switch (level) {
      case 'debutant':
        return {'label': 'Débutant', 'color': Colors.grey};
      case 'confirme':
        return {'label': 'Confirmé', 'color': Colors.blue};
      case 'expert':
        return {'label': 'Expert', 'color': Colors.purple};
      case 'vip':
        return {'label': 'VIP', 'color': Colors.amber};
      default:
        return {'label': 'Inconnu', 'color': Colors.grey};
    }
  }
}
