// ===== lib/services/platform_revenue_service.dart =====
// Service pour la gestion des revenus de la plateforme

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/revenue_model.dart' as revenue;
import '../models/financial_summary_model.dart';
import '../models/order_model.dart';
import '../models/subscription_model.dart';
import '../config/constants.dart';

class PlatformRevenueService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ========== ENREGISTREMENT DES REVENUS ==========

  /// Enregistrer une commission de vente
  static Future<void> recordSaleCommission(OrderModel order) async {
    try {
      // Récupérer l'abonnement du vendeur pour connaître le taux de commission
      final vendeurDoc = await _firestore
          .collection(FirebaseCollections.users)
          .doc(order.vendeurId)
          .get();

      if (!vendeurDoc.exists) return;

      final vendeurData = vendeurDoc.data()!;
      final subscriptionTier = vendeurData['subscriptionTier'] as String? ?? 'BASIQUE';

      // Taux de commission selon le tier
      double commissionRate;
      switch (subscriptionTier.toUpperCase()) {
        case 'PREMIUM':
          commissionRate = 0.05; // 5%
          break;
        case 'PRO':
          commissionRate = 0.10; // 10%
          break;
        case 'BASIQUE':
        default:
          commissionRate = 0.15; // 15%
          break;
      }

      final commissionAmount = order.totalAmount * commissionRate;
      final now = DateTime.now();

      final revenueRecord = revenue.RevenueModel(
        id: '', // Sera généré par Firestore
        type: revenue.RevenueType.commissionVente,
        amount: commissionAmount,
        sourceId: order.id,
        userId: order.vendeurId,
        userType: revenue.UserType.vendeur,
        description: 'Commission ${(commissionRate * 100).toStringAsFixed(0)}% sur commande ${order.displayNumber}',
        metadata: {
          'orderId': order.id,
          'orderTotal': order.totalAmount,
          'commissionRate': commissionRate,
          'subscriptionTier': subscriptionTier,
        },
        createdAt: now,
        month: now.month,
        year: now.year,
      );

      await _firestore
          .collection('platform_revenue')
          .add(revenueRecord.toFirestore());

      // Mettre à jour le résumé mensuel
      await updateMonthlySummary(now.year, now.month);
    } catch (e) {
      debugPrint('❌ Erreur enregistrement commission vente: $e');
      rethrow;
    }
  }

  /// Enregistrer une commission de livraison
  static Future<void> recordDeliveryCommission({
    required String deliveryId,
    required String livreurId,
    required double deliveryFee,
  }) async {
    try {
      // Récupérer l'abonnement du livreur pour connaître le taux de commission
      final livreurDoc = await _firestore
          .collection(FirebaseCollections.users)
          .doc(livreurId)
          .get();

      if (!livreurDoc.exists) return;

      final livreurData = livreurDoc.data()!;
      final subscriptionTier = livreurData['subscriptionTier'] as String? ?? 'STARTER';

      // Taux de commission selon le tier
      double commissionRate;
      switch (subscriptionTier.toUpperCase()) {
        case 'PREMIUM':
          commissionRate = 0.10; // 10%
          break;
        case 'PRO':
          commissionRate = 0.15; // 15%
          break;
        case 'STARTER':
        default:
          commissionRate = 0.25; // 25%
          break;
      }

      final commissionAmount = deliveryFee * commissionRate;
      final now = DateTime.now();

      final revenueRecord = revenue.RevenueModel(
        id: '', // Sera généré par Firestore
        type: revenue.RevenueType.commissionLivraison,
        amount: commissionAmount,
        sourceId: deliveryId,
        userId: livreurId,
        userType: revenue.UserType.livreur,
        description: 'Commission ${(commissionRate * 100).toStringAsFixed(0)}% sur livraison',
        metadata: {
          'deliveryId': deliveryId,
          'deliveryFee': deliveryFee,
          'commissionRate': commissionRate,
          'subscriptionTier': subscriptionTier,
        },
        createdAt: now,
        month: now.month,
        year: now.year,
      );

      await _firestore
          .collection('platform_revenue')
          .add(revenueRecord.toFirestore());

      // Mettre à jour le résumé mensuel
      await updateMonthlySummary(now.year, now.month);
    } catch (e) {
      debugPrint('❌ Erreur enregistrement commission livraison: $e');
      rethrow;
    }
  }

  /// Enregistrer un revenu d'abonnement vendeur
  static Future<void> recordVendeurSubscriptionRevenue(VendeurSubscription subscription) async {
    try {
      final now = DateTime.now();

      final revenueRecord = revenue.RevenueModel(
        id: '', // Sera généré par Firestore
        type: revenue.RevenueType.abonnementVendeur,
        amount: subscription.monthlyPrice,
        sourceId: subscription.id,
        userId: subscription.vendeurId,
        userType: revenue.UserType.vendeur,
        description: 'Abonnement ${subscription.tierName} vendeur',
        metadata: {
          'subscriptionTier': subscription.tierName,
          'subscriptionPeriod': 'monthly',
          'startDate': subscription.startDate,
          'endDate': subscription.endDate,
        },
        createdAt: now,
        month: now.month,
        year: now.year,
      );

      await _firestore
          .collection('platform_revenue')
          .add(revenueRecord.toFirestore());

      // Mettre à jour le résumé mensuel
      await updateMonthlySummary(now.year, now.month);
    } catch (e) {
      debugPrint('❌ Erreur enregistrement abonnement vendeur: $e');
      rethrow;
    }
  }

  /// Enregistrer un revenu d'abonnement livreur
  static Future<void> recordLivreurSubscriptionRevenue(LivreurSubscription subscription) async {
    try {
      final now = DateTime.now();

      final revenueRecord = revenue.RevenueModel(
        id: '', // Sera généré par Firestore
        type: revenue.RevenueType.abonnementLivreur,
        amount: subscription.monthlyPrice,
        sourceId: subscription.id,
        userId: subscription.livreurId,
        userType: revenue.UserType.livreur,
        description: 'Abonnement ${subscription.tierName} livreur',
        metadata: {
          'subscriptionTier': subscription.tierName,
          'subscriptionPeriod': 'monthly',
          'startDate': subscription.startDate,
          'endDate': subscription.endDate,
        },
        createdAt: now,
        month: now.month,
        year: now.year,
      );

      await _firestore
          .collection('platform_revenue')
          .add(revenueRecord.toFirestore());

      // Mettre à jour le résumé mensuel
      await updateMonthlySummary(now.year, now.month);
    } catch (e) {
      debugPrint('❌ Erreur enregistrement abonnement livreur: $e');
      rethrow;
    }
  }

  // ========== RÉCUPÉRATION DES DONNÉES ==========

  /// Récupérer tous les revenus d'une période
  static Future<List<revenue.RevenueModel>> getRevenueByPeriod(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('platform_revenue')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => revenue.RevenueModel.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('❌ Erreur récupération revenus: $e');
      return [];
    }
  }

  /// Récupérer les revenus d'un mois spécifique
  static Future<List<revenue.RevenueModel>> getRevenueByMonth(int year, int month) async {
    try {
      final snapshot = await _firestore
          .collection('platform_revenue')
          .where('year', isEqualTo: year)
          .where('month', isEqualTo: month)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => revenue.RevenueModel.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('❌ Erreur récupération revenus du mois: $e');
      return [];
    }
  }

  /// Récupérer le résumé financier d'un mois
  static Future<FinancialSummary> getMonthlySummary(int year, int month) async {
    try {
      final monthStr = month.toString().padLeft(2, '0');
      final docId = '$year-$monthStr';

      final doc = await _firestore
          .collection('financial_summary')
          .doc(docId)
          .get();

      if (doc.exists) {
        return FinancialSummary.fromFirestore(doc);
      } else {
        // Retourner un résumé vide si pas encore créé
        return FinancialSummary.empty(year, month);
      }
    } catch (e) {
      debugPrint('❌ Erreur récupération résumé mensuel: $e');
      return FinancialSummary.empty(year, month);
    }
  }

  /// Récupérer les résumés des N derniers mois
  static Future<List<FinancialSummary>> getLastMonthsSummaries(int numberOfMonths) async {
    try {
      final now = DateTime.now();
      final summaries = <FinancialSummary>[];

      for (int i = 0; i < numberOfMonths; i++) {
        final targetDate = DateTime(now.year, now.month - i, 1);
        final summary = await getMonthlySummary(targetDate.year, targetDate.month);
        summaries.add(summary);
      }

      return summaries;
    } catch (e) {
      debugPrint('❌ Erreur récupération résumés mensuels: $e');
      return [];
    }
  }

  // ========== MISE À JOUR DU RÉSUMÉ MENSUEL ==========

  /// Calculer et mettre à jour le résumé mensuel
  static Future<void> updateMonthlySummary(int year, int month) async {
    try {
      final monthStr = month.toString().padLeft(2, '0');
      final docId = '$year-$monthStr';

      // Récupérer tous les revenus du mois
      final revenues = await getRevenueByMonth(year, month);

      // Calculer les totaux par catégorie
      double commissionsVente = 0.0;
      double commissionsLivraison = 0.0;
      double abonnementsVendeurs = 0.0;
      double abonnementsLivreurs = 0.0;

      for (final rev in revenues) {
        switch (rev.type) {
          case revenue.RevenueType.commissionVente:
            commissionsVente += rev.amount;
            break;
          case revenue.RevenueType.commissionLivraison:
            commissionsLivraison += rev.amount;
            break;
          case revenue.RevenueType.abonnementVendeur:
            abonnementsVendeurs += rev.amount;
            break;
          case revenue.RevenueType.abonnementLivreur:
            abonnementsLivreurs += rev.amount;
            break;
        }
      }

      // Compter les statistiques
      final nbCommandesLivrees = revenues
          .where((r) => r.type == revenue.RevenueType.commissionVente)
          .length;

      final nbLivraisons = revenues
          .where((r) => r.type == revenue.RevenueType.commissionLivraison)
          .length;

      // Compter les abonnements actifs (simplifié pour l'instant)
      final nbAbonnementsVendeursActifs = revenues
          .where((r) => r.type == revenue.RevenueType.abonnementVendeur)
          .length;

      final nbAbonnementsLivreursActifs = revenues
          .where((r) => r.type == revenue.RevenueType.abonnementLivreur)
          .length;

      // Répartition par tier (à améliorer avec des requêtes plus précises)
      final vendeursParTier = {'basique': 0, 'pro': 0, 'premium': 0};
      final livreursParTier = {'starter': 0, 'pro': 0, 'premium': 0};

      // Créer/mettre à jour le résumé
      final summary = FinancialSummary(
        id: docId,
        month: month,
        year: year,
        commissionsVente: commissionsVente,
        commissionsLivraison: commissionsLivraison,
        abonnementsVendeurs: abonnementsVendeurs,
        abonnementsLivreurs: abonnementsLivreurs,
        total: commissionsVente + commissionsLivraison + abonnementsVendeurs + abonnementsLivreurs,
        nbCommandesLivrees: nbCommandesLivrees,
        nbLivraisons: nbLivraisons,
        nbAbonnementsVendeursActifs: nbAbonnementsVendeursActifs,
        nbAbonnementsLivreursActifs: nbAbonnementsLivreursActifs,
        vendeursParTier: vendeursParTier,
        livreursParTier: livreursParTier,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('financial_summary')
          .doc(docId)
          .set(summary.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('❌ Erreur mise à jour résumé mensuel: $e');
      rethrow;
    }
  }

  // ========== STATISTIQUES GLOBALES ==========

  /// Calculer les statistiques globales (tous les temps)
  static Future<Map<String, dynamic>> getGlobalStats() async {
    try {
      final snapshot = await _firestore
          .collection('platform_revenue')
          .get();

      final revenues = snapshot.docs.map((doc) => revenue.RevenueModel.fromFirestore(doc)).toList();

      double totalCommissionsVente = 0.0;
      double totalCommissionsLivraison = 0.0;
      double totalAbonnementsVendeurs = 0.0;
      double totalAbonnementsLivreurs = 0.0;

      for (final rev in revenues) {
        switch (rev.type) {
          case revenue.RevenueType.commissionVente:
            totalCommissionsVente += rev.amount;
            break;
          case revenue.RevenueType.commissionLivraison:
            totalCommissionsLivraison += rev.amount;
            break;
          case revenue.RevenueType.abonnementVendeur:
            totalAbonnementsVendeurs += rev.amount;
            break;
          case revenue.RevenueType.abonnementLivreur:
            totalAbonnementsLivreurs += rev.amount;
            break;
        }
      }

      return {
        'totalRevenue': totalCommissionsVente + totalCommissionsLivraison + totalAbonnementsVendeurs + totalAbonnementsLivreurs,
        'commissionsVente': totalCommissionsVente,
        'commissionsLivraison': totalCommissionsLivraison,
        'abonnementsVendeurs': totalAbonnementsVendeurs,
        'abonnementsLivreurs': totalAbonnementsLivreurs,
        'nbTransactions': revenues.length,
      };
    } catch (e) {
      debugPrint('❌ Erreur calcul statistiques globales: $e');
      return {
        'totalRevenue': 0.0,
        'commissionsVente': 0.0,
        'commissionsLivraison': 0.0,
        'abonnementsVendeurs': 0.0,
        'abonnementsLivreurs': 0.0,
        'nbTransactions': 0,
      };
    }
  }
}
