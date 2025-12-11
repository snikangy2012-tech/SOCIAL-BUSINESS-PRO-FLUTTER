// ===== lib/screens/kyc/kyc_pending_screen.dart =====
// Écran d'attente de validation KYC

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../providers/auth_provider_firebase.dart';
import '../../widgets/custom_widgets.dart';
import '../widgets/system_ui_scaffold.dart';

class KYCPendingScreen extends StatelessWidget {
  const KYCPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    if (user == null) {
      return SystemUIScaffold(
        body: Center(child: Text('Utilisateur non connecté')),
      );
    }

    final userTypeLabel = user.userType == UserType.vendeur ? 'vendeur' : 'livreur';

    return SystemUIScaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        title: const Text('Vérification en cours'),
        backgroundColor: AppColors.warning,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Rediriger vers le dashboard approprié
            if (user.userType == UserType.vendeur) {
              context.go('/vendeur/dashboard');
            } else if (user.userType == UserType.livreur) {
              context.go('/livreur/dashboard');
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xl),

              // Icône horloge
              const Icon(
                Icons.hourglass_empty,
                size: 100,
                color: AppColors.warning,
              ),

              const SizedBox(height: AppSpacing.xl),

              // Titre
              const Text(
                'Vérification en cours',
                style: TextStyle(
                  fontSize: AppFontSizes.xxxl,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.md),

              // Message principal
              Text(
                'Vos documents sont actuellement en cours de vérification par notre équipe.',
                style: const TextStyle(
                  fontSize: AppFontSizes.lg,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.xl),

              // Card informations
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          border: Border.all(color: AppColors.warning),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.pending,
                              color: AppColors.warning,
                              size: 20,
                            ),
                            SizedBox(width: AppSpacing.xs),
                            Text(
                              'En attente de validation',
                              style: TextStyle(
                                color: AppColors.warning,
                                fontWeight: FontWeight.bold,
                                fontSize: AppFontSizes.md,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // Timeline
                      _buildTimelineItem(
                        icon: Icons.check_circle,
                        title: 'Documents reçus',
                        subtitle: 'Nous avons bien reçu vos documents',
                        isCompleted: true,
                      ),

                      _buildTimelineDivider(isCompleted: false),

                      _buildTimelineItem(
                        icon: Icons.search,
                        title: 'Vérification en cours',
                        subtitle: 'Notre équipe vérifie vos informations',
                        isCompleted: false,
                        isCurrent: true,
                      ),

                      _buildTimelineDivider(isCompleted: false),

                      _buildTimelineItem(
                        icon: Icons.verified,
                        title: 'Validation finale',
                        subtitle: 'Vous recevrez une notification',
                        isCompleted: false,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Délai estimé
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.info.withOpacity(0.3)),
                ),
                child: const Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.access_time, color: AppColors.info),
                        SizedBox(width: AppSpacing.sm),
                        Text(
                          'Délai de vérification',
                          style: TextStyle(
                            color: AppColors.info,
                            fontWeight: FontWeight.bold,
                            fontSize: AppFontSizes.lg,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      '24 à 48 heures',
                      style: TextStyle(
                        color: AppColors.info,
                        fontSize: AppFontSizes.xxl,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      'Du lundi au vendredi, 8h-17h',
                      style: TextStyle(
                        color: AppColors.info,
                        fontSize: AppFontSizes.sm,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Pendant ce temps (vendeur uniquement)
              if (user.userType == UserType.vendeur) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.success.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.lightbulb, color: AppColors.success),
                          SizedBox(width: AppSpacing.sm),
                          Text(
                            'Pendant ce temps...',
                            style: TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.bold,
                              fontSize: AppFontSizes.md,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const Text(
                        'Vous pouvez préparer votre catalogue de produits en attendant la validation.',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: AppFontSizes.sm,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      CustomButton(
                        text: 'Préparer mon catalogue',
                        icon: Icons.inventory,
                        backgroundColor: AppColors.success,
                        onPressed: () => context.go('/vendeur/products'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],

              // Informations complémentaires
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.textSecondary, size: 20),
                        SizedBox(width: AppSpacing.sm),
                        Text(
                          'Bon à savoir',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '• Vous recevrez une notification dès validation\n'
                      '• En cas de rejet, vous pourrez re-soumettre vos documents\n'
                      '• Une fois vérifié, vous pourrez ${userTypeLabel == "vendeur" ? "vendre" : "effectuer des livraisons"} immédiatement',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: AppFontSizes.sm,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Bouton retour dashboard
              CustomButton(
                text: 'Retour au tableau de bord',
                icon: Icons.dashboard,
                isOutlined: true,
                onPressed: () {
                  if (user.userType == UserType.vendeur) {
                    context.go('/vendeur/dashboard');
                  } else if (user.userType == UserType.livreur) {
                    context.go('/livreur/dashboard');
                  } else {
                    context.go('/');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget pour un item de la timeline
  Widget _buildTimelineItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isCompleted,
    bool isCurrent = false,
  }) {
    final Color color = isCompleted
        ? AppColors.success
        : isCurrent
            ? AppColors.warning
            : AppColors.textSecondary;

    return Row(
      children: [
        // Icône
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Icon(icon, color: color, size: 20),
        ),

        const SizedBox(width: AppSpacing.md),

        // Texte
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: AppFontSizes.md,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: AppFontSizes.sm,
                  color: color.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Widget pour le divider de la timeline
  Widget _buildTimelineDivider({required bool isCompleted}) {
    return Padding(
      padding: const EdgeInsets.only(left: 19, top: 4, bottom: 4),
      child: Container(
        width: 2,
        height: 30,
        color: isCompleted
            ? AppColors.success
            : AppColors.textSecondary.withOpacity(0.3),
      ),
    );
  }
}
