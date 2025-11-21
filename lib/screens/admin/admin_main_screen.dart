// ===== lib/screens/admin/admin_main_screen.dart =====
// Écran principal admin avec navigation bottom bar

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:social_business_pro/screens/admin/admin_dashboard.dart';
import 'package:social_business_pro/screens/admin/user_management_screen.dart';
import 'package:social_business_pro/screens/admin/global_statistics_screen.dart';
import 'package:social_business_pro/screens/admin/admin_profile_screen.dart';

import 'package:social_business_pro/config/constants.dart';
import '../../providers/auth_provider_firebase.dart' as auth;
import '../../providers/admin_navigation_provider.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  // Liste des écrans admin
  final List<Widget> _screens = const [
    AdminDashboard(),           // Index 0: Dashboard
    UserManagementScreen(),     // Index 1: Gestion utilisateurs
    GlobalStatisticsScreen(),   // Index 2: Statistiques globales
    AdminProfileScreen(),       // Index 3: Profil admin
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<auth.AuthProvider>();
    final navProvider = context.watch<AdminNavigationProvider>();
    final user = authProvider.user;

    // Vérification sécurité
    if (user == null || user.userType != UserType.admin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pushReplacementNamed('/');
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      canPop: true, // ✅ Permet la navigation retour (go_router gère les sous-pages)
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;

        // Si on n'est pas sur le dashboard (index 0), revenir au dashboard
        if (navProvider.currentIndex != 0) {
          navProvider.setIndex(0);
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
          SystemNavigator.pop();
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          systemNavigationBarColor: Color(0xFF000000),
          systemNavigationBarIconBrightness: Brightness.light,
          systemNavigationBarDividerColor: Color(0xFF000000),
        ),
        child: Scaffold(
          extendBody: false,
          body: IndexedStack(
            index: navProvider.currentIndex,
            children: _screens,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: navProvider.currentIndex,
            onTap: (index) => navProvider.setIndex(index),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.warning,
            unselectedItemColor: Colors.grey,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard),
                activeIcon: Icon(Icons.dashboard, size: 28),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people),
                activeIcon: Icon(Icons.people, size: 28),
                label: 'Utilisateurs',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.analytics),
                activeIcon: Icon(Icons.analytics, size: 28),
                label: 'Statistiques',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                activeIcon: Icon(Icons.person, size: 28),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
