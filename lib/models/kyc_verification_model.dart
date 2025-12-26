import 'package:cloud_firestore/cloud_firestore.dart';

/// Niveaux de risque KYC
enum RiskLevel {
  low,
  medium,
  high,
  critical,
}

/// Statut de vérification KYC
enum KYCStatus {
  pending,
  approved,
  rejected,
  investigating,
  needsInfo,
}

/// Modèle de données pour la vérification KYC avancée
class KYCVerificationModel {
  final String id;
  final String userId;
  final String userType; // vendeur | livreur
  final KYCStatus status;

  // Niveau 1: Identité
  final IdentityData identity;

  // Niveau 2: Biométrie
  final BiometricData? biometrics;

  // Niveau 3: Device
  final DeviceData? device;

  // Niveau 4: Contact & Mobile Money
  final ContactData? contact;

  // Niveau 5: Graph Analysis
  final ConnectionData? connections;

  // Niveau 6: Blacklist
  final BlacklistCheckData? blacklistCheck;

  // Niveau 7: Score de risque
  final RiskAssessment? riskAssessment;

  // Métadonnées
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? reviewNotes;
  final DateTime updatedAt;

  KYCVerificationModel({
    required this.id,
    required this.userId,
    required this.userType,
    required this.status,
    required this.identity,
    this.biometrics,
    this.device,
    this.contact,
    this.connections,
    this.blacklistCheck,
    this.riskAssessment,
    required this.submittedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.reviewNotes,
    required this.updatedAt,
  });

  /// Factory depuis Firestore
  factory KYCVerificationModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;

    return KYCVerificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userType: data['userType'] ?? '',
      status: KYCStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => KYCStatus.pending,
      ),
      identity: IdentityData.fromMap(data['identity'] ?? {}),
      biometrics: data['biometrics'] != null
          ? BiometricData.fromMap(data['biometrics'])
          : null,
      device: data['device'] != null
          ? DeviceData.fromMap(data['device'])
          : null,
      contact: data['contact'] != null
          ? ContactData.fromMap(data['contact'])
          : null,
      connections: data['connections'] != null
          ? ConnectionData.fromMap(data['connections'])
          : null,
      blacklistCheck: data['blacklistCheck'] != null
          ? BlacklistCheckData.fromMap(data['blacklistCheck'])
          : null,
      riskAssessment: data['riskAssessment'] != null
          ? RiskAssessment.fromMap(data['riskAssessment'])
          : null,
      submittedAt: (data['submittedAt'] as Timestamp).toDate(),
      reviewedAt: data['reviewedAt'] != null
          ? (data['reviewedAt'] as Timestamp).toDate()
          : null,
      reviewedBy: data['reviewedBy'],
      reviewNotes: data['reviewNotes'],
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Conversion vers Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userType': userType,
      'status': status.name,
      'identity': identity.toMap(),
      'biometrics': biometrics?.toMap(),
      'device': device?.toMap(),
      'contact': contact?.toMap(),
      'connections': connections?.toMap(),
      'blacklistCheck': blacklistCheck?.toMap(),
      'riskAssessment': riskAssessment?.toMap(),
      'submittedAt': Timestamp.fromDate(submittedAt),
      'reviewedAt':
          reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'reviewedBy': reviewedBy,
      'reviewNotes': reviewNotes,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// CopyWith
  KYCVerificationModel copyWith({
    String? id,
    String? userId,
    String? userType,
    KYCStatus? status,
    IdentityData? identity,
    BiometricData? biometrics,
    DeviceData? device,
    ContactData? contact,
    ConnectionData? connections,
    BlacklistCheckData? blacklistCheck,
    RiskAssessment? riskAssessment,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? reviewNotes,
    DateTime? updatedAt,
  }) {
    return KYCVerificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userType: userType ?? this.userType,
      status: status ?? this.status,
      identity: identity ?? this.identity,
      biometrics: biometrics ?? this.biometrics,
      device: device ?? this.device,
      contact: contact ?? this.contact,
      connections: connections ?? this.connections,
      blacklistCheck: blacklistCheck ?? this.blacklistCheck,
      riskAssessment: riskAssessment ?? this.riskAssessment,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewNotes: reviewNotes ?? this.reviewNotes,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Helpers
  bool get isApproved => status == KYCStatus.approved;
  bool get isRejected => status == KYCStatus.rejected;
  bool get isPending => status == KYCStatus.pending;
  bool get needsManualReview =>
      riskAssessment != null &&
      riskAssessment!.totalScore >= 50 &&
      riskAssessment!.totalScore < 80;
  bool get shouldAutoApprove =>
      riskAssessment != null && riskAssessment!.totalScore >= 80;
  bool get shouldAutoReject =>
      riskAssessment != null && riskAssessment!.totalScore < 50;
}

/// Niveau 1: Données d'identité
class IdentityData {
  final String cniNumber;
  final String firstName;
  final String lastName;
  final DateTime dateOfBirth;
  final String placeOfBirth;
  final CNIPhotos cniPhotos;
  final String selfieWithCni;
  final String proofOfAddress;
  final bool cniVerifiedByGov;
  final DateTime? cniExpiryDate;

  IdentityData({
    required this.cniNumber,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.placeOfBirth,
    required this.cniPhotos,
    required this.selfieWithCni,
    required this.proofOfAddress,
    this.cniVerifiedByGov = false,
    this.cniExpiryDate,
  });

  factory IdentityData.fromMap(Map<String, dynamic> map) {
    return IdentityData(
      cniNumber: map['cniNumber'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      dateOfBirth: map['dateOfBirth'] != null
          ? (map['dateOfBirth'] as Timestamp).toDate()
          : DateTime.now(),
      placeOfBirth: map['placeOfBirth'] ?? '',
      cniPhotos: CNIPhotos.fromMap(map['cniPhotos'] ?? {}),
      selfieWithCni: map['selfieWithCni'] ?? '',
      proofOfAddress: map['proofOfAddress'] ?? '',
      cniVerifiedByGov: map['cniVerifiedByGov'] ?? false,
      cniExpiryDate: map['cniExpiryDate'] != null
          ? (map['cniExpiryDate'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cniNumber': cniNumber,
      'firstName': firstName,
      'lastName': lastName,
      'dateOfBirth': Timestamp.fromDate(dateOfBirth),
      'placeOfBirth': placeOfBirth,
      'cniPhotos': cniPhotos.toMap(),
      'selfieWithCni': selfieWithCni,
      'proofOfAddress': proofOfAddress,
      'cniVerifiedByGov': cniVerifiedByGov,
      'cniExpiryDate':
          cniExpiryDate != null ? Timestamp.fromDate(cniExpiryDate!) : null,
    };
  }

  bool get isCNIExpired =>
      cniExpiryDate != null && cniExpiryDate!.isBefore(DateTime.now());
}

class CNIPhotos {
  final String front;
  final String back;

  CNIPhotos({required this.front, required this.back});

  factory CNIPhotos.fromMap(Map<String, dynamic> map) {
    return CNIPhotos(
      front: map['front'] ?? '',
      back: map['back'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'front': front,
      'back': back,
    };
  }
}

/// Niveau 2: Données biométriques
class BiometricData {
  final String faceHash;
  final List<double> faceEmbedding;
  final double livenessScore;
  final double cniPhotoSimilarity;
  final List<String> duplicateFacesFound;
  final bool faceVerified;

  BiometricData({
    required this.faceHash,
    required this.faceEmbedding,
    required this.livenessScore,
    required this.cniPhotoSimilarity,
    this.duplicateFacesFound = const [],
    required this.faceVerified,
  });

  factory BiometricData.fromMap(Map<String, dynamic> map) {
    return BiometricData(
      faceHash: map['faceHash'] ?? '',
      faceEmbedding: List<double>.from(map['faceEmbedding'] ?? []),
      livenessScore: (map['livenessScore'] ?? 0.0).toDouble(),
      cniPhotoSimilarity: (map['cniPhotoSimilarity'] ?? 0.0).toDouble(),
      duplicateFacesFound:
          List<String>.from(map['duplicateFacesFound'] ?? []),
      faceVerified: map['faceVerified'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'faceHash': faceHash,
      'faceEmbedding': faceEmbedding,
      'livenessScore': livenessScore,
      'cniPhotoSimilarity': cniPhotoSimilarity,
      'duplicateFacesFound': duplicateFacesFound,
      'faceVerified': faceVerified,
    };
  }

  bool get hasDuplicates => duplicateFacesFound.isNotEmpty;
  bool get passedLivenessCheck => livenessScore >= 0.8;
  bool get matchesCNIPhoto => cniPhotoSimilarity >= 0.85;
}

/// Niveau 3: Données appareil
class DeviceData {
  final String deviceId;
  final String deviceModel;
  final String osVersion;
  final String appVersion;
  final String ipAddress;
  final String carrier;
  final String simSerial;
  final String installationId;
  final DateTime firstSeenDate;
  final int deviceRiskScore;
  final List<String> previousUsersOnDevice;

  DeviceData({
    required this.deviceId,
    required this.deviceModel,
    required this.osVersion,
    required this.appVersion,
    required this.ipAddress,
    required this.carrier,
    required this.simSerial,
    required this.installationId,
    required this.firstSeenDate,
    required this.deviceRiskScore,
    this.previousUsersOnDevice = const [],
  });

  factory DeviceData.fromMap(Map<String, dynamic> map) {
    return DeviceData(
      deviceId: map['deviceId'] ?? '',
      deviceModel: map['deviceModel'] ?? '',
      osVersion: map['osVersion'] ?? '',
      appVersion: map['appVersion'] ?? '',
      ipAddress: map['ipAddress'] ?? '',
      carrier: map['carrier'] ?? '',
      simSerial: map['simSerial'] ?? '',
      installationId: map['installationId'] ?? '',
      firstSeenDate: map['firstSeenDate'] != null
          ? (map['firstSeenDate'] as Timestamp).toDate()
          : DateTime.now(),
      deviceRiskScore: map['deviceRiskScore'] ?? 0,
      previousUsersOnDevice:
          List<String>.from(map['previousUsersOnDevice'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'deviceId': deviceId,
      'deviceModel': deviceModel,
      'osVersion': osVersion,
      'appVersion': appVersion,
      'ipAddress': ipAddress,
      'carrier': carrier,
      'simSerial': simSerial,
      'installationId': installationId,
      'firstSeenDate': Timestamp.fromDate(firstSeenDate),
      'deviceRiskScore': deviceRiskScore,
      'previousUsersOnDevice': previousUsersOnDevice,
    };
  }

  bool get isDeviceReused => previousUsersOnDevice.isNotEmpty;
  bool get isHighRisk => deviceRiskScore < 5;
}

/// Niveau 4: Données contact et Mobile Money
class ContactData {
  final String phoneNumber;
  final bool phoneVerified;
  final DateTime? otpVerifiedAt;
  final String mobileMoneyProvider;
  final String mobileMoneyAccount;
  final String mobileMoneyName;
  final bool mobileMoneyVerified;
  final int mobileMoneyAccountAge;
  final double nameMatchScore;
  final int phoneRiskScore;

  ContactData({
    required this.phoneNumber,
    required this.phoneVerified,
    this.otpVerifiedAt,
    required this.mobileMoneyProvider,
    required this.mobileMoneyAccount,
    required this.mobileMoneyName,
    required this.mobileMoneyVerified,
    required this.mobileMoneyAccountAge,
    required this.nameMatchScore,
    required this.phoneRiskScore,
  });

  factory ContactData.fromMap(Map<String, dynamic> map) {
    return ContactData(
      phoneNumber: map['phoneNumber'] ?? '',
      phoneVerified: map['phoneVerified'] ?? false,
      otpVerifiedAt: map['otpVerifiedAt'] != null
          ? (map['otpVerifiedAt'] as Timestamp).toDate()
          : null,
      mobileMoneyProvider: map['mobileMoneyProvider'] ?? '',
      mobileMoneyAccount: map['mobileMoneyAccount'] ?? '',
      mobileMoneyName: map['mobileMoneyName'] ?? '',
      mobileMoneyVerified: map['mobileMoneyVerified'] ?? false,
      mobileMoneyAccountAge: map['mobileMoneyAccountAge'] ?? 0,
      nameMatchScore: (map['nameMatchScore'] ?? 0.0).toDouble(),
      phoneRiskScore: map['phoneRiskScore'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'phoneNumber': phoneNumber,
      'phoneVerified': phoneVerified,
      'otpVerifiedAt':
          otpVerifiedAt != null ? Timestamp.fromDate(otpVerifiedAt!) : null,
      'mobileMoneyProvider': mobileMoneyProvider,
      'mobileMoneyAccount': mobileMoneyAccount,
      'mobileMoneyName': mobileMoneyName,
      'mobileMoneyVerified': mobileMoneyVerified,
      'mobileMoneyAccountAge': mobileMoneyAccountAge,
      'nameMatchScore': nameMatchScore,
      'phoneRiskScore': phoneRiskScore,
    };
  }

  bool get hasOldMobileMoneyAccount => mobileMoneyAccountAge >= 6;
  bool get nameMatchesWell => nameMatchScore >= 0.85;
}

/// Niveau 5: Données de connexions
class ConnectionData {
  final List<String> suspiciousLinks;
  final List<String> sharedAddresses;
  final List<String> similarBehaviorAccounts;
  final int relationshipScore;
  final int graphRiskScore;

  ConnectionData({
    this.suspiciousLinks = const [],
    this.sharedAddresses = const [],
    this.similarBehaviorAccounts = const [],
    required this.relationshipScore,
    required this.graphRiskScore,
  });

  factory ConnectionData.fromMap(Map<String, dynamic> map) {
    return ConnectionData(
      suspiciousLinks: List<String>.from(map['suspiciousLinks'] ?? []),
      sharedAddresses: List<String>.from(map['sharedAddresses'] ?? []),
      similarBehaviorAccounts:
          List<String>.from(map['similarBehaviorAccounts'] ?? []),
      relationshipScore: map['relationshipScore'] ?? 0,
      graphRiskScore: map['graphRiskScore'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'suspiciousLinks': suspiciousLinks,
      'sharedAddresses': sharedAddresses,
      'similarBehaviorAccounts': similarBehaviorAccounts,
      'relationshipScore': relationshipScore,
      'graphRiskScore': graphRiskScore,
    };
  }

  bool get hasSuspiciousConnections => suspiciousLinks.isNotEmpty;
}

/// Niveau 6: Vérification blacklist
class BlacklistCheckData {
  final bool isBlacklisted;
  final List<String> blacklistMatches;
  final double outstandingDebt;
  final bool canReconcile;
  final int blacklistRiskScore;

  BlacklistCheckData({
    required this.isBlacklisted,
    this.blacklistMatches = const [],
    required this.outstandingDebt,
    required this.canReconcile,
    required this.blacklistRiskScore,
  });

  factory BlacklistCheckData.fromMap(Map<String, dynamic> map) {
    return BlacklistCheckData(
      isBlacklisted: map['isBlacklisted'] ?? false,
      blacklistMatches: List<String>.from(map['blacklistMatches'] ?? []),
      outstandingDebt: (map['outstandingDebt'] ?? 0.0).toDouble(),
      canReconcile: map['canReconcile'] ?? false,
      blacklistRiskScore: map['blacklistRiskScore'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isBlacklisted': isBlacklisted,
      'blacklistMatches': blacklistMatches,
      'outstandingDebt': outstandingDebt,
      'canReconcile': canReconcile,
      'blacklistRiskScore': blacklistRiskScore,
    };
  }

  bool get hasDebt => outstandingDebt > 0;
}

/// Niveau 7: Évaluation des risques
class RiskAssessment {
  final int totalScore;
  final bool autoApproved;
  final bool requiresManualReview;
  final RiskLevel riskLevel;
  final ScoreBreakdown scoreBreakdown;
  final List<String> flags;
  final String recommendations;

  RiskAssessment({
    required this.totalScore,
    required this.autoApproved,
    required this.requiresManualReview,
    required this.riskLevel,
    required this.scoreBreakdown,
    this.flags = const [],
    required this.recommendations,
  });

  factory RiskAssessment.fromMap(Map<String, dynamic> map) {
    return RiskAssessment(
      totalScore: map['totalScore'] ?? 0,
      autoApproved: map['autoApproved'] ?? false,
      requiresManualReview: map['requiresManualReview'] ?? false,
      riskLevel: RiskLevel.values.firstWhere(
        (e) => e.name == map['riskLevel'],
        orElse: () => RiskLevel.medium,
      ),
      scoreBreakdown: ScoreBreakdown.fromMap(map['scoreBreakdown'] ?? {}),
      flags: List<String>.from(map['flags'] ?? []),
      recommendations: map['recommendations'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalScore': totalScore,
      'autoApproved': autoApproved,
      'requiresManualReview': requiresManualReview,
      'riskLevel': riskLevel.name,
      'scoreBreakdown': scoreBreakdown.toMap(),
      'flags': flags,
      'recommendations': recommendations,
    };
  }
}

class ScoreBreakdown {
  final int identity;
  final int biometrics;
  final int device;
  final int contact;
  final int connections;
  final int blacklist;
  final int completeness;
  final int malus;

  ScoreBreakdown({
    required this.identity,
    required this.biometrics,
    required this.device,
    required this.contact,
    required this.connections,
    required this.blacklist,
    required this.completeness,
    required this.malus,
  });

  factory ScoreBreakdown.fromMap(Map<String, dynamic> map) {
    return ScoreBreakdown(
      identity: map['identity'] ?? 0,
      biometrics: map['biometrics'] ?? 0,
      device: map['device'] ?? 0,
      contact: map['contact'] ?? 0,
      connections: map['connections'] ?? 0,
      blacklist: map['blacklist'] ?? 0,
      completeness: map['completeness'] ?? 0,
      malus: map['malus'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'identity': identity,
      'biometrics': biometrics,
      'device': device,
      'contact': contact,
      'connections': connections,
      'blacklist': blacklist,
      'completeness': completeness,
      'malus': malus,
    };
  }
}