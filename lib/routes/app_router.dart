import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:social_business_pro/screens/acheteur/checkout_screen.dart';
import 'package:social_business_pro/screens/acheteur/address_management_screen.dart';
import 'package:social_business_pro/screens/acheteur/payment_methods_screen.dart';
import 'package:social_business_pro/screens/acheteur/categories_screen.dart';
import 'package:social_business_pro/screens/acheteur/favorite_screen.dart';
import 'package:social_business_pro/screens/admin/global_statistics_screen.dart';
import 'package:social_business_pro/screens/admin/user_management_screen.dart';
import 'package:social_business_pro/screens/admin/vendor_management_screen.dart';
import 'package:social_business_pro/screens/livreur/delivery_detail_screen.dart';
import 'package:social_business_pro/screens/livreur/livreur_main_screen.dart';
import 'package:social_business_pro/screens/livreur/delivery_list_screen.dart';
import 'package:social_business_pro/screens/livreur/livreur_earnings_screen.dart';
import 'package:social_business_pro/screens/livreur/livreur_profile_screen.dart';
import 'package:social_business_pro/screens/acheteur/acheteur_profile_screen.dart';
import 'package:social_business_pro/screens/admin/admin_profile_screen.dart';
import 'package:social_business_pro/screens/admin/admin_dashboard.dart';
import 'package:social_business_pro/screens/vendeur/vendeur_main_screen.dart';
import 'package:social_business_pro/screens/vendeur/add_product.dart';
import 'package:social_business_pro/screens/vendeur/vendeur_statistics.dart';

// Nouveaux imports
import 'package:social_business_pro/screens/vendeur/vendeur_profile_screen.dart';
import 'package:social_business_pro/screens/subscription/subscription_dashboard_screen.dart';
import 'package:social_business_pro/screens/subscription/subscription_plans_screen.dart';
import 'package:social_business_pro/screens/auth/change_password_screen.dart';
import 'package:social_business_pro/screens/common/notifications_screen.dart';

import '../screens/main_scaffold.dart';
import '../screens/auth/login_screen_extended.dart';
import '../screens/auth/register_screen_extended.dart';
import '../screens/temp_screens.dart';
import '../screens/vendeur/edit_product_dart.dart';
import '../screens/vendeur/order_detail_dart.dart';
import '../providers/auth_provider_firebase.dart';
import '../screens/acheteur/product_detail_screen.dart';
import '../screens/acheteur/order_history_screen.dart';
import '../screens/acheteur/cart_screen.dart';
import '../config/constants.dart';
import '../screens/subscription/subscription_subscribe_screen.dart';
import '../screens/subscription/limit_reached_screen.dart';
import '../models/subscription_model.dart';

class AppRouter {
  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/',
      refreshListenable: authProvider,
      
      redirect: (BuildContext context, GoRouterState state) {
        final isAuthenticated = authProvider.isAuthenticated;
        final user = authProvider.user;
        final currentpath = state.uri.path;
        
        final publicpaths = ['/', '/login', '/register', '/forgot-password','/product', '/categories'];
        
        if (publicpaths.contains(currentpath)) return null;
        
        if (!isAuthenticated) return '/login';

        // Ajout de la vérification de nullité pour l'utilisateur
        if (user == null) return '/login';
        
        if (currentpath == '/') {
          switch (user.userType) {
            case UserType.admin: return '/admin-dashboard';
            case UserType.acheteur: return '/acheteur-home';
            case UserType.vendeur: return '/vendeur-dashboard';
            case UserType.livreur: return '/livreur-dashboard';
          }
        }

        if (currentpath.startsWith('/vendeur') && user.userType != UserType.vendeur) return '/';
        if (currentpath.startsWith('/admin') && user.userType != UserType.admin) return '/';
        if (currentpath.startsWith('/livreur') && user.userType != UserType.livreur) return '/';
        if (currentpath.startsWith('/acheteur') && user.userType != UserType.acheteur) return '/';
        
        return null;
      },
      
      routes: <RouteBase>[
        GoRoute(
            path: '/', 
            builder: (context, state) => const MainScaffold()
        ),

        // AUTH
        GoRoute(
            path: '/login', 
            builder: (context, state) => const LoginScreenExtended()
        ),
        GoRoute(
            path: '/register',
            builder: (context, state) => const RegisterScreenExtended()
        ),

        GoRoute(
            path: '/forgot-password',
            builder: (context, state) => const TempScreen(
                title: 'Mot de passe oublié',
                subtitle: 'Récupération de mot de passe',
                description: 'Vous avez oublié votre mot de passe ?',
                icon: Icons.lock_reset,)
        ),

        // ROUTES TRANSVERSALES (tous les types d'utilisateurs)
        GoRoute(
            path: '/change-password',
            builder: (context, state) => const ChangePasswordScreen()
        ),
        GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsScreen()
        ),



        // VENDEUR
        GoRoute(path: '/vendeur-dashboard', builder: (context, state) => const VendeurMainScreen()),
        GoRoute(path: '/vendeur/add-product', builder: (context, state) => const AddProduct()),
        GoRoute(path: '/vendeur/edit-product/:productId', builder: (context, state) => EditProduct(productId: state.pathParameters['productId']!)),
        GoRoute(path: '/vendeur/order-detail/:id', builder: (context, state) => OrderDetail(orderId: state.pathParameters['id']!)),
        GoRoute(path: '/vendeur/profile', builder: (context, state) => const VendeurProfileScreen()),
        GoRoute(path: '/vendeur/subscription', builder: (context, state) => const SubscriptionDashboardScreen()), // Tableau de bord par défaut
        GoRoute(path: '/vendeur/vendeur-statistics', builder: (context, state) => const Statistics()),

        // ABONNEMENTS (Transversal: vendeurs et livreurs)
        GoRoute(
          path: '/subscription/subscribe',
          builder: (context, state) {
            final tier = state.extra;
            if (tier is VendeurSubscriptionTier) {
              return SubscriptionSubscribeScreen(tier: tier);
            } else if (tier is LivreurTier) {
              return SubscriptionSubscribeScreen(tier: tier);
            } else {
              return const Scaffold(
                  body: Center(child: Text('Erreur: Plan non spécifié ou invalide')));
            }
          },
        ),
        GoRoute(
            path: '/subscription/plans',
            builder: (context, state) => const SubscriptionPlansScreen(),
        ),
        GoRoute(
            path: '/subscription/limit-reached',
            builder: (context, state) => LimitReachedScreen(
                limitType: state.extra as String? ?? 'products')
        ),
        GoRoute(
            path: '/subscription/dashboard',
            builder: (context, state) => const SubscriptionDashboardScreen(),
        ),

        // ACHETEUR
        GoRoute(
          path: '/acheteur-home', 
          builder: (context, state) => const MainScaffold(),
        ),

        GoRoute(
            path: '/acheteur/cart', 
            builder: (context, state) => const CartScreen()
        ),

        GoRoute(path: '/acheteur/checkout', builder: (context, state) => const CheckoutScreen()),
        GoRoute(path: '/acheteur/orders', builder: (context, state) => const OrderHistoryScreen()),
        GoRoute(path: '/acheteur/profile', builder: (context, state) => const AcheteurProfileScreen()),
        GoRoute(path: '/acheteur/addresses', builder: (context, state) => const AddressManagementScreen()),
        GoRoute(path: '/acheteur/payment-methods', builder: (context, state) => const PaymentMethodsScreen()),
        GoRoute(path: '/product/:id', builder: (context, state) => ProductDetailScreen(productId: state.pathParameters['id']!)),

        // Routes communes acheteur (accessibles sans /acheteur)
        GoRoute(path: '/categories', builder: (context, state) => const CategoriesScreen()),
        GoRoute(path: '/favorites', builder: (context, state) => const FavoriteScreen()),

        // LIVREUR
        GoRoute(path: '/livreur-dashboard', builder: (context, state) => const LivreurMainScreen()),
        GoRoute(path: '/livreur/deliveries', builder: (context, state) => const DeliveryListScreen()),
        GoRoute(path: '/livreur/delivery-detail/:id', builder: (context, state) => DeliveryDetailScreen(deliveryId: state.pathParameters['id']!)),
        GoRoute(path:  '/livreur/earnings', builder: (context, state) => const LivreurEarningsScreen()),
        GoRoute(path: '/livreur/profile', builder: (context, state) => const LivreurProfileScreen()),
        GoRoute(path: '/livreur/subscription', builder: (context, state) => const SubscriptionDashboardScreen()),
       

        // ADMIN
        GoRoute(
          path: '/admin-dashboard', 
          builder: (context, state) => const AdminDashboard()
          ),
       
        GoRoute(
          path: '/admin/profile', 
          builder: (context, state) => const AdminProfileScreen()
        ),

        GoRoute(
          path: '/admin/users', 
          builder: (context, state) => const UserManagementScreen()
        ),

        GoRoute(
          path: '/admin/vendors', 
          builder: (context, state) => const VendorManagementScreen()
        ),

        GoRoute(
          path: '/admin/statistics', 
          builder: (context, state) => const GlobalStatisticsScreen()
        ),
      ],

      errorBuilder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('Erreur')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Page introuvable', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(state.uri.toString(), style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: () => context.go('/'), child: const Text('Retour à l\'accueil')),
            ],
          ),
        ),
      ),
    );
  }
}
