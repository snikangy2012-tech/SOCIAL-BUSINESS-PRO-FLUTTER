// ===== lib/services/firestore_sync_service.dart =====
// Service de synchronisation Firestore asynchrone pour Web
// Permet inscription/connexion rapide avec synchronisation en arrière-plan

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../config/constants.dart';

class FirestoreSyncService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Map<String, bool> _syncQueue = {};

  /// Créer document utilisateur en arrière-plan (non bloquant)
  static Future<void> createUserDocumentAsync({
    required String uid,
    required String email,
    required String displayName,
    required String phoneNumber,
    required String userType,
  }) async {
    if (_syncQueue[uid] == true) {
      debugPrint('⏭️ Document $uid déjà en cours de création');
      return;
    }

    _syncQueue[uid] = true;

    // Ne pas attendre - lancer en arrière-plan
    _createDocumentInBackground(
      uid: uid,
      email: email,
      displayName: displayName,
      phoneNumber: phoneNumber,
      userType: userType,
    ).then((_) {
      debugPrint('✅ Document $uid créé avec succès en arrière-plan');
      _syncQueue.remove(uid);
    }).catchError((error) {
      debugPrint('❌ Échec création document $uid: $error');
      // Réessayer après 5 secondes
      Future.delayed(const Duration(seconds: 5), () {
        _syncQueue.remove(uid);
        createUserDocumentAsync(
          uid: uid,
          email: email,
          displayName: displayName,
          phoneNumber: phoneNumber,
          userType: userType,
        );
      });
    });
  }

  /// Création effective du document (avec retry)
  static Future<void> _createDocumentInBackground({
    required String uid,
    required String email,
    required String displayName,
    required String phoneNumber,
    required String userType,
  }) async {
    final userData = {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'userType': userType,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    int retries = 3;
    while (retries > 0) {
      try {
        await _firestore
            .collection(FirebaseCollections.users)
            .doc(uid)
            .set(userData, SetOptions(merge: true))
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () {
                throw TimeoutException('Firestore timeout');
              },
            );

        debugPrint('✅ Document Firestore créé: $uid');
        return;
      } catch (e) {
        retries--;
        debugPrint('⚠️ Tentative échouée (reste $retries): $e');

        if (retries > 0) {
          await Future.delayed(Duration(seconds: 5 * (4 - retries)));
        } else {
          rethrow;
        }
      }
    }
  }

  /// Vérifier si le document existe, sinon le créer
  static Future<bool> ensureDocumentExists({
    required String uid,
    required String email,
    required String displayName,
    String phoneNumber = '',
    String userType = 'acheteur',
  }) async {
    try {
      final doc = await _firestore
          .collection(FirebaseCollections.users)
          .doc(uid)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('Document check timeout'),
          );

      if (doc.exists) {
        debugPrint('✅ Document existe déjà: $uid');
        return true;
      }

      debugPrint('⚠️ Document absent, création en arrière-plan...');
      createUserDocumentAsync(
        uid: uid,
        email: email,
        displayName: displayName,
        phoneNumber: phoneNumber,
        userType: userType,
      );

      // Retourner true immédiatement (création en arrière-plan)
      return true;
    } catch (e) {
      debugPrint('❌ Erreur vérification document: $e');

      // Lancer création en arrière-plan même si vérification échoue
      createUserDocumentAsync(
        uid: uid,
        email: email,
        displayName: displayName,
        phoneNumber: phoneNumber,
        userType: userType,
      );

      return true; // Ne pas bloquer l'utilisateur
    }
  }

  /// Charger document avec fallback rapide
  static Future<Map<String, dynamic>?> getUserDataWithFallback({
    required String uid,
    required String email,
    required String displayName,
    String phoneNumber = '',
  }) async {
    try {
      final doc = await _firestore
          .collection(FirebaseCollections.users)
          .doc(uid)
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () => throw TimeoutException('Load timeout'),
          );

      if (doc.exists) {
        return doc.data();
      }

      debugPrint('⚠️ Document absent, retour données locales');
      return null;
    } catch (e) {
      debugPrint('❌ Erreur chargement: $e');
      return null;
    }
  }

  /// Synchroniser données locales vers Firestore
  static Future<void> syncLocalDataToFirestore({
    required String uid,
    required Map<String, dynamic> localData,
  }) async {
    try {
      await _firestore
          .collection(FirebaseCollections.users)
          .doc(uid)
          .set(localData, SetOptions(merge: true))
          .timeout(const Duration(seconds: 10));

      debugPrint('✅ Données locales synchronisées: $uid');
    } catch (e) {
      debugPrint('❌ Échec synchronisation: $e');
      // Réessayer plus tard
      Future.delayed(const Duration(minutes: 1), () {
        syncLocalDataToFirestore(uid: uid, localData: localData);
      });
    }
  }

  /// Nettoyer la queue de synchronisation
  static void clearSyncQueue() {
    _syncQueue.clear();
    debugPrint('🧹 Queue de synchronisation vidée');
  }

  /// Obtenir l'état de synchronisation d'un utilisateur
  static bool isSyncing(String uid) {
    return _syncQueue[uid] ?? false;
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => 'TimeoutException: $message';
}
