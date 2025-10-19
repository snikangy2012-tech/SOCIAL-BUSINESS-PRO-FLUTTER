// ===== lib/screens/temp_screens.dart =====
// Écrans temporaires pour tester la navigation

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/constants.dart';

// Écran générique temporaire (équivalent à PlaceholderComponent.tsx)
class TempScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? description;
  final IconData icon;
  final Color? backgroundColor;
  final List<TempButton>? buttons;

  const TempScreen({
    super.key,
    required this.title,
    required this.subtitle,
    this.description,
    required this.icon,
    this.backgroundColor,
    this.buttons,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        color: backgroundColor?.withValues(alpha:0.1),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icône
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: (backgroundColor ?? AppColors.primary).withValues(alpha:0.2),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                child: Icon(
                  icon,
                  size: 50,
                  color: backgroundColor ?? AppColors.primary,
                ),
              ),
              
              const SizedBox(height: AppSpacing.xl),
              
              // Titre
              Text(
                title,
                style: const TextStyle(
                  fontSize: AppFontSizes.xxl,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              // Sous-titre
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: AppFontSizes.lg,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              // Description (optionnelle)
              if (description != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  description!,
                  style: const TextStyle(
                    fontSize: AppFontSizes.md,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: AppSpacing.xl),
              
              // Badge "En développement"
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha:0.2),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.warning),
                ),
                child: const Text(
                  '🚧 En développement',
                  style: TextStyle(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              
              const SizedBox(height: AppSpacing.xl),
              
              // Boutons de navigation de test
              if (buttons != null)
                ...buttons!.map((btn) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => btn.onPressed(context),
                      icon: Icon(btn.icon),
                      label: Text(btn.label),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: btn.color ?? AppColors.primary,
                      ),
                    ),
                  ),
                ))
              else
                _buildDefaultNavigationButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultNavigationButtons(BuildContext context) {
    return Column(
      children: [
        // Boutons de navigation par type d'utilisateur
        const Text(
          'Navigation test :',
          style: TextStyle(
            fontSize: AppFontSizes.lg,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          alignment: WrapAlignment.center,
          children: [
            _NavButton(
              'Vendeur',
              Icons.store,
              AppColors.primary,
              () => context.go('/vendeur'),
            ),
            _NavButton(
              'Acheteur',
              Icons.shopping_bag,
              AppColors.secondary,
              () => context.go('/acheteur'),
            ),
            _NavButton(
              'Livreur',
              Icons.delivery_dining,
              AppColors.success,
              () => context.go('/livreur'),
            ),
            _NavButton(
              'Connexion',
              Icons.login,
              AppColors.info,
              () => context.go('/login'),
            ),
            _NavButton(
              'Profil',
              Icons.person,
              AppColors.textSecondary,
              () => context.go('/profile'),
            ),
          ],
        ),
        
        const SizedBox(height: AppSpacing.lg),
        
        // Bouton retour intelligent
        OutlinedButton.icon(
          onPressed: () {
            // Si on peut revenir en arrière, on le fait
            if (context.canPop()) {
              context.pop();
            } else {
              // Sinon, on retourne au splash/accueil
              context.go('/');
            }
          },
          icon: Icon(context.canPop() ? Icons.arrow_back : Icons.home),
          label: Text(context.canPop() ? 'Retour' : 'Accueil'),
        ),
      ],
    );
  }
}

// Widget bouton de navigation helper
class _NavButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _NavButton(this.label, this.icon, this.color, this.onPressed);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
    );
  }
}

// Classe helper pour définir des boutons personnalisés
class TempButton {
  final String label;
  final IconData icon;
  final Color? color;
  final void Function(BuildContext) onPressed;

  TempButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color,
  });
}

// ===== ÉCRANS SPÉCIFIQUES =====

// Splash Screen temporaire
class SplashScreenTemp extends StatefulWidget {
  const SplashScreenTemp({super.key});

  @override
  State<SplashScreenTemp> createState() => _SplashScreenTempState();
}

class _SplashScreenTempState extends State<SplashScreenTemp> {
  @override
  void initState() {
    super.initState();
    // Simuler un chargement puis aller à la connexion
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        context.go('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.store,
              size: 100,
              color: Colors.white,
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              AppConstants.appName,
              style: TextStyle(
                fontSize: AppFontSizes.xxxl,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              AppConstants.slogan,
              style: TextStyle(
                fontSize: AppFontSizes.lg,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.xl),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}