// ===== lib/config/payment_methods_config.dart =====
// Configuration des méthodes de paiement et leurs logos

class PaymentMethodsConfig {
  // Map des logos Mobile Money
  static const Map<String, String> logos = {
    'orange_money': 'assets/Mobile Money LOGO/Orange-Money-logo-1024x687.png',
    'mtn_money': 'assets/Mobile Money LOGO/mtn-momo-mobile-money.png',
    'moov_money': 'assets/Mobile Money LOGO/moov money logo.png',
    'wave': 'assets/Mobile Money LOGO/logo wave.png', // ✅ Corrigé: espace au lieu de underscore
  };

  // Obtenir le logo pour une méthode
  static String? getLogo(String methodId) {
    return logos[methodId];
  }

  // Vérifier si une méthode a un logo
  static bool hasLogo(String methodId) {
    return logos.containsKey(methodId);
  }
}
