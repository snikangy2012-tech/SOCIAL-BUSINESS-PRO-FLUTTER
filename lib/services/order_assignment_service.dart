// ===== lib/services/order_assignment_service.dart =====
// Service d'assignation de commandes par distance - SOCIAL BUSINESS Pro

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/order_model.dart';
import '../models/livreur_trust_level.dart';
import '../config/constants.dart';
import 'geolocation_service.dart';
import 'delivery_service.dart';
import 'notification_service.dart';
import 'livreur_trust_service.dart';

/// Service pour assigner les commandes aux livreurs par distance
class OrderAssignmentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Récupérer les commandes disponibles (prêtes pour livraison, sans livreur assigné)
  static Future<List<OrderModel>> getAvailableOrders() async {
    try {
      debugPrint('📦 Récupération commandes disponibles...');

      final querySnapshot = await _firestore
          .collection(FirebaseCollections.orders)
          .where('status', isEqualTo: 'ready') // Commandes prêtes à être livrées
          .get();

      final allOrders = querySnapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList();

      // Filtrer pour ne garder que celles sans livreur assigné
      final orders = allOrders
          .where((order) => order.livreurId == null || order.livreurId!.isEmpty)
          .toList();

      debugPrint('✅ ${orders.length} commandes disponibles trouvées (sur ${allOrders.length} prêtes)');
      return orders;

    } catch (e) {
      debugPrint('❌ Erreur récupération commandes disponibles: $e');
      return [];
    }
  }

  /// Stream des commandes disponibles en temps réel
  static Stream<List<OrderModel>> streamAvailableOrders() {
    debugPrint('📡 Stream commandes disponibles démarré');

    return _firestore
        .collection(FirebaseCollections.orders)
        .where('status', isEqualTo: 'ready') // ✅ SEULEMENT les commandes ready (préparées)
        .snapshots()
        .map((snapshot) {
          final allOrders = snapshot.docs
              .map((doc) => OrderModel.fromFirestore(doc))
              .toList();

          // Filtrer pour ne garder que celles sans livreur assigné
          final orders = allOrders
              .where((order) => order.livreurId == null || order.livreurId!.isEmpty)
              .toList();

          debugPrint('📦 ${orders.length} commandes disponibles dans le stream (statut: ready, sans livreur)');
          return orders;
        });
  }

  /// Récupérer les commandes triées par distance (les plus proches en premier)
  static Future<List<OrderWithDistance>> getOrdersSortedByDistance({
    required Position livreurPosition,
    double? maxDistanceKm,
  }) async {
    try {
      debugPrint('🎯 Tri commandes par distance...');
      debugPrint('📍 Position livreur: ${livreurPosition.latitude}, ${livreurPosition.longitude}');

      // Récupérer toutes les commandes disponibles
      final orders = await getAvailableOrders();

      if (orders.isEmpty) {
        debugPrint('⚠️ Aucune commande disponible');
        return [];
      }

      // Calculer la distance pour chaque commande
      final ordersWithDistance = <OrderWithDistance>[];

      for (var order in orders) {
        // Vérifier si la commande a des coordonnées de pickup
        if (order.pickupLatitude == null || order.pickupLongitude == null) {
          debugPrint('⚠️ Commande ${order.orderNumber} sans coordonnées GPS');
          continue;
        }

        // Calculer la distance
        final distance = GeolocationService.calculateDistance(
          livreurPosition.latitude,
          livreurPosition.longitude,
          order.pickupLatitude!,
          order.pickupLongitude!,
        );

        // Filtrer par distance maximale si spécifiée
        if (maxDistanceKm != null && distance > maxDistanceKm) {
          debugPrint('⏭️ Commande ${order.orderNumber} trop loin: ${distance.toStringAsFixed(1)} km');
          continue;
        }

        ordersWithDistance.add(OrderWithDistance(
          order: order,
          distanceKm: distance,
          estimatedTimeMinutes: GeolocationService.estimateTravelTime(distance),
        ));
      }

      // Trier par distance (les plus proches en premier)
      ordersWithDistance.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

      debugPrint('✅ ${ordersWithDistance.length} commandes triées par distance');

      // Afficher les 3 plus proches
      if (ordersWithDistance.isNotEmpty) {
        debugPrint('📊 Top 3 commandes les plus proches:');
        for (var i = 0; i < ordersWithDistance.length && i < 3; i++) {
          final item = ordersWithDistance[i];
          debugPrint('   ${i + 1}. ${item.order.orderNumber} - ${item.distanceKm.toStringAsFixed(1)} km (${item.estimatedTimeMinutes} min)');
        }
      }

      return ordersWithDistance;

    } catch (e) {
      debugPrint('❌ Erreur tri commandes par distance: $e');
      return [];
    }
  }

  /// Stream des commandes triées par distance en temps réel
  static Stream<List<OrderWithDistance>> streamOrdersSortedByDistance({
    required Position livreurPosition,
    double? maxDistanceKm,
  }) async* {
    debugPrint('📡 Stream commandes triées par distance démarré');

    await for (var orders in streamAvailableOrders()) {
      final ordersWithDistance = <OrderWithDistance>[];
      int skippedNoGPS = 0;
      int skippedTooFar = 0;

      for (var order in orders) {
        // Vérifier si la commande a des coordonnées de pickup
        if (order.pickupLatitude == null || order.pickupLongitude == null) {
          debugPrint('⚠️ Commande ${order.orderNumber} (${order.status}) sans GPS - IGNORÉE');
          skippedNoGPS++;
          continue;
        }

        // Calculer la distance
        final distance = GeolocationService.calculateDistance(
          livreurPosition.latitude,
          livreurPosition.longitude,
          order.pickupLatitude!,
          order.pickupLongitude!,
        );

        // Filtrer par distance maximale si spécifiée
        if (maxDistanceKm != null && distance > maxDistanceKm) {
          debugPrint('⏭️ Commande ${order.orderNumber} trop loin: ${distance.toStringAsFixed(1)} km');
          skippedTooFar++;
          continue;
        }

        ordersWithDistance.add(OrderWithDistance(
          order: order,
          distanceKm: distance,
          estimatedTimeMinutes: GeolocationService.estimateTravelTime(distance),
        ));
      }

      // Trier par distance
      ordersWithDistance.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

      debugPrint('📊 Stream: ${ordersWithDistance.length} commandes affichées, $skippedNoGPS sans GPS, $skippedTooFar trop loin');

      yield ordersWithDistance;
    }
  }

  /// Assigner une commande à un livreur
  static Future<bool> assignOrderToLivreur({
    required String orderId,
    required String livreurId,
  }) async {
    try {
      debugPrint('🚚 Assignation commande $orderId au livreur $livreurId...');

      // ✅ SYSTÈME DE CONFIANCE: Récupérer la configuration du livreur
      // La limite de livraisons simultanées dépend du niveau de confiance:
      // - Débutant: 1 livraison (strict)
      // - Confirmé: 2 livraisons
      // - Expert: 3 livraisons
      // - VIP: 5 livraisons
      final trustConfig = await LivreurTrustService.getLivreurTrustConfig(livreurId);
      final maxActiveDeliveries = trustConfig.maxActiveDeliveries;

      debugPrint('📊 Niveau de confiance: ${trustConfig.displayName} ${trustConfig.badgeIcon}');
      debugPrint('   Limite de livraisons simultanées: $maxActiveDeliveries');

      // Récupérer toutes les livraisons du livreur
      final allDeliveries = await _firestore
          .collection(FirebaseCollections.deliveries)
          .where('livreurId', isEqualTo: livreurId)
          .get();

      // Filtrer les livraisons actives (assigned, picked_up, in_transit)
      final activeStatuses = ['assigned', 'picked_up', 'in_transit'];
      final activeDeliveries = allDeliveries.docs
          .where((doc) => activeStatuses.contains(doc.data()['status']))
          .toList();

      final activeCount = activeDeliveries.length;

      // ✅ Vérifier si le livreur peut accepter plus de livraisons
      if (!trustConfig.canAcceptMoreDeliveries(activeCount)) {
        debugPrint('❌ Le livreur a atteint sa limite: $activeCount/$maxActiveDeliveries livraison(s) active(s)');

        // Construire le message d'erreur détaillé
        final statusMessages = <String>[];
        for (final delivery in activeDeliveries) {
          final data = delivery.data();
          final status = data['status'];
          String statusLabel;
          switch (status) {
            case 'assigned':
              statusLabel = 'assignée';
              break;
            case 'picked_up':
              statusLabel = 'récupérée';
              break;
            case 'in_transit':
              statusLabel = 'en livraison';
              break;
            default:
              statusLabel = status;
          }
          statusMessages.add('• 1 livraison $statusLabel');
        }

        final remainingSlots = trustConfig.getRemainingDeliverySlots(activeCount);
        throw Exception(
          'Vous avez atteint votre limite de $maxActiveDeliveries livraison(s) simultanée(s).\n'
          'Niveau: ${trustConfig.displayName} ${trustConfig.badgeIcon}\n\n'
          'Livraisons en cours:\n${statusMessages.join('\n')}\n\n'
          'Terminez une livraison pour en accepter une nouvelle.'
          '${trustConfig.level != LivreurTrustLevel.vip ? '\n\n💡 Astuce: Montez de niveau pour augmenter cette limite!' : ''}'
        );
      }

      final remainingSlots = trustConfig.getRemainingDeliverySlots(activeCount);
      debugPrint('✅ Livreur éligible: $activeCount/$maxActiveDeliveries livraisons actives ($remainingSlots places restantes)');

      // Vérifier que la commande est toujours disponible
      final orderDoc = await _firestore
          .collection(FirebaseCollections.orders)
          .doc(orderId)
          .get();

      if (!orderDoc.exists) {
        debugPrint('❌ Commande introuvable');
        throw Exception('Commande introuvable');
      }

      final order = OrderModel.fromFirestore(orderDoc);

      // Vérifier que la commande n'a pas déjà été assignée
      if (order.livreurId != null && order.livreurId!.isNotEmpty) {
        debugPrint('❌ Commande déjà assignée au livreur ${order.livreurId}');
        throw Exception('Cette commande a déjà été assignée à un autre livreur');
      }

      // ✅ SÉCURITÉ CRITIQUE: N'autoriser QUE le statut "ready"
      // Le vendeur DOIT avoir confirmé ET préparé avant qu'un livreur puisse accepter
      // Workflow: pending → confirmed → preparing → ready → en_cours
      if (order.status != 'ready') {
        debugPrint('❌ Commande pas prête (statut: ${order.status})');
        debugPrint('   Le vendeur doit marquer la commande comme "ready" après préparation');
        throw Exception('Cette commande n\'est pas encore prête pour la livraison.\nLe vendeur doit la préparer.');
      }

      // Récupérer les infos du livreur
      final livreurDoc = await _firestore
          .collection(FirebaseCollections.users)
          .doc(livreurId)
          .get();

      String? livreurName;
      String? livreurPhone;

      if (livreurDoc.exists) {
        final livreurData = livreurDoc.data();
        livreurName = livreurData?['displayName'] ?? livreurData?['username'];
        livreurPhone = livreurData?['phone'];
      }

      // Assigner le livreur et changer le statut à 'en_cours'
      await _firestore
          .collection(FirebaseCollections.orders)
          .doc(orderId)
          .update({
        'livreurId': livreurId,
        'livreurName': livreurName,
        'livreurPhone': livreurPhone,
        'status': 'en_cours', // ✅ CORRIGÉ: utilise 'en_cours' au lieu de 'in_delivery'
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Commande assignée avec succès');

      // Créer un document de livraison dans la collection deliveries
      try {
        final delivery = await DeliveryService.createDeliveryFromOrder(
          orderId: orderId,
          livreurId: livreurId,
        );
        debugPrint('✅ Document de livraison créé: ${delivery.id}');
      } catch (e) {
        debugPrint('⚠️ Erreur création document de livraison: $e');
        // Ne pas bloquer l'assignation si la création du delivery échoue
      }

      // Envoyer notifications au vendeur et au client
      try {
        final notificationService = NotificationService();

        // Notification au vendeur
        await notificationService.createNotification(
          userId: order.vendeurId,
          type: 'order_picked_up',
          title: 'Commande prise en charge',
          body: 'Un livreur a accepté votre commande ${order.orderNumber}',
          data: {
            'orderId': orderId,
            'orderNumber': order.orderNumber,
            'livreurId': livreurId,
          },
        );

        // Notification au client
        await notificationService.createNotification(
          userId: order.buyerId,
          type: 'order_in_delivery',
          title: 'Commande en cours de livraison',
          body: 'Votre commande ${order.orderNumber} est en route !',
          data: {
            'orderId': orderId,
            'orderNumber': order.orderNumber,
          },
        );

        debugPrint('✅ Notifications envoyées au vendeur et au client');
      } catch (e) {
        debugPrint('⚠️ Erreur envoi notifications: $e');
        // Ne pas bloquer l'assignation si les notifications échouent
      }

      return true;

    } catch (e) {
      debugPrint('❌ Erreur assignation commande: $e');
      throw Exception('Impossible d\'accepter cette commande: $e');
    }
  }

  /// Rechercher les livreurs disponibles dans un rayon donné
  static Future<List<String>> findAvailableLivreursInRadius({
    required double centerLatitude,
    required double centerLongitude,
    double radiusKm = 10.0,
  }) async {
    try {
      debugPrint('🔍 Recherche livreurs dans un rayon de $radiusKm km...');

      // Récupérer tous les livreurs
      final querySnapshot = await _firestore
          .collection(FirebaseCollections.users)
          .where('userType', isEqualTo: 'livreur')
          .where('isAvailable', isEqualTo: true) // Uniquement les livreurs disponibles
          .get();

      final availableLivreurs = <String>[];

      for (var doc in querySnapshot.docs) {
        final data = doc.data();

        // Vérifier si le livreur a des coordonnées GPS
        if (data['currentLatitude'] == null || data['currentLongitude'] == null) {
          continue;
        }

        final livreurLat = (data['currentLatitude'] as num).toDouble();
        final livreurLng = (data['currentLongitude'] as num).toDouble();

        // Vérifier si le livreur est dans le rayon
        final isWithin = GeolocationService.isWithinRadius(
          centerLatitude,
          centerLongitude,
          livreurLat,
          livreurLng,
          radiusKm,
        );

        if (isWithin) {
          availableLivreurs.add(doc.id);
        }
      }

      debugPrint('✅ ${availableLivreurs.length} livreurs trouvés dans le rayon');
      return availableLivreurs;

    } catch (e) {
      debugPrint('❌ Erreur recherche livreurs: $e');
      return [];
    }
  }

  /// Mettre à jour la position actuelle d'un livreur
  static Future<void> updateLivreurPosition({
    required String livreurId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await _firestore
          .collection(FirebaseCollections.users)
          .doc(livreurId)
          .update({
        'currentLatitude': latitude,
        'currentLongitude': longitude,
        'lastPositionUpdate': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Position livreur mise à jour: $latitude, $longitude');

    } catch (e) {
      debugPrint('❌ Erreur mise à jour position: $e');
    }
  }

  /// Mettre à jour le statut de disponibilité d'un livreur
  static Future<void> updateLivreurAvailability({
    required String livreurId,
    required bool isAvailable,
  }) async {
    try {
      await _firestore
          .collection(FirebaseCollections.users)
          .doc(livreurId)
          .update({
        'isAvailable': isAvailable,
        'availabilityUpdatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Disponibilité livreur mise à jour: $isAvailable');

    } catch (e) {
      debugPrint('❌ Erreur mise à jour disponibilité: $e');
    }
  }

  /// Assigner plusieurs commandes du même vendeur à un livreur
  /// ✅ La limite dépend du niveau de confiance du livreur:
  /// - Débutant: 1 livraison, Confirmé: 2, Expert: 3, VIP: 5
  static Future<Map<String, dynamic>> assignMultipleOrdersToLivreur({
    required List<String> orderIds,
    required String livreurId,
  }) async {
    try {
      debugPrint('🚚 Assignation groupée de ${orderIds.length} commandes au livreur $livreurId...');

      // Créer des listes fortement typées pour éviter les erreurs de null safety
      final successList = <String>[];
      final failedList = <Map<String, String>>[];

      // ✅ SYSTÈME DE CONFIANCE: Récupérer la configuration du livreur
      final trustConfig = await LivreurTrustService.getLivreurTrustConfig(livreurId);
      final maxActiveDeliveries = trustConfig.maxActiveDeliveries;

      debugPrint('📊 Niveau de confiance: ${trustConfig.displayName} ${trustConfig.badgeIcon}');
      debugPrint('   Limite de livraisons simultanées: $maxActiveDeliveries');

      // Récupérer toutes les livraisons actives du livreur
      final allDeliveries = await _firestore
          .collection(FirebaseCollections.deliveries)
          .where('livreurId', isEqualTo: livreurId)
          .get();

      final activeStatuses = ['assigned', 'picked_up', 'in_transit'];
      final activeCount = allDeliveries.docs
          .where((doc) => activeStatuses.contains(doc.data()['status']))
          .length;

      // ✅ Vérifier si le livreur peut accepter plus de livraisons
      if (!trustConfig.canAcceptMoreDeliveries(activeCount)) {
        throw Exception(
          'Vous avez atteint votre limite de $maxActiveDeliveries livraison(s) simultanée(s).\n'
          'Niveau: ${trustConfig.displayName} ${trustConfig.badgeIcon}\n'
          'Terminez vos livraisons en cours avant d\'en accepter de nouvelles.'
        );
      }

      // Calculer combien de nouvelles livraisons peuvent être acceptées
      final availableSlots = trustConfig.getRemainingDeliverySlots(activeCount);
      debugPrint('📦 Places disponibles: $availableSlots (actuelles: $activeCount, max: $maxActiveDeliveries)');

      // Récupérer toutes les commandes pour validation
      final orders = await Future.wait(
        orderIds.map((id) => _firestore.collection(FirebaseCollections.orders).doc(id).get())
      );

      // Vérifier que toutes les commandes sont du même vendeur
      String? vendeurId;
      final orderModels = <OrderModel>[];

      for (var i = 0; i < orders.length; i++) {
        if (!orders[i].exists) {
          failedList.add({'orderId': orderIds[i], 'reason': 'Commande introuvable'});
          continue;
        }

        final order = OrderModel.fromFirestore(orders[i]);
        orderModels.add(order);

        if (vendeurId == null) {
          vendeurId = order.vendeurId;
        } else if (order.vendeurId != vendeurId) {
          failedList.add({
            'orderId': orderIds[i],
            'reason': 'Commande d\'un vendeur différent'
          });
          continue;
        }

        if (order.livreurId != null && order.livreurId!.isNotEmpty) {
          failedList.add({
            'orderId': orderIds[i],
            'reason': 'Déjà assignée'
          });
          continue;
        }

        if (order.status != 'ready' && order.status != 'confirmed') {
          failedList.add({
            'orderId': orderIds[i],
            'reason': 'Statut invalide: ${order.status}'
          });
          continue;
        }
      }

      // Vérifier la proximité géographique des points de livraison (rayon max: 3 km)
      if (orderModels.length > 1) {
        final firstOrder = orderModels.first;
        if (firstOrder.deliveryLatitude != null && firstOrder.deliveryLongitude != null) {
          for (var i = 1; i < orderModels.length; i++) {
            final order = orderModels[i];
            if (order.deliveryLatitude != null && order.deliveryLongitude != null) {
              final distance = GeolocationService.calculateDistance(
                firstOrder.deliveryLatitude!,
                firstOrder.deliveryLongitude!,
                order.deliveryLatitude!,
                order.deliveryLongitude!,
              );

              if (distance > 3.0) {
                debugPrint('⚠️ Commande ${order.id} trop éloignée: ${distance.toStringAsFixed(1)} km');
                failedList.add({
                  'orderId': order.id,
                  'reason': 'Trop éloignée (${distance.toStringAsFixed(1)} km)'
                });
                orderModels.removeAt(i);
                i--;
              }
            }
          }
        }
      }

      // ✅ Limiter le nombre de commandes à assigner selon les places disponibles
      if (orderModels.length > availableSlots) {
        debugPrint('⚠️ Limitation: ${orderModels.length} commandes demandées mais seulement $availableSlots places disponibles');
        // Marquer les commandes excédentaires comme échouées
        for (var i = availableSlots; i < orderModels.length; i++) {
          failedList.add({
            'orderId': orderModels[i].id,
            'reason': 'Limite de livraisons atteinte (${trustConfig.displayName}: max $maxActiveDeliveries)'
          });
        }
        // Ne garder que les commandes qu'on peut assigner
        orderModels.removeRange(availableSlots, orderModels.length);
      }

      // Assigner les commandes valides (dans la limite des places disponibles)
      for (final order in orderModels) {
        try {
          await assignOrderToLivreur(
            orderId: order.id,
            livreurId: livreurId,
          );
          successList.add(order.id);
        } catch (e) {
          failedList.add({
            'orderId': order.id,
            'reason': e.toString()
          });
        }
      }

      debugPrint('✅ Assignation groupée terminée: ${successList.length} succès, ${failedList.length} échecs');
      debugPrint('   Niveau: ${trustConfig.displayName}, Places utilisées: ${successList.length}/$availableSlots');

      // Retourner les résultats
      return {
        'success': successList,
        'failed': failedList,
        'total': orderIds.length,
      };

    } catch (e) {
      debugPrint('❌ Erreur assignation groupée: $e');
      rethrow;
    }
  }
}

/// Classe pour représenter une commande avec sa distance
class OrderWithDistance {
  final OrderModel order;
  final double distanceKm;
  final int estimatedTimeMinutes;

  OrderWithDistance({
    required this.order,
    required this.distanceKm,
    required this.estimatedTimeMinutes,
  });

  /// Formatter la distance pour affichage
  String get formattedDistance => GeolocationService.formatDistance(distanceKm);

  /// Obtenir le temps estimé formaté
  String get formattedTime {
    if (estimatedTimeMinutes < 60) {
      return '$estimatedTimeMinutes min';
    } else {
      final hours = estimatedTimeMinutes ~/ 60;
      final minutes = estimatedTimeMinutes % 60;
      return '${hours}h ${minutes}min';
    }
  }

  /// Déterminer si la commande est proche (< 5 km)
  bool get isNearby => distanceKm < 5.0;

  /// Déterminer si la commande est loin (> 15 km)
  bool get isFar => distanceKm > 15.0;

  @override
  String toString() {
    return 'OrderWithDistance(${order.orderNumber}, $formattedDistance, $formattedTime)';
  }
}
