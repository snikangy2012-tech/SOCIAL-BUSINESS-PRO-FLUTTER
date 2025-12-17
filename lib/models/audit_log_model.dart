// ===== lib/models/audit_log_model.dart =====
// Modèle pour les logs d'audit et tracking d'activité

import 'package:cloud_firestore/cloud_firestore.dart';

/// Catégories de logs d'audit
enum AuditCategory {
  adminAction,   // Actions administratives
  userAction,    // Actions utilisateurs normales
  security,      // Événements de sécurité
  financial,     // Transactions financières
  system,        // Événements système
}

/// Niveaux de sévérité des logs
enum AuditSeverity {
  low,           // Info normale
  medium,        // Attention requise
  high,          // Action importante
  critical,      // Action critique nécessitant revue
}

/// Modèle de log d'audit unifié
class AuditLog {
  final String id;

  // === ACTEUR ===
  final String userId;              // UID de l'utilisateur qui a agi
  final String userType;            // acheteur|vendeur|livreur|admin
  final String userEmail;           // Email de l'acteur
  final String? userName;           // Nom de l'acteur

  // === CATÉGORIE & ACTION ===
  final AuditCategory category;     // Catégorie du log
  final String action;              // Code de l'action (ex: create_admin, order_placed)
  final String actionLabel;         // Label lisible (ex: "Création d'un administrateur")
  final String description;         // Description détaillée de l'action

  // === CIBLE ===
  final String? targetType;         // Type d'entité cible (user|product|order|admin|finance|setting)
  final String? targetId;           // ID de l'entité cible
  final String? targetLabel;        // Label de la cible (ex: "Commande #CMD-2025-001")

  // === DÉTAILS ===
  final Map<String, dynamic> metadata; // Données contextuelles

  // === CONTEXTE TECHNIQUE ===
  final String? ipAddress;          // Adresse IP
  final String? deviceInfo;         // Info appareil (Android 12, iOS 16, etc.)
  final GeoPoint? location;         // Localisation (optionnelle)

  // === SÉCURITÉ ===
  final AuditSeverity severity;     // Niveau de gravité
  final bool requiresReview;        // Nécessite revue par admin
  final bool isSuccessful;          // Action réussie ou échouée

  // === TIMESTAMPS ===
  final DateTime timestamp;         // Date/heure de l'action
  final DateTime? reviewedAt;       // Date de revue (si applicable)
  final String? reviewedBy;         // Admin qui a revu (si applicable)

  AuditLog({
    required this.id,
    required this.userId,
    required this.userType,
    required this.userEmail,
    this.userName,
    required this.category,
    required this.action,
    required this.actionLabel,
    required this.description,
    this.targetType,
    this.targetId,
    this.targetLabel,
    this.metadata = const {},
    this.ipAddress,
    this.deviceInfo,
    this.location,
    this.severity = AuditSeverity.low,
    this.requiresReview = false,
    this.isSuccessful = true,
    required this.timestamp,
    this.reviewedAt,
    this.reviewedBy,
  });

  /// Conversion depuis Firestore
  factory AuditLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return AuditLog(
      id: doc.id,
      userId: data['userId'] ?? '',
      userType: data['userType'] ?? '',
      userEmail: data['userEmail'] ?? '',
      userName: data['userName'],
      category: AuditCategory.values.firstWhere(
        (c) => c.name == data['category'],
        orElse: () => AuditCategory.system,
      ),
      action: data['action'] ?? '',
      actionLabel: data['actionLabel'] ?? '',
      description: data['description'] ?? '',
      targetType: data['targetType'],
      targetId: data['targetId'],
      targetLabel: data['targetLabel'],
      metadata: data['metadata'] as Map<String, dynamic>? ?? {},
      ipAddress: data['ipAddress'],
      deviceInfo: data['deviceInfo'],
      location: data['location'] as GeoPoint?,
      severity: AuditSeverity.values.firstWhere(
        (s) => s.name == data['severity'],
        orElse: () => AuditSeverity.low,
      ),
      requiresReview: data['requiresReview'] ?? false,
      isSuccessful: data['isSuccessful'] ?? true,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      reviewedAt: data['reviewedAt'] != null
          ? (data['reviewedAt'] as Timestamp).toDate()
          : null,
      reviewedBy: data['reviewedBy'],
    );
  }

  /// Conversion vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userType': userType,
      'userEmail': userEmail,
      'userName': userName,
      'category': category.name,
      'action': action,
      'actionLabel': actionLabel,
      'description': description,
      'targetType': targetType,
      'targetId': targetId,
      'targetLabel': targetLabel,
      'metadata': metadata,
      'ipAddress': ipAddress,
      'deviceInfo': deviceInfo,
      'location': location,
      'severity': severity.name,
      'requiresReview': requiresReview,
      'isSuccessful': isSuccessful,
      'timestamp': Timestamp.fromDate(timestamp),
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'reviewedBy': reviewedBy,
    };
  }

  /// Copie avec modifications
  AuditLog copyWith({
    String? id,
    String? userId,
    String? userType,
    String? userEmail,
    String? userName,
    AuditCategory? category,
    String? action,
    String? actionLabel,
    String? description,
    String? targetType,
    String? targetId,
    String? targetLabel,
    Map<String, dynamic>? metadata,
    String? ipAddress,
    String? deviceInfo,
    GeoPoint? location,
    AuditSeverity? severity,
    bool? requiresReview,
    bool? isSuccessful,
    DateTime? timestamp,
    DateTime? reviewedAt,
    String? reviewedBy,
  }) {
    return AuditLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userType: userType ?? this.userType,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
      category: category ?? this.category,
      action: action ?? this.action,
      actionLabel: actionLabel ?? this.actionLabel,
      description: description ?? this.description,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      targetLabel: targetLabel ?? this.targetLabel,
      metadata: metadata ?? this.metadata,
      ipAddress: ipAddress ?? this.ipAddress,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      location: location ?? this.location,
      severity: severity ?? this.severity,
      requiresReview: requiresReview ?? this.requiresReview,
      isSuccessful: isSuccessful ?? this.isSuccessful,
      timestamp: timestamp ?? this.timestamp,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
    );
  }

  /// Obtenir la couleur selon la sévérité
  String get severityColor {
    switch (severity) {
      case AuditSeverity.low:
        return '#4CAF50'; // Vert
      case AuditSeverity.medium:
        return '#FF9800'; // Orange
      case AuditSeverity.high:
        return '#F44336'; // Rouge
      case AuditSeverity.critical:
        return '#9C27B0'; // Violet
    }
  }

  /// Obtenir l'icône selon la catégorie
  String get categoryIcon {
    switch (category) {
      case AuditCategory.adminAction:
        return '🔧'; // Admin
      case AuditCategory.userAction:
        return '👤'; // Utilisateur
      case AuditCategory.security:
        return '🔒'; // Sécurité
      case AuditCategory.financial:
        return '💰'; // Finance
      case AuditCategory.system:
        return '⚙️'; // Système
    }
  }

  /// Obtenir le label de catégorie traduit
  String get categoryLabel {
    switch (category) {
      case AuditCategory.adminAction:
        return 'Action Admin';
      case AuditCategory.userAction:
        return 'Action Utilisateur';
      case AuditCategory.security:
        return 'Sécurité';
      case AuditCategory.financial:
        return 'Finance';
      case AuditCategory.system:
        return 'Système';
    }
  }

  /// Obtenir le label de sévérité traduit
  String get severityLabel {
    switch (severity) {
      case AuditSeverity.low:
        return 'Info';
      case AuditSeverity.medium:
        return 'Attention';
      case AuditSeverity.high:
        return 'Important';
      case AuditSeverity.critical:
        return 'Critique';
    }
  }
}

/// Extensions pour faciliter la création de logs
extension AuditLogExtension on AuditLog {
  /// Créer un log d'action admin
  static AuditLog createAdminLog({
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
    return AuditLog(
      id: '',
      userId: userId,
      userType: 'admin',
      userEmail: userEmail,
      userName: userName,
      category: AuditCategory.adminAction,
      action: action,
      actionLabel: actionLabel,
      description: description ?? actionLabel,
      targetType: targetType,
      targetId: targetId,
      targetLabel: targetLabel,
      metadata: metadata ?? {},
      severity: severity,
      requiresReview: requiresReview,
      timestamp: DateTime.now(),
    );
  }

  /// Créer un log d'action utilisateur
  static AuditLog createUserLog({
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
    return AuditLog(
      id: '',
      userId: userId,
      userType: userType,
      userEmail: userEmail,
      userName: userName,
      category: AuditCategory.userAction,
      action: action,
      actionLabel: actionLabel,
      description: description ?? actionLabel,
      targetType: targetType,
      targetId: targetId,
      targetLabel: targetLabel,
      metadata: metadata ?? {},
      severity: severity,
      timestamp: DateTime.now(),
    );
  }

  /// Créer un log de sécurité
  static AuditLog createSecurityLog({
    required String userId,
    required String userEmail,
    String? userName,
    required String action,
    required String actionLabel,
    String? description,
    Map<String, dynamic>? metadata,
    AuditSeverity severity = AuditSeverity.high,
    bool requiresReview = true,
    bool isSuccessful = true,
  }) {
    return AuditLog(
      id: '',
      userId: userId,
      userType: 'system',
      userEmail: userEmail,
      userName: userName,
      category: AuditCategory.security,
      action: action,
      actionLabel: actionLabel,
      description: description ?? actionLabel,
      metadata: metadata ?? {},
      severity: severity,
      requiresReview: requiresReview,
      isSuccessful: isSuccessful,
      timestamp: DateTime.now(),
    );
  }

  /// Créer un log financier
  static AuditLog createFinancialLog({
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
    return AuditLog(
      id: '',
      userId: userId,
      userType: userType,
      userEmail: userEmail,
      userName: userName,
      category: AuditCategory.financial,
      action: action,
      actionLabel: actionLabel,
      description: description ?? actionLabel,
      targetType: targetType,
      targetId: targetId,
      targetLabel: targetLabel,
      metadata: metadata ?? {},
      severity: severity,
      timestamp: DateTime.now(),
    );
  }
}

/// Constantes pour les actions courantes
class AuditActions {
  // === ADMIN ACTIONS ===
  static const String createAdmin = 'create_admin';
  static const String updateAdmin = 'update_admin';
  static const String deleteAdmin = 'delete_admin';
  static const String changePrivileges = 'change_privileges';
  static const String suspendUser = 'suspend_user';
  static const String reactivateUser = 'reactivate_user';
  static const String deleteUser = 'delete_user';
  static const String verifyKyc = 'verify_kyc';
  static const String deleteProduct = 'delete_product';
  static const String suspendShop = 'suspend_shop';
  static const String resolveReport = 'resolve_report';
  static const String viewFinance = 'view_finance';
  static const String adjustCommission = 'adjust_commission';
  static const String issueRefund = 'issue_refund';
  static const String changeSettings = 'change_settings';
  static const String exportReport = 'export_report';

  // === USER ACTIONS ===
  static const String orderPlaced = 'order_placed';
  static const String orderCancelled = 'order_cancelled';
  static const String reviewPosted = 'review_posted';
  static const String favoriteAdded = 'favorite_added';
  static const String productAdded = 'product_added';
  static const String productUpdated = 'product_updated';
  static const String productDeleted = 'product_deleted';
  static const String shopCreated = 'shop_created';
  static const String shopUpdated = 'shop_updated';
  static const String subscriptionPurchased = 'subscription_purchased';
  static const String orderShipped = 'order_shipped';
  static const String deliveryAccepted = 'delivery_accepted';
  static const String deliveryCompleted = 'delivery_completed';
  static const String deliveryFailed = 'delivery_failed';
  static const String zoneUpdated = 'zone_updated';

  // === SECURITY ACTIONS ===
  static const String loginSuccess = 'login_success';
  static const String loginFailed = 'login_failed';
  static const String logout = 'logout';
  static const String passwordChanged = 'password_changed';
  static const String passwordResetRequested = 'password_reset_requested';
  static const String unauthorizedAccess = 'unauthorized_access';
  static const String accountLocked = 'account_locked';
  static const String suspiciousActivity = 'suspicious_activity';

  // === FINANCIAL ACTIONS ===
  static const String paymentReceived = 'payment_received';
  static const String commissionCharged = 'commission_charged';
  static const String subscriptionPayment = 'subscription_payment';
  static const String refundIssued = 'refund_issued';
  static const String payoutProcessed = 'payout_processed';

  // === SYSTEM ACTIONS ===
  static const String dataMigration = 'data_migration';
  static const String backupCreated = 'backup_created';
  static const String errorOccurred = 'error_occurred';
}
