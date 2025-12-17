// ===== lib/models/platform_transaction_model.dart =====
// Gestion des transactions et commissions de la plateforme

import 'package:cloud_firestore/cloud_firestore.dart';

/// Type de transaction de la plateforme
enum PlatformTransactionType {
  vendeurCommission, // Commission sur vente vendeur
  livreurCommission, // Commission sur livraison
  subscriptionPayment, // Paiement d'abonnement
}

/// Statut du paiement de la commission
enum CommissionPaymentStatus {
  pending, // En attente de paiement (livreur doit reverser)
  paid, // Payé à la plateforme
  settled, // Réglé au vendeur par la plateforme
  cancelled, // Annulé (commande annulée)
}

/// Méthode de collecte du paiement
enum PaymentCollectionMethod {
  cash, // Espèces (collectées par livreur)
  mobileMoney, // Mobile Money (paiement direct)
  platformWallet, // Portefeuille plateforme
}

/// Modèle pour une transaction de la plateforme
class PlatformTransaction {
  final String id;
  final PlatformTransactionType type;
  final String orderId; // ID de la commande associée
  final String? deliveryId; // ID de la livraison (si applicable)

  // Parties impliquées
  final String vendeurId;
  final String? livreurId;
  final String? buyerId;

  // Montants
  final double orderAmount; // Montant total de la commande
  final double vendeurAmount; // Montant revenant au vendeur (après commission)
  final double livreurAmount; // Montant revenant au livreur (frais de livraison - commission)
  final double platformCommissionVendeur; // Commission plateforme sur vente
  final double platformCommissionLivreur; // Commission plateforme sur livraison
  final double totalPlatformRevenue; // Revenu total plateforme (vendeur + livreur commissions)

  // Taux de commission appliqués
  final double vendeurCommissionRate; // Ex: 0.10 (10%)
  final double livreurCommissionRate; // Ex: 0.25 (25%)

  // Méthode de paiement
  final PaymentCollectionMethod paymentMethod;
  final CommissionPaymentStatus status;

  // Suivi des paiements
  final DateTime? cashCollectedAt; // Quand le livreur a collecté l'argent
  final DateTime? platformPaidAt; // Quand la commission a été reversée à la plateforme
  final DateTime? vendeurSettledAt; // Quand le vendeur a été payé par la plateforme

  // Informations de règlement
  final String? livreurPaymentReference; // Référence paiement livreur → plateforme
  final String? vendeurPaymentReference; // Référence paiement plateforme → vendeur

  // Métadonnées
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> metadata;

  PlatformTransaction({
    required this.id,
    required this.type,
    required this.orderId,
    this.deliveryId,
    required this.vendeurId,
    this.livreurId,
    this.buyerId,
    required this.orderAmount,
    required this.vendeurAmount,
    required this.livreurAmount,
    required this.platformCommissionVendeur,
    required this.platformCommissionLivreur,
    required this.totalPlatformRevenue,
    required this.vendeurCommissionRate,
    required this.livreurCommissionRate,
    required this.paymentMethod,
    required this.status,
    this.cashCollectedAt,
    this.platformPaidAt,
    this.vendeurSettledAt,
    this.livreurPaymentReference,
    this.vendeurPaymentReference,
    required this.createdAt,
    required this.updatedAt,
    this.metadata = const {},
  });

  /// Crée une transaction depuis Firestore
  factory PlatformTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PlatformTransaction.fromMap(data, doc.id);
  }

  /// Crée une transaction depuis une Map
  factory PlatformTransaction.fromMap(Map<String, dynamic> map, [String? id]) {
    return PlatformTransaction(
      id: id ?? map['id'] ?? '',
      type: PlatformTransactionType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => PlatformTransactionType.vendeurCommission,
      ),
      orderId: map['orderId'] ?? '',
      deliveryId: map['deliveryId'],
      vendeurId: map['vendeurId'] ?? '',
      livreurId: map['livreurId'],
      buyerId: map['buyerId'],
      orderAmount: (map['orderAmount'] ?? 0).toDouble(),
      vendeurAmount: (map['vendeurAmount'] ?? 0).toDouble(),
      livreurAmount: (map['livreurAmount'] ?? 0).toDouble(),
      platformCommissionVendeur: (map['platformCommissionVendeur'] ?? 0).toDouble(),
      platformCommissionLivreur: (map['platformCommissionLivreur'] ?? 0).toDouble(),
      totalPlatformRevenue: (map['totalPlatformRevenue'] ?? 0).toDouble(),
      vendeurCommissionRate: (map['vendeurCommissionRate'] ?? 0).toDouble(),
      livreurCommissionRate: (map['livreurCommissionRate'] ?? 0).toDouble(),
      paymentMethod: PaymentCollectionMethod.values.firstWhere(
        (m) => m.name == map['paymentMethod'],
        orElse: () => PaymentCollectionMethod.cash,
      ),
      status: CommissionPaymentStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => CommissionPaymentStatus.pending,
      ),
      cashCollectedAt: map['cashCollectedAt'] != null
          ? (map['cashCollectedAt'] as Timestamp).toDate()
          : null,
      platformPaidAt: map['platformPaidAt'] != null
          ? (map['platformPaidAt'] as Timestamp).toDate()
          : null,
      vendeurSettledAt: map['vendeurSettledAt'] != null
          ? (map['vendeurSettledAt'] as Timestamp).toDate()
          : null,
      livreurPaymentReference: map['livreurPaymentReference'],
      vendeurPaymentReference: map['vendeurPaymentReference'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  /// Convertit en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'orderId': orderId,
      'deliveryId': deliveryId,
      'vendeurId': vendeurId,
      'livreurId': livreurId,
      'buyerId': buyerId,
      'orderAmount': orderAmount,
      'vendeurAmount': vendeurAmount,
      'livreurAmount': livreurAmount,
      'platformCommissionVendeur': platformCommissionVendeur,
      'platformCommissionLivreur': platformCommissionLivreur,
      'totalPlatformRevenue': totalPlatformRevenue,
      'vendeurCommissionRate': vendeurCommissionRate,
      'livreurCommissionRate': livreurCommissionRate,
      'paymentMethod': paymentMethod.name,
      'status': status.name,
      'cashCollectedAt': cashCollectedAt != null
          ? Timestamp.fromDate(cashCollectedAt!)
          : null,
      'platformPaidAt': platformPaidAt != null
          ? Timestamp.fromDate(platformPaidAt!)
          : null,
      'vendeurSettledAt': vendeurSettledAt != null
          ? Timestamp.fromDate(vendeurSettledAt!)
          : null,
      'livreurPaymentReference': livreurPaymentReference,
      'vendeurPaymentReference': vendeurPaymentReference,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
    };
  }

  /// Copie avec modifications
  PlatformTransaction copyWith({
    String? id,
    PlatformTransactionType? type,
    String? orderId,
    String? deliveryId,
    String? vendeurId,
    String? livreurId,
    String? buyerId,
    double? orderAmount,
    double? vendeurAmount,
    double? livreurAmount,
    double? platformCommissionVendeur,
    double? platformCommissionLivreur,
    double? totalPlatformRevenue,
    double? vendeurCommissionRate,
    double? livreurCommissionRate,
    PaymentCollectionMethod? paymentMethod,
    CommissionPaymentStatus? status,
    DateTime? cashCollectedAt,
    DateTime? platformPaidAt,
    DateTime? vendeurSettledAt,
    String? livreurPaymentReference,
    String? vendeurPaymentReference,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return PlatformTransaction(
      id: id ?? this.id,
      type: type ?? this.type,
      orderId: orderId ?? this.orderId,
      deliveryId: deliveryId ?? this.deliveryId,
      vendeurId: vendeurId ?? this.vendeurId,
      livreurId: livreurId ?? this.livreurId,
      buyerId: buyerId ?? this.buyerId,
      orderAmount: orderAmount ?? this.orderAmount,
      vendeurAmount: vendeurAmount ?? this.vendeurAmount,
      livreurAmount: livreurAmount ?? this.livreurAmount,
      platformCommissionVendeur: platformCommissionVendeur ?? this.platformCommissionVendeur,
      platformCommissionLivreur: platformCommissionLivreur ?? this.platformCommissionLivreur,
      totalPlatformRevenue: totalPlatformRevenue ?? this.totalPlatformRevenue,
      vendeurCommissionRate: vendeurCommissionRate ?? this.vendeurCommissionRate,
      livreurCommissionRate: livreurCommissionRate ?? this.livreurCommissionRate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      cashCollectedAt: cashCollectedAt ?? this.cashCollectedAt,
      platformPaidAt: platformPaidAt ?? this.platformPaidAt,
      vendeurSettledAt: vendeurSettledAt ?? this.vendeurSettledAt,
      livreurPaymentReference: livreurPaymentReference ?? this.livreurPaymentReference,
      vendeurPaymentReference: vendeurPaymentReference ?? this.vendeurPaymentReference,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Obtient le nom du type de transaction
  String get typeName {
    switch (type) {
      case PlatformTransactionType.vendeurCommission:
        return 'Commission Vendeur';
      case PlatformTransactionType.livreurCommission:
        return 'Commission Livreur';
      case PlatformTransactionType.subscriptionPayment:
        return 'Paiement Abonnement';
    }
  }

  /// Obtient le nom du statut
  String get statusName {
    switch (status) {
      case CommissionPaymentStatus.pending:
        return 'En attente';
      case CommissionPaymentStatus.paid:
        return 'Payé';
      case CommissionPaymentStatus.settled:
        return 'Réglé';
      case CommissionPaymentStatus.cancelled:
        return 'Annulé';
    }
  }

  /// Obtient le nom de la méthode de paiement
  String get paymentMethodName {
    switch (paymentMethod) {
      case PaymentCollectionMethod.cash:
        return 'Espèces';
      case PaymentCollectionMethod.mobileMoney:
        return 'Mobile Money';
      case PaymentCollectionMethod.platformWallet:
        return 'Portefeuille';
    }
  }
}
