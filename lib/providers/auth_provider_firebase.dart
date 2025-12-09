// ===== lib/providers/auth_provider_firebase.dart =====
// Provider d'authentification avec Firebase réel - CORRIGÉ

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:social_business_pro/config/constants.dart'; // ✅ Import complet - plus de conflit
import '../models/user_model.dart';
import '../services/firebase_service.dart';
import '../services/audit_service.dart';
import '../models/audit_log_model.dart';
import '../config/user_type_config.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

// ===== HELPER FUNCTIONS =====
/// Parse une date depuis Firestore - supporte Timestamp ET String
DateTime? _parseDateField(dynamic value) {
  if (value == null) return null;

  // Cas 1: C'est déjà un Timestamp Firestore
  if (value is Timestamp) {
    return value.toDate();
  }

  // Cas 2: C'est une String (format ISO ou autre)
  if (value is String) {
    try {
      return DateTime.parse(value);
    } catch (e) {
      // Si le parsing échoue, retourner null
      return null;
    }
  }

  // Cas 3: Type inconnu
  return null;
}

// Provider d'authentification Firebase
class AuthProvider extends ChangeNotifier {
  UserModel? _user; // ✅ Changé de User vers UserModel
  bool _isLoading = false;
  String? _errorMessage;

  // Getters corrigés
  UserModel? get user => _user; // ✅ Retourne UserModel
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserType? get userType => _user?.userType;

  // Initialisation - Écouter les changements d'authentification
  AuthProvider() {
    _initializeAuthListener();
  }

  void _initializeAuthListener() {
    FirebaseService.authStateChanges.listen((firebaseUser) async {
      if (firebaseUser != null) {
        // Utilisateur connecté - charger ses données
        await _loadUserFromFirestore(firebaseUser.uid);
      } else {
        // Utilisateur déconnecté
        _user = null;
        notifyListeners();
      }
    });
  }

  // Charger les données utilisateur depuis Firestore
  Future<void> _loadUserFromFirestore(String uid) async {
    
    try {
      final userData = await FirebaseService.getDocument(
        collection: FirebaseCollections.users,
        docId: uid,
      );

      if (userData == null) {
        // ❌ NE PAS créer automatiquement - risque d'écraser le vrai document
        debugPrint('⚠️ Document utilisateur non trouvé pour UID: $uid');
        debugPrint('⚠️ Cela peut être dû à un timeout Firestore');
        debugPrint('⚠️ Utilisateur temporairement non chargé');

        // Ne rien faire - l'utilisateur restera null
        return;
      }

      // ✅ Créer UserModel au lieu de User local
      _user = UserModel(
        id: uid,
        email: userData['email'] ?? '',
        displayName: userData['displayName'] ?? 'Utilisateur', // ✅ Mapper name → displayName
        phoneNumber: userData['phone'],
        userType: UserType.values.firstWhere(
          (type) => type.toString().split('.').last == userData['userType'],
          orElse: () => UserType.acheteur,
        ),
        isVerified: userData['isVerified'] ?? false,
        isActive: userData['isActive'] ?? true,
        isSuperAdmin: userData['isSuperAdmin'] ?? false,
        preferences: UserPreferences.fromMap(userData['preferences'] ?? {}),
        profile: Map<String, dynamic>.from(userData['profile'] ?? {}),
        createdAt: _parseDateField(userData['createdAt']) ?? DateTime.now(),
        updatedAt: _parseDateField(userData['updatedAt']) ?? DateTime.now(),
        lastLoginAt: _parseDateField(userData['lastLoginAt']),
      );
      
      debugPrint('✅ Utilisateur chargé: ${_user?.displayName}');
          
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Erreur chargement utilisateur: $e');
      _errorMessage = 'Erreur lors du chargement du profil';
      notifyListeners();
    }
  }

  // ===== MÉTHODES D'AUTHENTIFICATION =====

  /// Inscription avec email et mot de passe
  Future<bool> register({
    required String username,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
    required UserType userType,
    String verificationType = 'email',
  }) async {
    if (_isLoading) return false;

    try {
      _setLoading(true);
      _clearError();

      // Validation
      if (password != confirmPassword) {
        throw Exception('Les mots de passe ne correspondent pas');
      }

      if (password.length < 6) {
        throw Exception('Le mot de passe doit contenir au moins 6 caractères');
      }
      debugPrint('🔵 Début inscription: $username');
      // Créer l'utilisateur via FirebaseService (SANS TIMEOUT pour Web)
      final newUser = await FirebaseService.registerWithEmail(
        username: username,
        email: email,
        phone: phone,
        password: password,
        userType: userType,
        verificationType: verificationType,
      );

      debugPrint('🟢 Inscription terminée');

      if (newUser != null) {
        // ✅ Convertir en UserModel
        _user = UserModel(
          id: newUser.id,
          email: newUser.email,
          displayName: newUser.displayName, // ✅ Mapper name → displayName
          phoneNumber: newUser.phoneNumber,
          userType: newUser.userType,
          isVerified: false,
          preferences: UserPreferences(), // Valeurs par défaut
          profile: _getDefaultProfile(newUser.userType),
          createdAt: newUser.createdAt,
          updatedAt: DateTime.now(),
        );

        debugPrint('✅ Inscription réussie: ${_user?.displayName}');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Erreur inscription: $e');
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Connexion avec email et mot de passe
  Future<bool> login({
    required String identifier,
    required String password,
  }) async {
    if (_isLoading) return false;

    try {
      _setLoading(true);
      _clearError();

      // Se connecter via FirebaseService
      final loggedUser = await FirebaseService.signInWithIdentifier(
        identifier: identifier,
        password: password,
      );

      if (loggedUser != null) {
        // Charger les données complètes depuis Firestore
        final userData = await FirebaseService.getDocument(
          collection: FirebaseCollections.users,
          docId: loggedUser.id,
        );

        // Récupérer les préférences et le profil depuis Firestore si disponibles
        UserPreferences preferences = UserPreferences();
        Map<String, dynamic> profile = _getDefaultProfile(loggedUser.userType);

        if (userData != null) {
          // Charger les préférences depuis Firestore
          if (userData['preferences'] != null) {
            try {
              preferences = UserPreferences.fromMap(userData['preferences'] as Map<String, dynamic>);
              debugPrint('✅ Préférences chargées depuis Firestore');
            } catch (e) {
              debugPrint('⚠️ Erreur chargement préférences: $e - utilisation valeurs par défaut');
            }
          }

          // Charger le profil depuis Firestore
          if (userData['profile'] != null) {
            profile = Map<String, dynamic>.from(userData['profile']);
            debugPrint('✅ Profil chargé depuis Firestore');
          }
        }

        // ✅ Convertir en UserModel avec données Firestore
        _user = UserModel(
          id: loggedUser.id,
          email: loggedUser.email,
          displayName: loggedUser.displayName,
          phoneNumber: loggedUser.phoneNumber,
          userType: loggedUser.userType,
          isVerified: true, // Connecté = vérifié
          preferences: preferences,
          profile: profile,
          createdAt: loggedUser.createdAt,
          updatedAt: DateTime.now(),
        );

        debugPrint('✅ Connexion réussie: ${_user?.displayName}');

        // 📊 Logger la connexion réussie
        await AuditService.logSecurityEvent(
          userId: _user!.id,
          userEmail: _user!.email,
          userName: _user!.displayName,
          action: AuditActions.loginSuccess,
          actionLabel: 'Connexion réussie',
          description: 'Connexion réussie pour ${_user!.displayName} (${_user!.userType.value})',
          metadata: {
            'userType': _user!.userType.value,
            'method': 'email',
          },
          severity: AuditSeverity.low,
          requiresReview: false,
        );

        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Erreur connexion: $e');

      // 📊 Logger l'échec de connexion
      try {
        await AuditService.logSecurityEvent(
          userId: identifier,
          userEmail: identifier,
          action: AuditActions.loginFailed,
          actionLabel: 'Échec de connexion',
          description: 'Tentative de connexion échouée pour $identifier',
          metadata: {
            'error': e.toString(),
            'identifier': identifier,
          },
          severity: AuditSeverity.medium,
          requiresReview: true,
          isSuccessful: false,
        );
      } catch (logError) {
        debugPrint('⚠️ Erreur logging échec connexion: $logError');
      }

      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Charger l'utilisateur depuis Firebase (pour Web après connexion rapide)
  Future<void> loadUserFromFirebase() async {
    try {
      final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;

      if (firebaseUser == null) {
        debugPrint('❌ Aucun utilisateur Firebase connecté');
        return;
      }

      debugPrint('🔄 Chargement utilisateur depuis Firestore: ${firebaseUser.uid}');

      // ✅ Laisser Firestore gérer automatiquement (serveur puis cache)
      DocumentSnapshot<Map<String, dynamic>>? userDoc;

      try {
        debugPrint('   📡 Lecture Firestore automatique (serveur → cache)...');

        userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
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
        final data = userDoc.data()!;

        // ✅ DÉTECTION ADMIN PAR EMAIL
        String userTypeString = data['userType'] ?? 'acheteur';
        final email = data['email'] ?? firebaseUser.email ?? '';

        if (email.isNotEmpty &&
            (email.contains('admin@') || email == 'admin@socialbusiness.ci')) {
          debugPrint('🔑 Admin détecté par email: $email');
          userTypeString = 'admin';

          // Mettre à jour dans Firestore si nécessaire (avec timeout court)
          if (data['userType'] != 'admin') {
            debugPrint('📝 Mise à jour du type admin dans Firestore...');
            try {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(firebaseUser.uid)
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

        // Charger les préférences depuis Firestore si disponibles
        UserPreferences preferences = UserPreferences();
        if (data['preferences'] != null) {
          try {
            preferences = UserPreferences.fromMap(data['preferences'] as Map<String, dynamic>);
            debugPrint('✅ Préférences chargées depuis Firestore');
          } catch (e) {
            debugPrint('⚠️ Erreur chargement préférences: $e - utilisation valeurs par défaut');
          }
        }

        _user = UserModel(
          id: firebaseUser.uid,
          email: email,
          displayName: data['displayName'] ?? firebaseUser.displayName ?? '',
          phoneNumber: data['phoneNumber'] ?? firebaseUser.phoneNumber ?? '',
          userType: UserType.values.firstWhere(
            (type) => type.value == userTypeString,
            orElse: () => UserType.acheteur,
          ),
          isVerified: data['isVerified'] ?? false,
          preferences: preferences,
          profile: data['profile'] ?? {},
          createdAt: _parseDateField(data['createdAt']) ?? DateTime.now(),
          updatedAt: _parseDateField(data['updatedAt']) ?? DateTime.now(),
        );

        debugPrint('✅ Utilisateur chargé: ${_user?.displayName} (${_user?.userType.value})');
        notifyListeners();
      } else {
        debugPrint('⚠️ Document Firestore non trouvé pour ${firebaseUser.uid}');

        // ✅ Utiliser configuration locale basée sur l'email
        final email = firebaseUser.email ?? '';
        final userTypeString = UserTypeConfig.getUserTypeFromEmail(email);

        debugPrint('⚠️ Utilisation configuration locale basée sur email');
        debugPrint('   📧 Email: $email');
        debugPrint('   🔑 UserType détecté: $userTypeString');

        _user = UserModel(
          id: firebaseUser.uid,
          email: email,
          displayName: firebaseUser.displayName ?? 'Utilisateur',
          phoneNumber: firebaseUser.phoneNumber ?? '',
          userType: UserTypeConfig.parseUserType(userTypeString),
          isVerified: false,
          preferences: UserPreferences(),
          profile: {},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        debugPrint('✅ Utilisateur créé localement: ${_user?.displayName} (${_user?.userType.value})');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement utilisateur: $e');
    }
  }

  /// Déconnexion
  Future<void> logout() async {
    try {
      debugPrint('🚪 Déconnexion...');

      // Sauvegarder les infos de l'utilisateur avant de le déconnecter
      final userId = _user?.id;
      final userEmail = _user?.email;
      final userName = _user?.displayName;
      final userType = _user?.userType.value;

      await FirebaseService.signOut();
      _user = null;
      _clearError();
      notifyListeners();
      debugPrint('✅ Déconnexion réussie');

      // 📊 Logger la déconnexion
      if (userId != null && userEmail != null) {
        try {
          await AuditService.logSecurityEvent(
            userId: userId,
            userEmail: userEmail,
            userName: userName,
            action: AuditActions.logout,
            actionLabel: 'Déconnexion',
            description: 'Déconnexion de ${userName ?? userEmail}',
            metadata: {
              'userType': userType,
            },
            severity: AuditSeverity.low,
            requiresReview: false,
          );
        } catch (logError) {
          debugPrint('⚠️ Erreur logging déconnexion: $logError');
        }
      }

    } catch (e) {
      debugPrint('❌ Erreur déconnexion: $e');
      _setError(e.toString());
      rethrow;
    }
  }

  /// Réinitialisation du mot de passe
  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);
      _clearError();

      await firebase_auth.FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      debugPrint('✅ Email de réinitialisation envoyé');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur réinitialisation: $e');
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Mettre à jour le profil utilisateur
  Future<bool> updateProfile({
    String? name,
    String? phone,
    Map<String, dynamic>? profileData,
  }) async {
    if (_user == null) return false;

    try {
      _setLoading(true);
      _clearError();

      // Préparer les données de mise à jour pour Firestore
      Map<String, dynamic> firestoreUpdates = {};

      if (name != null) firestoreUpdates['displayName'] = name;
      if (phone != null) firestoreUpdates['phoneNumber'] = phone;

      // Fusionner les données du profil existant avec les nouvelles
      if (profileData != null) {
        final mergedProfile = Map<String, dynamic>.from(_user!.profile);
        mergedProfile.addAll(profileData);
        firestoreUpdates['profile'] = mergedProfile;
      }

      // Mettre à jour dans Firestore via FirebaseService
      final success = await FirebaseService.updateUserData(
        _user!.id,
        firestoreUpdates,
      );

      if (!success) {
        throw Exception('Échec de la mise à jour dans Firestore');
      }

      debugPrint('✅ Données Firestore mises à jour');

      // Mettre à jour localement après succès Firestore
      _user = _user!.copyWith(
        displayName: name,
        phoneNumber: phone,
        profile: profileData != null
            ? Map<String, dynamic>.from({..._user!.profile, ...profileData})
            : _user!.profile,
        updatedAt: DateTime.now(),
      );

      notifyListeners();
      debugPrint('✅ Profil mis à jour localement');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur mise à jour profil: $e');
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ✅ MÉTHODE NAVIGATION INTELLIGENTE
  String getHomeRoute() {
    switch (_user?.userType) {
      case UserType.admin:
        return '/admin';
      case UserType.vendeur: 
        return '/vendeur';
      case UserType.acheteur:
        return '/acheteur';
      case UserType.livreur:
        return '/livreur';
      default:
        return '/login';
    }
  }

  // ===== MÉTHODES UTILITAIRES =====

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Obtenir le profil par défaut selon le type d'utilisateur
  Map<String, dynamic> _getDefaultProfile(UserType userType) {
    switch (userType) {
      case UserType.vendeur:
        return VendeurProfile(
          businessName: '',
          businessCategory: '',
          paymentInfo: PaymentInfo(),
          stats: BusinessStats(),
          deliverySettings: DeliverySettings(),
        ).toMap();
      
      case UserType.acheteur:
        return AcheteurProfile(
          deliveryPreferences: DeliveryPreferences(),
        ).toMap();
      
      case UserType.livreur:
        return LivreurProfile(
          vehicleType: 'moto',
          deliveryZone: '',
          deliveryRates: DeliveryRates(),
          workingHours: WorkingHours(),
        ).toMap();
      
      default:
        return {};
    }
  }

  /// Rafraîchir les données utilisateur
  Future<void> refreshUser() async {
    if (_user != null) {
      await _loadUserFromFirestore(_user!.id);
    }
  }

  @override
  void dispose() {
    // Nettoyer les listeners si nécessaire
    super.dispose();
  }

}