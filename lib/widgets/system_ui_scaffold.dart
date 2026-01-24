// lib/widgets/system_ui_scaffold.dart
// Widget wrapper qui configure automatiquement les barres système Android

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'system_back_button_handler.dart';

/// Wrapper Scaffold qui configure automatiquement les barres système Android
///
/// RÉSOUT DEUX PROBLÈMES :
/// 1. Barre système blanche opaque avec icônes noires sur TOUS les écrans
/// 2. Empêche le contenu de se cacher sous la barre système
///
/// UTILISATION :
/// ```dart
/// return SystemUIScaffold(
///   appBar: AppBar(title: Text('Mon écran')),
///   body: MonContenu(),
/// );
/// ```
class SystemUIScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final Widget? endDrawer;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;
  final bool extendBody;
  final bool extendBodyBehindAppBar;

  /// Active SafeArea en haut (défaut: false car AppBar gère le top)
  final bool safeAreaTop;

  /// Active SafeArea en bas (défaut: true pour ne pas cacher sous barre système)
  final bool safeAreaBottom;

  /// Padding minimum pour SafeArea en bas (défaut: 0)
  final EdgeInsets safeAreaMinimum;

  /// Configuration personnalisée des barres système (optionnel)
  /// Si null, utilise la configuration par défaut (blanc opaque, icônes noires)
  final SystemUiOverlayStyle? customSystemUI;

  /// Active la gestion automatique du bouton retour système Android (défaut: true)
  final bool enableSystemBackButton;

  /// Callback personnalisé pour le bouton retour (optionnel)
  final VoidCallback? onBackPressed;

  const SystemUIScaffold({
    super.key,
    this.appBar,
    this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.drawer,
    this.endDrawer,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.safeAreaTop = false,
    this.safeAreaBottom = true,
    this.safeAreaMinimum = EdgeInsets.zero,
    this.customSystemUI,
    this.enableSystemBackButton = true,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Configuration par défaut : barre blanche opaque avec icônes noires
    final systemUIStyle = customSystemUI ?? const SystemUiOverlayStyle(
      // ✅ Barre de navigation : fond BLANC OPAQUE avec icônes noires
      systemNavigationBarColor: Color(0xFFFFFFFF), // Blanc opaque
      systemNavigationBarIconBrightness: Brightness.dark, // Icônes noires
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: true, // Force le contraste

      // Status bar : transparent avec icônes adaptatives
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark, // Icônes noires
      statusBarBrightness: Brightness.light, // Pour iOS
    );

    final scaffold = Scaffold(
      appBar: appBar,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      drawer: drawer,
      endDrawer: endDrawer,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
      body: body != null
          ? SafeArea(
              top: safeAreaTop,
              bottom: safeAreaBottom,
              minimum: safeAreaMinimum,
              child: body!,
            )
          : null,
    );

    // Envelopper avec AnnotatedRegion pour les barres système
    final annotatedScaffold = AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemUIStyle,
      child: scaffold,
    );

    // Si la gestion du bouton retour est activée, envelopper avec SystemBackButtonHandler
    if (enableSystemBackButton) {
      return SystemBackButtonHandler(
        onBackPressed: onBackPressed,
        child: annotatedScaffold,
      );
    }

    return annotatedScaffold;
  }
}

/// Wrapper pour écrans avec PopScope (écrans racines avec gestion du bouton retour)
///
/// UTILISATION pour écrans principaux qui gèrent le bouton retour Android :
/// ```dart
/// return SystemUIPopScaffold(
///   canPop: false,
///   onPopInvoked: (didPop) async {
///     if (didPop) return;
///     // Gérer navigation retour personnalisée
///   },
///   appBar: AppBar(title: Text('Mon écran')),
///   body: MonContenu(),
/// );
/// ```
class SystemUIPopScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final Widget? endDrawer;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final bool safeAreaTop;
  final bool safeAreaBottom;
  final EdgeInsets safeAreaMinimum;
  final SystemUiOverlayStyle? customSystemUI;

  /// Contrôle si le pop est autorisé automatiquement
  final bool canPop;

  /// Callback appelé quand le bouton retour est pressé
  final void Function(bool didPop, dynamic result)? onPopInvokedWithResult;

  const SystemUIPopScaffold({
    super.key,
    this.appBar,
    this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.drawer,
    this.endDrawer,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.safeAreaTop = false,
    this.safeAreaBottom = true,
    this.safeAreaMinimum = EdgeInsets.zero,
    this.customSystemUI,
    this.canPop = false,
    this.onPopInvokedWithResult,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: onPopInvokedWithResult,
      child: SystemUIScaffold(
        appBar: appBar,
        body: body,
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
        bottomNavigationBar: bottomNavigationBar,
        drawer: drawer,
        endDrawer: endDrawer,
        backgroundColor: backgroundColor,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        extendBody: extendBody,
        extendBodyBehindAppBar: extendBodyBehindAppBar,
        safeAreaTop: safeAreaTop,
        safeAreaBottom: safeAreaBottom,
        safeAreaMinimum: safeAreaMinimum,
        customSystemUI: customSystemUI,
      ),
    );
  }
}
