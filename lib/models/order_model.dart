// ===== lib/models/order_model.dart (AJOUTS NÉCESSAIRES) =====

import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
  final String orderNumber;
  final int displayNumber; // Numéro d'affichage incrémental (1, 2, 3...)
  final String vendeurId;
  final String buyerId;
  final String buyerName;
  final String buyerPhone;
  final List<OrderItemModel> items;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double totalAmount;
  final String status;
  final String deliveryAddress;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deliveredAt;
  final String? cancellationReason;
  final DateTime? cancelledAt;

  // Coordonnées GPS pour la livraison
  final double? pickupLatitude;
  final double? pickupLongitude;
  final double? deliveryLatitude;
  final double? deliveryLongitude;
  final String? livreurId; // ID du livreur assigné
  final String? livreurName; // Nom du livreur
  final String? livreurPhone; // Téléphone du livreur

  // Champs pour les remboursements
  final String? refundId; // ID du remboursement associé
  final String? refundStatus; // Statut du remboursement
  final String? paymentMethod; // Méthode de paiement utilisée

  // Informations vendeur
  final String? vendeurName; // Nom du vendeur
  final String? vendeurShopName; // Nom de la boutique
  final String? vendeurPhone; // Téléphone du vendeur
  final String? vendeurLocation; // Localisation de la boutique (ex: "Cocody, Angré")
  final bool isVendorDelivery; // Le vendeur livre lui-même (pour commandes >50k)

  // Click & Collect (Retrait en boutique)
  final String deliveryMethod; // 'home_delivery' | 'store_pickup' | 'vendor_delivery'
  final String? pickupQRCode; // QR code pour validation retrait en boutique
  final DateTime? pickupReadyAt; // Date/heure où la commande est prête pour retrait
  final DateTime? pickedUpAt; // Date/heure de récupération effective par le client

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.displayNumber,
    required this.vendeurId,
    required this.buyerId,
    required this.buyerName,
    required this.buyerPhone,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    this.discount = 0,
    required this.totalAmount,
    required this.status,
    required this.deliveryAddress,
    this.notes,
    required this.createdAt,
    this.updatedAt,
    this.deliveredAt,
    this.cancellationReason,
    this.cancelledAt,
    this.pickupLatitude,
    this.pickupLongitude,
    this.deliveryLatitude,
    this.deliveryLongitude,
    this.livreurId,
    this.livreurName,
    this.livreurPhone,
    this.refundId,
    this.refundStatus,
    this.paymentMethod,
    this.vendeurName,
    this.vendeurShopName,
    this.vendeurPhone,
    this.vendeurLocation,
    this.isVendorDelivery = false,
    this.deliveryMethod = 'home_delivery',
    this.pickupQRCode,
    this.pickupReadyAt,
    this.pickedUpAt,
  });

  // ✅ MÉTHODE À AJOUTER : Créer OrderModel depuis Firestore DocumentSnapshot
  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return OrderModel(
      id: doc.id,
      orderNumber: data['orderNumber'] ?? '',
      displayNumber: data['displayNumber'] ?? 0,
      vendeurId: data['vendeurId'] ?? '',
      buyerId: data['buyerId'] ?? '',
      buyerName: data['buyerName'] ?? 'Client',
      buyerPhone: data['buyerPhone'] ?? '',
      items: (data['items'] as List<dynamic>? ?? [])
          .map((item) => OrderItemModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      subtotal: (data['subtotal'] ?? 0).toDouble(),
      deliveryFee: (data['deliveryFee'] ?? 0).toDouble(),
      discount: (data['discount'] ?? 0).toDouble(),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      status: data['status'] ?? 'pending',
      deliveryAddress: data['deliveryAddress'] ?? '',
      notes: data['notes'],
      createdAt: _timestampToDateTime(data['createdAt']),
      updatedAt: _timestampToDateTime(data['updatedAt']),
      deliveredAt: _timestampToDateTime(data['deliveredAt']),
      cancellationReason: data['cancellationReason'],
      cancelledAt: _timestampToDateTime(data['cancelledAt']),
      pickupLatitude: data['pickupLatitude']?.toDouble(),
      pickupLongitude: data['pickupLongitude']?.toDouble(),
      deliveryLatitude: data['deliveryLatitude']?.toDouble(),
      deliveryLongitude: data['deliveryLongitude']?.toDouble(),
      livreurId: data['livreurId'],
      livreurName: data['livreurName'],
      livreurPhone: data['livreurPhone'],
      refundId: data['refundId'],
      refundStatus: data['refundStatus'],
      paymentMethod: data['paymentMethod'],
      vendeurName: data['vendeurName'],
      vendeurShopName: data['vendeurShopName'],
      vendeurPhone: data['vendeurPhone'],
      vendeurLocation: data['vendeurLocation'],
      isVendorDelivery: data['isVendorDelivery'] ?? false,
      deliveryMethod: data['deliveryMethod'] ?? 'home_delivery',
      pickupQRCode: data['pickupQRCode'],
      pickupReadyAt: _timestampToDateTime(data['pickupReadyAt']),
      pickedUpAt: _timestampToDateTime(data['pickedUpAt']),
    );
  }

  // ✅ MÉTHODE À AJOUTER : Convertir OrderModel en Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'orderNumber': orderNumber,
      'displayNumber': displayNumber,
      'vendeurId': vendeurId,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'buyerPhone': buyerPhone,
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'discount': discount,
      'totalAmount': totalAmount,
      'status': status,
      'deliveryAddress': deliveryAddress,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'deliveredAt': deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
      'cancellationReason': cancellationReason,
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'pickupLatitude': pickupLatitude,
      'pickupLongitude': pickupLongitude,
      'deliveryLatitude': deliveryLatitude,
      'deliveryLongitude': deliveryLongitude,
      'livreurId': livreurId,
      'livreurName': livreurName,
      'livreurPhone': livreurPhone,
      'refundId': refundId,
      'refundStatus': refundStatus,
      'paymentMethod': paymentMethod,
      'vendeurName': vendeurName,
      'vendeurShopName': vendeurShopName,
      'vendeurPhone': vendeurPhone,
      'vendeurLocation': vendeurLocation,
      'isVendorDelivery': isVendorDelivery,
      'deliveryMethod': deliveryMethod,
      'pickupQRCode': pickupQRCode,
      'pickupReadyAt': pickupReadyAt != null ? Timestamp.fromDate(pickupReadyAt!) : null,
      'pickedUpAt': pickedUpAt != null ? Timestamp.fromDate(pickedUpAt!) : null,
    };
  }

  // ✅ HELPER PRIVÉ : Convertir Timestamp Firestore en DateTime
  static DateTime _timestampToDateTime(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }
    
    if (timestamp is DateTime) {
      return timestamp;
    }
    
    // Fallback si type inconnu
    return DateTime.now();
  }

  // ✅ MÉTHODE À AJOUTER : Créer copie avec modifications
  OrderModel copyWith({
    String? id,
    String? orderNumber,
    int? displayNumber,
    String? vendeurId,
    String? buyerId,
    String? buyerName,
    String? buyerPhone,
    List<OrderItemModel>? items,
    double? subtotal,
    double? deliveryFee,
    double? totalAmount,
    String? status,
    String? deliveryAddress,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deliveredAt,
    String? cancellationReason,
    DateTime? cancelledAt,
    double? pickupLatitude,
    double? pickupLongitude,
    double? deliveryLatitude,
    double? deliveryLongitude,
    String? livreurId,
    String? livreurName,
    String? livreurPhone,
    String? refundId,
    String? refundStatus,
    String? paymentMethod,
    String? vendeurName,
    String? vendeurShopName,
    String? vendeurPhone,
    String? vendeurLocation,
    bool? isVendorDelivery,
    String? deliveryMethod,
    String? pickupQRCode,
    DateTime? pickupReadyAt,
    DateTime? pickedUpAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      displayNumber: displayNumber ?? this.displayNumber,
      vendeurId: vendeurId ?? this.vendeurId,
      buyerId: buyerId ?? this.buyerId,
      buyerName: buyerName ?? this.buyerName,
      buyerPhone: buyerPhone ?? this.buyerPhone,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      pickupLatitude: pickupLatitude ?? this.pickupLatitude,
      pickupLongitude: pickupLongitude ?? this.pickupLongitude,
      deliveryLatitude: deliveryLatitude ?? this.deliveryLatitude,
      deliveryLongitude: deliveryLongitude ?? this.deliveryLongitude,
      livreurId: livreurId ?? this.livreurId,
      livreurName: livreurName ?? this.livreurName,
      livreurPhone: livreurPhone ?? this.livreurPhone,
      refundId: refundId ?? this.refundId,
      refundStatus: refundStatus ?? this.refundStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      vendeurName: vendeurName ?? this.vendeurName,
      vendeurShopName: vendeurShopName ?? this.vendeurShopName,
      vendeurPhone: vendeurPhone ?? this.vendeurPhone,
      vendeurLocation: vendeurLocation ?? this.vendeurLocation,
      isVendorDelivery: isVendorDelivery ?? this.isVendorDelivery,
      deliveryMethod: deliveryMethod ?? this.deliveryMethod,
      pickupQRCode: pickupQRCode ?? this.pickupQRCode,
      pickupReadyAt: pickupReadyAt ?? this.pickupReadyAt,
      pickedUpAt: pickedUpAt ?? this.pickedUpAt,
    );
  }

  // Vérifier si la commande peut être retournée
  bool get canBeReturned {
    return (status == 'livree' || status == 'en_cours') && refundId == null;
  }

  // Vérifier si un remboursement est en cours
  bool get hasRefundPending {
    return refundId != null && refundStatus != 'rembourse' && refundStatus != 'refusee';
  }
}

// ===== OrderItemModel avec méthode toJson() =====
class OrderItemModel {
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final String? productImage;

  OrderItemModel({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    this.productImage,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 0,
      productImage: json['productImage'],
    );
  }

  // ✅ MÉTHODE À AJOUTER
  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'price': price,
      'quantity': quantity,
      'productImage': productImage,
    };
  }
}

// Modèle pour les statistiques de commandes
class OrderStats {
  final int totalOrders;
  final int pendingOrders;
  final int deliveredOrders;
  final int cancelledOrders;
  final double totalRevenue;

  OrderStats({
    required this.totalOrders,
    required this.pendingOrders,
    required this.deliveredOrders,
    required this.cancelledOrders,
    required this.totalRevenue,
  });
}