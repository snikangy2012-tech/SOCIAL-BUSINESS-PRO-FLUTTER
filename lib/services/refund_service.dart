// ===== lib/services/refund_service.dart =====
// Service de gestion des remboursements et retours - SOCIAL BUSINESS Pro

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../config/constants.dart';
import '../models/refund_model.dart';
import '../models/order_model.dart';
import 'firebase_service.dart';
import 'notification_service.dart';

class RefundService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Créer une demande de remboursement/retour
  static Future<String?> createRefundRequest({
    required OrderModel order,
    required String buyerId,
    required String buyerName,
    required String reason,
    required String description,
    List<String> images = const [],
  }) async {
    try {
      debugPrint('💰 Création demande de remboursement pour commande ${order.id}');

      // Vérifier que la commande est livrée ou en cours
      if (order.status != OrderStatus.livree.value &&
          order.status != OrderStatus.enCours.value) {
        debugPrint('❌ Impossible de demander un remboursement pour une commande avec statut: ${order.status}');
        return null;
      }

      // Calculer les montants
      final productAmount = order.totalAmount - order.deliveryFee;
      final deliveryFee = order.deliveryFee * 2; // Aller-retour
      final vendeurCharge = deliveryFee / 2;
      final livreurCharge = deliveryFee / 2;

      // Déterminer si prépayé
      final isPrepaid = order.paymentMethod != 'cash_on_delivery';

      // Créer le modèle de remboursement
      final refundId = _firestore.collection(FirebaseCollections.refunds).doc().id;
      final refund = RefundModel(
        id: refundId,
        orderId: order.id,
        buyerId: buyerId,
        buyerName: buyerName,
        vendeurId: order.vendeurId,
        vendeurName: order.vendeurName ?? 'Vendeur',
        livreurId: order.livreurId,
        livreurName: null, // Récupéré depuis Firestore si besoin
        reason: reason,
        description: description,
        images: images,
        productAmount: productAmount,
        deliveryFee: deliveryFee,
        vendeurDeliveryCharge: vendeurCharge,
        livreurDeliveryCharge: livreurCharge,
        paymentMethod: order.paymentMethod ?? 'cash_on_delivery',
        isPrepaid: isPrepaid,
        status: RefundStatus.demandeEnvoyee.value,
        requestedAt: DateTime.now(),
      );

      // Sauvegarder dans Firestore
      await FirebaseService.setDocument(
        collection: FirebaseCollections.refunds,
        docId: refundId,
        data: refund.toMap(),
      );

      // Mettre à jour la commande avec l'ID du remboursement
      await FirebaseService.updateDocument(
        collection: FirebaseCollections.orders,
        docId: order.id,
        data: {
          'refundId': refundId,
          'refundStatus': RefundStatus.demandeEnvoyee.value,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      // Notifier le vendeur
      final notificationService = NotificationService();
      await notificationService.createNotification(
        userId: order.vendeurId,
        title: '🔄 Nouvelle demande de retour',
        body: '$buyerName a demandé le retour de la commande #${order.id.substring(0, 8)}',
        type: 'refund_request',
        data: {
          'refundId': refundId,
          'orderId': order.id,
        },
      );

      debugPrint('✅ Demande de remboursement créée: $refundId');
      return refundId;
    } catch (e) {
      debugPrint('❌ Erreur création demande remboursement: $e');
      return null;
    }
  }

  /// Approuver une demande de remboursement (vendeur)
  static Future<bool> approveRefund({
    required String refundId,
    String? vendeurNote,
  }) async {
    try {
      debugPrint('✅ Approbation du remboursement $refundId');

      await FirebaseService.updateDocument(
        collection: FirebaseCollections.refunds,
        docId: refundId,
        data: {
          'status': RefundStatus.approuvee.value,
          'approvedAt': FieldValue.serverTimestamp(),
          'vendeurNote': vendeurNote,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      // Récupérer le remboursement pour notifier l'acheteur
      final refundDoc = await _firestore
          .collection(FirebaseCollections.refunds)
          .doc(refundId)
          .get();

      if (refundDoc.exists) {
        final refund = RefundModel.fromMap(refundDoc.data()!);

        // Mettre à jour la commande
        await FirebaseService.updateDocument(
          collection: FirebaseCollections.orders,
          docId: refund.orderId,
          data: {
            'refundStatus': RefundStatus.approuvee.value,
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );

        // Notifier l'acheteur
        final notificationService = NotificationService();
        await notificationService.createNotification(
          userId: refund.buyerId,
          title: '✅ Demande de retour approuvée',
          body: 'Votre demande de retour pour la commande #${refund.orderId.substring(0, 8)} a été approuvée',
          type: 'refund_approved',
          data: {
            'refundId': refundId,
            'orderId': refund.orderId,
          },
        );
      }

      debugPrint('✅ Remboursement approuvé');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur approbation remboursement: $e');
      return false;
    }
  }

  /// Refuser une demande de remboursement (vendeur)
  static Future<bool> refuseRefund({
    required String refundId,
    String? vendeurNote,
  }) async {
    try {
      debugPrint('❌ Refus du remboursement $refundId');

      await FirebaseService.updateDocument(
        collection: FirebaseCollections.refunds,
        docId: refundId,
        data: {
          'status': RefundStatus.refusee.value,
          'approvedAt': FieldValue.serverTimestamp(),
          'vendeurNote': vendeurNote,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      // Récupérer le remboursement pour notifier l'acheteur
      final refundDoc = await _firestore
          .collection(FirebaseCollections.refunds)
          .doc(refundId)
          .get();

      if (refundDoc.exists) {
        final refund = RefundModel.fromMap(refundDoc.data()!);

        // Mettre à jour la commande
        await FirebaseService.updateDocument(
          collection: FirebaseCollections.orders,
          docId: refund.orderId,
          data: {
            'refundStatus': RefundStatus.refusee.value,
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );

        // Notifier l'acheteur
        final notificationService = NotificationService();
        await notificationService.createNotification(
          userId: refund.buyerId,
          title: '❌ Demande de retour refusée',
          body: 'Votre demande de retour pour la commande #${refund.orderId.substring(0, 8)} a été refusée',
          type: 'refund_refused',
          data: {
            'refundId': refundId,
            'orderId': refund.orderId,
            'vendeurNote': vendeurNote,
          },
        );
      }

      debugPrint('✅ Remboursement refusé');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur refus remboursement: $e');
      return false;
    }
  }

  /// Marquer le produit comme retourné (livreur)
  static Future<bool> markProductReturned({
    required String refundId,
  }) async {
    try {
      debugPrint('📦 Marquage produit retourné: $refundId');

      await FirebaseService.updateDocument(
        collection: FirebaseCollections.refunds,
        docId: refundId,
        data: {
          'status': RefundStatus.produitRetourne.value,
          'returnedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      // Récupérer le remboursement
      final refundDoc = await _firestore
          .collection(FirebaseCollections.refunds)
          .doc(refundId)
          .get();

      if (refundDoc.exists) {
        final refund = RefundModel.fromMap(refundDoc.data()!);

        // Mettre à jour la commande
        await FirebaseService.updateDocument(
          collection: FirebaseCollections.orders,
          docId: refund.orderId,
          data: {
            'refundStatus': RefundStatus.produitRetourne.value,
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );

        // Enregistrer les frais de livraison dans l'historique des paiements
        await _recordDeliveryCharges(refund);

        // Notifier le vendeur
        final notificationService = NotificationService();
        await notificationService.createNotification(
          userId: refund.vendeurId,
          title: '📦 Produit retourné',
          body: 'Le produit de la commande #${refund.orderId.substring(0, 8)} a été retourné',
          type: 'product_returned',
          data: {
            'refundId': refundId,
            'orderId': refund.orderId,
          },
        );

        // Notifier l'acheteur
        await notificationService.createNotification(
          userId: refund.buyerId,
          title: '📦 Produit retourné',
          body: 'Le produit a été retourné au vendeur. En attente de remboursement.',
          type: 'product_returned',
          data: {
            'refundId': refundId,
            'orderId': refund.orderId,
          },
        );
      }

      debugPrint('✅ Produit marqué comme retourné');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur marquage produit retourné: $e');
      return false;
    }
  }

  /// Marquer le remboursement comme effectué (vendeur)
  static Future<bool> markRefundCompleted({
    required String refundId,
    required String refundReference,
  }) async {
    try {
      debugPrint('💰 Marquage remboursement effectué: $refundId');

      await FirebaseService.updateDocument(
        collection: FirebaseCollections.refunds,
        docId: refundId,
        data: {
          'status': RefundStatus.rembourse.value,
          'refundedAt': FieldValue.serverTimestamp(),
          'refundReference': refundReference,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      // Récupérer le remboursement
      final refundDoc = await _firestore
          .collection(FirebaseCollections.refunds)
          .doc(refundId)
          .get();

      if (refundDoc.exists) {
        final refund = RefundModel.fromMap(refundDoc.data()!);

        // Mettre à jour la commande
        await FirebaseService.updateDocument(
          collection: FirebaseCollections.orders,
          docId: refund.orderId,
          data: {
            'refundStatus': RefundStatus.rembourse.value,
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );

        // Enregistrer le remboursement dans l'historique des paiements
        await _recordRefundPayment(refund, refundReference);

        // Notifier l'acheteur
        final notificationService = NotificationService();
        await notificationService.createNotification(
          userId: refund.buyerId,
          title: '✅ Remboursement effectué',
          body: 'Vous avez été remboursé de ${refund.productAmount} FCFA',
          type: 'refund_completed',
          data: {
            'refundId': refundId,
            'orderId': refund.orderId,
            'amount': refund.productAmount.toString(),
          },
        );
      }

      debugPrint('✅ Remboursement marqué comme effectué');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur marquage remboursement effectué: $e');
      return false;
    }
  }

  /// Enregistrer les frais de livraison dans l'historique des paiements
  static Future<void> _recordDeliveryCharges(RefundModel refund) async {
    try {
      // Frais vendeur
      final vendeurPaymentId = _firestore.collection(FirebaseCollections.payments).doc().id;
      await FirebaseService.setDocument(
        collection: FirebaseCollections.payments,
        docId: vendeurPaymentId,
        data: {
          'id': vendeurPaymentId,
          'userId': refund.vendeurId,
          'type': 'refund_delivery_charge',
          'amount': -refund.vendeurDeliveryCharge,
          'orderId': refund.orderId,
          'refundId': refund.id,
          'description': 'Frais de livraison retour (part vendeur)',
          'status': 'completed',
          'createdAt': FieldValue.serverTimestamp(),
        },
      );

      // Frais livreur (si existe)
      if (refund.livreurId != null) {
        final livreurPaymentId = _firestore.collection(FirebaseCollections.payments).doc().id;
        await FirebaseService.setDocument(
          collection: FirebaseCollections.payments,
          docId: livreurPaymentId,
          data: {
            'id': livreurPaymentId,
            'userId': refund.livreurId,
            'type': 'refund_delivery_charge',
            'amount': -refund.livreurDeliveryCharge,
            'orderId': refund.orderId,
            'refundId': refund.id,
            'description': 'Frais de livraison retour (part livreur)',
            'status': 'completed',
            'createdAt': FieldValue.serverTimestamp(),
          },
        );
      }

      debugPrint('✅ Frais de livraison enregistrés dans l\'historique');
    } catch (e) {
      debugPrint('❌ Erreur enregistrement frais livraison: $e');
    }
  }

  /// Enregistrer le remboursement dans l'historique des paiements
  static Future<void> _recordRefundPayment(RefundModel refund, String reference) async {
    try {
      // Paiement acheteur (crédit)
      final buyerPaymentId = _firestore.collection(FirebaseCollections.payments).doc().id;
      await FirebaseService.setDocument(
        collection: FirebaseCollections.payments,
        docId: buyerPaymentId,
        data: {
          'id': buyerPaymentId,
          'userId': refund.buyerId,
          'type': 'refund',
          'amount': refund.productAmount,
          'orderId': refund.orderId,
          'refundId': refund.id,
          'description': 'Remboursement commande #${refund.orderId.substring(0, 8)}',
          'status': 'completed',
          'reference': reference,
          'createdAt': FieldValue.serverTimestamp(),
        },
      );

      // Paiement vendeur (débit)
      final vendeurPaymentId = _firestore.collection(FirebaseCollections.payments).doc().id;
      await FirebaseService.setDocument(
        collection: FirebaseCollections.payments,
        docId: vendeurPaymentId,
        data: {
          'id': vendeurPaymentId,
          'userId': refund.vendeurId,
          'type': 'refund',
          'amount': -refund.productAmount,
          'orderId': refund.orderId,
          'refundId': refund.id,
          'description': 'Remboursement commande #${refund.orderId.substring(0, 8)}',
          'status': 'completed',
          'reference': reference,
          'createdAt': FieldValue.serverTimestamp(),
        },
      );

      debugPrint('✅ Remboursement enregistré dans l\'historique');
    } catch (e) {
      debugPrint('❌ Erreur enregistrement remboursement: $e');
    }
  }

  /// Récupérer les demandes de remboursement pour un utilisateur
  static Stream<List<RefundModel>> getRefundsForUser({
    required String userId,
    required String userType,
  }) {
    String fieldName = userType == 'acheteur' ? 'buyerId' : 'vendeurId';

    return _firestore
        .collection(FirebaseCollections.refunds)
        .where(fieldName, isEqualTo: userId)
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => RefundModel.fromMap(doc.data())).toList();
    });
  }

  /// Récupérer un remboursement par ID
  static Future<RefundModel?> getRefundById(String refundId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseCollections.refunds)
          .doc(refundId)
          .get();

      if (doc.exists) {
        return RefundModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Erreur récupération remboursement: $e');
      return null;
    }
  }

  /// Récupérer le remboursement d'une commande
  static Future<RefundModel?> getRefundByOrderId(String orderId) async {
    try {
      final querySnapshot = await _firestore
          .collection(FirebaseCollections.refunds)
          .where('orderId', isEqualTo: orderId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return RefundModel.fromMap(querySnapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      debugPrint('❌ Erreur récupération remboursement par commande: $e');
      return null;
    }
  }
}
