# Système d'Audit, Tracking et Rapports d'Activité

## Vue d'ensemble

Ce document décrit le **système unifié d'audit et de rapports d'activité** de SOCIAL BUSINESS Pro, conçu pour :
- 📊 Tracer toutes les activités des utilisateurs et administrateurs
- 🔍 Faciliter la résolution de conflits avec des preuves documentées
- 📈 Générer des rapports détaillés d'activité
- 🔒 Assurer la sécurité et la conformité de la plateforme
- 📄 Exporter des rapports en PDF/Excel pour analyse

## Objectifs du Système

### 1. **Traçabilité Complète**
Enregistrer automatiquement toutes les actions importantes effectuées sur la plateforme :
- Actions des administrateurs (création d'admin, suspension d'utilisateur, etc.)
- Actions des utilisateurs (commandes, ajout de produits, livraisons, etc.)
- Actions de sécurité (connexions, modifications de mot de passe, etc.)
- Transactions financières (paiements, commissions, abonnements, etc.)

### 2. **Résolution de Conflits**
Fournir des preuves irréfutables pour résoudre les litiges :
- Historique complet d'une commande (du panier à la livraison)
- Trace des modifications de produits ou de boutiques
- Historique des communications entre parties
- Calculs détaillés de commissions et paiements

### 3. **Audit de Sécurité**
Surveiller les activités suspectes et maintenir la sécurité :
- Tentatives de connexion échouées
- Accès non autorisés
- Modifications de privilèges administratifs
- Accès aux données financières sensibles

### 4. **Rapports et Analyse**
Permettre aux utilisateurs et admins de consulter et exporter leur activité :
- Rapport d'activité personnel pour chaque utilisateur
- Rapports globaux pour les administrateurs
- Export en PDF professionnel
- Export en CSV/Excel pour analyse

## Architecture du Système

### Structure des Fichiers

```
lib/
├── models/
│   ├── audit_log_model.dart              # Modèle de log d'audit unifié
│   ├── report_model.dart                  # Modèle de rapport généré
│   └── report_config_model.dart           # Configuration de rapport
│
├── services/
│   ├── audit_service.dart                 # Service central de logging
│   ├── report_generation_service.dart     # Génération de rapports
│   ├── pdf_export_service.dart            # Export PDF
│   └── csv_export_service.dart            # Export CSV/Excel
│
├── screens/
│   ├── admin/
│   │   ├── audit_logs_screen.dart         # Consultation logs d'audit (admins)
│   │   ├── global_reports_screen.dart     # Rapports globaux (admins)
│   │   └── user_activity_report_screen.dart # Rapport utilisateur spécifique
│   │
│   ├── shared/
│   │   └── my_activity_screen.dart        # Mon activité (tous utilisateurs)
│   │
│   └── reports/
│       ├── report_viewer_screen.dart      # Visionneuse de rapport
│       └── report_filter_dialog.dart      # Filtres de rapport
│
└── utils/
    ├── report_templates.dart              # Templates de rapports
    └── audit_helpers.dart                 # Helpers pour logging
```

## Modèles de Données

### 1. Modèle `AuditLog`

```dart
class AuditLog {
  final String id;

  // === ACTEUR ===
  final String userId;              // UID de l'utilisateur qui a agi
  final String userType;            // acheteur|vendeur|livreur|admin
  final String userEmail;           // Email de l'acteur
  final String? userName;           // Nom de l'acteur

  // === CATÉGORIE & ACTION ===
  final AuditCategory category;     // admin_action|user_action|security|financial|system
  final String action;              // create_admin|order_placed|login_failed|...
  final String actionLabel;         // "Création d'un administrateur"
  final String description;         // Description détaillée de l'action

  // === CIBLE ===
  final String? targetType;         // user|product|order|admin|finance|setting|...
  final String? targetId;           // ID de l'entité cible
  final String? targetLabel;        // "Commande #CMD-2025-001"

  // === DÉTAILS ===
  final Map<String, dynamic> metadata; // Données contextuelles

  // === CONTEXTE TECHNIQUE ===
  final String? ipAddress;          // Adresse IP
  final String? deviceInfo;         // Info appareil (Android 12, iOS 16, etc.)
  final GeoPoint? location;         // Localisation (optionnelle)

  // === SÉCURITÉ ===
  final AuditSeverity severity;     // low|medium|high|critical
  final bool requiresReview;        // Nécessite revue par admin
  final bool isSuccessful;          // Action réussie ou échouée

  // === TIMESTAMPS ===
  final DateTime timestamp;         // Date/heure de l'action
  final DateTime? reviewedAt;       // Date de revue (si applicable)
  final String? reviewedBy;         // Admin qui a revu (si applicable)
}

enum AuditCategory {
  adminAction,      // Actions administratives
  userAction,       // Actions utilisateurs normales
  security,         // Événements de sécurité
  financial,        // Transactions financières
  system,           // Événements système
}

enum AuditSeverity {
  low,              // Info normale
  medium,           // Attention requise
  high,             // Action importante
  critical,         // Action critique nécessitant revue
}
```

### 2. Modèle `GeneratedReport`

```dart
class GeneratedReport {
  final String id;
  final ReportType reportType;      // user_activity|admin_audit|global|financial|security|conflict
  final String generatedBy;         // UID de l'admin qui a généré
  final String? targetUserId;       // UID de l'utilisateur cible (null si global)
  final ReportPeriod period;        // Période du rapport
  final Map<String, dynamic> filters; // Filtres appliqués
  final ReportFormat format;        // pdf|csv|excel|html
  final String? fileUrl;            // URL du fichier dans Storage
  final String? fileName;           // Nom du fichier
  final int? fileSize;              // Taille en bytes
  final ReportStatus status;        // generating|ready|failed|expired
  final DateTime createdAt;
  final DateTime? expiresAt;        // Auto-suppression après 30 jours
  final Map<String, dynamic> summary; // Résumé des données du rapport
}

enum ReportType {
  userActivity,     // Activité d'un utilisateur spécifique
  adminAudit,       // Audit des actions admin
  globalActivity,   // Activité globale de la plateforme
  financial,        // Rapport financier (super admin only)
  security,         // Rapport de sécurité
  conflict,         // Rapport de résolution de conflit
}

enum ReportFormat {
  pdf,              // PDF professionnel
  csv,              // CSV (Excel compatible)
  excel,            // Excel natif (.xlsx)
  html,             // HTML (vue web)
}

enum ReportStatus {
  generating,       // En cours de génération
  ready,            // Prêt à télécharger
  failed,           // Échec de génération
  expired,          // Expiré (supprimé)
}

class ReportPeriod {
  final DateTime startDate;
  final DateTime endDate;
  final String label;  // "7 derniers jours", "Novembre 2025", etc.
}
```

### 3. Modèle `ReportConfig`

```dart
class ReportConfig {
  final String title;
  final String? subtitle;
  final ReportType type;
  final ReportPeriod period;
  final List<String> includedSections;  // Sections à inclure
  final Map<String, dynamic> filters;   // Filtres personnalisés
  final bool includeCharts;             // Inclure graphiques
  final bool includeMetadata;           // Inclure métadonnées techniques
  final String language;                // fr|en
  final String? logoUrl;                // URL du logo pour PDF
}
```

## Actions à Logger

### 🔴 **Catégorie : Admin Actions** (admin_action)

#### Gestion des Administrateurs
- `create_admin` - Création d'un administrateur
  - Metadata: `{adminEmail, adminRole, privileges[]}`
- `update_admin` - Modification d'un administrateur
  - Metadata: `{adminId, oldRole, newRole, privilegesChanged[]}`
- `delete_admin` - Suppression d'un administrateur
  - Metadata: `{adminId, adminEmail, reason}`
- `change_privileges` - Modification des privilèges
  - Metadata: `{adminId, addedPrivileges[], removedPrivileges[]}`

#### Gestion des Utilisateurs
- `suspend_user` - Suspension d'un utilisateur
  - Metadata: `{userId, userType, reason, duration}`
- `reactivate_user` - Réactivation d'un utilisateur
  - Metadata: `{userId, userType, suspendedSince}`
- `delete_user` - Suppression d'un utilisateur
  - Metadata: `{userId, userType, reason, dataRetained}`
- `verify_kyc` - Validation KYC vendeur/livreur
  - Metadata: `{userId, userType, documentsVerified[]}`

#### Modération de Contenu
- `delete_product` - Suppression d'un produit
  - Metadata: `{productId, productName, vendorId, reason}`
- `suspend_shop` - Suspension d'une boutique
  - Metadata: `{shopId, vendorId, reason, duration}`
- `resolve_report` - Résolution d'un signalement
  - Metadata: `{reportId, reportType, resolution, actionTaken}`

#### Gestion Financière
- `view_finance` - Consultation des données financières
  - Metadata: `{section: "revenues|commissions|subscriptions", period}`
- `adjust_commission` - Ajustement manuel de commission
  - Metadata: `{orderId, oldAmount, newAmount, reason}`
- `issue_refund` - Émission d'un remboursement
  - Metadata: `{orderId, amount, reason, userId}`

#### Paramètres Système
- `change_settings` - Modification des paramètres
  - Metadata: `{setting, oldValue, newValue}`
- `export_report` - Export de rapport
  - Metadata: `{reportType, period, format, targetUserId?}`

### 🔵 **Catégorie : User Actions** (user_action)

#### Actions Acheteur
- `order_placed` - Commande passée
  - Metadata: `{orderId, totalAmount, itemsCount, vendorId}`
- `order_cancelled` - Commande annulée
  - Metadata: `{orderId, reason, cancellationFee?}`
- `review_posted` - Avis publié
  - Metadata: `{reviewId, targetType, targetId, rating}`
- `favorite_added` - Favori ajouté
  - Metadata: `{targetType: "product|vendor", targetId}`

#### Actions Vendeur
- `product_added` - Produit ajouté
  - Metadata: `{productId, productName, category, price}`
- `product_updated` - Produit modifié
  - Metadata: `{productId, fieldsChanged[], oldPrice?, newPrice?}`
- `product_deleted` - Produit supprimé
  - Metadata: `{productId, productName, reason}`
- `shop_created` - Boutique créée
  - Metadata: `{shopId, shopName, category}`
- `shop_updated` - Boutique modifiée
  - Metadata: `{shopId, fieldsChanged[]}`
- `subscription_purchased` - Abonnement souscrit
  - Metadata: `{subscriptionTier, amount, duration}`
- `order_shipped` - Commande expédiée
  - Metadata: `{orderId, trackingNumber?, deliveryId?}`

#### Actions Livreur
- `delivery_accepted` - Livraison acceptée
  - Metadata: `{deliveryId, orderId, pickupLocation, deliveryLocation}`
- `delivery_completed` - Livraison complétée
  - Metadata: `{deliveryId, orderId, deliveryFee, commission}`
- `delivery_failed` - Échec de livraison
  - Metadata: `{deliveryId, orderId, reason}`
- `zone_updated` - Zone de livraison mise à jour
  - Metadata: `{zones[], addedZones[], removedZones[]}`

### 🟡 **Catégorie : Security** (security)

- `login_success` - Connexion réussie
  - Metadata: `{method: "email|google|phone"}`
- `login_failed` - Échec de connexion
  - Metadata: `{email, reason, attemptCount}`
- `logout` - Déconnexion
  - Metadata: `{sessionDuration}`
- `password_changed` - Mot de passe changé
  - Metadata: `{method: "reset|change"}`
- `password_reset_requested` - Demande de réinitialisation
  - Metadata: `{email}`
- `unauthorized_access` - Tentative d'accès non autorisé
  - Metadata: `{attemptedAction, requiredPrivilege}`
- `account_locked` - Compte verrouillé
  - Metadata: `{reason, lockDuration}`
- `suspicious_activity` - Activité suspecte détectée
  - Metadata: `{activityType, riskScore}`

### 🟢 **Catégorie : Financial** (financial)

- `payment_received` - Paiement reçu
  - Metadata: `{orderId, amount, method, transactionId}`
- `commission_charged` - Commission prélevée
  - Metadata: `{sourceId, sourceType, amount, rate, tier}`
- `subscription_payment` - Paiement d'abonnement
  - Metadata: `{subscriptionId, tier, amount, period}`
- `refund_issued` - Remboursement émis
  - Metadata: `{orderId, amount, reason, method}`
- `payout_processed` - Paiement vendeur/livreur traité
  - Metadata: `{userId, userType, amount, period}`

### 🟣 **Catégorie : System** (system)

- `data_migration` - Migration de données
  - Metadata: `{migrationType, recordsAffected}`
- `backup_created` - Sauvegarde créée
  - Metadata: `{backupSize, collections[]}`
- `error_occurred` - Erreur système
  - Metadata: `{errorType, errorMessage, stackTrace?}`

## Collections Firestore

### Collection `audit_logs`

```javascript
{
  "id": "auto_generated",

  // Acteur
  "userId": "uid_user_123",
  "userType": "admin",
  "userEmail": "admin@socialbusiness.com",
  "userName": "Jean Dupont",

  // Action
  "category": "admin_action",
  "action": "suspend_user",
  "actionLabel": "Suspension d'utilisateur",
  "description": "Suspension de l'utilisateur Marie Martin pour non-respect des CGU",

  // Cible
  "targetType": "user",
  "targetId": "uid_user_456",
  "targetLabel": "Marie Martin (marie@example.com)",

  // Détails
  "metadata": {
    "reason": "Non-respect des CGU - Produits contrefaits",
    "duration": "30 days",
    "previousViolations": 2,
    "evidenceUrls": ["..."],
  },

  // Contexte
  "ipAddress": "192.168.1.100",
  "deviceInfo": "Chrome 120 / Windows 11",
  "location": null,

  // Sécurité
  "severity": "high",
  "requiresReview": false,
  "isSuccessful": true,

  // Timestamps
  "timestamp": Timestamp(2025, 11, 28, 14, 30),
  "reviewedAt": null,
  "reviewedBy": null
}
```

#### Index Firestore Requis

```javascript
// Index composites nécessaires
audit_logs:
  - userId + timestamp (desc)
  - category + timestamp (desc)
  - targetType + targetId + timestamp (desc)
  - severity + timestamp (desc)
  - requiresReview + timestamp (desc)
  - action + timestamp (desc)
  - userId + category + timestamp (desc)
```

### Collection `generated_reports`

```javascript
{
  "id": "report_20251128_143045",
  "reportType": "user_activity",
  "generatedBy": "uid_admin_123",
  "targetUserId": "uid_vendor_456",
  "period": {
    "startDate": Timestamp(2025, 11, 1),
    "endDate": Timestamp(2025, 11, 30),
    "label": "Novembre 2025"
  },
  "filters": {
    "categories": ["user_action", "financial"],
    "actions": ["product_added", "order_shipped", "payment_received"]
  },
  "format": "pdf",
  "fileUrl": "gs://social-business-pro.appspot.com/reports/report_20251128_143045.pdf",
  "fileName": "Rapport_Activité_Vendeur_Nov2025.pdf",
  "fileSize": 2458624,  // bytes
  "status": "ready",
  "createdAt": Timestamp(2025, 11, 28, 14, 30),
  "expiresAt": Timestamp(2025, 12, 28, 14, 30),  // 30 jours
  "summary": {
    "totalLogs": 156,
    "productsAdded": 23,
    "ordersShipped": 45,
    "totalRevenue": 1250000,
    "totalCommissions": 187500
  }
}
```

## Services

### 1. `AuditService`

Service central pour enregistrer tous les logs d'audit.

```dart
class AuditService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Enregistrer un log d'audit
  static Future<String> log({
    required String userId,
    required String userType,
    required AuditCategory category,
    required String action,
    required String actionLabel,
    String? description,
    String? targetType,
    String? targetId,
    String? targetLabel,
    Map<String, dynamic>? metadata,
    AuditSeverity severity = AuditSeverity.low,
    bool requiresReview = false,
    bool isSuccessful = true,
  });

  /// Méthodes de convenance pour actions fréquentes
  static Future<String> logAdminAction(...);
  static Future<String> logUserAction(...);
  static Future<String> logSecurityEvent(...);
  static Future<String> logFinancialTransaction(...);

  /// Récupérer les logs d'un utilisateur
  static Future<List<AuditLog>> getUserLogs(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
    List<AuditCategory>? categories,
    int? limit,
  });

  /// Récupérer les logs globaux (admin only)
  static Future<List<AuditLog>> getGlobalLogs({
    DateTime? startDate,
    DateTime? endDate,
    List<AuditCategory>? categories,
    AuditSeverity? minSeverity,
    bool? requiresReview,
    int? limit,
  });

  /// Rechercher dans les logs
  static Future<List<AuditLog>> searchLogs({
    String? searchTerm,
    String? userId,
    String? targetId,
    List<String>? actions,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Marquer un log comme revu
  static Future<void> markAsReviewed(String logId, String reviewedBy);

  /// Obtenir les logs nécessitant une revue
  static Future<List<AuditLog>> getLogsRequiringReview();

  /// Statistiques d'audit
  static Future<Map<String, dynamic>> getAuditStats({
    DateTime? startDate,
    DateTime? endDate,
  });
}
```

### 2. `ReportGenerationService`

Service pour générer les rapports d'activité.

```dart
class ReportGenerationService {
  /// Générer un rapport d'activité utilisateur
  static Future<GeneratedReport> generateUserActivityReport({
    required String userId,
    required String generatedBy,
    required ReportPeriod period,
    List<AuditCategory>? categories,
    ReportFormat format = ReportFormat.pdf,
  });

  /// Générer un rapport d'audit admin
  static Future<GeneratedReport> generateAdminAuditReport({
    required String generatedBy,
    required ReportPeriod period,
    String? specificAdminId,
    ReportFormat format = ReportFormat.pdf,
  });

  /// Générer un rapport global d'activité
  static Future<GeneratedReport> generateGlobalActivityReport({
    required String generatedBy,
    required ReportPeriod period,
    ReportFormat format = ReportFormat.pdf,
  });

  /// Générer un rapport financier (super admin only)
  static Future<GeneratedReport> generateFinancialReport({
    required String generatedBy,
    required ReportPeriod period,
    ReportFormat format = ReportFormat.pdf,
  });

  /// Générer un rapport de résolution de conflit
  static Future<GeneratedReport> generateConflictReport({
    required String generatedBy,
    required String conflictType,  // "order"|"delivery"|"product"
    required String entityId,
    ReportFormat format = ReportFormat.pdf,
  });

  /// Obtenir un rapport généré
  static Future<GeneratedReport?> getReport(String reportId);

  /// Lister les rapports générés
  static Future<List<GeneratedReport>> listReports({
    String? generatedBy,
    String? targetUserId,
    ReportType? type,
    int? limit,
  });

  /// Supprimer un rapport
  static Future<void> deleteReport(String reportId);

  /// Nettoyer les rapports expirés
  static Future<int> cleanupExpiredReports();
}
```

### 3. `PDFExportService`

Service pour exporter les rapports en PDF.

```dart
class PDFExportService {
  /// Générer un PDF à partir d'un rapport
  static Future<File> generatePDF({
    required GeneratedReport report,
    required List<AuditLog> logs,
    Map<String, dynamic>? additionalData,
  });

  /// Templates de PDF
  static Future<File> generateUserActivityPDF(...);
  static Future<File> generateAdminAuditPDF(...);
  static Future<File> generateGlobalActivityPDF(...);
  static Future<File> generateFinancialPDF(...);
  static Future<File> generateConflictResolutionPDF(...);

  /// Uploader le PDF vers Firebase Storage
  static Future<String> uploadPDF(File pdfFile, String fileName);

  /// Télécharger un PDF
  static Future<File> downloadPDF(String fileUrl);
}
```

### 4. `CSVExportService`

Service pour exporter en CSV/Excel.

```dart
class CSVExportService {
  /// Générer un CSV à partir de logs
  static Future<File> generateCSV({
    required List<AuditLog> logs,
    required String fileName,
  });

  /// Générer un fichier Excel (.xlsx)
  static Future<File> generateExcel({
    required List<AuditLog> logs,
    required String fileName,
    bool includeCharts = false,
  });
}
```

## Interfaces Utilisateur

### 1. Écran "Logs d'Audit" (Admin)

**Accès** : Tous les admins (privilège `viewAdmins` ou `viewReports`)

**Fonctionnalités** :
- Liste de tous les logs d'audit
- Filtres :
  - Période (aujourd'hui, 7j, 30j, personnalisé)
  - Catégorie (admin, user, security, financial, system)
  - Sévérité (low, medium, high, critical)
  - Utilisateur spécifique
  - Action spécifique
  - Nécessite revue (oui/non)
- Recherche full-text
- Tri (date, sévérité, catégorie)
- Vue détaillée d'un log avec tous les metadata
- Actions :
  - Marquer comme revu
  - Exporter en PDF/CSV
  - Générer rapport pour utilisateur spécifique

**UI** :
```
┌─────────────────────────────────────────────────┐
│ 📋 Logs d'Audit                      [Filtres 🔍]│
├─────────────────────────────────────────────────┤
│ [Période ▼] [Catégorie ▼] [Sévérité ▼]         │
│ [Rechercher...]                      [Export 📥] │
├─────────────────────────────────────────────────┤
│ ⚠️ CRITIQUE - 28/11/2025 14:30                 │
│ Tentative d'accès non autorisé                  │
│ user@example.com → Finances                     │
│ [Voir détails]                        [Revoir ✓]│
├─────────────────────────────────────────────────┤
│ ℹ️ INFO - 28/11/2025 14:25                      │
│ Commande passée                                  │
│ acheteur@example.com → CMD-2025-001             │
│ [Voir détails]                                   │
├─────────────────────────────────────────────────┤
│ ...                                              │
└─────────────────────────────────────────────────┘
```

### 2. Écran "Mon Activité" (Tous Utilisateurs)

**Accès** : Tous les utilisateurs authentifiés

**Fonctionnalités** :
- Historique de mes propres actions
- Filtres par période
- Vue chronologique
- Export de mon activité en PDF
- Statistiques personnelles

**UI** :
```
┌─────────────────────────────────────────────────┐
│ 📊 Mon Activité                                  │
├─────────────────────────────────────────────────┤
│ [7 derniers jours ▼]              [Export PDF 📄]│
├─────────────────────────────────────────────────┤
│ 📈 Résumé                                        │
│ • 15 commandes passées                           │
│ • 3 avis publiés                                 │
│ • 45 000 FCFA dépensés                          │
├─────────────────────────────────────────────────┤
│ 📅 Activité récente                             │
│                                                  │
│ 🛒 28/11/2025 14:25                             │
│ Commande passée - CMD-2025-001                   │
│ Montant: 25 000 FCFA                            │
│                                                  │
│ ⭐ 27/11/2025 10:15                             │
│ Avis publié - Produit "T-shirt Nike"            │
│ Note: 5/5                                        │
│                                                  │
│ ...                                              │
└─────────────────────────────────────────────────┘
```

### 3. Écran "Rapports Globaux" (Super Admin)

**Accès** : Super Admin uniquement

**Fonctionnalités** :
- Générer différents types de rapports
- Consulter les rapports générés
- Télécharger les rapports
- Supprimer les rapports

**UI** :
```
┌─────────────────────────────────────────────────┐
│ 📊 Rapports Globaux                              │
├─────────────────────────────────────────────────┤
│ 📝 Générer un nouveau rapport                    │
│                                                  │
│ Type de rapport:                                 │
│ [Activité Globale ▼]                            │
│                                                  │
│ Période:                                         │
│ Du: [01/11/2025] Au: [30/11/2025]              │
│                                                  │
│ Format:                                          │
│ ( ) PDF  (•) Excel  ( ) CSV                     │
│                                                  │
│              [Générer le rapport 🚀]            │
├─────────────────────────────────────────────────┤
│ 📂 Rapports récents                             │
│                                                  │
│ 📄 Rapport_Global_Nov2025.pdf                   │
│ Généré le 28/11/2025 - 2.4 Mo                   │
│ [Télécharger 📥] [Supprimer 🗑️]                │
│                                                  │
│ 📊 Rapport_Financier_Nov2025.xlsx               │
│ Généré le 25/11/2025 - 856 Ko                   │
│ [Télécharger 📥] [Supprimer 🗑️]                │
│                                                  │
└─────────────────────────────────────────────────┘
```

### 4. Écran "Rapport Utilisateur Spécifique" (Admin)

**Accès** : Admin avec privilège `viewUsers`

**Fonctionnalités** :
- Sélectionner un utilisateur
- Générer son rapport d'activité
- Filtres personnalisés
- Export multi-format

## Templates de Rapports PDF

### 1. Rapport d'Activité Utilisateur

**Structure** :
```
┌─────────────────────────────────────────────────┐
│ [LOGO SOCIAL BUSINESS PRO]                      │
│                                                  │
│         RAPPORT D'ACTIVITÉ UTILISATEUR          │
│                                                  │
│ Utilisateur: Jean Dupont                        │
│ Type: Vendeur                                    │
│ Email: jean@example.com                         │
│ Période: 01/11/2025 - 30/11/2025               │
│ Généré le: 28/11/2025 à 14:30                  │
├─────────────────────────────────────────────────┤
│                                                  │
│ 📊 RÉSUMÉ D'ACTIVITÉ                            │
│                                                  │
│ • Produits ajoutés: 12                          │
│ • Commandes expédiées: 45                       │
│ • Revenus générés: 1 250 000 FCFA              │
│ • Commissions payées: 187 500 FCFA             │
│ • Note moyenne: 4.8/5                           │
│                                                  │
├─────────────────────────────────────────────────┤
│                                                  │
│ 📈 GRAPHIQUE D'ÉVOLUTION                        │
│                                                  │
│ [Graphique courbe des ventes]                   │
│                                                  │
├─────────────────────────────────────────────────┤
│                                                  │
│ 📋 DÉTAIL DES ACTIVITÉS                         │
│                                                  │
│ 28/11/2025 14:25 - Commande expédiée            │
│ CMD-2025-045 - 35 000 FCFA                      │
│                                                  │
│ 27/11/2025 10:15 - Produit ajouté               │
│ "Chaussures Nike Air Max"                       │
│                                                  │
│ ...                                              │
│                                                  │
├─────────────────────────────────────────────────┤
│ Page 1/3                                         │
└─────────────────────────────────────────────────┘
```

### 2. Rapport de Résolution de Conflit

**Structure** :
```
┌─────────────────────────────────────────────────┐
│ [LOGO SOCIAL BUSINESS PRO]                      │
│                                                  │
│      RAPPORT DE RÉSOLUTION DE CONFLIT           │
│                                                  │
│ Type de conflit: Litige sur commande            │
│ Commande: CMD-2025-034                          │
│ Date du conflit: 25/11/2025                     │
│ Parties impliquées:                              │
│ • Acheteur: Marie Martin (marie@example.com)    │
│ • Vendeur: Shop Tech (vendor@example.com)       │
│                                                  │
├─────────────────────────────────────────────────┤
│                                                  │
│ 📋 CHRONOLOGIE COMPLÈTE                         │
│                                                  │
│ 20/11/2025 10:00 - Commande passée              │
│ Montant: 45 000 FCFA                            │
│ Produit: "Smartphone Samsung Galaxy"            │
│                                                  │
│ 20/11/2025 15:30 - Paiement confirmé            │
│ Méthode: Mobile Money                           │
│ Transaction ID: TXN-789456                       │
│                                                  │
│ 21/11/2025 09:00 - Commande expédiée            │
│ Numéro de suivi: TRACK-123456                   │
│                                                  │
│ 22/11/2025 14:00 - Livraison effectuée          │
│ Livreur: Amadou Diallo                          │
│                                                  │
│ 25/11/2025 10:00 - Réclamation acheteur         │
│ Motif: "Produit défectueux"                     │
│                                                  │
│ 25/11/2025 16:00 - Réponse vendeur              │
│ Message: "Produit testé avant envoi"            │
│                                                  │
├─────────────────────────────────────────────────┤
│                                                  │
│ 🔍 PREUVES                                      │
│                                                  │
│ • Photos produit avant expédition (3)           │
│ • Preuve de livraison avec signature            │
│ • Messages échangés (12)                        │
│ • Photos produit reçu par acheteur (5)          │
│                                                  │
├─────────────────────────────────────────────────┤
│                                                  │
│ ⚖️ RÉSOLUTION RECOMMANDÉE                       │
│                                                  │
│ Basée sur l'analyse des preuves:                │
│ • Le produit a été correctement emballé         │
│ • Problème survenu après réception              │
│                                                  │
│ Recommandation:                                  │
│ Remboursement partiel de 50% (22 500 FCFA)     │
│                                                  │
│ Rapport généré le: 28/11/2025 à 14:30          │
│ Par: Admin Jean Dupont                          │
│                                                  │
└─────────────────────────────────────────────────┘
```

## Cas d'Usage Détaillés

### Cas 1 : Litige sur une Commande

**Scénario** : Un acheteur prétend ne pas avoir reçu sa commande, le vendeur affirme l'avoir envoyée.

**Solution avec le système** :
1. Admin accède à "Rapports Globaux"
2. Sélectionne "Rapport de Conflit"
3. Entre le numéro de commande
4. Le système génère un PDF avec :
   - Chronologie complète (commande → paiement → expédition → livraison)
   - Captures d'écran des communications
   - Preuves de paiement
   - Informations du livreur
   - Géolocalisation de la livraison (si disponible)
5. Admin prend une décision éclairée
6. L'action admin est elle-même loggée pour traçabilité

### Cas 2 : Contestation de Commission

**Scénario** : Un vendeur conteste le montant de commission prélevé.

**Solution** :
1. Admin génère le rapport financier du vendeur
2. Le PDF contient :
   - Détail de chaque transaction
   - Taux de commission appliqué selon le tier d'abonnement
   - Calculs étape par étape
   - Historique d'abonnement (changements de tier)
3. Vendeur reçoit le rapport par email
4. Transparence totale = conflit résolu

### Cas 3 : Audit de Sécurité

**Scénario** : Activité suspecte détectée sur un compte admin.

**Solution** :
1. Système détecte tentative d'accès aux finances à 3h du matin
2. Log automatique avec sévérité "critical" et requiresReview=true
3. Super Admin reçoit une alerte
4. Consulte les logs de sécurité de cet admin
5. Génère un rapport d'audit complet
6. Décide de révoquer l'accès
7. Toutes ces actions sont loggées

### Cas 4 : Analyse de Performance Vendeur

**Scénario** : Vendeur veut comprendre l'évolution de ses ventes.

**Solution** :
1. Vendeur accède à "Mon Activité"
2. Sélectionne la période (ex: 3 derniers mois)
3. Génère un rapport PDF
4. Le rapport contient :
   - Graphique d'évolution des ventes
   - Produits les plus vendus
   - Notes et avis reçus
   - Commissions payées
   - Comparaison mois par mois
5. Vendeur peut exporter en Excel pour analyse personnelle

## Sécurité et Conformité

### Règles de Sécurité Firestore

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Fonction: vérifier si super admin
    function isSuperAdmin() {
      return request.auth != null
        && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isSuperAdmin == true;
    }

    // Fonction: vérifier si admin
    function isAdmin() {
      return request.auth != null
        && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.userType == 'admin';
    }

    // Collection audit_logs
    match /audit_logs/{logId} {
      // Lecture: utilisateur peut voir ses propres logs
      allow read: if request.auth != null
        && (resource.data.userId == request.auth.uid || isAdmin());

      // Écriture: backend uniquement (via Cloud Functions ou Admin SDK)
      allow create: if request.auth != null;

      // Modification: admin peut marquer comme revu
      allow update: if isAdmin()
        && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['reviewedAt', 'reviewedBy']);

      // Suppression: super admin uniquement
      allow delete: if isSuperAdmin();
    }

    // Collection generated_reports
    match /generated_reports/{reportId} {
      // Lecture: celui qui a généré ou le sujet du rapport
      allow read: if request.auth != null
        && (resource.data.generatedBy == request.auth.uid
            || resource.data.targetUserId == request.auth.uid
            || isAdmin());

      // Création: admin uniquement
      allow create: if isAdmin();

      // Modification: système uniquement (mise à jour du status)
      allow update: if false;

      // Suppression: celui qui a généré ou super admin
      allow delete: if request.auth != null
        && (resource.data.generatedBy == request.auth.uid || isSuperAdmin());
    }
  }
}
```

### Règles de Sécurité Firebase Storage

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {

    // Rapports PDF/CSV
    match /reports/{reportId} {
      // Lecture: utilisateur concerné ou admin
      allow read: if request.auth != null;

      // Écriture: backend uniquement
      allow write: if false;
    }
  }
}
```

### Protection des Données Sensibles

#### Données à Anonymiser (si RGPD applicable)
- Adresses IP (hasher après 30 jours)
- Informations de localisation précises
- Métadonnées de device trop spécifiques

#### Données à Supprimer
- Logs de plus de 2 ans (sauf logs financiers: 10 ans)
- Rapports expirés (30 jours par défaut)
- Logs d'utilisateurs supprimés (après 90 jours)

#### Chiffrement
- Métadonnées sensibles chiffrées dans Firestore
- PDFs stockés avec encryption at rest (Firebase Storage par défaut)
- Transmission via HTTPS uniquement

## Performance et Optimisation

### Indexation

```javascript
// firestore.indexes.json
{
  "indexes": [
    {
      "collectionGroup": "audit_logs",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "userId", "order": "ASCENDING"},
        {"fieldPath": "timestamp", "order": "DESCENDING"}
      ]
    },
    {
      "collectionGroup": "audit_logs",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "category", "order": "ASCENDING"},
        {"fieldPath": "timestamp", "order": "DESCENDING"}
      ]
    },
    {
      "collectionGroup": "audit_logs",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "targetType", "order": "ASCENDING"},
        {"fieldPath": "targetId", "order": "ASCENDING"},
        {"fieldPath": "timestamp", "order": "DESCENDING"}
      ]
    },
    {
      "collectionGroup": "audit_logs",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "severity", "order": "DESCENDING"},
        {"fieldPath": "timestamp", "order": "DESCENDING"}
      ]
    },
    {
      "collectionGroup": "audit_logs",
      "queryScope": "COLLECTION",
      "fields": [
        {"fieldPath": "requiresReview", "order": "ASCENDING"},
        {"fieldPath": "timestamp", "order": "DESCENDING"}
      ]
    }
  ]
}
```

### Pagination

- Utiliser `limit()` et `startAfter()` pour paginer les logs
- Limiter à 50 logs par page par défaut
- Cache côté client pour logs récemment consultés

### Génération Asynchrone de Rapports

- Rapports PDF générés en background (Cloud Functions)
- Notification push quand le rapport est prêt
- Upload du PDF vers Storage
- URL de téléchargement fournie à l'utilisateur

### Nettoyage Automatique

```dart
// Cloud Function (à exécuter quotidiennement)
exports.cleanupExpiredReports = functions.pubsub
  .schedule('0 2 * * *')  // Tous les jours à 2h du matin
  .onRun(async (context) => {
    const expiredReports = await admin.firestore()
      .collection('generated_reports')
      .where('expiresAt', '<', admin.firestore.Timestamp.now())
      .get();

    for (const doc of expiredReports.docs) {
      // Supprimer le fichier de Storage
      await admin.storage().bucket().file(doc.data().fileName).delete();
      // Supprimer le document Firestore
      await doc.ref.delete();
    }

    return null;
  });
```

## Roadmap et Évolutions Futures

### Phase 1 (Actuelle) : Foundation
- ✅ Modèles de données
- ✅ Service d'audit
- ✅ Logs automatiques pour actions critiques
- ✅ Interface de consultation des logs

### Phase 2 : Rapports de Base
- ✅ Génération de rapports HTML/Web
- ✅ Export PDF basique
- ✅ Export CSV
- ✅ Écran "Mon Activité"

### Phase 3 : Rapports Avancés
- ✅ Templates PDF professionnels
- ✅ Graphiques et visualisations
- ✅ Rapport de résolution de conflit
- ✅ Envoi par email

### Phase 4 (Future) : Intelligence
- ⏳ Détection automatique d'anomalies
- ⏳ Alertes en temps réel
- ⏳ Rapports prédictifs
- ⏳ Tableau de bord analytique
- ⏳ Machine Learning pour fraude detection

### Phase 5 (Future) : Conformité
- ⏳ Conformité RGPD complète
- ⏳ Droit à l'oubli automatisé
- ⏳ Export de données utilisateur
- ⏳ Audit trail immuable (blockchain?)

## Packages Flutter Nécessaires

```yaml
dependencies:
  # Core
  cloud_firestore: ^5.0.0
  firebase_storage: ^12.0.0

  # PDF Generation
  pdf: ^3.10.0
  printing: ^5.11.0

  # Excel/CSV
  excel: ^4.0.0
  csv: ^6.0.0

  # Charts
  fl_chart: ^0.66.0
  syncfusion_flutter_charts: ^24.0.0

  # Date/Time
  intl: ^0.19.0

  # File handling
  path_provider: ^2.1.0
  open_file: ^3.3.0

  # Email
  mailer: ^6.0.0  # Si envoi d'email depuis le backend
```

## Exemples de Code

### Logger une action admin

```dart
await AuditService.logAdminAction(
  userId: currentUser.uid,
  userType: 'admin',
  action: 'suspend_user',
  actionLabel: 'Suspension d\'utilisateur',
  description: 'Suspension de Marie Martin pour non-respect des CGU',
  targetType: 'user',
  targetId: targetUser.uid,
  targetLabel: '${targetUser.displayName} (${targetUser.email})',
  metadata: {
    'reason': 'Non-respect des CGU - Produits contrefaits',
    'duration': '30 days',
    'previousViolations': 2,
  },
  severity: AuditSeverity.high,
);
```

### Générer un rapport utilisateur

```dart
final report = await ReportGenerationService.generateUserActivityReport(
  userId: vendorId,
  generatedBy: adminId,
  period: ReportPeriod(
    startDate: DateTime(2025, 11, 1),
    endDate: DateTime(2025, 11, 30),
    label: 'Novembre 2025',
  ),
  categories: [
    AuditCategory.userAction,
    AuditCategory.financial,
  ],
  format: ReportFormat.pdf,
);

// Télécharger le PDF
final pdfFile = await PDFExportService.downloadPDF(report.fileUrl!);
await OpenFile.open(pdfFile.path);
```

### Rechercher dans les logs

```dart
final logs = await AuditService.searchLogs(
  searchTerm: 'CMD-2025-034',
  startDate: DateTime(2025, 11, 20),
  endDate: DateTime(2025, 11, 28),
);
```

## FAQ

### Q : Combien de temps les logs sont-ils conservés ?
**R** : Par défaut, 2 ans pour les logs normaux, 10 ans pour les logs financiers (conformité comptable).

### Q : Les utilisateurs peuvent-ils supprimer leurs logs ?
**R** : Non, pour garantir l'intégrité de l'audit. En cas de suppression de compte, les logs sont anonymisés après 90 jours.

### Q : Les rapports PDF sont-ils sécurisés ?
**R** : Oui, stockés avec encryption at rest, URLs signées avec expiration, accès contrôlé par règles Firestore.

### Q : Peut-on générer un rapport pour plusieurs utilisateurs ?
**R** : Oui, via le rapport global qui agrège les données de tous les utilisateurs (admin/super admin uniquement).

### Q : Les logs peuvent-ils être modifiés ?
**R** : Non, sauf le champ `reviewedAt`/`reviewedBy` par les admins. Les logs sont immuables pour garantir l'intégrité.

### Q : Comment sont détectées les activités suspectes ?
**R** : Via des règles prédéfinies (ex: 5 tentatives de connexion échouées en 10 min, accès à des données sensibles à des heures inhabituelles).

## Conclusion

Ce système d'audit et de rapports fournit :
- ✅ **Traçabilité complète** de toutes les activités
- ✅ **Résolution de conflits** basée sur des preuves
- ✅ **Sécurité renforcée** avec détection d'anomalies
- ✅ **Transparence** pour tous les utilisateurs
- ✅ **Conformité** aux exigences légales et réglementaires

Il constitue un pilier fondamental pour la confiance et la sécurité de la plateforme SOCIAL BUSINESS Pro.

---

**Document créé le** : 28 Novembre 2025
**Version** : 1.0
**Auteur** : Équipe SOCIAL BUSINESS Pro
