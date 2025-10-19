// ===== lib/config/user_type_config.dart =====

/// Configuration locale des types d'utilisateurs
/// À utiliser quand Firestore est inaccessible
library;

import 'constants.dart';

class UserTypeConfig {
  /// Mapping manuel des emails vers leur type d'utilisateur
  /// Utilisé comme fallback quand Firestore ne répond pas
  static final Map<String, String> emailToUserType = {
    // Admins
    'admin@socialbusiness.ci': 'admin',

    // Livreurs
    'livreurtest@test.ci': 'livreur',

    // Vendeurs
    'vendeurtest@test.ci': 'vendeur',
    'armo@test.com': 'vendeur',

    // Acheteurs
    'acheteurtest@test.ci': 'acheteur',
    'snikangy2012@gmail.com': 'acheteur',

    // Ajoutez vos autres utilisateurs ici...
  };

  /// Obtenir le type d'utilisateur depuis l'email
  static String getUserTypeFromEmail(String? email) {
    if (email == null) return 'acheteur';

    // Chercher dans le mapping
    final userType = emailToUserType[email.toLowerCase()];

    if (userType != null) {
      return userType;
    }

    // Détecter admin par pattern email
    if (email.toLowerCase().contains('admin@')) {
      return 'admin';
    }

    // Détecter livreur par pattern email
    if (email.toLowerCase().contains('livreur')) {
      return 'livreur';
    }

    // Détecter vendeur par pattern email
    if (email.toLowerCase().contains('vendeur')) {
      return 'vendeur';
    }

    // Par défaut: acheteur
    return 'acheteur';
  }

  /// Convertir string vers UserType enum
  static UserType parseUserType(String typeString) {
    switch (typeString.toLowerCase()) {
      case 'admin':
        return UserType.admin;
      case 'livreur':
        return UserType.livreur;
      case 'vendeur':
        return UserType.vendeur;
      case 'acheteur':
      default:
        return UserType.acheteur;
    }
  }
}
