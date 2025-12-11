// ===== lib/services/global_report_service.dart =====
// Service de génération de rapports globaux pour admins

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:csv/csv.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/audit_log_model.dart';
import '../models/report_model.dart';
import '../services/audit_service.dart';

/// Service de génération de rapports globaux pour admins
/// Gère la création, le stockage et la gestion des rapports
class GlobalReportService {
  static final _dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');
  static final _fileDateFormat = DateFormat('yyyyMMdd_HHmmss');
  static const _reportsCollection = 'generated_reports';
  static const _storageFolder = 'reports';

  /// Générer un rapport complet
  ///
  /// Cette méthode orchestre la génération complète d'un rapport:
  /// 1. Crée l'entrée Firestore avec statut "generating"
  /// 2. Collecte les données selon le type de rapport
  /// 3. Génère le fichier (PDF/CSV/Excel/HTML)
  /// 4. Upload vers Firebase Storage
  /// 5. Met à jour l'entrée Firestore avec l'URL et statut "ready"
  static Future<String> generateReport({
    required ReportType reportType,
    required String generatedBy,
    required ReportPeriod period,
    required ReportFormat format,
    String? targetUserId,
    Map<String, dynamic>? filters,
    ReportConfig? config,
  }) async {
    try {
      // 1. Créer l'entrée dans Firestore
      final reportId = await _createReportEntry(
        reportType: reportType,
        generatedBy: generatedBy,
        period: period,
        format: format,
        targetUserId: targetUserId,
        filters: filters,
      );

      debugPrint('📊 Génération rapport $reportId démarrée...');

      // 2. Collecter les données
      final data = await _collectReportData(
        reportType: reportType,
        targetUserId: targetUserId,
        period: period,
        filters: filters,
      );

      debugPrint('📦 ${data['logs'].length} logs collectés');

      // 3. Générer le fichier
      File file;
      switch (format) {
        case ReportFormat.pdf:
          file = await _generatePDF(
            reportType: reportType,
            data: data,
            period: period,
            config: config,
          );
          break;
        case ReportFormat.csv:
          file = await _generateCSV(
            reportType: reportType,
            data: data,
          );
          break;
        case ReportFormat.excel:
          // TODO: Implémenter Excel natif
          file = await _generateCSV(
            reportType: reportType,
            data: data,
          );
          break;
        case ReportFormat.html:
          // TODO: Implémenter HTML
          file = await _generatePDF(
            reportType: reportType,
            data: data,
            period: period,
            config: config,
          );
          break;
      }

      debugPrint('📄 Fichier généré: ${file.path}');

      // 4. Upload vers Firebase Storage
      final fileUrl = await _uploadToStorage(file, reportId, format);

      debugPrint('☁️ Fichier uploadé: $fileUrl');

      // 5. Mettre à jour l'entrée Firestore
      await _updateReportEntry(
        reportId: reportId,
        fileUrl: fileUrl,
        fileName: file.path.split('/').last,
        fileSize: await file.length(),
        summary: data['summary'] as Map<String, dynamic>,
      );

      debugPrint('✅ Rapport $reportId généré avec succès');
      return reportId;
    } catch (e) {
      debugPrint('❌ Erreur génération rapport: $e');

      // Marquer le rapport comme échoué
      try {
        await FirebaseFirestore.instance
            .collection(_reportsCollection)
            .doc(reportId)
            .update({
          'status': ReportStatus.failed.name,
          'error': e.toString(),
          'errorTimestamp': FieldValue.serverTimestamp(),
        });
      } catch (updateError) {
        debugPrint('❌ Erreur mise à jour statut erreur: $updateError');
      }

      rethrow;
    }
  }

  /// Créer l'entrée initiale du rapport dans Firestore
  static Future<String> _createReportEntry({
    required ReportType reportType,
    required String generatedBy,
    required ReportPeriod period,
    required ReportFormat format,
    String? targetUserId,
    Map<String, dynamic>? filters,
  }) async {
    final doc = await FirebaseFirestore.instance
        .collection(_reportsCollection)
        .add({
      'reportType': reportType.name,
      'generatedBy': generatedBy,
      'targetUserId': targetUserId,
      'period': period.toMap(),
      'filters': filters ?? {},
      'format': format.name,
      'status': ReportStatus.generating.name,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(
        DateTime.now().add(const Duration(days: 30)),
      ),
    });

    return doc.id;
  }

  /// Collecter les données pour le rapport
  static Future<Map<String, dynamic>> _collectReportData({
    required ReportType reportType,
    String? targetUserId,
    required ReportPeriod period,
    Map<String, dynamic>? filters,
  }) async {
    List<AuditLog> logs = [];
    Map<String, dynamic> summary = {};

    switch (reportType) {
      case ReportType.userActivity:
        if (targetUserId == null) {
          throw Exception('targetUserId requis pour rapport utilisateur');
        }
        logs = await AuditService.getUserLogs(
          targetUserId,
          startDate: period.startDate,
          endDate: period.endDate,
          limit: 1000,
        );
        summary = await AuditService.getAuditStats(
          userId: targetUserId,
          startDate: period.startDate,
          endDate: period.endDate,
        );
        break;

      case ReportType.adminAudit:
        logs = await AuditService.getGlobalLogs(
          startDate: period.startDate,
          endDate: period.endDate,
          categories: [AuditCategory.adminAction],
          limit: 1000,
        );
        summary = await AuditService.getAuditStats(
          startDate: period.startDate,
          endDate: period.endDate,
        );
        break;

      case ReportType.globalActivity:
        logs = await AuditService.getGlobalLogs(
          startDate: period.startDate,
          endDate: period.endDate,
          limit: 1000,
        );
        summary = await AuditService.getAuditStats(
          startDate: period.startDate,
          endDate: period.endDate,
        );
        break;

      case ReportType.financial:
        logs = await AuditService.getGlobalLogs(
          startDate: period.startDate,
          endDate: period.endDate,
          categories: [AuditCategory.financial],
          limit: 1000,
        );
        summary = await AuditService.getAuditStats(
          startDate: period.startDate,
          endDate: period.endDate,
        );
        break;

      case ReportType.security:
        logs = await AuditService.getGlobalLogs(
          startDate: period.startDate,
          endDate: period.endDate,
          categories: [AuditCategory.security],
          limit: 1000,
        );
        summary = await AuditService.getAuditStats(
          startDate: period.startDate,
          endDate: period.endDate,
        );
        break;

      case ReportType.conflict:
        // Pour les conflits, on récupère tous les logs liés
        logs = await AuditService.getGlobalLogs(
          startDate: period.startDate,
          endDate: period.endDate,
          limit: 500,
        );
        summary = await AuditService.getAuditStats(
          startDate: period.startDate,
          endDate: period.endDate,
        );
        break;
    }

    return {
      'logs': logs,
      'summary': summary,
    };
  }

  /// Générer un rapport PDF
  static Future<File> _generatePDF({
    required ReportType reportType,
    required Map<String, dynamic> data,
    required ReportPeriod period,
    ReportConfig? config,
  }) async {
    final pdf = pw.Document();
    final logs = data['logs'] as List<AuditLog>;
    final summary = data['summary'] as Map<String, dynamic>;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // En-tête
          _buildPDFReportHeader(reportType, period),
          pw.SizedBox(height: 20),

          // Résumé statistique
          _buildPDFSummary(summary),
          pw.SizedBox(height: 20),

          // Titre de la section logs
          pw.Header(
            level: 1,
            child: pw.Text(
              'Détail des activités',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 10),

          // Tableau des logs
          _buildPDFLogsTable(logs),

          // Footer
          pw.SizedBox(height: 20),
          _buildPDFReportFooter(),
        ],
      ),
    );

    // Sauvegarder le fichier
    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        'rapport_${reportType.name}_${_fileDateFormat.format(DateTime.now())}.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  /// Générer un rapport CSV
  static Future<File> _generateCSV({
    required ReportType reportType,
    required Map<String, dynamic> data,
  }) async {
    final logs = data['logs'] as List<AuditLog>;

    List<List<dynamic>> rows = [
      // En-tête
      [
        'Date/Heure',
        'Utilisateur',
        'Email',
        'Type',
        'Action',
        'Description',
        'Catégorie',
        'Sévérité',
        'Cible',
        'Statut'
      ],
    ];

    // Ajouter les logs
    for (final log in logs) {
      rows.add([
        _dateFormat.format(log.timestamp),
        log.userName ?? log.userId,
        log.userEmail,
        log.userType,
        log.actionLabel,
        log.description,
        log.categoryLabel,
        log.severityLabel,
        log.targetLabel ?? log.targetId ?? '',
        log.isSuccessful ? 'Succès' : 'Échec',
      ]);
    }

    // Convertir en CSV
    final csvData = const ListToCsvConverter().convert(rows);

    // Sauvegarder le fichier
    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        'rapport_${reportType.name}_${_fileDateFormat.format(DateTime.now())}.csv';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(csvData);

    return file;
  }

  /// Upload un fichier vers Firebase Storage
  static Future<String> _uploadToStorage(
    File file,
    String reportId,
    ReportFormat format,
  ) async {
    final fileName = file.path.split('/').last;
    final ref = FirebaseStorage.instance
        .ref()
        .child('$_storageFolder/$reportId/$fileName');

    await ref.putFile(file);
    final downloadUrl = await ref.getDownloadURL();

    return downloadUrl;
  }

  /// Mettre à jour l'entrée du rapport avec les détails finaux
  static Future<void> _updateReportEntry({
    required String reportId,
    required String fileUrl,
    required String fileName,
    required int fileSize,
    required Map<String, dynamic> summary,
  }) async {
    await FirebaseFirestore.instance
        .collection(_reportsCollection)
        .doc(reportId)
        .update({
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'summary': summary,
      'status': ReportStatus.ready.name,
    });
  }

  // ========== Construction PDF ==========

  static pw.Widget _buildPDFReportHeader(
    ReportType reportType,
    ReportPeriod period,
  ) {
    String title;
    switch (reportType) {
      case ReportType.userActivity:
        title = 'RAPPORT D\'ACTIVITÉ UTILISATEUR';
        break;
      case ReportType.adminAudit:
        title = 'RAPPORT D\'AUDIT ADMINISTRATEUR';
        break;
      case ReportType.globalActivity:
        title = 'RAPPORT D\'ACTIVITÉ GLOBALE';
        break;
      case ReportType.financial:
        title = 'RAPPORT FINANCIER';
        break;
      case ReportType.security:
        title = 'RAPPORT DE SÉCURITÉ';
        break;
      case ReportType.conflict:
        title = 'RAPPORT DE RÉSOLUTION DE CONFLIT';
        break;
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Divider(color: PdfColors.blue200),
          pw.SizedBox(height: 8),
          _buildPDFInfoRow('Période:', period.label),
          _buildPDFInfoRow('Généré le:', _dateFormat.format(DateTime.now())),
          _buildPDFInfoRow(
              'Plateforme:', 'SOCIAL BUSINESS Pro - Rapport Administrateur'),
        ],
      ),
    );
  }

  static pw.Widget _buildPDFInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPDFSummary(Map<String, dynamic> summary) {
    final totalLogs = summary['totalLogs'] as int? ?? 0;
    // Convertir Map<dynamic, dynamic> en Map<String, int>
    final byCategoryRaw = summary['byCategory'] as Map<dynamic, dynamic>? ?? {};
    final byCategory = Map<String, int>.from(
      byCategoryRaw.map((key, value) => MapEntry(key.toString(), value as int? ?? 0))
    );

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'RÉSUMÉ STATISTIQUE',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Divider(),
          pw.SizedBox(height: 8),
          _buildPDFStatRow('Total d\'activités:', totalLogs.toString()),
          pw.SizedBox(height: 4),
          ...byCategory.entries.where((e) => e.value > 0).map((entry) {
            String label;
            switch (entry.key) {
              case 'adminAction':
                label = 'Actions administratives';
                break;
              case 'userAction':
                label = 'Actions utilisateur';
                break;
              case 'security':
                label = 'Événements de sécurité';
                break;
              case 'financial':
                label = 'Transactions financières';
                break;
              case 'system':
                label = 'Événements système';
                break;
              default:
                label = entry.key;
            }
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: _buildPDFStatRow('$label:', entry.value.toString()),
            );
          }),
        ],
      ),
    );
  }

  static pw.Widget _buildPDFStatRow(String label, String value) {
    return pw.Row(
      children: [
        pw.SizedBox(
          width: 250,
          child: pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 10),
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildPDFLogsTable(List<AuditLog> logs) {
    if (logs.isEmpty) {
      return pw.Center(
        child: pw.Text(
          'Aucune activité pour cette période',
          style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(2), // Date
        1: const pw.FlexColumnWidth(2), // Utilisateur
        2: const pw.FlexColumnWidth(3), // Action
        3: const pw.FlexColumnWidth(2), // Catégorie
      },
      children: [
        // En-tête
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildPDFTableHeader('Date/Heure'),
            _buildPDFTableHeader('Utilisateur'),
            _buildPDFTableHeader('Action'),
            _buildPDFTableHeader('Catégorie'),
          ],
        ),
        // Lignes de données (max 50 pour éviter PDF trop gros)
        ...logs.take(50).map((log) => pw.TableRow(
              children: [
                _buildPDFTableCell(_dateFormat.format(log.timestamp)),
                _buildPDFTableCell(log.userName ?? log.userEmail),
                _buildPDFTableCell(log.actionLabel),
                _buildPDFTableCell(log.categoryLabel),
              ],
            )),
      ],
    );
  }

  static pw.Widget _buildPDFTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _buildPDFTableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 9),
      ),
    );
  }

  static pw.Widget _buildPDFReportFooter() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'SOCIAL BUSINESS Pro - Panel Administrateur',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Ce document est confidentiel et réservé à un usage administratif interne.',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
          pw.Text(
            'Toute diffusion non autorisée est strictement interdite.',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  // ========== Gestion des rapports ==========

  /// Récupérer les rapports générés par un admin
  static Future<List<GeneratedReport>> getReportsByAdmin(
    String adminId, {
    int limit = 20,
  }) async {
    final snapshot = await FirebaseFirestore.instance
        .collection(_reportsCollection)
        .where('generatedBy', isEqualTo: adminId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => GeneratedReport.fromFirestore(doc))
        .toList();
  }

  /// Supprimer un rapport (fichier + entrée Firestore)
  static Future<void> deleteReport(String reportId) async {
    try {
      // Récupérer le rapport
      final doc = await FirebaseFirestore.instance
          .collection(_reportsCollection)
          .doc(reportId)
          .get();

      if (!doc.exists) return;

      final report = GeneratedReport.fromFirestore(doc);

      // Supprimer le fichier du Storage si existe
      if (report.fileUrl != null) {
        try {
          final ref = FirebaseStorage.instance.refFromURL(report.fileUrl!);
          await ref.delete();
          debugPrint('🗑️ Fichier supprimé du Storage');
        } catch (e) {
          debugPrint('⚠️ Erreur suppression Storage: $e');
        }
      }

      // Supprimer l'entrée Firestore
      await FirebaseFirestore.instance
          .collection(_reportsCollection)
          .doc(reportId)
          .delete();

      debugPrint('✅ Rapport $reportId supprimé');
    } catch (e) {
      debugPrint('❌ Erreur suppression rapport: $e');
      rethrow;
    }
  }

  /// Nettoyer les rapports expirés
  static Future<int> cleanupExpiredReports() async {
    int count = 0;
    try {
      final now = DateTime.now();
      final snapshot = await FirebaseFirestore.instance
          .collection(_reportsCollection)
          .where('expiresAt', isLessThan: Timestamp.fromDate(now))
          .get();

      for (final doc in snapshot.docs) {
        await deleteReport(doc.id);
        count++;
      }

      debugPrint('🗑️ $count rapports expirés supprimés');
      return count;
    } catch (e) {
      debugPrint('❌ Erreur nettoyage rapports: $e');
      return count;
    }
  }
}
