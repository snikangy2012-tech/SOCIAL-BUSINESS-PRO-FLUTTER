// ===== lib/screens/admin/audit_logs_screen.dart =====
// Écran de consultation des logs d'audit (Admin)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/constants.dart';
import '../../models/audit_log_model.dart';
import '../../services/audit_service.dart';
import '../../widgets/system_ui_scaffold.dart';

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');

  // Filtres
  String _selectedPeriod = '7days';
  AuditCategory? _selectedCategory;
  AuditSeverity? _selectedSeverity;
  bool? _requiresReview;
  String _searchTerm = '';

  // Données
  List<AuditLog> _logs = [];
  bool _isLoading = true;
  int _requiresReviewCount = 0;

  @override
  void initState() {
    super.initState();
    _loadLogs();
    _loadRequiresReviewCount();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);

    try {
      // Calculer la période
      final now = DateTime.now();
      DateTime? startDate;

      switch (_selectedPeriod) {
        case '24h':
          startDate = now.subtract(const Duration(hours: 24));
          break;
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
      final logs = await AuditService.getGlobalLogs(
        startDate: startDate,
        endDate: now,
        categories: _selectedCategory != null ? [_selectedCategory!] : null,
        minSeverity: _selectedSeverity,
        requiresReview: _requiresReview,
        limit: 100,
      );

      // Filtrer par terme de recherche côté client
      if (_searchTerm.isNotEmpty) {
        final term = _searchTerm.toLowerCase();
        _logs = logs.where((log) {
          return log.actionLabel.toLowerCase().contains(term) ||
              log.description.toLowerCase().contains(term) ||
              log.userEmail.toLowerCase().contains(term) ||
              (log.targetLabel?.toLowerCase().contains(term) ?? false);
        }).toList();
      } else {
        _logs = logs;
      }

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('❌ Erreur chargement logs: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRequiresReviewCount() async {
    try {
      final count = await AuditService.countLogsRequiringReview();
      setState(() => _requiresReviewCount = count);
    } catch (e) {
      debugPrint('❌ Erreur comptage logs à revoir: $e');
    }
  }

  Future<void> _markAsReviewed(AuditLog log, String reviewedBy) async {
    try {
      await AuditService.markAsReviewed(log.id, reviewedBy);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Log marqué comme revu')),
        );
      }

      _loadLogs();
      _loadRequiresReviewCount();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _showLogDetails(AuditLog log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
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

              // Acteur
              _buildDetailSection('Acteur', [
                _buildDetailRow('Utilisateur', log.userName ?? log.userEmail),
                _buildDetailRow('Email', log.userEmail),
                _buildDetailRow('Type', log.userType),
              ]),

              // Action
              _buildDetailSection('Action', [
                _buildDetailRow('Catégorie', log.categoryLabel),
                _buildDetailRow('Action', log.action),
                _buildDetailRow('Description', log.description),
                _buildDetailRow('Sévérité', log.severityLabel),
                _buildDetailRow('Succès', log.isSuccessful ? 'Oui' : 'Non'),
              ]),

              // Cible
              if (log.targetType != null) ...[
                _buildDetailSection('Cible', [
                  _buildDetailRow('Type', log.targetType!),
                  if (log.targetId != null) _buildDetailRow('ID', log.targetId!),
                  if (log.targetLabel != null) _buildDetailRow('Label', log.targetLabel!),
                ]),
              ],

              // Métadonnées
              if (log.metadata.isNotEmpty) ...[
                _buildDetailSection('Métadonnées', [
                  ...log.metadata.entries
                      .map((entry) => _buildDetailRow(entry.key, entry.value.toString())),
                ]),
              ],

              // Contexte technique
              if (log.ipAddress != null || log.deviceInfo != null) ...[
                _buildDetailSection('Contexte technique', [
                  if (log.ipAddress != null) _buildDetailRow('Adresse IP', log.ipAddress!),
                  if (log.deviceInfo != null) _buildDetailRow('Appareil', log.deviceInfo!),
                ]),
              ],

              // Revue
              if (log.requiresReview) ...[
                const SizedBox(height: 20),
                if (log.reviewedAt == null)
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // TODO: Récupérer l'ID de l'admin connecté
                      _markAsReviewed(log, 'current_admin_id');
                    },
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Marquer comme revu'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                    ),
                  )
                else
                  Card(
                    color: AppColors.success.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '✓ Revu',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Le ${dateFormat.format(log.reviewedAt!)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          if (log.reviewedBy != null)
                            Text(
                              'Par: ${log.reviewedBy}',
                              style: const TextStyle(fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SystemUIScaffold(
      appBar: AppBar(
        title: const Text('Logs d\'Audit'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          // Badge pour logs nécessitant revue
          if (_requiresReviewCount > 0)
            Stack(
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _requiresReview = true;
                      _loadLogs();
                    });
                  },
                  icon: const Icon(Icons.warning_amber),
                  tooltip: 'Logs nécessitant revue',
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_requiresReviewCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          IconButton(
            onPressed: _loadLogs,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtres
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Column(
              children: [
                // Barre de recherche
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Rechercher...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onChanged: (value) {
                    setState(() => _searchTerm = value);
                    _loadLogs();
                  },
                ),
                const SizedBox(height: 12),

                // Filtres en ligne
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Période
                      _buildFilterChip(
                        label: _getPeriodLabel(_selectedPeriod),
                        icon: Icons.calendar_today,
                        onTap: () => _showPeriodPicker(),
                      ),
                      const SizedBox(width: 8),

                      // Catégorie
                      _buildFilterChip(
                        label: _selectedCategory?.name ?? 'Toutes catégories',
                        icon: Icons.category,
                        onTap: () => _showCategoryPicker(),
                        isActive: _selectedCategory != null,
                      ),
                      const SizedBox(width: 8),

                      // Sévérité
                      _buildFilterChip(
                        label: _selectedSeverity?.name ?? 'Toute sévérité',
                        icon: Icons.priority_high,
                        onTap: () => _showSeverityPicker(),
                        isActive: _selectedSeverity != null,
                      ),
                      const SizedBox(width: 8),

                      // Nécessite revue
                      _buildFilterChip(
                        label: _requiresReview == true ? 'À revoir' : 'Tous',
                        icon: Icons.check_circle,
                        onTap: () {
                          setState(() {
                            _requiresReview = _requiresReview == true ? null : true;
                          });
                          _loadLogs();
                        },
                        isActive: _requiresReview == true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Liste des logs
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _logs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucun log trouvé',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadLogs,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _logs.length,
                          itemBuilder: (context, index) {
                            final log = _logs[index];
                            return _buildLogCard(log);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogCard(AuditLog log) {
    Color severityColor;
    switch (log.severity) {
      case AuditSeverity.low:
        severityColor = AppColors.success;
        break;
      case AuditSeverity.medium:
        severityColor = AppColors.warning;
        break;
      case AuditSeverity.high:
        severityColor = AppColors.error;
        break;
      case AuditSeverity.critical:
        severityColor = Colors.purple;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showLogDetails(log),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icône catégorie
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: severityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  log.categoryIcon,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(width: 12),

              // Contenu
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            log.actionLabel,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (log.requiresReview && log.reviewedAt == null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'À revoir',
                              style: TextStyle(
                                color: AppColors.warning,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
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
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 14,
                          color: AppColors.textLight,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            log.userName ?? log.userEmail,
                            style: TextStyle(
                              color: AppColors.textLight,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: AppColors.textLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateFormat.format(log.timestamp),
                          style: TextStyle(
                            color: AppColors.textLight,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Indicateur sévérité
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color: severityColor,
                  borderRadius: BorderRadius.circular(2),
                ),
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
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.primary : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
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
      case '24h':
        return '24 heures';
      case '7days':
        return '7 jours';
      case '30days':
        return '30 jours';
      case '3months':
        return '3 mois';
      case 'all':
        return 'Tout';
      default:
        return '7 jours';
    }
  }

  void _showPeriodPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPeriodOption('24 heures', '24h'),
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
        _loadLogs();
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
                _loadLogs();
              },
            ),
            ...AuditCategory.values.map((category) => ListTile(
                  title: Text(_getCategoryLabel(category)),
                  trailing: _selectedCategory == category
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () {
                    setState(() => _selectedCategory = category);
                    Navigator.pop(context);
                    _loadLogs();
                  },
                )),
          ],
        ),
      ),
    );
  }

  String _getCategoryLabel(AuditCategory category) {
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

  void _showSeverityPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Toute sévérité'),
              trailing: _selectedSeverity == null
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                setState(() => _selectedSeverity = null);
                Navigator.pop(context);
                _loadLogs();
              },
            ),
            ...AuditSeverity.values.map((severity) => ListTile(
                  title: Text(_getSeverityLabel(severity)),
                  trailing: _selectedSeverity == severity
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () {
                    setState(() => _selectedSeverity = severity);
                    Navigator.pop(context);
                    _loadLogs();
                  },
                )),
          ],
        ),
      ),
    );
  }

  String _getSeverityLabel(AuditSeverity severity) {
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
