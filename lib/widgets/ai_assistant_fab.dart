// ===== lib/widgets/ai_assistant_fab.dart =====
// Bouton flottant pour accéder à l'assistant IA depuis n'importe quel écran

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/constants.dart';
import '../providers/auth_provider_firebase.dart';

/// FloatingActionButton pour accéder à l'assistant IA
class AIAssistantFAB extends StatelessWidget {
  final bool mini;
  final Color? backgroundColor;

  const AIAssistantFAB({
    super.key,
    this.mini = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'ai_assistant_fab_${DateTime.now().millisecondsSinceEpoch}',
      onPressed: () => context.push('/ai-assistant'),
      backgroundColor: backgroundColor ?? AppColors.primary,
      tooltip: 'Assistant IA',
      mini: mini,
      child: const Icon(Icons.smart_toy, color: Colors.white),
    );
  }
}

/// Overlay global qui affiche le FAB sur tous les écrans quand connecté
class AIAssistantOverlay extends StatelessWidget {
  final Widget child;

  const AIAssistantOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        // Ne pas afficher si non connecté
        if (!auth.isAuthenticated || auth.user == null) {
          return child;
        }

        return Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: [
              // Le contenu de l'app prend toute la place
              child,
              // FAB positionné en bas à droite, au-dessus de la bottom nav
              Positioned(
                right: 16,
                bottom: 90,
                child: Material(
                  type: MaterialType.transparency,
                  child: const _GlobalAIFab(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// FAB global pour l'assistant IA
class _GlobalAIFab extends StatelessWidget {
  const _GlobalAIFab();

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'global_ai_assistant',
      onPressed: () => _openAssistant(context),
      backgroundColor: AppColors.primary,
      tooltip: 'Assistant IA',
      mini: true,
      elevation: 4,
      child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
    );
  }

  void _openAssistant(BuildContext context) {
    try {
      context.push('/ai-assistant');
    } catch (e) {
      // Fallback si GoRouter n'est pas disponible
      debugPrint('⚠️ GoRouter indisponible, utilisation Navigator');
      Navigator.of(context).pushNamed('/ai-assistant');
    }
  }
}
