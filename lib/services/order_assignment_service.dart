// ===== lib/services/order_assignment_service.dart =====
// Service d'assignation de commandes par distance - SOCIAL BUSINESS Pro

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/order_model.dart';
import '../config/constants.dart';
import 'geolocation_service.dart';
import 'delivery_service.dart';
import 'notification_service.dart';

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
        .where('status', whereIn: ['ready', 'confirmed']) // Commandes prêtes ou confirmées
        .snapshots()
        .map((snapshot) {
          final allOrders = snapshot.docs
              .map((doc) => OrderModel.fromFirestore(doc))
              .toList();

          // Filtrer pour ne garder que celles sans livreur assigné
          final orders = allOrders
              .where((order) => order.livreurId == null || order.livreurId!.isEmpty)
              .toList();

          debugPrint('📦 ${orders.length} commandes disponibles dans le stream (statuts: ready/confirmed, sans livreur)');
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

      // Vérifier que le livreur n'a pas déjà une livraison EN COURS (in_progress)
      // Note: On autorise plusieurs livraisons assignées (assigned), mais une seule en cours
      final inProgressDeliveries = await _firestore
          .collection(FirebaseCollections.deliveries)
          .where('livreurId', isEqualTo: livreurId)
          .where('status', isEqualTo: 'in_progress')
          .get();

      if (inProgressDeliveries.docs.isNotEmpty) {
        debugPrint('❌ Le livreur a déjà une livraison en cours de transport');
        throw Exception('Ce livreur a déjà une livraison en cours de transport. Il doit la terminer avant d\'en accepter une autre.');
      }

      // Vérifier le nombre de livraisons assignées (limite: 5 maximum)
      final assignedDeliveries = await _firestore
          .collection(FirebaseCollections.deliveries)
          .where('livreurId', isEqualTo: livreurId)
          .where('status', isEqualTo: 'assigned')
          .get();

      const maxAssignedDeliveries = 5;
      if (assignedDeliveries.docs.length >= maxAssignedDeliveries) {
        debugPrint('❌ Le livreur a déjà $maxAssignedDeliveries livraisons assignées');
        throw Exception('Ce livreur a atteint la limite de $maxAssignedDeliveries livraisons assignées simultanément.');
      }

      debugPrint('✅ Livreur éligible: ${assignedDeliveries.docs.length} assignées, 0 en cours');

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

      // Vérifier que le statut est "ready" ou "confirmed"
      if (order.status != 'ready' && order.status != 'confirmed') {
        debugPrint('❌ Commande pas disponible (statut: ${order.status})');
        throw Exception('Cette commande n\'est pas disponible pour la livraison');
      }

      // Assigner le livreur et changer le statut
      await _firestore
          .collection(FirebaseCollections.orders)
          .doc(orderId)
          .update({
        'livreurId': livreurId,
        'status': 'in_delivery',
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
  /// Vérifie que les commandes sont du même vendeur et dans la même zone
  static Future<Map<String, dynamic>> assignMultipleOrdersToLivreur({
    required List<String> orderIds,
    required String livreurId,
  }) async {
    try {
      debugPrint('🚚 Assignation groupée de ${orderIds.length} commandes au livreur $livreurId...');

      // Créer des listes fortement typées pour éviter les erreurs de null safety
      final successList = <String>[];
      final failedList = <Map<String, String>>[];

      // Vérifier que le livreur peut prendre ces commandes
      final inProgressCount = await _firestore
          .collection(FirebaseCollections.deliveries)
          .where('livreurId', isEqualTo: livreurId)
          .where('status', isEqualTo: 'in_progress')
          .count()
          .get();

      if (inProgressCount.count! > 0) {
        throw Exception('Le livreur a déjà une livraison en cours');
      }

      final assignedCount = await _firestore
          .collection(FirebaseCollections.deliveries)
          .where('livreurId', isEqualTo: livreurId)
          .where('status', isEqualTo: 'assigned')
          .count()
          .get();

      const maxAssignedDeliveries = 5;
      if (assignedCount.count! + orderIds.length > maxAssignedDeliveries) {
        throw Exception('Limite dépassée: maximum $maxAssignedDeliveries livraisons simultanées');
      }

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

      // Assigner les commandes valides
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
