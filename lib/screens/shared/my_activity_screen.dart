// ===== lib/screens/shared/my_activity_screen.dart =====
// Écran Mon Activité (pour tous les utilisateurs)

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/constants.dart';
import '../../models/audit_log_model.dart';
import '../../services/audit_service.dart';
import '../../services/activity_export_service.dart';
import '../../providers/auth_provider_firebase.dart' as auth;
import '../../widgets/system_ui_scaffold.dart';

class MyActivityScreen extends StatefulWidget {
  const MyActivityScreen({super.key});

  @override
  State<MyActivityScreen> createState() => _MyActivityScreenState();
}

class _MyActivityScreenState extends State<MyActivityScreen> {
  final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');

  // Filtres
  String _selectedPeriod = '30days';
  AuditCategory? _selectedCategory;

  // Données
  List<AuditLog> _logs = [];
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActivity();
  }

  Future<void> _loadActivity() async {
    setState(() => _isLoading = true);

    final authProvider = context.read<auth.AuthProvider>();
    final userId = authProvider.user?.id;

    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Calculer la période
      final now = DateTime.now();
      DateTime? startDate;

      switch (_selectedPeriod) {
        case '7days':
          startDate = now.subtract(const Duration(days: 7));
          break;
        case '30days':
          startDate = now.subtract(const Duration(days: 30));
          break;
        case '3months':
          startDate = now.subtract(const Duration(days: 90));
          break;
        case 'all':
          startDate = null;
          break;
      }

      // Charger les logs
      final logs = await AuditService.getUserLogs(
        userId,
        startDate: startDate,
        endDate: now,
        categories: _selectedCategory != null ? [_selectedCategory!] : null,
        limit: 100,
      );

      // Charger les statistiques
      final stats = await AuditService.getAuditStats(
        userId: userId,
        startDate: startDate,
        endDate: now,
      );

      setState(() {
        _logs = logs;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Erreur chargement activité: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showLogDetails(AuditLog log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
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
                  Text(
                    log.categoryIcon,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log.actionLabel,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          dateFormat.format(log.timestamp),
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 30),

              // Description
              Text(
                log.description,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 20),

              // Métadonnées
              if (log.metadata.isNotEmpty) ...[
                const Text(
                  'Détails',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                ...log.metadata.entries.map((entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 120,
                            child: Text(
                              entry.key,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              entry.value.toString(),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ],
          ),
        ),
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
              context.go('/');
            }
          },
          tooltip: 'Retour',
        ),
        title: const Text('Rapport d\'Activité'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadActivity,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
          ),
          IconButton(
            onPressed: _showExportDialog,
            icon: const Icon(Icons.download),
            tooltip: 'Exporter',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtres
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                Expanded(
                  child: _buildFilterChip(
                    label: _getPeriodLabel(_selectedPeriod),
                    icon: Icons.calendar_today,
                    onTap: () => _showPeriodPicker(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildFilterChip(
                    label: _selectedCategory != null
                        ? _getCategoryLabel(_selectedCategory!)
                        : 'Toutes',
                    icon: Icons.category,
                    onTap: () => _showCategoryPicker(),
                    isActive: _selectedCategory != null,
                  ),
                ),
              ],
            ),
          ),

          // Contenu
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadActivity,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Statistiques
                        if (_stats != null) _buildStatsSection(),

                        const SizedBox(height: 24),

                        // Titre activité récente
                        const Text(
                          'Activité récente',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Liste des logs
                        if (_logs.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(40),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.inbox,
                                    size: 64,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Aucune activité pour cette période',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ...List.generate(_logs.length, (index) {
                            final log = _logs[index];
                            return _buildActivityCard(log);
                          }),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    final totalLogs = _stats!['totalLogs'] as int;
    // Convertir Map<dynamic, dynamic> en Map<String, int>
    final byCategoryRaw = _stats!['byCategory'] as Map<dynamic, dynamic>;
    final byCategory = Map<String, int>.from(
      byCategoryRaw.map((key, value) => MapEntry(key.toString(), value as int? ?? 0))
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Résumé',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Total d'activités
            _buildStatRow(
              'Total d\'activités',
              totalLogs.toString(),
              Icons.list_alt,
              AppColors.primary,
            ),

            const SizedBox(height: 12),

            // Par catégorie
            ...byCategory.entries.where((e) => e.value > 0).map((entry) {
              IconData icon;
              Color color;
              String label;

              switch (entry.key) {
                case 'userAction':
                  icon = Icons.touch_app;
                  color = AppColors.info;
                  label = 'Actions';
                  break;
                case 'security':
                  icon = Icons.lock;
                  color = AppColors.warning;
                  label = 'Sécurité';
                  break;
                case 'financial':
                  icon = Icons.payment;
                  color = AppColors.success;
                  label = 'Transactions';
                  break;
                default:
                  icon = Icons.circle;
                  color = AppColors.textSecondary;
                  label = entry.key;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildStatRow(label, entry.value.toString(), icon, color),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityCard(AuditLog log) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showLogDetails(log),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Icône
              Text(
                log.categoryIcon,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 12),

              // Contenu
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.actionLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      log.description,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      dateFormat.format(log.timestamp),
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Flèche
              Icon(
                Icons.chevron_right,
                color: AppColors.textLight,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? AppColors.primary : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isActive ? Colors.white : AppColors.textPrimary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPeriodLabel(String period) {
    switch (period) {
      case '7days':
        return '7 jours';
      case '30days':
        return '30 jours';
      case '3months':
        return '3 mois';
      case 'all':
        return 'Tout';
      default:
        return '30 jours';
    }
  }

  void _showPeriodPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPeriodOption('7 derniers jours', '7days'),
            _buildPeriodOption('30 derniers jours', '30days'),
            _buildPeriodOption('3 derniers mois', '3months'),
            _buildPeriodOption('Tout', 'all'),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodOption(String label, String value) {
    return ListTile(
      title: Text(label),
      trailing: _selectedPeriod == value ? const Icon(Icons.check, color: AppColors.primary) : null,
      onTap: () {
        setState(() => _selectedPeriod = value);
        Navigator.pop(context);
        _loadActivity();
      },
    );
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Toutes les catégories'),
              trailing: _selectedCategory == null
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                setState(() => _selectedCategory = null);
                Navigator.pop(context);
                _loadActivity();
              },
            ),
            ListTile(
              title: const Text('Actions'),
              trailing: _selectedCategory == AuditCategory.userAction
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                setState(() => _selectedCategory = AuditCategory.userAction);
                Navigator.pop(context);
                _loadActivity();
              },
            ),
            ListTile(
              title: const Text('Sécurité'),
              trailing: _selectedCategory == AuditCategory.security
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                setState(() => _selectedCategory = AuditCategory.security);
                Navigator.pop(context);
                _loadActivity();
              },
            ),
            ListTile(
              title: const Text('Transactions'),
              trailing: _selectedCategory == AuditCategory.financial
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                setState(() => _selectedCategory = AuditCategory.financial);
                Navigator.pop(context);
                _loadActivity();
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryLabel(AuditCategory category) {
    switch (category) {
      case AuditCategory.userAction:
        return 'Actions';
      case AuditCategory.security:
        return 'Sécurité';
      case AuditCategory.financial:
        return 'Transactions';
      default:
        return category.name;
    }
  }

  void _showExportDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.download, color: AppColors.primary),
                const SizedBox(width: 12),
                const Text(
                  'Exporter mon rapport',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Choisissez le format d\'export',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const Divider(height: 24),

            // Options d'export
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.picture_as_pdf, color: AppColors.error),
              ),
              title: const Text('Exporter en PDF'),
              subtitle: const Text('Rapport professionnel avec graphiques'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                _exportToPDF();
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.table_chart, color: AppColors.success),
              ),
              title: const Text('Exporter en CSV'),
              subtitle: const Text('Données tabulaires pour Excel'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                _exportToCSV();
              },
            ),

            const SizedBox(height: 16),

            // Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.info, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'L\'export inclura les ${_logs.length} activités filtrées',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportToPDF() async {
    if (!ActivityExportService.validateExportData(logs: _logs, maxLogs: 500)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              _logs.isEmpty ? 'Aucune donnée à exporter' : 'Trop de données à exporter (max: 500)'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      // Afficher un loader
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final authProvider = context.read<auth.AuthProvider>();
      final user = authProvider.user;

      if (user == null) {
        Navigator.pop(context);
        throw Exception('Utilisateur non connecté');
      }

      // Générer le PDF
      final file = await ActivityExportService.exportToPDF(
        logs: _logs,
        userName: user.displayName,
        userEmail: user.email,
        userType: user.userType.value,
        period: _getPeriodLabel(_selectedPeriod),
        stats: _stats,
      );

      // Fermer le loader
      if (mounted) Navigator.pop(context);

      // Partager le fichier
      await ActivityExportService.shareFile(
        file,
        'Mon Activité - ${_getPeriodLabel(_selectedPeriod)}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ PDF généré avec succès'),
            backgroundColor: AppColors.success,
          ),
        );
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
      debugPrint('❌ Erreur export PDF: $e');
    }
  }

  Future<void> _exportToCSV() async {
    if (!ActivityExportService.validateExportData(logs: _logs, maxLogs: 1000)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_logs.isEmpty
              ? 'Aucune donnée à exporter'
              : 'Trop de données à exporter (max: 1000)'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      // Afficher un loader
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final authProvider = context.read<auth.AuthProvider>();
      final user = authProvider.user;

      if (user == null) {
        Navigator.pop(context);
        throw Exception('Utilisateur non connecté');
      }

      // Générer le CSV
      final file = await ActivityExportService.exportToCSV(
        logs: _logs,
        userName: user.displayName,
      );

      // Fermer le loader
      if (mounted) Navigator.pop(context);

      // Partager le fichier
      await ActivityExportService.shareFile(
        file,
        'Mon Activité - ${_getPeriodLabel(_selectedPeriod)}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ CSV généré avec succès'),
            backgroundColor: AppColors.success,
          ),
        );
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
      debugPrint('❌ Erreur export CSV: $e');
    }
  }
}

