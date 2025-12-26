import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/blacklist_entry_model.dart';
import '../models/face_hash_model.dart';
import '../models/audit_log_model.dart';
import 'audit_service.dart';

/// Service de gestion de la blacklist
/// Gère la détection de comptes frauduleux et la réconciliation des dettes
class BlacklistService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  static const String _blacklistCollection = 'blacklist';
  static const String _faceHashesCollection = 'face_hashes';

  /// Vérification complète blacklist (multi-critères)
  static Future<BlacklistCheckResult> checkBlacklist({
    String? cniNumber,
    String? faceHash,
    String? phoneNumber,
    String? mobileMoneyAccount,
    String? deviceId,
  }) async {
    try {
      debugPrint('🔍 Checking blacklist with:');
      debugPrint('  - CNI: $cniNumber');
      debugPrint('  - Face hash: ${faceHash?.substring(0, 10)}...');
      debugPrint('  - Phone: $phoneNumber');
      debugPrint('  - Mobile Money: $mobileMoneyAccount');
      debugPrint('  - Device: $deviceId');

      final List<BlacklistEntryModel> matches = [];

      // Recherche par CNI
      if (cniNumber != null && cniNumber.isNotEmpty) {
        final cniMatches = await _searchByCriteria('cniNumber', cniNumber);
        matches.addAll(cniMatches);
      }

      // Recherche par face hash (biométrie)
      if (faceHash != null && faceHash.isNotEmpty) {
        final faceMatches = await _searchByCriteria('faceHash', faceHash);
        matches.addAll(faceMatches);
      }

      // Recherche par téléphone
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        final phoneMatches =
            await _searchByCriteria('phoneNumber', phoneNumber);
        matches.addAll(phoneMatches);
      }

      // Recherche par Mobile Money
      if (mobileMoneyAccount != null && mobileMoneyAccount.isNotEmpty) {
        final mmMatches =
            await _searchByCriteria('mobileMoneyAccount', mobileMoneyAccount);
        matches.addAll(mmMatches);
      }

      // Recherche par device ID
      if (deviceId != null && deviceId.isNotEmpty) {
        final deviceMatches =
            await _searchByDeviceId('deviceIds', deviceId);
        matches.addAll(deviceMatches);
      }

      // Éliminer les doublons
      final uniqueMatches = <String, BlacklistEntryModel>{};
      for (var match in matches) {
        uniqueMatches[match.id] = match;
      }

      final finalMatches = uniqueMatches.values
          .where((m) =>
              m.status == BlacklistStatus.active ||
              m.status == BlacklistStatus.permanent)
          .toList();

      // Calculer le total de la dette
      final totalDebt =
          finalMatches.fold<double>(0, (total, entry) => total + entry.amountDue);

      // Vérifier si réconciliation possible
      final canReconcile = finalMatches.every((m) => m.canReconcile) &&
          !finalMatches.any((m) => m.status == BlacklistStatus.permanent);

      // Collecter les raisons de blocage
      final blockedReasons = finalMatches.map((m) => m.reason).toSet().toList();

      debugPrint('✅ Blacklist check complete:');
      debugPrint('  - Matches found: ${finalMatches.length}');
      debugPrint('  - Total debt: $totalDebt FCFA');
      debugPrint('  - Can reconcile: $canReconcile');

      return BlacklistCheckResult(
        isBlacklisted: finalMatches.isNotEmpty,
        matches: finalMatches,
        totalDebtAmount: totalDebt,
        canReconcile: canReconcile,
        blockedReasons: blockedReasons,
      );
    } catch (e) {
      debugPrint('❌ Error checking blacklist: $e');
      rethrow;
    }
  }

  /// Recherche par critère unique
  static Future<List<BlacklistEntryModel>> _searchByCriteria(
      String field, String value) async {
    try {
      final snapshot = await _firestore
          .collection(_blacklistCollection)
          .where(field, isEqualTo: value)
          .get()
          .timeout(const Duration(seconds: 10));

      return snapshot.docs
          .map((doc) => BlacklistEntryModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('❌ Error searching blacklist by $field: $e');
      return [];
    }
  }

  /// Recherche par device ID (array-contains)
  static Future<List<BlacklistEntryModel>> _searchByDeviceId(
      String field, String deviceId) async {
    try {
      final snapshot = await _firestore
          .collection(_blacklistCollection)
          .where(field, arrayContains: deviceId)
          .get()
          .timeout(const Duration(seconds: 10));

      return snapshot.docs
          .map((doc) => BlacklistEntryModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('❌ Error searching blacklist by device ID: $e');
      return [];
    }
  }

  /// Ajouter à la blacklist
  static Future<String> addToBlacklist({
    required BlacklistType type,
    String? cniNumber,
    String? faceHash,
    String? phoneNumber,
    String? mobileMoneyAccount,
    List<String> deviceIds = const [],
    required String userId,
    required String userName,
    required String userType,
    required String reason,
    required double amountDue,
    String currency = 'FCFA',
    List<String> ordersInvolved = const [],
    List<String> deliveriesInvolved = const [],
    required String adminId,
    bool canReconcile = true,
    int reconciliationDaysDeadline = 60,
    double penaltyPercentage = 10.0,
    required BlacklistSeverity severity,
    String notes = '',
  }) async {
    try {
      debugPrint('📝 Adding to blacklist: $userName ($userType)');

      final now = DateTime.now();
      final reconciliationDeadline =
          now.add(Duration(days: reconciliationDaysDeadline));
      final reconciliationAmount = amountDue * (1 + penaltyPercentage / 100);

      final entry = BlacklistEntryModel(
        id: '', // Will be set by Firestore
        type: type,
        cniNumber: cniNumber,
        faceHash: faceHash,
        phoneNumber: phoneNumber,
        mobileMoneyAccount: mobileMoneyAccount,
        deviceIds: deviceIds,
        userId: userId,
        userName: userName,
        userType: userType,
        reason: reason,
        amountDue: amountDue,
        currency: currency,
        ordersInvolved: ordersInvolved,
        deliveriesInvolved: deliveriesInvolved,
        listedAt: now,
        listedBy: adminId,
        canReconcile: canReconcile,
        reconciliationDeadline: canReconcile ? reconciliationDeadline : null,
        reconciliationAmount: reconciliationAmount,
        status: BlacklistStatus.active,
        severity: severity,
        notes: notes,
        updatedAt: now,
      );

      final docRef =
          await _firestore.collection(_blacklistCollection).add(entry.toMap());

      // Mettre à jour le statut de l'utilisateur dans face_hashes si faceHash fourni
      if (faceHash != null && faceHash.isNotEmpty) {
        await _updateFaceHashStatus(
          faceHash: faceHash,
          status: FaceAccountStatus.blacklisted,
          blacklistId: docRef.id,
        );
      }

      // Audit log
      await AuditService.log(
        userId: adminId,
        userEmail: 'admin',
        userName: 'Admin',
        userType: 'admin',
        action: 'blacklist_add',
        actionLabel: 'User Added to Blacklist',
        category: AuditCategory.security,
        severity: AuditSeverity.high,
        targetType: 'user',
        targetId: userId,
        metadata: {
          'blacklistId': docRef.id,
          'reason': reason,
          'amountDue': amountDue,
          'severity': severity.name,
        },
      );

      debugPrint('✅ Blacklist entry created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Error adding to blacklist: $e');
      rethrow;
    }
  }

  /// Mettre à jour le statut face hash
  static Future<void> _updateFaceHashStatus({
    required String faceHash,
    required FaceAccountStatus status,
    String? blacklistId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_faceHashesCollection)
          .where('faceHash', isEqualTo: faceHash)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        await snapshot.docs.first.reference.update({
          'accountStatus': status.name,
          'blacklistId': blacklistId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('❌ Error updating face hash status: $e');
    }
  }

  /// Initier réconciliation
  static Future<void> initiateReconciliation({
    required String blacklistId,
    required String userId,
    required String paymentProof,
  }) async {
    try {
      debugPrint('💰 Initiating reconciliation for blacklist: $blacklistId');

      await _firestore.collection(_blacklistCollection).doc(blacklistId).update({
        'status': BlacklistStatus.underInvestigation.name,
        'paymentProof': paymentProof,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Audit log
      await AuditService.log(
        userId: userId,
        userEmail: 'user',
        userName: 'User',
        userType: 'unknown',
        action: 'reconciliation_initiated',
        actionLabel: 'Reconciliation Initiated',
        category: AuditCategory.userAction,
        severity: AuditSeverity.medium,
        targetType: 'blacklist',
        targetId: blacklistId,
        metadata: {
          'paymentProof': paymentProof,
        },
      );

      debugPrint('✅ Reconciliation initiated');
    } catch (e) {
      debugPrint('❌ Error initiating reconciliation: $e');
      rethrow;
    }
  }

  /// Approuver réconciliation (admin)
  static Future<void> approveReconciliation({
    required String blacklistId,
    required String adminId,
  }) async {
    try {
      debugPrint('✅ Approving reconciliation for blacklist: $blacklistId');

      final now = DateTime.now();

      // Récupérer l'entrée blacklist
      final doc = await _firestore
          .collection(_blacklistCollection)
          .doc(blacklistId)
          .get();

      if (!doc.exists) {
        throw Exception('Blacklist entry not found');
      }

      final entry = BlacklistEntryModel.fromFirestore(doc);

      // Mettre à jour le statut
      await doc.reference.update({
        'status': BlacklistStatus.reconciled.name,
        'reconciledAt': Timestamp.fromDate(now),
        'reconciledBy': adminId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Restaurer le statut face hash si présent
      if (entry.faceHash != null && entry.faceHash!.isNotEmpty) {
        await _updateFaceHashStatus(
          faceHash: entry.faceHash!,
          status: FaceAccountStatus.suspended, // Surveillance renforcée
          blacklistId: null,
        );
      }

      // Audit log
      await AuditService.log(
        userId: adminId,
        userEmail: 'admin',
        userName: 'Admin',
        userType: 'admin',
        action: 'reconciliation_approved',
        actionLabel: 'Reconciliation Approved',
        category: AuditCategory.security,
        severity: AuditSeverity.medium,
        targetType: 'blacklist',
        targetId: blacklistId,
        metadata: {
          'userId': entry.userId,
          'amountReconciled': entry.reconciliationAmount,
        },
      );

      debugPrint('✅ Reconciliation approved');
    } catch (e) {
      debugPrint('❌ Error approving reconciliation: $e');
      rethrow;
    }
  }

  /// Rejeter réconciliation (admin)
  static Future<void> rejectReconciliation({
    required String blacklistId,
    required String adminId,
    required String reason,
  }) async {
    try {
      debugPrint('❌ Rejecting reconciliation for blacklist: $blacklistId');

      await _firestore.collection(_blacklistCollection).doc(blacklistId).update({
        'status': BlacklistStatus.active.name,
        'notes': 'Reconciliation rejected: $reason',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Audit log
      await AuditService.log(
        userId: adminId,
        userEmail: 'admin',
        userName: 'Admin',
        userType: 'admin',
        action: 'reconciliation_rejected',
        actionLabel: 'Reconciliation Rejected',
        category: AuditCategory.security,
        severity: AuditSeverity.medium,
        targetType: 'blacklist',
        targetId: blacklistId,
        metadata: {
          'reason': reason,
        },
      );

      debugPrint('✅ Reconciliation rejected');
    } catch (e) {
      debugPrint('❌ Error rejecting reconciliation: $e');
      rethrow;
    }
  }

  /// Retirer de la blacklist (admin uniquement)
  static Future<void> removeFromBlacklist({
    required String blacklistId,
    required String adminId,
    required String reason,
  }) async {
    try {
      debugPrint('🗑️ Removing from blacklist: $blacklistId');

      final doc = await _firestore
          .collection(_blacklistCollection)
          .doc(blacklistId)
          .get();

      if (!doc.exists) {
        throw Exception('Blacklist entry not found');
      }

      final entry = BlacklistEntryModel.fromFirestore(doc);

      // Restaurer face hash status
      if (entry.faceHash != null && entry.faceHash!.isNotEmpty) {
        await _updateFaceHashStatus(
          faceHash: entry.faceHash!,
          status: FaceAccountStatus.active,
          blacklistId: null,
        );
      }

      // Supprimer l'entrée (ou marquer comme inactive)
      await doc.reference.delete();

      // Audit log
      await AuditService.log(
        userId: adminId,
        userEmail: 'admin',
        userName: 'Admin',
        userType: 'admin',
        action: 'blacklist_remove',
        actionLabel: 'User Removed from Blacklist',
        category: AuditCategory.security,
        severity: AuditSeverity.high,
        targetType: 'user',
        targetId: entry.userId,
        metadata: {
          'blacklistId': blacklistId,
          'reason': reason,
        },
      );

      debugPrint('✅ Removed from blacklist');
    } catch (e) {
      debugPrint('❌ Error removing from blacklist: $e');
      rethrow;
    }
  }

  /// Récupérer toutes les entrées blacklist (admin)
  static Future<List<BlacklistEntryModel>> getAllBlacklistEntries({
    BlacklistStatus? status,
    BlacklistType? type,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore
          .collection(_blacklistCollection)
          .orderBy('listedAt', descending: true);

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      if (type != null) {
        query = query.where('type', isEqualTo: type.name);
      }

      final snapshot = await query.limit(limit).get();

      return snapshot.docs
          .map((doc) => BlacklistEntryModel.fromFirestore(
                doc as DocumentSnapshot<Map<String, dynamic>>,
              ))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching blacklist entries: $e');
      return [];
    }
  }

  /// Récupérer l'entrée blacklist par ID
  static Future<BlacklistEntryModel?> getBlacklistEntry(
      String blacklistId) async {
    try {
      final doc = await _firestore
          .collection(_blacklistCollection)
          .doc(blacklistId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return BlacklistEntryModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('❌ Error fetching blacklist entry: $e');
      return null;
    }
  }

  /// Stream des entrées blacklist
  static Stream<List<BlacklistEntryModel>> streamBlacklistEntries({
    BlacklistStatus? status,
    int limit = 50,
  }) {
    Query query = _firestore
        .collection(_blacklistCollection)
        .orderBy('listedAt', descending: true);

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    return query.limit(limit).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => BlacklistEntryModel.fromFirestore(
                doc as DocumentSnapshot<Map<String, dynamic>>,
              ))
          .toList();
    });
  }
}