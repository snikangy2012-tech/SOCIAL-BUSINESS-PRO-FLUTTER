// ===== lib/services/review_service.dart =====
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/review_model.dart';
import '../config/constants.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get reviews by product
  Future<List<ReviewModel>> getReviewsByProduct(String productId) async {
    try {
      debugPrint('🔥 Récupération des avis pour le produit: $productId');

      final querySnapshot = await _firestore
          .collection(FirebaseCollections.reviews)
          .where('targetId', isEqualTo: productId)
          .where('targetType', isEqualTo: 'product')
          .orderBy('createdAt', descending: true)
          .get();

      final reviews = querySnapshot.docs
          .map((doc) => ReviewModel.fromFirestore(doc))
          .toList();

      debugPrint('✅ ${reviews.length} avis trouvés');
      return reviews;
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des avis: $e');

      // Return empty list on Web if offline
      if (kIsWeb && e.toString().contains('unavailable')) {
        debugPrint('⚠️ Mode offline Web - retour liste vide');
        return [];
      }

      rethrow;
    }
  }

  // Get reviews by vendor
  Future<List<ReviewModel>> getReviewsByVendor(String vendorId) async {
    try {
      debugPrint('🔥 Récupération des avis pour le vendeur: $vendorId');

      final querySnapshot = await _firestore
          .collection(FirebaseCollections.reviews)
          .where('targetId', isEqualTo: vendorId)
          .where('targetType', isEqualTo: 'vendor')
          .orderBy('createdAt', descending: true)
          .get();

      final reviews = querySnapshot.docs
          .map((doc) => ReviewModel.fromFirestore(doc))
          .toList();

      debugPrint('✅ ${reviews.length} avis trouvés');
      return reviews;
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des avis: $e');

      if (kIsWeb && e.toString().contains('unavailable')) {
        return [];
      }

      rethrow;
    }
  }

  // Get reviews by livreur
  Future<List<ReviewModel>> getReviewsByLivreur(String livreurId) async {
    try {
      debugPrint('🔥 Récupération des avis pour le livreur: $livreurId');

      final querySnapshot = await _firestore
          .collection(FirebaseCollections.reviews)
          .where('targetId', isEqualTo: livreurId)
          .where('targetType', isEqualTo: 'livreur')
          .orderBy('createdAt', descending: true)
          .get();

      final reviews = querySnapshot.docs
          .map((doc) => ReviewModel.fromFirestore(doc))
          .toList();

      debugPrint('✅ ${reviews.length} avis trouvés');
      return reviews;
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des avis: $e');

      if (kIsWeb && e.toString().contains('unavailable')) {
        return [];
      }

      rethrow;
    }
  }

  // Create a new review
  Future<String> createReview(ReviewModel review) async {
    try {
      debugPrint('🔥 Création d\'un nouvel avis');

      final docRef = await _firestore
          .collection(FirebaseCollections.reviews)
          .add(review.toFirestore());

      debugPrint('✅ Avis créé avec ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Erreur lors de la création de l\'avis: $e');
      rethrow;
    }
  }

  // Update a review
  Future<void> updateReview(String reviewId, Map<String, dynamic> updates) async {
    try {
      debugPrint('🔥 Mise à jour de l\'avis: $reviewId');

      updates['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection(FirebaseCollections.reviews)
          .doc(reviewId)
          .update(updates);

      debugPrint('✅ Avis mis à jour');
    } catch (e) {
      debugPrint('❌ Erreur lors de la mise à jour de l\'avis: $e');
      rethrow;
    }
  }

  // Delete a review
  Future<void> deleteReview(String reviewId) async {
    try {
      debugPrint('🔥 Suppression de l\'avis: $reviewId');

      await _firestore
          .collection(FirebaseCollections.reviews)
          .doc(reviewId)
          .delete();

      debugPrint('✅ Avis supprimé');
    } catch (e) {
      debugPrint('❌ Erreur lors de la suppression de l\'avis: $e');
      rethrow;
    }
  }

  // Add vendor/seller response to a review
  Future<void> addResponse(String reviewId, String response) async {
    try {
      debugPrint('🔥 Ajout d\'une réponse à l\'avis: $reviewId');

      await updateReview(reviewId, {'response': response});

      debugPrint('✅ Réponse ajoutée');
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'ajout de la réponse: $e');
      rethrow;
    }
  }

  // Get average rating for a target
  Future<double> getAverageRating(String targetId, String targetType) async {
    try {
      List<ReviewModel> reviews;

      switch (targetType) {
        case 'product':
          reviews = await getReviewsByProduct(targetId);
          break;
        case 'vendor':
          reviews = await getReviewsByVendor(targetId);
          break;
        case 'livreur':
          reviews = await getReviewsByLivreur(targetId);
          break;
        default:
          return 0.0;
      }

      if (reviews.isEmpty) return 0.0;

      final totalRating = reviews.fold<double>(
        0,
        (sum, review) => sum + review.rating,
      );

      return totalRating / reviews.length;
    } catch (e) {
      debugPrint('❌ Erreur lors du calcul de la note moyenne: $e');
      return 0.0;
    }
  }

  // Get rating distribution
  Future<Map<int, int>> getRatingDistribution(
    String targetId,
    String targetType,
  ) async {
    try {
      List<ReviewModel> reviews;

      switch (targetType) {
        case 'product':
          reviews = await getReviewsByProduct(targetId);
          break;
        case 'vendor':
          reviews = await getReviewsByVendor(targetId);
          break;
        case 'livreur':
          reviews = await getReviewsByLivreur(targetId);
          break;
        default:
          return {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
      }

      final distribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

      for (var review in reviews) {
        distribution[review.rating] = (distribution[review.rating] ?? 0) + 1;
      }

      return distribution;
    } catch (e) {
      debugPrint('❌ Erreur lors du calcul de la distribution: $e');
      return {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    }
  }

  // Check if user has already reviewed a target
  Future<bool> hasUserReviewed(
    String userId,
    String targetId,
    String targetType,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(FirebaseCollections.reviews)
          .where('reviewerId', isEqualTo: userId)
          .where('targetId', isEqualTo: targetId)
          .where('targetType', isEqualTo: targetType)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('❌ Erreur lors de la vérification de l\'avis: $e');

      if (kIsWeb && e.toString().contains('unavailable')) {
        return false;
      }

      rethrow;
    }
  }

  // Get review by user for a target
  Future<ReviewModel?> getUserReview(
    String userId,
    String targetId,
    String targetType,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(FirebaseCollections.reviews)
          .where('reviewerId', isEqualTo: userId)
          .where('targetId', isEqualTo: targetId)
          .where('targetType', isEqualTo: targetType)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return ReviewModel.fromFirestore(querySnapshot.docs.first);
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération de l\'avis: $e');

      if (kIsWeb && e.toString().contains('unavailable')) {
        return null;
      }

      rethrow;
    }
  }
}