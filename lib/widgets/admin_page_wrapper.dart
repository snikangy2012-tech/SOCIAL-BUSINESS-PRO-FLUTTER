// ===== lib/widgets/admin_page_wrapper.dart =====
// Wrapper pour les pages admin avec gestion du bouton retour Android

import 'package:flutter/material.dart';

/// Wrapper pour les pages admin qui gère automatiquement le bouton retour Android
///
/// Utilisation:
/// ```dart
/// @override
/// Widget build(BuildContext context) {
///   return AdminPageWrapper(
///     child: Scaffold(
///       appBar: AppBar(...),
///       body: ...,
///     ),
///   );
/// }
/// ```
class AdminPageWrapper extends StatelessWidget {
  final Widget child;

  const AdminPageWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true, // Permet le retour normal avec Navigator.pop()
      child: child,
    );
  }
}
