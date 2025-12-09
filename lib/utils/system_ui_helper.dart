// ===== lib/utils/system_ui_helper.dart =====
// Helper pour gérer l'UI système (barres status et navigation)
//
// ⚠️ IMPORTANT - Bonnes pratiques Flutter (2025) :
//
// 1. Pour les écrans AVEC AppBar :
//    → Utiliser AppBarTheme.systemOverlayStyle dans MaterialApp theme (voir main.dart)
//    → OU utiliser AppBar.systemOverlayStyle pour des cas spéciaux
//
// 2. Pour les écrans SANS AppBar :
//    → Utiliser AnnotatedRegion<SystemUiOverlayStyle> autour du Scaffold
//    → Voir exemples dans main_scaffold.dart, vendeur_main_screen.dart, etc.
//
// 3. NE PAS utiliser SystemChrome.setSystemUIOverlayStyle() directement
//    → Cette méthode est globale et ne se réinitialise pas lors de la navigation
//    → Elle sera écrasée par les AppBar et AnnotatedRegion des écrans
//
// Sources :
// - https://api.flutter.dev/flutter/material/AppBar/systemOverlayStyle.html
// - https://github.com/flutter/flutter/issues/152613
// - https://stackoverflow.com/questions/49441187/

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SystemUIHelper {
  /// ✅ STYLE RECOMMANDÉ pour écrans SANS AppBar
  /// À utiliser avec AnnotatedRegion<SystemUiOverlayStyle>
  static const SystemUiOverlayStyle lightStyle = SystemUiOverlayStyle(
    // Barre de navigation (boutons système en bas) - Fond BLANC OPAQUE
    systemNavigationBarColor: Color(0xFFFFFFFF), // Blanc opaque
    systemNavigationBarIconBrightness: Brightness.dark, // Icônes grises/noires
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarContrastEnforced: true, // Force le contraste
    // Status bar (en haut) - Transparente
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark, // Icônes grises/noires
    statusBarBrightness: Brightness.light, // Pour iOS
  );

  /// ✅ STYLE RECOMMANDÉ pour AppBar colorées
  /// À utiliser via AppBar.systemOverlayStyle ou AppBarTheme
  static const SystemUiOverlayStyle darkStyle = SystemUiOverlayStyle(
    // Status bar (en haut) - Icônes blanches pour AppBar sombre
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light, // Icônes blanches
    statusBarBrightness: Brightness.dark, // Pour iOS
    // Navigation bar reste BLANCHE OPAQUE
    systemNavigationBarColor: Color(0xFFFFFFFF), // Blanc opaque
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarContrastEnforced: true, // Force le contraste
  );

  /// Configuration initiale dans main() - Mode edge-to-edge
  static void setDefaultSystemUI() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge, // Mode edge-to-edge (barres visibles)
    );
  }

  /// Configuration pour le splash screen : Plein écran immersif
  static void setSplashScreenUI() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky, // Plein écran, barres masquées
    );
  }

  /// Restaurer le mode edge-to-edge (barres visibles)
  static void restoreSystemUI() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );
  }
}