// ===== lib/services/payment_service.dart =====
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/payment_method_model.dart';
import '../config/firebase_collections.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all payment methods for a user
  Future<List<PaymentMethodModel>> getPaymentMethodsByUser(String userId) async {
    try {
      debugPrint('🔥 Récupération des moyens de paiement pour userId: $userId');

      final querySnapshot = await _firestore
          .collection(FirebaseCollections.paymentMethods)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      final methods = querySnapshot.docs
          .map((doc) => PaymentMethodModel.fromFirestore(doc))
          .toList();

      debugPrint('✅ ${methods.length} moyens de paiement trouvés');
      return methods;
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des moyens de paiement: $e');

      // Return empty list on Web if offline
      if (kIsWeb && e.toString().contains('unavailable')) {
        debugPrint('⚠️ Mode offline Web - retour liste vide');
        return [];
      }

      rethrow;
    }
  }

  // Get default payment method for a user
  Future<PaymentMethodModel?> getDefaultPaymentMethod(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(FirebaseCollections.paymentMethods)
          .where('userId', isEqualTo: userId)
          .where('isDefault', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return PaymentMethodModel.fromFirestore(querySnapshot.docs.first);
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération du moyen de paiement par défaut: $e');

      if (kIsWeb && e.toString().contains('unavailable')) {
        return null;
      }

      rethrow;
    }
  }

  // Add a new payment method
  Future<String> addPaymentMethod(PaymentMethodModel paymentMethod) async {
    try {
      debugPrint('🔥 Ajout d\'un nouveau moyen de paiement de type: ${paymentMethod.type}');

      // If this is the first payment method, make it default
      final existingMethods = await getPaymentMethodsByUser(paymentMethod.userId);
      final shouldBeDefault = existingMethods.isEmpty;

      final methodToAdd = shouldBeDefault
          ? paymentMethod.copyWith(isDefault: true)
          : paymentMethod;

      final docRef = await _firestore
          .collection(FirebaseCollections.paymentMethods)
          .add(methodToAdd.toFirestore());

      debugPrint('✅ Moyen de paiement ajouté avec ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'ajout du moyen de paiement: $e');
      rethrow;
    }
  }

  // Update a payment method
  Future<void> updatePaymentMethod(
    String paymentMethodId,
    Map<String, dynamic> updates,
  ) async {
    try {
      debugPrint('🔥 Mise à jour du moyen de paiement: $paymentMethodId');

      updates['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection(FirebaseCollections.paymentMethods)
          .doc(paymentMethodId)
          .update(updates);

      debugPrint('✅ Moyen de paiement mis à jour');
    } catch (e) {
      debugPrint('❌ Erreur lors de la mise à jour du moyen de paiement: $e');
      rethrow;
    }
  }

  // Set a payment method as default
  Future<void> setDefaultPaymentMethod(String userId, String paymentMethodId) async {
    try {
      debugPrint('🔥 Définition du moyen de paiement par défaut: $paymentMethodId');

      // Start a batch write
      final batch = _firestore.batch();

      // Remove default from all user's payment methods
      final allMethods = await getPaymentMethodsByUser(userId);
      for (var method in allMethods) {
        final docRef = _firestore
            .collection(FirebaseCollections.paymentMethods)
            .doc(method.id);
        batch.update(docRef, {
          'isDefault': false,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Set the selected method as default
      final selectedDocRef = _firestore
          .collection(FirebaseCollections.paymentMethods)
          .doc(paymentMethodId);
      batch.update(selectedDocRef, {
        'isDefault': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Commit the batch
      await batch.commit();

      debugPrint('✅ Moyen de paiement par défaut défini');
    } catch (e) {
      debugPrint('❌ Erreur lors de la définition du moyen de paiement par défaut: $e');
      rethrow;
    }
  }

  // Delete a payment method
  Future<void> deletePaymentMethod(String paymentMethodId) async {
    try {
      debugPrint('🔥 Suppression du moyen de paiement: $paymentMethodId');

      // Get the payment method to check if it's default
      final doc = await _firestore
          .collection(FirebaseCollections.paymentMethods)
          .doc(paymentMethodId)
          .get();

      if (!doc.exists) {
        throw Exception('Moyen de paiement introuvable');
      }

      final paymentMethod = PaymentMethodModel.fromFirestore(doc);

      // Delete the payment method
      await _firestore
          .collection(FirebaseCollections.paymentMethods)
          .doc(paymentMethodId)
          .delete();

      // If it was default, set another one as default
      if (paymentMethod.isDefault) {
        final remainingMethods = await getPaymentMethodsByUser(paymentMethod.userId);
        if (remainingMethods.isNotEmpty) {
          await setDefaultPaymentMethod(
            paymentMethod.userId,
            remainingMethods.first.id,
          );
        }
      }

      debugPrint('✅ Moyen de paiement supprimé');
    } catch (e) {
      debugPrint('❌ Erreur lors de la suppression du moyen de paiement: $e');
      rethrow;
    }
  }

  // Get payment method by ID
  Future<PaymentMethodModel?> getPaymentMethodById(String paymentMethodId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseCollections.paymentMethods)
          .doc(paymentMethodId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return PaymentMethodModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération du moyen de paiement: $e');

      if (kIsWeb && e.toString().contains('unavailable')) {
        return null;
      }

      rethrow;
    }
  }

  // Validate payment method (check if expired for cards)
  bool isPaymentMethodValid(PaymentMethodModel paymentMethod) {
    if (paymentMethod.type == 'card' && paymentMethod.expiryDate != null) {
      try {
        final parts = paymentMethod.expiryDate!.split('/');
        if (parts.length != 2) return false;

        final month = int.parse(parts[0]);
        final year = int.parse('20${parts[1]}'); // Assuming 20XX

        final expiryDate = DateTime(year, month + 1, 0); // Last day of the month
        final now = DateTime.now();

        return expiryDate.isAfter(now);
      } catch (e) {
        debugPrint('⚠️ Erreur lors de la validation de la date d\'expiration: $e');
        return false;
      }
    }

    return true; // Other types are always valid
  }

  // Get payment method statistics for a user
  Future<Map<String, int>> getPaymentMethodStats(String userId) async {
    try {
      final methods = await getPaymentMethodsByUser(userId);

      final stats = <String, int>{
        'total': methods.length,
        'card': methods.where((m) => m.type == 'card').length,
        'mobile_money': methods.where((m) => m.type == 'mobile_money').length,
        'bank_transfer': methods.where((m) => m.type == 'bank_transfer').length,
        'expired': methods.where((m) => !isPaymentMethodValid(m)).length,
      };

      return stats;
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des statistiques: $e');
      return {'total': 0, 'card': 0, 'mobile_money': 0, 'bank_transfer': 0, 'expired': 0};
    }
  }
}