// ===== lib/services/vendor_stats_service.dart =====
// Service pour les statistiques vendeur - SOCIAL BUSINESS Pro

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import '../config/constants.dart';

class VendorStatsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Calculer les statistiques complètes d'un vendeur
  static Future<VendorStats> getVendorStats(String vendeurId) async {
    try {
      debugPrint('📊 === Calcul statistiques vendeur: $vendeurId ===');

      // 1. Charger toutes les commandes du vendeur
      final ordersSnapshot = await _firestore
          .collection(FirebaseCollections.orders)
          .where('vendeurId', isEqualTo: vendeurId)
          .get();

      final orders = ordersSnapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList();

      debugPrint('📦 Total commandes: ${orders.length}');

      // 2. Calculer les statistiques des commandes
      int pendingOrders = 0;
      int confirmedOrders = 0;
      int preparingOrders = 0;
      int readyOrders = 0;
      int inDeliveryOrders = 0;
      int deliveredOrders = 0;
      int cancelledOrders = 0;
      int returnedOrders = 0;

      num totalRevenue = 0;
      num monthlyRevenue = 0;

      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      for (var order in orders) {
        final status = order.status.toLowerCase();
        debugPrint('📦 Commande ${order.id}: statut="${order.status}" (lowercase: "$status")');

        // Compter par statut
        switch (status) {
          case 'pending':
          case 'en_attente':
            pendingOrders++;
            break;
          case 'confirmed':
          case 'ready':
          case 'preparing':
          case 'in_delivery':
          case 'in delivery':
          case 'processing':
          case 'en_cours':
            confirmedOrders++; // On utilise confirmedOrders pour "en cours"
            break;
          case 'delivered':
          case 'completed':
          case 'livree':
            deliveredOrders++;
            totalRevenue += order.subtotal; // Revenu brut du vendeur (sans frais de livraison)
            break;
          case 'cancelled':
          case 'canceled':
          case 'annulee':
            cancelledOrders++;
            break;
          case 'retourne':
          case 'retournee':
          case 'returned':
            returnedOrders++;
            break;
          default:
            debugPrint('⚠️ Statut non reconnu: $status pour commande ${order.id}');
            break;
        }

        // Revenu mensuel (uniquement commandes livrées ce mois)
        if ((status == 'delivered' || status == 'completed' || status == 'livree') &&
            order.createdAt.isAfter(startOfMonth)) {
          monthlyRevenue += order.subtotal; // Utiliser subtotal au lieu de totalAmount
        }
      }

      debugPrint('📊 En attente: $pendingOrders');
      debugPrint('📊 En cours: $confirmedOrders');
      debugPrint('📊 Livrées: $deliveredOrders');
      debugPrint('📊 Annulées: $cancelledOrders');
      debugPrint('📊 Retournées: $returnedOrders');

      // 3. Charger les produits du vendeur
      final productsSnapshot = await _firestore
          .collection(FirebaseCollections.products)
          .where('vendeurId', isEqualTo: vendeurId)
          .get();

      final products = productsSnapshot.docs
          .map((doc) => ProductModel.fromMap({...doc.data(), 'id': doc.id}))
          .toList();

      final totalProducts = products.length;
      final activeProducts = products.where((p) => p.stock > 0).length;

      debugPrint('🛍️  Total produits: $totalProducts');
      debugPrint('✅ Produits actifs: $activeProducts');

      // 4. Calculer les vues du mois (simulation pour l'instant)
      // TODO: Implémenter un système de tracking des vues
      final viewsThisMonth = products.fold<int>(
        0,
        (total, product) => total + (product.stock > 0 ? 10 : 0),
      );

      return VendorStats(
        totalOrders: orders.length,
        pendingOrders: pendingOrders,
        confirmedOrders: confirmedOrders,
        preparingOrders: preparingOrders,
        readyOrders: readyOrders,
        inDeliveryOrders: inDeliveryOrders,
        deliveredOrders: deliveredOrders,
        cancelledOrders: cancelledOrders,
        returnedOrders: returnedOrders,
        totalRevenue: totalRevenue,
        monthlyRevenue: monthlyRevenue,
        totalProducts: totalProducts,
        activeProducts: activeProducts,
        viewsThisMonth: viewsThisMonth,
      );
    } catch (e) {
      debugPrint('❌ Erreur calcul statistiques: $e');
      throw Exception('Impossible de calculer les statistiques: $e');
    }
  }

  /// Récupérer les commandes récentes d'un vendeur (5 dernières)
  static Future<List<RecentOrderData>> getRecentOrders(String vendeurId, {int limit = 5}) async {
    try {
      debugPrint('📋 Chargement commandes récentes vendeur: $vendeurId');

      final querySnapshot = await _firestore
          .collection(FirebaseCollections.orders)
          .where('vendeurId', isEqualTo: vendeurId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      final recentOrders = <RecentOrderData>[];

      for (var doc in querySnapshot.docs) {
        final order = OrderModel.fromFirestore(doc);

        // Récupérer le nom de l'acheteur
        String customerName = 'Client inconnu';
        try {
          final buyerDoc =
              await _firestore.collection(FirebaseCollections.users).doc(order.buyerId).get();

          if (buyerDoc.exists) {
            customerName = buyerDoc.data()?['displayName'] ?? 'Client inconnu';
          }
        } catch (e) {
          debugPrint('⚠️  Erreur récupération nom client: $e');
        }

        recentOrders.add(RecentOrderData(
          id: order.id,
          orderNumber: order.orderNumber,
          displayNumber: order.displayNumber,
          customerName: customerName,
          amount: order.totalAmount,
          status: order.status,
          date: order.createdAt,
        ));
      }

      debugPrint('✅ ${recentOrders.length} commandes récentes chargées');
      return recentOrders;
    } catch (e) {
      debugPrint('❌ Erreur chargement commandes récentes: $e');
      throw Exception('Impossible de charger les commandes récentes: $e');
    }
  }
}

/// Classe pour les statistiques vendeur
class VendorStats {
  final int totalOrders;
  final int pendingOrders;
  final int confirmedOrders;
  final int preparingOrders;
  final int readyOrders;
  final int inDeliveryOrders;
  final int deliveredOrders;
  final int cancelledOrders;
  final int returnedOrders;
  final num totalRevenue;
  final num monthlyRevenue;
  final int totalProducts;
  final int activeProducts;
  final int viewsThisMonth;

  VendorStats({
    required this.totalOrders,
    required this.pendingOrders,
    required this.confirmedOrders,
    required this.preparingOrders,
    required this.readyOrders,
    required this.inDeliveryOrders,
    required this.deliveredOrders,
    required this.cancelledOrders,
    required this.returnedOrders,
    required this.totalRevenue,
    required this.monthlyRevenue,
    required this.totalProducts,
    required this.activeProducts,
    required this.viewsThisMonth,
  });

  /// Commandes actives = pending + confirmed + preparing + ready + in_delivery
  int get activeOrders =>
      pendingOrders + confirmedOrders + preparingOrders + readyOrders + inDeliveryOrders;

  /// Commandes complétées = delivered
  int get completedOrders => deliveredOrders;
}

/// Classe pour les données de commande récente
class RecentOrderData {
  final String id;
  final String orderNumber; // Pour les logs système
  final int displayNumber; // Numéro séquentiel affiché (1, 2, 3...)
  final String customerName;
  final num amount;
  final String status;
  final DateTime date;

  RecentOrderData({
    required this.id,
    required this.orderNumber,
    required this.displayNumber,
    required this.customerName,
    required this.amount,
    required this.status,
    required this.date,
  });
}
