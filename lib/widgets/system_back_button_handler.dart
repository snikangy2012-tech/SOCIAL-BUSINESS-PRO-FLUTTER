// ===== lib/widgets/system_back_button_handler.dart =====
// Gestionnaire centralisé du bouton retour système Android
// Applique automatiquement à toutes les pages de l'application

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Widget qui gère intelligemment le bouton retour système Android
///
/// Utilisation:
/// ```dart
/// SystemBackButtonHandler(
///   child: Scaffold(...),
/// )
/// ```
class SystemBackButtonHandler extends StatelessWidget {
  final Widget child;
  final VoidCallback? onBackPressed;
  final bool canPop;

  const SystemBackButtonHandler({
    super.key,
    required this.child,
    this.onBackPressed,
    this.canPop = true,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // Si un callback personnalisé est fourni, l'utiliser
        if (onBackPressed != null) {
          onBackPressed!();
          return;
        }

        // Comportement par défaut: utiliser GoRouter pour la navigation
        if (context.canPop()) {
          context.pop();
        } else {
          // Si on ne peut pas pop, on ne fait rien (évite de quitter l'app)
          debugPrint('⚠️ Cannot pop - at root route');
        }
      },
      child: child,
    );
  }
}

/// Extension pour faciliter l'utilisation dans les widgets
extension SystemBackButtonExtension on Widget {
  /// Enveloppe le widget avec SystemBackButtonHandler
  Widget withSystemBackButton({
    VoidCallback? onBackPressed,
    bool canPop = true,
  }) {
    return SystemBackButtonHandler(
      onBackPressed: onBackPressed,
      canPop: canPop,
      child: this,
    );
  }
}
