// ===== lib/services/dynamic_commission_service.dart =====
// Service de calcul dynamique des commissions - SOCIAL BUSINESS Pro

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/livreur_trust_level.dart';
import 'subscription_service.dart';

/// Service de tarification dynamique des commissions
///
/// Calcule les commissions en fonction de:
/// - Niveau de confiance du livreur (trust level)
/// - Abonnement du livreur (STARTER/PRO/PREMIUM)
/// - Montant de la commande
/// - Performance du livreur (bonus/malus)
class DynamicCommissionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Calculer la commission pour une livraison
  ///
  /// Retourne un Map avec:
  /// - `baseRate`: Taux de base selon abonnement (0.25, 0.20, 0.15)
  /// - `trustBonus`: Bonus basé sur le niveau de confiance (-0.05 à +0.05)
  /// - `performanceBonus`: Bonus basé sur la note moyenne (-0.02 à +0.03)
  /// - `finalRate`: Taux final appliqué
  /// - `commissionAmount`: Montant de la commission en FCFA
  /// - `livreurEarnings`: Ce que le livreur reçoit
  static Future<Map<String, dynamic>> calculateDeliveryCommission({
    required String livreurId,
    required double orderAmount,
  }) async {
    try {
      debugPrint('💰 Calcul commission pour livreur $livreurId - Montant: $orderAmount FCFA');

      // 1. Récupérer les données du livreur
      final livreurDoc = await _firestore
          .collection('users')
          .doc(livreurId)
          .get();

      if (!livreurDoc.exists) {
        throw Exception('Livreur introuvable');
      }

      final livreurData = livreurDoc.data()!;
      final profile = livreurData['profile'] as Map<String, dynamic>? ?? {};

      // 2. Récupérer les métriques de performance
      final completedDeliveries = profile['completedDeliveries'] as int? ?? 0;
      final averageRating = (profile['averageRating'] as num? ?? 0.0).toDouble();
      final cautionDeposited = (profile['cautionDeposited'] as num? ?? 0.0).toDouble();

      // 3. Calculer le niveau de confiance
      final trustConfig = LivreurTrustConfig.getConfig(
        completedDeliveries: completedDeliveries,
        averageRating: averageRating,
        cautionDeposited: cautionDeposited,
      );

      // 4. Récupérer le taux de commission de base (selon abonnement)
      final subscriptionService = SubscriptionService();
      final baseRate = await subscriptionService.getLivreurCommissionRate(livreurId);

      // 5. Appliquer bonus de niveau de confiance
      double trustBonus = 0.0;
      switch (trustConfig.level) {
        case LivreurTrustLevel.debutant:
          trustBonus = 0.0; // Pas de bonus
          break;
        case LivreurTrustLevel.confirme:
          trustBonus = -0.02; // -2% de commission (gagne plus)
          break;
        case LivreurTrustLevel.expert:
          trustBonus = -0.04; // -4% de commission
          break;
        case LivreurTrustLevel.vip:
          trustBonus = -0.05; // -5% de commission
          break;
      }

      // 6. Appliquer bonus de performance (basé sur la note)
      double performanceBonus = 0.0;
      if (averageRating >= 4.8) {
        performanceBonus = -0.03; // Excellente note: -3%
      } else if (averageRating >= 4.5) {
        performanceBonus = -0.02; // Très bonne note: -2%
      } else if (averageRating >= 4.0) {
        performanceBonus = -0.01; // Bonne note: -1%
      } else if (averageRating < 3.5 && averageRating > 0) {
        performanceBonus = 0.02; // Mauvaise note: +2% (malus)
      }

      // 7. Calculer le taux final (ne peut pas descendre en dessous de 10%)
      double finalRate = baseRate + trustBonus + performanceBonus;
      finalRate = finalRate.clamp(0.10, 0.30); // Entre 10% et 30%

      // 8. Calculer les montants
      final commissionAmount = orderAmount * finalRate;
      final livreurEarnings = orderAmount - commissionAmount;

      debugPrint('✅ Commission calculée:');
      debugPrint('   - Taux de base: ${(baseRate * 100).toStringAsFixed(0)}%');
      debugPrint('   - Bonus confiance: ${(trustBonus * 100).toStringAsFixed(0)}%');
      debugPrint('   - Bonus performance: ${(performanceBonus * 100).toStringAsFixed(0)}%');
      debugPrint('   - Taux final: ${(finalRate * 100).toStringAsFixed(1)}%');
      debugPrint('   - Commission: ${commissionAmount.toStringAsFixed(0)} FCFA');
      debugPrint('   - Gains livreur: ${livreurEarnings.toStringAsFixed(0)} FCFA');

      return {
        'baseRate': baseRate,
        'trustBonus': trustBonus,
        'performanceBonus': performanceBonus,
        'finalRate': finalRate,
        'commissionAmount': commissionAmount,
        'livreurEarnings': livreurEarnings,
        'orderAmount': orderAmount,
        'trustLevel': trustConfig.level.name,
        'averageRating': averageRating,
        'completedDeliveries': completedDeliveries,
      };

    } catch (e) {
      debugPrint('❌ Erreur calcul commission: $e');

      // Retourner valeur par défaut en cas d'erreur
      return {
        'baseRate': 0.25,
        'trustBonus': 0.0,
        'performanceBonus': 0.0,
        'finalRate': 0.25,
        'commissionAmount': orderAmount * 0.25,
        'livreurEarnings': orderAmount * 0.75,
        'orderAmount': orderAmount,
        'error': e.toString(),
      };
    }
  }

  /// Calculer les commissions pour plusieurs livraisons (batch)
  static Future<Map<String, dynamic>> calculateBatchCommissions({
    required String livreurId,
    required List<double> orderAmounts,
  }) async {
    try {
      double totalCommission = 0.0;
      double totalEarnings = 0.0;
      final List<Map<String, dynamic>> details = [];

      for (final amount in orderAmounts) {
        final result = await calculateDeliveryCommission(
          livreurId: livreurId,
          orderAmount: amount,
        );

        totalCommission += result['commissionAmount'] as double;
        totalEarnings += result['livreurEarnings'] as double;
        details.add(result);
      }

      return {
        'totalOrders': orderAmounts.length,
        'totalOrderAmount': orderAmounts.reduce((a, b) => a + b),
        'totalCommission': totalCommission,
        'totalEarnings': totalEarnings,
        'averageRate': totalCommission / orderAmounts.reduce((a, b) => a + b),
        'details': details,
      };

    } catch (e) {
      debugPrint('❌ Erreur calcul batch commissions: $e');
      rethrow;
    }
  }

  /// Simuler les gains potentiels selon différents niveaux de confiance
  ///
  /// Utile pour afficher à l'utilisateur ce qu'il peut gagner en montant de niveau
  static Map<String, dynamic> simulateEarningsByTrustLevel({
    required double orderAmount,
    required double currentAverageRating,
  }) {
    final Map<String, Map<String, dynamic>> scenarios = {};

    // Simuler chaque niveau
    for (final level in LivreurTrustLevel.values) {
      // Taux de base (on suppose abonnement STARTER pour la simulation)
      double baseRate = 0.25;

      // Bonus confiance
      double trustBonus = 0.0;
      switch (level) {
        case LivreurTrustLevel.debutant:
          trustBonus = 0.0;
          break;
        case LivreurTrustLevel.confirme:
          trustBonus = -0.02;
          break;
        case LivreurTrustLevel.expert:
          trustBonus = -0.04;
          break;
        case LivreurTrustLevel.vip:
          trustBonus = -0.05;
          break;
      }

      // Bonus performance (on garde la note actuelle)
      double performanceBonus = 0.0;
      if (currentAverageRating >= 4.8) {
        performanceBonus = -0.03;
      } else if (currentAverageRating >= 4.5) {
        performanceBonus = -0.02;
      } else if (currentAverageRating >= 4.0) {
        performanceBonus = -0.01;
      }

      final finalRate = (baseRate + trustBonus + performanceBonus).clamp(0.10, 0.30);
      final commission = orderAmount * finalRate;
      final earnings = orderAmount - commission;

      scenarios[level.name] = {
        'level': level.name,
        'finalRate': finalRate,
        'commissionAmount': commission,
        'livreurEarnings': earnings,
        'savingsVsDebutant': 0.0, // Calculé après
      };
    }

    // Calculer les économies par rapport au niveau débutant
    final debutantCommission = scenarios['debutant']!['commissionAmount'] as double;
    for (final scenario in scenarios.values) {
      final commission = scenario['commissionAmount'] as double;
      scenario['savingsVsDebutant'] = debutantCommission - commission;
    }

    return {
      'orderAmount': orderAmount,
      'scenarios': scenarios,
    };
  }

  /// Obtenir un résumé des gains d'un livreur sur une période
  static Future<Map<String, dynamic>> getLivreurEarningsSummary({
    required String livreurId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      debugPrint('📊 Calcul résumé gains livreur $livreurId');

      // Récupérer toutes les livraisons de la période
      final deliveriesSnapshot = await _firestore
          .collection('deliveries')
          .where('livreurId', isEqualTo: livreurId)
          .where('deliveredAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('deliveredAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .where('status', isEqualTo: 'delivered')
          .get();

      if (deliveriesSnapshot.docs.isEmpty) {
        return {
          'totalDeliveries': 0,
          'totalOrderAmount': 0.0,
          'totalCommission': 0.0,
          'totalEarnings': 0.0,
          'averageCommissionRate': 0.0,
        };
      }

      double totalOrderAmount = 0.0;
      double totalCommission = 0.0;
      double totalEarnings = 0.0;

      for (final doc in deliveriesSnapshot.docs) {
        final data = doc.data();
        final orderAmount = (data['orderAmount'] as num?)?.toDouble() ?? 0.0;
        final commission = (data['platformCommission'] as num?)?.toDouble() ?? 0.0;
        final earnings = (data['livreurEarnings'] as num?)?.toDouble() ?? 0.0;

        totalOrderAmount += orderAmount;
        totalCommission += commission;
        totalEarnings += earnings;
      }

      final averageRate = totalOrderAmount > 0
          ? totalCommission / totalOrderAmount
          : 0.0;

      debugPrint('✅ Résumé calculé:');
      debugPrint('   - ${deliveriesSnapshot.docs.length} livraisons');
      debugPrint('   - Total commandes: ${totalOrderAmount.toStringAsFixed(0)} FCFA');
      debugPrint('   - Total commissions: ${totalCommission.toStringAsFixed(0)} FCFA');
      debugPrint('   - Total gains: ${totalEarnings.toStringAsFixed(0)} FCFA');
      debugPrint('   - Taux moyen: ${(averageRate * 100).toStringAsFixed(1)}%');

      return {
        'totalDeliveries': deliveriesSnapshot.docs.length,
        'totalOrderAmount': totalOrderAmount,
        'totalCommission': totalCommission,
        'totalEarnings': totalEarnings,
        'averageCommissionRate': averageRate,
        'periodStart': startDate,
        'periodEnd': endDate,
      };

    } catch (e) {
      debugPrint('❌ Erreur résumé gains: $e');
      rethrow;
    }
  }

  /// Calculer la commission pour un vendeur sur une vente
  ///
  /// Retourne un Map avec:
  /// - `productAmount`: Montant des produits vendus (hors frais de livraison)
  /// - `commissionRate`: Taux de commission selon abonnement (0.07, 0.10)
  /// - `commissionAmount`: Montant de la commission en FCFA
  /// - `vendorEarnings`: Ce que le vendeur garde
  /// - `tier`: Niveau d'abonnement du vendeur
  static Future<Map<String, dynamic>> calculateVendorCommission({
    required String vendorId,
    required double totalAmount,
    required double deliveryFee,
  }) async {
    try {
      debugPrint('💰 Calcul commission vendeur $vendorId - Total: $totalAmount FCFA');

      // Calculer le montant des produits (hors frais de livraison)
      final productAmount = totalAmount - deliveryFee;

      // Récupérer le taux de commission du vendeur (basé sur l'abonnement)
      final subscriptionService = SubscriptionService();
      final commissionRate = await subscriptionService.getVendeurCommissionRate(vendorId);

      // Récupérer l'abonnement pour afficher le tier
      final subscription = await subscriptionService.getVendeurSubscription(vendorId);
      final tier = subscription?.tier.name ?? 'basique';

      // Calculer la commission
      final commissionAmount = productAmount * commissionRate;
      final vendorEarnings = productAmount - commissionAmount;

      debugPrint('✅ Commission vendeur calculée:');
      debugPrint('   - Montant produits: ${productAmount.toStringAsFixed(0)} FCFA');
      debugPrint('   - Taux commission: ${(commissionRate * 100).toStringAsFixed(0)}%');
      debugPrint('   - Commission plateforme: ${commissionAmount.toStringAsFixed(0)} FCFA');
      debugPrint('   - Gains vendeur: ${vendorEarnings.toStringAsFixed(0)} FCFA');
      debugPrint('   - Tier: $tier');

      return {
        'productAmount': productAmount,
        'commissionRate': commissionRate,
        'commissionAmount': commissionAmount,
        'vendorEarnings': vendorEarnings,
        'tier': tier,
        'deliveryFee': deliveryFee,
        'totalAmount': totalAmount,
      };

    } catch (e) {
      debugPrint('❌ Erreur calcul commission vendeur: $e');

      // Retourner valeur par défaut en cas d'erreur (10% commission)
      final productAmount = totalAmount - deliveryFee;
      return {
        'productAmount': productAmount,
        'commissionRate': 0.10,
        'commissionAmount': productAmount * 0.10,
        'vendorEarnings': productAmount * 0.90,
        'tier': 'basique',
        'deliveryFee': deliveryFee,
        'totalAmount': totalAmount,
        'error': e.toString(),
      };
    }
  }

  /// Obtenir un résumé des commissions d'un vendeur sur une période
  static Future<Map<String, dynamic>> getVendorCommissionSummary({
    required String vendorId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      debugPrint('📊 Calcul résumé commissions vendeur $vendorId');

      // Récupérer toutes les commandes de la période (livrées)
      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('vendeurId', isEqualTo: vendorId)
          .where('deliveredAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('deliveredAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .where('status', isEqualTo: 'delivered')
          .get();

      if (ordersSnapshot.docs.isEmpty) {
        return {
          'totalOrders': 0,
          'totalSales': 0.0,
          'totalCommission': 0.0,
          'totalEarnings': 0.0,
          'averageCommissionRate': 0.0,
        };
      }

      double totalSales = 0.0;
      double totalCommission = 0.0;
      double totalEarnings = 0.0;

      for (final doc in ordersSnapshot.docs) {
        final data = doc.data();
        final totalAmount = (data['totalAmount'] as num?)?.toDouble() ?? 0.0;
        final deliveryFee = (data['deliveryFee'] as num?)?.toDouble() ?? 0.0;
        final productAmount = totalAmount - deliveryFee;

        // Calculer la commission pour cette commande
        final commissionData = await calculateVendorCommission(
          vendorId: vendorId,
          totalAmount: totalAmount,
          deliveryFee: deliveryFee,
        );

        final commission = commissionData['commissionAmount'] as double;
        final earnings = commissionData['vendorEarnings'] as double;

        totalSales += productAmount;
        totalCommission += commission;
        totalEarnings += earnings;
      }

      final averageRate = totalSales > 0
          ? totalCommission / totalSales
          : 0.0;

      debugPrint('✅ Résumé calculé:');
      debugPrint('   - ${ordersSnapshot.docs.length} commandes');
      debugPrint('   - Total ventes: ${totalSales.toStringAsFixed(0)} FCFA');
      debugPrint('   - Total commissions: ${totalCommission.toStringAsFixed(0)} FCFA');
      debugPrint('   - Total gains: ${totalEarnings.toStringAsFixed(0)} FCFA');
      debugPrint('   - Taux moyen: ${(averageRate * 100).toStringAsFixed(1)}%');

      return {
        'totalOrders': ordersSnapshot.docs.length,
        'totalSales': totalSales,
        'totalCommission': totalCommission,
        'totalEarnings': totalEarnings,
        'averageCommissionRate': averageRate,
        'periodStart': startDate,
        'periodEnd': endDate,
      };

    } catch (e) {
      debugPrint('❌ Erreur résumé commissions vendeur: $e');
      rethrow;
    }
  }
}
