import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/device_fingerprint_model.dart';

/// Service de device fingerprinting
/// Collecte et analyse les empreintes d'appareils pour détecter les comptes multiples
class DeviceFingerprintService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  static const String _deviceRegistryCollection = 'device_registry';

  /// Collecter les informations de l'appareil
  static Future<DeviceInfo> collectDeviceInfo() async {
    try {
      debugPrint('📱 Collecting device information...');

      final packageInfo = await PackageInfo.fromPlatform();
      String deviceId = '';
      String model = '';
      String manufacturer = '';
      String osVersion = '';
      String platform = '';
      String? androidId;
      String? iosIdentifierForVendor;
      bool isPhysicalDevice = true;

      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        deviceId = androidInfo.id; // Android ID
        model = androidInfo.model;
        manufacturer = androidInfo.manufacturer;
        osVersion = 'Android ${androidInfo.version.release}';
        platform = 'Android';
        androidId = androidInfo.id;
        isPhysicalDevice = androidInfo.isPhysicalDevice;

        debugPrint('Android Device:');
        debugPrint('  - ID: ${deviceId.substring(0, 10)}...');
        debugPrint('  - Model: $model');
        debugPrint('  - Manufacturer: $manufacturer');
        debugPrint('  - OS: $osVersion');
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? '';
        model = iosInfo.model;
        manufacturer = 'Apple';
        osVersion = 'iOS ${iosInfo.systemVersion}';
        platform = 'iOS';
        iosIdentifierForVendor = iosInfo.identifierForVendor;
        isPhysicalDevice = iosInfo.isPhysicalDevice;

        debugPrint('iOS Device:');
        debugPrint('  - ID: ${deviceId.substring(0, 10)}...');
        debugPrint('  - Model: $model');
        debugPrint('  - OS: $osVersion');
      }

      final deviceInfo = DeviceInfo(
        deviceId: deviceId,
        model: model,
        manufacturer: manufacturer,
        osVersion: osVersion,
        platform: platform,
        appVersion: packageInfo.version,
        androidId: androidId,
        iosIdentifierForVendor: iosIdentifierForVendor,
        isPhysicalDevice: isPhysicalDevice,
      );

      debugPrint('✅ Device info collected');
      return deviceInfo;
    } catch (e) {
      debugPrint('❌ Error collecting device info: $e');
      rethrow;
    }
  }

  /// Vérifier l'appareil dans le registre
  static Future<DeviceRiskAssessment> checkDeviceRegistry(
    String deviceId,
    String userId,
  ) async {
    try {
      debugPrint('🔍 Checking device registry for: ${deviceId.substring(0, 10)}...');

      final doc = await _firestore
          .collection(_deviceRegistryCollection)
          .doc(deviceId)
          .get()
          .timeout(const Duration(seconds: 10));

      if (!doc.exists) {
        // Nouvel appareil
        debugPrint('✅ New device detected');
        return DeviceRiskAssessment(
          isNewDevice: true,
          hasRiskFactors: false,
          riskFactors: [],
          riskScore: 10, // Score maximum pour nouvel appareil
          riskLevel: DeviceRiskLevel.safe,
          previousUsers: [],
          recommendation: 'Nouvel appareil - Aucun risque détecté',
        );
      }

      // Appareil existant
      final deviceModel = DeviceFingerprintModel.fromFirestore(doc);

      // Vérifier si l'utilisateur est déjà enregistré sur cet appareil
      final isExistingUser = deviceModel.associatedUsers
          .any((user) => user.userId == userId);

      if (isExistingUser) {
        debugPrint('✅ Existing user on known device');
        return DeviceRiskAssessment(
          isNewDevice: false,
          hasRiskFactors: false,
          riskFactors: [],
          riskScore: deviceModel.calculateRiskScore(),
          riskLevel: deviceModel.riskLevel,
          previousUsers: deviceModel.associatedUsers,
          recommendation: 'Utilisateur connu sur appareil connu',
        );
      }

      // Nouvel utilisateur sur appareil existant - ANALYSE RISQUE
      final riskFactors = <String>[];
      int riskScore = 10;

      // Facteur 1: Nombre d'utilisateurs sur l'appareil
      if (deviceModel.associatedUsers.length >= 3) {
        riskFactors.add('Plus de 3 utilisateurs sur cet appareil');
        riskScore -= 5;
      } else if (deviceModel.associatedUsers.length > 1) {
        riskFactors.add('Appareil partagé (${deviceModel.associatedUsers.length} utilisateurs)');
        riskScore -= 2;
      }

      // Facteur 2: Utilisateurs blacklistés
      if (deviceModel.hasBlacklistedUsers) {
        riskFactors.add('Appareil lié à un compte blacklisté');
        riskScore -= 5;
      }

      // Facteur 3: Appareil déjà flaggé
      if (deviceModel.isFlagged) {
        riskFactors.add('Appareil précédemment signalé: ${deviceModel.flagReason}');
        riskScore -= 3;
      }

      // Facteur 4: Utilisateurs suspendus
      final suspendedCount = deviceModel.associatedUsers
          .where((u) => u.accountStatus == 'suspended')
          .length;
      if (suspendedCount > 0) {
        riskFactors.add('$suspendedCount compte(s) suspendu(s) sur cet appareil');
        riskScore -= 2;
      }

      riskScore = riskScore.clamp(0, 10);

      // Déterminer le niveau de risque
      DeviceRiskLevel riskLevel;
      if (riskScore >= 8) {
        riskLevel = DeviceRiskLevel.safe;
      } else if (riskScore >= 6) {
        riskLevel = DeviceRiskLevel.low;
      } else if (riskScore >= 4) {
        riskLevel = DeviceRiskLevel.medium;
      } else if (riskScore >= 2) {
        riskLevel = DeviceRiskLevel.high;
      } else {
        riskLevel = DeviceRiskLevel.critical;
      }

      // Recommandation
      String recommendation;
      if (riskLevel == DeviceRiskLevel.safe || riskLevel == DeviceRiskLevel.low) {
        recommendation = 'Risque faible - Approbation possible';
      } else if (riskLevel == DeviceRiskLevel.medium) {
        recommendation = 'Risque moyen - Revue manuelle recommandée';
      } else {
        recommendation = 'Risque élevé - Investigation requise';
      }

      debugPrint('✅ Device risk assessment complete:');
      debugPrint('  - Risk score: $riskScore/10');
      debugPrint('  - Risk level: ${riskLevel.name}');
      debugPrint('  - Risk factors: ${riskFactors.length}');

      return DeviceRiskAssessment(
        isNewDevice: false,
        hasRiskFactors: riskFactors.isNotEmpty,
        riskFactors: riskFactors,
        riskScore: riskScore,
        riskLevel: riskLevel,
        previousUsers: deviceModel.associatedUsers,
        recommendation: recommendation,
      );
    } catch (e) {
      debugPrint('❌ Error checking device registry: $e');
      // En cas d'erreur, retourner un résultat neutre
      return DeviceRiskAssessment(
        isNewDevice: true,
        hasRiskFactors: false,
        riskFactors: [],
        riskScore: 5,
        riskLevel: DeviceRiskLevel.medium,
        previousUsers: [],
        recommendation: 'Erreur lors de la vérification - Revue manuelle requise',
      );
    }
  }

  /// Enregistrer un nouvel appareil ou mettre à jour
  static Future<void> registerDevice(
    String deviceId,
    String userId,
    DeviceInfo deviceInfo,
  ) async {
    try {
      debugPrint('📝 Registering device: ${deviceId.substring(0, 10)}...');

      final docRef =
          _firestore.collection(_deviceRegistryCollection).doc(deviceId);
      final doc = await docRef.get();

      final now = DateTime.now();

      if (!doc.exists) {
        // Nouvel appareil
        final newDevice = DeviceFingerprintModel(
          id: deviceId,
          associatedUsers: [
            DeviceUser(
              userId: userId,
              firstUsed: now,
              lastUsed: now,
              accountStatus: 'active',
            ),
          ],
          riskLevel: DeviceRiskLevel.safe,
          firstSeenAt: now,
          lastSeenAt: now,
          deviceInfo: deviceInfo.toMap(),
        );

        await docRef.set(newDevice.toMap());
        debugPrint('✅ New device registered');
      } else {
        // Appareil existant - ajouter utilisateur ou mettre à jour
        final device = DeviceFingerprintModel.fromFirestore(doc);

        final existingUserIndex = device.associatedUsers
            .indexWhere((u) => u.userId == userId);

        List<DeviceUser> updatedUsers;

        if (existingUserIndex != -1) {
          // Utilisateur existant - mettre à jour lastUsed
          updatedUsers = List.from(device.associatedUsers);
          updatedUsers[existingUserIndex] = device.associatedUsers[existingUserIndex].copyWith(
            lastUsed: now,
          );
        } else {
          // Nouvel utilisateur sur appareil existant
          updatedUsers = [
            ...device.associatedUsers,
            DeviceUser(
              userId: userId,
              firstUsed: now,
              lastUsed: now,
              accountStatus: 'active',
            ),
          ];
        }

        // Recalculer le risk level
        final userCount = updatedUsers.length;
        DeviceRiskLevel newRiskLevel;
        if (userCount == 1) {
          newRiskLevel = DeviceRiskLevel.safe;
        } else if (userCount == 2) {
          newRiskLevel = DeviceRiskLevel.low;
        } else if (userCount == 3) {
          newRiskLevel = DeviceRiskLevel.medium;
        } else {
          newRiskLevel = DeviceRiskLevel.high;
        }

        await docRef.update({
          'associatedUsers': updatedUsers.map((u) => u.toMap()).toList(),
          'riskLevel': newRiskLevel.name,
          'lastSeenAt': Timestamp.fromDate(now),
        });

        debugPrint('✅ Device registry updated');
      }
    } catch (e) {
      debugPrint('❌ Error registering device: $e');
      rethrow;
    }
  }

  /// Mettre à jour le statut d'un utilisateur sur un appareil
  static Future<void> updateUserStatusOnDevice({
    required String deviceId,
    required String userId,
    required String newStatus, // active | suspended | blacklisted
  }) async {
    try {
      debugPrint('📝 Updating user status on device...');

      final docRef =
          _firestore.collection(_deviceRegistryCollection).doc(deviceId);
      final doc = await docRef.get();

      if (!doc.exists) {
        debugPrint('⚠️ Device not found in registry');
        return;
      }

      final device = DeviceFingerprintModel.fromFirestore(doc);

      final updatedUsers = device.associatedUsers.map((user) {
        if (user.userId == userId) {
          return DeviceUser(
            userId: user.userId,
            firstUsed: user.firstUsed,
            lastUsed: user.lastUsed,
            accountStatus: newStatus,
          );
        }
        return user;
      }).toList();

      await docRef.update({
        'associatedUsers': updatedUsers.map((u) => u.toMap()).toList(),
        'lastSeenAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ User status updated on device');
    } catch (e) {
      debugPrint('❌ Error updating user status on device: $e');
    }
  }

  /// Flagguer un appareil comme suspect
  static Future<void> flagDevice({
    required String deviceId,
    required String reason,
  }) async {
    try {
      debugPrint('🚩 Flagging device: $deviceId');

      await _firestore.collection(_deviceRegistryCollection).doc(deviceId).update({
        'flaggedAt': FieldValue.serverTimestamp(),
        'flagReason': reason,
        'riskLevel': DeviceRiskLevel.high.name,
      });

      debugPrint('✅ Device flagged');
    } catch (e) {
      debugPrint('❌ Error flagging device: $e');
    }
  }

  /// Retirer le flag d'un appareil
  static Future<void> unflagDevice(String deviceId) async {
    try {
      debugPrint('✅ Unflagging device: $deviceId');

      await _firestore.collection(_deviceRegistryCollection).doc(deviceId).update({
        'flaggedAt': null,
        'flagReason': null,
        'riskLevel': DeviceRiskLevel.safe.name,
      });

      debugPrint('✅ Device unflagged');
    } catch (e) {
      debugPrint('❌ Error unflagging device: $e');
    }
  }

  /// Récupérer les informations d'un appareil
  static Future<DeviceFingerprintModel?> getDeviceInfo(String deviceId) async {
    try {
      final doc = await _firestore
          .collection(_deviceRegistryCollection)
          .doc(deviceId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return DeviceFingerprintModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('❌ Error fetching device info: $e');
      return null;
    }
  }

  /// Récupérer tous les appareils d'un utilisateur
  static Future<List<DeviceFingerprintModel>> getUserDevices(
      String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_deviceRegistryCollection)
          .where('associatedUsers', arrayContains: {'userId': userId})
          .get();

      return snapshot.docs
          .map((doc) => DeviceFingerprintModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching user devices: $e');
      return [];
    }
  }
}

/// Extension pour DeviceUser copyWith
extension DeviceUserCopyWith on DeviceUser {
  DeviceUser copyWith({
    String? userId,
    DateTime? firstUsed,
    DateTime? lastUsed,
    String? accountStatus,
  }) {
    return DeviceUser(
      userId: userId ?? this.userId,
      firstUsed: firstUsed ?? this.firstUsed,
      lastUsed: lastUsed ?? this.lastUsed,
      accountStatus: accountStatus ?? this.accountStatus,
    );
  }
}