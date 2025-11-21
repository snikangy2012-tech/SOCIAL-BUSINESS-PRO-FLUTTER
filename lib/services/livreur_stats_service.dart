// ===== lib/services/livreur_stats_service.dart =====
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/delivery_model.dart';
import '../config/constants.dart';

class LivreurStatsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<LivreurStats> getLivreurStats(String livreurId) async {
    try {
      debugPrint('📊 === Calcul statistiques livreur: $livreurId ===');

      final deliveriesSnapshot = await _firestore
          .collection(FirebaseCollections.deliveries)
          .where('livreurId', isEqualTo: livreurId)
          .get();

      final deliveries = deliveriesSnapshot.docs
          .map((doc) => DeliveryModel.fromFirestore(doc))
          .toList();

      debugPrint('📦 Total livraisons: ${deliveries.length}');

      int pendingDeliveries = 0;
      int pickedUpDeliveries = 0;
      int inProgressDeliveries = 0;
      int deliveredDeliveries = 0;
      int cancelledDeliveries = 0;

      num totalEarnings = 0;
      num todayEarnings = 0;
      num weekEarnings = 0;
      num monthEarnings = 0;

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfMonth = DateTime(now.year, now.month, 1);

      for (var delivery in deliveries) {
        final status = delivery.status.toLowerCase();

        switch (status) {
          case 'pending':
            pendingDeliveries++;
            break;
          case 'picked_up':
            pickedUpDeliveries++;
            break;
          case 'in_progress':
            inProgressDeliveries++;
            break;
          case 'delivered':
            deliveredDeliveries++;
            totalEarnings += delivery.deliveryFee;

            if (delivery.deliveredAt != null) {
              if (delivery.deliveredAt!.isAfter(startOfDay)) {
                todayEarnings += delivery.deliveryFee;
              }
              if (delivery.deliveredAt!.isAfter(startOfWeek)) {
                weekEarnings += delivery.deliveryFee;
              }
              if (delivery.deliveredAt!.isAfter(startOfMonth)) {
                monthEarnings += delivery.deliveryFee;
              }
            }
            break;
          case 'cancelled':
            cancelledDeliveries++;
            break;
        }
      }

      debugPrint('📊 Pending: $pendingDeliveries');
      debugPrint('📊 Picked Up: $pickedUpDeliveries');
      debugPrint('📊 In Progress: $inProgressDeliveries');
      debugPrint('📊 Delivered: $deliveredDeliveries');
      debugPrint('📊 Cancelled: $cancelledDeliveries');
      debugPrint('💰 Total Earnings: $totalEarnings');

      return LivreurStats(
        totalDeliveries: deliveries.length,
        pendingDeliveries: pendingDeliveries,
        pickedUpDeliveries: pickedUpDeliveries,
        inProgressDeliveries: inProgressDeliveries,
        deliveredDeliveries: deliveredDeliveries,
        cancelledDeliveries: cancelledDeliveries,
        totalEarnings: totalEarnings,
        todayEarnings: todayEarnings,
        weekEarnings: weekEarnings,
        monthEarnings: monthEarnings,
      );
    } catch (e) {
      debugPrint('❌ Erreur calcul statistiques livreur: $e');
      throw Exception('Impossible de calculer les statistiques: $e');
    }
  }

  static Future<List<RecentDeliveryData>> getRecentDeliveries(
    String livreurId, {
    int limit = 5,
  }) async {
    try {
      debugPrint('📋 Chargement livraisons récentes livreur: $livreurId');

      final querySnapshot = await _firestore
          .collection(FirebaseCollections.deliveries)
          .where('livreurId', isEqualTo: livreurId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      final recentDeliveries = <RecentDeliveryData>[];
      final seenIds = <String>{}; // Pour éviter les doublons

      for (var doc in querySnapshot.docs) {
        final delivery = DeliveryModel.fromFirestore(doc);

        // Ignorer les doublons
        if (seenIds.contains(delivery.id)) {
          debugPrint('⚠️ Livraison dupliquée ignorée: ${delivery.id}');
          continue;
        }
        seenIds.add(delivery.id);

        String customerName = 'Client inconnu';
        String orderNumber = 'N/A';

        try {
          final orderDoc = await _firestore
              .collection(FirebaseCollections.orders)
              .doc(delivery.orderId)
              .get();

          if (orderDoc.exists) {
            final orderData = orderDoc.data()!;
            customerName = orderData['buyerName'] ?? 'Client inconnu';
            orderNumber = orderData['orderNumber'] ?? 'N/A';
          }
        } catch (e) {
          debugPrint('⚠️ Erreur récupération info commande: $e');
        }

        recentDeliveries.add(RecentDeliveryData(
          id: delivery.id,
          orderNumber: orderNumber,
          customerName: customerName,
          amount: delivery.deliveryFee,
          status: delivery.status,
          date: delivery.createdAt,
        ));
      }

      debugPrint('✅ ${recentDeliveries.length} livraisons récentes chargées (${seenIds.length} uniques)');
      return recentDeliveries;
    } catch (e) {
      debugPrint('❌ Erreur chargement livraisons récentes: $e');
      throw Exception('Impossible de charger les livraisons récentes: $e');
    }
  }
}

class LivreurStats {
  final int totalDeliveries;
  final int pendingDeliveries;
  final int pickedUpDeliveries;
  final int inProgressDeliveries;
  final int deliveredDeliveries;
  final int cancelledDeliveries;
  final num totalEarnings;
  final num todayEarnings;
  final num weekEarnings;
  final num monthEarnings;

  LivreurStats({
    required this.totalDeliveries,
    required this.pendingDeliveries,
    required this.pickedUpDeliveries,
    required this.inProgressDeliveries,
    required this.deliveredDeliveries,
    required this.cancelledDeliveries,
    required this.totalEarnings,
    required this.todayEarnings,
    required this.weekEarnings,
    required this.monthEarnings,
  });

  int get activeDeliveries => pickedUpDeliveries + inProgressDeliveries;
  int get completedDeliveries => deliveredDeliveries;
}

class RecentDeliveryData {
  final String id;
  final String orderNumber;
  final String customerName;
  final num amount;
  final String status;
  final DateTime date;

  RecentDeliveryData({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.amount,
    required this.status,
    required this.date,
  });
}
