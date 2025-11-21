// ===== lib/services/delivery_service.dart =====
// Service de gestion des livraisons - SOCIAL BUSINESS Pro
// Migré depuis src/services/delivery.service.ts

import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'package:social_business_pro/config/constants.dart';
import '../models/delivery_model.dart';
import 'kyc_verification_service.dart';


/// Service de gestion des livraisons
class DeliveryService {
  static final DeliveryService _instance = DeliveryService._internal();
  factory DeliveryService() => _instance;
  DeliveryService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ===== GESTION DES LIVRAISONS =====

  /// Créer une nouvelle livraison
  Future<DeliveryModel> createDelivery({
    required String orderId,
    required String vendeurId,
    required String acheteurId,
    required Map<String, dynamic> pickupAddress,
    required Map<String, dynamic> deliveryAddress,
    required String packageDescription,
    required double packageValue,
    bool isFragile = false,
  }) async {
    try {
      final deliveryRef = _db.collection(FirebaseCollections.deliveries).doc();
      
      // Calculer la distance et les frais
      final distance = _calculateDistance(
        pickupAddress['coordinates'],
        deliveryAddress['coordinates'],
      );
      
      final deliveryFee = _calculateDeliveryFee(distance);
      final estimatedDuration = _estimateDeliveryDuration(distance);

      final delivery = DeliveryModel(
        id: deliveryRef.id,
        orderId: orderId,
        vendeurId: vendeurId,
        acheteurId: acheteurId,
        pickupAddress: pickupAddress,
        deliveryAddress: deliveryAddress,
        distance: distance,
        deliveryFee: deliveryFee,
        estimatedDuration: estimatedDuration,
        packageDescription: packageDescription,
        packageValue: packageValue,
        isFragile: isFragile,
        status: 'available',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await deliveryRef.set(delivery.toMap());
      return delivery;
    } catch (e) {
      throw Exception('Erreur création livraison: $e');
    }
  }

  /// Récupérer une livraison par ID
  Future<DeliveryModel?> getDelivery(String deliveryId) async {
    try {
      final doc = await _db
          .collection(FirebaseCollections.deliveries)
          .doc(deliveryId)
          .get();

      if (!doc.exists) return null;
      return DeliveryModel.fromMap(doc.data()!);
    } catch (e) {
      throw Exception('Erreur récupération livraison: $e');
    }
  }

  /// Récupérer une livraison par numéro de commande
  static Future<DeliveryModel?> getDeliveryByOrderId(String orderId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(FirebaseCollections.deliveries)
          .where('orderId', isEqualTo: orderId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return DeliveryModel.fromMap(snapshot.docs.first.data());
    } catch (e) {
      throw Exception('Erreur récupération livraison par orderId: $e');
    }
  }

  /// Créer un document de livraison depuis une commande acceptée
  static Future<DeliveryModel> createDeliveryFromOrder({
    required String orderId,
    required String livreurId,
  }) async {
    try {
      // 🔐 VÉRIFICATION KYC: Le livreur doit être vérifié pour accepter des livraisons
      final canDeliver = await KYCVerificationService.canPerformAction(
        livreurId,
        'deliver',
      );

      if (!canDeliver) {
        debugPrint('❌ Livreur $livreurId non vérifié - acceptation livraison bloquée');
        throw Exception(
          'Votre compte doit être vérifié avant d\'accepter des livraisons. '
          'Complétez vos documents dans "Profil > Gestion des documents".',
        );
      }

      final db = FirebaseFirestore.instance;

      // Récupérer les détails de la commande
      final orderDoc = await db
          .collection(FirebaseCollections.orders)
          .doc(orderId)
          .get();

      if (!orderDoc.exists) {
        throw Exception('Commande introuvable');
      }

      final orderData = orderDoc.data()!;

      // Créer le document de livraison
      final deliveryRef = db.collection(FirebaseCollections.deliveries).doc();

      // Extraire les coordonnées depuis la commande
      final pickupAddress = {
        'street': orderData['deliveryAddress'] ?? '',
        'coordinates': {
          'latitude': orderData['pickupLatitude'] ?? 0.0,
          'longitude': orderData['pickupLongitude'] ?? 0.0,
        },
      };

      final deliveryAddress = {
        'street': orderData['deliveryAddress'] ?? '',
        'coordinates': {
          'latitude': orderData['deliveryLatitude'] ?? 0.0,
          'longitude': orderData['deliveryLongitude'] ?? 0.0,
        },
      };

      // Calculer la distance
      double distance = 0.0;
      if (orderData['pickupLatitude'] != null && orderData['deliveryLatitude'] != null) {
        final pickupCoords = pickupAddress['coordinates'] as Map<String, dynamic>;
        final deliveryCoords = deliveryAddress['coordinates'] as Map<String, dynamic>;

        distance = DeliveryService()._calculateDistance(
          pickupCoords,
          deliveryCoords,
        );
      }

      // Calculer les frais et la durée
      final deliveryFee = DeliveryService()._calculateDeliveryFee(distance);
      final estimatedDuration = DeliveryService()._estimateDeliveryDuration(distance);

      final delivery = DeliveryModel(
        id: deliveryRef.id,
        orderId: orderId,
        vendeurId: orderData['vendeurId'] ?? '',
        acheteurId: orderData['buyerId'] ?? '',
        livreurId: livreurId,
        pickupAddress: pickupAddress,
        deliveryAddress: deliveryAddress,
        distance: distance,
        deliveryFee: deliveryFee,
        estimatedDuration: estimatedDuration,
        packageDescription: '${(orderData['items'] as List).length} article(s)',
        packageValue: (orderData['totalAmount'] ?? 0).toDouble(),
        isFragile: false,
        status: 'assigned',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        assignedAt: DateTime.now(),
      );

      await deliveryRef.set(delivery.toMap());

      debugPrint('✅ Document de livraison créé: ${delivery.id}');
      return delivery;
    } catch (e) {
      debugPrint('❌ Erreur création livraison depuis commande: $e');
      throw Exception('Impossible de créer la livraison: $e');
    }
  }

  /// Récupérer les livraisons d'un livreur
  Future<List<DeliveryModel>> getLivreurDeliveries({
    required String livreurId,
    String? status,
    int limit = 50,
  }) async {
    try {
      Query query = _db
          .collection(FirebaseCollections.deliveries)
          .where('livreurId', isEqualTo: livreurId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => DeliveryModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Erreur récupération livraisons livreur: $e');
    }
  }

  /// Récupérer les livraisons disponibles
  Future<List<Map<String, dynamic>>> getAvailableDeliveries({
    required Map<String, dynamic> livreurLocation,
    double maxDistance = 10.0, // km
  }) async {
    try {
      final snapshot = await _db
          .collection(FirebaseCollections.deliveries)
          .where('status', isEqualTo: 'available')
          .orderBy('createdAt', descending: false)
          .limit(20)
          .get();

      final availableDeliveries = <Map<String, dynamic>>[];

      for (var doc in snapshot.docs) {
        final delivery = DeliveryModel.fromMap(doc.data());
        
        // Vérifier la distance
        if (delivery.pickupAddress['coordinates'] != null) {
          final distance = _calculateDistance(
            livreurLocation,
            delivery.pickupAddress['coordinates'],
          );

          if (distance <= maxDistance) {
            availableDeliveries.add({
              'id': delivery.id,
              'orderId': delivery.orderId,
              'pickupAddress': delivery.pickupAddress,
              'deliveryAddress': delivery.deliveryAddress,
              'distance': distance,
              'deliveryFee': delivery.deliveryFee,
              'estimatedDuration': delivery.estimatedDuration,
              'packageDescription': delivery.packageDescription,
              'isFragile': delivery.isFragile,
              'packageValue': delivery.packageValue,
              'createdAt': delivery.createdAt,
            });
          }
        }
      }

      // Trier par distance
      availableDeliveries.sort((a, b) => 
        (a['distance'] as double).compareTo(b['distance'] as double)
      );

      return availableDeliveries;
    } catch (e) {
      throw Exception('Erreur récupération livraisons disponibles: $e');
    }
  }

  /// Assigner une livraison à un livreur
  Future<void> assignDelivery({
    required String deliveryId,
    required String livreurId,
    required DateTime estimatedPickup,
    required DateTime estimatedDelivery,
  }) async {
    try {
      await _db.runTransaction((transaction) async {
        final deliveryRef = _db
            .collection(FirebaseCollections.deliveries)
            .doc(deliveryId);
        
        final deliveryDoc = await transaction.get(deliveryRef);

        if (!deliveryDoc.exists) {
          throw Exception('Livraison introuvable');
        }

        final delivery = DeliveryModel.fromMap(deliveryDoc.data()!);

        if (delivery.status != 'available') {
          throw Exception('Cette livraison n\'est plus disponible');
        }

        // Mettre à jour la livraison
        transaction.update(deliveryRef, {
          'livreurId': livreurId,
          'status': 'assigned',
          'estimatedPickup': Timestamp.fromDate(estimatedPickup),
          'estimatedDelivery': Timestamp.fromDate(estimatedDelivery),
          'assignedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Mettre à jour la commande
        final orderRef = _db
            .collection(FirebaseCollections.orders)
            .doc(delivery.orderId);
        
        transaction.update(orderRef, {
          'livreurId': livreurId,
          'status': 'preparing',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      throw Exception('Erreur assignation livraison: $e');
    }
  }

  /// Mettre à jour le statut d'une livraison
  Future<void> updateDeliveryStatus({
    required String deliveryId,
    required String status,
    Map<String, dynamic>? currentLocation,
    String? notes,
    List<String>? proofOfDelivery,
  }) async {
    try {
      final updates = <String, dynamic>{
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (currentLocation != null) {
        updates['currentLocation'] = currentLocation;
        updates['lastLocationUpdate'] = FieldValue.serverTimestamp();
      }

      if (notes != null) {
        updates['notes'] = notes;
      }

      if (proofOfDelivery != null) {
        updates['proofOfDelivery'] = proofOfDelivery;
      }

      // Timestamps selon le statut
      switch (status) {
        case 'picked_up':
          updates['pickedUpAt'] = FieldValue.serverTimestamp();
          break;
        case 'in_transit':
          updates['inTransitAt'] = FieldValue.serverTimestamp();
          break;
        case 'delivered':
          updates['deliveredAt'] = FieldValue.serverTimestamp();
          updates['completedAt'] = FieldValue.serverTimestamp();
          break;
        case 'cancelled':
          updates['cancelledAt'] = FieldValue.serverTimestamp();
          break;
      }

      await _db
          .collection(FirebaseCollections.deliveries)
          .doc(deliveryId)
          .update(updates);

      // Mettre à jour la commande associée
      final delivery = await getDelivery(deliveryId);
      if (delivery != null) {
        final orderStatus = _mapDeliveryStatusToOrderStatus(status);
        await _db
            .collection(FirebaseCollections.orders)
            .doc(delivery.orderId)
            .update({
          'status': orderStatus,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw Exception('Erreur mise à jour statut: $e');
    }
  }

  /// Suivre la position en temps réel
  Stream<DeliveryModel> trackDelivery(String deliveryId) {
    return _db
        .collection(FirebaseCollections.deliveries)
        .doc(deliveryId)
        .snapshots()
        .map((doc) => DeliveryModel.fromMap(doc.data()!));
  }

  // ===== GÉOLOCALISATION =====

  /// Obtenir la position actuelle
  Future<Position> getCurrentPosition() async {
    try {
      // Vérifier les permissions
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final newPermission = await Geolocator.requestPermission();
        if (newPermission == LocationPermission.denied) {
          throw Exception('Permission de localisation refusée');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permission de localisation refusée définitivement');
      }

      // Obtenir la position
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      throw Exception('Erreur récupération position: $e');
    }
  }

  /// Suivre la position en temps réel
  Stream<Position> watchPosition() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Mettre à jour tous les 10 mètres
      ),
    );
  }

  /// Mettre à jour la position du livreur
  Future<void> updateLivreurLocation({
    required String deliveryId,
    required Position position,
  }) async {
    try {
      await _db
          .collection(FirebaseCollections.deliveries)
          .doc(deliveryId)
          .update({
        'currentLocation': {
          'latitude': position.latitude,
          'longitude': position.longitude,
        },
        'lastLocationUpdate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erreur mise à jour position: $e');
    }
  }

  // ===== CALCULS =====

  /// Calculer la distance entre deux points (en km)
  double _calculateDistance(
    Map<String, dynamic> point1,
    Map<String, dynamic> point2,
  ) {
    const earthRadius = 6371; // Rayon de la Terre en km

    final lat1 = point1['latitude'] * pi / 180;
    final lat2 = point2['latitude'] * pi / 180;
    final dLat = (point2['latitude'] - point1['latitude']) * pi / 180;
    final dLon = (point2['longitude'] - point1['longitude']) * pi / 180;

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  /// Calculer les frais de livraison
  double _calculateDeliveryFee(double distance) {
    // Tarifs par distance (paliers révisés)
    if (distance <= 10) return 1000;  // 1000 FCFA pour 0-10km
    if (distance <= 20) return 1500;  // 1500 FCFA pour 10-20km
    if (distance <= 30) return 2000;  // 2000 FCFA pour 20-30km
    return 2000 + ((distance - 30) * 100); // 2000 FCFA + 100 FCFA/km au-delà de 30km
  }

  /// Estimer la durée de livraison (en minutes)
  int _estimateDeliveryDuration(double distance) {
    const avgSpeed = 25.0; // Vitesse moyenne en km/h (moto)
    final travelTime = (distance / avgSpeed) * 60; // Temps de trajet en minutes
    const pickupTime = 10; // Temps de récupération
    const deliveryTime = 5; // Temps de remise
    
    return (travelTime + pickupTime + deliveryTime).round();
  }

  /// Calculer l'ETA (Estimated Time of Arrival)
  Future<Map<String, dynamic>> calculateETA({
    required String deliveryId,
    required Map<String, dynamic> currentLocation,
  }) async {
    try {
      final delivery = await getDelivery(deliveryId);
      if (delivery == null) {
        throw Exception('Livraison introuvable');
      }

      final remainingDistance = _calculateDistance(
        currentLocation,
        delivery.deliveryAddress['coordinates'],
      );

      final remainingTime = _estimateDeliveryDuration(remainingDistance);
      final eta = DateTime.now().add(Duration(minutes: remainingTime));

      return {
        'eta': eta,
        'remainingDistance': remainingDistance,
        'remainingTime': remainingTime,
      };
    } catch (e) {
      throw Exception('Erreur calcul ETA: $e');
    }
  }

  /// Mapper le statut de livraison au statut de commande
  String _mapDeliveryStatusToOrderStatus(String deliveryStatus) {
    switch (deliveryStatus) {
      case 'assigned':
        return 'preparing';
      case 'picked_up':
        return 'ready';
      case 'in_transit':
        return 'in_delivery';
      case 'delivered':
        return 'delivered';
      case 'cancelled':
        return 'cancelled';
      default:
        return 'pending';
    }
  }

  // ===== STATISTIQUES LIVREUR =====

  /// Obtenir les statistiques d'un livreur
  Future<Map<String, dynamic>> getLivreurStats(String livreurId) async {
    try {
      final deliveries = await getLivreurDeliveries(
        livreurId: livreurId,
        limit: 1000,
      );

      final todayDeliveries = deliveries.where((d) {
        final today = DateTime.now();
        return d.createdAt.year == today.year &&
               d.createdAt.month == today.month &&
               d.createdAt.day == today.day;
      }).toList();

      final completedDeliveries = deliveries
          .where((d) => d.status == 'delivered')
          .toList();

      final todayEarnings = todayDeliveries
          .where((d) => d.status == 'delivered')
          .fold<double>(0.0, (total, d) => total + d.deliveryFee);

      final totalEarnings = completedDeliveries
          .fold<double>(0.0, (total, d) => total + d.deliveryFee);

      final totalDistance = completedDeliveries
          .fold<double>(0.0, (total, d) => total + d.distance);

      return {
        'todayDeliveries': todayDeliveries.length,
        'todayEarnings': todayEarnings,
        'totalDeliveries': deliveries.length,
        'completedDeliveries': completedDeliveries.length,
        'totalEarnings': totalEarnings,
        'totalDistance': totalDistance,
        'avgRating': 4.5, // TODO: Calculer depuis les reviews
        'completionRate': deliveries.isEmpty 
            ? 0.0 
            : (completedDeliveries.length / deliveries.length) * 100,
      };
    } catch (e) {
      throw Exception('Erreur récupération stats: $e');
    }
  }
}
