// ===== lib/models/refund_model.dart =====
// Modèle de remboursement et retour de produits - SOCIAL BUSINESS Pro

import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/constants.dart';

/// Modèle de remboursement et retour
class RefundModel {
  final String id;
  final String orderId;
  final String buyerId;
  final String buyerName;
  final String vendeurId;
  final String vendeurName;
  final String? livreurId;
  final String? livreurName;

  // Détails de la demande
  final String reason; // Raison du retour
  final String description; // Description détaillée
  final List<String> images; // Photos du produit (problème, défaut, etc.)

  // Montants
  final double productAmount; // Montant du produit à rembourser
  final double deliveryFee; // Frais de livraison aller-retour
  final double vendeurDeliveryCharge; // Part du vendeur (50% des frais)
  final double livreurDeliveryCharge; // Part du livreur (50% des frais)

  // Informations paiement original
  final String paymentMethod; // cash_on_delivery, mobile_money, bank_card
  final bool isPrepaid; // true si payé avant livraison

  // Statut et workflow
  final String status; // demande_envoyee, approuvee, refusee, produit_retourne, rembourse
  final DateTime requestedAt;
  final DateTime? approvedAt;
  final DateTime? returnedAt; // Date de retour du produit
  final DateTime? refundedAt; // Date de remboursement effectué

  // Notes et communications
  final String? vendeurNote; // Note du vendeur lors de l'approbation/refus
  final String? refundReference; // Référence du remboursement (pour traçabilité)

  RefundModel({
    required this.id,
    required this.orderId,
    required this.buyerId,
    required this.buyerName,
    required this.vendeurId,
    required this.vendeurName,
    this.livreurId,
    this.livreurName,
    required this.reason,
    required this.description,
    this.images = const [],
    required this.productAmount,
    required this.deliveryFee,
    required this.vendeurDeliveryCharge,
    required this.livreurDeliveryCharge,
    required this.paymentMethod,
    required this.isPrepaid,
    required this.status,
    required this.requestedAt,
    this.approvedAt,
    this.returnedAt,
    this.refundedAt,
    this.vendeurNote,
    this.refundReference,
  });

  /// Créer depuis Firestore
  factory RefundModel.fromMap(Map<String, dynamic> data) {
    return RefundModel(
      id: data['id'] ?? '',
      orderId: data['orderId'] ?? '',
      buyerId: data['buyerId'] ?? '',
      buyerName: data['buyerName'] ?? '',
      vendeurId: data['vendeurId'] ?? '',
      vendeurName: data['vendeurName'] ?? '',
      livreurId: data['livreurId'],
      livreurName: data['livreurName'],
      reason: data['reason'] ?? '',
      description: data['description'] ?? '',
      images: List<String>.from(data['images'] ?? []),
      productAmount: (data['productAmount'] ?? 0).toDouble(),
      deliveryFee: (data['deliveryFee'] ?? 0).toDouble(),
      vendeurDeliveryCharge: (data['vendeurDeliveryCharge'] ?? 0).toDouble(),
      livreurDeliveryCharge: (data['livreurDeliveryCharge'] ?? 0).toDouble(),
      paymentMethod: data['paymentMethod'] ?? '',
      isPrepaid: data['isPrepaid'] ?? false,
      status: data['status'] ?? RefundStatus.demandeEnvoyee.value,
      requestedAt: data['requestedAt']?.toDate() ?? DateTime.now(),
      approvedAt: data['approvedAt']?.toDate(),
      returnedAt: data['returnedAt']?.toDate(),
      refundedAt: data['refundedAt']?.toDate(),
      vendeurNote: data['vendeurNote'],
      refundReference: data['refundReference'],
    );
  }

  /// Convertir en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'vendeurId': vendeurId,
      'vendeurName': vendeurName,
      'livreurId': livreurId,
      'livreurName': livreurName,
      'reason': reason,
      'description': description,
      'images': images,
      'productAmount': productAmount,
      'deliveryFee': deliveryFee,
      'vendeurDeliveryCharge': vendeurDeliveryCharge,
      'livreurDeliveryCharge': livreurDeliveryCharge,
      'paymentMethod': paymentMethod,
      'isPrepaid': isPrepaid,
      'status': status,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'returnedAt': returnedAt != null ? Timestamp.fromDate(returnedAt!) : null,
      'refundedAt': refundedAt != null ? Timestamp.fromDate(refundedAt!) : null,
      'vendeurNote': vendeurNote,
      'refundReference': refundReference,
    };
  }

  /// Copier avec modifications
  RefundModel copyWith({
    String? id,
    String? orderId,
    String? buyerId,
    String? buyerName,
    String? vendeurId,
    String? vendeurName,
    String? livreurId,
    String? livreurName,
    String? reason,
    String? description,
    List<String>? images,
    double? productAmount,
    double? deliveryFee,
    double? vendeurDeliveryCharge,
    double? livreurDeliveryCharge,
    String? paymentMethod,
    bool? isPrepaid,
    String? status,
    DateTime? requestedAt,
    DateTime? approvedAt,
    DateTime? returnedAt,
    DateTime? refundedAt,
    String? vendeurNote,
    String? refundReference,
  }) {
    return RefundModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      buyerId: buyerId ?? this.buyerId,
      buyerName: buyerName ?? this.buyerName,
      vendeurId: vendeurId ?? this.vendeurId,
      vendeurName: vendeurName ?? this.vendeurName,
      livreurId: livreurId ?? this.livreurId,
      livreurName: livreurName ?? this.livreurName,
      reason: reason ?? this.reason,
      description: description ?? this.description,
      images: images ?? this.images,
      productAmount: productAmount ?? this.productAmount,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      vendeurDeliveryCharge: vendeurDeliveryCharge ?? this.vendeurDeliveryCharge,
      livreurDeliveryCharge: livreurDeliveryCharge ?? this.livreurDeliveryCharge,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isPrepaid: isPrepaid ?? this.isPrepaid,
      status: status ?? this.status,
      requestedAt: requestedAt ?? this.requestedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      returnedAt: returnedAt ?? this.returnedAt,
      refundedAt: refundedAt ?? this.refundedAt,
      vendeurNote: vendeurNote ?? this.vendeurNote,
      refundReference: refundReference ?? this.refundReference,
    );
  }

  /// Montant total des frais de livraison aller-retour
  double get totalDeliveryFee => vendeurDeliveryCharge + livreurDeliveryCharge;

  /// Vérifier si le remboursement est en attente d'action vendeur
  bool get isPendingVendeurAction => status == RefundStatus.demandeEnvoyee.value;

  /// Vérifier si le remboursement est approuvé
  bool get isApproved => status == RefundStatus.approuvee.value;

  /// Vérifier si le remboursement est refusé
  bool get isRefused => status == RefundStatus.refusee.value;

  /// Vérifier si le produit est retourné
  bool get isReturned => status == RefundStatus.produitRetourne.value;

  /// Vérifier si le remboursement est complété
  bool get isCompleted => status == RefundStatus.rembourse.value;
}
