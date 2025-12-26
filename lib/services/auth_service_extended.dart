// ===== lib/services/auth_service_extended.dart =====
// Service d'authentification étendu avec OTP et Google

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_service.dart';
import 'notification_service.dart';
import 'kyc_adaptive_service.dart';
import 'package:social_business_pro/config/constants.dart';

class AuthServiceExtended {
  static final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  // Variables pour OTP
  static firebase_auth.ConfirmationResult? _confirmationResult;
  static String? _verificationId;
  static int? _resendToken;

  // Stream pour notifier l'UI des événements OTP
  static final StreamController<Map<String, dynamic>> _otpStatusController =
      StreamController<Map<String, dynamic>>.broadcast();

  static Stream<Map<String, dynamic>> get otpStatusStream => _otpStatusController.stream;

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

      final userData = {
        'uid': credential.user!.uid,
        'email': email,
        'displayName': username,
        'phoneNumber': phone,
        'userType': userType.name,
        'isActive': true, // Actif par défaut
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      };

      if (kIsWeb) {
        // ✅ SUR WEB : Pas de timeout, attente infinie
        await FirebaseFirestore.instance
            .collection('users')
            .doc(credential.user!.uid)
            .set(userData, SetOptions(merge: true));
      } else {
        // Mobile avec timeout
        await FirebaseFirestore.instance
            .collection('users')
            .doc(credential.user!.uid)
            .set(userData, SetOptions(merge: true))
            .timeout(
              const Duration(seconds: 5),
              onTimeout: () {
                debugPrint('⚠️ Timeout sauvegarde Firestore (pas grave)');
                return Future.value();
              },
            );
      }

      debugPrint('✅ Inscription directe réussie');

      // 4. ✨ NOUVEAU: Évaluation risque adaptative (non-bloquante)
      UserRiskAssessment? riskAssessment;

      if (userType == UserType.vendeur || userType == UserType.livreur) {
        try {
          debugPrint('🔍 Évaluation risque pour ${credential.user!.uid}...');

          riskAssessment = await KYCAdaptiveService.assessUserRisk(
            userId: credential.user!.uid,
            phoneNumber: phone,
            email: email,
          );

          debugPrint('✅ Risque évalué: ${riskAssessment.tier.displayName} (Score: ${riskAssessment.riskScore}/100)');

          // SEUL CAS BLOQUANT: Blacklisté avéré
          if (riskAssessment.tier == RiskTier.blacklisted) {
            debugPrint('🛑 Utilisateur blacklisté détecté - Blocage inscription');

            // Supprimer le compte créé
            await credential.user!.delete();

            // Supprimer le document Firestore
            await FirebaseFirestore.instance
                .collection('users')
                .doc(credential.user!.uid)
                .delete();

            return {
              'success': false,
              'message': 'Votre inscription ne peut être traitée. '
                  'Pour plus d\'informations, contactez notre support : '
                  'support@socialbusiness.ci ou WhatsApp +225 XX XX XX XX',
            };
          }

          // ✅ Tous les autres cas : Accès accordé avec limites adaptées
          debugPrint('✅ Accès accordé - Tier: ${riskAssessment.tier.name}');

        } catch (e) {
          debugPrint('⚠️ Erreur évaluation risque (non-bloquant): $e');
          // En cas d'erreur, on laisse passer (mode sécurisé appliqué par défaut)
        }
      }

      // 5. Notifier les admins pour vendeurs et livreurs
      if (userType == UserType.vendeur || userType == UserType.livreur) {
        try {
          await NotificationService.notifyAllAdmins(
            type: 'user_registration',
            title: 'Nouvel utilisateur ${userType.label}',
            body: '$username vient de s\'inscrire et attend validation',
            data: {
              'userId': credential.user!.uid,
              'userType': userType.name,
              'userName': username,
              'userEmail': email,
              if (riskAssessment != null) 'riskTier': riskAssessment.tier.name,
              if (riskAssessment != null) 'riskScore': riskAssessment.riskScore.toString(),
            },
          );
          debugPrint('✅ Admins notifiés de la nouvelle inscription');
        } catch (e) {
          debugPrint('⚠️ Erreur notification admins: $e');
          // Ne pas bloquer l'inscription si la notification échoue
        }
      }

      return {
        'success': true,
        'user': credential.user,
        'message': 'Compte créé avec succès',
        'riskAssessment': riskAssessment, // Pour afficher les limites à l'utilisateur
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
        // 🚧 PHASE DE DÉVELOPPEMENT : Envoi email de vérification désactivé
        // TODO: Réactiver en production
        // await sendEmailVerification();

        return {
          'success': true,
          'user': user,
          // 'requiresVerification': true, // Désactivé en dev
          'message': 'Compte créé avec succès !',
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
        // 🚧 PHASE DE DÉVELOPPEMENT : Vérification email désactivée
        // TODO: Réactiver en production
        /*
        // Vérifier si l'email est vérifié
        final currentUser = _auth.currentUser;
        if (currentUser != null && !currentUser.emailVerified) {
          return {
            'success': false,
            'requiresVerification': true,
            'message': 'Email non vérifié. Vérifiez votre boîte email.',
          };
        }
        */

        // ✅ Vérifier et créer le document Firestore si nécessaire
        final currentUser = _auth.currentUser;
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
          forceResendingToken: _resendToken,
          verificationCompleted: (firebase_auth.PhoneAuthCredential credential) async {
            // Auto-vérification (Android uniquement)
            await _auth.signInWithCredential(credential);
            debugPrint('✅ Auto-vérification SMS réussie');
            _otpStatusController.add({
              'event': 'autoVerified',
              'message': 'Code vérifié automatiquement',
            });
          },
          verificationFailed: (firebase_auth.FirebaseAuthException e) {
            debugPrint('❌ Échec vérification: ${e.message}');
            _otpStatusController.add({
              'event': 'verificationFailed',
              'message': e.message ?? 'Échec de vérification',
            });
          },
          codeSent: (String verificationId, int? resendToken) {
            _verificationId = verificationId;
            _resendToken = resendToken;
            debugPrint('✅ Code envoyé, ID: $verificationId');
            _otpStatusController.add({
              'event': 'codeSent',
              'message': 'Code envoyé avec succès',
            });
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            _verificationId = verificationId;
            debugPrint('⏱️ Timeout auto-retrieval - entrez le code manuellement');
            _otpStatusController.add({
              'event': 'autoRetrievalTimeout',
              'message': 'Veuillez entrer le code manuellement',
            });
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

      GoogleSignInAccount? googleUser;

      // ✅ Différenciation Web vs Mobile
      if (kIsWeb) {
        // Sur Web : signInSilently d'abord, puis signIn si nécessaire
        googleUser = await _googleSignIn.signInSilently();
        if (googleUser == null) {
          debugPrint('⚠️ signInSilently échoué, tentative signIn normal...');
          googleUser = await _googleSignIn.signIn();
        }
      } else {
        // Sur Mobile : signIn directement pour ouvrir popup Google
        googleUser = await _googleSignIn.signIn();
      }

      // Vérifier si l'utilisateur a annulé la connexion
      if (googleUser == null) {
        debugPrint('⚠️ Connexion Google annulée par l\'utilisateur');
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

      debugPrint('🔐 Connexion Firebase avec credentials Google...');

      // Connexion Firebase avec Google
      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user == null) {
        return {'success': false, 'message': 'Échec de la connexion Firebase'};
      }

      final user = userCredential.user!;
      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

      debugPrint('✅ Connexion Firebase réussie pour: ${user.email}');

      // ✅ Toujours s'assurer que le document Firestore existe
      await _ensureFirestoreDocument(user);

      if (isNewUser) {
        debugPrint('🆕 Nouvel utilisateur Google créé dans Firestore');
      } else {
        debugPrint('👤 Utilisateur Google existant connecté');
      }

      // Charger l'utilisateur depuis Firestore
      final localUser = await FirebaseService.getDocument(
        collection: FirebaseCollections.users,
        docId: user.uid,
      );

      return {
        'success': true,
        'user': _createLocalUser(user.uid, localUser ?? {}),
        'isNewUser': isNewUser,
      };
    } catch (e) {
      debugPrint('❌ Erreur Google Sign-In: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion Google: ${e.toString()}',
      };
    }
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

        // Notifier les admins pour vendeurs et livreurs
        if (userType == UserType.vendeur || userType == UserType.livreur) {
          try {
            await NotificationService.notifyAllAdmins(
              type: 'user_registration',
              title: 'Nouvel utilisateur ${userType.label}',
              body: '$name vient de s\'inscrire par téléphone et attend validation',
              data: {
                'userId': firebaseUser.uid,
                'userType': userType.name,
                'userName': name,
                'userPhone': firebaseUser.phoneNumber ?? '',
              },
            );
            debugPrint('✅ Admins notifiés de la nouvelle inscription (téléphone)');
          } catch (e) {
            debugPrint('⚠️ Erreur notification admins: $e');
          }
        }
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