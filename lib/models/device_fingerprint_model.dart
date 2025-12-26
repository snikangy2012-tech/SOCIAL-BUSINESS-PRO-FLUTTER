import 'package:cloud_firestore/cloud_firestore.dart';

/// Niveau de risque appareil
enum DeviceRiskLevel {
  safe,
  low,
  medium,
  high,
  critical,
}

/// Informations d'un utilisateur sur un appareil
class DeviceUser {
  final String userId;
  final DateTime firstUsed;
  final DateTime lastUsed;
  final String accountStatus; // active | suspended | blacklisted

  DeviceUser({
    required this.userId,
    required this.firstUsed,
    required this.lastUsed,
    required this.accountStatus,
  });

  factory DeviceUser.fromMap(Map<String, dynamic> map) {
    return DeviceUser(
      userId: map['userId'] ?? '',
      firstUsed: (map['firstUsed'] as Timestamp).toDate(),
      lastUsed: (map['lastUsed'] as Timestamp).toDate(),
      accountStatus: map['accountStatus'] ?? 'active',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'firstUsed': Timestamp.fromDate(firstUsed),
      'lastUsed': Timestamp.fromDate(lastUsed),
      'accountStatus': accountStatus,
    };
  }

  bool get isActive => accountStatus == 'active';
  bool get isBlacklisted => accountStatus == 'blacklisted';
}

/// Modèle de registre d'appareil
class DeviceFingerprintModel {
  final String id; // deviceId
  final List<DeviceUser> associatedUsers;
  final DeviceRiskLevel riskLevel;
  final DateTime? flaggedAt;
  final String? flagReason;
  final DateTime firstSeenAt;
  final DateTime lastSeenAt;
  final Map<String, dynamic> deviceInfo;

  DeviceFingerprintModel({
    required this.id,
    this.associatedUsers = const [],
    required this.riskLevel,
    this.flaggedAt,
    this.flagReason,
    required this.firstSeenAt,
    required this.lastSeenAt,
    this.deviceInfo = const {},
  });

  /// Factory depuis Firestore
  factory DeviceFingerprintModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;

    return DeviceFingerprintModel(
      id: doc.id,
      associatedUsers: (data['associatedUsers'] as List<dynamic>?)
              ?.map((e) => DeviceUser.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      riskLevel: DeviceRiskLevel.values.firstWhere(
        (e) => e.name == data['riskLevel'],
        orElse: () => DeviceRiskLevel.safe,
      ),
      flaggedAt: data['flaggedAt'] != null
          ? (data['flaggedAt'] as Timestamp).toDate()
          : null,
      flagReason: data['flagReason'],
      firstSeenAt: (data['firstSeenAt'] as Timestamp).toDate(),
      lastSeenAt: (data['lastSeenAt'] as Timestamp).toDate(),
      deviceInfo: Map<String, dynamic>.from(data['deviceInfo'] ?? {}),
    );
  }

  /// Conversion vers Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'associatedUsers': associatedUsers.map((u) => u.toMap()).toList(),
      'riskLevel': riskLevel.name,
      'flaggedAt': flaggedAt != null ? Timestamp.fromDate(flaggedAt!) : null,
      'flagReason': flagReason,
      'firstSeenAt': Timestamp.fromDate(firstSeenAt),
      'lastSeenAt': Timestamp.fromDate(lastSeenAt),
      'deviceInfo': deviceInfo,
    };
  }

  /// CopyWith
  DeviceFingerprintModel copyWith({
    String? id,
    List<DeviceUser>? associatedUsers,
    DeviceRiskLevel? riskLevel,
    DateTime? flaggedAt,
    String? flagReason,
    DateTime? firstSeenAt,
    DateTime? lastSeenAt,
    Map<String, dynamic>? deviceInfo,
  }) {
    return DeviceFingerprintModel(
      id: id ?? this.id,
      associatedUsers: associatedUsers ?? this.associatedUsers,
      riskLevel: riskLevel ?? this.riskLevel,
      flaggedAt: flaggedAt ?? this.flaggedAt,
      flagReason: flagReason ?? this.flagReason,
      firstSeenAt: firstSeenAt ?? this.firstSeenAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      deviceInfo: deviceInfo ?? this.deviceInfo,
    );
  }

  /// Helpers
  bool get isFlagged => flaggedAt != null;
  bool get isNewDevice => associatedUsers.isEmpty;
  bool get hasMultipleUsers => associatedUsers.length > 1;
  bool get hasBlacklistedUsers =>
      associatedUsers.any((u) => u.isBlacklisted);

  int get activeUserCount =>
      associatedUsers.where((u) => u.isActive).length;

  String get displayRiskLevel {
    switch (riskLevel) {
      case DeviceRiskLevel.safe:
        return 'Sécurisé';
      case DeviceRiskLevel.low:
        return 'Risque faible';
      case DeviceRiskLevel.medium:
        return 'Risque moyen';
      case DeviceRiskLevel.high:
        return 'Risque élevé';
      case DeviceRiskLevel.critical:
        return 'Risque critique';
    }
  }

  /// Calculer le score de risque basé sur les critères
  int calculateRiskScore() {
    int score = 10; // Score initial maximum

    // Pénalité si multiple utilisateurs
    if (associatedUsers.length > 3) {
      score -= 5;
    } else if (associatedUsers.length > 1) {
      score -= 2;
    }

    // Pénalité si utilisateurs blacklistés
    if (hasBlacklistedUsers) {
      score -= 5;
    }

    // Pénalité si flaggé
    if (isFlagged) {
      score -= 3;
    }

    return score.clamp(0, 10);
  }
}

/// Empreinte appareil collectée
class DeviceInfo {
  final String deviceId;
  final String model;
  final String manufacturer;
  final String osVersion;
  final String platform;
  final String appVersion;
  final String? androidId;
  final String? iosIdentifierForVendor;
  final bool isPhysicalDevice;

  DeviceInfo({
    required this.deviceId,
    required this.model,
    required this.manufacturer,
    required this.osVersion,
    required this.platform,
    required this.appVersion,
    this.androidId,
    this.iosIdentifierForVendor,
    required this.isPhysicalDevice,
  });

  Map<String, dynamic> toMap() {
    return {
      'deviceId': deviceId,
      'model': model,
      'manufacturer': manufacturer,
      'osVersion': osVersion,
      'platform': platform,
      'appVersion': appVersion,
      'androidId': androidId,
      'iosIdentifierForVendor': iosIdentifierForVendor,
      'isPhysicalDevice': isPhysicalDevice,
    };
  }

  factory DeviceInfo.fromMap(Map<String, dynamic> map) {
    return DeviceInfo(
      deviceId: map['deviceId'] ?? '',
      model: map['model'] ?? '',
      manufacturer: map['manufacturer'] ?? '',
      osVersion: map['osVersion'] ?? '',
      platform: map['platform'] ?? '',
      appVersion: map['appVersion'] ?? '',
      androidId: map['androidId'],
      iosIdentifierForVendor: map['iosIdentifierForVendor'],
      isPhysicalDevice: map['isPhysicalDevice'] ?? true,
    );
  }
}

/// Résultat d'évaluation de risque d'appareil
class DeviceRiskAssessment {
  final bool isNewDevice;
  final bool hasRiskFactors;
  final List<String> riskFactors;
  final int riskScore; // 0-10, 10 = safe
  final DeviceRiskLevel riskLevel;
  final List<DeviceUser> previousUsers;
  final String recommendation;

  DeviceRiskAssessment({
    required this.isNewDevice,
    required this.hasRiskFactors,
    required this.riskFactors,
    required this.riskScore,
    required this.riskLevel,
    required this.previousUsers,
    required this.recommendation,
  });

  bool get isSafe => riskLevel == DeviceRiskLevel.safe;
  bool get shouldBlock =>
      riskLevel == DeviceRiskLevel.critical ||
      riskLevel == DeviceRiskLevel.high;
}