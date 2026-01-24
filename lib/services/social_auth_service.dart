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
