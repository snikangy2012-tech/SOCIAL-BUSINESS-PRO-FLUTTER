import 'package:cloud_firestore/cloud_firestore.dart';

/// Type d'entrée blacklist
enum BlacklistType {
  commissionDebt, // Dette de commission
  fraud, // Fraude détectée
  policyViolation, // Violation de politique
  identity, // Usurpation d'identité
  other, // Autre
}

/// Statut blacklist
enum BlacklistStatus {
  active, // Active
  reconciled, // Réconciliée (dette payée)
  permanent, // Permanente (fraude grave)
  underInvestigation, // En investigation
}

/// Sévérité
enum BlacklistSeverity {
  low,
  medium,
  high,
  critical,
}

/// Modèle d'entrée dans la blacklist
class BlacklistEntryModel {
  final String id;
  final BlacklistType type;

  // Identifiants multiples (pour détection multi-critères)
  final String? cniNumber;
  final String? faceHash;
  final String? phoneNumber;
  final String? mobileMoneyAccount;
  final List<String> deviceIds;

  // Détails utilisateur original
  final String userId;
  final String userName;
  final String userType; // vendeur | livreur

  // Détails de l'incident
  final String reason;
  final double amountDue;
  final String currency;
  final List<String> ordersInvolved;
  final List<String> deliveriesInvolved;

  // Dates
  final DateTime listedAt;
  final String listedBy; // Admin ID

  // Réconciliation
  final bool canReconcile;
  final DateTime? reconciliationDeadline;
  final double reconciliationAmount; // Avec pénalité
  final DateTime? reconciledAt;
  final String? reconciledBy;
  final String? paymentProof;

  // Statut
  final BlacklistStatus status;
  final BlacklistSeverity severity;

  // Métadonnées
  final String notes;
  final Map<String, dynamic> metadata;
  final DateTime updatedAt;

  BlacklistEntryModel({
    required this.id,
    required this.type,
    this.cniNumber,
    this.faceHash,
    this.phoneNumber,
    this.mobileMoneyAccount,
    this.deviceIds = const [],
    required this.userId,
    required this.userName,
    required this.userType,
    required this.reason,
    required this.amountDue,
    this.currency = 'FCFA',
    this.ordersInvolved = const [],
    this.deliveriesInvolved = const [],
    required this.listedAt,
    required this.listedBy,
    this.canReconcile = true,
    this.reconciliationDeadline,
    required this.reconciliationAmount,
    this.reconciledAt,
    this.reconciledBy,
    this.paymentProof,
    required this.status,
    required this.severity,
    this.notes = '',
    this.metadata = const {},
    required this.updatedAt,
  });

  /// Factory depuis Firestore
  factory BlacklistEntryModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;

    return BlacklistEntryModel(
      id: doc.id,
      type: BlacklistType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => BlacklistType.other,
      ),
      cniNumber: data['cniNumber'],
      faceHash: data['faceHash'],
      phoneNumber: data['phoneNumber'],
      mobileMoneyAccount: data['mobileMoneyAccount'],
      deviceIds: List<String>.from(data['deviceIds'] ?? []),
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userType: data['userType'] ?? '',
      reason: data['reason'] ?? '',
      amountDue: (data['amountDue'] ?? 0.0).toDouble(),
      currency: data['currency'] ?? 'FCFA',
      ordersInvolved: List<String>.from(data['ordersInvolved'] ?? []),
      deliveriesInvolved: List<String>.from(data['deliveriesInvolved'] ?? []),
      listedAt: (data['listedAt'] as Timestamp).toDate(),
      listedBy: data['listedBy'] ?? '',
      canReconcile: data['canReconcile'] ?? false,
      reconciliationDeadline: data['reconciliationDeadline'] != null
          ? (data['reconciliationDeadline'] as Timestamp).toDate()
          : null,
      reconciliationAmount: (data['reconciliationAmount'] ?? 0.0).toDouble(),
      reconciledAt: data['reconciledAt'] != null
          ? (data['reconciledAt'] as Timestamp).toDate()
          : null,
      reconciledBy: data['reconciledBy'],
      paymentProof: data['paymentProof'],
      status: BlacklistStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => BlacklistStatus.active,
      ),
      severity: BlacklistSeverity.values.firstWhere(
        (e) => e.name == data['severity'],
        orElse: () => BlacklistSeverity.medium,
      ),
      notes: data['notes'] ?? '',
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Conversion vers Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'cniNumber': cniNumber,
      'faceHash': faceHash,
      'phoneNumber': phoneNumber,
      'mobileMoneyAccount': mobileMoneyAccount,
      'deviceIds': deviceIds,
      'userId': userId,
      'userName': userName,
      'userType': userType,
      'reason': reason,
      'amountDue': amountDue,
      'currency': currency,
      'ordersInvolved': ordersInvolved,
      'deliveriesInvolved': deliveriesInvolved,
      'listedAt': Timestamp.fromDate(listedAt),
      'listedBy': listedBy,
      'canReconcile': canReconcile,
      'reconciliationDeadline': reconciliationDeadline != null
          ? Timestamp.fromDate(reconciliationDeadline!)
          : null,
      'reconciliationAmount': reconciliationAmount,
      'reconciledAt':
          reconciledAt != null ? Timestamp.fromDate(reconciledAt!) : null,
      'reconciledBy': reconciledBy,
      'paymentProof': paymentProof,
      'status': status.name,
      'severity': severity.name,
      'notes': notes,
      'metadata': metadata,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// CopyWith
  BlacklistEntryModel copyWith({
    String? id,
    BlacklistType? type,
    String? cniNumber,
    String? faceHash,
    String? phoneNumber,
    String? mobileMoneyAccount,
    List<String>? deviceIds,
    String? userId,
    String? userName,
    String? userType,
    String? reason,
    double? amountDue,
    String? currency,
    List<String>? ordersInvolved,
    List<String>? deliveriesInvolved,
    DateTime? listedAt,
    String? listedBy,
    bool? canReconcile,
    DateTime? reconciliationDeadline,
    double? reconciliationAmount,
    DateTime? reconciledAt,
    String? reconciledBy,
    String? paymentProof,
    BlacklistStatus? status,
    BlacklistSeverity? severity,
    String? notes,
    Map<String, dynamic>? metadata,
    DateTime? updatedAt,
  }) {
    return BlacklistEntryModel(
      id: id ?? this.id,
      type: type ?? this.type,
      cniNumber: cniNumber ?? this.cniNumber,
      faceHash: faceHash ?? this.faceHash,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      mobileMoneyAccount: mobileMoneyAccount ?? this.mobileMoneyAccount,
      deviceIds: deviceIds ?? this.deviceIds,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userType: userType ?? this.userType,
      reason: reason ?? this.reason,
      amountDue: amountDue ?? this.amountDue,
      currency: currency ?? this.currency,
      ordersInvolved: ordersInvolved ?? this.ordersInvolved,
      deliveriesInvolved: deliveriesInvolved ?? this.deliveriesInvolved,
      listedAt: listedAt ?? this.listedAt,
      listedBy: listedBy ?? this.listedBy,
      canReconcile: canReconcile ?? this.canReconcile,
      reconciliationDeadline:
          reconciliationDeadline ?? this.reconciliationDeadline,
      reconciliationAmount: reconciliationAmount ?? this.reconciliationAmount,
      reconciledAt: reconciledAt ?? this.reconciledAt,
      reconciledBy: reconciledBy ?? this.reconciledBy,
      paymentProof: paymentProof ?? this.paymentProof,
      status: status ?? this.status,
      severity: severity ?? this.severity,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Helpers
  bool get isActive => status == BlacklistStatus.active;
  bool get isReconciled => status == BlacklistStatus.reconciled;
  bool get isPermanent => status == BlacklistStatus.permanent;

  bool get hasDeadlinePassed =>
      reconciliationDeadline != null &&
      reconciliationDeadline!.isBefore(DateTime.now());

  String get displayType {
    switch (type) {
      case BlacklistType.commissionDebt:
        return 'Dette de commission';
      case BlacklistType.fraud:
        return 'Fraude';
      case BlacklistType.policyViolation:
        return 'Violation de politique';
      case BlacklistType.identity:
        return "Usurpation d'identité";
      case BlacklistType.other:
        return 'Autre';
    }
  }

  String get displaySeverity {
    switch (severity) {
      case BlacklistSeverity.low:
        return 'Faible';
      case BlacklistSeverity.medium:
        return 'Moyenne';
      case BlacklistSeverity.high:
        return 'Élevée';
      case BlacklistSeverity.critical:
        return 'Critique';
    }
  }

  String get displayStatus {
    switch (status) {
      case BlacklistStatus.active:
        return 'Active';
      case BlacklistStatus.reconciled:
        return 'Réconciliée';
      case BlacklistStatus.permanent:
        return 'Permanente';
      case BlacklistStatus.underInvestigation:
        return 'En investigation';
    }
  }
}

/// Résultat de vérification blacklist
class BlacklistCheckResult {
  final bool isBlacklisted;
  final List<BlacklistEntryModel> matches;
  final double totalDebtAmount;
  final bool canReconcile;
  final List<String> blockedReasons;

  BlacklistCheckResult({
    required this.isBlacklisted,
    required this.matches,
    required this.totalDebtAmount,
    required this.canReconcile,
    required this.blockedReasons,
  });

  bool get hasDebt => totalDebtAmount > 0;
  bool get hasPermanentBlock =>
      matches.any((m) => m.status == BlacklistStatus.permanent);
  bool get hasActiveInvestigation =>
      matches.any((m) => m.status == BlacklistStatus.underInvestigation);
}