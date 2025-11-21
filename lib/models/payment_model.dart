// ===== lib/models/payment_model.dart =====
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  final String id;
  final String orderId;
  final String? orderNumber;
  final String transactionId;
  final double amount;
  final double fees;
  final double? transactionFee;
  final String phoneNumber;
  final String providerId;
  final String paymentMethod;
  final String status;
  final String? description;
  final String? vendeurId;
  final DateTime createdAt;
  final DateTime? completedAt;

  PaymentModel({
    required this.id,
    required this.orderId,
    this.orderNumber,
    required this.transactionId,
    required this.amount,
    required this.fees,
    this.transactionFee,
    required this.phoneNumber,
    required this.providerId,
    required this.paymentMethod,
    required this.status,
    this.description,
    this.vendeurId,
    required this.createdAt,
    this.completedAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'],
      orderId: json['orderId'],
      orderNumber: json['orderNumber'],
      transactionId: json['transactionId'],
      amount: (json['amount'] as num).toDouble(),
      fees: (json['fees'] as num).toDouble(),
      transactionFee: json['transactionFee'] != null ? (json['transactionFee'] as num).toDouble() : null,
      phoneNumber: json['phoneNumber'],
      providerId: json['providerId'],
      paymentMethod: json['paymentMethod'] ?? 'mobile_money',
      status: json['status'],
      description: json['description'],
      vendeurId: json['vendeurId'],
      createdAt: DateTime.parse(json['createdAt']),
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
    );
  }

  factory PaymentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PaymentModel(
      id: doc.id,
      orderId: data['orderId'] ?? '',
      orderNumber: data['orderNumber'],
      transactionId: data['transactionId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      fees: (data['fees'] ?? 0).toDouble(),
      transactionFee: data['transactionFee'] != null ? (data['transactionFee'] as num).toDouble() : null,
      phoneNumber: data['phoneNumber'] ?? '',
      providerId: data['providerId'] ?? '',
      paymentMethod: data['paymentMethod'] ?? 'mobile_money',
      status: data['status'] ?? 'pending',
      description: data['description'],
      vendeurId: data['vendeurId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'orderNumber': orderNumber,
      'transactionId': transactionId,
      'amount': amount,
      'fees': fees,
      'transactionFee': transactionFee,
      'phoneNumber': phoneNumber,
      'providerId': providerId,
      'paymentMethod': paymentMethod,
      'status': status,
      'description': description,
      'vendeurId': vendeurId,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }
}