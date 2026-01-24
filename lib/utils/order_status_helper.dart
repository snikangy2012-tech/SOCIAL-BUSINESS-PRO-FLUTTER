// ===== lib/utils/order_status_helper.dart =====
// Helper pour la traduction et l'affichage des statuts de commande

import 'package:flutter/material.dart';
import '../config/constants.dart';

class OrderStatusHelper {
  /// Traduire le statut en français
  static String getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      // Statuts en attente
      case 'en_attente':
      case 'pending':
        return 'En attente';

      // Statuts confirmés
      case 'confirmed':
        return 'Confirmée';

      case 'ready':
        return 'Prête';

      case 'preparing':
        return 'En préparation';

      // Statuts en cours
      case 'en_cours':
      case 'in_delivery':
        return 'En cours de livraison';

      // Statuts livrés
      case 'livree':
      case 'delivered':
      case 'completed':
        return 'Livrée';

      // Statuts annulés
      case 'annulee':
      case 'cancelled':
      case 'canceled':
        return 'Annulée';

      // Statuts retournés
      case 'retourne':
      case 'retournee':
      case 'returned':
        return 'Retournée';

      // Autres statuts
      case 'all':
        return 'Toutes';

      default:
        return status; // Retourner le statut tel quel si pas de traduction
    }
  }

  /// Obtenir la couleur selon le statut
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'en_attente':
      case 'pending':
        return const Color.fromARGB(255, 245, 226, 11); // Jaune

      case 'confirmed':
      case 'ready':
      case 'preparing':
        return AppColors.info; // Bleu

      case 'en_cours':
      case 'in_delivery':
        return AppColors.warning; // Orange (en livraison)

      case 'livree':
      case 'delivered':
      case 'completed':
        return AppColors.success; // Vert

      case 'annulee':
      case 'cancelled':
      case 'canceled':
        return AppColors.error; // Rouge

      case 'retourne':
      case 'retournee':
      case 'returned':
        return const Color.fromARGB(255, 156, 39, 176); // Violet

      default:
        return AppColors.textLight;
    }
  }

  /// Obtenir l'icône selon le statut
  static IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'en_attente':
      case 'pending':
        return Icons.schedule; // Horloge

      case 'confirmed':
        return Icons.check_circle_outline; // Cercle coché

      case 'ready':
        return Icons.shopping_bag_outlined; // Sac prêt

      case 'preparing':
        return Icons.kitchen_outlined; // En préparation

      case 'en_cours':
      case 'in_delivery':
        return Icons.delivery_dining; // Livreur en route

      case 'livree':
      case 'delivered':
      case 'completed':
        return Icons.check_circle; // Coché vert

      case 'annulee':
      case 'cancelled':
      case 'canceled':
        return Icons.cancel; // Annulé

      case 'retourne':
      case 'retournee':
      case 'returned':
        return Icons.keyboard_return; // Retour

      default:
        return Icons.receipt; // Facture par défaut
    }
  }

  /// Badge de statut prêt à l'emploi
  static Widget statusBadge(String status, {bool compact = false}) {
    final color = getStatusColor(status);
    final label = getStatusLabel(status);
    final icon = getStatusIcon(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(compact ? 4 : 6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 14 : 16, color: color),
          SizedBox(width: compact ? 4 : 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: compact ? 11 : 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
