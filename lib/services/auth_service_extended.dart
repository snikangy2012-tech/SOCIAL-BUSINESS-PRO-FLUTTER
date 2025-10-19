// ===== lib/services/auth_service_extended.dart =====
// Service d'authentification étendu avec OTP et Google

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_service.dart';
import '../config/constants.dart';

class AuthServiceExtended {
  static final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  // Variables pour OTP
  static firebase_auth.ConfirmationResult? _confirmationResult;
  static String? _verificationId;

  // ===== AUTHENTIFICATION EMAIL/PASSWORD (existant) =====
  
  // ✅ AJOUTER cette méthode simple et directe
  static Future<Map<String, dynamic>> registerWithEmailDirect({
    required String username,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
    required String verificationType,
    required UserType userType,
  }) async {
    firebase_auth.UserCredential? credential;
    
    try {
      debugPrint('🚀 Inscription directe: $username');
      
      // 1. Créer compte Auth
      credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw Exception('Échec création compte');
      }

      // 2. Mettre à jour profil
      await credential.user!.updateDisplayName(username);
      
      // 3. Sauvegarder DIRECTEMENT dans Firestore (SIMPLE)
      debugPrint('📝 Sauvegarde Firestore...');
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({
        'uid': credential.user!.uid,
        'email': email,
        'displayName': username,
        'phoneNumber': phone,
        'userType': userType.name,
        'isVerified': false,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      }, SetOptions(merge: true)); // ✅ Merge pour éviter les conflits

        if (kIsWeb) {
        // ✅ SUR WEB : Pas de timeout, attente infinie
        await FirebaseFirestore.instance
            .collection('users')
            .doc(credential.user!.uid)
            .set({
              'uid': credential.user!.uid,
              'email': email,
              'displayName': username,
              'phoneNumber': phone,
              'userType': userType.name,
              'isVerified': false,
              'createdAt': Timestamp.now(),
              'updatedAt': Timestamp.now(),
              }, SetOptions(merge: true));
      } else {
        // Mobile avec timeout
        await FirebaseFirestore.instance
            .collection('users')
            .doc(credential.user!.uid)
            .set({
              'uid': credential.user!.uid,
              'email': email,
              'displayName': username,
              'phoneNumber': phone,
              'userType': userType.name,
              'isVerified': false,
              'createdAt': Timestamp.now(),
              'updatedAt': Timestamp.now(),
            }, SetOptions(merge: true))
            .timeout(
              const Duration(seconds: 5),
              onTimeout: () {
              // Créer un document vide si timeout
              return FirebaseFirestore.instance
                  .collection('users')
                  .doc(credential!.user!.uid)
                  .get()
                  .then((value) => value);
              },
            );
      }

      debugPrint('✅ Inscription directe réussie');

      return {
        'success': true,
        'user': credential.user,
        'message': 'Compte créé avec succès',
      };

    } catch (e) {
      debugPrint('❌ Erreur inscription directe: $e');

      // Rollback si nécessaire
      if (credential?.user != null) {
        try {
          await credential!.user!.delete();
        } catch (deleteError) {
          debugPrint('⚠️ Erreur rollback: $deleteError');
        }
      }

      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> registerWithEmail({
    required String username,
    required String email,
    required String phone,
    required String password,
    required UserType userType,
    required String confirmPassword,
    required String verificationType,
  }) async {
    try {
      final user = await FirebaseService.registerWithEmail(
        username: username,
        email: email,
        phone: phone,
        password: password,
        userType: userType,
      );

      if (user != null) {
        // Envoyer OTP de vérification par email
        await sendEmailVerification();
        
        return {
          'success': true,
          'user': user,
          'requiresVerification': true,
          'message': 'Compte créé ! Vérifiez votre email pour activer votre compte.',
        };
      }
      
      return {'success': false, 'message': 'Échec de la création du compte'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> signInWithIdentifier({
    required String identifier,
    required String password,
  }) async {
    try {
      final user = await FirebaseService.signInWithIdentifier(
        identifier: identifier,
        password: password,
      );

      if (user != null) {
        // Vérifier si l'email est vérifié
        final currentUser = _auth.currentUser;
        if (currentUser != null && !currentUser.emailVerified) {
          return {
            'success': false,
            'requiresVerification': true,
            'message': 'Email non vérifié. Vérifiez votre boîte email.',
          };
        }

        // ✅ Vérifier et créer le document Firestore si nécessaire
        if (currentUser != null) {
          await _ensureFirestoreDocument(currentUser);
        }

        return {'success': true, 'user': user};
      }

      return {'success': false, 'message': 'Identifiants incorrects'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ✅ Nouvelle méthode pour s'assurer que le document Firestore existe
  static Future<void> _ensureFirestoreDocument(firebase_auth.User firebaseUser) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (!userDoc.exists) {
        debugPrint('📝 Création du document Firestore manquant pour ${firebaseUser.uid}');

        await FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .set({
          'uid': firebaseUser.uid,
          'email': firebaseUser.email ?? '',
          'displayName': firebaseUser.displayName ?? 'Utilisateur',
          'name': firebaseUser.displayName ?? 'Utilisateur',
          'phoneNumber': firebaseUser.phoneNumber ?? '',
          'phone': firebaseUser.phoneNumber ?? '',
          'userType': 'acheteur',
          'isVerified': firebaseUser.emailVerified,
          'isActive': true,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
          'profile': {
            'deliveryPreferences': {
              'defaultAddress': null,
              'preferredDeliveryTime': 'anytime',
            },
            'favoriteCategories': [],
            'totalOrders': 0,
            'totalSpent': 0.0,
          },
          'preferences': {
            'theme': 'light',
            'language': 'fr',
            'emailNotifications': true,
            'pushNotifications': true,
            'smsNotifications': false,
            'marketingEmails': false,
            'currency': 'XOF',
          },
        });

        debugPrint('✅ Document Firestore créé avec succès');
      }
    } catch (e) {
      debugPrint('⚠️ Erreur lors de la vérification/création du document: $e');
    }
  }

  // ===== VÉRIFICATION EMAIL =====

  static Future<bool> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Erreur envoi email de vérification: $e');
      return false;
    }
  }

  static Future<bool> checkEmailVerified() async {
    try {
      await _auth.currentUser?.reload();
      return _auth.currentUser?.emailVerified ?? false;
    } catch (e) {
      debugPrint('Erreur vérification email: $e');
      return false;
    }
  }

  // ===== AUTHENTIFICATION PAR TÉLÉPHONE (OTP SMS) =====

  static Future<Map<String, dynamic>> sendPhoneOTP(String phoneNumber) async {
    try {
      // Format international pour la Côte d'Ivoire
      String formattedPhone = phoneNumber;
      if (!phoneNumber.startsWith('+')) {
        // Convertir les numéros ivoiriens
        if (phoneNumber.startsWith('0')) {
          formattedPhone = '+225${phoneNumber.substring(1)}';
        } else if (phoneNumber.length == 10) {
          formattedPhone = '+225$phoneNumber';
        } else {
          formattedPhone = '+225$phoneNumber';
        }
      }

      debugPrint('📱 Envoi OTP vers: $formattedPhone');

      if (kIsWeb) {
        // Pour le web, utiliser RecaptchaVerifier
        final confirmationResult = await _auth.signInWithPhoneNumber(formattedPhone);
        _confirmationResult = confirmationResult;
        
        return {
          'success': true,
          'message': 'Code OTP envoyé par SMS à $formattedPhone',
          'verificationId': 'web_confirmation',
        };
      } else {
        // Pour mobile
        await _auth.verifyPhoneNumber(
          phoneNumber: formattedPhone,
          verificationCompleted: (firebase_auth.PhoneAuthCredential credential) async {
            // Auto-vérification (Android uniquement)
            await _auth.signInWithCredential(credential);
          },
          verificationFailed: (firebase_auth.FirebaseAuthException e) {
            debugPrint('❌ Échec vérification: ${e.message}');
          },
          codeSent: (String verificationId, int? resendToken) {
            _verificationId = verificationId;
            debugPrint('✅ Code envoyé, ID: $verificationId');
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            _verificationId = verificationId;
          },
        );

        return {
          'success': true,
          'message': 'Code OTP envoyé par SMS à $formattedPhone',
          'verificationId': _verificationId,
        };
      }
    } catch (e) {
      debugPrint('❌ Erreur envoi OTP: $e');
      return {
        'success': false,
        'message': 'Erreur lors de l\'envoi du code: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> verifyPhoneOTP({
    required String otpCode,
    required String name,
    required UserType userType,
  }) async {
    try {
      firebase_auth.PhoneAuthCredential credential;

      if (kIsWeb && _confirmationResult != null) {
        // Vérification web
        final userCredential = await _confirmationResult!.confirm(otpCode);
        if (userCredential.user != null) {
          return await _handlePhoneAuthSuccess(
            userCredential.user!,
            name,
            userType,
          );
        }
      } else if (_verificationId != null) {
        // Vérification mobile
        credential = firebase_auth.PhoneAuthProvider.credential(
          verificationId: _verificationId!,
          smsCode: otpCode,
        );

        final userCredential = await _auth.signInWithCredential(credential);
        if (userCredential.user != null) {
          return await _handlePhoneAuthSuccess(
            userCredential.user!,
            name,
            userType,
          );
        }
      }

      return {'success': false, 'message': 'Code OTP invalide'};
    } catch (e) {
      debugPrint('❌ Erreur vérification OTP: $e');
      return {
        'success': false,
        'message': 'Code OTP invalide ou expiré',
      };
    }
  }

  // ===== AUTHENTIFICATION GOOGLE =====

  static Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      
      debugPrint('🔍 Tentative connexion Google...');

      if (kIsWeb) {
        // ✅ Configuration spéciale Web
        final GoogleSignInAccount? googleUser = await _googleSignIn.signInSilently();
        if (googleUser == null) {
          // Fallback si signInSilently échoue
          return {'success': false, 'message': 'Utilisez signInSilently sur Web'};
        }
      } else {


      // Déclencher le flux d'authentification
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        return {'success': false, 'message': 'Connexion Google annulée'};
      }

      debugPrint('✅ Utilisateur Google sélectionné: ${googleUser.email}');

      // Obtenir les détails d'authentification
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Créer les credentials Firebase
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Connexion Firebase avec Google
      final userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        final user = userCredential.user!;

        // Vérifier si c'est un nouvel utilisateur
        final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

        // ✅ Toujours s'assurer que le document Firestore existe
        await _ensureFirestoreDocument(user);

        if (isNewUser) {
          debugPrint('🆕 Nouvel utilisateur Google détecté');
          // Le document a déjà été créé par _ensureFirestoreDocument
        }

        // Retourner l'utilisateur local
        final localUser = await FirebaseService.getDocument(
          collection: FirebaseCollections.users,
          docId: user.uid,
        );

        return {
          'success': true,
          'user': _createLocalUser(user.uid, localUser ?? {}),
          'isNewUser': isNewUser,
        };
      }

      return {'success': false, 'message': 'Échec de la connexion Google'};
      }
    } 
    catch (e) {
      debugPrint('❌ Erreur Google Sign-In: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion Google: ${e.toString()}',
      };
    }
    return {'success': false, 'message': 'Erreur inconnue'};
  }

  // ===== MÉTHODES HELPER PRIVÉES =====

  static Future<Map<String, dynamic>> _handlePhoneAuthSuccess(
    firebase_auth.User firebaseUser,
    String name,
    UserType userType,
  ) async {
    try {
      // Vérifier si l'utilisateur existe déjà
      final existingUser = await FirebaseService.getDocument(
        collection: FirebaseCollections.users,
        docId: firebaseUser.uid,
      );

      if (existingUser == null) {
        // Nouveau utilisateur - créer le profil
        await FirebaseService.setDocument(
          collection: FirebaseCollections.users,
          docId: firebaseUser.uid,
          data: {
            'name': name,
            'email': firebaseUser.email ?? '',
            'phone': firebaseUser.phoneNumber ?? '',
            'userType': userType.value,
            'isVerified': true, // Téléphone vérifié
            'authProvider': 'phone',
            'createdAt': DateTime.now(),
            'updatedAt': DateTime.now(),
            'profile': _getDefaultProfile(userType),
          },
        );
      }

      final userData = await FirebaseService.getDocument(
        collection: FirebaseCollections.users,
        docId: firebaseUser.uid,
      );

      return {
        'success': true,
        'user': _createLocalUser(firebaseUser.uid, userData ?? {}),
        'message': 'Connexion réussie !',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static dynamic _createLocalUser(String uid, Map<String, dynamic> data) {
    return {
      'id': uid,
      'name': data['name'] ?? 'Utilisateur',
      'email': data['email'] ?? '',
      'phone': data['phone'] ?? '',
      'userType': UserType.values.firstWhere(
        (type) => type.value == data['userType'],
        orElse: () => UserType.acheteur,
      ),
      'createdAt': data['createdAt']?.toDate() ?? DateTime.now(),
    };
  }

  static Map<String, dynamic> _getDefaultProfile(UserType userType) {
    // Même logique que dans FirebaseService
    switch (userType) {
      case UserType.vendeur:
        return {
          'businessName': '',
          'businessDescription': '',
          'businessType': 'individual',
          'rating': {'average': 0.0, 'count': 0},
          'totalSales': 0,
          'isVerified': false,
        };
      case UserType.acheteur:
        return {
          'favoriteCategories': [],
          'totalOrders': 0,
          'totalSpent': 0,
        };
      case UserType.livreur:
        return {
          'vehicleType': '',
          'isAvailable': true,
          'rating': {'average': 0.0, 'count': 0},
          'totalDeliveries': 0,
          'isVerified': false,
        };
      case UserType.admin:
        return {
          'role': 'admin',
          'permissions': ['all'],
        };
    }
  }

  // ===== MÉTHODES UTILITAIRES =====

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  static firebase_auth.User? get currentUser => _auth.currentUser;
}