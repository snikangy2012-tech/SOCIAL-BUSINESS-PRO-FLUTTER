// ===== lib/screens/main_scaffold.dart =====
// Scaffold principal avec Bottom Navigation Bar - SOCIAL BUSINESS Pro

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:social_business_pro/config/constants.dart';
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
      canPop: false, // ✅ CRITIQUE: Intercepter AVANT le pop pour gérer la navigation
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        // ✅ Avec canPop: false, didPop sera toujours false
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
          body: SafeArea(
            top: false, // AppBar gère le top
            bottom: true, // ✅ FORCE le respect de la barre système en bas
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
          // ✅ BOTTOM NAVIGATION BAR SANS ENCOCHE
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                height: 60,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // 1: Catégories
                    _buildNavItem(
                      index: 1,
                      icon: Icons.apps_rounded,
                      activeIcon: Icons.apps,
                      label: 'Catégories',
                    ),

                    // 2: Favoris
                    _buildNavItem(
                      index: 2,
                      icon: Icons.favorite_outline_rounded,
                      activeIcon: Icons.favorite_rounded,
                      label: 'Favoris',
                    ),

                    // 0: ACCUEIL (au milieu avec cercle quand actif)
                    _buildHomeNavItem(),

                    // 3: Panier avec badge
                    _buildNavItemWithBadge(),

                    // 4: Business Pro
                    _buildNavItem(
                      index: 4,
                      icon: Icons.storefront_outlined,
                      activeIcon: Icons.storefront_rounded,
                      label: 'Business',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ✅ WIDGET POUR ACCUEIL (au milieu avec cercle quand actif)
  Widget _buildHomeNavItem() {
    final isActive = _currentIndex == 0;
    return Expanded(
      child: InkWell(
        onTap: () => _onTabTapped(0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : Colors.transparent,
                shape: BoxShape.circle,
                border: isActive ? null : Border.all(
                  color: AppColors.textSecondary.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(
                isActive ? Icons.home_rounded : Icons.home_outlined,
                color: isActive ? Colors.white : AppColors.textSecondary,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ WIDGET POUR ITEM DE NAVIGATION
  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isActive = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => _onTabTapped(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ WIDGET POUR PANIER AVEC BADGE
  Widget _buildNavItemWithBadge() {
    final isActive = _currentIndex == 3;
    return Expanded(
      child: InkWell(
        onTap: () => _onTabTapped(3),
        child: Consumer<CartProvider>(
          builder: (context, cart, child) {
            final itemCount = cart.totalQuantity;
            return Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      isActive ? Icons.shopping_cart : Icons.shopping_cart_outlined,
                      color: isActive ? AppColors.primary : AppColors.textSecondary,
                      size: 24,
                    ),
                    if (itemCount > 0)
                      Positioned(
                        right: -8,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
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
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Panier',
                  style: TextStyle(
                    fontSize: 11,
                    color: isActive ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}