import 'package:cloud_firestore/cloud_firestore.dart';

/// Statut du compte associé au visage
enum FaceAccountStatus {
  active,
  suspended,
  blacklisted,
  deleted,
}

/// Modèle pour l'index biométrique des visages
class FaceHashModel {
  final String id;
  final String userId;
  final String faceHash; // Hash unique du visage
  final List<double> faceEmbedding; // 128D embedding pour comparaison
  final DateTime registeredAt;
  final FaceAccountStatus accountStatus;
  final String? blacklistId; // Si blacklisté
  final DateTime updatedAt;

  FaceHashModel({
    required this.id,
    required this.userId,
    required this.faceHash,
    required this.faceEmbedding,
    required this.registeredAt,
    required this.accountStatus,
    this.blacklistId,
    required this.updatedAt,
  });

  /// Factory depuis Firestore
  factory FaceHashModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;

    return FaceHashModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      faceHash: data['faceHash'] ?? '',
      faceEmbedding: List<double>.from(data['faceEmbedding'] ?? []),
      registeredAt: (data['registeredAt'] as Timestamp).toDate(),
      accountStatus: FaceAccountStatus.values.firstWhere(
        (e) => e.name == data['accountStatus'],
        orElse: () => FaceAccountStatus.active,
      ),
      blacklistId: data['blacklistId'],
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Conversion vers Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'faceHash': faceHash,
      'faceEmbedding': faceEmbedding,
      'registeredAt': Timestamp.fromDate(registeredAt),
      'accountStatus': accountStatus.name,
      'blacklistId': blacklistId,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// CopyWith
  FaceHashModel copyWith({
    String? id,
    String? userId,
    String? faceHash,
    List<double>? faceEmbedding,
    DateTime? registeredAt,
    FaceAccountStatus? accountStatus,
    String? blacklistId,
    DateTime? updatedAt,
  }) {
    return FaceHashModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      faceHash: faceHash ?? this.faceHash,
      faceEmbedding: faceEmbedding ?? this.faceEmbedding,
      registeredAt: registeredAt ?? this.registeredAt,
      accountStatus: accountStatus ?? this.accountStatus,
      blacklistId: blacklistId ?? this.blacklistId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Helpers
  bool get isActive => accountStatus == FaceAccountStatus.active;
  bool get isBlacklisted => accountStatus == FaceAccountStatus.blacklisted;
  bool get isSuspended => accountStatus == FaceAccountStatus.suspended;

  String get displayStatus {
    switch (accountStatus) {
      case FaceAccountStatus.active:
        return 'Actif';
      case FaceAccountStatus.suspended:
        return 'Suspendu';
      case FaceAccountStatus.blacklisted:
        return 'Blacklisté';
      case FaceAccountStatus.deleted:
        return 'Supprimé';
    }
  }
}

/// Résultat de correspondance de visage
class FaceMatch {
  final String userId;
  final String faceHash;
  final double similarityScore; // 0.0 - 1.0
  final FaceAccountStatus accountStatus;
  final String? blacklistId;
  final DateTime registeredAt;

  FaceMatch({
    required this.userId,
    required this.faceHash,
    required this.similarityScore,
    required this.accountStatus,
    this.blacklistId,
    required this.registeredAt,
  });

  bool get isHighMatch => similarityScore >= 0.85;
  bool get isMediumMatch => similarityScore >= 0.70 && similarityScore < 0.85;
  bool get isLowMatch => similarityScore < 0.70;

  bool get isBlacklisted => accountStatus == FaceAccountStatus.blacklisted;

  String get matchLevel {
    if (isHighMatch) return 'Élevée';
    if (isMediumMatch) return 'Moyenne';
    return 'Faible';
  }

  String get similarityPercentage =>
      '${(similarityScore * 100).toStringAsFixed(1)}%';
}

/// Résultat de recherche de visage
class FaceDuplicateCheckResult {
  final bool hasDuplicates;
  final List<FaceMatch> matches;
  final FaceMatch? bestMatch;
  final bool hasBlacklistedMatch;
  final List<String> blockedUserIds;

  FaceDuplicateCheckResult({
    required this.hasDuplicates,
    required this.matches,
    this.bestMatch,
    required this.hasBlacklistedMatch,
    required this.blockedUserIds,
  });

  bool get shouldBlock => hasBlacklistedMatch || hasDuplicates;

  String get blockReason {
    if (hasBlacklistedMatch) {
      return 'Visage associé à un compte blacklisté';
    }
    if (hasDuplicates) {
      return 'Visage déjà enregistré dans le système';
    }
    return '';
  }
}