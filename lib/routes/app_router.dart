import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:social_business_pro/screens/acheteur/checkout_screen.dart';
import 'package:social_business_pro/screens/acheteur/address_management_screen.dart';
import 'package:social_business_pro/screens/acheteur/payment_methods_screen.dart';
import 'package:social_business_pro/screens/acheteur/categories_screen.dart';
import 'package:social_business_pro/screens/acheteur/favorite_screen.dart';
import 'package:social_business_pro/screens/acheteur/product_search_screen.dart';
import 'package:social_business_pro/screens/acheteur/my_reviews_screen.dart';
import 'package:social_business_pro/screens/admin/admin_livreur_management_screen.dart';
import 'package:social_business_pro/screens/admin/admin_livreur_detail_screen.dart';
import 'package:social_business_pro/screens/admin/global_statistics_screen.dart';
import 'package:social_business_pro/screens/admin/migration_tools_screen.dart';
import 'package:social_business_pro/screens/livreur/delivery_detail_screen.dart';
import 'package:social_business_pro/screens/livreur/livreur_main_screen.dart';
import 'package:social_business_pro/screens/livreur/delivery_list_screen.dart';
import 'package:social_business_pro/screens/livreur/livreur_earnings_screen.dart';
import 'package:social_business_pro/screens/livreur/livreur_profile_screen.dart';
import 'package:social_business_pro/screens/livreur/documents_management_screen.dart';
import 'package:social_business_pro/screens/livreur/livreur_reviews_screen.dart';
import 'package:social_business_pro/screens/livreur/available_orders_screen.dart';
import 'package:social_business_pro/screens/acheteur/acheteur_profile_screen.dart';
import 'package:social_business_pro/screens/admin/admin_main_screen.dart';
import 'package:social_business_pro/screens/admin/settings_screen.dart';
import 'package:social_business_pro/screens/admin/activity_log_screen.dart';
import 'package:social_business_pro/screens/admin/admin_subscription_management_screen.dart';
import 'package:social_business_pro/screens/admin/vendor_management_screen.dart';
import 'package:social_business_pro/screens/admin/admin_product_management_screen.dart';
import 'package:social_business_pro/screens/admin/admin_order_management_screen.dart';
import 'package:social_business_pro/screens/admin/suspended_users_screen.dart';

import 'package:social_business_pro/screens/vendeur/vendeur_main_screen.dart';
import 'package:social_business_pro/screens/vendeur/add_product.dart';
import 'package:social_business_pro/screens/vendeur/vendeur_statistics.dart';
import 'package:social_business_pro/screens/vendeur/product_management.dart';
import 'package:social_business_pro/screens/vendeur/refund_management_screen.dart';

// Nouveaux imports
import 'package:social_business_pro/screens/vendeur/vendeur_profile_screen.dart';
import 'package:social_business_pro/screens/vendeur/vendeur_finance_screen.dart';
import 'package:social_business_pro/screens/vendeur/sale_detail_screen.dart';
import 'package:social_business_pro/screens/vendeur/payment_settings_screen.dart';
import 'package:social_business_pro/screens/vendeur/vendeur_reviews_screen.dart';
import 'package:social_business_pro/screens/vendeur/shop_setup_screen.dart';
import 'package:social_business_pro/screens/vendeur/my_shop_screen.dart';
import 'package:social_business_pro/screens/vendeur/payment_history_screen.dart';
import 'package:social_business_pro/screens/subscription/subscription_dashboard_screen.dart';
import 'package:social_business_pro/screens/subscription/subscription_plans_screen.dart';
import 'package:social_business_pro/screens/auth/change_password_screen.dart';
import 'package:social_business_pro/screens/auth/change_initial_password_screen.dart';
import 'package:social_business_pro/screens/common/notifications_screen.dart';
import 'package:social_business_pro/screens/common/user_settings_screen.dart';

import '../screens/main_scaffold.dart';
import '../screens/auth/login_screen_extended.dart';
import '../screens/auth/register_screen_extended.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/kyc/kyc_upload_screen.dart';
import '../screens/kyc/kyc_pending_screen.dart';
import '../screens/kyc/verification_required_screen.dart';
import '../screens/admin/kyc_validation_screen.dart';

import '../screens/vendeur/edit_product.dart';
import '../screens/vendeur/order_detail_screen.dart';
import '../providers/auth_provider_firebase.dart';
import '../screens/acheteur/product_detail_screen.dart';
import '../screens/acheteur/order_history_screen.dart';
import '../screens/acheteur/order_detail_screen.dart';
import '../screens/acheteur/cart_screen.dart';
import '../screens/acheteur/delivery_tracking_screen.dart';
import 'package:social_business_pro/config/constants.dart';
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

        // ✅ VÉRIFIER SI L'UTILISATEUR DOIT CHANGER SON MOT DE PASSE INITIAL
        // (Sauf s'il est déjà sur la page de changement de mot de passe)
        if (currentpath != '/change-initial-password') {
          final needsPasswordChange = user.profile['needsPasswordChange'] ?? false;
          if (needsPasswordChange == true) {
            debugPrint('🔐 Redirection vers changement de mot de passe initial');
            return '/change-initial-password';
          }
        }

        if (currentpath == '/') {
          switch (user.userType) {
            case UserType.admin: return '/admin-dashboard';
            case UserType.acheteur: return '/acheteur-home';
            case UserType.vendeur:
              // Vérifier si shopLocation est défini
              final profile = user.profile;
              if (profile.isNotEmpty) {
                final vendeurProfile = profile['vendeurProfile'] as Map<String, dynamic>?;
                if (vendeurProfile == null || vendeurProfile['shopLocation'] == null) {
                  debugPrint('⚠️ shopLocation non défini, redirection vers setup');
                  return '/vendeur/shop-setup';
                }
              }
              return '/vendeur-dashboard';
            case UserType.livreur: return '/livreur-dashboard';
          }
        }

        // Vérifier shopLocation pour accès dashboard vendeur
        if (currentpath == '/vendeur-dashboard' && user.userType == UserType.vendeur) {
          final profile = user.profile;
          if (profile.isNotEmpty) {
            final vendeurProfile = profile['vendeurProfile'] as Map<String, dynamic>?;
            if (vendeurProfile == null || vendeurProfile['shopLocation'] == null) {
              debugPrint('⚠️ Tentative accès dashboard sans shopLocation');
              return '/vendeur/shop-setup';
            }
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
            builder: (context, state) => const ForgotPasswordScreen()
        ),

        // ROUTES KYC (Vérification d'identité)
        GoRoute(
            path: '/kyc-verification',
            builder: (context, state) => const KYCUploadScreen()
        ),
        GoRoute(
            path: '/kyc-pending',
            builder: (context, state) => const KYCPendingScreen()
        ),
        GoRoute(
            path: '/verification-required',
            builder: (context, state) => const VerificationRequiredScreen()
        ),

        // ROUTES TRANSVERSALES (tous les types d'utilisateurs)
        GoRoute(
            path: '/change-password',
            builder: (context, state) => const ChangePasswordScreen()
        ),
        GoRoute(
            path: '/change-initial-password',
            builder: (context, state) => const ChangeInitialPasswordScreen()
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
        GoRoute(path: '/vendeur/finance', builder: (context, state) => const VendeurFinanceScreen()),
        GoRoute(path: '/vendeur/sale-detail/:id', builder: (context, state) => SaleDetailScreen(saleId: state.pathParameters['id']!)),
        GoRoute(path: '/vendeur/profile', builder: (context, state) => const VendeurProfileScreen()),
        GoRoute(path: '/vendeur/payment-settings', builder: (context, state) => const VendeurPaymentSettingsScreen()),
        GoRoute(path: '/vendeur/reviews', builder: (context, state) => const VendeurReviewsScreen()),
        GoRoute(path: '/vendeur/my-shop', builder: (context, state) => const MyShopScreen()),
        GoRoute(path: '/vendeur/shop-setup', builder: (context, state) => const ShopSetupScreen()),
        GoRoute(path: '/vendeur/payment-history', builder: (context, state) => const PaymentHistoryScreen()),
        GoRoute(path: '/vendeur/subscription', builder: (context, state) => const SubscriptionDashboardScreen()), // Tableau de bord par défaut
        GoRoute(path: '/vendeur/vendeur-statistics', builder: (context, state) => const Statistics()),
        GoRoute(path: '/vendeur/products', builder: (context, state) => ProductManagement(storeId: authProvider.user?.id ?? '')),
        GoRoute(path: '/vendeur/refunds', builder: (context, state) => const RefundManagementScreen()),

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
        GoRoute(
          path: '/acheteur/order/:id',
          builder: (context, state) => AcheteurOrderDetailScreen(
            orderId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/acheteur/order/:orderId/tracking',
          builder: (context, state) => DeliveryTrackingScreen(
            orderId: state.pathParameters['orderId']!,
          ),
        ),
        GoRoute(path: '/acheteur/profile', builder: (context, state) => const AcheteurProfileScreen()),
        GoRoute(path: '/acheteur/addresses', builder: (context, state) => const AddressManagementScreen()),
        GoRoute(path: '/acheteur/payment-methods', builder: (context, state) => const PaymentMethodsScreen()),
        GoRoute(path: '/acheteur/my-reviews', builder: (context, state) => const MyReviewsScreen()),
        GoRoute(path: '/acheteur/search', builder: (context, state) => const ProductSearchScreen()),
        GoRoute(path: '/product/:id', builder: (context, state) => ProductDetailScreen(productId: state.pathParameters['id']!)),

        // Routes communes acheteur (accessibles sans /acheteur)
        GoRoute(
          path: '/categories',
          builder: (context, state) => CategoriesScreen(
            initialCategory: state.extra as String?,
          ),
        ),
        GoRoute(path: '/favorites', builder: (context, state) => const FavoriteScreen()),

        // LIVREUR
        GoRoute(path: '/livreur-dashboard', builder: (context, state) => const LivreurMainScreen()),
        GoRoute(path: '/livreur/available-orders', builder: (context, state) => const AvailableOrdersScreen()),
        GoRoute(path: '/livreur/deliveries', builder: (context, state) => const DeliveryListScreen()),
        GoRoute(path: '/livreur/delivery-detail/:id', builder: (context, state) => DeliveryDetailScreen(deliveryId: state.pathParameters['id']!)),
        GoRoute(path:  '/livreur/earnings', builder: (context, state) => const LivreurEarningsScreen()),
        GoRoute(path: '/livreur/profile', builder: (context, state) => const LivreurProfileScreen()),
        GoRoute(path: '/livreur/documents', builder: (context, state) => const DocumentsManagementScreen()),
        GoRoute(path: '/livreur/reviews', builder: (context, state) => const LivreurReviewsScreen()),
        GoRoute(path: '/livreur/subscription', builder: (context, state) => const SubscriptionDashboardScreen()),
       

        // ADMIN
        GoRoute(
          path: '/admin-dashboard',
          builder: (context, state) => const AdminMainScreen()
        ),
        GoRoute(path: '/admin/settings', builder: (context, state) => const SettingsScreen()),
        GoRoute(path: '/admin/activities', builder: (context, state) => const ActivityLogScreen()),
        GoRoute (path: '/admin/global-statistics', builder: (context, state) => const GlobalStatisticsScreen()),
        GoRoute(path: '/admin/subscription-management', builder: (context, state) => const AdminSubscriptionManagementScreen()),
        GoRoute(path: '/admin/migration-tools', builder: (context, state) => const MigrationToolsScreen()),
        GoRoute(path: '/admin/vendors', builder: (context, state) => const VendorManagementScreen()),
        GoRoute(path: '/admin/livreurs', builder: (context, state) => const AdminLivreurManagementScreen()),
        GoRoute(path: '/admin/livreur-detail/:id', builder: (context, state) => AdminLivreurDetailScreen(livreurId: state.pathParameters['id']!)),
        GoRoute(path: '/admin/kyc-validation', builder: (context, state) => const KYCValidationScreen()),
        GoRoute(path: '/admin/product-management', builder: (context, state) => const AdminProductManagementScreen()),
        GoRoute(path: '/admin/order-management', builder: (context, state) => const AdminOrderManagementScreen()),
        GoRoute(path: '/admin/suspended-users', builder: (context, state) => const SuspendedUsersScreen()),

        // PARAMÈTRES UTILISATEUR (commun à tous)
        GoRoute(path: '/user-settings', builder: (context, state) => const UserSettingsScreen()),
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
