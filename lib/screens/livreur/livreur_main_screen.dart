// lib/screens/livreur/livreur_main_screen.dart
// Écran principal pour les livreurs avec Bottom Navigation Bar

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
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

    return Scaffold(
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
    );
  }
}