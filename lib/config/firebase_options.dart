// ===== lib/config/firebase_options.dart =====
// Configuration Firebase pour SOCIAL BUSINESS Pro

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Configuration Firebase par défaut pour SOCIAL BUSINESS Pro
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Configuration Web (pour les tests sur Chrome)
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyA-rTjMA0ZsE1n9nOeGlxq3swmbkrtg49o",
    authDomain: "social-media-business-pro.firebaseapp.com",
    projectId: "social-business-pro",
    storageBucket: "social-business-pro.firebasestorage.app",
    messagingSenderId: "162267219364",
    appId: "1:162267219364:web:58b3606f6c55669043ad31",
    measurementId: "G-ZTVBD3X1RE"
  );

  // Configuration Android
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyANfaX2lTV0TgVuaxFzZrE5-B-UV1tPKm4',
    appId: '1:162267219364:android:6d52b4bb8143dafc43ad31',
    messagingSenderId: '162267219364',
    projectId: 'social-media-business-pro',
    storageBucket: 'social-media-business-pro.firebasestorage.app',
  );

  // Configuration iOS
  // TODO: Créer l'app iOS dans Firebase Console et remplacer ces valeurs
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA-rTjMA0ZsE1n9nOeGlxq3swmbkrtg49o', // Temporaire: même que Web
    appId: '1:162267219364:ios:XXXXXX', // TODO: Remplacer après création app iOS
    messagingSenderId: '162267219364',
    projectId: 'social-media-business-pro',
    storageBucket: 'social-media-business-pro.firebasestorage.app',
    iosBundleId: 'ci.socialbusinesspro.socialMediaBusinessPro',
  );

  // Configuration macOS (utilise la même config qu'iOS)
  // TODO: Créer l'app macOS dans Firebase Console si nécessaire
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyA-rTjMA0ZsE1n9nOeGlxq3swmbkrtg49o', // Temporaire: même que Web
    appId: '1:162267219364:ios:XXXXXX', // TODO: Même app ID qu'iOS ou créer app macOS
    messagingSenderId: '162267219364',
    projectId: 'social-media-business-pro',
    storageBucket: 'social-media-business-pro.firebasestorage.app',
    iosBundleId: 'ci.socialbusinesspro.socialMediaBusinessPro',
  );

  // Configuration Windows (utilise la config Web pour développement)
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyA-rTjMA0ZsE1n9nOeGlxq3swmbkrtg49o',
    appId: '1:162267219364:web:58b3606f6c55669043ad31',
    messagingSenderId: '162267219364',
    projectId: 'social-media-business-pro',
    authDomain: 'social-media-business-pro.firebaseapp.com',
    storageBucket: 'social-media-business-pro.firebasestorage.app',
    measurementId: 'G-ZTVBD3X1RE',
  );
}

// ===== INSTRUCTIONS POUR CONFIGURER FIREBASE =====

/*
🔥 COMMENT CONFIGURER FIREBASE POUR VOTRE PROJET :

1. **Créer un projet Firebase :**
   - Allez sur https://console.firebase.google.com
   - Cliquez "Ajouter un projet"
   - Nom : "social-business-pro-ci" (ou votre choix)
   - Activez Google Analytics si souhaité

2. **Ajouter une app Web :**
   - Dans le projet → Paramètres → Général
   - Cliquez "Ajouter une app" → Web
   - Nom : "SOCIAL BUSINESS Pro Web"
   - Cochez "Configurer Firebase Hosting" (optionnel)
   - Copiez la configuration qui s'affiche

3. **Remplacer les valeurs ci-dessus :**
   - Remplacez les valeurs dans `web` par vos vraies valeurs Firebase
   - Gardez le même format

4. **Activer Authentication :**
   - Dans Firebase Console → Authentication
   - Onglet "Sign-in method"
   - Activez "Email/Password"
   - Optionnel : Activez aussi Google, Facebook, etc.

5. **Activer Firestore :**
   - Dans Firebase Console → Firestore Database
   - Créer une base de données
   - Mode test pour commencer (rules publiques)

6. **Activer Storage :**
   - Dans Firebase Console → Storage
   - Commencer en mode test

EXEMPLE DE VRAIE CONFIGURATION :
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'AIzaSyBXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX',
  appId: '1:987654321:web:abcdef123456789abcdef',
  messagingSenderId: '987654321',
  projectId: 'social-business-pro-2024',
  authDomain: 'social-business-pro-2024.firebaseapp.com',
  storageBucket: 'social-business-pro-2024.appspot.com',
);
*/