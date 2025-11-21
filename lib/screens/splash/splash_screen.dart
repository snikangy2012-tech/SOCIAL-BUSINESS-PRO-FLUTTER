// ===== lib/screens/splash/splash_screen.dart =====
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:social_business_pro/config/constants.dart';
import '../../utils/system_ui_helper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Activer le mode plein écran immersif pour le splash
    SystemUIHelper.setSplashScreenUI();

    // Simuler un chargement de 2 secondes puis aller à la connexion
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        // Restaurer les barres système avant de quitter le splash
        SystemUIHelper.setDefaultSystemUI();
        context.go('/login');
      }
    });
  }

  @override
  void dispose() {
    // S'assurer que les barres système sont restaurées
    SystemUIHelper.setDefaultSystemUI();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo temporaire
            Icon(
              Icons.store,
              size: 100,
              color: Colors.white,
            ),
            
            SizedBox(height: AppSpacing.lg),
            
            // Nom de l'app
            Text(
              AppConstants.appName,
              style: TextStyle(
                fontSize: AppFontSizes.xxxl,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: AppSpacing.sm),
            
            // Slogan
            Text(
              AppConstants.slogan,
              style: TextStyle(
                fontSize: AppFontSizes.lg,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: AppSpacing.xl),
            
            // Indicateur de chargement
            CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
            
            SizedBox(height: AppSpacing.md),
            
            // Texte de chargement
            Text(
              'Chargement...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: AppFontSizes.md,
              ),
            ),
          ],
        ),
      ),
    );
  }
}