// ===== lib/models/order_model.dart (AJOUTS NÉCESSAIRES) =====

import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
  final String orderNumber;
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

  OrderModel({
    required this.id,
    required this.orderNumber,
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
  });

  // ✅ MÉTHODE À AJOUTER : Créer OrderModel depuis Firestore DocumentSnapshot
  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return OrderModel(
      id: doc.id,
      orderNumber: data['orderNumber'] ?? '',
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
    );
  }

  // ✅ MÉTHODE À AJOUTER : Convertir OrderModel en Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'orderNumber': orderNumber,
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
  }) {
    return OrderModel(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
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
    );
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