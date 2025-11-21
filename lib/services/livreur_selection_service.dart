// ===== lib/services/livreur_selection_service.dart =====
// Service de sélection intelligente des livreurs basé sur les avis et performances

import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../config/constants.dart';
import 'review_service.dart';

/// Critère de sélection des livreurs
class LivreurSelectionCriteria {
  final double minRating; // Note minimum requise
  final int minDeliveries; // Nombre minimum de livraisons
  final double maxDistance; // Distance max du point de collecte (km)
  final bool onlyTrustedDeliverers; // Uniquement les livreurs de confiance (≥4.5)

  const LivreurSelectionCriteria({
    this.minRating = 3.0,
    this.minDeliveries = 0,
    this.maxDistance = 50.0,
    this.onlyTrustedDeliverers = false,
  });
}

/// Livreur candidat avec ses scores
class LivreurCandidate {
  final String id;
  final String name;
  final String? photoUrl;
  final String? phoneNumber;
  final double rating;
  final int totalDeliveries;
  final int completedDeliveries;
  final double completionRate;
  final double distance; // Distance du point de collecte
  final bool isAvailable;
  final bool hasActiveDelivery; // A une livraison en cours (in_progress)
  final int assignedDeliveriesCount; // Nombre de livraisons assignées (assigned)
  final double score; // Score calculé (0-100)

  LivreurCandidate({
    required this.id,
    required this.name,
    this.photoUrl,
    this.phoneNumber,
    required this.rating,
    required this.totalDeliveries,
    required this.completedDeliveries,
    required this.completionRate,
    required this.distance,
    required this.isAvailable,
    required this.hasActiveDelivery,
    this.assignedDeliveriesCount = 0,
    required this.score,
  });

  /// Détermine si le livreur est "de confiance"
  bool get isTrusted => rating >= 4.5 && totalDeliveries >= 10;

  /// Détermine si le livreur est recommandé (disponible et sans livraison en cours)
  bool get isRecommended => isAvailable && !hasActiveDelivery && rating >= 4.0;

  /// Peut accepter plus de livraisons (limite: 5 assigned max, 0 in_progress)
  bool get canAcceptMore => !hasActiveDelivery && assignedDeliveriesCount < 5;

  /// Niveau de confiance en texte
  String get trustLevel {
    if (rating >= 4.5) return 'Excellent';
    if (rating >= 4.0) return 'Bon';
    if (rating >= 3.5) return 'Correct';
    if (rating >= 3.0) return 'Acceptable';
    return 'Non recommandé';
  }

  /// Statut de disponibilité en texte
  String get availabilityStatus {
    if (hasActiveDelivery) return 'En livraison';
    if (assignedDeliveriesCount > 0) return '$assignedDeliveriesCount assignée(s)';
    if (!isAvailable) return 'Hors ligne';
    return 'Disponible';
  }

  /// Distance formatée pour affichage
  String get formattedDistance {
    if (distance < 1.0) {
      return '${(distance * 1000).toStringAsFixed(0)} m';
    }
    return '${distance.toStringAsFixed(1)} km';
  }
}

class LivreurSelectionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ReviewService _reviewService = ReviewService();

  /// Sélectionne le meilleur livreur disponible selon les critères
  Future<LivreurCandidate?> selectBestLivreur({
    required double pickupLat,
    required double pickupLng,
    LivreurSelectionCriteria criteria = const LivreurSelectionCriteria(),
  }) async {
    try {
      debugPrint('🔍 Recherche du meilleur livreur...');

      final candidates = await getAvailableLivreurs(
        pickupLat: pickupLat,
        pickupLng: pickupLng,
        criteria: criteria,
      );

      if (candidates.isEmpty) {
        debugPrint('❌ Aucun livreur disponible');
        return null;
      }

      // Trier par score décroissant
      candidates.sort((a, b) => b.score.compareTo(a.score));

      final best = candidates.first;
      debugPrint('✅ Meilleur livreur sélectionné: ${best.name} (score: ${best.score.toStringAsFixed(1)})');

      return best;
    } catch (e) {
      debugPrint('❌ Erreur sélection livreur: $e');
      return null;
    }
  }

  /// Récupère tous les livreurs disponibles et calcule leurs scores
  Future<List<LivreurCandidate>> getAvailableLivreurs({
    required double pickupLat,
    required double pickupLng,
    LivreurSelectionCriteria criteria = const LivreurSelectionCriteria(),
  }) async {
    try {
      // Récupérer tous les livreurs avec le bon type d'utilisateur
      final querySnapshot = await _firestore
          .collection(FirebaseCollections.users)
          .where('userType', isEqualTo: UserType.livreur.value)
          .get();

      final List<LivreurCandidate> candidates = [];

      for (final doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          final profile = data['profile'] as Map<String, dynamic>?;
          final livreurProfile = profile?['livreurProfile'] as Map<String, dynamic>?;

          if (livreurProfile == null) continue;

          // Vérifier la disponibilité
          final isAvailable = livreurProfile['isAvailable'] == true;
          if (!isAvailable) continue;

          // Récupérer la localisation actuelle
          final currentLocation = livreurProfile['currentLocation'] as Map<String, dynamic>?;
          if (currentLocation == null) continue;

          final livreurLat = (currentLocation['latitude'] as num?)?.toDouble();
          final livreurLng = (currentLocation['longitude'] as num?)?.toDouble();

          if (livreurLat == null || livreurLng == null) continue;

          // Calculer la distance
          final distance = _calculateDistance(
            pickupLat,
            pickupLng,
            livreurLat,
            livreurLng,
          );

          // Filtrer par distance max
          if (distance > criteria.maxDistance) continue;

          // Récupérer les statistiques
          final stats = livreurProfile['stats'] as Map<String, dynamic>?;
          final totalDeliveries = (stats?['totalDeliveries'] as num?)?.toInt() ?? 0;
          final completedDeliveries = (stats?['completedDeliveries'] as num?)?.toInt() ?? 0;

          // Filtrer par nombre minimum de livraisons
          if (totalDeliveries < criteria.minDeliveries) continue;

          // Calculer le taux de complétion
          final completionRate = totalDeliveries > 0
              ? (completedDeliveries / totalDeliveries * 100)
              : 0.0;

          // Récupérer la note moyenne depuis ReviewService
          final rating = await _reviewService.getAverageRating(doc.id, 'livreur');

          // Filtrer par note minimum
          if (rating < criteria.minRating) continue;

          // Filtrer les livreurs de confiance uniquement si demandé
          if (criteria.onlyTrustedDeliverers && rating < 4.5) continue;

          // Vérifier si le livreur a une livraison active
          final hasActiveDelivery = await _hasActiveDelivery(doc.id);

          // Calculer le score global (0-100)
          // Pénaliser si le livreur a une livraison active
          final score = _calculateScore(
            rating: rating,
            completionRate: completionRate,
            totalDeliveries: totalDeliveries,
            distance: distance,
            hasActiveDelivery: hasActiveDelivery,
          );

          candidates.add(LivreurCandidate(
            id: doc.id,
            name: data['displayName'] ?? 'Livreur',
            photoUrl: data['photoURL'],
            phoneNumber: data['phoneNumber'],
            rating: rating,
            totalDeliveries: totalDeliveries,
            completedDeliveries: completedDeliveries,
            completionRate: completionRate,
            distance: distance,
            isAvailable: isAvailable,
            hasActiveDelivery: hasActiveDelivery,
            score: score,
          ));
        } catch (e) {
          debugPrint('⚠️ Erreur traitement livreur ${doc.id}: $e');
          continue;
        }
      }

      debugPrint('✅ ${candidates.length} livreur(s) candidat(s) trouvé(s)');
      return candidates;
    } catch (e) {
      debugPrint('❌ Erreur récupération livreurs: $e');
      return [];
    }
  }

  /// Calcule le score global d'un livreur (0-100)
  /// Pondération:
  /// - Note (50%): Plus la note est élevée, mieux c'est (priorité 1)
  /// - Proximité (30%): Plus proche = mieux (priorité 2)
  /// - Taux de complétion (15%): % de livraisons complétées
  /// - Expérience (5%): Nombre de livraisons (plafonné à 100)
  /// - Pénalité: -50 points si livraison active
  double _calculateScore({
    required double rating,
    required double completionRate,
    required int totalDeliveries,
    required double distance,
    bool hasActiveDelivery = false,
  }) {
    // Score de note (0-50 points) - PRIORITÉ 1
    final ratingScore = (rating / 5.0) * 50;

    // Score de proximité (0-30 points) - PRIORITÉ 2
    // Distance max considérée: 20 km
    final proximityScore = ((20 - distance.clamp(0, 20)) / 20) * 30;

    // Score de complétion (0-15 points)
    final completionScore = (completionRate / 100) * 15;

    // Score d'expérience (0-5 points) - Plafonné à 50 livraisons
    final experienceScore = (totalDeliveries.clamp(0, 50) / 50) * 5;

    var totalScore = ratingScore + proximityScore + completionScore + experienceScore;

    // PÉNALITÉ IMPORTANTE: Si le livreur a déjà une livraison active, réduire drastiquement son score
    if (hasActiveDelivery) {
      totalScore -= 50; // Le livreur passe en dernier
    }

    return totalScore.clamp(0, 100);
  }

  /// Calcule la distance entre deux points GPS (formule de Haversine)
  /// Retourne la distance en kilomètres
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Rayon de la Terre en km

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final lat1Rad = _degreesToRadians(lat1);
    final lat2Rad = _degreesToRadians(lat2);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
        math.sin(dLon / 2) * math.sin(dLon / 2);

    final c = 2 * math.asin(math.sqrt(a));

    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  /// Vérifie si un livreur a une livraison EN COURS (in_progress)
  /// Note: On autorise plusieurs livraisons assignées, mais une seule en cours
  Future<bool> _hasActiveDelivery(String livreurId) async {
    try {
      final inProgressDeliveries = await _firestore
          .collection(FirebaseCollections.deliveries)
          .where('livreurId', isEqualTo: livreurId)
          .where('status', isEqualTo: 'in_progress')
          .limit(1)
          .get();

      return inProgressDeliveries.docs.isNotEmpty;
    } catch (e) {
      debugPrint('❌ Erreur vérification livraison active: $e');
      return false;
    }
  }

  /// Compte le nombre de livraisons assignées à un livreur
  Future<int> getAssignedDeliveriesCount(String livreurId) async {
    try {
      final assignedCount = await _firestore
          .collection(FirebaseCollections.deliveries)
          .where('livreurId', isEqualTo: livreurId)
          .where('status', isEqualTo: 'assigned')
          .count()
          .get();

      return assignedCount.count ?? 0;
    } catch (e) {
      debugPrint('❌ Erreur comptage livraisons assignées: $e');
      return 0;
    }
  }

  /// Assigne une livraison à un livreur
  Future<void> assignDeliveryToLivreur({
    required String deliveryId,
    required String livreurId,
  }) async {
    try {
      await _firestore.collection('deliveries').doc(deliveryId).update({
        'livreurId': livreurId,
        'status': 'assigned',
        'assignedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Livraison $deliveryId assignée au livreur $livreurId');
    } catch (e) {
      debugPrint('❌ Erreur assignation livraison: $e');
      rethrow;
    }
  }

  /// Récupère les statistiques de performance d'un livreur
  Future<Map<String, dynamic>> getLivreurPerformanceStats(String livreurId) async {
    try {
      final rating = await _reviewService.getAverageRating(livreurId, 'livreur');
      final totalReviews = (await _reviewService.getReviewsByLivreur(livreurId)).length;
      final distribution = await _reviewService.getRatingDistribution(livreurId, 'livreur');

      return {
        'rating': rating,
        'totalReviews': totalReviews,
        'distribution': distribution,
        'isTrusted': rating >= 4.5 && totalReviews >= 10,
        'trustLevel': rating >= 4.5
            ? 'Excellent'
            : rating >= 4.0
                ? 'Bon'
                : rating >= 3.5
                    ? 'Correct'
                    : 'À améliorer',
      };
    } catch (e) {
      debugPrint('❌ Erreur stats livreur: $e');
      return {
        'rating': 0.0,
        'totalReviews': 0,
        'distribution': {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
        'isTrusted': false,
        'trustLevel': 'Inconnu',
      };
    }
  }
}
