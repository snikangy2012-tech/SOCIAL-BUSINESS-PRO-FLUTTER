// ===== lib/services/commission_enforcement_service.dart =====
// Service de gestion des versements de commissions vendeurs - SOCIAL BUSINESS Pro

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'subscription_service.dart';
import 'notification_service.dart';

/// Niveaux d'alerte pour les commissions impayées
enum CommissionAlertLevel {
  none,       // Pas d'alerte
  warning,    // Avertissement (50% du seuil)
  softBlock,  // Blocage partiel (75% du seuil)
  hardBlock,  // Blocage complet (100% du seuil)
}

/// Service de gestion des versements de commissions pour les vendeurs
///
/// Fonctionnalités:
/// - Tracking des commissions impayées
/// - Alertes progressives (Warning → Soft Block → Hard Block)
/// - Blocage automatique du compte vendeur
/// - Seuils basés sur l'abonnement
class CommissionEnforcementService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Seuils de commission impayée par tier d'abonnement (en FCFA)
  static const Map<String, double> _thresholdsByTier = {
    'basique': 50000,   // 50k FCFA
    'pro': 100000,      // 100k FCFA
    'premium': 150000,  // 150k FCFA
  };

  /// Vérifier le statut des commissions impayées d'un vendeur
  ///
  /// Retourne le niveau d'alerte actuel et met à jour les flags de blocage
  static Future<Map<String, dynamic>> checkCommissionStatus({
    required String vendorId,
  }) async {
    try {
      debugPrint('🔍 Vérification commissions vendeur $vendorId');

      // Récupérer les données du vendeur
      final vendorDoc = await _firestore.collection('users').doc(vendorId).get();

      if (!vendorDoc.exists) {
        throw Exception('Vendeur introuvable');
      }

      final vendorData = vendorDoc.data()!;
      final profile = vendorData['profile'] as Map<String, dynamic>? ?? {};

      // Récupérer le solde impayé
      final unpaidCommissions = (profile['unpaidCommissions'] as num?)?.toDouble() ?? 0.0;

      // Récupérer l'abonnement pour déterminer le seuil
      final subscriptionService = SubscriptionService();
      final subscription = await subscriptionService.getVendeurSubscription(vendorId);
      final tier = subscription?.tier.name ?? 'basique';
      final threshold = _thresholdsByTier[tier] ?? 50000.0;

      // Calculer le pourcentage du seuil atteint
      final percentageOfThreshold = (unpaidCommissions / threshold) * 100;

      // Déterminer le niveau d'alerte
      CommissionAlertLevel alertLevel;
      bool isBlockedForCommission = false;

      if (percentageOfThreshold >= 100) {
        alertLevel = CommissionAlertLevel.hardBlock;
        isBlockedForCommission = true;
      } else if (percentageOfThreshold >= 75) {
        alertLevel = CommissionAlertLevel.softBlock;
        isBlockedForCommission = false; // Avertissement sévère mais pas bloqué
      } else if (percentageOfThreshold >= 50) {
        alertLevel = CommissionAlertLevel.warning;
        isBlockedForCommission = false;
      } else {
        alertLevel = CommissionAlertLevel.none;
        isBlockedForCommission = false;
      }

      debugPrint('📊 Statut commissions:');
      debugPrint('   - Impayé: ${unpaidCommissions.toStringAsFixed(0)} FCFA');
      debugPrint('   - Seuil: ${threshold.toStringAsFixed(0)} FCFA');
      debugPrint('   - Pourcentage: ${percentageOfThreshold.toStringAsFixed(1)}%');
      debugPrint('   - Niveau alerte: ${alertLevel.name}');
      debugPrint('   - Bloqué: $isBlockedForCommission');

      // Mettre à jour les flags dans Firestore si nécessaire
      final currentAlertLevel = profile['commissionAlertLevel'] as String? ?? 'none';
      final currentIsBlocked = profile['isBlockedForCommission'] as bool? ?? false;

      if (currentAlertLevel != alertLevel.name || currentIsBlocked != isBlockedForCommission) {
        await _firestore.collection('users').doc(vendorId).update({
          'profile.commissionAlertLevel': alertLevel.name,
          'profile.isBlockedForCommission': isBlockedForCommission,
          'profile.lastCommissionCheck': FieldValue.serverTimestamp(),
        });

        debugPrint('✅ Flags de commission mis à jour');

        // Envoyer notification si niveau d'alerte a changé
        await _sendAlertNotification(
          vendorId: vendorId,
          alertLevel: alertLevel,
          unpaidAmount: unpaidCommissions,
          threshold: threshold,
        );
      }

      return {
        'unpaidCommissions': unpaidCommissions,
        'threshold': threshold,
        'percentageOfThreshold': percentageOfThreshold,
        'alertLevel': alertLevel.name,
        'isBlocked': isBlockedForCommission,
        'tier': tier,
      };

    } catch (e) {
      debugPrint('❌ Erreur vérification commissions: $e');
      rethrow;
    }
  }

  /// Vérifier si un vendeur est bloqué pour commissions impayées
  static Future<bool> isVendorBlocked(String vendorId) async {
    try {
      final vendorDoc = await _firestore.collection('users').doc(vendorId).get();

      if (!vendorDoc.exists) {
        return false;
      }

      final profile = vendorDoc.data()!['profile'] as Map<String, dynamic>? ?? {};
      return profile['isBlockedForCommission'] as bool? ?? false;

    } catch (e) {
      debugPrint('❌ Erreur vérification blocage vendeur: $e');
      return false;
    }
  }

  /// Enregistrer un versement de commission
  static Future<void> recordCommissionPayment({
    required String vendorId,
    required double amount,
    required String paymentMethod,
    String? transactionId,
  }) async {
    try {
      debugPrint('💳 Enregistrement versement commission: $amount FCFA');

      final vendorDoc = await _firestore.collection('users').doc(vendorId).get();

      if (!vendorDoc.exists) {
        throw Exception('Vendeur introuvable');
      }

      final profile = vendorDoc.data()!['profile'] as Map<String, dynamic>? ?? {};
      final unpaidCommissions = (profile['unpaidCommissions'] as num?)?.toDouble() ?? 0.0;

      // Calculer le nouveau solde (ne peut pas être négatif)
      final newBalance = (unpaidCommissions - amount).clamp(0.0, double.infinity);

      // Mettre à jour Firestore
      await _firestore.collection('users').doc(vendorId).update({
        'profile.unpaidCommissions': newBalance,
        'profile.lastCommissionPayment': FieldValue.serverTimestamp(),
        'profile.totalCommissionsPaid': FieldValue.increment(amount),
      });

      // Créer un enregistrement de transaction
      await _firestore.collection('commission_payments').add({
        'vendorId': vendorId,
        'amount': amount,
        'paymentMethod': paymentMethod,
        'transactionId': transactionId,
        'previousBalance': unpaidCommissions,
        'newBalance': newBalance,
        'paidAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Versement enregistré. Nouveau solde: ${newBalance.toStringAsFixed(0)} FCFA');

      // Re-vérifier le statut pour mettre à jour les alertes
      await checkCommissionStatus(vendorId: vendorId);

      // Notification de confirmation
      await NotificationService().createNotification(
        userId: vendorId,
        type: 'commission_payment_confirmed',
        title: '✅ Versement confirmé',
        body: 'Votre versement de ${amount.toStringAsFixed(0)} FCFA a été enregistré',
        data: {
          'amount': amount,
          'newBalance': newBalance,
          'route': '/vendeur/commissions',
        },
      );

    } catch (e) {
      debugPrint('❌ Erreur enregistrement versement: $e');
      rethrow;
    }
  }

  /// Envoyer une notification d'alerte selon le niveau
  static Future<void> _sendAlertNotification({
    required String vendorId,
    required CommissionAlertLevel alertLevel,
    required double unpaidAmount,
    required double threshold,
  }) async {
    try {
      String title;
      String body;
      String type;

      switch (alertLevel) {
        case CommissionAlertLevel.warning:
          title = '⚠️ Attention - Commissions à verser';
          body = 'Vous avez ${unpaidAmount.toStringAsFixed(0)} FCFA de commissions impayées (seuil: ${threshold.toStringAsFixed(0)} FCFA)';
          type = 'commission_warning';
          break;

        case CommissionAlertLevel.softBlock:
          title = '🚨 Urgent - Versement requis';
          body = 'Vous approchez du seuil de blocage. Versez ${unpaidAmount.toStringAsFixed(0)} FCFA rapidement.';
          type = 'commission_soft_block';
          break;

        case CommissionAlertLevel.hardBlock:
          title = '🔒 Compte bloqué - Commissions impayées';
          body = 'Votre compte est bloqué. Versez ${unpaidAmount.toStringAsFixed(0)} FCFA pour le débloquer.';
          type = 'commission_hard_block';
          break;

        case CommissionAlertLevel.none:
          return; // Pas de notification
      }

      await NotificationService().createNotification(
        userId: vendorId,
        type: type,
        title: title,
        body: body,
        data: {
          'unpaidAmount': unpaidAmount,
          'threshold': threshold,
          'alertLevel': alertLevel.name,
          'route': '/vendeur/commissions',
          'action': 'pay_commissions',
        },
      );

      debugPrint('📬 Notification d\'alerte envoyée: ${alertLevel.name}');

    } catch (e) {
      debugPrint('❌ Erreur envoi notification alerte: $e');
    }
  }

  /// Obtenir l'historique des versements d'un vendeur
  static Future<List<Map<String, dynamic>>> getPaymentHistory({
    required String vendorId,
    int limit = 20,
  }) async {
    try {
      final paymentsSnapshot = await _firestore
          .collection('commission_payments')
          .where('vendorId', isEqualTo: vendorId)
          .orderBy('paidAt', descending: true)
          .limit(limit)
          .get();

      return paymentsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();

    } catch (e) {
      debugPrint('❌ Erreur récupération historique: $e');
      return [];
    }
  }

  /// Calculer les statistiques de commission d'un vendeur
  static Future<Map<String, dynamic>> getCommissionStats({
    required String vendorId,
  }) async {
    try {
      final vendorDoc = await _firestore.collection('users').doc(vendorId).get();

      if (!vendorDoc.exists) {
        throw Exception('Vendeur introuvable');
      }

      final profile = vendorDoc.data()!['profile'] as Map<String, dynamic>? ?? {};

      final unpaidCommissions = (profile['unpaidCommissions'] as num?)?.toDouble() ?? 0.0;
      final totalCommissionsPaid = (profile['totalCommissionsPaid'] as num?)?.toDouble() ?? 0.0;
      final totalCommissions = unpaidCommissions + totalCommissionsPaid;

      // Récupérer le seuil
      final subscriptionService = SubscriptionService();
      final subscription = await subscriptionService.getVendeurSubscription(vendorId);
      final tier = subscription?.tier.name ?? 'basique';
      final threshold = _thresholdsByTier[tier] ?? 50000.0;

      return {
        'unpaidCommissions': unpaidCommissions,
        'totalCommissionsPaid': totalCommissionsPaid,
        'totalCommissions': totalCommissions,
        'threshold': threshold,
        'percentageOfThreshold': (unpaidCommissions / threshold) * 100,
        'tier': tier,
      };

    } catch (e) {
      debugPrint('❌ Erreur statistiques commissions: $e');
      return {
        'unpaidCommissions': 0.0,
        'totalCommissionsPaid': 0.0,
        'totalCommissions': 0.0,
        'threshold': 50000.0,
        'percentageOfThreshold': 0.0,
        'tier': 'basique',
      };
    }
  }
}
