// ===== lib/widgets/livreur_trust_badge.dart =====
// Widget pour afficher le badge de niveau de confiance d'un livreur

import 'package:flutter/material.dart';
import '../models/livreur_trust_level.dart';

class LivreurTrustBadge extends StatelessWidget {
  final LivreurTrustLevel level;
  final bool showLabel;
  final double size;

  const LivreurTrustBadge({
    super.key,
    required this.level,
    this.showLabel = true,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getBadgeConfig(level);

    if (!showLabel) {
      // Badge compact (icône seulement)
      return Container(
        padding: EdgeInsets.all(size / 6),
        decoration: BoxDecoration(
          color: config.color.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: config.color, width: 2),
        ),
        child: Text(
          config.icon,
          style: TextStyle(fontSize: size),
        ),
      );
    }

    // Badge complet avec label
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size / 2,
        vertical: size / 4,
      ),
      decoration: BoxDecoration(
        color: config.color,
        borderRadius: BorderRadius.circular(size),
        border: Border.all(color: config.borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: config.color.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            config.icon,
            style: TextStyle(fontSize: size),
          ),
          SizedBox(width: size / 4),
          Text(
            config.label,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: size * 0.6,
            ),
          ),
        ],
      ),
    );
  }

  _BadgeConfig _getBadgeConfig(LivreurTrustLevel level) {
    switch (level) {
      case LivreurTrustLevel.vip:
        return _BadgeConfig(
          label: 'VIP',
          icon: '🌟',
          color: const Color(0xFF9C27B0), // Purple
          borderColor: const Color(0xFFFFD700), // Gold
        );
      case LivreurTrustLevel.expert:
        return _BadgeConfig(
          label: 'Expert',
          icon: '⚡',
          color: const Color(0xFF2196F3), // Blue
          borderColor: const Color(0xFF64B5F6), // Light blue
        );
      case LivreurTrustLevel.confirme:
        return _BadgeConfig(
          label: 'Confirmé',
          icon: '✓',
          color: const Color(0xFF4CAF50), // Green
          borderColor: const Color(0xFF81C784), // Light green
        );
      case LivreurTrustLevel.debutant:
        return _BadgeConfig(
          label: 'Débutant',
          icon: '🔰',
          color: const Color(0xFF757575), // Grey
          borderColor: const Color(0xFF9E9E9E), // Light grey
        );
    }
  }
}

class _BadgeConfig {
  final String label;
  final String icon;
  final Color color;
  final Color borderColor;

  _BadgeConfig({
    required this.label,
    required this.icon,
    required this.color,
    required this.borderColor,
  });
}

/// Widget pour afficher les détails du niveau avec progression
class LivreurTrustCard extends StatelessWidget {
  final LivreurTrustConfig config;
  final int completedDeliveries;
  final double averageRating;
  final double? currentBalance;

  const LivreurTrustCard({
    super.key,
    required this.config,
    required this.completedDeliveries,
    required this.averageRating,
    this.currentBalance,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Niveau de confiance',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                LivreurTrustBadge(level: config.level, size: 20),
              ],
            ),

            const SizedBox(height: 16),

            // Statistiques
            _buildStatRow(
              icon: Icons.local_shipping,
              label: 'Livraisons complétées',
              value: completedDeliveries.toString(),
            ),
            const SizedBox(height: 8),
            _buildStatRow(
              icon: Icons.star,
              label: 'Note moyenne',
              value: averageRating.toStringAsFixed(1),
            ),
            const SizedBox(height: 8),
            _buildStatRow(
              icon: Icons.account_balance_wallet,
              label: 'Montant max/commande',
              value: '${config.maxOrderAmount.toStringAsFixed(0)} FCFA',
            ),

            if (currentBalance != null) ...[
              const SizedBox(height: 8),
              _buildStatRow(
                icon: Icons.pending_actions,
                label: 'Non reversé',
                value: '${currentBalance!.toStringAsFixed(0)} FCFA',
                valueColor: _getBalanceColor(currentBalance!, config.maxUnpaidBalance),
              ),
              const SizedBox(height: 8),
              // Barre de progression
              LinearProgressIndicator(
                value: (currentBalance! / config.maxUnpaidBalance).clamp(0.0, 1.0),
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation(
                  _getBalanceColor(currentBalance!, config.maxUnpaidBalance),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Limite: ${config.maxUnpaidBalance.toStringAsFixed(0)} FCFA',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],

            const Divider(height: 24),

            // Avantages du niveau
            Text(
              'Avantages',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildAdvantageRow(
              icon: Icons.check_circle,
              text: 'Commandes jusqu\'à ${config.maxOrderAmount.toStringAsFixed(0)} FCFA',
            ),
            _buildAdvantageRow(
              icon: Icons.check_circle,
              text: 'Délai de reversement: ${_formatDelay(config.reversementDelayHours)}',
            ),
            if (config.level != LivreurTrustLevel.debutant)
              _buildAdvantageRow(
                icon: Icons.check_circle,
                text: 'Caution: ${config.cautionRequired.toStringAsFixed(0)} FCFA',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: valueColor ?? Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildAdvantageRow({
    required IconData icon,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Color _getBalanceColor(double current, double max) {
    final percentage = (current / max) * 100;
    if (percentage >= 90) return Colors.red;
    if (percentage >= 70) return Colors.orange;
    return Colors.green;
  }

  String _formatDelay(int hours) {
    if (hours >= 168) return '${(hours / 168).round()} semaine(s)';
    if (hours >= 24) return '${(hours / 24).round()} jour(s)';
    return '$hours heure(s)';
  }
}
