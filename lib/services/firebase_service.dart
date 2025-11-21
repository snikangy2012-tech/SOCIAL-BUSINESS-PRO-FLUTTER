// ===== lib/services/firebase_service.dart =====
// Service Firebase principal avec gestion optimisée des timeouts et reconnexions

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';

import 'package:social_business_pro/config/constants.dart';
import '../models/user_model.dart';
import 'subscription_service.dart';

class FirebaseService {
  static final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ===== VÉRIFICATION CONNEXION =====
  
  /// Vérifier la connexion Firestore
  static Future<bool> checkFirestoreConnection() async {
    // ✅ TOUJOURS RETOURNER TRUE SUR WEB (évite les timeouts)
    if (kIsWeb) {
      debugPrint('✅ Web: Connexion Firestore assumée active');
      return true;
    }
    try {
      await _firestore.enableNetwork();
      
      // Test de connexion simple
      await _firestore.collection('health_check').doc('test').get()
          .timeout(const Duration(seconds: 10));
      
      debugPrint('✅ Firestore connecté');
      return true;
    } catch (e) {
      debugPrint('❌ Firestore déconnecté: $e');
      return false;
    }
  }

  // ===== AUTHENTIFICATION =====

  /// Inscription avec email et mot de passe
  static Future<UserModel?> registerWithEmail({
    required String username,
    required String email,
    required String phone,
    required String password,
    required UserType userType,
    String verificationType = 'email',
  }) async {
    firebase_auth.UserCredential? credential;
    
    try {
      debugPrint('🚀 Début inscription: $username');
      
      // ÉTAPE 1 : Vérifier la connexion
      debugPrint('🔄 [1/7] Vérification connexion...');
      final isConnected = await checkFirestoreConnection();
      if (!isConnected) {
        throw Exception('Pas de connexion Internet. Vérifiez votre réseau.');
      }

      // ÉTAPE 2 : Créer le compte Firebase Auth
      debugPrint('🔄 [2/7] Création compte Auth...');
      credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Timeout création compte Auth'),
      );

      if (credential.user == null) {
        throw Exception('Échec création compte Auth');
      }

      debugPrint('✅ [3/7] Compte Auth créé: ${credential.user!.uid}');

      // ÉTAPE 3 : Mettre à jour le profil
      debugPrint('🔄 [4/7] Mise à jour profil...');
      await credential.user!.updateDisplayName(username).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Timeout mise à jour profil'),
      );

      debugPrint('✅ [5/7] Profil mis à jour');

      // ÉTAPE 4 : Préparer les données Firestore
      debugPrint('🔄 [6/7] Préparation données Firestore...');
      final userData = {
        'uid': credential.user!.uid,
        'email': email,
        'displayName': username,
        'phoneNumber': phone,
        'userType': userType.name,
        'isVerified': false,
        'isActive': true,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        'lastLogin': Timestamp.now(),
        
        // Préférences par défaut
        'preferences': {
          'notifications': {
            'push': true,
            'email': true,
            'sms': false,
          },
          'language': 'fr',
          'theme': 'light',
        },

        // Profil selon le type d'utilisateur
        'profile': _getDefaultProfile(userType),
        
        // Métadonnées
        'metadata': {
          'platform': kIsWeb ? 'web' : 'mobile',
          'version': '1.0.0',
          'registrationMethod': verificationType,
        },
      };

      // ÉTAPE 5 : Sauvegarder dans Firestore avec retry
      debugPrint('🔄 [7/7] Sauvegarde Firestore avec retry...');
      await _saveUserDataWithRetry(credential.user!.uid, userData);

      // ÉTAPE 6 : Envoyer vérification selon le choix
      try {
        if (verificationType == 'sms') {
          debugPrint('📱 Préparation envoi SMS...');
          // Le SMS sera envoyé par AuthServiceExtended
        } else {
          debugPrint('📧 Envoi email de vérification...');
          await credential.user!.sendEmailVerification();
          debugPrint('✅ Email de vérification envoyé');
        }
      } catch (verificationError) {
        debugPrint('⚠️ Erreur envoi vérification (non critique): $verificationError');
      }

      debugPrint('✅ Inscription terminée avec succès');

      // ÉTAPE 7 : Créer l'abonnement par défaut (VENDEUR et LIVREUR uniquement)
      try {
        if (userType == UserType.vendeur) {
          debugPrint('📊 Création abonnement BASIQUE par défaut pour vendeur...');
          final subscriptionService = SubscriptionService();
          await subscriptionService.createBasiqueSubscription(credential.user!.uid);
          debugPrint('✅ Abonnement BASIQUE créé pour vendeur');
        } else if (userType == UserType.livreur) {
          debugPrint('📊 Création abonnement STARTER par défaut pour livreur...');
          final subscriptionService = SubscriptionService();
          await subscriptionService.createStarterLivreurSubscription(credential.user!.uid);
          debugPrint('✅ Abonnement STARTER créé pour livreur');
        }
      } catch (subscriptionError) {
        debugPrint('⚠️ Erreur création abonnement par défaut (non critique): $subscriptionError');
        // Ne pas bloquer l'inscription si l'abonnement échoue
      }

      // Retourner le modèle utilisateur
      return UserModel(
        id: credential.user!.uid,
        email: email,
        displayName: username,
        phoneNumber: phone,
        userType: userType,
        isVerified: false,
        preferences: UserPreferences(),
        profile: _getDefaultProfile(userType),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

    } catch (e) {
      debugPrint('❌ Erreur inscription: $e');

      // ROLLBACK : Supprimer le compte Auth si Firestore échoue
      if (credential?.user != null) {
        try {
          debugPrint('🔄 Rollback: suppression compte Auth...');
          await credential!.user!.delete();
          debugPrint('✅ Compte Auth supprimé (rollback réussi)');
        } catch (deleteError) {
          debugPrint('⚠️ Erreur rollback: $deleteError');
        }
      }

      // Relancer l'exception avec un message plus clair
      if (e.toString().contains('email-already-in-use')) {
        throw Exception('Un compte existe déjà avec cet email');
      } else if (e.toString().contains('weak-password')) {
        throw Exception('Mot de passe trop faible');
      } else if (e.toString().contains('invalid-email')) {
        throw Exception('Adresse email invalide');
      } else if (e.toString().contains('Timeout')) {
        throw Exception('Connexion trop lente. Réessayez.');
      } else {
        throw Exception('Échec sauvegarde profil. Veuillez réessayer.');
      }
    }
  }

  /// Sauvegarder données utilisateur avec retry automatique et fallback Web
  static Future<void> _saveUserDataWithRetry(String uid, Map<String, dynamic> userData) async {
    // ✅ SUR WEB: Sauvegarder sans timeout et ne pas échouer si offline
    if (kIsWeb) {
      try {
        debugPrint('💾 Web: Sauvegarde Firestore (mode tolérant)...');

        // Tentative de sauvegarde sans timeout strict
        await _firestore
            .collection(FirebaseCollections.users)
            .doc(uid)
            .set(userData)
            .timeout(
              const Duration(seconds: 60),
              onTimeout: () async {
                debugPrint('⏱️ Timeout Web - les données seront sauvegardées en arrière-plan');
                // Ne pas lancer d'exception, juste logger
                return;
              },
            );

        debugPrint('✅ Données Firestore sauvegardées (Web)');
      } catch (e) {
        // Sur Web, ne pas échouer l'inscription si Firestore est offline
        debugPrint('⚠️ Firestore offline (Web) - données Auth créées, Firestore en attente');
        debugPrint('   💡 Les données seront synchronisées à la prochaine connexion');
        // Ne pas lancer d'exception
      }
      return;
    }

    // ✅ SUR MOBILE: Retry agressif avec timeouts
    int retries = 0;
    const maxRetries = 3;

    while (retries < maxRetries) {
      try {
        await _firestore
            .collection(FirebaseCollections.users)
            .doc(uid)
            .set(userData)
            .timeout(const Duration(seconds: 120)); // 2 minutes

        debugPrint('✅ Données Firestore sauvegardées (Mobile)');
        return; // Succès, sortir de la fonction

      } catch (e) {
        retries++;
        debugPrint('⚠️ Tentative $retries/$maxRetries échouée: $e');

        if (retries >= maxRetries) {
          throw Exception('Timeout sauvegarde Firestore après $maxRetries tentatives');
        }

        // Délai progressif avant retry (2s, 4s, 6s)
        final delaySeconds = 2 * retries;
        debugPrint('🔄 Retry dans ${delaySeconds}s...');
        await Future.delayed(Duration(seconds: delaySeconds));

        // Réactiver le réseau avant retry
        try {
          await _firestore.enableNetwork();
        } catch (networkError) {
          debugPrint('⚠️ Erreur réactivation réseau: $networkError');
        }
      }
    }
  }

  /// Connexion avec identifiant (email, téléphone ou nom d'utilisateur)
  static Future<UserModel?> signInWithIdentifier({
    required String identifier,
    required String password,
  }) async {
    try {
      debugPrint('🔐 Tentative connexion: $identifier');

      String email = identifier;

      // Si l'identifiant n'est pas un email, chercher l'email correspondant
      if (!identifier.contains('@')) {
        debugPrint('🔍 Recherche email depuis téléphone...');
        
        final isConnected = await checkFirestoreConnection();
        if (!isConnected) {
          throw Exception('Pas de connexion Internet');
        }

        // Chercher par téléphone ou nom d'utilisateur
        QuerySnapshot userQuery;
        
        if (RegExp(r'^\d+$').hasMatch(identifier)) {
          // C'est un numéro de téléphone
          userQuery = await _firestore
              .collection(FirebaseCollections.users)
              .where('phoneNumber', isEqualTo: identifier)
              .limit(1)
              .get()
              .timeout(const Duration(seconds: 30));
        } else {
          // C'est un nom d'utilisateur
          userQuery = await _firestore
              .collection(FirebaseCollections.users)
              .where('displayName', isEqualTo: identifier)
              .limit(1)
              .get()
              .timeout(const Duration(seconds: 30));
        }

        if (userQuery.docs.isEmpty) {
          throw Exception('Aucun compte trouvé avec ces identifiants');
        }

        final userData = userQuery.docs.first.data() as Map<String, dynamic>?;
        email = userData?['email'] ?? '';

        if (email.isEmpty) {
          throw Exception('Email introuvable pour cet utilisateur');
        }
      }

      // Connexion avec email et mot de passe
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Timeout connexion Auth'),
      );

      if (credential.user == null) {
        throw Exception('Échec de la connexion');
      }

      // Récupérer les données utilisateur depuis Firestore
      final userData = await getUserData(credential.user!.uid);
      if (userData == null) {
        throw Exception('Données utilisateur introuvables');
      }

      debugPrint('✅ Connexion réussie: ${userData.displayName}');
      return userData;

    } catch (e) {
      debugPrint('❌ Erreur connexion: $e');

      if (e.toString().contains('user-not-found')) {
        throw Exception('Aucun compte trouvé avec ces identifiants');
      } else if (e.toString().contains('wrong-password') || 
                 e.toString().contains('invalid-credential')) {
        throw Exception('Mot de passe incorrect');
      } else if (e.toString().contains('too-many-requests')) {
        throw Exception('Trop de tentatives. Réessayez plus tard.');
      } else if (e.toString().contains('user-disabled')) {
        throw Exception('Ce compte a été désactivé');
      } else {
        throw Exception('Erreur inconnue: $e');
      }
    }
  }

  /// Récupérer les données utilisateur depuis Firestore
  static Future<UserModel?> getUserData(String uid) async {
    try {
      final isConnected = await checkFirestoreConnection();
      if (!isConnected) {
        throw Exception('Pas de connexion Internet');
      }

      final doc = await _firestore
          .collection(FirebaseCollections.users)
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 30));

      if (!doc.exists) {
        debugPrint('❌ Données utilisateur introuvables pour: $uid');
        return null;
      }

      final data = doc.data();
      if (data == null) {
        debugPrint('❌ Document utilisateur vide pour: $uid');
        return null;
      }

      debugPrint('✅ Utilisateur chargé: ${data['displayName']}');

      return UserModel(
        id: uid,
        email: data['email'] ?? '',
        displayName: data['displayName'] ?? '',
        phoneNumber: data['phoneNumber'] ?? '',
        userType: UserType.values.firstWhere(
          (type) => type.name == data['userType'],
          orElse: () => UserType.acheteur,
        ),
        isVerified: data['isVerified'] ?? false,
        preferences: UserPreferences(), // TODO: Parser depuis data
        profile: data['profile'] ?? {},
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

    } catch (e) {
      debugPrint('❌ Erreur récupération document: $e');
      return null;
    }
  }

  /// Déconnexion
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
      debugPrint('✅ Déconnexion réussie');
    } catch (e) {
      debugPrint('❌ Erreur déconnexion: $e');
      throw Exception('Erreur lors de la déconnexion');
    }
  }

  /// Utilisateur actuel
  static firebase_auth.User? get currentUser => _auth.currentUser;

  /// Stream de l'état d'authentification
  static Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();

  // ===== MÉTHODES UTILITAIRES =====

  /// Générer un profil par défaut selon le type d'utilisateur
  static Map<String, dynamic> _getDefaultProfile(UserType userType) {
    switch (userType) {
      case UserType.vendeur:
        return {
          'businessName': '',
          'businessType': '',
          'description': '',
          'address': '',
          'businessHours': {},
          'rating': 0.0,
          'totalSales': 0,
          'isVerifiedBusiness': false,
        };

      case UserType.acheteur:
        return {
          'firstName': '',
          'lastName': '',
          'birthDate': null,
          'address': '',
          'favoriteCategories': [],
          'totalOrders': 0,
          'loyaltyPoints': 0,
        };

      case UserType.livreur:
        return {
          'vehicleType': '',
          'licenseNumber': '',
          'isAvailable': false,
          'currentLocation': null,
          'deliveryZones': [],
          'rating': 0.0,
          'totalDeliveries': 0,
        };

      case UserType.admin:
        return {
          'role': 'admin',
          'permissions': [],
          'department': '',
        };

    }
  }

  /// Mettre à jour les données utilisateur
  static Future<bool> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = Timestamp.now();
      
      await _firestore
          .collection(FirebaseCollections.users)
          .doc(uid)
          .update(data)
          .timeout(const Duration(seconds: 30));

      debugPrint('✅ Données utilisateur mises à jour');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur mise à jour: $e');
      return false;
    }
  }

  /// Récupérer un document depuis Firestore
  static Future<Map<String, dynamic>?> getDocument({
    required String collection,
    required String docId,
  }) async {
    try {
      final isConnected = await checkFirestoreConnection();
      if (!isConnected) {
        throw Exception('Pas de connexion Internet');
      }

      final doc = await _firestore
          .collection(collection)
          .doc(docId)
          .get()
          .timeout(const Duration(seconds: 30));

      if (!doc.exists) {
        return null;
      }

      final data = doc.data();
      if (data != null) {
        data['id'] = doc.id; // Ajouter l'ID du document
      }

      return data;
    } catch (e) {
      debugPrint('❌ Erreur récupération document: $e');
      return null;
    }
  }

  /// Créer/remplacer un document dans Firestore
  static Future<bool> setDocument({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final isConnected = await checkFirestoreConnection();
      if (!isConnected) {
        throw Exception('Pas de connexion Internet');
      }

      // ✅ SANS TIMEOUT - Firestore Web est lent mais fiable
      await _firestore
          .collection(collection)
          .doc(docId)
          .set(data);

      debugPrint('✅ Document créé/mis à jour: $collection/$docId');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur création document: $e');
      return false;
    }
  }

  /// Mettre à jour un document dans Firestore
  static Future<bool> updateDocument({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final isConnected = await checkFirestoreConnection();
      if (!isConnected) {
        throw Exception('Pas de connexion Internet');
      }

      data['updatedAt'] = Timestamp.now();

      await _firestore
          .collection(collection)
          .doc(docId)
          .update(data)
          .timeout(const Duration(seconds: 30));

      debugPrint('✅ Document mis à jour: $collection/$docId');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur mise à jour document: $e');
      return false;
    }
  }
}