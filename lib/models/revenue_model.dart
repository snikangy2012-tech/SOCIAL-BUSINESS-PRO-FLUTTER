// ===== lib/models/revenue_model.dart =====
// Modèle pour les revenus de la plateforme

import 'package:cloud_firestore/cloud_firestore.dart';

enum RevenueType {
  commissionVente,
  commissionLivraison,
  abonnementVendeur,
  abonnementLivreur,
}

enum UserType {
  vendeur,
  livreur,
}

class RevenueModel {
  final String id;
  final RevenueType type;
  final double amount;
  final String sourceId; // ID de la commande ou de l'abonnement
  final String userId; // ID du vendeur ou livreur concerné
  final UserType userType;
  final String description;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final int month; // 1-12
  final int year; // 2025, etc.

  RevenueModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.sourceId,
    required this.userId,
    required this.userType,
    required this.description,
    required this.metadata,
    required this.createdAt,
    required this.month,
    required this.year,
  });

  // Conversion depuis Firestore
  factory RevenueModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return RevenueModel(
      id: doc.id,
      type: _parseRevenueType(data['type'] as String),
      amount: (data['amount'] as num).toDouble(),
      sourceId: data['sourceId'] as String,
      userId: data['userId'] as String,
      userType: _parseUserType(data['userType'] as String),
      description: data['description'] as String,
      metadata: data['metadata'] as Map<String, dynamic>,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      month: data['month'] as int,
      year: data['year'] as int,
    );
  }

  // Conversion vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'type': _revenueTypeToString(type),
      'amount': amount,
      'sourceId': sourceId,
      'userId': userId,
      'userType': _userTypeToString(userType),
      'description': description,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
      'month': month,
      'year': year,
    };
  }

  // Helpers pour les enums
  static RevenueType _parseRevenueType(String value) {
    switch (value) {
      case 'commission_vente':
        return RevenueType.commissionVente;
      case 'commission_livraison':
        return RevenueType.commissionLivraison;
      case 'abonnement_vendeur':
        return RevenueType.abonnementVendeur;
      case 'abonnement_livreur':
        return RevenueType.abonnementLivreur;
      default:
        throw Exception('Type de revenu inconnu: $value');
    }
  }

  static String _revenueTypeToString(RevenueType type) {
    switch (type) {
      case RevenueType.commissionVente:
        return 'commission_vente';
      case RevenueType.commissionLivraison:
        return 'commission_livraison';
      case RevenueType.abonnementVendeur:
        return 'abonnement_vendeur';
      case RevenueType.abonnementLivreur:
        return 'abonnement_livreur';
    }
  }

  static UserType _parseUserType(String value) {
    switch (value) {
      case 'vendeur':
        return UserType.vendeur;
      case 'livreur':
        return UserType.livreur;
      default:
        throw Exception('Type utilisateur inconnu: $value');
    }
  }

  static String _userTypeToString(UserType type) {
    switch (type) {
      case UserType.vendeur:
        return 'vendeur';
      case UserType.livreur:
        return 'livreur';
    }
  }

  // Helper pour le label du type de revenu
  String get typeLabel {
    switch (type) {
      case RevenueType.commissionVente:
        return 'Commission vente';
      case RevenueType.commissionLivraison:
        return 'Commission livraison';
      case RevenueType.abonnementVendeur:
        return 'Abonnement vendeur';
      case RevenueType.abonnementLivreur:
        return 'Abonnement livreur';
    }
  }
}
