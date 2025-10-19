import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_business_pro/screens/vendeur/order_management.dart';
import 'package:social_business_pro/screens/vendeur/product_management.dart';
import 'package:social_business_pro/screens/vendeur/vendeur_profile_screen.dart';


import '../../config/constants.dart';
import '../../providers/auth_provider_firebase.dart' as auth;
import '../../screens/vendeur/vendeur_dashboard.dart';
import '../../providers/vendeur_navigation_provider.dart';


class VendeurMainScreen extends StatefulWidget {
  const VendeurMainScreen({super.key});

  @override
  State<VendeurMainScreen> createState() => _VendeurMainScreenState();
}

class _VendeurMainScreenState extends State<VendeurMainScreen> {

  @override
    Widget build(BuildContext context) {
      final authProvider = context.watch<auth.AuthProvider>();
      final navProvider = context.watch<VendeurNavigationProvider>();
      final user = authProvider.user;

      // Vérification sécurité
      if (user == null || user.userType != UserType.vendeur) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.of(context).pushReplacementNamed('/');
        });
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      return Scaffold(
        body: IndexedStack(
          index: navProvider.currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: navProvider.currentIndex,
          onTap: (index) => navProvider.setIndex(index),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.grey,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.store),
              activeIcon: Icon(Icons.store, size: 28),
              label: 'Ma Boutique',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2, size: 28),
              label: 'Mes Articles',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long, size: 28),
              label: 'Mes Commandes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person, size: 28),
              label: 'Mon Profil',
            ),
          ],
        ),
      );
    }

  final List<Widget> _screens = [
    const VendeurDashboard(),
    const ProductManagement(storeId: 'Magasin',),
    const OrderManagement(orderId: 'Numéro de la commande',),
    const VendeurProfileScreen(),
  ];

  
}