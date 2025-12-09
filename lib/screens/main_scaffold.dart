// ===== lib/screens/main_scaffold.dart =====
// Scaffold principal avec Bottom Navigation Bar - SOCIAL BUSINESS Pro

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:social_business_pro/config/constants.dart';
import '../providers/auth_provider_firebase.dart';
import '../providers/cart_provider.dart';
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
    return PopScope(
      canPop: true, // ✅ Permet la navigation retour (go_router gère les sous-pages)
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;

        // Si on n'est pas sur l'accueil (index 0), revenir à l'accueil
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
          return;
        }

        // Si on est sur l'accueil, demander confirmation avant de quitter
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
          // ✅ Barres système : fond BLANC OPAQUE avec icônes noires
          systemNavigationBarColor: Color(0xFFFFFFFF), // Blanc opaque
          systemNavigationBarIconBrightness: Brightness.dark, // Icônes noires
          systemNavigationBarDividerColor: Colors.transparent,
          systemNavigationBarContrastEnforced: true, // Force le contraste
          // Status bar pour écrans sans AppBar
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark, // Icônes noires
          statusBarBrightness: Brightness.light, // Pour iOS
        ),
        child: Scaffold(
          extendBody: false, // ✅ CRITIQUE: Empêche le contenu de passer sous la barre de navigation
          body: SafeArea(
            top: false, // AppBar gère le top
            bottom: true, // ✅ FORCE le respect de la barre système en bas
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
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
            icon: Consumer<CartProvider>(
              builder: (context, cart, child) {
                final itemCount = cart.totalQuantity;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(_currentIndex == 3 ? Icons.shopping_cart : Icons.shopping_cart_outlined),
                    if (itemCount > 0)
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
                          child: Text(
                            itemCount > 99 ? '99+' : '$itemCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
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
        ),
      ),
    );
  }
}