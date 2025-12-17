// ===== lib/services/livreur_trust_service.dart =====
// Service de gestion des paliers de confiance des livreurs

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/livreur_trust_level.dart';

class LivreurTrustService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Obtenir la configuration de confiance d'un livreur
  static Future<LivreurTrustConfig> getLivreurTrustConfig(String livreurId) async {
    try {
      // Récupérer le profil du livreur
      final userDoc = await _firestore.collection('users').doc(livreurId).get();

      if (!userDoc.exists) {
        debugPrint('❌ Livreur $livreurId introuvable');
        return LivreurTrustConfig.getConfigByLevel(LivreurTrustLevel.debutant);
      }

      final userData = userDoc.data()!;
      final profile = userData['profile'] as Map<String, dynamic>? ?? {};
      final livreurProfile = profile['livreurProfile'] as Map<String, dynamic>? ?? {};

      // Extraire les données nécessaires
      final completedDeliveries = livreurProfile['completedDeliveries'] as int? ?? 0;
      final averageRating = (livreurProfile['averageRating'] as num? ?? 0.0).toDouble();
      final cautionDeposited = (userData['cautionDeposited'] as num? ?? 0.0).toDouble();

      debugPrint('📊 Livreur $livreurId: $completedDeliveries livraisons, note $averageRating, caution $cautionDeposited FCFA');

      // Calculer la configuration
      final config = LivreurTrustConfig.getConfig(
        completedDeliveries: completedDeliveries,
        averageRating: averageRating,
        cautionDeposited: cautionDeposited,
      );

      debugPrint('✅ Niveau: ${config.displayName} ${config.badgeIcon}');
      return config;
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération du niveau de confiance: $e');
      return LivreurTrustConfig.getConfigByLevel(LivreurTrustLevel.debutant);
    }
  }

  /// Vérifier si un livreur peut accepter une commande
  static Future<Map<String, dynamic>> canLivreurAcceptOrder({
    required String livreurId,
    required double orderAmount,
  }) async {
    try {
      final config = await getLivreurTrustConfig(livreurId);

      // Vérifier si le montant est dans la limite
      if (orderAmount > config.maxOrderAmount) {
        debugPrint('❌ Commande ${orderAmount.toStringAsFixed(0)} FCFA > limite ${config.maxOrderAmount.toStringAsFixed(0)} FCFA');

        return {
          'canAccept': false,
          'reason': 'montant_trop_eleve',
          'message': 'Cette commande dépasse votre limite de ${config.maxOrderAmount.toStringAsFixed(0)} FCFA.\n'
                     'Niveau actuel: ${config.displayName} ${config.badgeIcon}\n'
                     'Effectuez plus de livraisons pour augmenter votre limite.',
          'config': config,
        };
      }

      // Vérifier le solde non reversé actuel
      final currentUnpaidBalance = await _getCurrentUnpaidBalance(livreurId);

      if (currentUnpaidBalance + orderAmount > config.maxUnpaidBalance) {
        debugPrint('❌ Solde non reversé ${(currentUnpaidBalance + orderAmount).toStringAsFixed(0)} FCFA > limite ${config.maxUnpaidBalance.toStringAsFixed(0)} FCFA');

        return {
          'canAccept': false,
          'reason': 'solde_non_reverse_depasse',
          'message': 'Vous devez reverser ${currentUnpaidBalance.toStringAsFixed(0)} FCFA avant d\'accepter cette commande.\n'
                     'Limite actuelle: ${config.maxUnpaidBalance.toStringAsFixed(0)} FCFA',
          'currentBalance': currentUnpaidBalance,
          'config': config,
        };
      }

      debugPrint('✅ Livreur peut accepter la commande (niveau: ${config.displayName})');

      return {
        'canAccept': true,
        'config': config,
        'currentBalance': currentUnpaidBalance,
        'remainingCapacity': config.maxUnpaidBalance - (currentUnpaidBalance + orderAmount),
      };
    } catch (e) {
      debugPrint('❌ Erreur lors de la vérification: $e');
      return {
        'canAccept': false,
        'reason': 'erreur',
        'message': 'Erreur lors de la vérification: $e',
      };
    }
  }

  /// Obtenir le solde non reversé actuel d'un livreur
  static Future<double> _getCurrentUnpaidBalance(String livreurId) async {
    try {
      // Récupérer toutes les livraisons complétées non reversées
      final deliveriesSnapshot = await _firestore
          .collection('deliveries')
          .where('livreurId', isEqualTo: livreurId)
          .where('status', isEqualTo: 'delivered')
          .where('paymentReversed', isEqualTo: false)
          .get();

      double totalUnpaid = 0.0;

      for (final doc in deliveriesSnapshot.docs) {
        final data = doc.data();
        final deliveryFee = (data['deliveryFee'] as num? ?? 0).toDouble();
        totalUnpaid += deliveryFee;
      }

      debugPrint('💰 Solde non reversé: ${totalUnpaid.toStringAsFixed(0)} FCFA');
      return totalUnpaid;
    } catch (e) {
      debugPrint('❌ Erreur calcul solde non reversé: $e');
      return 0.0;
    }
  }

  /// Filtrer les commandes disponibles selon le niveau du livreur
  static Future<List<Map<String, dynamic>>> filterOrdersByTrustLevel({
    required String livreurId,
    required List<Map<String, dynamic>> orders,
  }) async {
    final config = await getLivreurTrustConfig(livreurId);
    final currentBalance = await _getCurrentUnpaidBalance(livreurId);

    final filteredOrders = <Map<String, dynamic>>[];

    for (final order in orders) {
      final orderAmount = (order['totalAmount'] as num? ?? 0).toDouble();

      // Vérifier montant max
      if (orderAmount > config.maxOrderAmount) {
        continue;
      }

      // Vérifier solde non reversé
      if (currentBalance + orderAmount > config.maxUnpaidBalance) {
        continue;
      }

      filteredOrders.add(order);
    }

    debugPrint('✅ ${filteredOrders.length}/${orders.length} commandes accessibles pour ce livreur');
    return filteredOrders;
  }

  /// Mettre à jour le niveau de confiance après une livraison
  static Future<void> updateTrustLevelAfterDelivery({
    required String livreurId,
    required double rating,
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(livreurId);
      final userDoc = await userRef.get();

      if (!userDoc.exists) return;

      final userData = userDoc.data()!;
      final profile = userData['profile'] as Map<String, dynamic>? ?? {};
      final livreurProfile = profile['livreurProfile'] as Map<String, dynamic>? ?? {};

      final currentDeliveries = livreurProfile['completedDeliveries'] as int? ?? 0;
      final currentRating = (livreurProfile['averageRating'] as num? ?? 0.0).toDouble();

      // Calculer nouvelle moyenne
      final newDeliveries = currentDeliveries + 1;
      final newAverageRating = ((currentRating * currentDeliveries) + rating) / newDeliveries;

      // Mettre à jour
      await userRef.update({
        'profile.livreurProfile.completedDeliveries': newDeliveries,
        'profile.livreurProfile.averageRating': newAverageRating,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Vérifier si changement de niveau
      final oldConfig = LivreurTrustConfig.getConfig(
        completedDeliveries: currentDeliveries,
        averageRating: currentRating,
        cautionDeposited: (userData['cautionDeposited'] as num? ?? 0).toDouble(),
      );

      final newConfig = LivreurTrustConfig.getConfig(
        completedDeliveries: newDeliveries,
        averageRating: newAverageRating,
        cautionDeposited: (userData['cautionDeposited'] as num? ?? 0).toDouble(),
      );

      if (oldConfig.level != newConfig.level) {
        debugPrint('🎉 NIVEAU UP ! ${oldConfig.displayName} → ${newConfig.displayName}');

        // TODO: Envoyer notification de niveau up
        await _sendLevelUpNotification(livreurId, oldConfig, newConfig);
      }
    } catch (e) {
      debugPrint('❌ Erreur mise à jour niveau de confiance: $e');
    }
  }

  /// Envoyer notification de changement de niveau
  static Future<void> _sendLevelUpNotification(
    String livreurId,
    LivreurTrustConfig oldConfig,
    LivreurTrustConfig newConfig,
  ) async {
    // TODO: Intégrer avec NotificationService
    debugPrint('📧 Notification niveau up: ${oldConfig.displayName} → ${newConfig.displayName}');
  }

  /// Obtenir les statistiques de progression d'un livreur
  static Future<Map<String, dynamic>> getProgressStats(String livreurId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(livreurId).get();

      if (!userDoc.exists) {
        return {
          'hasData': false,
        };
      }

      final userData = userDoc.data()!;
      final profile = userData['profile'] as Map<String, dynamic>? ?? {};
      final livreurProfile = profile['livreurProfile'] as Map<String, dynamic>? ?? {};

      final completedDeliveries = livreurProfile['completedDeliveries'] as int? ?? 0;
      final averageRating = (livreurProfile['averageRating'] as num? ?? 0.0).toDouble();
      final cautionDeposited = (userData['cautionDeposited'] as num? ?? 0.0).toDouble();

      final currentConfig = LivreurTrustConfig.getConfig(
        completedDeliveries: completedDeliveries,
        averageRating: averageRating,
        cautionDeposited: cautionDeposited,
      );

      final progressInfo = LivreurTrustConfig.getProgressToNextLevel(
        completedDeliveries: completedDeliveries,
        averageRating: averageRating,
        cautionDeposited: cautionDeposited,
      );

      return {
        'hasData': true,
        'currentLevel': currentConfig,
        'completedDeliveries': completedDeliveries,
        'averageRating': averageRating,
        'cautionDeposited': cautionDeposited,
        'progressInfo': progressInfo,
      };
    } catch (e) {
      debugPrint('❌ Erreur récupération stats progression: $e');
      return {
        'hasData': false,
        'error': e.toString(),
      };
    }
  }

  /// Déposer ou retirer une caution
  static Future<bool> updateCaution({
    required String livreurId,
    required double amount,
    required String operation, // 'deposit' ou 'withdraw'
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(livreurId);
      final userDoc = await userRef.get();

      if (!userDoc.exists) return false;

      final currentCaution = (userDoc.data()!['cautionDeposited'] as num? ?? 0).toDouble();

      double newCaution;
      if (operation == 'deposit') {
        newCaution = currentCaution + amount;
      } else if (operation == 'withdraw') {
        newCaution = currentCaution - amount;
        if (newCaution < 0) {
          debugPrint('❌ Montant de retrait supérieur à la caution disponible');
          return false;
        }
      } else {
        debugPrint('❌ Opération invalide: $operation');
        return false;
      }

      await userRef.update({
        'cautionDeposited': newCaution,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Caution mise à jour: ${currentCaution.toStringAsFixed(0)} → ${newCaution.toStringAsFixed(0)} FCFA');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur mise à jour caution: $e');
      return false;
    }
  }
}
