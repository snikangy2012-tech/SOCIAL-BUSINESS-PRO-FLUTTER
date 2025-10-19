// ===== lib/models/delivery_model.dart =====
// Modèle de données pour les livraisons - SOCIAL BUSINESS Pro

import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle de livraison
class DeliveryModel {
  final String id;
  final String orderId;
  final String vendeurId;
  final String acheteurId;
  final String? livreurId;
  final Map<String, dynamic> pickupAddress;
  final Map<String, dynamic> deliveryAddress;
  final double distance; // en km
  final double deliveryFee; // en FCFA
  final int estimatedDuration; // en minutes
  final String packageDescription;
  final double packageValue; // en FCFA
  final bool isFragile;
  final String status; // available, assigned, picked_up, in_transit, delivered, cancelled
  final Map<String, dynamic>? currentLocation;
  final List<String>? proofOfDelivery; // URLs des photos de preuve
  final String? notes;
  final DateTime? estimatedPickup;
  final DateTime? estimatedDelivery;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? assignedAt;
  final DateTime? pickedUpAt;
  final DateTime? inTransitAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;
  final DateTime? lastLocationUpdate;

  DeliveryModel({
    required this.id,
    required this.orderId,
    required this.vendeurId,
    required this.acheteurId,
    this.livreurId,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.distance,
    required this.deliveryFee,
    required this.estimatedDuration,
    required this.packageDescription,
    required this.packageValue,
    this.isFragile = false,
    required this.status,
    this.currentLocation,
    this.proofOfDelivery,
    this.notes,
    this.estimatedPickup,
    this.estimatedDelivery,
    required this.createdAt,
    required this.updatedAt,
    this.assignedAt,
    this.pickedUpAt,
    this.inTransitAt,
    this.deliveredAt,
    this.cancelledAt,
    this.lastLocationUpdate,
  });

  /// Créer depuis Firestore
  factory DeliveryModel.fromMap(Map<String, dynamic> data) {
    return DeliveryModel(
      id: data['id'] ?? '',
      orderId: data['orderId'] ?? '',
      vendeurId: data['vendeurId'] ?? '',
      acheteurId: data['acheteurId'] ?? '',
      livreurId: data['livreurId'],
      pickupAddress: Map<String, dynamic>.from(data['pickupAddress'] ?? {}),
      deliveryAddress: Map<String, dynamic>.from(data['deliveryAddress'] ?? {}),
      distance: (data['distance'] ?? 0).toDouble(),
      deliveryFee: (data['deliveryFee'] ?? 0).toDouble(),
      estimatedDuration: data['estimatedDuration'] ?? 0,
      packageDescription: data['packageDescription'] ?? '',
      packageValue: (data['packageValue'] ?? 0).toDouble(),
      isFragile: data['isFragile'] ?? false,
      status: data['status'] ?? 'available',
      currentLocation: data['currentLocation'] != null
          ? Map<String, dynamic>.from(data['currentLocation'])
          : null,
      proofOfDelivery: data['proofOfDelivery'] != null
          ? List<String>.from(data['proofOfDelivery'])
          : null,
      notes: data['notes'],
      estimatedPickup: data['estimatedPickup']?.toDate(),
      estimatedDelivery: data['estimatedDelivery']?.toDate(),
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: data['updatedAt']?.toDate() ?? DateTime.now(),
      assignedAt: data['assignedAt']?.toDate(),
      pickedUpAt: data['pickedUpAt']?.toDate(),
      inTransitAt: data['inTransitAt']?.toDate(),
      deliveredAt: data['deliveredAt']?.toDate(),
      cancelledAt: data['cancelledAt']?.toDate(),
      lastLocationUpdate: data['lastLocationUpdate']?.toDate(),
    );
  }

  /// Convertir en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'vendeurId': vendeurId,
      'acheteurId': acheteurId,
      'livreurId': livreurId,
      'pickupAddress': pickupAddress,
      'deliveryAddress': deliveryAddress,
      'distance': distance,
      'deliveryFee': deliveryFee,
      'estimatedDuration': estimatedDuration,
      'packageDescription': packageDescription,
      'packageValue': packageValue,
      'isFragile': isFragile,
      'status': status,
      'currentLocation': currentLocation,
      'proofOfDelivery': proofOfDelivery,
      'notes': notes,
      'estimatedPickup': estimatedPickup != null 
          ? Timestamp.fromDate(estimatedPickup!) 
          : null,
      'estimatedDelivery': estimatedDelivery != null 
          ? Timestamp.fromDate(estimatedDelivery!) 
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'assignedAt': assignedAt != null ? Timestamp.fromDate(assignedAt!) : null,
      'pickedUpAt': pickedUpAt != null ? Timestamp.fromDate(pickedUpAt!) : null,
      'inTransitAt': inTransitAt != null ? Timestamp.fromDate(inTransitAt!) : null,
      'deliveredAt': deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'lastLocationUpdate': lastLocationUpdate != null 
          ? Timestamp.fromDate(lastLocationUpdate!) 
          : null,
    };
  }

  /// Copier avec modifications
  DeliveryModel copyWith({
    String? id,
    String? orderId,
    String? vendeurId,
    String? acheteurId,
    String? livreurId,
    Map<String, dynamic>? pickupAddress,
    Map<String, dynamic>? deliveryAddress,
    double? distance,
    double? deliveryFee,
    int? estimatedDuration,
    String? packageDescription,
    double? packageValue,
    bool? isFragile,
    String? status,
    Map<String, dynamic>? currentLocation,
    List<String>? proofOfDelivery,
    String? notes,
    DateTime? estimatedPickup,
    DateTime? estimatedDelivery,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? assignedAt,
    DateTime? pickedUpAt,
    DateTime? inTransitAt,
    DateTime? deliveredAt,
    DateTime? cancelledAt,
    DateTime? lastLocationUpdate,
  }) {
    return DeliveryModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      vendeurId: vendeurId ?? this.vendeurId,
      acheteurId: acheteurId ?? this.acheteurId,
      livreurId: livreurId ?? this.livreurId,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      distance: distance ?? this.distance,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      packageDescription: packageDescription ?? this.packageDescription,
      packageValue: packageValue ?? this.packageValue,
      isFragile: isFragile ?? this.isFragile,
      status: status ?? this.status,
      currentLocation: currentLocation ?? this.currentLocation,
      proofOfDelivery: proofOfDelivery ?? this.proofOfDelivery,
      notes: notes ?? this.notes,
      estimatedPickup: estimatedPickup ?? this.estimatedPickup,
      estimatedDelivery: estimatedDelivery ?? this.estimatedDelivery,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      assignedAt: assignedAt ?? this.assignedAt,
      pickedUpAt: pickedUpAt ?? this.pickedUpAt,
      inTransitAt: inTransitAt ?? this.inTransitAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      lastLocationUpdate: lastLocationUpdate ?? this.lastLocationUpdate,
    );
  }

  /// Obtenir le statut en français
  String get statusLabel {
    switch (status) {
      case 'available':
        return 'Disponible';
      case 'assigned':
        return 'Assignée';
      case 'picked_up':
        return 'Récupérée';
      case 'in_transit':
        return 'En cours';
      case 'delivered':
        return 'Livrée';
      case 'cancelled':
        return 'Annulée';
      default:
        return status;
    }
  }

  /// Vérifier si la livraison est en cours
  bool get isActive {
    return ['assigned', 'picked_up', 'in_transit'].contains(status);
  }

  /// Vérifier si la livraison est terminée
  bool get isCompleted {
    return ['delivered', 'cancelled'].contains(status);
  }
}
