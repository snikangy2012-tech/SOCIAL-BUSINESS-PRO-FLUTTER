// ===== lib/services/counter_service.dart =====
// Service pour gérer les compteurs incrémentaux dans Firestore

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class CounterService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Obtient le numéro de commande basé sur le NOMBRE RÉEL de commandes actives
  /// Compte les commandes NON ANNULÉES du vendeur et ajoute 1
  ///
  /// @param vendeurId - ID du vendeur (pour avoir des numéros séquentiels par boutique)
  /// @return Numéro basé sur le count réel (1, 2, 3... sans trous)
  static Future<int> getNextOrderNumber({required String vendeurId}) async {
    try {
      // ✅ NOUVEAU: Compter les commandes ACTIVES (non annulées) du vendeur
      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('vendeurId', isEqualTo: vendeurId)
          .where('status', whereNotIn: ['cancelled', 'annulee']) // Exclure annulées
          .get();

      // Le prochain numéro = nombre de commandes actives + 1
      final nextNumber = ordersSnapshot.docs.length + 1;

      debugPrint('✅ Commandes actives vendeur $vendeurId: ${ordersSnapshot.docs.length}, prochain numéro: $nextNumber');
      return nextNumber;

    } catch (e) {
      debugPrint('❌ Erreur comptage commandes vendeur: $e');
      // En cas d'erreur, essayer l'ancien système de compteur
      try {
        final counterRef = _firestore
            .collection('counters')
            .doc('orders_by_vendor')
            .collection('vendors')
            .doc(vendeurId);

        final nextNumber = await _firestore.runTransaction<int>((transaction) async {
          final counterDoc = await transaction.get(counterRef);
          int currentValue = counterDoc.exists ? (counterDoc.data()?['value'] ?? 0) : 0;
          final nextValue = currentValue + 1;

          if (counterDoc.exists) {
            transaction.update(counterRef, {
              'value': nextValue,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          } else {
            transaction.set(counterRef, {
              'value': nextValue,
              'vendeurId': vendeurId,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }

          return nextValue;
        });

        debugPrint('⚠️ Utilisation compteur fallback: $nextNumber');
        return nextNumber;
      } catch (fallbackError) {
        debugPrint('❌ Erreur fallback: $fallbackError');
        return DateTime.now().millisecondsSinceEpoch % 100000;
      }
    }
  }

  /// Obtient le numéro de livraison basé sur le NOMBRE RÉEL de livraisons actives
  /// Compte les livraisons NON ANNULÉES et ajoute 1
  ///
  /// @return Numéro basé sur le count réel (1, 2, 3... sans trous)
  static Future<int> getNextDeliveryNumber() async {
    try {
      // ✅ NOUVEAU: Compter les livraisons ACTIVES (non annulées)
      final deliveriesSnapshot = await _firestore
          .collection('deliveries')
          .where('status', whereNotIn: ['cancelled', 'annulee']) // Exclure annulées
          .get();

      // Le prochain numéro = nombre de livraisons actives + 1
      final nextNumber = deliveriesSnapshot.docs.length + 1;

      debugPrint('✅ Livraisons actives: ${deliveriesSnapshot.docs.length}, prochain numéro: $nextNumber');
      return nextNumber;

    } catch (e) {
      debugPrint('❌ Erreur comptage livraisons: $e');
      // En cas d'erreur, essayer l'ancien système de compteur
      try {
        final counterRef = _firestore.collection('counters').doc('deliveries');

        final nextNumber = await _firestore.runTransaction<int>((transaction) async {
          final counterDoc = await transaction.get(counterRef);
          int currentValue = counterDoc.exists ? (counterDoc.data()?['value'] ?? 0) : 0;
          final nextValue = currentValue + 1;

          if (counterDoc.exists) {
            transaction.update(counterRef, {
              'value': nextValue,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          } else {
            transaction.set(counterRef, {
              'value': nextValue,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }

          return nextValue;
        });

        debugPrint('⚠️ Utilisation compteur livraisons fallback: $nextNumber');
        return nextNumber;
      } catch (fallbackError) {
        debugPrint('❌ Erreur fallback livraisons: $fallbackError');
        return DateTime.now().millisecondsSinceEpoch % 100000;
      }
    }
  }

  /// Réinitialise un compteur global (uniquement pour les admins)
  static Future<void> resetCounter(String counterType, {int value = 0}) async {
    try {
      await _firestore.collection('counters').doc(counterType).set({
        'value': value,
        'resetAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Compteur $counterType réinitialisé à $value');

    } catch (e) {
      debugPrint('❌ Erreur réinitialisation compteur: $e');
      rethrow;
    }
  }

  /// Réinitialise le compteur de commandes d'un vendeur spécifique
  /// @param vendeurId - ID du vendeur dont on veut réinitialiser le compteur
  /// @param value - Valeur de départ (par défaut 0)
  static Future<void> resetVendorOrderCounter({
    required String vendeurId,
    int value = 0,
  }) async {
    try {
      final counterRef = _firestore
          .collection('counters')
          .doc('orders_by_vendor')
          .collection('vendors')
          .doc(vendeurId);

      await counterRef.set({
        'value': value,
        'vendeurId': vendeurId,
        'resetAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Compteur commandes vendeur $vendeurId réinitialisé à $value');

    } catch (e) {
      debugPrint('❌ Erreur réinitialisation compteur vendeur: $e');
      rethrow;
    }
  }

  /// Réinitialise TOUS les compteurs de commandes de TOUS les vendeurs
  /// ⚠️ Utiliser avec précaution - cela affectera tous les vendeurs
  static Future<void> resetAllVendorOrderCounters({int value = 0}) async {
    try {
      final vendorCountersSnapshot = await _firestore
          .collection('counters')
          .doc('orders_by_vendor')
          .collection('vendors')
          .get();

      final batch = _firestore.batch();

      for (final doc in vendorCountersSnapshot.docs) {
        batch.update(doc.reference, {
          'value': value,
          'resetAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      debugPrint('✅ Tous les compteurs vendeurs réinitialisés (${vendorCountersSnapshot.docs.length} vendeurs)');

    } catch (e) {
      debugPrint('❌ Erreur réinitialisation compteurs vendeurs: $e');
      rethrow;
    }
  }

  /// Obtient la valeur actuelle d'un compteur sans l'incrémenter
  static Future<int> getCurrentCounterValue(String counterType) async {
    try {
      final counterDoc = await _firestore
          .collection('counters')
          .doc(counterType)
          .get();

      if (counterDoc.exists) {
        return counterDoc.data()?['value'] ?? 0;
      }

      return 0;

    } catch (e) {
      debugPrint('❌ Erreur lecture compteur: $e');
      return 0;
    }
  }
}
