// ===== lib/utils/system_ui_helper.dart =====
// Helper pour gérer l'UI système (barres status et navigation)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SystemUIHelper {
  /// Configuration par défaut : Barres système visibles avec fond blanc
  static void setDefaultSystemUI() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge, // Mode edge-to-edge (barres visibles)
    );

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        // Barre de navigation (boutons système en bas)
        systemNavigationBarColor: Colors.white, // Fond blanc opaque
        systemNavigationBarIconBrightness: Brightness.dark, // Icônes noires
        systemNavigationBarDividerColor: Colors.transparent,

        // Status bar (en haut) - reste inchangée
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );
  }

  /// Configuration pour le splash screen : Plein écran immersif
  static void setSplashScreenUI() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky, // Plein écran, barres masquées
    );

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        // Tout transparent pour le splash
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
  }

  /// Configuration pour les écrans avec AppBar colorée
  static void setAppBarColoredUI(Color appBarColor) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        // Barre de navigation reste blanche
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,

        // Status bar s'adapte à la couleur de l'AppBar
        statusBarColor: appBarColor,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
  }

  /// Restaurer les barres système si elles ont été masquées
  static void restoreSystemUI() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );
  }
}