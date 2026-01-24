// ===== lib/screens/admin/global_reports_screen.dart =====
// Écran de génération et gestion des rapports globaux (Super Admin uniquement)

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../config/constants.dart';
import '../../models/report_model.dart';
import '../../services/global_report_service.dart';
import '../../providers/auth_provider_firebase.dart' as auth;
import '../../widgets/system_ui_scaffold.dart';

class GlobalReportsScreen extends StatefulWidget {
  const GlobalReportsScreen({super.key});

  @override
  State<GlobalReportsScreen> createState() => _GlobalReportsScreenState();
}

class _GlobalReportsScreenState extends State<GlobalReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');

  // Liste des rapports générés (mock pour le moment)
  List<GeneratedReport> _generatedReports = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadReports();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<auth.AuthProvider>();
      final userId = authProvider.user?.id;

      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final reports = await GlobalReportService.getReportsByAdmin(userId);

      setState(() {
        _generatedReports = reports;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Erreur chargement rapports: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateReport({
    required ReportType reportType,
    required ReportPeriod period,
    required ReportFormat format,
    String? targetUserId,
    Map<String, dynamic>? filters,
  }) async {
    final authProvider = context.read<auth.AuthProvider>();
    final currentUser = authProvider.user;

    if (currentUser == null) return;

    try {
      // Afficher un loader
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Génération du rapport en cours...'),
            ],
          ),
        ),
      );

      // Générer le rapport
      await GlobalReportService.generateReport(
        reportType: reportType,
        generatedBy: currentUser.id,
        period: period,
        format: format,
        targetUserId: targetUserId,
        filters: filters,
      );

      // Fermer le loader
      if (mounted) Navigator.pop(context);

      // Recharger la liste des rapports
      await _loadReports();

      // Afficher le succès
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Rapport généré avec succès'),
            backgroundColor: AppColors.success,
          ),
        );

        // Basculer sur l'onglet "Rapports générés"
        _tabController.animateTo(1);
      }
    } catch (e) {
      // Fermer le loader si toujours ouvert
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      debugPrint('❌ Erreur génération rapport: $e');
    }
  }

  void _showNewReportDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _NewReportSheet(
        onGenerate: _generateReport,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SystemUIScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/admin-dashboard');
            }
          },
          tooltip: 'Retour',
        ),
        title: const Text('Rapports Globaux'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Nouveau rapport', icon: Icon(Icons.add_chart, size: 20)),
            Tab(text: 'Rapports générés', icon: Icon(Icons.folder, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNewReportTab(),
          _buildGeneratedReportsTab(),
        ],
      ),
    );
  }

  Widget _buildNewReportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          const Text(
            'Générer un nouveau rapport',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sélectionnez le type de rapport à générer',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),

          // Types de rapports
          _buildReportTypeCard(
            title: 'Activité Utilisateur',
            description: 'Rapport détaillé de l\'activité d\'un utilisateur spécifique',
            icon: Icons.person,
            color: AppColors.info,
            reportType: ReportType.userActivity,
          ),
          const SizedBox(height: 12),

          _buildReportTypeCard(
            title: 'Audit Admin',
            description: 'Toutes les actions administratives effectuées',
            icon: Icons.admin_panel_settings,
            color: AppColors.warning,
            reportType: ReportType.adminAudit,
          ),
          const SizedBox(height: 12),

          _buildReportTypeCard(
            title: 'Activité Globale',
            description: 'Vue d\'ensemble de l\'activité de la plateforme',
            icon: Icons.public,
            color: AppColors.primary,
            reportType: ReportType.globalActivity,
          ),
          const SizedBox(height: 12),

          _buildReportTypeCard(
            title: 'Rapport Financier',
            description: 'Transactions, commissions, abonnements (Super Admin)',
            icon: Icons.attach_money,
            color: AppColors.success,
            reportType: ReportType.financial,
          ),
          const SizedBox(height: 12),

          _buildReportTypeCard(
            title: 'Rapport de Sécurité',
            description: 'Événements de connexion, tentatives suspectes',
            icon: Icons.security,
            color: AppColors.error,
            reportType: ReportType.security,
          ),
          const SizedBox(height: 12),

          _buildReportTypeCard(
            title: 'Résolution de Conflit',
            description: 'Rapport pour aider à résoudre un litige',
            icon: Icons.gavel,
            color: Colors.purple,
            reportType: ReportType.conflict,
          ),
        ],
      ),
    );
  }

  Widget _buildReportTypeCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required ReportType reportType,
  }) {
    return Card(
      child: InkWell(
        onTap: () => _showReportConfigDialog(reportType),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: AppColors.textLight,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReportConfigDialog(ReportType reportType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ReportConfigSheet(
        reportType: reportType,
        onGenerate: (period, format, targetUserId, filters) {
          _generateReport(
            reportType: reportType,
            period: period,
            format: format,
            targetUserId: targetUserId,
            filters: filters,
          );
        },
      ),
    );
  }

  Widget _buildGeneratedReportsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_generatedReports.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.description,
                size: 80,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'Aucun rapport généré',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Créez votre premier rapport depuis l\'onglet "Nouveau rapport"',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textLight,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReports,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _generatedReports.length,
        itemBuilder: (context, index) {
          final report = _generatedReports[index];
          return _buildReportCard(report);
        },
      ),
    );
  }

  Widget _buildReportCard(GeneratedReport report) {
    Color statusColor;
    switch (report.status) {
      case ReportStatus.generating:
        statusColor = AppColors.warning;
        break;
      case ReportStatus.ready:
        statusColor = AppColors.success;
        break;
      case ReportStatus.failed:
        statusColor = AppColors.error;
        break;
      case ReportStatus.expired:
        statusColor = AppColors.textLight;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: report.isReady ? () => _viewReport(report) : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Text(
                    report.statusIcon,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.typeLabel,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          report.period.label,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      report.statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const Divider(height: 24),

              // Détails
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      icon: Icons.calendar_today,
                      label: 'Créé le',
                      value: dateFormat.format(report.createdAt),
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      icon: Icons.insert_drive_file,
                      label: 'Format',
                      value: report.formatLabel,
                    ),
                  ),
                ],
              ),

              if (report.fileSize != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        icon: Icons.storage,
                        label: 'Taille',
                        value: report.fileSizeFormatted,
                      ),
                    ),
                    if (report.daysUntilExpiration != null)
                      Expanded(
                        child: _buildInfoItem(
                          icon: Icons.timer,
                          label: 'Expire dans',
                          value: '${report.daysUntilExpiration} jours',
                        ),
                      ),
                  ],
                ),
              ],

              // Actions
              if (report.isReady) ...[
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _viewReport(report),
                      icon: const Icon(Icons.visibility, size: 18),
                      label: const Text('Voir'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _downloadReport(report),
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('Télécharger'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],

              // Message d'erreur
              if (report.status == ReportStatus.failed && report.errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: AppColors.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          report.errorMessage!,
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textLight,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _viewReport(GeneratedReport report) async {
    if (report.fileUrl == null || report.fileUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ URL du rapport non disponible'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      final uri = Uri.parse(report.fileUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        debugPrint('✅ Rapport ouvert: ${report.fileUrl}');
      } else {
        throw 'Impossible d\'ouvrir l\'URL';
      }
    } catch (e) {
      debugPrint('❌ Erreur ouverture rapport: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur lors de l\'ouverture: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _downloadReport(GeneratedReport report) async {
    if (report.fileUrl == null || report.fileUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ URL du rapport non disponible'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      // Sur mobile, on peut utiliser share_plus pour partager le fichier
      // L'utilisateur pourra ensuite choisir de le sauvegarder
      await Share.shareUri(Uri.parse(report.fileUrl!));

      debugPrint('✅ Rapport partagé: ${report.fileUrl}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Rapport prêt à être téléchargé'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Erreur téléchargement rapport: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur lors du téléchargement: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

// ===== Sheet pour configuration de rapport =====
class _ReportConfigSheet extends StatefulWidget {
  final ReportType reportType;
  final Function(
    ReportPeriod period,
    ReportFormat format,
    String? targetUserId,
    Map<String, dynamic>? filters,
  ) onGenerate;

  const _ReportConfigSheet({
    required this.reportType,
    required this.onGenerate,
  });

  @override
  State<_ReportConfigSheet> createState() => _ReportConfigSheetState();
}

class _ReportConfigSheetState extends State<_ReportConfigSheet> {
  ReportPeriod _selectedPeriod = ReportPeriod.last30Days();
  ReportFormat _selectedFormat = ReportFormat.pdf;
  final _targetUserController = TextEditingController();

  @override
  void dispose() {
    _targetUserController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: ListView(
          controller: scrollController,
          children: [
            // Header
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Configuration du rapport',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(height: 24),

            // Période
            const Text(
              'Période',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPeriodChip('7 jours', ReportPeriod.last7Days()),
                _buildPeriodChip('30 jours', ReportPeriod.last30Days()),
                _buildPeriodChip('3 mois', ReportPeriod.last3Months()),
                _buildPeriodChip('Mois actuel', ReportPeriod.currentMonth()),
                _buildPeriodChip('Mois dernier', ReportPeriod.lastMonth()),
              ],
            ),
            const SizedBox(height: 24),

            // Format
            const Text(
              'Format',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFormatChip('PDF', ReportFormat.pdf, Icons.picture_as_pdf),
                _buildFormatChip('CSV', ReportFormat.csv, Icons.table_chart),
                _buildFormatChip('Excel', ReportFormat.excel, Icons.grid_on),
                _buildFormatChip('HTML', ReportFormat.html, Icons.language),
              ],
            ),
            const SizedBox(height: 24),

            // Utilisateur cible (si rapport utilisateur)
            if (widget.reportType == ReportType.userActivity) ...[
              const Text(
                'Utilisateur cible',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _targetUserController,
                decoration: InputDecoration(
                  hintText: 'Email ou UID de l\'utilisateur',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Bouton générer
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _generateReport,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Générer le rapport'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodChip(String label, ReportPeriod period) {
    final isSelected = _selectedPeriod.label == period.label;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedPeriod = period);
      },
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
    );
  }

  Widget _buildFormatChip(String label, ReportFormat format, IconData icon) {
    final isSelected = _selectedFormat == format;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedFormat = format);
      },
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
    );
  }

  void _generateReport() {
    // Validation
    if (widget.reportType == ReportType.userActivity && _targetUserController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez spécifier un utilisateur cible'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Générer
    widget.onGenerate(
      _selectedPeriod,
      _selectedFormat,
      widget.reportType == ReportType.userActivity ? _targetUserController.text.trim() : null,
      null,
    );

    Navigator.pop(context);
  }
}

// ===== Sheet pour nouveau rapport (version simplifiée) =====
class _NewReportSheet extends StatelessWidget {
  final Function({
    required ReportType reportType,
    required ReportPeriod period,
    required ReportFormat format,
    String? targetUserId,
    Map<String, dynamic>? filters,
  }) onGenerate;

  const _NewReportSheet({required this.onGenerate});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nouveau rapport',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text('Fonctionnalité en développement...'),
        ],
      ),
    );
  }
}

