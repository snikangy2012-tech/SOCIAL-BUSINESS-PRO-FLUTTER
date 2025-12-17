// ===== lib/services/audit_service.dart =====
// Service central pour la gestion des logs d'audit et tracking d'activité

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/audit_log_model.dart';

class AuditService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'audit_logs';

  // ========== ENREGISTREMENT DE LOGS ==========

  /// Enregistrer un log d'audit générique
  static Future<String> log({
    required String userId,
    required String userType,
    required String userEmail,
    String? userName,
    required AuditCategory category,
    required String action,
    required String actionLabel,
    String? description,
    String? targetType,
    String? targetId,
    String? targetLabel,
    Map<String, dynamic>? metadata,
    String? ipAddress,
    String? deviceInfo,
    GeoPoint? location,
    AuditSeverity severity = AuditSeverity.low,
    bool requiresReview = false,
    bool isSuccessful = true,
  }) async {
    try {
      final log = AuditLog(
        id: '',
        userId: userId,
        userType: userType,
        userEmail: userEmail,
        userName: userName,
        category: category,
        action: action,
        actionLabel: actionLabel,
        description: description ?? actionLabel,
        targetType: targetType,
        targetId: targetId,
        targetLabel: targetLabel,
        metadata: metadata ?? {},
        ipAddress: ipAddress,
        deviceInfo: deviceInfo,
        location: location,
        severity: severity,
        requiresReview: requiresReview,
        isSuccessful: isSuccessful,
        timestamp: DateTime.now(),
      );

      final docRef = await _firestore
          .collection(_collectionName)
          .add(log.toFirestore());

      debugPrint('✅ Log d\'audit enregistré: ${log.actionLabel} (ID: ${docRef.id})');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Erreur enregistrement log d\'audit: $e');
      rethrow;
    }
  }

  /// Logger une action admin
  static Future<String> logAdminAction({
    required String userId,
    required String userEmail,
    String? userName,
    required String action,
    required String actionLabel,
    String? description,
    String? targetType,
    String? targetId,
    String? targetLabel,
    Map<String, dynamic>? metadata,
    AuditSeverity severity = AuditSeverity.medium,
    bool requiresReview = false,
  }) {
    return log(
      userId: userId,
      userType: 'admin',
      userEmail: userEmail,
      userName: userName,
      category: AuditCategory.adminAction,
      action: action,
      actionLabel: actionLabel,
      description: description,
      targetType: targetType,
      targetId: targetId,
      targetLabel: targetLabel,
      metadata: metadata,
      severity: severity,
      requiresReview: requiresReview,
    );
  }

  /// Logger une action utilisateur
  static Future<String> logUserAction({
    required String userId,
    required String userType,
    required String userEmail,
    String? userName,
    required String action,
    required String actionLabel,
    String? description,
    String? targetType,
    String? targetId,
    String? targetLabel,
    Map<String, dynamic>? metadata,
    AuditSeverity severity = AuditSeverity.low,
  }) {
    return log(
      userId: userId,
      userType: userType,
      userEmail: userEmail,
      userName: userName,
      category: AuditCategory.userAction,
      action: action,
      actionLabel: actionLabel,
      description: description,
      targetType: targetType,
      targetId: targetId,
      targetLabel: targetLabel,
      metadata: metadata,
      severity: severity,
    );
  }

  /// Logger un événement de sécurité
  static Future<String> logSecurityEvent({
    required String userId,
    required String userEmail,
    String? userName,
    required String action,
    required String actionLabel,
    String? description,
    Map<String, dynamic>? metadata,
    String? ipAddress,
    String? deviceInfo,
    AuditSeverity severity = AuditSeverity.high,
    bool requiresReview = true,
    bool isSuccessful = true,
  }) {
    return log(
      userId: userId,
      userType: 'system',
      userEmail: userEmail,
      userName: userName,
      category: AuditCategory.security,
      action: action,
      actionLabel: actionLabel,
      description: description,
      metadata: metadata,
      ipAddress: ipAddress,
      deviceInfo: deviceInfo,
      severity: severity,
      requiresReview: requiresReview,
      isSuccessful: isSuccessful,
    );
  }

  /// Logger une transaction financière
  static Future<String> logFinancialTransaction({
    required String userId,
    required String userType,
    required String userEmail,
    String? userName,
    required String action,
    required String actionLabel,
    String? description,
    String? targetType,
    String? targetId,
    String? targetLabel,
    Map<String, dynamic>? metadata,
    AuditSeverity severity = AuditSeverity.medium,
  }) {
    return log(
      userId: userId,
      userType: userType,
      userEmail: userEmail,
      userName: userName,
      category: AuditCategory.financial,
      action: action,
      actionLabel: actionLabel,
      description: description,
      targetType: targetType,
      targetId: targetId,
      targetLabel: targetLabel,
      metadata: metadata,
      severity: severity,
    );
  }

  /// Logger un événement système
  static Future<String> logSystemEvent({
    required String action,
    required String actionLabel,
    String? description,
    Map<String, dynamic>? metadata,
    AuditSeverity severity = AuditSeverity.low,
  }) {
    return log(
      userId: 'system',
      userType: 'system',
      userEmail: 'system@socialbusiness.com',
      category: AuditCategory.system,
      action: action,
      actionLabel: actionLabel,
      description: description,
      metadata: metadata,
      severity: severity,
    );
  }

  // ========== RÉCUPÉRATION DE LOGS ==========

  /// Récupérer les logs d'un utilisateur spécifique
  static Future<List<AuditLog>> getUserLogs(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
    List<AuditCategory>? categories,
    int? limit,
  }) async {
    try {
      Query query = _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true);

      // Filtre par date de début
      if (startDate != null) {
        query = query.where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      // Filtre par date de fin
      if (endDate != null) {
        query = query.where('timestamp',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      // Filtre par catégories
      if (categories != null && categories.isNotEmpty) {
        final categoryNames = categories.map((c) => c.name).toList();
        query = query.where('category', whereIn: categoryNames);
      }

      // Limite
      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => AuditLog.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('❌ Erreur récupération logs utilisateur: $e');
      return [];
    }
  }

  /// Récupérer les logs globaux (admin only)
  static Future<List<AuditLog>> getGlobalLogs({
    DateTime? startDate,
    DateTime? endDate,
    List<AuditCategory>? categories,
    AuditSeverity? minSeverity,
    bool? requiresReview,
    String? action,
    int? limit,
  }) async {
    try {
      Query query = _firestore
          .collection(_collectionName)
          .orderBy('timestamp', descending: true);

      // Filtre par date de début
      if (startDate != null) {
        query = query.where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      // Filtre par date de fin
      if (endDate != null) {
        query = query.where('timestamp',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      // Filtre par catégories
      if (categories != null && categories.isNotEmpty) {
        final categoryNames = categories.map((c) => c.name).toList();
        query = query.where('category', whereIn: categoryNames);
      }

      // Filtre par sévérité minimale (nécessite un index composite)
      if (minSeverity != null) {
        final severityNames = AuditSeverity.values
            .where((s) => s.index >= minSeverity.index)
            .map((s) => s.name)
            .toList();
        query = query.where('severity', whereIn: severityNames);
      }

      // Filtre par requiresReview
      if (requiresReview != null) {
        query = query.where('requiresReview', isEqualTo: requiresReview);
      }

      // Filtre par action spécifique
      if (action != null) {
        query = query.where('action', isEqualTo: action);
      }

      // Limite
      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => AuditLog.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('❌ Erreur récupération logs globaux: $e');
      return [];
    }
  }

  /// Rechercher dans les logs
  static Future<List<AuditLog>> searchLogs({
    String? searchTerm,
    String? userId,
    String? targetId,
    List<String>? actions,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      Query query = _firestore
          .collection(_collectionName)
          .orderBy('timestamp', descending: true);

      // Filtre par utilisateur
      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }

      // Filtre par cible
      if (targetId != null) {
        query = query.where('targetId', isEqualTo: targetId);
      }

      // Filtre par actions
      if (actions != null && actions.isNotEmpty) {
        query = query.where('action', whereIn: actions);
      }

      // Filtre par date de début
      if (startDate != null) {
        query = query.where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      // Filtre par date de fin
      if (endDate != null) {
        query = query.where('timestamp',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      // Limite
      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      var logs = snapshot.docs.map((doc) => AuditLog.fromFirestore(doc)).toList();

      // Filtre côté client pour le terme de recherche (full-text search)
      if (searchTerm != null && searchTerm.isNotEmpty) {
        final term = searchTerm.toLowerCase();
        logs = logs.where((log) {
          return log.actionLabel.toLowerCase().contains(term) ||
              log.description.toLowerCase().contains(term) ||
              log.userEmail.toLowerCase().contains(term) ||
              (log.targetLabel?.toLowerCase().contains(term) ?? false);
        }).toList();
      }

      return logs;
    } catch (e) {
      debugPrint('❌ Erreur recherche logs: $e');
      return [];
    }
  }

  /// Récupérer les logs pour une entité spécifique (ex: tous les logs pour une commande)
  static Future<List<AuditLog>> getEntityLogs({
    required String targetType,
    required String targetId,
    int? limit,
  }) async {
    try {
      Query query = _firestore
          .collection(_collectionName)
          .where('targetType', isEqualTo: targetType)
          .where('targetId', isEqualTo: targetId)
          .orderBy('timestamp', descending: false); // Chronologique pour une entité

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => AuditLog.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('❌ Erreur récupération logs entité: $e');
      return [];
    }
  }

  // ========== GESTION DES LOGS ==========

  /// Marquer un log comme revu
  static Future<void> markAsReviewed(String logId, String reviewedBy) async {
    try {
      await _firestore.collection(_collectionName).doc(logId).update({
        'reviewedAt': Timestamp.now(),
        'reviewedBy': reviewedBy,
        'requiresReview': false,
      });

      debugPrint('✅ Log marqué comme revu: $logId');
    } catch (e) {
      debugPrint('❌ Erreur marquage log: $e');
      rethrow;
    }
  }

  /// Obtenir les logs nécessitant une revue
  static Future<List<AuditLog>> getLogsRequiringReview({int? limit}) async {
    try {
      Query query = _firestore
          .collection(_collectionName)
          .where('requiresReview', isEqualTo: true)
          .orderBy('timestamp', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => AuditLog.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('❌ Erreur récupération logs à revoir: $e');
      return [];
    }
  }

  /// Compter les logs nécessitant une revue
  static Future<int> countLogsRequiringReview() async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('requiresReview', isEqualTo: true)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('❌ Erreur comptage logs à revoir: $e');
      return 0;
    }
  }

  // ========== STATISTIQUES ==========

  /// Obtenir les statistiques d'audit pour une période
  static Future<Map<String, dynamic>> getAuditStats({
    DateTime? startDate,
    DateTime? endDate,
    String? userId,
  }) async {
    try {
      Query query = _firestore.collection(_collectionName);

      // Filtre par utilisateur
      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }

      // Filtre par période
      if (startDate != null) {
        query = query.where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('timestamp',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final snapshot = await query.get();
      final logs = snapshot.docs.map((doc) => AuditLog.fromFirestore(doc)).toList();

      // Compter par catégorie
      final Map<String, int> byCategory = {};
      for (final category in AuditCategory.values) {
        byCategory[category.name] = logs.where((l) => l.category == category).length;
      }

      // Compter par sévérité
      final Map<String, int> bySeverity = {};
      for (final severity in AuditSeverity.values) {
        bySeverity[severity.name] = logs.where((l) => l.severity == severity).length;
      }

      // Compter les actions les plus fréquentes
      final Map<String, int> byAction = {};
      for (final log in logs) {
        byAction[log.action] = (byAction[log.action] ?? 0) + 1;
      }

      // Trier les actions par fréquence
      final topActions = byAction.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return {
        'totalLogs': logs.length,
        'byCategory': byCategory,
        'bySeverity': bySeverity,
        'topActions': Map.fromEntries(topActions.take(10)),
        'requiresReview': logs.where((l) => l.requiresReview).length,
        'failed': logs.where((l) => !l.isSuccessful).length,
        'uniqueUsers': logs.map((l) => l.userId).toSet().length,
      };
    } catch (e) {
      debugPrint('❌ Erreur calcul statistiques audit: $e');
      return {
        'totalLogs': 0,
        'byCategory': {},
        'bySeverity': {},
        'topActions': {},
        'requiresReview': 0,
        'failed': 0,
        'uniqueUsers': 0,
      };
    }
  }

  /// Obtenir les activités récentes (pour dashboard)
  static Future<List<AuditLog>> getRecentActivity({
    int limit = 20,
    List<AuditCategory>? categories,
  }) async {
    try {
      Query query = _firestore
          .collection(_collectionName)
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (categories != null && categories.isNotEmpty) {
        final categoryNames = categories.map((c) => c.name).toList();
        query = query.where('category', whereIn: categoryNames);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => AuditLog.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('❌ Erreur récupération activité récente: $e');
      return [];
    }
  }

  // ========== NETTOYAGE ==========

  /// Supprimer les logs anciens (à exécuter périodiquement via Cloud Function)
  static Future<int> cleanupOldLogs({
    required int daysToKeep,
    List<AuditCategory>? excludeCategories,
  }) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));

      Query query = _firestore
          .collection(_collectionName)
          .where('timestamp', isLessThan: Timestamp.fromDate(cutoffDate));

      // Exclure certaines catégories (ex: garder les logs financiers plus longtemps)
      if (excludeCategories != null && excludeCategories.isNotEmpty) {
        final excludeNames = excludeCategories.map((c) => c.name).toList();
        query = query.where('category', whereNotIn: excludeNames);
      }

      final snapshot = await query.get();
      int deletedCount = 0;

      // Supprimer par batch (max 500 docs par batch)
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
        deletedCount++;

        if (deletedCount % 500 == 0) {
          await batch.commit();
        }
      }

      // Commit final
      if (deletedCount % 500 != 0) {
        await batch.commit();
      }

      debugPrint('✅ $deletedCount logs anciens supprimés');
      return deletedCount;
    } catch (e) {
      debugPrint('❌ Erreur nettoyage logs anciens: $e');
      return 0;
    }
  }

  // ========== STREAM (TEMPS RÉEL) ==========

  /// Stream des logs d'un utilisateur (pour affichage temps réel)
  static Stream<List<AuditLog>> streamUserLogs(
    String userId, {
    int limit = 50,
  }) {
    return _firestore
        .collection(_collectionName)
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => AuditLog.fromFirestore(doc)).toList());
  }

  /// Stream des logs nécessitant une revue
  static Stream<List<AuditLog>> streamLogsRequiringReview({int limit = 20}) {
    return _firestore
        .collection(_collectionName)
        .where('requiresReview', isEqualTo: true)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => AuditLog.fromFirestore(doc)).toList());
  }

  /// Stream de l'activité récente
  static Stream<List<AuditLog>> streamRecentActivity({int limit = 20}) {
    return _firestore
        .collection(_collectionName)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => AuditLog.fromFirestore(doc)).toList());
  }
}
