// lib/screens/livreur/livreur_main_screen.dart
// Écran principal pour les livreurs avec Bottom Navigation Bar

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:social_business_pro/config/constants.dart';
import '../../providers/auth_provider_firebase.dart' as auth;
import 'livreur_dashboard.dart';
import 'delivery_list_screen.dart';
import 'livreur_earnings_screen.dart';
import 'livreur_profile_screen.dart';

class LivreurMainScreen extends StatefulWidget {
  const LivreurMainScreen({super.key});

  @override
  State<LivreurMainScreen> createState() => _LivreurMainScreenState();
}

class _LivreurMainScreenState extends State<LivreurMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DeliveryDashboard(),
    const DeliveryListScreen(),
    const LivreurEarningsScreen(),
    const LivreurProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<auth.AuthProvider>();
    final user = authProvider.user;

    if (user == null || user.userType != UserType.livreur) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return PopScope(
      canPop: true, // ✅ Permet la navigation retour (go_router gère les sous-pages)
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;

        // Si on n'est pas sur le dashboard (index 0), revenir au dashboard
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
          return;
        }

        // Si on est sur le dashboard, demander confirmation avant de quitter
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Quitter l\'application ?'),
            content: const Text('Voulez-vous vraiment quitter SOCIAL BUSINESS Pro ?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Quitter'),
              ),
            ],
          ),
        );

        if (shouldExit == true && context.mounted) {
          SystemNavigator.pop(); // Quitte l'application
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          // ✅ Force les boutons système Android à rester OPAQUES (non transparents)
          systemNavigationBarColor: Color(0xFF000000), // Fond noir opaque
          systemNavigationBarIconBrightness: Brightness.light, // Icônes blanches
          systemNavigationBarDividerColor: Color(0xFF000000), // Diviseur noir
        ),
        child: Scaffold(
          extendBody: false, // ✅ Empêche le body de passer sous les boutons Android
          body: IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: Colors.grey,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.delivery_dining),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.list_alt),
                label: 'Livraisons',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.payments),
                label: 'Gains',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}