// ===== lib/screens/main_scaffold.dart =====
// Scaffold principal avec Bottom Navigation Bar - SOCIAL BUSINESS Pro

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/constants.dart';
import '../providers/auth_provider_firebase.dart';
import 'acheteur/acheteur_home.dart';
import 'acheteur/categories_screen.dart';
import 'acheteur/favorite_screen.dart';
import 'acheteur/cart_screen.dart';
import 'acheteur/business_pro_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  // ✅ ORDRE CORRECT DES SCREENS (correspond aux items)
  final List<Widget> _screens = [
    const AcheteurHome(),       // 0: Accueil
    const CategoriesScreen(),   // 1: Catégories
    const FavoriteScreen(),     // 2: Favoris ✅
    const CartScreen(),         // 3: Panier ✅
    const BusinessProScreen(),  // 4: Business Pro ✅
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        elevation: 8,
        items: [
          // 0: Accueil
          BottomNavigationBarItem(
            icon: Icon(_currentIndex == 0 ? Icons.home : Icons.home_outlined),
            label: 'Accueil',
          ),
          
          // 1: Catégories
          BottomNavigationBarItem(
            icon: Icon(_currentIndex == 1 ? Icons.grid_view : Icons.grid_view_outlined),
            label: 'Catégories',
          ),

          // 2: Favoris ✅
          BottomNavigationBarItem(
            icon: Icon(_currentIndex == 2 ? Icons.favorite : Icons.favorite_outline),
            label: 'Favoris',
          ),
          
          // 3: Panier avec badge ✅
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(_currentIndex == 3 ? Icons.shopping_cart : Icons.shopping_cart_outlined),
                Positioned(
                  right: -6,
                  top: -6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: const Text(
                      '0',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            label: 'Panier',
          ),
          
          // 4: Business Pro ✅
          BottomNavigationBarItem(
            icon: Consumer<AuthProvider>(
              builder: (context, auth, child) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(_currentIndex == 4 
                        ? Icons.business_center 
                        : Icons.business_center_outlined),
                    if (auth.isAuthenticated)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            label: 'Business Pro',
          ),
        ],
      ),
    );
  }
}