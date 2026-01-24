# Plan d'Implémentation - Éléments du Thème SmarterVision

## Vue d'Ensemble

Ce document détaille l'implémentation des éléments visuels et fonctionnels inspirés du thème **e-commerce-flutter-app-ui-kit-by-smartervision** dans l'application **SOCIAL BUSINESS Pro**, tout en conservant le thème Vert Émeraude (Money Green) pour l'identité ivoirienne.

**Date**: 26 décembre 2025
**Thème actuel**: Vert Émeraude (#4CAF50) - FlexScheme.money
**Thème analysé**: SmarterVision (Cyan/Teal #17A2B8)

---

## 📋 Tableau de Synthèse des Éléments à Implémenter

| # | Élément | Priorité | Complexité | Fichiers Concernés | Statut |
|---|---------|----------|------------|-------------------|--------|
| 1 | Connexion Réseaux Sociaux | CRITIQUE | Élevée | `login_screen.dart`, `register_screen.dart`, `auth_service.dart` | À faire |
| 2 | Cartes Vendeur avec Gradients | Haute | Moyenne | `acheteur_home.dart`, `vendor_card.dart` (nouveau) | À faire |
| 3 | Badges/Pills pour Statuts | Haute | Faible | `order_card.dart`, `status_badge.dart` (nouveau) | À faire |
| 4 | Chips pour Filtres Catégories | Moyenne | Faible | `category_filter.dart` (nouveau), screens concernés | À faire |
| 5 | Navigation Bottom avec FAB Central | Moyenne | Moyenne | `vendeur_main_screen.dart`, `acheteur_main_screen.dart` | À faire |
| 6 | Écrans Onboarding Illustrés | Faible | Moyenne | `onboarding_screen.dart` (nouveau) | À faire |
| 7 | Grille Marques/Catégories | Faible | Faible | `categories_screen.dart`, `brands_screen.dart` | À faire |

---

## 🎯 PRIORITÉ 1 - Intégration Réseaux Sociaux (CRITIQUE)

### Contexte Stratégique

**Objectif business**: Connecter les vendeurs informels des réseaux sociaux (Facebook, WhatsApp, Instagram, TikTok) à la plateforme professionnelle SOCIAL BUSINESS Pro.

**Citation utilisateur**:
> "c'est justement pour les vendeurs qui sont dans l'informel sur les réseaux sociaux que j'ai créé cette application (facebook, whatsapp, instagram et surtout Tiktok qui a un essort fulgurant en ce moment mon objectif meme et de lier mon appli a leurs reseaux afin de le rediriger vers l'appli qui offre plus de professionalisme a leur vente et une meilleu gestion)"

### Phase 1.1 - Connexion Sociale (Social Login)

#### Dépendances à Ajouter

```yaml
# pubspec.yaml - Section dependencies
dependencies:
  # Authentification sociale
  google_sign_in: ^6.2.1              # Connexion Google
  flutter_facebook_auth: ^7.0.1       # Connexion Facebook
  sign_in_with_apple: ^6.1.1          # Connexion Apple (iOS)

  # Partage social
  share_plus: ^10.0.2                 # Partage de contenu
  url_launcher: ^6.3.0                # Ouvrir URLs/apps externes

  # Deep linking
  uni_links: ^0.5.1                   # Deep links (deprecated mais stable)
  app_links: ^6.3.2                   # Deep links moderne (alternative)
```

#### Configuration Firebase (Social Login)

**Étapes**:

1. **Console Firebase** → Authentication → Sign-in method
   - Activer **Google**
   - Activer **Facebook** (nécessite Facebook App ID + Secret)
   - Activer **Apple** (pour iOS uniquement)

2. **Facebook Developer Console**
   - Créer une app Facebook: https://developers.facebook.com/apps
   - Obtenir App ID et App Secret
   - Configurer OAuth Redirect URI: `https://socialbusinesspro.firebaseapp.com/__/auth/handler`
   - Activer permissions: `email`, `public_profile`

3. **Android Configuration** (`android/app/src/main/AndroidManifest.xml`)

```xml
<!-- Facebook Login -->
<meta-data
    android:name="com.facebook.sdk.ApplicationId"
    android:value="@string/facebook_app_id"/>

<activity
    android:name="com.facebook.FacebookActivity"
    android:configChanges="keyboard|keyboardHidden|screenLayout|screenSize|orientation"
    android:label="@string/app_name" />

<activity
    android:name="com.facebook.CustomTabActivity"
    android:exported="true">
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="@string/fb_login_protocol_scheme" />
    </intent-filter>
</activity>
```

4. **Android Strings** (`android/app/src/main/res/values/strings.xml`)

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">SOCIAL BUSINESS Pro</string>
    <string name="facebook_app_id">VOTRE_FACEBOOK_APP_ID</string>
    <string name="fb_login_protocol_scheme">fbVOTRE_FACEBOOK_APP_ID</string>
</resources>
```

#### Fichier: `lib/services/social_auth_service.dart` (NOUVEAU)

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter/foundation.dart';

class SocialAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Connexion avec Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Déclencher le flux d'authentification Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('❌ Connexion Google annulée par l\'utilisateur');
        return null;
      }

      // Obtenir les détails d'authentification
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Créer un credential Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Connecter à Firebase
      final userCredential = await _auth.signInWithCredential(credential);
      debugPrint('✅ Connexion Google réussie: ${userCredential.user?.email}');

      return userCredential;
    } catch (e) {
      debugPrint('❌ Erreur connexion Google: $e');
      rethrow;
    }
  }

  /// Connexion avec Facebook
  Future<UserCredential?> signInWithFacebook() async {
    try {
      // Déclencher le flux d'authentification Facebook
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status != LoginStatus.success) {
        debugPrint('❌ Connexion Facebook échouée: ${result.status}');
        return null;
      }

      // Créer un credential Firebase
      final OAuthCredential credential = FacebookAuthProvider.credential(
        result.accessToken!.tokenString,
      );

      // Connecter à Firebase
      final userCredential = await _auth.signInWithCredential(credential);
      debugPrint('✅ Connexion Facebook réussie: ${userCredential.user?.email}');

      return userCredential;
    } catch (e) {
      debugPrint('❌ Erreur connexion Facebook: $e');
      rethrow;
    }
  }

  /// Déconnexion de tous les providers sociaux
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
        FacebookAuth.instance.logOut(),
      ]);
      debugPrint('✅ Déconnexion sociale réussie');
    } catch (e) {
      debugPrint('❌ Erreur déconnexion sociale: $e');
    }
  }

  /// Vérifier si l'utilisateur est connecté via un provider social
  String? getCurrentProvider() {
    final user = _auth.currentUser;
    if (user == null) return null;

    for (var providerData in user.providerData) {
      if (providerData.providerId == 'google.com') return 'Google';
      if (providerData.providerId == 'facebook.com') return 'Facebook';
      if (providerData.providerId == 'apple.com') return 'Apple';
    }
    return 'Email'; // Connexion classique
  }
}
```

#### Fichier: `lib/widgets/social_login_buttons.dart` (NOUVEAU)

```dart
import 'package:flutter/material.dart';
import '../config/constants.dart';

class SocialLoginButton extends StatelessWidget {
  final String provider; // 'google', 'facebook', 'apple'
  final VoidCallback onPressed;
  final bool isLoading;

  const SocialLoginButton({
    super.key,
    required this.provider,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getProviderConfig();

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Image.asset(
                config['icon']!,
                width: 24,
                height: 24,
              ),
        label: Text(
          isLoading ? 'Connexion...' : config['label']!,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(int.parse(config['color']!)),
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Map<String, String> _getProviderConfig() {
    switch (provider.toLowerCase()) {
      case 'google':
        return {
          'label': 'Continuer avec Google',
          'color': '0xFFDB4437', // Rouge Google
          'icon': 'assets/icons/google_icon.png',
        };
      case 'facebook':
        return {
          'label': 'Continuer avec Facebook',
          'color': '0xFF1877F2', // Bleu Facebook
          'icon': 'assets/icons/facebook_icon.png',
        };
      case 'apple':
        return {
          'label': 'Continuer avec Apple',
          'color': '0xFF000000', // Noir Apple
          'icon': 'assets/icons/apple_icon.png',
        };
      default:
        return {
          'label': 'Connexion',
          'color': '0xFF${AppColors.primary.value.toRadixString(16).substring(2)}',
          'icon': 'assets/icons/default_icon.png',
        };
    }
  }
}

/// Widget groupant tous les boutons de connexion sociale
class SocialLoginButtons extends StatelessWidget {
  final Function(String provider) onSocialLogin;
  final bool isLoading;

  const SocialLoginButtons({
    super.key,
    required this.onSocialLogin,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Séparateur "OU"
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey.shade300)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'OU',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(child: Divider(color: Colors.grey.shade300)),
          ],
        ),
        const SizedBox(height: 24),

        // Bouton Google
        SocialLoginButton(
          provider: 'google',
          onPressed: () => onSocialLogin('google'),
          isLoading: isLoading,
        ),
        const SizedBox(height: 12),

        // Bouton Facebook
        SocialLoginButton(
          provider: 'facebook',
          onPressed: () => onSocialLogin('facebook'),
          isLoading: isLoading,
        ),
        const SizedBox(height: 12),

        // Bouton Apple (iOS uniquement)
        if (Theme.of(context).platform == TargetPlatform.iOS)
          SocialLoginButton(
            provider: 'apple',
            onPressed: () => onSocialLogin('apple'),
            isLoading: isLoading,
          ),
      ],
    );
  }
}
```

#### Modification: `lib/screens/auth/login_screen.dart`

**Ajouter après le bouton de connexion email** (environ ligne 150):

```dart
// Après le bouton "Se connecter"
const SizedBox(height: 24),

// Boutons de connexion sociale
SocialLoginButtons(
  onSocialLogin: _handleSocialLogin,
  isLoading: _isLoading,
),
```

**Ajouter la méthode** dans `_LoginScreenState`:

```dart
final SocialAuthService _socialAuthService = SocialAuthService();

Future<void> _handleSocialLogin(String provider) async {
  setState(() => _isLoading = true);

  try {
    UserCredential? userCredential;

    switch (provider) {
      case 'google':
        userCredential = await _socialAuthService.signInWithGoogle();
        break;
      case 'facebook':
        userCredential = await _socialAuthService.signInWithFacebook();
        break;
      default:
        throw Exception('Provider non supporté: $provider');
    }

    if (userCredential == null) {
      // Connexion annulée par l'utilisateur
      setState(() => _isLoading = false);
      return;
    }

    // Vérifier si l'utilisateur existe dans Firestore
    final authProvider = context.read<AuthProvider>();
    await authProvider.checkAndCreateUserFromSocial(userCredential.user!);

    if (mounted) {
      // Navigation gérée par AuthProvider/Router
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bienvenue ${userCredential.user!.displayName ?? ""}!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de connexion: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}
```

#### Modification: `lib/providers/auth_provider_firebase.dart`

**Ajouter la méthode** pour créer/vérifier l'utilisateur après connexion sociale:

```dart
import '../services/social_auth_service.dart';

class AuthProvider extends ChangeNotifier {
  // ... code existant ...

  final SocialAuthService _socialAuthService = SocialAuthService();

  /// Vérifier et créer un utilisateur après connexion sociale
  Future<void> checkAndCreateUserFromSocial(User firebaseUser) async {
    try {
      // Vérifier si l'utilisateur existe dans Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get()
          .timeout(const Duration(seconds: 10));

      if (!userDoc.exists) {
        // Nouvel utilisateur - créer le profil
        debugPrint('🆕 Nouvel utilisateur social - Création du profil');

        // Déterminer le type d'utilisateur (par défaut: acheteur)
        UserType userType = UserType.acheteur;
        if (firebaseUser.email == 'admin@socialbusiness.ci') {
          userType = UserType.admin;
        }

        final newUser = UserModel(
          id: firebaseUser.uid,
          email: firebaseUser.email!,
          displayName: firebaseUser.displayName ?? 'Utilisateur',
          phoneNumber: firebaseUser.phoneNumber ?? '',
          userType: userType,
          photoURL: firebaseUser.photoURL,
          isVerified: firebaseUser.emailVerified,
          isActive: true,
          createdAt: DateTime.now(),
          profile: userType == UserType.acheteur
              ? {
                  'addresses': [],
                  'favorites': [],
                  'loyaltyPoints': 0,
                }
              : {},
        );

        // Sauvegarder dans Firestore
        await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .set(newUser.toMap());

        _user = newUser;

        // Log audit
        await AuditService.logAction(
          userId: firebaseUser.uid,
          userEmail: firebaseUser.email!,
          userName: firebaseUser.displayName ?? 'Unknown',
          userType: userType,
          action: 'social_login_first_time',
          actionLabel: 'First Social Login',
          category: AuditCategory.security,
          severity: AuditSeverity.low,
          metadata: {
            'provider': _socialAuthService.getCurrentProvider() ?? 'unknown',
          },
        );
      } else {
        // Utilisateur existant - charger le profil
        _user = UserModel.fromMap(userDoc.data()!);

        // Mettre à jour la photo si changée
        if (firebaseUser.photoURL != _user!.photoURL) {
          await updateProfile({'photoURL': firebaseUser.photoURL});
        }

        debugPrint('✅ Utilisateur social existant chargé: ${_user!.email}');
      }

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Erreur checkAndCreateUserFromSocial: $e');
      rethrow;
    }
  }

  /// Déconnexion avec support des providers sociaux
  @override
  Future<void> logout() async {
    try {
      // Déconnexion Firebase + Providers sociaux
      await _socialAuthService.signOut();
      await _auth.signOut();

      _user = null;
      notifyListeners();

      debugPrint('✅ Déconnexion complète (email + social)');
    } catch (e) {
      debugPrint('❌ Erreur logout: $e');
      rethrow;
    }
  }
}
```

#### Assets Requis

**Créer le dossier**: `assets/icons/`

**Icônes à ajouter** (PNG 512x512 transparent):
- `google_icon.png` - Logo Google (télécharger depuis Google Brand Resources)
- `facebook_icon.png` - Logo Facebook (télécharger depuis Facebook Brand Resources)
- `apple_icon.png` - Logo Apple (télécharger depuis Apple Brand Resources)

**Mettre à jour** `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/icons/
    - assets/icons/google_icon.png
    - assets/icons/facebook_icon.png
    - assets/icons/apple_icon.png
```

---

### Phase 1.2 - Partage Social (Share to Social Networks)

#### Fichier: `lib/services/social_share_service.dart` (NOUVEAU)

```dart
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';

class SocialShareService {
  /// Partager un produit sur les réseaux sociaux
  static Future<void> shareProduct(ProductModel product, {String? vendorName}) async {
    try {
      final String shareText = '''
🛍️ ${product.name}

💰 Prix: ${product.price.toStringAsFixed(0)} FCFA
${product.description.isNotEmpty ? '\n📝 ${product.description}\n' : ''}
${vendorName != null ? '🏪 Vendeur: $vendorName\n' : ''}
📱 Téléchargez SOCIAL BUSINESS Pro pour commander!

🔗 https://socialbusinesspro.ci/products/${product.id}
''';

      await Share.share(
        shareText,
        subject: product.name,
      );

      debugPrint('✅ Produit partagé: ${product.id}');
    } catch (e) {
      debugPrint('❌ Erreur partage produit: $e');
      rethrow;
    }
  }

  /// Partager directement sur WhatsApp
  static Future<void> shareToWhatsApp({
    required String text,
    String? phoneNumber,
  }) async {
    try {
      String url;

      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        // Message direct à un numéro (WhatsApp Business)
        final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
        url = 'https://wa.me/$cleanNumber?text=${Uri.encodeComponent(text)}';
      } else {
        // Partage général
        url = 'whatsapp://send?text=${Uri.encodeComponent(text)}';
      }

      final uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        debugPrint('✅ Partagé sur WhatsApp');
      } else {
        throw Exception('WhatsApp non installé');
      }
    } catch (e) {
      debugPrint('❌ Erreur partage WhatsApp: $e');
      rethrow;
    }
  }

  /// Partager sur Facebook (via navigateur)
  static Future<void> shareToFacebook(String url) async {
    try {
      final facebookUrl = Uri.parse(
        'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(url)}',
      );

      if (await canLaunchUrl(facebookUrl)) {
        await launchUrl(facebookUrl, mode: LaunchMode.externalApplication);
        debugPrint('✅ Partagé sur Facebook');
      } else {
        throw Exception('Impossible d\'ouvrir Facebook');
      }
    } catch (e) {
      debugPrint('❌ Erreur partage Facebook: $e');
      rethrow;
    }
  }

  /// Partager une boutique vendeur
  static Future<void> shareVendorShop({
    required String vendorId,
    required String shopName,
    String? description,
  }) async {
    try {
      final String shareText = '''
🏪 Découvrez ma boutique: $shopName

${description ?? 'Visitez ma boutique sur SOCIAL BUSINESS Pro!'}

📱 Téléchargez l'app pour commander:
🔗 https://socialbusinesspro.ci/vendors/$vendorId

#SocialBusinessPro #CommerceCI #MadeInCotedIvoire
''';

      await Share.share(shareText, subject: shopName);
      debugPrint('✅ Boutique partagée: $vendorId');
    } catch (e) {
      debugPrint('❌ Erreur partage boutique: $e');
      rethrow;
    }
  }

  /// Générer un lien de parrainage vendeur
  static Future<void> shareReferralLink({
    required String vendorId,
    required String vendorName,
  }) async {
    try {
      final String referralLink = 'https://socialbusinesspro.ci/refer/$vendorId';

      final String shareText = '''
🎁 $vendorName vous invite à rejoindre SOCIAL BUSINESS Pro!

✨ Inscrivez-vous avec mon lien de parrainage et profitez d'avantages exclusifs!

🔗 $referralLink

#Parrainage #SocialBusinessPro
''';

      await Share.share(shareText, subject: 'Invitation SOCIAL BUSINESS Pro');
      debugPrint('✅ Lien de parrainage partagé: $vendorId');
    } catch (e) {
      debugPrint('❌ Erreur partage parrainage: $e');
      rethrow;
    }
  }

  /// Contacter un vendeur via WhatsApp Business
  static Future<void> contactVendorWhatsApp({
    required String vendorPhone,
    required String vendorName,
    String? productName,
  }) async {
    try {
      String message = 'Bonjour $vendorName, ';

      if (productName != null) {
        message += 'je suis intéressé(e) par votre produit "$productName" vu sur SOCIAL BUSINESS Pro.';
      } else {
        message += 'j\'ai vu votre boutique sur SOCIAL BUSINESS Pro et je souhaite en savoir plus.';
      }

      await shareToWhatsApp(
        text: message,
        phoneNumber: vendorPhone,
      );
    } catch (e) {
      debugPrint('❌ Erreur contact WhatsApp vendeur: $e');
      rethrow;
    }
  }
}
```

#### Widget: `lib/widgets/social_share_button.dart` (NOUVEAU)

```dart
import 'package:flutter/material.dart';
import '../services/social_share_service.dart';
import '../config/constants.dart';

class SocialShareButton extends StatelessWidget {
  final VoidCallback? onShare;
  final IconData icon;
  final String label;
  final Color? color;

  const SocialShareButton({
    super.key,
    this.onShare,
    this.icon = Icons.share,
    this.label = 'Partager',
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onShare,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color ?? AppColors.primary,
        side: BorderSide(color: color ?? AppColors.primary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

/// Bottom sheet avec options de partage social
class SocialShareBottomSheet extends StatelessWidget {
  final String shareText;
  final String? shareUrl;

  const SocialShareBottomSheet({
    super.key,
    required this.shareText,
    this.shareUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Partager sur',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Options de partage
          _ShareOption(
            icon: Icons.share,
            label: 'Autres applications',
            color: AppColors.primary,
            onTap: () async {
              Navigator.pop(context);
              await Share.share(shareText);
            },
          ),
          const SizedBox(height: 12),

          _ShareOption(
            icon: Icons.chat,
            label: 'WhatsApp',
            color: const Color(0xFF25D366),
            onTap: () async {
              Navigator.pop(context);
              await SocialShareService.shareToWhatsApp(text: shareText);
            },
          ),
          const SizedBox(height: 12),

          if (shareUrl != null)
            _ShareOption(
              icon: Icons.facebook,
              label: 'Facebook',
              color: const Color(0xFF1877F2),
              onTap: () async {
                Navigator.pop(context);
                await SocialShareService.shareToFacebook(shareUrl!);
              },
            ),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ShareOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

#### Exemple d'Utilisation dans `product_detail_screen.dart`

**Ajouter un bouton de partage** dans l'AppBar:

```dart
AppBar(
  title: const Text('Détails du produit'),
  actions: [
    // Bouton partager
    IconButton(
      icon: const Icon(Icons.share),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          builder: (context) => SocialShareBottomSheet(
            shareText: 'Découvrez ${product.name} sur SOCIAL BUSINESS Pro!',
            shareUrl: 'https://socialbusinesspro.ci/products/${product.id}',
          ),
        );
      },
    ),
  ],
),
```

---

### Phase 1.3 - Deep Linking (Liens Profonds)

#### Configuration Deep Links

**Android** (`android/app/src/main/AndroidManifest.xml`):

```xml
<activity android:name=".MainActivity">
  <!-- Deep links -->
  <intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />

    <!-- Schema personnalisé -->
    <data android:scheme="socialbusiness" />

    <!-- URLs web -->
    <data
      android:scheme="https"
      android:host="socialbusinesspro.ci" />
  </intent-filter>
</activity>
```

**iOS** (`ios/Runner/Info.plist`):

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>socialbusiness</string>
    </array>
  </dict>
</array>
```

#### Fichier: `lib/services/deep_link_service.dart` (NOUVEAU)

```dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uni_links/uni_links.dart';
import 'package:go_router/go_router.dart';

class DeepLinkService {
  StreamSubscription? _subscription;

  /// Initialiser l'écoute des deep links
  Future<void> initDeepLinks(GoRouter router) async {
    try {
      // Gérer le lien initial (app démarré via deep link)
      final initialLink = await getInitialLink();
      if (initialLink != null) {
        _handleDeepLink(initialLink, router);
      }

      // Écouter les liens entrants (app déjà ouverte)
      _subscription = linkStream.listen(
        (String? link) {
          if (link != null) {
            _handleDeepLink(link, router);
          }
        },
        onError: (err) {
          debugPrint('❌ Erreur deep link: $err');
        },
      );

      debugPrint('✅ Deep links initialisés');
    } catch (e) {
      debugPrint('❌ Erreur initialisation deep links: $e');
    }
  }

  /// Gérer un deep link
  void _handleDeepLink(String link, GoRouter router) {
    try {
      final uri = Uri.parse(link);
      debugPrint('🔗 Deep link reçu: $link');

      // Extraire le chemin
      String path = uri.path;
      Map<String, String> queryParams = uri.queryParameters;

      // Router vers la bonne destination
      if (path.startsWith('/products/')) {
        // Produit: socialbusiness://products/PRODUCT_ID
        final productId = path.replaceFirst('/products/', '');
        router.go('/product-detail', extra: {'productId': productId});
      } else if (path.startsWith('/vendors/')) {
        // Boutique vendeur: socialbusiness://vendors/VENDOR_ID
        final vendorId = path.replaceFirst('/vendors/', '');
        router.go('/vendor-shop', extra: {'vendorId': vendorId});
      } else if (path.startsWith('/refer/')) {
        // Parrainage: socialbusiness://refer/VENDOR_ID
        final referrerId = path.replaceFirst('/refer/', '');
        router.go('/register', extra: {'referrerId': referrerId});
      } else if (path.startsWith('/orders/')) {
        // Commande: socialbusiness://orders/ORDER_ID
        final orderId = path.replaceFirst('/orders/', '');
        router.go('/order-detail', extra: {'orderId': orderId});
      } else {
        debugPrint('⚠️ Chemin deep link non géré: $path');
        router.go('/');
      }
    } catch (e) {
      debugPrint('❌ Erreur traitement deep link: $e');
    }
  }

  /// Nettoyer les ressources
  void dispose() {
    _subscription?.cancel();
  }
}
```

#### Modification: `lib/main.dart`

**Initialiser le service de deep links**:

```dart
class SocialBusinessProApp extends StatefulWidget {
  const SocialBusinessProApp({super.key});

  @override
  State<SocialBusinessProApp> createState() => _SocialBusinessProAppState();
}

class _SocialBusinessProAppState extends State<SocialBusinessProApp> {
  final DeepLinkService _deepLinkService = DeepLinkService();

  @override
  void dispose() {
    _deepLinkService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ... providers existants ...
      ],
      child: Builder(
        builder: (context) {
          final authProvider = context.watch<AuthProvider>();
          final router = AppRouter.createRouter(authProvider);

          // Initialiser deep links
          _deepLinkService.initDeepLinks(router);

          return MaterialApp.router(
            routerConfig: router,
            // ... reste du code ...
          );
        },
      ),
    );
  }
}
```

---

## 🎨 PRIORITÉ 2 - Cartes Vendeur avec Gradients

### Objectif

Créer des cartes visuellement attractives pour afficher les boutiques vendeur sur la page d'accueil acheteur, inspirées du design SmarterVision.

### Widget: `lib/widgets/vendor_card_gradient.dart` (NOUVEAU)

```dart
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../config/constants.dart';

class VendorCardGradient extends StatelessWidget {
  final UserModel vendor;
  final VoidCallback onTap;
  final List<Color>? gradientColors;

  const VendorCardGradient({
    super.key,
    required this.vendor,
    required this.onTap,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    // Gradients variés pour différencier visuellement les vendeurs
    final gradient = gradientColors ??
        _getGradientByIndex(vendor.id.hashCode % 5);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Motif décoratif (cercles en arrière-plan)
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              bottom: -20,
              left: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),

            // Contenu
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar vendeur
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white,
                        backgroundImage: vendor.photoURL != null
                            ? NetworkImage(vendor.photoURL!)
                            : null,
                        child: vendor.photoURL == null
                            ? Text(
                                vendor.displayName[0].toUpperCase(),
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: gradient.first,
                                ),
                              )
                            : null,
                      ),
                      const Spacer(),
                      // Badge vérifié
                      if (vendor.isVerified)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.verified,
                                color: Colors.white,
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Vérifié',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Nom de la boutique
                  Text(
                    vendor.profile['businessName'] ?? vendor.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Catégorie
                  if (vendor.profile['businessCategory'] != null)
                    Text(
                      vendor.profile['businessCategory'],
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                      ),
                    ),
                  const Spacer(),

                  // Statistiques
                  Row(
                    children: [
                      _StatItem(
                        icon: Icons.star,
                        value: vendor.profile['rating']?.toString() ?? '5.0',
                      ),
                      const SizedBox(width: 16),
                      _StatItem(
                        icon: Icons.shopping_bag,
                        value: '${vendor.profile['totalSales'] ?? 0}',
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _getGradientByIndex(int index) {
    const gradients = [
      [Color(0xFF4CAF50), Color(0xFF81C784)], // Vert
      [Color(0xFFFFB300), Color(0xFFFFD54F)], // Or
      [Color(0xFF29B6F6), Color(0xFF4FC3F7)], // Bleu
      [Color(0xFFAB47BC), Color(0xFFBA68C8)], // Violet
      [Color(0xFFFF7043), Color(0xFFFF8A65)], // Orange
    ];
    return gradients[index];
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;

  const _StatItem({
    required this.icon,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
```

### Modification: `lib/screens/acheteur/acheteur_home.dart`

**Remplacer la section des vendeurs** par:

```dart
// Section Vendeurs Populaires
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const Text(
        'Vendeurs Populaires',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      TextButton(
        onPressed: () {
          // Navigation vers liste complète des vendeurs
          context.go('/vendors');
        },
        child: const Text('Voir tout'),
      ),
    ],
  ),
),
const SizedBox(height: 16),

// Liste horizontale de cartes vendeur
SizedBox(
  height: 180,
  child: ListView.builder(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    itemCount: vendors.length,
    itemBuilder: (context, index) {
      final vendor = vendors[index];
      return Padding(
        padding: const EdgeInsets.only(right: 16),
        child: SizedBox(
          width: 300,
          child: VendorCardGradient(
            vendor: vendor,
            onTap: () {
              context.go('/vendor-shop', extra: {'vendorId': vendor.id});
            },
          ),
        ),
      );
    },
  ),
),
```

---

## 🏷️ PRIORITÉ 3 - Badges/Pills pour Statuts de Commandes

### Widget: `lib/widgets/status_badge.dart` (NOUVEAU)

```dart
import 'package:flutter/material.dart';
import '../config/constants.dart';

enum BadgeStyle {
  filled,   // Fond coloré, texte blanc
  outlined, // Bordure colorée, texte coloré
  soft,     // Fond léger, texte coloré (style moderne)
}

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final BadgeStyle style;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.style = BadgeStyle.soft,
    this.icon,
  });

  /// Factory pour statut de commande
  factory StatusBadge.orderStatus(String status) {
    switch (status) {
      case 'en_attente':
        return StatusBadge(
          label: 'En attente',
          color: AppColors.warning,
          icon: Icons.schedule,
        );
      case 'en_cours':
        return StatusBadge(
          label: 'En cours',
          color: AppColors.info,
          icon: Icons.local_shipping,
        );
      case 'livree':
        return StatusBadge(
          label: 'Livrée',
          color: AppColors.success,
          icon: Icons.check_circle,
        );
      case 'annulee':
        return StatusBadge(
          label: 'Annulée',
          color: AppColors.error,
          icon: Icons.cancel,
        );
      default:
        return StatusBadge(
          label: status,
          color: Colors.grey,
        );
    }
  }

  /// Factory pour statut de livraison
  factory StatusBadge.deliveryStatus(String status) {
    switch (status) {
      case 'available':
        return StatusBadge(
          label: 'Disponible',
          color: AppColors.info,
          icon: Icons.check,
        );
      case 'assigned':
        return StatusBadge(
          label: 'Assignée',
          color: AppColors.warning,
          icon: Icons.person,
        );
      case 'picked_up':
        return StatusBadge(
          label: 'Récupérée',
          color: const Color(0xFF9C27B0), // Violet
          icon: Icons.local_shipping,
        );
      case 'in_transit':
        return StatusBadge(
          label: 'En transit',
          color: AppColors.primary,
          icon: Icons.navigation,
        );
      case 'delivered':
        return StatusBadge(
          label: 'Livrée',
          color: AppColors.success,
          icon: Icons.done_all,
        );
      case 'cancelled':
        return StatusBadge(
          label: 'Annulée',
          color: AppColors.error,
          icon: Icons.cancel,
        );
      default:
        return StatusBadge(
          label: status,
          color: Colors.grey,
        );
    }
  }

  /// Factory pour statut de paiement
  factory StatusBadge.paymentStatus(String status) {
    switch (status) {
      case 'pending':
        return StatusBadge(
          label: 'En attente',
          color: AppColors.warning,
          icon: Icons.schedule,
        );
      case 'paid':
        return StatusBadge(
          label: 'Payé',
          color: AppColors.success,
          icon: Icons.check_circle,
        );
      case 'failed':
        return StatusBadge(
          label: 'Échoué',
          color: AppColors.error,
          icon: Icons.error,
        );
      case 'refunded':
        return StatusBadge(
          label: 'Remboursé',
          color: AppColors.info,
          icon: Icons.refresh,
        );
      default:
        return StatusBadge(
          label: status,
          color: Colors.grey,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        border: style == BadgeStyle.outlined
            ? Border.all(color: color, width: 1.5)
            : null,
        borderRadius: BorderRadius.circular(20), // Pill shape
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 14,
              color: _getTextColor(),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: _getTextColor(),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (style) {
      case BadgeStyle.filled:
        return color;
      case BadgeStyle.outlined:
        return Colors.transparent;
      case BadgeStyle.soft:
        return color.withOpacity(0.15);
    }
  }

  Color _getTextColor() {
    switch (style) {
      case BadgeStyle.filled:
        return Colors.white;
      case BadgeStyle.outlined:
      case BadgeStyle.soft:
        return color;
    }
  }
}
```

### Utilisation dans `order_card.dart` ou `order_detail_screen.dart`

```dart
// Dans la carte de commande
Row(
  children: [
    Text(
      'Commande #${order.id.substring(0, 8)}',
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    ),
    const Spacer(),
    StatusBadge.orderStatus(order.status),
  ],
),

// Pour le statut de paiement
StatusBadge.paymentStatus(order.paymentStatus),

// Pour le statut de livraison
StatusBadge.deliveryStatus(delivery.status),
```

---

## 🔍 PRIORITÉ 4 - Chips pour Filtres de Catégories

### Widget: `lib/widgets/category_filter_chips.dart` (NOUVEAU)

```dart
import 'package:flutter/material.dart';
import '../config/constants.dart';

class CategoryFilterChips extends StatefulWidget {
  final List<String> categories;
  final String? selectedCategory;
  final Function(String?) onCategorySelected;
  final bool showAllOption;

  const CategoryFilterChips({
    super.key,
    required this.categories,
    this.selectedCategory,
    required this.onCategorySelected,
    this.showAllOption = true,
  });

  @override
  State<CategoryFilterChips> createState() => _CategoryFilterChipsState();
}

class _CategoryFilterChipsState extends State<CategoryFilterChips> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // Chip "Tout"
          if (widget.showAllOption)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: const Text('Tout'),
                selected: widget.selectedCategory == null,
                onSelected: (selected) {
                  widget.onCategorySelected(null);
                },
                selectedColor: AppColors.primary,
                backgroundColor: Colors.grey.shade200,
                labelStyle: TextStyle(
                  color: widget.selectedCategory == null
                      ? Colors.white
                      : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),

          // Chips des catégories
          ...widget.categories.map((category) {
            final isSelected = widget.selectedCategory == category;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (selected) {
                  widget.onCategorySelected(selected ? category : null);
                },
                selectedColor: AppColors.primary,
                backgroundColor: Colors.grey.shade200,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                avatar: isSelected
                    ? const Icon(Icons.check, size: 18, color: Colors.white)
                    : null,
              ),
            );
          }),
        ],
      ),
    );
  }
}
```

### Utilisation dans `acheteur_home.dart`

```dart
class _AcheteurHomeScreenState extends State<AcheteurHomeScreen> {
  String? _selectedCategory;

  final List<String> _categories = [
    'Électronique',
    'Mode',
    'Maison',
    'Alimentaire',
    'Beauté',
    'Sports',
    'Livres',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ... AppBar ...

          SliverToBoxAdapter(
            child: Column(
              children: [
                // Barre de recherche
                // ...

                const SizedBox(height: 16),

                // Filtres de catégories
                CategoryFilterChips(
                  categories: _categories,
                  selectedCategory: _selectedCategory,
                  onCategorySelected: (category) {
                    setState(() {
                      _selectedCategory = category;
                    });
                    // Filtrer les produits selon la catégorie
                    _filterProductsByCategory(category);
                  },
                ),

                const SizedBox(height: 24),

                // Grille de produits filtrés
                // ...
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _filterProductsByCategory(String? category) {
    // Logique de filtrage
    debugPrint('Filtrer par catégorie: $category');
    // TODO: Implémenter le filtrage réel
  }
}
```

---

## 📱 PRIORITÉ 5 - Navigation Bottom avec FAB Central

### Modification: `lib/screens/vendeur/vendeur_main_screen.dart`

```dart
class VendeurMainScreen extends StatefulWidget {
  const VendeurMainScreen({super.key});

  @override
  State<VendeurMainScreen> createState() => _VendeurMainScreenState();
}

class _VendeurMainScreenState extends State<VendeurMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const VendeurDashboard(),
    const ProductManagement(),
    const OrderManagement(), // Placeholder pour FAB central
    const MyShopScreen(),
    const VendeurProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),

      // Floating Action Button central
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Action principale: Ajouter un produit
          context.go('/add-product');
        },
        backgroundColor: AppColors.secondary, // Doré
        elevation: 4,
        child: const Icon(Icons.add, size: 32, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // Bottom Navigation Bar avec encoche pour le FAB
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Colors.white,
        elevation: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Gauche du FAB
            _buildNavItem(
              icon: Icons.dashboard,
              label: 'Tableau de bord',
              index: 0,
            ),
            _buildNavItem(
              icon: Icons.inventory,
              label: 'Produits',
              index: 1,
            ),

            // Espace pour le FAB
            const SizedBox(width: 40),

            // Droite du FAB
            _buildNavItem(
              icon: Icons.store,
              label: 'Ma Boutique',
              index: 3,
            ),
            _buildNavItem(
              icon: Icons.person,
              label: 'Profil',
              index: 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;

    return InkWell(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : Colors.grey.shade600,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? AppColors.primary : Colors.grey.shade600,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Version pour Acheteur: `lib/screens/acheteur/acheteur_main_screen.dart`

```dart
// Similaire avec les écrans acheteur
floatingActionButton: FloatingActionButton(
  onPressed: () {
    // Action principale acheteur: Voir le panier
    context.go('/cart');
  },
  backgroundColor: AppColors.secondary,
  child: const Icon(Icons.shopping_cart, size: 28, color: Colors.white),
),
```

---

## 🎬 PRIORITÉ 6 - Écrans Onboarding Illustrés

### Dépendances

```yaml
dependencies:
  smooth_page_indicator: ^1.2.0+3  # Indicateurs de pagination
```

### Fichier: `lib/screens/onboarding/onboarding_screen.dart` (NOUVEAU)

```dart
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../config/constants.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Bienvenue sur SOCIAL BUSINESS Pro',
      description: 'La plateforme e-commerce dédiée aux vendeurs informels de Côte d\'Ivoire',
      imagePath: 'assets/onboarding/welcome.png',
      backgroundColor: AppColors.primary,
    ),
    OnboardingPage(
      title: 'Vendez en toute simplicité',
      description: 'Créez votre boutique en ligne et gérez vos produits facilement depuis vos réseaux sociaux',
      imagePath: 'assets/onboarding/sell.png',
      backgroundColor: AppColors.secondary,
    ),
    OnboardingPage(
      title: 'Livraison GPS en temps réel',
      description: 'Suivez vos commandes en direct avec notre système de tracking GPS',
      imagePath: 'assets/onboarding/delivery.png',
      backgroundColor: AppColors.info,
    ),
    OnboardingPage(
      title: 'Paiement Mobile Money',
      description: 'Payez en toute sécurité avec Orange Money, MTN MoMo, Moov et Wave',
      imagePath: 'assets/onboarding/payment.png',
      backgroundColor: AppColors.success,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Bouton "Passer"
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finishOnboarding,
                child: const Text(
                  'Passer',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),

            // Indicateurs de pagination
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: SmoothPageIndicator(
                controller: _pageController,
                count: _pages.length,
                effect: WormEffect(
                  activeDotColor: AppColors.primary,
                  dotColor: Colors.grey.shade300,
                  dotHeight: 10,
                  dotWidth: 10,
                  spacing: 16,
                ),
              ),
            ),

            // Bouton "Suivant" / "Commencer"
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentPage == _pages.length - 1) {
                      _finishOnboarding();
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _currentPage == _pages.length - 1
                        ? 'Commencer'
                        : 'Suivant',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Container(
      color: page.backgroundColor.withOpacity(0.05),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration
          Image.asset(
            page.imagePath,
            height: 300,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 300,
                width: 300,
                decoration: BoxDecoration(
                  color: page.backgroundColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.image,
                  size: 100,
                  color: page.backgroundColor.withOpacity(0.3),
                ),
              );
            },
          ),
          const SizedBox(height: 48),

          // Titre
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              page.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: page.backgroundColor,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              page.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _finishOnboarding() async {
    // Marquer l'onboarding comme terminé
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    if (mounted) {
      context.go('/login');
    }
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final String imagePath;
  final Color backgroundColor;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.backgroundColor,
  });
}
```

### Modification: `lib/routes/app_router.dart`

**Ajouter la route onboarding** et la logique de redirection:

```dart
GoRoute(
  path: '/onboarding',
  builder: (context, state) => const OnboardingScreen(),
),

// Modifier la route '/' pour vérifier l'onboarding
redirect: (context, state) async {
  final prefs = await SharedPreferences.getInstance();
  final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

  if (!onboardingCompleted && state.matchedLocation == '/') {
    return '/onboarding';
  }
  return null;
},
```

---

## 📊 Récapitulatif et Prochaines Étapes

### Priorités d'Implémentation

1. ✅ **Connexion Réseaux Sociaux** (CRITIQUE) - Semaine 1
   - Social login (Google, Facebook)
   - Partage produits/boutiques
   - Deep linking

2. ✅ **Amélioration UI** - Semaine 2
   - Cartes vendeur avec gradients
   - Badges de statut modernes
   - Chips de filtrage
   - Bottom nav avec FAB

3. ✅ **Onboarding** - Semaine 3
   - Écrans illustrés
   - Indicateurs de pagination

### Assets à Créer

**Dossier `assets/icons/`**:
- `google_icon.png` (512x512)
- `facebook_icon.png` (512x512)
- `apple_icon.png` (512x512)

**Dossier `assets/onboarding/`**:
- `welcome.png` (illustration accueil)
- `sell.png` (illustration vente)
- `delivery.png` (illustration livraison GPS)
- `payment.png` (illustration paiement mobile money)

**Sources d'illustrations**:
- **unDraw**: https://undraw.co/illustrations (gratuit, personnalisable)
- **Storyset**: https://storyset.com/ (gratuit, modifiable)
- **Freepik**: https://www.freepik.com/ (gratuit avec attribution)

### Configuration Firebase Requise

1. **Console Firebase** → Authentication:
   - Activer Google
   - Activer Facebook (App ID + Secret requis)
   - Activer Apple (iOS uniquement)

2. **Facebook Developer**:
   - Créer une app: https://developers.facebook.com/apps
   - OAuth Redirect URI: `https://socialbusinesspro.firebaseapp.com/__/auth/handler`

3. **Firebase Dynamic Links** (pour deep linking):
   - Créer un domaine: `socialbusinesspro.page.link`
   - Configurer redirections

### Tests Requis

**Tests Fonctionnels**:
- [ ] Connexion Google fonctionne
- [ ] Connexion Facebook fonctionne
- [ ] Partage produit sur WhatsApp
- [ ] Partage boutique sur Facebook
- [ ] Deep link ouvre le bon produit
- [ ] Badges affichent les bonnes couleurs
- [ ] Filtres de catégories fonctionnent
- [ ] FAB central navigue correctement
- [ ] Onboarding s'affiche au premier lancement

**Tests de Sécurité**:
- [ ] Tokens Firebase valides
- [ ] Permissions Facebook correctes
- [ ] Deep links validés (pas de phishing)

### Documentation Utilisateur

**Guide Vendeur** (à créer):
- Comment partager sa boutique sur les réseaux sociaux
- Comment utiliser le lien de parrainage
- Comment contacter les clients via WhatsApp

**FAQ** (à ajouter):
- Pourquoi connecter mes réseaux sociaux ?
- Est-ce que mes données Facebook sont sécurisées ?
- Comment déconnecter mon compte Google ?

---

## 📄 Fichiers Modifiés

### Nouveaux Fichiers

1. `lib/services/social_auth_service.dart`
2. `lib/services/social_share_service.dart`
3. `lib/services/deep_link_service.dart`
4. `lib/widgets/social_login_buttons.dart`
5. `lib/widgets/social_share_button.dart`
6. `lib/widgets/vendor_card_gradient.dart`
7. `lib/widgets/status_badge.dart`
8. `lib/widgets/category_filter_chips.dart`
9. `lib/screens/onboarding/onboarding_screen.dart`

### Fichiers à Modifier

1. `pubspec.yaml` - Ajouter dépendances
2. `android/app/src/main/AndroidManifest.xml` - Configuration Facebook + Deep links
3. `android/app/src/main/res/values/strings.xml` - Facebook App ID
4. `ios/Runner/Info.plist` - Deep links iOS
5. `lib/screens/auth/login_screen.dart` - Boutons social login
6. `lib/screens/auth/register_screen.dart` - Boutons social login
7. `lib/providers/auth_provider_firebase.dart` - Logique social auth
8. `lib/screens/acheteur/acheteur_home.dart` - Cartes vendeur + chips
9. `lib/screens/vendeur/vendeur_main_screen.dart` - Bottom nav avec FAB
10. `lib/screens/acheteur/acheteur_main_screen.dart` - Bottom nav avec FAB
11. `lib/routes/app_router.dart` - Routes onboarding + deep links
12. `lib/main.dart` - Initialisation deep links

---

## ⚠️ Points d'Attention

### Licences et Droits

- ✅ **flex_color_scheme**: MIT License (OK commercial)
- ✅ **google_sign_in**: BSD License (OK commercial)
- ✅ **flutter_facebook_auth**: MIT License (OK commercial)
- ✅ **share_plus**: BSD License (OK commercial)

### Respect des Guidelines

**Google Sign-In**:
- Utiliser les boutons officiels Google (design guidelines)
- Ne pas modifier les logos

**Facebook Login**:
- Respecter la charte graphique Facebook
- Demander uniquement permissions nécessaires (email, public_profile)
- Privacy Policy requise

**Deep Links**:
- Valider les domaines (Android App Links verification)
- Gérer les cas d'erreur (lien invalide)

### Performance

- **Images onboarding**: Compresser (< 200KB chacune)
- **Gradients**: Utiliser `CachedNetworkImage` pour photos vendeur
- **Deep links**: Timeout de 5s pour éviter blocage app

---

## 📞 Support et Ressources

**Documentation Officielle**:
- [FlexColorScheme](https://docs.flexcolorscheme.com/)
- [Google Sign-In Flutter](https://pub.dev/packages/google_sign_in)
- [Facebook Auth Flutter](https://pub.dev/packages/flutter_facebook_auth)
- [Firebase Dynamic Links](https://firebase.google.com/docs/dynamic-links)

**Outils de Test**:
- [Facebook Debug Tool](https://developers.facebook.com/tools/debug/) - Tester partages
- [Android Deep Link Validator](https://developer.android.com/training/app-links/verify-android-applinks)

---

**Date de dernière mise à jour**: 26 décembre 2025
**Version du document**: 1.0
**Auteur**: Claude Code Assistant
