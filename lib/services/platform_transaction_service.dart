// ===== lib/services/platform_transaction_service.dart =====
// Gestion complète des transactions, commissions et paiements cash de la plateforme

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/platform_transaction_model.dart';
import '../models/order_model.dart';
import '../models/delivery_model.dart';
import 'subscription_service.dart';

class PlatformTransactionService {
  static final _firestore = FirebaseFirestore.instance;
  static const String _transactionsCollection = 'platform_transactions';

  /// Crée une transaction lors de la livraison d'une commande
  /// Cette méthode calcule TOUTES les commissions et gère le cas du paiement cash
  static Future<PlatformTransaction?> createTransactionOnDelivery({
    required OrderModel order,
    required DeliveryModel delivery,
  }) async {
    try {
      debugPrint('💰 Création transaction plateforme pour commande ${order.displayNumber}');

      // 1. Récupérer les taux de commission
      final subscriptionService = SubscriptionService();
      final vendeurCommissionRate = await subscriptionService.getVendeurCommissionRate(order.vendeurId);
      final livreurCommissionRate = delivery.livreurId != null
          ? await subscriptionService.getLivreurCommissionRate(delivery.livreurId!)
          : 0.0;

      // 2. Calculer les montants
      final platformCommissionVendeur = order.subtotal * vendeurCommissionRate;
      final platformCommissionLivreur = order.deliveryFee * livreurCommissionRate;
      final totalPlatformRevenue = platformCommissionVendeur + platformCommissionLivreur;

      final vendeurAmount = order.subtotal - platformCommissionVendeur;
      final livreurAmount = order.deliveryFee - platformCommissionLivreur;

      // 3. Déterminer la méthode de paiement
      PaymentCollectionMethod paymentMethod;
      CommissionPaymentStatus initialStatus;

      if (order.paymentMethod == 'cash') {
        // PAIEMENT CASH : Le livreur collecte l'argent et doit reverser les commissions
        paymentMethod = PaymentCollectionMethod.cash;
        initialStatus = CommissionPaymentStatus.pending; // En attente du reversement
      } else {
        // MOBILE MONEY : Paiement direct, commissions automatiquement retenues
        paymentMethod = PaymentCollectionMethod.mobileMoney;
        initialStatus = CommissionPaymentStatus.paid; // Déjà payé
      }

      final now = DateTime.now();

      // 4. Créer la transaction
      final transaction = PlatformTransaction(
        id: '',
        type: PlatformTransactionType.vendeurCommission,
        orderId: order.id,
        deliveryId: delivery.id,
        vendeurId: order.vendeurId,
        livreurId: delivery.livreurId,
        buyerId: order.buyerId,
        orderAmount: order.totalAmount,
        vendeurAmount: vendeurAmount,
        livreurAmount: livreurAmount,
        platformCommissionVendeur: platformCommissionVendeur,
        platformCommissionLivreur: platformCommissionLivreur,
        totalPlatformRevenue: totalPlatformRevenue,
        vendeurCommissionRate: vendeurCommissionRate,
        livreurCommissionRate: livreurCommissionRate,
        paymentMethod: paymentMethod,
        status: initialStatus,
        cashCollectedAt: paymentMethod == PaymentCollectionMethod.cash ? now : null,
        platformPaidAt: paymentMethod == PaymentCollectionMethod.mobileMoney ? now : null,
        createdAt: now,
        updatedAt: now,
        metadata: {
          'orderNumber': order.orderNumber,
          'displayNumber': order.displayNumber,
          'vendeurName': order.vendeurName,
          'livreurId': delivery.livreurId,
        },
      );

      // 5. Enregistrer dans Firestore
      final docRef = await _firestore
          .collection(_transactionsCollection)
          .add(transaction.toMap());

      debugPrint('✅ Transaction créée: ${docRef.id}');
      debugPrint('   Commission vendeur: ${platformCommissionVendeur.toStringAsFixed(0)} FCFA (${(vendeurCommissionRate * 100).toStringAsFixed(0)}%)');
      debugPrint('   Commission livreur: ${platformCommissionLivreur.toStringAsFixed(0)} FCFA (${(livreurCommissionRate * 100).toStringAsFixed(0)}%)');
      debugPrint('   Total plateforme: ${totalPlatformRevenue.toStringAsFixed(0)} FCFA');
      debugPrint('   Méthode: ${paymentMethod.name}');
      debugPrint('   Statut: ${initialStatus.name}');

      if (paymentMethod == PaymentCollectionMethod.cash) {
        debugPrint('   ⚠️ CASH: Livreur doit reverser ${totalPlatformRevenue.toStringAsFixed(0)} FCFA à la plateforme');
      }

      return transaction.copyWith(id: docRef.id);
    } catch (e) {
      debugPrint('❌ Erreur création transaction: $e');
      return null;
    }
  }

  /// Marque qu'un livreur a reversé sa commission à la plateforme
  static Future<bool> markLivreurCommissionPaid({
    required String transactionId,
    required String paymentReference,
  }) async {
    try {
      debugPrint('💵 Marquage commission livreur comme payée: $transactionId');

      await _firestore
          .collection(_transactionsCollection)
          .doc(transactionId)
          .update({
        'status': CommissionPaymentStatus.paid.name,
        'platformPaidAt': Timestamp.now(),
        'livreurPaymentReference': paymentReference,
        'updatedAt': Timestamp.now(),
      });

      debugPrint('✅ Commission livreur marquée comme payée');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur marquage paiement commission: $e');
      return false;
    }
  }

  /// Marque qu'un vendeur a été payé par la plateforme
  static Future<bool> markVendeurSettled({
    required String transactionId,
    required String paymentReference,
  }) async {
    try {
      debugPrint('💸 Marquage vendeur comme réglé: $transactionId');

      await _firestore
          .collection(_transactionsCollection)
          .doc(transactionId)
          .update({
        'status': CommissionPaymentStatus.settled.name,
        'vendeurSettledAt': Timestamp.now(),
        'vendeurPaymentReference': paymentReference,
        'updatedAt': Timestamp.now(),
      });

      debugPrint('✅ Vendeur marqué comme réglé');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur marquage règlement vendeur: $e');
      return false;
    }
  }

  /// Annule une transaction (commande annulée)
  static Future<bool> cancelTransaction(String transactionId) async {
    try {
      debugPrint('❌ Annulation transaction: $transactionId');

      await _firestore
          .collection(_transactionsCollection)
          .doc(transactionId)
          .update({
        'status': CommissionPaymentStatus.cancelled.name,
        'updatedAt': Timestamp.now(),
      });

      debugPrint('✅ Transaction annulée');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur annulation transaction: $e');
      return false;
    }
  }

  /// Récupère toutes les commissions en attente de paiement par un livreur
  static Future<List<PlatformTransaction>> getPendingLivreurCommissions(String livreurId) async {
    try {
      final snapshot = await _firestore
          .collection(_transactionsCollection)
          .where('livreurId', isEqualTo: livreurId)
          .where('status', isEqualTo: CommissionPaymentStatus.pending.name)
          .where('paymentMethod', isEqualTo: PaymentCollectionMethod.cash.name)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PlatformTransaction.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('❌ Erreur récupération commissions livreur en attente: $e');
      return [];
    }
  }

  /// Calcule le montant total dû par un livreur à la plateforme
  static Future<double> getTotalLivreurDebt(String livreurId) async {
    try {
      final pendingCommissions = await getPendingLivreurCommissions(livreurId);
      return pendingCommissions.fold<double>(
        0.0,
        (total, transaction) => total + transaction.totalPlatformRevenue,
      );
    } catch (e) {
      debugPrint('❌ Erreur calcul dette livreur: $e');
      return 0.0;
    }
  }

  /// Récupère toutes les transactions en attente de règlement pour un vendeur
  static Future<List<PlatformTransaction>> getPendingVendeurSettlements(String vendeurId) async {
    try {
      final snapshot = await _firestore
          .collection(_transactionsCollection)
          .where('vendeurId', isEqualTo: vendeurId)
          .where('status', isEqualTo: CommissionPaymentStatus.paid.name)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PlatformTransaction.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('❌ Erreur récupération règlements vendeur en attente: $e');
      return [];
    }
  }

  /// Calcule le montant total à payer à un vendeur par la plateforme
  static Future<double> getTotalVendeurPendingAmount(String vendeurId) async {
    try {
      final pendingSettlements = await getPendingVendeurSettlements(vendeurId);
      return pendingSettlements.fold<double>(
        0.0,
        (total, transaction) => total + transaction.vendeurAmount,
      );
    } catch (e) {
      debugPrint('❌ Erreur calcul montant vendeur en attente: $e');
      return 0.0;
    }
  }

  /// Récupère toutes les transactions pour un ordre
  static Future<PlatformTransaction?> getTransactionByOrder(String orderId) async {
    try {
      final snapshot = await _firestore
          .collection(_transactionsCollection)
          .where('orderId', isEqualTo: orderId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return PlatformTransaction.fromFirestore(snapshot.docs.first);
    } catch (e) {
      debugPrint('❌ Erreur récupération transaction par commande: $e');
      return null;
    }
  }

  /// Statistiques globales des transactions
  static Future<Map<String, dynamic>> getGlobalTransactionStats() async {
    try {
      final snapshot = await _firestore
          .collection(_transactionsCollection)
          .get();

      final transactions = snapshot.docs
          .map((doc) => PlatformTransaction.fromFirestore(doc))
          .toList();

      double totalRevenue = 0.0;
      double totalPending = 0.0;
      double totalPaid = 0.0;
      double totalSettled = 0.0;
      int cashTransactions = 0;
      int mobileMoneyTransactions = 0;

      for (final transaction in transactions) {
        totalRevenue += transaction.totalPlatformRevenue;

        switch (transaction.status) {
          case CommissionPaymentStatus.pending:
            totalPending += transaction.totalPlatformRevenue;
            break;
          case CommissionPaymentStatus.paid:
            totalPaid += transaction.totalPlatformRevenue;
            break;
          case CommissionPaymentStatus.settled:
            totalSettled += transaction.totalPlatformRevenue;
            break;
          case CommissionPaymentStatus.cancelled:
            break;
        }

        if (transaction.paymentMethod == PaymentCollectionMethod.cash) {
          cashTransactions++;
        } else if (transaction.paymentMethod == PaymentCollectionMethod.mobileMoney) {
          mobileMoneyTransactions++;
        }
      }

      return {
        'totalRevenue': totalRevenue,
        'totalPending': totalPending,
        'totalPaid': totalPaid,
        'totalSettled': totalSettled,
        'totalTransactions': transactions.length,
        'cashTransactions': cashTransactions,
        'mobileMoneyTransactions': mobileMoneyTransactions,
      };
    } catch (e) {
      debugPrint('❌ Erreur statistiques transactions: $e');
      return {
        'totalRevenue': 0.0,
        'totalPending': 0.0,
        'totalPaid': 0.0,
        'totalSettled': 0.0,
        'totalTransactions': 0,
        'cashTransactions': 0,
        'mobileMoneyTransactions': 0,
      };
    }
  }

  /// Récupère l'historique complet des transactions pour l'admin
  static Future<List<PlatformTransaction>> getAllTransactions({
    int limit = 50,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore
          .collection(_transactionsCollection)
          .orderBy('createdAt', descending: true);

      if (startDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final snapshot = await query.limit(limit).get();

      return snapshot.docs
          .map((doc) => PlatformTransaction.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('❌ Erreur récupération toutes les transactions: $e');
      return [];
    }
  }

  /// Récupère les transactions par statut
  static Future<List<PlatformTransaction>> getTransactionsByStatus(
    CommissionPaymentStatus status, {
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_transactionsCollection)
          .where('status', isEqualTo: status.name)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => PlatformTransaction.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('❌ Erreur récupération transactions par statut: $e');
      return [];
    }
  }
}
