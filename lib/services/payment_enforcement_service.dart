// ===== lib/services/payment_enforcement_service.dart =====
// Service de gestion des versements pour livreurs - SOCIAL BUSINESS Pro

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/livreur_trust_level.dart';
import 'notification_service.dart';

/// Niveaux d'alerte pour les paiements non effectués
enum PaymentAlertLevel {
  none,       // Pas d'alerte
  warning,    // Avertissement (50% du seuil)
  softBlock,  // Blocage partiel (75% du seuil)
  hardBlock,  // Blocage complet (100% du seuil)
}

/// Service de gestion des versements pour les livreurs
///
/// Fonctionnalités:
/// - Tracking des montants collectés non versés
/// - Alertes progressives (Warning → Soft Block → Hard Block)
/// - Blocage automatique du compte livreur
/// - Seuils basés sur le niveau de confiance (Trust Level)
class PaymentEnforcementService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Seuils de paiement impayé par niveau de confiance (en FCFA)
  static const Map<String, double> _thresholdsByTrustLevel = {
    'debutant': 30000,   // 30k FCFA
    'confirme': 75000,   // 75k FCFA
    'expert': 100000,    // 100k FCFA
    'vip': 150000,       // 150k FCFA
  };

  /// Vérifier le statut des paiements non effectués d'un livreur
  ///
  /// Retourne le niveau d'alerte actuel et met à jour les flags de blocage
  static Future<Map<String, dynamic>> checkPaymentStatus({
    required String livreurId,
  }) async {
    try {
      debugPrint('🔍 Vérification paiements livreur $livreurId');

      // Récupérer les données du livreur
      final livreurDoc = await _firestore.collection('users').doc(livreurId).get();

      if (!livreurDoc.exists) {
        throw Exception('Livreur introuvable');
      }

      final livreurData = livreurDoc.data()!;
      final profile = livreurData['profile'] as Map<String, dynamic>? ?? {};

      // Récupérer le solde impayé
      final unpaidBalance = (profile['unpaidBalance'] as num?)?.toDouble() ?? 0.0;

      // Calculer le niveau de confiance
      final completedDeliveries = profile['completedDeliveries'] as int? ?? 0;
      final averageRating = (profile['averageRating'] as num? ?? 0.0).toDouble();
      final cautionDeposited = (profile['cautionDeposited'] as num? ?? 0.0).toDouble();

      final trustConfig = LivreurTrustConfig.getConfig(
        completedDeliveries: completedDeliveries,
        averageRating: averageRating,
        cautionDeposited: cautionDeposited,
      );

      final trustLevel = trustConfig.level.name;
      final threshold = _thresholdsByTrustLevel[trustLevel] ?? 30000.0;

      // Calculer le pourcentage du seuil atteint
      final percentageOfThreshold = (unpaidBalance / threshold) * 100;

      // Déterminer le niveau d'alerte
      PaymentAlertLevel alertLevel;
      bool isBlockedForPayment = false;

      if (percentageOfThreshold >= 100) {
        alertLevel = PaymentAlertLevel.hardBlock;
        isBlockedForPayment = true;
      } else if (percentageOfThreshold >= 75) {
        alertLevel = PaymentAlertLevel.softBlock;
        isBlockedForPayment = false; // Avertissement sévère mais pas bloqué
      } else if (percentageOfThreshold >= 50) {
        alertLevel = PaymentAlertLevel.warning;
        isBlockedForPayment = false;
      } else {
        alertLevel = PaymentAlertLevel.none;
        isBlockedForPayment = false;
      }

      debugPrint('📊 Statut paiements:');
      debugPrint('   - Impayé: ${unpaidBalance.toStringAsFixed(0)} FCFA');
      debugPrint('   - Seuil: ${threshold.toStringAsFixed(0)} FCFA');
      debugPrint('   - Pourcentage: ${percentageOfThreshold.toStringAsFixed(1)}%');
      debugPrint('   - Niveau confiance: $trustLevel');
      debugPrint('   - Niveau alerte: ${alertLevel.name}');
      debugPrint('   - Bloqué: $isBlockedForPayment');

      // Mettre à jour les flags dans Firestore si nécessaire
      final currentAlertLevel = profile['paymentAlertLevel'] as String? ?? 'none';
      final currentIsBlocked = profile['isBlockedForPayment'] as bool? ?? false;

      if (currentAlertLevel != alertLevel.name || currentIsBlocked != isBlockedForPayment) {
        await _firestore.collection('users').doc(livreurId).update({
          'profile.paymentAlertLevel': alertLevel.name,
          'profile.isBlockedForPayment': isBlockedForPayment,
          'profile.lastPaymentCheck': FieldValue.serverTimestamp(),
        });

        debugPrint('✅ Flags de paiement mis à jour');

        // Envoyer notification si niveau d'alerte a changé
        await _sendAlertNotification(
          livreurId: livreurId,
          alertLevel: alertLevel,
          unpaidAmount: unpaidBalance,
          threshold: threshold,
        );
      }

      return {
        'unpaidBalance': unpaidBalance,
        'threshold': threshold,
        'percentageOfThreshold': percentageOfThreshold,
        'alertLevel': alertLevel.name,
        'isBlocked': isBlockedForPayment,
        'trustLevel': trustLevel,
      };

    } catch (e) {
      debugPrint('❌ Erreur vérification paiements: $e');
      rethrow;
    }
  }

  /// Vérifier si un livreur est bloqué pour paiements non effectués
  static Future<bool> isLivreurBlocked(String livreurId) async {
    try {
      final livreurDoc = await _firestore.collection('users').doc(livreurId).get();

      if (!livreurDoc.exists) {
        return false;
      }

      final profile = livreurDoc.data()!['profile'] as Map<String, dynamic>? ?? {};
      return profile['isBlockedForPayment'] as bool? ?? false;

    } catch (e) {
      debugPrint('❌ Erreur vérification blocage livreur: $e');
      return false;
    }
  }

  /// Enregistrer un versement de paiement (dépôt)
  static Future<void> recordPaymentDeposit({
    required String livreurId,
    required double amount,
    required String paymentMethod,
    String? transactionId,
  }) async {
    try {
      debugPrint('💳 Enregistrement dépôt: $amount FCFA');

      final livreurDoc = await _firestore.collection('users').doc(livreurId).get();

      if (!livreurDoc.exists) {
        throw Exception('Livreur introuvable');
      }

      final profile = livreurDoc.data()!['profile'] as Map<String, dynamic>? ?? {};
      final unpaidBalance = (profile['unpaidBalance'] as num?)?.toDouble() ?? 0.0;

      // Calculer le nouveau solde (ne peut pas être négatif)
      final newBalance = (unpaidBalance - amount).clamp(0.0, double.infinity);

      // Mettre à jour Firestore
      await _firestore.collection('users').doc(livreurId).update({
        'profile.unpaidBalance': newBalance,
        'profile.lastPaymentDate': FieldValue.serverTimestamp(),
        'profile.totalPaymentsDeposited': FieldValue.increment(amount),
      });

      // Créer un enregistrement de transaction
      await _firestore.collection('livreur_deposits').add({
        'livreurId': livreurId,
        'amount': amount,
        'paymentMethod': paymentMethod,
        'transactionId': transactionId,
        'previousBalance': unpaidBalance,
        'newBalance': newBalance,
        'depositedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Dépôt enregistré. Nouveau solde: ${newBalance.toStringAsFixed(0)} FCFA');

      // Re-vérifier le statut pour mettre à jour les alertes
      await checkPaymentStatus(livreurId: livreurId);

      // Notification de confirmation
      await NotificationService().createNotification(
        userId: livreurId,
        type: 'payment_deposit_confirmed',
        title: '✅ Dépôt confirmé',
        body: 'Votre dépôt de ${amount.toStringAsFixed(0)} FCFA a été enregistré',
        data: {
          'amount': amount,
          'newBalance': newBalance,
          'route': '/livreur/payments',
        },
      );

    } catch (e) {
      debugPrint('❌ Erreur enregistrement dépôt: $e');
      rethrow;
    }
  }

  /// Incrémenter le solde impayé après une livraison
  ///
  /// À appeler quand un livreur complète une livraison et collecte l'argent
  static Future<void> incrementUnpaidBalance({
    required String livreurId,
    required double amount,
    required String orderId,
  }) async {
    try {
      debugPrint('💰 Ajout au solde impayé: $amount FCFA (Order: $orderId)');

      await _firestore.collection('users').doc(livreurId).update({
        'profile.unpaidBalance': FieldValue.increment(amount),
        'profile.lastCollectionDate': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Solde impayé mis à jour');

      // Vérifier le statut après l'ajout
      await checkPaymentStatus(livreurId: livreurId);

    } catch (e) {
      debugPrint('❌ Erreur incrémentation solde: $e');
      rethrow;
    }
  }

  /// Envoyer une notification d'alerte selon le niveau
  static Future<void> _sendAlertNotification({
    required String livreurId,
    required PaymentAlertLevel alertLevel,
    required double unpaidAmount,
    required double threshold,
  }) async {
    try {
      String title;
      String body;
      String type;

      switch (alertLevel) {
        case PaymentAlertLevel.warning:
          title = '⚠️ Attention - Versement à faire';
          body = 'Vous avez collecté ${unpaidAmount.toStringAsFixed(0)} FCFA à verser (seuil: ${threshold.toStringAsFixed(0)} FCFA)';
          type = 'payment_warning';
          break;

        case PaymentAlertLevel.softBlock:
          title = '🚨 Urgent - Dépôt requis';
          body = 'Vous approchez du seuil de blocage. Déposez ${unpaidAmount.toStringAsFixed(0)} FCFA rapidement.';
          type = 'payment_soft_block';
          break;

        case PaymentAlertLevel.hardBlock:
          title = '🔒 Compte bloqué - Paiements non effectués';
          body = 'Votre compte est bloqué. Déposez ${unpaidAmount.toStringAsFixed(0)} FCFA pour le débloquer.';
          type = 'payment_hard_block';
          break;

        case PaymentAlertLevel.none:
          return; // Pas de notification
      }

      await NotificationService().createNotification(
        userId: livreurId,
        type: type,
        title: title,
        body: body,
        data: {
          'unpaidAmount': unpaidAmount,
          'threshold': threshold,
          'alertLevel': alertLevel.name,
          'route': '/livreur/payments',
          'action': 'make_deposit',
        },
      );

      debugPrint('📬 Notification d\'alerte envoyée: ${alertLevel.name}');

    } catch (e) {
      debugPrint('❌ Erreur envoi notification alerte: $e');
    }
  }

  /// Obtenir l'historique des dépôts d'un livreur
  static Future<List<Map<String, dynamic>>> getDepositHistory({
    required String livreurId,
    int limit = 20,
  }) async {
    try {
      final depositsSnapshot = await _firestore
          .collection('livreur_deposits')
          .where('livreurId', isEqualTo: livreurId)
          .orderBy('depositedAt', descending: true)
          .limit(limit)
          .get();

      return depositsSnapshot.docs.map((doc) {
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

  /// Calculer les statistiques de paiement d'un livreur
  static Future<Map<String, dynamic>> getPaymentStats({
    required String livreurId,
  }) async {
    try {
      final livreurDoc = await _firestore.collection('users').doc(livreurId).get();

      if (!livreurDoc.exists) {
        throw Exception('Livreur introuvable');
      }

      final profile = livreurDoc.data()!['profile'] as Map<String, dynamic>? ?? {};

      final unpaidBalance = (profile['unpaidBalance'] as num?)?.toDouble() ?? 0.0;
      final totalPaymentsDeposited = (profile['totalPaymentsDeposited'] as num?)?.toDouble() ?? 0.0;
      final totalCollected = unpaidBalance + totalPaymentsDeposited;

      // Récupérer le seuil
      final completedDeliveries = profile['completedDeliveries'] as int? ?? 0;
      final averageRating = (profile['averageRating'] as num? ?? 0.0).toDouble();
      final cautionDeposited = (profile['cautionDeposited'] as num? ?? 0.0).toDouble();

      final trustConfig = LivreurTrustConfig.getConfig(
        completedDeliveries: completedDeliveries,
        averageRating: averageRating,
        cautionDeposited: cautionDeposited,
      );

      final trustLevel = trustConfig.level.name;
      final threshold = _thresholdsByTrustLevel[trustLevel] ?? 30000.0;

      return {
        'unpaidBalance': unpaidBalance,
        'totalPaymentsDeposited': totalPaymentsDeposited,
        'totalCollected': totalCollected,
        'threshold': threshold,
        'percentageOfThreshold': (unpaidBalance / threshold) * 100,
        'trustLevel': trustLevel,
      };

    } catch (e) {
      debugPrint('❌ Erreur statistiques paiements: $e');
      return {
        'unpaidBalance': 0.0,
        'totalPaymentsDeposited': 0.0,
        'totalCollected': 0.0,
        'threshold': 30000.0,
        'percentageOfThreshold': 0.0,
        'trustLevel': 'debutant',
      };
    }
  }
}
