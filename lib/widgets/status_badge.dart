import 'package:flutter/material.dart';
import '../config/constants.dart';

enum BadgeStyle {
  filled,   // Fond coloré, texte blanc
  outlined, // Bordure colorée, texte coloré
  soft,     // Fond léger, texte coloré (style moderne)
}

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final BadgeStyle style;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.style = BadgeStyle.soft,
    this.icon,
  });

  /// Factory pour statut de commande
  factory StatusBadge.orderStatus(String status) {
    switch (status) {
      case 'en_attente':
        return StatusBadge(
          label: 'En attente',
          color: AppColors.warning,
          icon: Icons.schedule,
        );
      case 'en_cours':
        return StatusBadge(
          label: 'En cours',
          color: AppColors.info,
          icon: Icons.local_shipping,
        );
      case 'livree':
        return StatusBadge(
          label: 'Livrée',
          color: AppColors.success,
          icon: Icons.check_circle,
        );
      case 'annulee':
        return StatusBadge(
          label: 'Annulée',
          color: AppColors.error,
          icon: Icons.cancel,
        );
      default:
        return StatusBadge(
          label: status,
          color: Colors.grey,
        );
    }
  }

  /// Factory pour statut de livraison
  factory StatusBadge.deliveryStatus(String status) {
    switch (status) {
      case 'available':
        return StatusBadge(
          label: 'Disponible',
          color: AppColors.info,
          icon: Icons.check,
        );
      case 'assigned':
        return StatusBadge(
          label: 'Assignée',
          color: AppColors.warning,
          icon: Icons.person,
        );
      case 'picked_up':
        return StatusBadge(
          label: 'Récupérée',
          color: const Color(0xFF9C27B0), // Violet
          icon: Icons.local_shipping,
        );
      case 'in_transit':
        return StatusBadge(
          label: 'En transit',
          color: AppColors.primary,
          icon: Icons.navigation,
        );
      case 'delivered':
        return StatusBadge(
          label: 'Livrée',
          color: AppColors.success,
          icon: Icons.done_all,
        );
      case 'cancelled':
        return StatusBadge(
          label: 'Annulée',
          color: AppColors.error,
          icon: Icons.cancel,
        );
      default:
        return StatusBadge(
          label: status,
          color: Colors.grey,
        );
    }
  }

  /// Factory pour statut de paiement
  factory StatusBadge.paymentStatus(String status) {
    switch (status) {
      case 'pending':
        return StatusBadge(
          label: 'En attente',
          color: AppColors.warning,
          icon: Icons.schedule,
        );
      case 'paid':
        return StatusBadge(
          label: 'Payé',
          color: AppColors.success,
          icon: Icons.check_circle,
        );
      case 'failed':
        return StatusBadge(
          label: 'Échoué',
          color: AppColors.error,
          icon: Icons.error,
        );
      case 'refunded':
        return StatusBadge(
          label: 'Remboursé',
          color: AppColors.info,
          icon: Icons.refresh,
        );
      default:
        return StatusBadge(
          label: status,
          color: Colors.grey,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        border: style == BadgeStyle.outlined
            ? Border.all(color: color, width: 1.5)
            : null,
        borderRadius: BorderRadius.circular(20), // Pill shape
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 14,
              color: _getTextColor(),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: _getTextColor(),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (style) {
      case BadgeStyle.filled:
        return color;
      case BadgeStyle.outlined:
        return Colors.transparent;
      case BadgeStyle.soft:
        return color.withOpacity(0.15);
    }
  }

  Color _getTextColor() {
    switch (style) {
      case BadgeStyle.filled:
        return Colors.white;
      case BadgeStyle.outlined:
      case BadgeStyle.soft:
        return color;
    }
  }
}
