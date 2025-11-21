// ===== lib/services/counter_service.dart =====
// Service pour gérer les compteurs incrémentaux dans Firestore

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class CounterService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Obtient et incrémente le compteur de commandes de manière atomique
  /// Retourne le numéro suivant à utiliser pour displayNumber
  static Future<int> getNextOrderNumber() async {
    try {
      final counterRef = _firestore.collection('counters').doc('orders');

      // Utiliser une transaction pour garantir l'atomicité
      final nextNumber = await _firestore.runTransaction<int>((transaction) async {
        final counterDoc = await transaction.get(counterRef);

        int currentValue = 0;
        if (counterDoc.exists) {
          currentValue = counterDoc.data()?['value'] ?? 0;
        }

        final nextValue = currentValue + 1;

        // Mettre à jour ou créer le compteur
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

      debugPrint('✅ Compteur commande obtenu: $nextNumber');
      return nextNumber;

    } catch (e) {
      debugPrint('❌ Erreur obtention compteur commande: $e');
      // En cas d'erreur, utiliser un fallback basé sur le timestamp
      return DateTime.now().millisecondsSinceEpoch % 100000;
    }
  }

  /// Obtient et incrémente le compteur de livraisons
  static Future<int> getNextDeliveryNumber() async {
    try {
      final counterRef = _firestore.collection('counters').doc('deliveries');

      final nextNumber = await _firestore.runTransaction<int>((transaction) async {
        final counterDoc = await transaction.get(counterRef);

        int currentValue = 0;
        if (counterDoc.exists) {
          currentValue = counterDoc.data()?['value'] ?? 0;
        }

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

      debugPrint('✅ Compteur livraison obtenu: $nextNumber');
      return nextNumber;

    } catch (e) {
      debugPrint('❌ Erreur obtention compteur livraison: $e');
      return DateTime.now().millisecondsSinceEpoch % 100000;
    }
  }

  /// Réinitialise un compteur (uniquement pour les admins)
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
