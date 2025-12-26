import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/device_fingerprint_model.dart';
import '../models/blacklist_entry_model.dart';
import 'blacklist_service.dart';
import 'device_fingerprint_service.dart';
import 'audit_service.dart';
import '../models/audit_log_model.dart';

/// Service de KYC adaptatif selon le niveau de risque
/// Permet un accès progressif sans bloquer les utilisateurs légitimes
class KYCAdaptiveService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Niveaux d'accès progressifs
  static const Map<RiskTier, TierLimits> TIER_LIMITS = {
    RiskTier.trusted: TierLimits(
      maxOrderValue: 5000000, // 5M FCFA
      maxDailyOrders: 50,
      maxPendingOrders: 20,
      canWithdrawEarnings: true,
      withdrawalDelay: Duration.zero,
      requiresKYC: false,
      kycMessage: 'Complétez votre KYC pour augmenter vos limites',
    ),
    RiskTier.verified: TierLimits(
      maxOrderValue: 1000000, // 1M FCFA
      maxDailyOrders: 20,
      maxPendingOrders: 10,
      canWithdrawEarnings: true,
      withdrawalDelay: Duration(hours: 2),
      requiresKYC: false,
      kycMessage: 'KYC recommandé pour limites supérieures',
    ),
    RiskTier.newUser: TierLimits(
      maxOrderValue: 250000, // 250k FCFA
      maxDailyOrders: 5,
      maxPendingOrders: 3,
      canWithdrawEarnings: true,
      withdrawalDelay: Duration(hours: 24),
      requiresKYC: false,
      kycMessage: 'Nouveau compte - Limites augmentent avec l\'activité',
    ),
    RiskTier.moderateRisk: TierLimits(
      maxOrderValue: 100000, // 100k FCFA
      maxDailyOrders: 2,
      maxPendingOrders: 1,
      canWithdrawEarnings: false,
      withdrawalDelay: Duration(days: 3),
      requiresKYC: true,
      kycMessage: 'KYC simplifié requis pour retirer vos gains',
    ),
    RiskTier.highRisk: TierLimits(
      maxOrderValue: 0,
      maxDailyOrders: 0,
      maxPendingOrders: 0,
      canWithdrawEarnings: false,
      withdrawalDelay: Duration(days: 7),
      requiresKYC: true,
      kycMessage: 'Vérification complète requise - Contactez le support',
    ),
    RiskTier.blacklisted: TierLimits(
      maxOrderValue: 0,
      maxDailyOrders: 0,
      maxPendingOrders: 0,
      canWithdrawEarnings: false,
      withdrawalDelay: Duration(days: 365),
      requiresKYC: true,
      kycMessage: 'Compte restreint - Contactez le support',
    ),
  };

  /// Évaluer le niveau de risque d'un utilisateur à l'inscription
  static Future<UserRiskAssessment> assessUserRisk({
    required String userId,
    required String phoneNumber,
    String? email,
  }) async {
    try {
      debugPrint('🔍 Évaluation risque pour user: $userId');

      // 1. Collecter device info
      final deviceInfo = await DeviceFingerprintService.collectDeviceInfo();

      // 2. Vérifier blacklist
      final blacklistCheck = await BlacklistService.checkBlacklist(
        phoneNumber: phoneNumber,
        deviceId: deviceInfo.deviceId,
      );

      // 3. Vérifier device risk
      final deviceRisk = await DeviceFingerprintService.checkDeviceRegistry(
        deviceInfo.deviceId,
        userId,
      );

      // 4. Enregistrer l'appareil
      await DeviceFingerprintService.registerDevice(
        deviceInfo.deviceId,
        userId,
        deviceInfo,
      );

      // 5. Calculer le score de risque global (0-100)
      int riskScore = 100;
      final List<String> riskFactors = [];
      RiskTier tier;

      // Facteur 1: Blacklist (critique)
      if (blacklistCheck.isBlacklisted) {
        riskScore = 0;
        tier = RiskTier.blacklisted;
        riskFactors.addAll(blacklistCheck.blockedReasons);

        // Log immédiat
        await AuditService.log(
          userId: userId,
          userEmail: email ?? 'unknown',
          userName: 'User',
          userType: 'unknown',
          action: 'blacklist_detected',
          actionLabel: 'Blacklisted User Detected',
          category: AuditCategory.security,
          severity: AuditSeverity.critical,
          targetType: 'user',
          targetId: userId,
          metadata: {
            'totalDebt': blacklistCheck.totalDebtAmount,
            'reasons': blacklistCheck.blockedReasons,
          },
        );
      } else {
        // Facteur 2: Device risk
        riskScore -= (10 - deviceRisk.riskScore) * 5; // Max -50 points
        if (deviceRisk.hasRiskFactors) {
          riskFactors.addAll(deviceRisk.riskFactors);
        }

        // Facteur 3: Appareil physique vs émulateur
        if (!deviceInfo.isPhysicalDevice) {
          riskScore -= 30;
          riskFactors.add('Appareil émulé ou virtuel détecté');
        }

        // Facteur 4: Email jetable (basique)
        if (email != null && _isDisposableEmail(email)) {
          riskScore -= 10;
          riskFactors.add('Email jetable utilisé');
        }

        // Déterminer le tier
        riskScore = riskScore.clamp(0, 100);

        if (riskScore >= 90) {
          tier = RiskTier.trusted; // Excellent
        } else if (riskScore >= 70) {
          tier = RiskTier.verified; // Bon
        } else if (riskScore >= 50) {
          tier = RiskTier.newUser; // Acceptable (nouveau)
        } else if (riskScore >= 30) {
          tier = RiskTier.moderateRisk; // Surveillé
        } else {
          tier = RiskTier.highRisk; // Suspect
        }
      }

      final limits = TIER_LIMITS[tier]!;

      debugPrint('✅ Évaluation complète:');
      debugPrint('  - Score: $riskScore/100');
      debugPrint('  - Tier: ${tier.name}');
      debugPrint('  - KYC requis: ${limits.requiresKYC}');

      final assessment = UserRiskAssessment(
        userId: userId,
        riskScore: riskScore,
        tier: tier,
        limits: limits,
        riskFactors: riskFactors,
        deviceInfo: deviceInfo,
        blacklistCheck: blacklistCheck,
        assessedAt: DateTime.now(),
      );

      // Sauvegarder dans Firestore
      await _saveRiskAssessment(assessment);

      return assessment;
    } catch (e) {
      debugPrint('❌ Erreur évaluation risque: $e');

      // En cas d'erreur, retourner un profil par défaut sécurisé
      return UserRiskAssessment(
        userId: userId,
        riskScore: 50,
        tier: RiskTier.newUser,
        limits: TIER_LIMITS[RiskTier.newUser]!,
        riskFactors: ['Erreur évaluation - Mode sécurisé'],
        deviceInfo: await DeviceFingerprintService.collectDeviceInfo(),
        blacklistCheck: BlacklistCheckResult(
          isBlacklisted: false,
          matches: [],
          totalDebtAmount: 0,
          canReconcile: false,
          blockedReasons: [],
        ),
        assessedAt: DateTime.now(),
      );
    }
  }

  /// Vérifier si un utilisateur peut effectuer une action
  static Future<ActionPermissionResult> canPerformAction({
    required String userId,
    required String action,
    double? orderValue,
    int? currentDailyOrders,
    int? currentPendingOrders,
  }) async {
    try {
      // Récupérer le risk assessment
      final assessment = await getRiskAssessment(userId);

      if (assessment == null) {
        return ActionPermissionResult(
          allowed: false,
          reason: 'Profil utilisateur non trouvé',
          suggestedAction: 'Contactez le support',
          requiresKYC: false,
          currentTier: null,
          nextTier: null,
        );
      }

      final limits = assessment.limits;
      final currentTier = assessment.tier;
      final nextTier = _getNextTier(currentTier);

      switch (action) {
        case 'create_order':
          // Vérifier valeur commande
          if (orderValue != null && orderValue > limits.maxOrderValue) {
            return ActionPermissionResult(
              allowed: false,
              reason:
                  'Montant maximum: ${limits.maxOrderValue} FCFA (Tier: ${assessment.tier.displayName})',
              suggestedAction: limits.requiresKYC
                  ? 'Complétez votre KYC pour augmenter les limites'
                  : 'Limite augmentée avec l\'historique',
              requiresKYC: limits.requiresKYC,
              currentTier: currentTier,
              nextTier: nextTier,
            );
          }

          // Vérifier nombre de commandes
          if (currentDailyOrders != null &&
              currentDailyOrders >= limits.maxDailyOrders) {
            return ActionPermissionResult(
              allowed: false,
              reason: 'Limite quotidienne atteinte: ${limits.maxDailyOrders} commandes',
              suggestedAction: 'Réessayez demain ou complétez votre KYC',
              requiresKYC: limits.requiresKYC,
              currentTier: currentTier,
              nextTier: nextTier,
            );
          }

          return ActionPermissionResult(
            allowed: true,
            requiresKYC: limits.requiresKYC,
            currentTier: currentTier,
            nextTier: nextTier,
          );

        case 'accept_delivery':
          // Même logique que create_order pour livreurs
          if (currentDailyOrders != null &&
              currentDailyOrders >= limits.maxDailyOrders) {
            return ActionPermissionResult(
              allowed: false,
              reason: 'Limite quotidienne: ${limits.maxDailyOrders} livraisons',
              suggestedAction: limits.kycMessage,
              requiresKYC: limits.requiresKYC,
              currentTier: currentTier,
              nextTier: nextTier,
            );
          }

          return ActionPermissionResult(
            allowed: true,
            requiresKYC: limits.requiresKYC,
            currentTier: currentTier,
            nextTier: nextTier,
          );

        case 'withdraw_earnings':
          if (!limits.canWithdrawEarnings) {
            return ActionPermissionResult(
              allowed: false,
              reason: 'Retraits bloqués pour votre niveau',
              suggestedAction: limits.kycMessage,
              requiresKYC: limits.requiresKYC,
              currentTier: currentTier,
              nextTier: nextTier,
            );
          }

          return ActionPermissionResult(
            allowed: true,
            requiresKYC: limits.requiresKYC,
            currentTier: currentTier,
            nextTier: nextTier,
          );

        default:
          return ActionPermissionResult(
            allowed: true,
            reason: 'Action non restreinte',
            requiresKYC: false,
            currentTier: currentTier,
            nextTier: nextTier,
          );
      }
    } catch (e) {
      debugPrint('❌ Erreur vérification permission: $e');
      return ActionPermissionResult(
        allowed: false,
        reason: 'Erreur de vérification',
        suggestedAction: 'Réessayez ou contactez le support',
        requiresKYC: false,
        currentTier: null,
        nextTier: null,
      );
    }
  }

  /// Retourner le tier suivant (pour progression)
  static RiskTier? _getNextTier(RiskTier currentTier) {
    final tierIndex = RiskTier.values.indexOf(currentTier);
    if (tierIndex <= 0) return null; // Déjà au tier maximum
    return RiskTier.values[tierIndex - 1];
  }

  /// Améliorer le tier d'un utilisateur (progression automatique)
  static Future<void> upgradeTierIfEligible(String userId) async {
    try {
      final assessment = await getRiskAssessment(userId);
      if (assessment == null) return;

      // Critères d'amélioration automatique
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return;

      final data = userDoc.data()!;
      final totalOrders = data['totalOrders'] ?? 0;
      final successfulOrders = data['successfulOrders'] ?? 0;
      final accountAge = DateTime.now().difference(
        (data['createdAt'] as Timestamp).toDate(),
      );

      RiskTier? newTier;

      // Progression: newUser → verified
      if (assessment.tier == RiskTier.newUser &&
          totalOrders >= 5 &&
          successfulOrders >= 4 &&
          accountAge.inDays >= 7) {
        newTier = RiskTier.verified;
      }

      // Progression: verified → trusted (avec KYC)
      if (assessment.tier == RiskTier.verified &&
          totalOrders >= 20 &&
          successfulOrders >= 18 &&
          accountAge.inDays >= 30 &&
          data['verificationStatus'] == 'verified') {
        newTier = RiskTier.trusted;
      }

      if (newTier != null) {
        await _updateUserTier(userId, newTier);
        debugPrint('✅ User $userId upgraded to ${newTier.name}');
      }
    } catch (e) {
      debugPrint('❌ Erreur upgrade tier: $e');
    }
  }

  /// Récupérer le risk assessment d'un utilisateur
  static Future<UserRiskAssessment?> getRiskAssessment(String userId) async {
    try {
      final doc = await _firestore
          .collection('risk_assessments')
          .doc(userId)
          .get()
          .timeout(const Duration(seconds: 5));

      if (!doc.exists) return null;

      return UserRiskAssessment.fromMap(doc.data()!, userId);
    } catch (e) {
      debugPrint('❌ Erreur récupération risk assessment: $e');
      return null;
    }
  }

  // ==================== MÉTHODES PRIVÉES ====================

  /// Sauvegarder le risk assessment
  static Future<void> _saveRiskAssessment(UserRiskAssessment assessment) async {
    await _firestore
        .collection('risk_assessments')
        .doc(assessment.userId)
        .set(assessment.toMap());
  }

  /// Mettre à jour le tier d'un utilisateur
  static Future<void> _updateUserTier(String userId, RiskTier newTier) async {
    await _firestore.collection('risk_assessments').doc(userId).update({
      'tier': newTier.name,
      'limits': TIER_LIMITS[newTier]!.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Détecter email jetable (basique)
  static bool _isDisposableEmail(String email) {
    final disposableDomains = [
      'tempmail.com',
      '10minutemail.com',
      'guerrillamail.com',
      'yopmail.com',
    ];

    final domain = email.split('@').last.toLowerCase();
    return disposableDomains.contains(domain);
  }
}

// ==================== MODÈLES ====================

enum RiskTier {
  trusted,
  verified,
  newUser,
  moderateRisk,
  highRisk,
  blacklisted;

  String get displayName {
    switch (this) {
      case RiskTier.trusted:
        return 'Utilisateur de confiance';
      case RiskTier.verified:
        return 'Utilisateur vérifié';
      case RiskTier.newUser:
        return 'Nouveau compte';
      case RiskTier.moderateRisk:
        return 'Surveillance renforcée';
      case RiskTier.highRisk:
        return 'Risque élevé';
      case RiskTier.blacklisted:
        return 'Compte bloqué';
    }
  }
}

class TierLimits {
  final double maxOrderValue;
  final int maxDailyOrders;
  final int maxPendingOrders;
  final bool canWithdrawEarnings;
  final Duration withdrawalDelay;
  final bool requiresKYC;
  final String kycMessage;

  const TierLimits({
    required this.maxOrderValue,
    required this.maxDailyOrders,
    required this.maxPendingOrders,
    required this.canWithdrawEarnings,
    required this.withdrawalDelay,
    required this.requiresKYC,
    required this.kycMessage,
  });

  Map<String, dynamic> toMap() {
    return {
      'maxOrderValue': maxOrderValue,
      'maxDailyOrders': maxDailyOrders,
      'maxPendingOrders': maxPendingOrders,
      'canWithdrawEarnings': canWithdrawEarnings,
      'withdrawalDelayHours': withdrawalDelay.inHours,
      'requiresKYC': requiresKYC,
      'kycMessage': kycMessage,
    };
  }
}

class UserRiskAssessment {
  final String userId;
  final int riskScore;
  final RiskTier tier;
  final TierLimits limits;
  final List<String> riskFactors;
  final DeviceInfo deviceInfo;
  final BlacklistCheckResult blacklistCheck;
  final DateTime assessedAt;

  UserRiskAssessment({
    required this.userId,
    required this.riskScore,
    required this.tier,
    required this.limits,
    required this.riskFactors,
    required this.deviceInfo,
    required this.blacklistCheck,
    required this.assessedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'riskScore': riskScore,
      'tier': tier.name,
      'limits': limits.toMap(),
      'riskFactors': riskFactors,
      'deviceId': deviceInfo.deviceId,
      'isBlacklisted': blacklistCheck.isBlacklisted,
      'assessedAt': Timestamp.fromDate(assessedAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory UserRiskAssessment.fromMap(Map<String, dynamic> map, String userId) {
    return UserRiskAssessment(
      userId: userId,
      riskScore: map['riskScore'] ?? 50,
      tier: RiskTier.values.firstWhere(
        (t) => t.name == map['tier'],
        orElse: () => RiskTier.newUser,
      ),
      limits: KYCAdaptiveService.TIER_LIMITS[RiskTier.values.firstWhere(
        (t) => t.name == map['tier'],
        orElse: () => RiskTier.newUser,
      )]!,
      riskFactors: List<String>.from(map['riskFactors'] ?? []),
      deviceInfo: DeviceInfo(
        deviceId: map['deviceId'] ?? '',
        model: '',
        manufacturer: '',
        osVersion: '',
        platform: '',
        appVersion: '',
        isPhysicalDevice: true,
      ),
      blacklistCheck: BlacklistCheckResult(
        isBlacklisted: map['isBlacklisted'] ?? false,
        matches: [],
        totalDebtAmount: 0,
        canReconcile: false,
        blockedReasons: [],
      ),
      assessedAt: (map['assessedAt'] as Timestamp).toDate(),
    );
  }
}

class ActionPermissionResult {
  final bool allowed;
  final String? reason;
  final String? suggestedAction;
  final bool requiresKYC;
  final RiskTier? currentTier;
  final RiskTier? nextTier;

  ActionPermissionResult({
    required this.allowed,
    this.reason,
    this.suggestedAction,
    this.requiresKYC = false,
    this.currentTier,
    this.nextTier,
  });
}