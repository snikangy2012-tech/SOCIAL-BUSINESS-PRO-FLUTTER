// ===== lib/config/constants.dart =====
// Équivalent de votre src/config/constants.ts

import 'package:flutter/material.dart';

// ===== CONFIGURATION PRINCIPALE =====
class AppConstants {
  // App Info (équivalent APP_CONFIG)
  static const String appName = 'SOCIAL BUSINESS Pro';
  static const String version = '1.0.0';
  static const String slogan = 'Vendre comme un Pro, Livrer comme un Boss';
  
  // Contact
  static const String supportEmail = 'support@socialbusinesspro.ci';
  static const String supportPhone = '+225 07 49 70 54 04';
  static const String supportWhatsApp = '+2250749705404';
  
  // URLs
  static const String apiUrl = 'https://api.socialbusinesspro.ci/v1';
  static const String webUrl = 'https://socialbusinesspro.ci';
}

// ===== COULEURS DU THÈME =====
// Équivalent de votre APP_CONFIG.COLORS
class AppColors {
  // Couleurs principales
  static const Color primary = Color(0xFFf97316); // Orange principal
  static const Color primaryDark = Color(0xFFea580c);
  static const Color primaryLight = Color(0xFFfed7aa);
  
  // Couleurs secondaires
  static const Color secondary = Color(0xFF059669); // Vert secondaire
  static const Color secondaryDark = Color(0xFF047857);
  static const Color secondaryLight = Color(0xFFa7f3d0);
  
  // États
  static const Color success = Color(0xFF10b981);
  static const Color error = Color(0xFFef4444);
  static const Color warning = Color(0xFFf59e0b);
  static const Color info = Color(0xFF3b82f6);
  
  // Textes
  static const Color textPrimary = Color(0xFF1f2937);
  static const Color textSecondary = Color(0xFF6b7280);
  static const Color textLight = Color(0xFF9ca3af);
  
  // Arrière-plans
  static const Color background = Color(0xFFffffff);
  static const Color backgroundSecondary = Color(0xFFf9fafb);
  static const Color backgroundDark = Color(0xFF111827);
  
  // Bordures
  static const Color border = Color(0xFFe5e7eb);
  static const Color borderLight = Color(0xFFf3f4f6);
  
  // Utilitaires
  static const Color white = Color(0xFFffffff);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Colors.transparent;
}

// ===== ESPACEMENTS =====
// Équivalent de votre APP_CONFIG.SPACING
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

// ===== RAYONS DE BORDURE =====
// Équivalent de votre APP_CONFIG.BORDER_RADIUS
class AppRadius {
  static const double sm = 4.0;
  static const double md = 8.0;
  static const double lg = 12.0;
  static const double xl = 16.0;
  static const double full = 999.0;
}

// ===== TAILLES DE POLICE =====
// Équivalent de votre APP_CONFIG.FONT_SIZES
class AppFontSizes {
  static const double xs = 12.0;
  static const double sm = 14.0;
  static const double md = 16.0;
  static const double lg = 18.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
}

// ===== DIMENSIONS =====
// Équivalent de votre APP_CONFIG.DIMENSIONS
class AppDimensions {
  // Hauteurs standard
  static const double headerHeight = 56.0;
  static const double tabBarHeight = 60.0;
  
  // Helpers pour responsive design
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 375;
  }
  
  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= 768;
  }

  
}

// ===== TYPES D'UTILISATEURS =====
// Équivalent de vos USER_TYPES
enum UserType {
  vendeur('vendeur'),
  acheteur('acheteur'),
  livreur('livreur'),
  admin('admin'); // ← Nouveau type admin

  const UserType(this.value);
  final String value;

  // Getter pour le label en français
  String get label {
    switch (this) {
      case UserType.vendeur:
        return 'Vendeur';
      case UserType.acheteur:
        return 'Acheteur';
      case UserType.livreur:
        return 'Livreur';
      case UserType.admin:
        return 'Admin';
    }
  }
}

// ===== COLLECTIONS FIREBASE =====
// Équivalent de vos COLLECTIONS
class FirebaseCollections {
  static const String users = 'users';
  static const String products = 'products';
  static const String orders = 'orders';
  static const String payments = 'payments';
  static const String deliveries = 'deliveries';
  static const String notifications = 'notifications';
  static const String categories = 'categories';
  static const String reviews = 'reviews';
  static const String analytics = 'analytics';
}

enum VerificationStatus {
  verified,
  pending,
  rejected,
  notVerified;

  String get value => toString().split('.').last;
}

enum OrderStatus {
  pending('pending'),
  confirmed('confirmed'),
  preparing('preparing'),
  ready('ready'),
  inDelivery('in_delivery'),
  delivered('delivered'),
  cancelled('cancelled');

  final String value;
  const OrderStatus(this.value);
}

// ===== DURÉES D'ANIMATION =====
class AppDurations {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration splash = Duration(seconds: 2);
}

// ===== LIMITES ET VALIDATIONS =====
class AppLimits {
  // Produits
  static const int maxProductImages = 5;
  static const int maxProductNameLength = 100;
  static const int maxProductDescriptionLength = 500;

    // Minimum du prix d'un produit :
  static const int minProductPrice = 100; // Prix minimum en FCFA
  
  // Commandes
  static const int minOrderAmount = 1000; // FCFA
  static const int maxOrderItems = 20;
  
  // Messages
  static const int maxMessageLength = 500;
  
  // Fichiers
  static const int maxImageSizeMB = 5;
  static const int maxVideoSizeMB = 50;
}

// ===== ROUTES DE NAVIGATION =====
class AppRoutes {
  // Auth
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String verifyOTP = '/verify-otp';
  
  // Vendeur
  static const String vendeurDashboard = '/vendeur';
  static const String productManagement = '/vendeur/products';
  static const String addProduct = '/vendeur/products/add';
  static const String orderManagement = '/vendeur/orders';
  static const String statistics = '/vendeur/statistics';
  
  // Acheteur
  static const String acheteurHome = '/acheteur';
  static const String productDetail = '/acheteur/product';
  static const String cart = '/acheteur/cart';
  static const String checkout = '/acheteur/checkout';
  
  // Livreur
  static const String deliveryDashboard = '/livreur';
  static const String deliveryMap = '/livreur/map';
  static const String activeDelivery = '/livreur/active';
  
  // Admin
  static const String adminDashboard = '/admin';
  
  // Commun
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String notifications = '/notifications';
  static const String help = '/help';
}