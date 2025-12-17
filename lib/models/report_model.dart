// ===== lib/models/report_model.dart =====
// Modèles pour les rapports générés

import 'package:cloud_firestore/cloud_firestore.dart';

/// Types de rapports
enum ReportType {
  userActivity,     // Activité d'un utilisateur spécifique
  adminAudit,       // Audit des actions admin
  globalActivity,   // Activité globale de la plateforme
  financial,        // Rapport financier (super admin only)
  security,         // Rapport de sécurité
  conflict,         // Rapport de résolution de conflit
}

/// Formats de rapport
enum ReportFormat {
  pdf,              // PDF professionnel
  csv,              // CSV (Excel compatible)
  excel,            // Excel natif (.xlsx)
  html,             // HTML (vue web)
}

/// Statuts de rapport
enum ReportStatus {
  generating,       // En cours de génération
  ready,            // Prêt à télécharger
  failed,           // Échec de génération
  expired,          // Expiré (supprimé)
}

/// Période de rapport
class ReportPeriod {
  final DateTime startDate;
  final DateTime endDate;
  final String label;  // "7 derniers jours", "Novembre 2025", etc.

  ReportPeriod({
    required this.startDate,
    required this.endDate,
    required this.label,
  });

  /// Créer une période prédéfinie
  factory ReportPeriod.last7Days() {
    final now = DateTime.now();
    return ReportPeriod(
      startDate: now.subtract(const Duration(days: 7)),
      endDate: now,
      label: '7 derniers jours',
    );
  }

  factory ReportPeriod.last30Days() {
    final now = DateTime.now();
    return ReportPeriod(
      startDate: now.subtract(const Duration(days: 30)),
      endDate: now,
      label: '30 derniers jours',
    );
  }

  factory ReportPeriod.last3Months() {
    final now = DateTime.now();
    return ReportPeriod(
      startDate: DateTime(now.year, now.month - 3, now.day),
      endDate: now,
      label: '3 derniers mois',
    );
  }

  factory ReportPeriod.currentMonth() {
    final now = DateTime.now();
    return ReportPeriod(
      startDate: DateTime(now.year, now.month, 1),
      endDate: now,
      label: 'Mois en cours',
    );
  }

  factory ReportPeriod.lastMonth() {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1, 1);
    final lastDayOfLastMonth = DateTime(now.year, now.month, 0);
    return ReportPeriod(
      startDate: lastMonth,
      endDate: lastDayOfLastMonth,
      label: 'Mois dernier',
    );
  }

  factory ReportPeriod.custom(DateTime start, DateTime end, String label) {
    return ReportPeriod(
      startDate: start,
      endDate: end,
      label: label,
    );
  }

  /// Conversion vers Map
  Map<String, dynamic> toMap() {
    return {
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'label': label,
    };
  }

  /// Conversion depuis Map
  factory ReportPeriod.fromMap(Map<String, dynamic> map) {
    return ReportPeriod(
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      label: map['label'] ?? '',
    );
  }

  /// Nombre de jours dans la période
  int get daysCount => endDate.difference(startDate).inDays + 1;
}

/// Modèle de rapport généré
class GeneratedReport {
  final String id;
  final ReportType reportType;      // Type de rapport
  final String generatedBy;         // UID de l'admin qui a généré
  final String? targetUserId;       // UID de l'utilisateur cible (null si global)
  final ReportPeriod period;        // Période du rapport
  final Map<String, dynamic> filters; // Filtres appliqués
  final ReportFormat format;        // Format du rapport
  final String? fileUrl;            // URL du fichier dans Storage
  final String? fileName;           // Nom du fichier
  final int? fileSize;              // Taille en bytes
  final ReportStatus status;        // Statut du rapport
  final DateTime createdAt;
  final DateTime? expiresAt;        // Auto-suppression après 30 jours
  final Map<String, dynamic> summary; // Résumé des données du rapport
  final String? errorMessage;       // Message d'erreur si failed

  GeneratedReport({
    required this.id,
    required this.reportType,
    required this.generatedBy,
    this.targetUserId,
    required this.period,
    this.filters = const {},
    required this.format,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    required this.status,
    required this.createdAt,
    this.expiresAt,
    this.summary = const {},
    this.errorMessage,
  });

  /// Conversion depuis Firestore
  factory GeneratedReport.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return GeneratedReport(
      id: doc.id,
      reportType: ReportType.values.firstWhere(
        (t) => t.name == data['reportType'],
        orElse: () => ReportType.userActivity,
      ),
      generatedBy: data['generatedBy'] ?? '',
      targetUserId: data['targetUserId'],
      period: ReportPeriod.fromMap(data['period'] as Map<String, dynamic>),
      filters: data['filters'] as Map<String, dynamic>? ?? {},
      format: ReportFormat.values.firstWhere(
        (f) => f.name == data['format'],
        orElse: () => ReportFormat.pdf,
      ),
      fileUrl: data['fileUrl'],
      fileName: data['fileName'],
      fileSize: data['fileSize'],
      status: ReportStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => ReportStatus.generating,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: data['expiresAt'] != null
          ? (data['expiresAt'] as Timestamp).toDate()
          : null,
      summary: data['summary'] as Map<String, dynamic>? ?? {},
      errorMessage: data['errorMessage'],
    );
  }

  /// Conversion vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'reportType': reportType.name,
      'generatedBy': generatedBy,
      'targetUserId': targetUserId,
      'period': period.toMap(),
      'filters': filters,
      'format': format.name,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'summary': summary,
      'errorMessage': errorMessage,
    };
  }

  /// Copie avec modifications
  GeneratedReport copyWith({
    String? id,
    ReportType? reportType,
    String? generatedBy,
    String? targetUserId,
    ReportPeriod? period,
    Map<String, dynamic>? filters,
    ReportFormat? format,
    String? fileUrl,
    String? fileName,
    int? fileSize,
    ReportStatus? status,
    DateTime? createdAt,
    DateTime? expiresAt,
    Map<String, dynamic>? summary,
    String? errorMessage,
  }) {
    return GeneratedReport(
      id: id ?? this.id,
      reportType: reportType ?? this.reportType,
      generatedBy: generatedBy ?? this.generatedBy,
      targetUserId: targetUserId ?? this.targetUserId,
      period: period ?? this.period,
      filters: filters ?? this.filters,
      format: format ?? this.format,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      summary: summary ?? this.summary,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Vérifier si le rapport est expiré
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Vérifier si le rapport est prêt
  bool get isReady => status == ReportStatus.ready && fileUrl != null;

  /// Obtenir le label du type de rapport
  String get typeLabel {
    switch (reportType) {
      case ReportType.userActivity:
        return 'Activité Utilisateur';
      case ReportType.adminAudit:
        return 'Audit Admin';
      case ReportType.globalActivity:
        return 'Activité Globale';
      case ReportType.financial:
        return 'Rapport Financier';
      case ReportType.security:
        return 'Rapport de Sécurité';
      case ReportType.conflict:
        return 'Résolution de Conflit';
    }
  }

  /// Obtenir le label du format
  String get formatLabel {
    switch (format) {
      case ReportFormat.pdf:
        return 'PDF';
      case ReportFormat.csv:
        return 'CSV';
      case ReportFormat.excel:
        return 'Excel';
      case ReportFormat.html:
        return 'HTML';
    }
  }

  /// Obtenir le label du statut
  String get statusLabel {
    switch (status) {
      case ReportStatus.generating:
        return 'En cours de génération...';
      case ReportStatus.ready:
        return 'Prêt';
      case ReportStatus.failed:
        return 'Échec';
      case ReportStatus.expired:
        return 'Expiré';
    }
  }

  /// Obtenir l'icône du statut
  String get statusIcon {
    switch (status) {
      case ReportStatus.generating:
        return '⏳';
      case ReportStatus.ready:
        return '✅';
      case ReportStatus.failed:
        return '❌';
      case ReportStatus.expired:
        return '🗑️';
    }
  }

  /// Obtenir l'extension du fichier
  String get fileExtension {
    switch (format) {
      case ReportFormat.pdf:
        return 'pdf';
      case ReportFormat.csv:
        return 'csv';
      case ReportFormat.excel:
        return 'xlsx';
      case ReportFormat.html:
        return 'html';
    }
  }

  /// Formater la taille du fichier
  String get fileSizeFormatted {
    if (fileSize == null) return 'N/A';

    if (fileSize! < 1024) {
      return '$fileSize bytes';
    } else if (fileSize! < 1024 * 1024) {
      return '${(fileSize! / 1024).toStringAsFixed(1)} Ko';
    } else {
      return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} Mo';
    }
  }

  /// Jours restants avant expiration
  int? get daysUntilExpiration {
    if (expiresAt == null) return null;
    final diff = expiresAt!.difference(DateTime.now());
    return diff.inDays;
  }
}

/// Configuration de rapport
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

  ReportConfig({
    required this.title,
    this.subtitle,
    required this.type,
    required this.period,
    this.includedSections = const [],
    this.filters = const {},
    this.includeCharts = true,
    this.includeMetadata = false,
    this.language = 'fr',
    this.logoUrl,
  });

  /// Conversion vers Map
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'type': type.name,
      'period': period.toMap(),
      'includedSections': includedSections,
      'filters': filters,
      'includeCharts': includeCharts,
      'includeMetadata': includeMetadata,
      'language': language,
      'logoUrl': logoUrl,
    };
  }

  /// Conversion depuis Map
  factory ReportConfig.fromMap(Map<String, dynamic> map) {
    return ReportConfig(
      title: map['title'] ?? '',
      subtitle: map['subtitle'],
      type: ReportType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => ReportType.userActivity,
      ),
      period: ReportPeriod.fromMap(map['period'] as Map<String, dynamic>),
      includedSections: List<String>.from(map['includedSections'] ?? []),
      filters: map['filters'] as Map<String, dynamic>? ?? {},
      includeCharts: map['includeCharts'] ?? true,
      includeMetadata: map['includeMetadata'] ?? false,
      language: map['language'] ?? 'fr',
      logoUrl: map['logoUrl'],
    );
  }

  /// Copie avec modifications
  ReportConfig copyWith({
    String? title,
    String? subtitle,
    ReportType? type,
    ReportPeriod? period,
    List<String>? includedSections,
    Map<String, dynamic>? filters,
    bool? includeCharts,
    bool? includeMetadata,
    String? language,
    String? logoUrl,
  }) {
    return ReportConfig(
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      type: type ?? this.type,
      period: period ?? this.period,
      includedSections: includedSections ?? this.includedSections,
      filters: filters ?? this.filters,
      includeCharts: includeCharts ?? this.includeCharts,
      includeMetadata: includeMetadata ?? this.includeMetadata,
      language: language ?? this.language,
      logoUrl: logoUrl ?? this.logoUrl,
    );
  }
}
