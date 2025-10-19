// ===== lib/models/payment_method_model.dart =====
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentMethodModel {
  final String id;
  final String userId;
  final String type; // 'card', 'mobile_money', 'bank_transfer'

  // Card fields
  final String? cardBrand; // Visa, Mastercard, etc.
  final String? lastFourDigits;
  final String? cardHolderName;
  final String? expiryDate; // MM/YY format

  // Mobile money fields
  final String? provider; // orange_money, mtn_money, moov_money, wave
  final String? phoneNumber;

  // Bank transfer fields
  final String? accountNumber;
  final String? accountName;
  final String? bankName;

  final bool isDefault;
  final DateTime createdAt;
  final DateTime? updatedAt;

  PaymentMethodModel({
    required this.id,
    required this.userId,
    required this.type,
    this.cardBrand,
    this.lastFourDigits,
    this.cardHolderName,
    this.expiryDate,
    this.provider,
    this.phoneNumber,
    this.accountNumber,
    this.accountName,
    this.bankName,
    this.isDefault = false,
    required this.createdAt,
    this.updatedAt,
  });

  // Create from Firestore document
  factory PaymentMethodModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PaymentMethodModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: data['type'] ?? 'card',
      cardBrand: data['cardBrand'],
      lastFourDigits: data['lastFourDigits'],
      cardHolderName: data['cardHolderName'],
      expiryDate: data['expiryDate'],
      provider: data['provider'],
      phoneNumber: data['phoneNumber'],
      accountNumber: data['accountNumber'],
      accountName: data['accountName'],
      bankName: data['bankName'],
      isDefault: data['isDefault'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    final Map<String, dynamic> data = {
      'userId': userId,
      'type': type,
      'isDefault': isDefault,
      'createdAt': Timestamp.fromDate(createdAt),
    };

    if (cardBrand != null) data['cardBrand'] = cardBrand;
    if (lastFourDigits != null) data['lastFourDigits'] = lastFourDigits;
    if (cardHolderName != null) data['cardHolderName'] = cardHolderName;
    if (expiryDate != null) data['expiryDate'] = expiryDate;
    if (provider != null) data['provider'] = provider;
    if (phoneNumber != null) data['phoneNumber'] = phoneNumber;
    if (accountNumber != null) data['accountNumber'] = accountNumber;
    if (accountName != null) data['accountName'] = accountName;
    if (bankName != null) data['bankName'] = bankName;
    if (updatedAt != null) data['updatedAt'] = Timestamp.fromDate(updatedAt!);

    return data;
  }

  // Copy with method
  PaymentMethodModel copyWith({
    String? id,
    String? userId,
    String? type,
    String? cardBrand,
    String? lastFourDigits,
    String? cardHolderName,
    String? expiryDate,
    String? provider,
    String? phoneNumber,
    String? accountNumber,
    String? accountName,
    String? bankName,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentMethodModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      cardBrand: cardBrand ?? this.cardBrand,
      lastFourDigits: lastFourDigits ?? this.lastFourDigits,
      cardHolderName: cardHolderName ?? this.cardHolderName,
      expiryDate: expiryDate ?? this.expiryDate,
      provider: provider ?? this.provider,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      accountNumber: accountNumber ?? this.accountNumber,
      accountName: accountName ?? this.accountName,
      bankName: bankName ?? this.bankName,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}