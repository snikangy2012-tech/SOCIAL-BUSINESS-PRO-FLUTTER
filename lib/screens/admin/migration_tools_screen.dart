// ===== lib/screens/admin/migration_tools_screen.dart =====
// Outils de migration et maintenance pour l'admin

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:social_business_pro/config/constants.dart';
import 'package:social_business_pro/services/subscription_service.dart';
import '../../widgets/system_ui_scaffold.dart';

class MigrationToolsScreen extends StatefulWidget {
  const MigrationToolsScreen({super.key});

  @override
  State<MigrationToolsScreen> createState() => _MigrationToolsScreenState();
}

class _MigrationToolsScreenState extends State<MigrationToolsScreen> {
  final _subscriptionService = SubscriptionService();
  bool _isRunningMigration = false;
  String _migrationResult = '';

  Future<void> _runFullMigration() async {
    setState(() {
      _isRunningMigration = true;
      _migrationResult = '';
    });

    try {
      await _subscriptionService.createAllMissingSubscriptions();
      setState(() {
        _migrationResult = '✅ Migration réussie ! Tous les abonnements manquants ont été créés.';
      });
    } catch (e) {
      setState(() {
        _migrationResult = '❌ Erreur lors de la migration: $e';
      });
    } finally {
      setState(() {
        _isRunningMigration = false;
      });
    }
  }

  Future<void> _runVendeurMigration() async {
    setState(() {
      _isRunningMigration = true;
      _migrationResult = '';
    });

    try {
      await _subscriptionService.createMissingVendeurSubscriptions();
      setState(() {
        _migrationResult = '✅ Migration vendeurs réussie !';
      });
    } catch (e) {
      setState(() {
        _migrationResult = '❌ Erreur migration vendeurs: $e';
      });
    } finally {
      setState(() {
        _isRunningMigration = false;
      });
    }
  }

  Future<void> _runLivreurMigration() async {
    setState(() {
      _isRunningMigration = true;
      _migrationResult = '';
    });

    try {
      await _subscriptionService.createMissingLivreurSubscriptions();
      setState(() {
        _migrationResult = '✅ Migration livreurs réussie !';
      });
    } catch (e) {
      setState(() {
        _migrationResult = '❌ Erreur migration livreurs: $e';
      });
    } finally {
      setState(() {
        _isRunningMigration = false;
      });
    }
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
        title: const Text('🛠️ Outils de Migration'),
        backgroundColor: AppColors.warning,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avertissement
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.warning),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber, color: AppColors.warning, size: 24),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'ATTENTION : Ces outils modifient directement la base de données. Utilisez-les avec précaution.',
                      style: TextStyle(
                        fontSize: AppFontSizes.sm,
                        fontWeight: FontWeight.w600,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Section: Migration des abonnements
            const Text(
              'Migration des Abonnements',
              style: TextStyle(
                fontSize: AppFontSizes.xl,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Créer les abonnements manquants pour les utilisateurs existants qui n\'en ont pas encore.',
              style: TextStyle(
                fontSize: AppFontSizes.sm,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Bouton: Migration complète
            _buildMigrationButton(
              title: 'Migration Complète',
              description: 'Créer tous les abonnements manquants (vendeurs + livreurs)',
              icon: Icons.rocket_launch,
              color: AppColors.primary,
              onPressed: _isRunningMigration ? null : _runFullMigration,
            ),

            const SizedBox(height: AppSpacing.md),

            // Bouton: Migration vendeurs seulement
            _buildMigrationButton(
              title: 'Migration Vendeurs Uniquement',
              description: 'Créer abonnements BASIQUE pour vendeurs sans abonnement',
              icon: Icons.store,
              color: AppColors.secondary,
              onPressed: _isRunningMigration ? null : _runVendeurMigration,
            ),

            const SizedBox(height: AppSpacing.md),

            // Bouton: Migration livreurs seulement
            _buildMigrationButton(
              title: 'Migration Livreurs Uniquement',
              description: 'Créer abonnements STARTER pour livreurs sans abonnement',
              icon: Icons.delivery_dining,
              color: AppColors.success,
              onPressed: _isRunningMigration ? null : _runLivreurMigration,
            ),

            const SizedBox(height: AppSpacing.xl),

            // Indicateur de chargement
            if (_isRunningMigration)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: AppSpacing.md),
                    Text(
                      'Migration en cours...',
                      style: TextStyle(
                        fontSize: AppFontSizes.md,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

            // Résultat de la migration
            if (_migrationResult.isNotEmpty && !_isRunningMigration)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: _migrationResult.startsWith('✅')
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: _migrationResult.startsWith('✅') ? AppColors.success : AppColors.error,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _migrationResult.startsWith('✅') ? Icons.check_circle : Icons.error,
                      color: _migrationResult.startsWith('✅') ? AppColors.success : AppColors.error,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        _migrationResult,
                        style: const TextStyle(
                          fontSize: AppFontSizes.md,
                          fontWeight: FontWeight.w600,
                        ),
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

  Widget _buildMigrationButton({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: AppFontSizes.md,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: AppFontSizes.sm,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: onPressed == null ? AppColors.border : color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

