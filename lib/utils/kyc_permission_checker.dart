import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../services/kyc_adaptive_service.dart';
import '../config/constants.dart';

/// Utilitaire pour vérifier les permissions KYC avant actions critiques
class KYCPermissionChecker {
  /// Vérifier si l'utilisateur peut créer une commande
  static Future<bool> canCreateOrder({
    required BuildContext context,
    required String userId,
    required double orderValue,
    bool showDialog = true,
  }) async {
    try {
      // Compter les commandes du jour
      final dailyOrders = await _getDailyOrderCount(userId);

      // Vérifier permission
      final permission = await KYCAdaptiveService.canPerformAction(
        userId: userId,
        action: 'create_order',
        orderValue: orderValue,
        currentDailyOrders: dailyOrders,
      );

      if (!permission.allowed && showDialog && context.mounted) {
        _showLimitDialog(
          context: context,
          permission: permission,
        );
      }

      return permission.allowed;
    } catch (e) {
      debugPrint('❌ Erreur vérification permission commande: $e');
      // En cas d'erreur, on autorise (fail-open pour bonne UX)
      return true;
    }
  }

  /// Vérifier si le livreur peut accepter une livraison
  static Future<bool> canAcceptDelivery({
    required BuildContext context,
    required String userId,
    bool showDialog = true,
  }) async {
    try {
      final dailyDeliveries = await _getDailyDeliveryCount(userId);

      final permission = await KYCAdaptiveService.canPerformAction(
        userId: userId,
        action: 'accept_delivery',
        currentDailyOrders: dailyDeliveries,
      );

      if (!permission.allowed && showDialog && context.mounted) {
        _showLimitDialog(
          context: context,
          permission: permission,
        );
      }

      return permission.allowed;
    } catch (e) {
      debugPrint('❌ Erreur vérification permission livraison: $e');
      return true;
    }
  }

  /// Vérifier si l'utilisateur peut retirer ses gains
  static Future<bool> canWithdrawEarnings({
    required BuildContext context,
    required String userId,
    bool showDialog = true,
  }) async {
    try {
      final permission = await KYCAdaptiveService.canPerformAction(
        userId: userId,
        action: 'withdraw_earnings',
      );

      if (!permission.allowed && showDialog && context.mounted) {
        _showLimitDialog(
          context: context,
          permission: permission,
        );
      }

      return permission.allowed;
    } catch (e) {
      debugPrint('❌ Erreur vérification permission retrait: $e');
      return true;
    }
  }

  /// Afficher le dialog de limite
  static void _showLimitDialog({
    required BuildContext context,
    required ActionPermissionResult permission,
  }) {
    final bool needsKYC = permission.suggestedAction?.contains('KYC') ?? false;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              needsKYC ? Icons.warning_amber : Icons.info,
              color: needsKYC ? AppColors.warning : AppColors.info,
            ),
            const SizedBox(width: AppSpacing.sm),
            const Expanded(
              child: Text('Limite atteinte'),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              permission.reason ?? 'Limite atteinte',
              style: const TextStyle(
                fontSize: AppFontSizes.md,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (permission.suggestedAction != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: needsKYC
                      ? AppColors.warning.withOpacity(0.1)
                      : AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: needsKYC ? AppColors.warning : AppColors.info,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb,
                      color: needsKYC ? AppColors.warning : AppColors.info,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        permission.suggestedAction!,
                        style: TextStyle(
                          fontSize: AppFontSizes.sm,
                          color: needsKYC ? AppColors.warning : AppColors.info,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (needsKYC) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.success.withOpacity(0.1),
                      AppColors.primary.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star, color: AppColors.warning, size: 20),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          '🎁 Bonus 5 000 FCFA',
                          style: TextStyle(
                            fontSize: AppFontSizes.md,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Complétez votre vérification en 2 minutes',
                      style: TextStyle(
                        fontSize: AppFontSizes.sm,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(needsKYC ? 'Plus tard' : 'Compris'),
          ),
          if (needsKYC)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                context.push('/kyc-upload');
              },
              icon: const Icon(Icons.verified_user),
              label: const Text('Vérifier maintenant'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  /// Compter les commandes du jour pour un vendeur
  static Future<int> _getDailyOrderCount(String userId) async {
    try {
      // Calculer le début de la journée
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      // Requête Firestore
      final snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('vendorId', isEqualTo: userId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .get()
          .timeout(const Duration(seconds: 5));

      return snapshot.docs.length;
    } catch (e) {
      debugPrint('⚠️ Erreur comptage commandes: $e');
      return 0; // En cas d'erreur, on retourne 0 (pas de blocage)
    }
  }

  /// Compter les livraisons du jour pour un livreur
  static Future<int> _getDailyDeliveryCount(String userId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final snapshot = await FirebaseFirestore.instance
          .collection('deliveries')
          .where('livreurId', isEqualTo: userId)
          .where('assignedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .get()
          .timeout(const Duration(seconds: 5));

      return snapshot.docs.length;
    } catch (e) {
      debugPrint('⚠️ Erreur comptage livraisons: $e');
      return 0;
    }
  }
}
