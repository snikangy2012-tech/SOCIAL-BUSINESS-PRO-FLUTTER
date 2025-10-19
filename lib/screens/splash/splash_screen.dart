// ===== lib/screens/splash/splash_screen.dart =====
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; 

import '../../config/constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    
    // Simuler un chargement de 2 secondes puis aller à la connexion
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        context.go('/login'); // Maintenant ça fonctionne !
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