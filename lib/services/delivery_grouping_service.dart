// ===== lib/services/delivery_grouping_service.dart =====
// Service pour regrouper et optimiser les livraisons multiples

import 'package:flutter/foundation.dart';
import '../models/delivery_model.dart';
import 'dart:math' as math;

class DeliveryGroupingService {
  /// Regroupe les livraisons par vendeur
  /// Retourne une Map avec vendeurId comme clé et liste de livraisons comme valeur
  static Map<String, List<DeliveryModel>> groupByVendor(
    List<DeliveryModel> deliveries,
  ) {
    final Map<String, List<DeliveryModel>> grouped = {};

    for (final delivery in deliveries) {
      if (!grouped.containsKey(delivery.vendeurId)) {
        grouped[delivery.vendeurId] = [];
      }
      grouped[delivery.vendeurId]!.add(delivery);
    }

    return grouped;
  }

  /// Identifie les vendeurs ayant plusieurs livraisons assignées
  /// Retourne uniquement les groupes avec 2+ livraisons
  static Map<String, List<DeliveryModel>> findMultiDeliveryVendors(
    List<DeliveryModel> deliveries,
  ) {
    final grouped = groupByVendor(deliveries);

    // Filtrer pour garder uniquement les vendeurs avec 2+ livraisons
    grouped.removeWhere((vendeurId, list) => list.length < 2);

    return grouped;
  }

  /// Calcule les statistiques d'un groupe de livraisons
  static DeliveryGroupStats calculateGroupStats(
    List<DeliveryModel> deliveries,
  ) {
    if (deliveries.isEmpty) {
      return DeliveryGroupStats(
        totalDeliveries: 0,
        totalDistance: 0,
        totalFee: 0,
        averageDistance: 0,
        vendeurId: '',
        vendeurName: '',
      );
    }

    final totalDistance = deliveries.fold<double>(
      0,
      (sum, d) => sum + d.distance,
    );

    final totalFee = deliveries.fold<double>(
      0,
      (sum, d) => sum + d.deliveryFee,
    );

    // Extraire le nom du vendeur depuis pickupAddress
    final vendeurName = deliveries.first.pickupAddress['name'] as String? ??
                        deliveries.first.pickupAddress['shopName'] as String? ??
                        'Vendeur';

    return DeliveryGroupStats(
      totalDeliveries: deliveries.length,
      totalDistance: totalDistance,
      totalFee: totalFee,
      averageDistance: totalDistance / deliveries.length,
      vendeurId: deliveries.first.vendeurId,
      vendeurName: vendeurName,
    );
  }

  /// Optimise l'ordre des livraisons en utilisant un algorithme du plus proche voisin
  /// Point de départ : boutique du vendeur
  /// Objectif : Minimiser la distance totale parcourue
  static List<DeliveryModel> optimizeRoute(
    List<DeliveryModel> deliveries,
  ) {
    if (deliveries.isEmpty || deliveries.length == 1) {
      return deliveries;
    }

    // Copier la liste pour ne pas modifier l'originale
    final remaining = List<DeliveryModel>.from(deliveries);
    final optimized = <DeliveryModel>[];

    // Point de départ : boutique du vendeur (pickupAddress contient lat/lng)
    final startLat = deliveries.first.pickupAddress['latitude'] as double? ?? 0.0;
    final startLng = deliveries.first.pickupAddress['longitude'] as double? ?? 0.0;

    double currentLat = startLat;
    double currentLng = startLng;

    // Algorithme du plus proche voisin
    while (remaining.isNotEmpty) {
      DeliveryModel? nearest;
      double minDistance = double.infinity;
      int nearestIndex = -1;

      // Trouver la livraison la plus proche
      for (int i = 0; i < remaining.length; i++) {
        final delivery = remaining[i];
        final deliveryLat = delivery.deliveryAddress['latitude'] as double? ?? 0.0;
        final deliveryLng = delivery.deliveryAddress['longitude'] as double? ?? 0.0;

        final distance = _calculateDistance(
          currentLat,
          currentLng,
          deliveryLat,
          deliveryLng,
        );

        if (distance < minDistance) {
          minDistance = distance;
          nearest = delivery;
          nearestIndex = i;
        }
      }

      if (nearest != null) {
        optimized.add(nearest);
        remaining.removeAt(nearestIndex);
        currentLat = nearest.deliveryAddress['latitude'] as double? ?? 0.0;
        currentLng = nearest.deliveryAddress['longitude'] as double? ?? 0.0;
      }
    }

    debugPrint('✅ Itinéraire optimisé: ${optimized.length} livraisons');
    return optimized;
  }

  /// Calcule la distance entre deux points GPS (formule de Haversine)
  /// Retourne la distance en kilomètres
  static double _calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadius = 6371.0; // Rayon de la Terre en km

    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  static double _toRadians(double degrees) {
    return degrees * math.pi / 180.0;
  }

  /// Calcule la distance totale réelle d'un itinéraire optimisé
  /// (boutique → client1 → client2 → ... → clientN)
  static double calculateOptimizedDistance(
    List<DeliveryModel> optimizedDeliveries,
  ) {
    if (optimizedDeliveries.isEmpty) return 0;

    double totalDistance = 0;

    // Boutique → Premier client
    final first = optimizedDeliveries.first;
    final pickupLat = first.pickupAddress['latitude'] as double? ?? 0.0;
    final pickupLng = first.pickupAddress['longitude'] as double? ?? 0.0;
    final firstDeliveryLat = first.deliveryAddress['latitude'] as double? ?? 0.0;
    final firstDeliveryLng = first.deliveryAddress['longitude'] as double? ?? 0.0;

    totalDistance += _calculateDistance(
      pickupLat,
      pickupLng,
      firstDeliveryLat,
      firstDeliveryLng,
    );

    // Client N → Client N+1
    for (int i = 0; i < optimizedDeliveries.length - 1; i++) {
      final current = optimizedDeliveries[i];
      final next = optimizedDeliveries[i + 1];

      final currentLat = current.deliveryAddress['latitude'] as double? ?? 0.0;
      final currentLng = current.deliveryAddress['longitude'] as double? ?? 0.0;
      final nextLat = next.deliveryAddress['latitude'] as double? ?? 0.0;
      final nextLng = next.deliveryAddress['longitude'] as double? ?? 0.0;

      totalDistance += _calculateDistance(
        currentLat,
        currentLng,
        nextLat,
        nextLng,
      );
    }

    return totalDistance;
  }

  /// Estime le temps de gain pour une tournée groupée
  /// Retourne le temps économisé en minutes
  static int estimateTimeSaved(
    List<DeliveryModel> deliveries,
  ) {
    if (deliveries.length <= 1) return 0;

    // Distance totale si livraisons séparées (boutique → client → boutique pour chaque)
    final separateDistance = deliveries.fold<double>(
      0,
      (sum, d) => sum + (d.distance * 2), // Aller-retour pour chaque livraison
    );

    // Distance optimisée (boutique → clients → fin)
    final optimized = optimizeRoute(deliveries);
    final optimizedDistance = calculateOptimizedDistance(optimized);

    // Différence de distance
    final savedDistance = separateDistance - optimizedDistance;

    // Estimation : 30 km/h en ville = 0.5 km/min
    // + 5 min de temps fixe économisé par livraison groupée (pas de retour boutique)
    final savedTime = (savedDistance / 0.5) + ((deliveries.length - 1) * 5);

    return savedTime.round();
  }
}

/// Classe pour les statistiques d'un groupe de livraisons
class DeliveryGroupStats {
  final int totalDeliveries;
  final double totalDistance;
  final double totalFee;
  final double averageDistance;
  final String vendeurId;
  final String vendeurName;

  DeliveryGroupStats({
    required this.totalDeliveries,
    required this.totalDistance,
    required this.totalFee,
    required this.averageDistance,
    required this.vendeurId,
    required this.vendeurName,
  });
}
