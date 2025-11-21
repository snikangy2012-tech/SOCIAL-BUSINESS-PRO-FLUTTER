// ===== lib/services/auth_service_web.dart =====
// Service d'authentification pour le Web avec Firebase Auth et Firestore


import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async'; // ✅ AJOUTER pour TimeoutException
import 'package:flutter/foundation.dart';

import '../config/user_type_config.dart';
import 'package:social_business_pro/config/constants.dart';
import 'subscription_service.dart';
import 'firestore_sync_service.dart';

class AuthServiceWeb {
  static final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  /// Inscription RAPIDE sur Web (Auth seulement)
  static Future<Map<String, dynamic>> registerWeb({
    required String username,
    required String email,
    required String password,
    String userType = 'acheteur', // ✅ Paramètre ajouté
  }) async {
    try {
      debugPrint('🚀 Inscription Web: $username (Type: $userType)');

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw Exception('Échec création compte');
      }

      await credential.user!.updateDisplayName(username);

      final userId = credential.user!.uid;

      // ✅ Stocker le userType dans la config locale (fallback immédiat)
      UserTypeConfig.emailToUserType[email.toLowerCase()] = userType;

      // ✅ Créer document Firestore EN ARRIÈRE-PLAN (non bloquant)
      FirestoreSyncService.createUserDocumentAsync(
        uid: userId,
        email: email,
        displayName: username,
        phoneNumber: '',
        userType: userType,
      );
      debugPrint('📤 Création document Firestore lancée en arrière-plan');

      // ✅ Créer l'abonnement par défaut selon le type d'utilisateur
      try {
        final subscriptionService = SubscriptionService();

        if (userType == UserType.vendeur.value || userType == 'vendeur') {
          // Créer abonnement BASIQUE pour vendeur
          debugPrint('📦 Création abonnement BASIQUE par défaut pour vendeur...');
          await subscriptionService.createDefaultVendeurSubscription(userId);
          debugPrint('✅ Abonnement BASIQUE créé');
        } else if (userType == UserType.livreur.value || userType == 'livreur') {
          // Créer abonnement STARTER pour livreur
          debugPrint('🚴 Création abonnement STARTER par défaut pour livreur...');
          await subscriptionService.createStarterLivreurSubscription(userId);
          debugPrint('✅ Abonnement STARTER créé');
        }
      } catch (e) {
        // Ne pas bloquer l'inscription si la création d'abonnement échoue
        debugPrint('⚠️ Erreur création abonnement par défaut: $e');
        debugPrint('   (L\'utilisateur pourra créer son abonnement plus tard)');
      }

      debugPrint('✅ Inscription Web réussie - Type: $userType enregistré');

      return {
        'success': true,
        'user': {
          'uid': userId,
          'email': email,
          'displayName': username,
          'userType': userType, // ✅ Type correct
        },
      };
    } catch (e) {
      debugPrint('❌ Erreur inscription Web: $e');
      
      if (e.toString().contains('email-already-in-use')) {
        return {
          'success': false,
          'message': 'Cette adresse email est déjà utilisée',
        };
      }
      
      return {
        'success': false,
        'message': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }

  /// Connexion RAPIDE sur Web
  static Future<Map<String, dynamic>> loginWeb({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('🔐 === CONNEXION WEB === : $email');
      
      if (!email.contains('@')) {
        return {
          'success': false,
          'message': 'Veuillez utiliser votre adresse email',
        };
      }
      
      // 1. Connexion Firebase Auth
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw Exception('Échec connexion');
      }

      final uid = credential.user!.uid;
      final userEmail = credential.user!.email;
      debugPrint('✅ Auth réussie - UID: $uid');

      // 2. ✅ LECTURE FIRESTORE SANS TIMEOUT (Web est lent mais fonctionne)
      String userType = 'acheteur';
      String? displayName;
      String? phoneNumber;
      Map<String, dynamic>? userData;

      try {
        debugPrint('🔍 Lecture Firestore avec stratégie serveur → cache...');

        DocumentSnapshot<Map<String, dynamic>>? userDoc;

        // ✅ Laisser Firestore gérer automatiquement (serveur puis cache)
        try {
          debugPrint('   📡 Lecture Firestore automatique (serveur → cache)...');

          userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .get() // Sans GetOptions = Firestore essaie serveur puis cache automatiquement
              .timeout(
                const Duration(seconds: 30),
                onTimeout: () => throw TimeoutException('Timeout lecture'),
              );

          if (userDoc.exists) {
            debugPrint('   ✅ Document trouvé');
          } else {
            debugPrint('   ⚠️ Document n\'existe pas');
          }
        } catch (readError) {
          debugPrint('   ❌ Échec lecture: $readError');
          // userDoc reste null
        }

        if (userDoc != null && userDoc.exists) {
          userData = userDoc.data();
          userType = userData?['userType'] ?? 'acheteur';
          displayName = userData?['displayName'] ?? userData?['name'];
          phoneNumber = userData?['phoneNumber'] ?? userData?['phone'];

          debugPrint('✅ Document trouvé (serveur ou cache)');

          // ✅ DÉTECTION ADMIN PAR EMAIL
          if (userEmail != null &&
              (userEmail.contains('admin@') ||
               userEmail == 'admin@socialbusiness.ci')) {
            debugPrint('🔑 Admin détecté par email: $userEmail');
            userType = 'admin';

            // Mettre à jour dans Firestore si nécessaire (avec timeout court)
            if (userData?['userType'] != 'admin') {
              debugPrint('📝 Mise à jour du type admin dans Firestore...');
              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .update({'userType': 'admin'})
                    .timeout(
                      const Duration(seconds: 5),
                      onTimeout: () {
                        debugPrint('⚠️ Timeout mise à jour (pas grave, sera fait plus tard)');
                        return; // Retourner void
                      },
                    );
                debugPrint('✅ Type admin mis à jour');
              } catch (e) {
                debugPrint('⚠️ Échec mise à jour: $e');
              }
            }
          }

          debugPrint('✅ Firestore OK');
          debugPrint('   📋 UserType: $userType');
          debugPrint('   👤 DisplayName: $displayName');
          debugPrint('   📧 Email: $userEmail');
          debugPrint('   📱 Phone: $phoneNumber');
        } else {
          // ❌ Document absent du serveur ET du cache
          debugPrint('⚠️ Document utilisateur introuvable (serveur + cache)');

          // ✅ Utiliser configuration locale basée sur l'email
          userType = UserTypeConfig.getUserTypeFromEmail(userEmail);
          displayName = credential.user!.displayName ?? 'Utilisateur';
          phoneNumber = credential.user!.phoneNumber ?? '';

          debugPrint('⚠️ Utilisation configuration locale basée sur email');
          debugPrint('   📧 Email: $userEmail');
          debugPrint('   👤 DisplayName: $displayName');
          debugPrint('   🔑 UserType détecté: $userType');
        }
      } catch (e) {
        debugPrint('❌ Erreur lecture Firestore: $e');

        // ✅ Utiliser configuration locale basée sur l'email
        userType = UserTypeConfig.getUserTypeFromEmail(userEmail);
        displayName = credential.user!.displayName ?? 'Utilisateur';
        phoneNumber = credential.user!.phoneNumber ?? '';

        debugPrint('⚠️ Fallback: Configuration locale basée sur email');
        debugPrint('   🔑 UserType détecté: $userType');
      }

      debugPrint('🎯 === CONNEXION TERMINÉE === UserType: $userType\n');

      return {
        'success': true,
        'user': {
          'uid': uid,
          'email': userEmail,
          'displayName': displayName ?? credential.user!.displayName ?? 'Utilisateur',
          'userType': userType, // ✅ UserType correct
        },
      };
      
    } catch (e) {
      debugPrint('❌ Erreur connexion: $e');
      
      if (e.toString().contains('invalid-credential') || 
          e.toString().contains('wrong-password')) {
        return {
          'success': false,
          'message': 'Email ou mot de passe incorrect',
        };
      }
      
      return {
        'success': false,
        'message': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }
  
  /// Déconnexion
  static Future<void> logoutWeb() async {
    await _auth.signOut();
    debugPrint('🔓 Déconnexion Web réussie');
  }
}