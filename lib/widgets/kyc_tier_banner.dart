import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/constants.dart';
import '../services/kyc_adaptive_service.dart';
import '../utils/number_formatter.dart';

/// Bannière affichant le tier KYC et suggérant la vérification
/// S'adapte selon le niveau de risque de l'utilisateur
class KYCTierBanner extends StatelessWidget {
  final String userId;
  final bool showCompact;

  const KYCTierBanner({
    super.key,
    required this.userId,
    this.showCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserRiskAssessment?>(
      future: KYCAdaptiveService.getRiskAssessment(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final assessment = snapshot.data!;
        final tier = assessment.tier;
        final limits = assessment.limits;

        // Ne rien afficher pour TRUSTED (tout est débloqué)
        if (tier == RiskTier.trusted) {
          return const SizedBox.shrink();
        }

        return showCompact
            ? _buildCompactBanner(context, tier, limits)
            : _buildFullBanner(context, tier, limits, assessment);
      },
    );
  }

  /// Bannière compacte (pour header/app bar)
  Widget _buildCompactBanner(BuildContext context, RiskTier tier, TierLimits limits) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: _getTierColor(tier).withOpacity(0.1),
        border: Border.all(color: _getTierColor(tier)),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getTierIcon(tier),
            size: 16,
            color: _getTierColor(tier),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            tier.displayName,
            style: TextStyle(
              fontSize: AppFontSizes.sm,
              color: _getTierColor(tier),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Bannière complète (pour dashboard)
  Widget _buildFullBanner(
    BuildContext context,
    RiskTier tier,
    TierLimits limits,
    UserRiskAssessment assessment,
  ) {
    // Couleur et style selon le tier
    final color = _getTierColor(tier);
    final icon = _getTierIcon(tier);
    final isUrgent = tier == RiskTier.highRisk || tier == RiskTier.blacklisted;

    return Card(
      margin: const EdgeInsets.all(AppSpacing.md),
      elevation: isUrgent ? 8 : 2,
      color: color.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(
          color: color,
          width: isUrgent ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec icône et tier
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tier.displayName,
                        style: TextStyle(
                          fontSize: AppFontSizes.lg,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      if (assessment.riskScore < 100)
                        Text(
                          'Score de confiance: ${assessment.riskScore}/100',
                          style: TextStyle(
                            fontSize: AppFontSizes.sm,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Limites actuelles
            _buildLimitsSection(limits),

            const SizedBox(height: AppSpacing.md),

            // Message et action selon tier
            _buildActionSection(context, tier, limits),
          ],
        ),
      ),
    );
  }

  /// Section des limites
  Widget _buildLimitsSection(TierLimits limits) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vos limites actuelles :',
            style: TextStyle(
              fontSize: AppFontSizes.sm,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          _buildLimitRow(
            Icons.shopping_cart,
            'Montant maximum',
            formatPriceWithCurrency(limits.maxOrderValue),
          ),
          _buildLimitRow(
            Icons.today,
            'Commandes/jour',
            '${limits.maxDailyOrders}',
          ),
          if (!limits.canWithdrawEarnings)
            _buildLimitRow(
              Icons.lock,
              'Retraits',
              'Bloqués',
              isWarning: true,
            )
          else if (limits.withdrawalDelay.inHours > 0)
            _buildLimitRow(
              Icons.schedule,
              'Délai retrait',
              '${limits.withdrawalDelay.inHours}h',
            ),
        ],
      ),
    );
  }

  Widget _buildLimitRow(IconData icon, String label, String value, {bool isWarning = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: isWarning ? AppColors.error : AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: AppFontSizes.sm,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: AppFontSizes.sm,
              fontWeight: FontWeight.bold,
              color: isWarning ? AppColors.error : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  /// Section action selon tier
  Widget _buildActionSection(BuildContext context, RiskTier tier, TierLimits limits) {
    switch (tier) {
      case RiskTier.newUser:
      case RiskTier.verified:
        // KYC optionnel avec bonus
        return Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary.withOpacity(0.1), AppColors.secondary.withOpacity(0.1)],
            ),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.star, color: AppColors.warning, size: 20),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      limits.kycMessage,
                      style: TextStyle(
                        fontSize: AppFontSizes.sm,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🎁 Bonus 5 000 FCFA',
                          style: TextStyle(
                            fontSize: AppFontSizes.md,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                        Text(
                          'Vérification en 2 minutes',
                          style: TextStyle(
                            fontSize: AppFontSizes.xs,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => context.push('/kyc-upload'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Vérifier'),
                  ),
                ],
              ),
            ],
          ),
        );

      case RiskTier.moderateRisk:
        // KYC requis pour débloquer
        return Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.1),
            border: Border.all(color: AppColors.warning),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning_amber, color: AppColors.warning),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      limits.kycMessage,
                      style: TextStyle(
                        fontSize: AppFontSizes.sm,
                        fontWeight: FontWeight.w600,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/kyc-upload'),
                  icon: const Icon(Icons.verified_user),
                  label: const Text('Compléter ma vérification'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );

      case RiskTier.highRisk:
      case RiskTier.blacklisted:
        // Support requis
        return Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.1),
            border: Border.all(color: AppColors.error, width: 2),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.block, color: AppColors.error),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      limits.kycMessage,
                      style: TextStyle(
                        fontSize: AppFontSizes.sm,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Ouvrir WhatsApp ou dialog support
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Contactez le support'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Email: support@socialbusiness.ci'),
                            SizedBox(height: AppSpacing.sm),
                            Text('WhatsApp: +225 XX XX XX XX'),
                            SizedBox(height: AppSpacing.sm),
                            Text('Disponible 24/7 pour vous aider'),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Fermer'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.support_agent),
                  label: const Text('Contacter le support'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  // Helpers pour couleurs et icônes
  Color _getTierColor(RiskTier tier) {
    switch (tier) {
      case RiskTier.trusted:
        return AppColors.success;
      case RiskTier.verified:
        return Colors.blue;
      case RiskTier.newUser:
        return Colors.grey;
      case RiskTier.moderateRisk:
        return AppColors.warning;
      case RiskTier.highRisk:
      case RiskTier.blacklisted:
        return AppColors.error;
    }
  }

  IconData _getTierIcon(RiskTier tier) {
    switch (tier) {
      case RiskTier.trusted:
        return Icons.verified;
      case RiskTier.verified:
        return Icons.check_circle;
      case RiskTier.newUser:
        return Icons.person_add;
      case RiskTier.moderateRisk:
        return Icons.warning_amber;
      case RiskTier.highRisk:
      case RiskTier.blacklisted:
        return Icons.block;
    }
  }
}
