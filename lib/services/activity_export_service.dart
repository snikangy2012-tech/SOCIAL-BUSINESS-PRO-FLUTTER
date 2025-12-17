// ===== lib/services/activity_export_service.dart =====
// Service d'export d'activité pour les utilisateurs (PDF/CSV)

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import '../models/audit_log_model.dart';

/// Service d'export d'activité utilisateur
/// Permet aux utilisateurs (vendeur, livreur, acheteur) d'exporter leur activité
class ActivityExportService {
  static final _dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');
  static final _fileDateFormat = DateFormat('yyyyMMdd_HHmmss');

  /// Exporter l'activité en PDF
  ///
  /// Paramètres:
  /// - [logs]: Liste des logs à exporter
  /// - [userName]: Nom de l'utilisateur
  /// - [userEmail]: Email de l'utilisateur
  /// - [userType]: Type d'utilisateur (vendeur, livreur, acheteur)
  /// - [period]: Période d'export (ex: "30 derniers jours")
  /// - [stats]: Statistiques optionnelles à inclure
  static Future<File> exportToPDF({
    required List<AuditLog> logs,
    required String userName,
    required String userEmail,
    required String userType,
    required String period,
    Map<String, dynamic>? stats,
  }) async {
    final pdf = pw.Document();

    // Créer le PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // En-tête
          _buildPDFHeader(userName, userEmail, userType, period),
          pw.SizedBox(height: 20),

          // Statistiques (si disponibles)
          if (stats != null) ...[
            _buildPDFStats(stats),
            pw.SizedBox(height: 20),
          ],

          // Titre de la section
          pw.Header(
            level: 1,
            child: pw.Text(
              'Historique d\'activité',
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
          _buildPDFFooter(),
        ],
      ),
    );

    // Sauvegarder le fichier
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'mon_activite_${_fileDateFormat.format(DateTime.now())}.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    debugPrint('✅ PDF exporté: ${file.path}');
    return file;
  }

  /// Exporter l'activité en CSV
  ///
  /// Format: Date, Action, Description, Catégorie, Sévérité
  static Future<File> exportToCSV({
    required List<AuditLog> logs,
    required String userName,
  }) async {
    // Préparer les données CSV
    List<List<dynamic>> rows = [
      // En-tête
      ['Date/Heure', 'Action', 'Description', 'Catégorie', 'Sévérité', 'Statut'],
    ];

    // Ajouter les logs
    for (final log in logs) {
      rows.add([
        _dateFormat.format(log.timestamp),
        log.actionLabel,
        log.description,
        log.categoryLabel,
        log.severityLabel,
        log.isSuccessful ? 'Succès' : 'Échec',
      ]);
    }

    // Convertir en CSV
    final csvData = const ListToCsvConverter().convert(rows);

    // Sauvegarder le fichier
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'mon_activite_${_fileDateFormat.format(DateTime.now())}.csv';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(csvData);

    debugPrint('✅ CSV exporté: ${file.path}');
    return file;
  }

  /// Partager un fichier exporté
  static Future<void> shareFile(File file, String title) async {
    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: title,
        text: 'Mon rapport d\'activité - SOCIAL BUSINESS Pro',
      );
      debugPrint('✅ Fichier partagé: ${file.path}');
    } catch (e) {
      debugPrint('❌ Erreur partage fichier: $e');
      rethrow;
    }
  }

  // ========== Construction PDF ==========

  static pw.Widget _buildPDFHeader(
    String userName,
    String userEmail,
    String userType,
    String period,
  ) {
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
            'RAPPORT D\'ACTIVITÉ',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Divider(color: PdfColors.blue200),
          pw.SizedBox(height: 8),
          _buildPDFInfoRow('Utilisateur:', userName),
          _buildPDFInfoRow('Email:', userEmail),
          _buildPDFInfoRow('Type:', _getUserTypeLabel(userType)),
          _buildPDFInfoRow('Période:', period),
          _buildPDFInfoRow('Généré le:', _dateFormat.format(DateTime.now())),
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

  static pw.Widget _buildPDFStats(Map<String, dynamic> stats) {
    final totalLogs = stats['totalLogs'] as int? ?? 0;
    final byCategory = stats['byCategory'] as Map<String, int>? ?? {};

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
            'STATISTIQUES',
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
              case 'userAction':
                label = 'Actions utilisateur';
                break;
              case 'security':
                label = 'Événements de sécurité';
                break;
              case 'financial':
                label = 'Transactions';
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
          width: 200,
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
        1: const pw.FlexColumnWidth(3), // Action
        2: const pw.FlexColumnWidth(4), // Description
        3: const pw.FlexColumnWidth(2), // Catégorie
      },
      children: [
        // En-tête
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildPDFTableHeader('Date/Heure'),
            _buildPDFTableHeader('Action'),
            _buildPDFTableHeader('Description'),
            _buildPDFTableHeader('Catégorie'),
          ],
        ),
        // Lignes de données
        ...logs.map((log) => pw.TableRow(
              children: [
                _buildPDFTableCell(_dateFormat.format(log.timestamp)),
                _buildPDFTableCell(log.actionLabel),
                _buildPDFTableCell(log.description),
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

  static pw.Widget _buildPDFFooter() {
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
            'SOCIAL BUSINESS Pro - Plateforme de Commerce Social',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Ce document est généré automatiquement et contient vos activités personnelles.',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
          pw.Text(
            'Pour toute question, contactez le support: support@socialbusinesspro.com',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  // ========== Helpers ==========

  static String _getUserTypeLabel(String userType) {
    switch (userType.toLowerCase()) {
      case 'vendeur':
        return 'Vendeur';
      case 'livreur':
        return 'Livreur';
      case 'acheteur':
        return 'Acheteur';
      case 'admin':
        return 'Administrateur';
      default:
        return userType;
    }
  }

  /// Valider les données avant export
  static bool validateExportData({
    required List<AuditLog> logs,
    int maxLogs = 1000,
  }) {
    if (logs.isEmpty) {
      debugPrint('⚠️ Aucune donnée à exporter');
      return false;
    }

    if (logs.length > maxLogs) {
      debugPrint('⚠️ Trop de logs à exporter: ${logs.length} (max: $maxLogs)');
      return false;
    }

    return true;
  }

  /// Nettoyer les anciens fichiers d'export (>7 jours)
  static Future<void> cleanupOldExports() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory.listSync();
      final now = DateTime.now();

      for (final file in files) {
        if (file is File) {
          final fileName = file.path.split('/').last;
          if (fileName.startsWith('mon_activite_') &&
              (fileName.endsWith('.pdf') || fileName.endsWith('.csv'))) {
            final stat = await file.stat();
            final age = now.difference(stat.modified);

            if (age.inDays > 7) {
              await file.delete();
              debugPrint('🗑️ Fichier supprimé: $fileName');
            }
          }
        }
      }
      debugPrint('✅ Nettoyage des exports terminé');
    } catch (e) {
      debugPrint('❌ Erreur nettoyage exports: $e');
    }
  }
}
