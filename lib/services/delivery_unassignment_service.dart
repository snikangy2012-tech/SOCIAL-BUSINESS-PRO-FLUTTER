// lib/services/delivery_unassignment_service.dart
// Service de gestion des désassignations de livraisons - MVP
// SOCIAL BUSINESS Pro

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/subscription_model.dart';
import '../models/delivery_model.dart';

/// Service gérant les désassignations de livraisons par les livreurs
/// Implémente les limites par tier (STARTER: 1/jour, PRO: 2/jour, PREMIUM: 3/jour)
class DeliveryUnassignmentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Vérifie si un livreur peut se désassigner d'une livraison
  ///
  /// Returns: Map contenant:
  ///   - 'canUnassign' (bool): true si la désassignation est possible
  ///   - 'reason' (String?): raison du refus si canUnassign = false
  ///   - 'remainingToday' (int): nombre de désassignations restantes aujourd'hui
  static Future<Map<String, dynamic>> canUnassign({
    required String livreurId,
    required String deliveryId,
  }) async {
    try {
      debugPrint('🔍 Vérification désassignation - Livreur: $livreurId, Livraison: $deliveryId');

      // 1. Récupérer l'abonnement du livreur
      final subscriptionDoc = await _firestore
          .collection('livreur_subscriptions')
          .doc(livreurId)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Timeout lors de la récupération de l\'abonnement'),
          );

      if (!subscriptionDoc.exists) {
        return {
          'canUnassign': false,
          'reason': 'Abonnement introuvable',
          'remainingToday': 0,
        };
      }

      final subscription = LivreurSubscription.fromFirestore(subscriptionDoc);

      // 2. Vérifier si le compteur quotidien doit être réinitialisé
      int currentCount = subscription.dailyUnassignments;
      if (subscription.needsDailyReset) {
        currentCount = 0;
        debugPrint('📅 Reset compteur quotidien détecté');
      }

      // 3. Vérifier la limite quotidienne
      if (!subscription.canUnassignToday && currentCount >= subscription.dailyUnassignmentLimit) {
        return {
          'canUnassign': false,
          'reason': 'Limite quotidienne atteinte (${subscription.dailyUnassignmentLimit}/${subscription.dailyUnassignmentLimit})',
          'remainingToday': 0,
        };
      }

      // 4. Récupérer la livraison
      final deliveryDoc = await _firestore
          .collection('deliveries')
          .doc(deliveryId)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Timeout lors de la récupération de la livraison'),
          );

      if (!deliveryDoc.exists) {
        return {
          'canUnassign': false,
          'reason': 'Livraison introuvable',
          'remainingToday': subscription.remainingUnassignments,
        };
      }

      final delivery = DeliveryModel.fromFirestore(deliveryDoc);

      // 5. Vérifier le statut de la livraison
      if (delivery.status != 'assigned') {
        return {
          'canUnassign': false,
          'reason': 'Vous ne pouvez vous désassigner qu\'avant de récupérer le colis (statut: ${delivery.status})',
          'remainingToday': subscription.remainingUnassignments,
        };
      }

      // 6. Vérifier que le livreur est bien assigné
      if (delivery.livreurId != livreurId) {
        return {
          'canUnassign': false,
          'reason': 'Vous n\'êtes pas assigné à cette livraison',
          'remainingToday': subscription.remainingUnassignments,
        };
      }

      // ✅ Tout est OK
      return {
        'canUnassign': true,
        'reason': null,
        'remainingToday': subscription.remainingUnassignments,
        'tierName': subscription.tierName,
        'dailyLimit': subscription.dailyUnassignmentLimit,
      };
    } catch (e) {
      debugPrint('❌ Erreur vérification désassignation: $e');
      return {
        'canUnassign': false,
        'reason': 'Erreur technique: ${e.toString()}',
        'remainingToday': 0,
      };
    }
  }

  /// Demande une désassignation de livraison
  ///
  /// Process:
  /// 1. Vérifie canUnassign()
  /// 2. Met à jour le compteur du livreur
  /// 3. Libère la livraison (status = available, livreurId = null)
  /// 4. Notifie le vendeur
  /// 5. Tente une ré-assignation automatique
  static Future<void> requestUnassignment({
    required String deliveryId,
    required String livreurId,
    String? reason, // Optionnel pour PRO/PREMIUM, requis pour STARTER si on veut
  }) async {
    try {
      debugPrint('🚫 Demande de désassignation - Livreur: $livreurId, Livraison: $deliveryId');

      // 1. Vérifier si possible
      final checkResult = await canUnassign(
        livreurId: livreurId,
        deliveryId: deliveryId,
      );

      if (checkResult['canUnassign'] != true) {
        throw Exception(checkResult['reason'] ?? 'Désassignation impossible');
      }

      // 2. Récupérer les données nécessaires
      final subscriptionDoc = await _firestore
          .collection('livreur_subscriptions')
          .doc(livreurId)
          .get();

      final deliveryDoc = await _firestore
          .collection('deliveries')
          .doc(deliveryId)
          .get();

      if (!subscriptionDoc.exists || !deliveryDoc.exists) {
        throw Exception('Données introuvables');
      }

      final subscription = LivreurSubscription.fromFirestore(subscriptionDoc);
      final delivery = DeliveryModel.fromFirestore(deliveryDoc);

      // 3. Mettre à jour l'abonnement (incrémenter compteur)
      final now = DateTime.now();
      final newCount = subscription.needsDailyReset ? 1 : (subscription.dailyUnassignments + 1);

      await _firestore.collection('livreur_subscriptions').doc(livreurId).update({
        'dailyUnassignments': newCount,
        'lastUnassignmentDate': Timestamp.fromDate(now),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Compteur mis à jour: $newCount/${subscription.dailyUnassignmentLimit}');

      // 4. Libérer la livraison
      await _firestore.collection('deliveries').doc(deliveryId).update({
        'livreurId': null,
        'status': 'available',
        'updatedAt': FieldValue.serverTimestamp(),
        'unassignmentReason': reason,
        'unassignedAt': Timestamp.fromDate(now),
        'previousLivreurId': livreurId, // Pour éviter de réassigner au même
      });

      debugPrint('✅ Livraison libérée: $deliveryId');

      // 5. Mettre à jour la commande si nécessaire
      if (delivery.orderId != null) {
        await _firestore.collection('orders').doc(delivery.orderId).update({
          'livreurId': null,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // 6. Créer une notification simple pour le vendeur
      if (delivery.vendeurId != null) {
        try {
          await _firestore.collection('notifications').add({
            'userId': delivery.vendeurId,
            'title': 'Livreur désassigné',
            'body': 'Le livreur s\'est désassigné de la commande #${delivery.orderId?.substring(0, 8)}',
            'type': 'delivery_update',
            'isRead': false,
            'data': {
              'deliveryId': deliveryId,
              'orderId': delivery.orderId,
              'action': 'unassigned',
            },
            'createdAt': FieldValue.serverTimestamp(),
          });
          debugPrint('📧 Notification vendeur créée');
        } catch (e) {
          debugPrint('⚠️  Erreur création notification: $e');
          // Non bloquant
        }
      }

      // 7. Note: La ré-assignation automatique peut être faite manuellement par le vendeur
      // Pour le MVP, on laisse la livraison en status 'available'
      debugPrint('ℹ️  Livraison disponible pour réassignation manuelle');

      debugPrint('✅ Désassignation complétée avec succès');
    } catch (e) {
      debugPrint('❌ Erreur lors de la désassignation: $e');
      rethrow;
    }
  }

  /// Obtient les statistiques de désassignation d'un livreur
  static Future<Map<String, dynamic>> getUnassignmentStats(String livreurId) async {
    try {
      final subscriptionDoc = await _firestore
          .collection('livreur_subscriptions')
          .doc(livreurId)
          .get();

      if (!subscriptionDoc.exists) {
        return {
          'dailyCount': 0,
          'dailyLimit': 1,
          'remaining': 1,
          'lastDate': null,
        };
      }

      final subscription = LivreurSubscription.fromFirestore(subscriptionDoc);

      return {
        'dailyCount': subscription.needsDailyReset ? 0 : subscription.dailyUnassignments,
        'dailyLimit': subscription.dailyUnassignmentLimit,
        'remaining': subscription.remainingUnassignments,
        'lastDate': subscription.lastUnassignmentDate,
        'tierName': subscription.tierName,
      };
    } catch (e) {
      debugPrint('❌ Erreur récupération stats: $e');
      return {
        'dailyCount': 0,
        'dailyLimit': 1,
        'remaining': 1,
        'lastDate': null,
      };
    }
  }
}
