// ===== lib/services/order_service.dart (VERSION COMPLÈTE) =====
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/order_model.dart';
import '../config/constants.dart';

class OrderService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Récupérer toutes les commandes d'un vendeur
  static Future<List<OrderModel>> getVendorOrders(String vendeurId) async {
    try {
      debugPrint('📦 Chargement commandes vendeur: $vendeurId');

      final querySnapshot = await _firestore
          .collection(FirebaseCollections.orders)
          .where('vendeurId', isEqualTo: vendeurId)
          .orderBy('createdAt', descending: true)
          .get();

      final orders = querySnapshot.docs.map((doc) {
        return OrderModel.fromFirestore(doc);
      }).toList();

      debugPrint('✅ ${orders.length} commandes chargées');
      return orders;

    } catch (e) {
      debugPrint('❌ Erreur chargement commandes: $e');
      throw Exception('Impossible de charger les commandes: $e');
    }
  }

  /// Récupérer toutes les commandes d'un acheteur
  static Future<List<OrderModel>> getOrdersByBuyer(String buyerId) async {
    try {
      debugPrint('📦 Chargement commandes acheteur: $buyerId');

      final querySnapshot = await _firestore
          .collection(FirebaseCollections.orders)
          .where('buyerId', isEqualTo: buyerId)
          .orderBy('createdAt', descending: true)
          .get();

      final orders = querySnapshot.docs.map((doc) {
        return OrderModel.fromFirestore(doc);
      }).toList();

      debugPrint('✅ ${orders.length} commandes chargées');
      return orders;

    } catch (e) {
      debugPrint('❌ Erreur chargement commandes: $e');
      throw Exception('Impossible de charger les commandes: $e');
    }
  }

  /// Récupérer les commandes par statut
  static Future<List<OrderModel>> getOrdersByStatus(
    String vendeurId, 
    String status
  ) async {
    try {
      debugPrint('📦 Chargement commandes vendeur $vendeurId - statut: $status');
      
      Query query = _firestore
          .collection(FirebaseCollections.orders)
          .where('vendeurId', isEqualTo: vendeurId);

      if (status != 'all') {
        query = query.where('status', isEqualTo: status);
      }

      final querySnapshot = await query
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList();
          
    } catch (e) {
      debugPrint('❌ Erreur filtrage commandes: $e');
      throw Exception('Erreur lors du filtrage: $e');
    }
  }

  /// Récupérer une commande par ID
  static Future<OrderModel?> getOrderById(String orderId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseCollections.orders)
          .doc(orderId)
          .get();

      if (doc.exists) {
        return OrderModel.fromFirestore(doc);
      }
      return null;
      
    } catch (e) {
      debugPrint('❌ Erreur récupération commande: $e');
      return null;
    }
  }

  /// Calculer les statistiques de commandes
  static Future<OrderStats> getOrderStats(String vendeurId) async {
    try {
      debugPrint('📊 Calcul statistiques commandes vendeur: $vendeurId');
      
      // Récupérer toutes les commandes du vendeur
      final allOrders = await getVendorOrders(vendeurId);

      if (allOrders.isEmpty) {
        return OrderStats(
          totalOrders: 0,
          pendingOrders: 0,
          deliveredOrders: 0,
          cancelledOrders: 0,
          totalRevenue: 0,
        );
      }

      // Calculer les statistiques
      int totalOrders = allOrders.length;
      int pendingOrders = allOrders.where((order) => 
        order.status == OrderStatus.pending.value || 
        order.status == OrderStatus.confirmed.value
      ).length;
      
      int deliveredOrders = allOrders.where((order) => 
        order.status == OrderStatus.delivered.value
      ).length;
      
      int cancelledOrders = allOrders.where((order) => 
        order.status == OrderStatus.cancelled.value
      ).length;

      // Calculer le revenu total (uniquement commandes livrées)
      double totalRevenue = allOrders
          .where((order) => order.status == OrderStatus.delivered.value)
          .fold(0.0, (sum, order) => sum + order.totalAmount);

      debugPrint('✅ Stats calculées - Total: $totalOrders, Revenu: $totalRevenue FCFA');

      return OrderStats(
        totalOrders: totalOrders,
        pendingOrders: pendingOrders,
        deliveredOrders: deliveredOrders,
        cancelledOrders: cancelledOrders,
        totalRevenue: totalRevenue,
      );
      
    } catch (e) {
      debugPrint('❌ Erreur calcul stats: $e');
      throw Exception('Erreur lors du calcul des statistiques: $e');
    }
  }

  /// Mettre à jour le statut d'une commande
  static Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      debugPrint('🔄 MAJ statut commande $orderId → $newStatus');
      
      await _firestore
          .collection(FirebaseCollections.orders)
          .doc(orderId)
          .update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Ajouter une entrée dans l'historique de statut
      await _firestore
          .collection(FirebaseCollections.orders)
          .doc(orderId)
          .collection('statusHistory')
          .add({
        'status': newStatus,
        'changedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Statut mis à jour avec succès');
      
    } catch (e) {
      debugPrint('❌ Erreur MAJ statut: $e');
      throw Exception('Impossible de mettre à jour le statut: $e');
    }
  }

  /// Annuler une commande
  static Future<void> cancelOrder(String orderId, String reason) async {
    try {
      debugPrint('❌ Annulation commande $orderId - Raison: $reason');
      
      await _firestore
          .collection(FirebaseCollections.orders)
          .doc(orderId)
          .update({
        'status': OrderStatus.cancelled.value,
        'cancellationReason': reason,
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Ajouter dans l'historique
      await _firestore
          .collection(FirebaseCollections.orders)
          .doc(orderId)
          .collection('statusHistory')
          .add({
        'status': OrderStatus.cancelled.value,
        'reason': reason,
        'changedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Commande annulée avec succès');
      
    } catch (e) {
      debugPrint('❌ Erreur annulation commande: $e');
      throw Exception('Impossible d\'annuler la commande: $e');
    }
  }

  /// Écouter les changements en temps réel des commandes d'un vendeur
  static Stream<List<OrderModel>> watchVendorOrders(String vendeurId) {
    return _firestore
        .collection(FirebaseCollections.orders)
        .where('vendeurId', isEqualTo: vendeurId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Récupérer les commandes récentes (dernières 24h)
  static Future<List<OrderModel>> getRecentOrders(String vendeurId, {int hours = 24}) async {
    try {
      final cutoffTime = DateTime.now().subtract(Duration(hours: hours));
      
      final querySnapshot = await _firestore
          .collection(FirebaseCollections.orders)
          .where('vendeurId', isEqualTo: vendeurId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(cutoffTime))
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList();
          
    } catch (e) {
      debugPrint('❌ Erreur commandes récentes: $e');
      return [];
    }
  }

  /// Rechercher des commandes par numéro ou client
  static Future<List<OrderModel>> searchOrders(
    String vendeurId, 
    String searchTerm
  ) async {
    try {
      final allOrders = await getVendorOrders(vendeurId);
      
      // Filtrer localement (Firestore ne supporte pas LIKE)
      return allOrders.where((order) {
        final orderNumber = order.orderNumber.toLowerCase();
        final buyerName = order.buyerName.toLowerCase();
        final search = searchTerm.toLowerCase();
        
        return orderNumber.contains(search) || buyerName.contains(search);
      }).toList();
      
    } catch (e) {
      debugPrint('❌ Erreur recherche commandes: $e');
      return [];
    }
  }
}