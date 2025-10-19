// ===== lib/models/payment_model.dart =====
class PaymentModel {
  final String id;
  final String orderId;
  final String transactionId;
  final double amount;
  final double fees;
  final String phoneNumber;
  final String providerId;
  final String status;
  final String? description;
  final DateTime createdAt;
  final DateTime? completedAt;

  PaymentModel({
    required this.id,
    required this.orderId,
    required this.transactionId,
    required this.amount,
    required this.fees,
    required this.phoneNumber,
    required this.providerId,
    required this.status,
    this.description,
    required this.createdAt,
    this.completedAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'],
      orderId: json['orderId'],
      transactionId: json['transactionId'],
      amount: (json['amount'] as num).toDouble(),
      fees: (json['fees'] as num).toDouble(),
      phoneNumber: json['phoneNumber'],
      providerId: json['providerId'],
      status: json['status'],
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
    );
  }
}