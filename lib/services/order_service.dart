// ===== lib/services/order_service.dart (VERSION COMPLÈTE) =====
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/order_model.dart';
import '../models/audit_log_model.dart';
import 'package:social_business_pro/config/constants.dart';
import 'stock_management_service.dart';
import 'audit_service.dart';
import 'notification_service.dart';
import 'kyc_adaptive_service.dart';

class OrderService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Récupérer toutes les commandes d'un vendeur
  static Future<List<OrderModel>> getVendorOrders(String vendeurId) async {
    try {
      debugPrint('📦 Chargement commandes vendeur: $vendeurId');
      debugPrint('📦 Collection: ${FirebaseCollections.orders}');

      final querySnapshot = await _firestore
          .collection(FirebaseCollections.orders)
          .where('vendeurId', isEqualTo: vendeurId)
          .orderBy('createdAt', descending: true)
          .get()
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              debugPrint('⏱️ Timeout lors de la requête Firestore (30s)');
              throw Exception('Timeout: La requête a pris trop de temps');
            },
          );

      debugPrint('📊 Résultats Firestore: ${querySnapshot.docs.length} documents');

      if (querySnapshot.docs.isEmpty) {
        debugPrint('⚠️ Aucun document trouvé dans Firestore pour vendeurId=$vendeurId');
        debugPrint('⚠️ Vérifiez que:');
        debugPrint('   1. Des commandes existent dans la collection "${FirebaseCollections.orders}"');
        debugPrint('   2. Le champ "vendeurId" correspond exactement à "$vendeurId"');
        debugPrint('   3. L\'index Firestore est déployé');
        return [];
      }

      final orders = <OrderModel>[];
      for (var doc in querySnapshot.docs) {
        try {
          final order = OrderModel.fromFirestore(doc);
          orders.add(order);
        } catch (e) {
          debugPrint('❌ Erreur parsing commande ${doc.id}: $e');
          // Continue avec les autres commandes
        }
      }

      debugPrint('✅ ${orders.length} commandes chargées avec succès');
      if (orders.isNotEmpty) {
        debugPrint('   Premier statut: ${orders.first.status}');
        debugPrint('   Dernier statut: ${orders.last.status}');
      }
      return orders;

    } catch (e, stackTrace) {
      debugPrint('❌ Erreur chargement commandes: $e');
      debugPrint('❌ Stack trace: $stackTrace');

      // Retourner une liste vide au lieu de lancer une exception
      // pour permettre à l'UI de continuer à fonctionner
      return [];
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

  /// Compter les commandes quotidiennes d'un utilisateur (pour limites KYC)
  static Future<int> getDailyOrderCount(String userId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final querySnapshot = await _firestore
          .collection(FirebaseCollections.orders)
          .where('vendeurId', isEqualTo: userId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .get();

      return querySnapshot.docs.length;

    } catch (e) {
      debugPrint('❌ Erreur comptage commandes quotidiennes: $e');
      return 0;
    }
  }

  /// Créer une nouvelle commande avec vérification KYC automatique
  /// Vérifie les limites tier avant de créer la commande
  static Future<Map<String, dynamic>> createOrder({
    required String vendeurId,
    required String buyerId,
    required String buyerName,
    required String buyerPhone,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double deliveryFee,
    required double totalAmount,
    String deliveryMethod = 'delivery',
    String? deliveryAddress,
    double? deliveryLatitude,
    double? deliveryLongitude,
    double? pickupLatitude,
    double? pickupLongitude,
    String? paymentMethod,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      debugPrint('🛒 Création commande - Vendeur: $vendeurId, Montant: $totalAmount FCFA');

      // ✨ ÉTAPE 1: Vérification KYC adaptative (limites tier)
      final dailyOrders = await getDailyOrderCount(vendeurId);

      final permission = await KYCAdaptiveService.canPerformAction(
        userId: vendeurId,
        action: 'create_order',
        orderValue: totalAmount,
        currentDailyOrders: dailyOrders,
      );

      if (!permission.allowed) {
        debugPrint('❌ Limite KYC atteinte - ${permission.reason}');
        return {
          'success': false,
          'error': 'kyc_limit_reached',
          'message': permission.reason,
          'requiresKYC': permission.requiresKYC,
          'currentTier': permission.currentTier?.name,
          'nextTier': permission.nextTier?.name,
        };
      }

      debugPrint('✅ Vérification KYC passée - Tier: ${permission.currentTier?.name}');

      // ✨ ÉTAPE 2: Réserver le stock
      final productsQuantities = <String, int>{};
      for (final item in items) {
        productsQuantities[item['productId'] as String] = item['quantity'] as int;
      }

      final stockReserved = await StockManagementService.reserveStockBatch(
        productsQuantities: productsQuantities,
      );

      if (!stockReserved) {
        debugPrint('❌ Stock insuffisant pour certains produits');
        return {
          'success': false,
          'error': 'insufficient_stock',
          'message': 'Stock insuffisant pour un ou plusieurs produits',
        };
      }

      debugPrint('✅ Stock réservé pour ${items.length} produit(s)');

      // ✨ ÉTAPE 3: Générer le numéro de commande
      final orderNumber = 'ORD-${DateTime.now().millisecondsSinceEpoch}';

      // Compter les commandes existantes pour le displayNumber
      final allOrdersSnapshot = await _firestore
          .collection(FirebaseCollections.orders)
          .orderBy('displayNumber', descending: true)
          .limit(1)
          .get();

      final displayNumber = allOrdersSnapshot.docs.isEmpty
          ? 1
          : ((allOrdersSnapshot.docs.first.data()['displayNumber'] ?? 0) as int) + 1;

      // ✨ ÉTAPE 4: Récupérer les informations du vendeur
      String? vendeurName;
      String? vendeurShopName;
      String? vendeurPhone;
      String? vendeurLocation;

      try {
        final vendeurDoc = await _firestore
            .collection(FirebaseCollections.users)
            .doc(vendeurId)
            .get();

        if (vendeurDoc.exists) {
          final data = vendeurDoc.data();
          vendeurName = data?['displayName'];

          // Récupérer les infos de la boutique depuis le profil vendeur
          // Structure: profile.vendeurProfile.businessName (comme dans shop_setup_screen)
          final profile = data?['profile'] as Map<String, dynamic>?;
          if (profile != null) {
            // ✅ Chercher dans vendeurProfile (structure correcte)
            final vendeurProfile = profile['vendeurProfile'] as Map<String, dynamic>?;
            if (vendeurProfile != null) {
              vendeurShopName = vendeurProfile['businessName'];
              vendeurPhone = vendeurProfile['businessPhone'];
              vendeurLocation = vendeurProfile['businessAddress'];
              debugPrint('📦 Infos trouvées dans vendeurProfile: shop=$vendeurShopName, phone=$vendeurPhone');
            }

            // Fallback sur profile direct
            vendeurShopName ??= profile['businessName'] ?? profile['shopName'];
            vendeurPhone ??= profile['businessPhone'] ?? profile['phone'];
            vendeurLocation ??= profile['businessAddress'] ?? profile['address'];
          }

          // Fallback sur champs de premier niveau
          vendeurShopName ??= data?['shopName'] ?? data?['businessName'] ?? vendeurName;
          vendeurPhone ??= data?['phoneNumber'] ?? data?['phone'];
        }

        debugPrint('✅ Infos vendeur récupérées - Boutique: $vendeurShopName, Tél: $vendeurPhone, Adresse: $vendeurLocation');
      } catch (e) {
        debugPrint('⚠️ Erreur récupération infos vendeur: $e');
      }

      // ✨ ÉTAPE 5: Créer le document de commande
      final orderData = {
        'orderNumber': orderNumber,
        'displayNumber': displayNumber,
        'vendeurId': vendeurId,
        'vendeurName': vendeurName,
        'vendeurShopName': vendeurShopName,
        'vendeurPhone': vendeurPhone,
        'vendeurLocation': vendeurLocation,
        'buyerId': buyerId,
        'buyerName': buyerName,
        'buyerPhone': buyerPhone,
        'items': items,
        'subtotal': subtotal,
        'deliveryFee': deliveryFee,
        'totalAmount': totalAmount,
        'status': OrderStatus.enAttente.value,
        'deliveryMethod': deliveryMethod,
        'deliveryAddress': deliveryAddress,
        'deliveryLatitude': deliveryLatitude,
        'deliveryLongitude': deliveryLongitude,
        'pickupLatitude': pickupLatitude,
        'pickupLongitude': pickupLongitude,
        'paymentMethod': paymentMethod,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        ...?additionalData,
      };

      final docRef = await _firestore
          .collection(FirebaseCollections.orders)
          .add(orderData);

      debugPrint('✅ Commande créée: ${docRef.id}');

      // ✨ ÉTAPE 6: Logger la création
      await AuditService.log(
        userId: vendeurId,
        userType: 'vendeur',
        userEmail: '',
        userName: '',
        action: 'order_created',
        actionLabel: 'Création de commande',
        category: AuditCategory.userAction,
        severity: AuditSeverity.low,
        description: 'Commande créée - Montant: $totalAmount FCFA',
        targetType: 'order',
        targetId: docRef.id,
        targetLabel: 'Commande #$displayNumber',
        metadata: {
          'orderId': docRef.id,
          'orderNumber': orderNumber,
          'totalAmount': totalAmount,
          'itemCount': items.length,
          'tier': permission.currentTier?.name,
          'dailyOrderCount': dailyOrders + 1,
        },
      );

      // ✨ ÉTAPE 6: Vérifier si éligible à upgrade de tier
      await KYCAdaptiveService.upgradeTierIfEligible(vendeurId);

      return {
        'success': true,
        'orderId': docRef.id,
        'orderNumber': orderNumber,
        'displayNumber': displayNumber,
        'message': 'Commande créée avec succès',
      };

    } catch (e, stackTrace) {
      debugPrint('❌ Erreur création commande: $e');
      debugPrint('Stack trace: $stackTrace');

      return {
        'success': false,
        'error': 'creation_failed',
        'message': 'Erreur lors de la création de la commande: $e',
      };
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

      // Calculer les statistiques avec nouveaux statuts
      int totalOrders = allOrders.length;

      int pendingOrders = allOrders.where((order) {
        final status = order.status.toLowerCase();
        return status == 'pending' || status == 'en_attente';
      }).length;

      int deliveredOrders = allOrders.where((order) {
        final status = order.status.toLowerCase();
        return status == 'delivered' || status == 'completed' || status == 'livree';
      }).length;

      int cancelledOrders = allOrders.where((order) {
        final status = order.status.toLowerCase();
        return status == 'cancelled' || status == 'canceled' || status == 'annulee';
      }).length;

      // Calculer le revenu total (uniquement commandes livrées)
      double totalRevenue = allOrders.where((order) {
        final status = order.status.toLowerCase();
        return status == 'delivered' || status == 'completed' || status == 'livree';
      }).fold(0.0, (sum, order) => sum + order.totalAmount);

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
  static Future<void> updateOrderStatus(
    String orderId,
    String newStatus, {
    String? userId,
    String? userEmail,
    String? userName,
    String? userType,
  }) async {
    try {
      debugPrint('🔄 MAJ statut commande $orderId → $newStatus');

      // Si la commande passe en statut "livree", déduire le stock définitivement
      if (newStatus == OrderStatus.livree.value) {
        final order = await getOrderById(orderId);
        if (order != null) {
          // Déduire le stock et libérer la réservation
          final productsQuantities = <String, int>{};
          for (final item in order.items) {
            productsQuantities[item.productId] = item.quantity;
          }

          await StockManagementService.deductStockBatch(
            productsQuantities: productsQuantities,
          );
          debugPrint('✅ Stock déduit définitivement pour ${order.items.length} produit(s)');
        }
      }

      // Si la commande est annulée, libérer le stock
      if (newStatus == OrderStatus.annulee.value) {
        final order = await getOrderById(orderId);
        if (order != null) {
          final productsQuantities = <String, int>{};
          for (final item in order.items) {
            productsQuantities[item.productId] = item.quantity;
          }

          await StockManagementService.releaseStockBatch(
            productsQuantities: productsQuantities,
          );
          debugPrint('✅ Stock libéré pour ${order.items.length} produit(s)');
        }
      }

      // Récupérer les infos de la commande pour les notifications
      final orderDoc = await _firestore
          .collection(FirebaseCollections.orders)
          .doc(orderId)
          .get();

      final orderData = orderDoc.data();

      await _firestore
          .collection(FirebaseCollections.orders)
          .doc(orderId)
          .update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
        if (newStatus == OrderStatus.livree.value)
          'deliveredAt': FieldValue.serverTimestamp(),
        // ✅ CLICK & COLLECT: Marquer prêt pour retrait
        if (newStatus == 'ready' && orderData?['deliveryMethod'] == 'store_pickup')
          'pickupReadyAt': FieldValue.serverTimestamp(),
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

      // Logger le changement de statut
      if (userId != null && userEmail != null && userType != null) {
        await AuditService.log(
          userId: userId,
          userType: userType,
          userEmail: userEmail,
          userName: userName,
          action: 'order_status_updated',
          actionLabel: 'Mise à jour statut commande',
          category: AuditCategory.userAction,
          severity: AuditSeverity.low,
          description: 'Changement de statut de commande vers "$newStatus"',
          targetType: 'order',
          targetId: orderId,
          targetLabel: 'Commande #${orderId.substring(0, 8)}',
          metadata: {
            'orderId': orderId,
            'newStatus': newStatus,
            'oldStatus': 'previous', // On pourrait récupérer l'ancien statut si besoin
          },
        );
      }

      // ✅ CLICK & COLLECT: Notification quand commande prête
      if (newStatus == 'ready' && orderData?['deliveryMethod'] == 'store_pickup') {
        try {
          final buyerId = orderData?['buyerId'] as String?;
          final displayNumber = orderData?['displayNumber'] as int?;

          if (buyerId != null && displayNumber != null) {
            await NotificationService().createNotification(
              userId: buyerId,
              type: 'pickup_ready',
              title: '🎉 Votre commande est prête !',
              body: 'Commande #$displayNumber - Vous pouvez venir la récupérer en boutique',
              data: {
                'orderId': orderId,
                'displayNumber': displayNumber,
                'route': '/acheteur/pickup-qr/$orderId',
                'action': 'view_qr_code',
              },
            );
            debugPrint('✅ Notification "Commande prête" envoyée à l\'acheteur');
          }
        } catch (e) {
          debugPrint('❌ Erreur envoi notification pickup ready: $e');
          // L'erreur n'empêche pas la mise à jour du statut
        }
      }

      debugPrint('✅ Statut mis à jour avec succès');

    } catch (e) {
      debugPrint('❌ Erreur MAJ statut: $e');
      throw Exception('Impossible de mettre à jour le statut: $e');
    }
  }

  /// Annuler une commande
  static Future<void> cancelOrder(
    String orderId,
    String reason, {
    String? userId,
    String? userEmail,
    String? userName,
    String? userType,
  }) async {
    try {
      debugPrint('❌ Annulation commande $orderId - Raison: $reason');

      // Récupérer la commande pour libérer le stock
      final order = await getOrderById(orderId);
      if (order != null) {
        // Libérer le stock réservé
        final productsQuantities = <String, int>{};
        for (final item in order.items) {
          productsQuantities[item.productId] = item.quantity;
        }

        await StockManagementService.releaseStockBatch(
          productsQuantities: productsQuantities,
        );
        debugPrint('✅ Stock libéré pour ${order.items.length} produit(s)');
      }

      await _firestore
          .collection(FirebaseCollections.orders)
          .doc(orderId)
          .update({
        'status': OrderStatus.annulee.value,
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
        'status': OrderStatus.annulee.value,
        'reason': reason,
        'changedAt': FieldValue.serverTimestamp(),
      });

      // Logger l'annulation
      if (userId != null && userEmail != null && userType != null) {
        await AuditService.log(
          userId: userId,
          userType: userType,
          userEmail: userEmail,
          userName: userName,
          action: 'order_cancelled',
          actionLabel: 'Annulation de commande',
          category: AuditCategory.userAction,
          severity: AuditSeverity.medium,
          description: 'Annulation de commande - Raison: $reason',
          targetType: 'order',
          targetId: orderId,
          targetLabel: 'Commande #${orderId.substring(0, 8)}',
          metadata: {
            'orderId': orderId,
            'cancellationReason': reason,
          },
        );
      }

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