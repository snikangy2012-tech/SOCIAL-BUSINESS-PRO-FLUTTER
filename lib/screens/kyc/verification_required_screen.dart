// ===== lib/screens/kyc/verification_required_screen.dart =====
// Écran de blocage pour vendeurs/livreurs non vérifiés

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../providers/auth_provider_firebase.dart';
import '../../widgets/custom_widgets.dart';
import '../../widgets/system_ui_scaffold.dart';

class VerificationRequiredScreen extends StatelessWidget {
  final UserType userType;

  const VerificationRequiredScreen({
    super.key,
    this.userType = UserType.vendeur,
  });

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    if (user == null) {
      return SystemUIScaffold(
        body: Center(child: Text('Utilisateur non connecté')),
      );
    }

    final isVendeur = userType == UserType.vendeur;
    final userTypeLabel = isVendeur ? 'vendeur' : 'livreur';
    final actionLabel = isVendeur ? 'vendre' : 'effectuer des livraisons';

    return SystemUIScaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        title: const Text('Vérification requise'),
        backgroundColor: AppColors.warning,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Rediriger vers le dashboard approprié
            if (isVendeur) {
              context.go('/vendeur/dashboard');
            } else {
              context.go('/livreur/dashboard');
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

              // Icône de vérification
              const Icon(
                Icons.verified_user,
                size: 100,
                color: AppColors.warning,
              ),

              const SizedBox(height: AppSpacing.xl),

              // Titre
              const Text(
                'Vérification d\'identité requise',
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
                'Pour garantir la sécurité de tous, vous devez compléter '
                'votre vérification d\'identité avant de pouvoir $actionLabel '
                'sur SOCIAL BUSINESS Pro.',
                style: const TextStyle(
                  fontSize: AppFontSizes.lg,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.xl),

              // Card blocage
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      // Icône de blocage
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.block,
                          size: 64,
                          color: AppColors.error,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // Titre blocage
                      Text(
                        'Fonctionnalités bloquées',
                        style: const TextStyle(
                          fontSize: AppFontSizes.xl,
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Liste des fonctionnalités bloquées
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundSecondary,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildBlockedFeature(
                              isVendeur ? 'Ajout de produits' : 'Acceptation de livraisons',
                            ),
                            _buildBlockedFeature(
                              isVendeur ? 'Publication de produits' : 'Gestion des livraisons',
                            ),
                            _buildBlockedFeature(
                              isVendeur ? 'Gestion des commandes' : 'Réception de paiements',
                            ),
                            _buildBlockedFeature(
                              isVendeur
                                  ? 'Réception de paiements'
                                  : 'Accès aux commandes disponibles',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Card documents requis
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.checklist, color: AppColors.primary),
                          SizedBox(width: AppSpacing.sm),
                          Text(
                            'Documents requis',
                            style: TextStyle(
                              fontSize: AppFontSizes.lg,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (isVendeur) ...[
                        // Documents vendeur
                        _buildRequiredDocument(
                          '1. Carte d\'identité (CNI)',
                          'Recto et verso, photo nette',
                          true,
                        ),
                        _buildRequiredDocument(
                          '2. Selfie avec CNI',
                          'Vous tenant votre CNI, visage visible',
                          true,
                        ),
                        _buildRequiredDocument(
                          '3. Justificatif de domicile',
                          'Facture CIE/SODECI < 3 mois (Recommandé)',
                          false,
                        ),
                      ] else ...[
                        // Documents livreur
                        _buildRequiredDocument(
                          '1. Carte d\'identité (CNI)',
                          'Recto et verso',
                          true,
                        ),
                        _buildRequiredDocument(
                          '2. Permis de conduire',
                          'Catégorie A (moto) ou B (voiture)',
                          true,
                        ),
                        _buildRequiredDocument(
                          '3. Carte grise du véhicule',
                          'En cours de validité',
                          true,
                        ),
                        _buildRequiredDocument(
                          '4. Assurance véhicule',
                          'Responsabilité civile minimum',
                          true,
                        ),
                        _buildRequiredDocument(
                          '5. Photo du véhicule',
                          'Plaque d\'immatriculation visible',
                          true,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Bouton principal
              CustomButton(
                text: isVendeur ? 'Compléter ma vérification' : 'Uploader mes documents',
                icon: Icons.upload_file,
                onPressed: () {
                  if (isVendeur) {
                    context.push('/kyc-verification');
                  } else {
                    context.push('/livreur/documents');
                  }
                },
              ),

              const SizedBox(height: AppSpacing.md),

              // Informations délai
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.info.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.access_time, color: AppColors.info, size: 20),
                        SizedBox(width: AppSpacing.sm),
                        Text(
                          'Validation rapide',
                          style: TextStyle(
                            color: AppColors.info,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const Text(
                      'Vos documents seront validés sous 24-48h',
                      style: TextStyle(
                        color: AppColors.info,
                        fontSize: AppFontSizes.sm,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Bouton retour dashboard
              CustomButton(
                text: 'Retour au tableau de bord',
                icon: Icons.dashboard,
                isOutlined: true,
                onPressed: () {
                  if (isVendeur) {
                    context.go('/vendeur/dashboard');
                  } else {
                    context.go('/livreur/dashboard');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget pour une fonctionnalité bloquée
  Widget _buildBlockedFeature(String feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          const Icon(
            Icons.close,
            color: AppColors.error,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              feature,
              style: const TextStyle(
                fontSize: AppFontSizes.md,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Widget pour un document requis
  Widget _buildRequiredDocument(String title, String subtitle, bool isRequired) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isRequired ? Icons.check_circle : Icons.info,
            color: isRequired ? AppColors.success : AppColors.info,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: AppFontSizes.md,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (isRequired)
                      const Text(
                        'REQUIS',
                        style: TextStyle(
                          fontSize: AppFontSizes.xs,
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                        ),
                      )
                    else
                      const Text(
                        'Recommandé',
                        style: TextStyle(
                          fontSize: AppFontSizes.xs,
                          fontWeight: FontWeight.bold,
                          color: AppColors.info,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: AppFontSizes.sm,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
