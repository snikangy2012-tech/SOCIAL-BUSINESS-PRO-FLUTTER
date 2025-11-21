// ===== lib/services/kyc_verification_service.dart =====
// Service de vérification KYC (Know Your Customer)

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../config/constants.dart';
import '../models/user_model.dart';
import 'notification_service.dart';

/// Service de gestion de la vérification KYC
class KYCVerificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ⚠️ MODE DÉVELOPPEMENT : Désactiver les blocages KYC pendant le développement
  // Passer à `true` en production pour activer les vérifications
  static const bool KYC_ENABLED = false;

  /// Vérifie si un utilisateur peut effectuer une action spécifique
  ///
  /// Actions supportées:
  /// - 'sell': Vendre des produits (vendeur)
  /// - 'deliver': Effectuer des livraisons (livreur)
  /// - 'buy': Acheter des produits (acheteur)
  static Future<bool> canPerformAction(
    String userId,
    String action,
  ) async {
    try {
      // 🔧 MODE DEV: Autoriser toutes les actions si KYC désactivé
      if (!KYC_ENABLED) {
        debugPrint('🔧 [DEV] KYC désactivé - Action "$action" autorisée pour user: $userId');
        return true;
      }

      // Récupérer les infos utilisateur
      final userDoc = await _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        debugPrint('❌ Utilisateur non trouvé: $userId');
        return false;
      }

      final user = UserModel.fromFirestore(userDoc);

      switch (action) {
        case 'sell':
          // Vendeur doit être vérifié pour vendre
          final canSell = user.userType == UserType.vendeur &&
              user.verificationStatus == VerificationStatus.verified;

          debugPrint(
            canSell
                ? '✅ Vendeur $userId vérifié - Vente autorisée'
                : '❌ Vendeur $userId non vérifié - Vente bloquée (status: ${user.verificationStatus})',
          );
          return canSell;

        case 'deliver':
          // Livreur doit être vérifié pour livrer
          final canDeliver = user.userType == UserType.livreur &&
              user.verificationStatus == VerificationStatus.verified;

          debugPrint(
            canDeliver
                ? '✅ Livreur $userId vérifié - Livraison autorisée'
                : '❌ Livreur $userId non vérifié - Livraison bloquée (status: ${user.verificationStatus})',
          );
          return canDeliver;

        case 'buy':
          // Acheteur peut TOUJOURS acheter (vérification optionnelle)
          final canBuy = user.userType == UserType.acheteur;

          debugPrint(
            canBuy
                ? '✅ Acheteur $userId - Achat autorisé (KYC optionnel)'
                : '❌ Type utilisateur incorrect pour achat',
          );
          return canBuy;

        default:
          debugPrint('⚠️ Action inconnue: $action');
          return false;
      }
    } catch (e) {
      debugPrint('❌ Erreur vérification KYC pour action "$action": $e');
      return false;
    }
  }

  /// Soumettre des documents pour vérification KYC
  ///
  /// [userId] ID de l'utilisateur
  /// [documents] Map des URLs des documents uploadés
  /// [userType] Type d'utilisateur (vendeur/livreur)
  static Future<void> submitVerification(
    String userId,
    Map<String, String> documents,
    UserType userType,
  ) async {
    try {
      debugPrint('📤 Soumission vérification KYC pour user: $userId');

      // Mettre à jour le statut à "pending"
      await _firestore.collection(FirebaseCollections.users).doc(userId).update({
        'verificationStatus': VerificationStatus.pending.value,
        'kycDocuments': documents,
        'kycSubmittedAt': FieldValue.serverTimestamp(),
        'kycUpdatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Documents KYC soumis avec succès');

      // 🔧 MODE DEV: Ne pas notifier admin si KYC désactivé
      if (!KYC_ENABLED) {
        debugPrint('🔧 [DEV] Notification admin KYC désactivée');
        return;
      }

      // Notifier les admins d'une nouvelle soumission
      await _notifyAdminNewVerification(userId, userType);
    } catch (e) {
      debugPrint('❌ Erreur soumission KYC: $e');
      rethrow;
    }
  }

  /// Valider ou rejeter une vérification KYC (Admin uniquement)
  ///
  /// [userId] ID de l'utilisateur à valider
  /// [approved] true = approuvé, false = rejeté
  /// [rejectionReason] Raison du rejet (si approved = false)
  /// [adminId] ID de l'admin qui valide
  static Future<void> validateKYC(
    String userId,
    bool approved, {
    String? rejectionReason,
    required String adminId,
  }) async {
    try {
      debugPrint(
        approved
            ? '✅ Validation KYC pour user: $userId par admin: $adminId'
            : '❌ Rejet KYC pour user: $userId - Raison: $rejectionReason',
      );

      final newStatus = approved
          ? VerificationStatus.verified
          : VerificationStatus.rejected;

      await _firestore.collection(FirebaseCollections.users).doc(userId).update({
        'verificationStatus': newStatus.value,
        'kycValidatedAt': FieldValue.serverTimestamp(),
        'kycValidatedBy': adminId,
        if (!approved && rejectionReason != null)
          'kycRejectionReason': rejectionReason,
      });

      debugPrint('✅ Statut KYC mis à jour: ${newStatus.value}');

      // Notifier l'utilisateur
      await _notifyUserKYCDecision(userId, approved, rejectionReason);
    } catch (e) {
      debugPrint('❌ Erreur validation KYC: $e');
      rethrow;
    }
  }

  /// Récupérer la liste des utilisateurs en attente de validation
  static Future<List<UserModel>> getPendingVerifications() async {
    try {
      debugPrint('📋 Récupération des vérifications en attente...');

      final querySnapshot = await _firestore
          .collection(FirebaseCollections.users)
          .where('verificationStatus', isEqualTo: VerificationStatus.pending.value)
          .orderBy('kycSubmittedAt', descending: false)
          .get();

      final users = querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();

      debugPrint('✅ ${users.length} vérifications en attente trouvées');
      return users;
    } catch (e) {
      debugPrint('❌ Erreur récupération vérifications: $e');
      return [];
    }
  }

  /// Vérifier si un utilisateur doit être redirigé vers l'écran KYC
  ///
  /// Retourne true si l'utilisateur est vendeur/livreur non vérifié
  static Future<bool> shouldRedirectToKYC(String userId) async {
    try {
      // 🔧 MODE DEV: Ne jamais rediriger si KYC désactivé
      if (!KYC_ENABLED) {
        return false;
      }

      final userDoc = await _firestore
          .collection(FirebaseCollections.users)
          .doc(userId)
          .get();

      if (!userDoc.exists) return false;

      final user = UserModel.fromFirestore(userDoc);

      // Rediriger si vendeur ou livreur ET non vérifié
      final needsKYC = (user.userType == UserType.vendeur ||
              user.userType == UserType.livreur) &&
          user.verificationStatus == VerificationStatus.notVerified;

      if (needsKYC) {
        debugPrint('🔴 Utilisateur $userId doit compléter KYC');
      }

      return needsKYC;
    } catch (e) {
      debugPrint('❌ Erreur vérification redirection KYC: $e');
      return false;
    }
  }

  /// Récupérer les statistiques KYC (pour dashboard admin)
  static Future<Map<String, int>> getKYCStatistics() async {
    try {
      final usersCollection = _firestore.collection(FirebaseCollections.users);

      // Compter par statut
      final verified = await usersCollection
          .where('verificationStatus', isEqualTo: VerificationStatus.verified.value)
          .count()
          .get();

      final pending = await usersCollection
          .where('verificationStatus', isEqualTo: VerificationStatus.pending.value)
          .count()
          .get();

      final rejected = await usersCollection
          .where('verificationStatus', isEqualTo: VerificationStatus.rejected.value)
          .count()
          .get();

      final notVerified = await usersCollection
          .where('verificationStatus', isEqualTo: VerificationStatus.notVerified.value)
          .count()
          .get();

      return {
        'verified': verified.count ?? 0,
        'pending': pending.count ?? 0,
        'rejected': rejected.count ?? 0,
        'notVerified': notVerified.count ?? 0,
      };
    } catch (e) {
      debugPrint('❌ Erreur récupération statistiques KYC: $e');
      return {
        'verified': 0,
        'pending': 0,
        'rejected': 0,
        'notVerified': 0,
      };
    }
  }

  // ==================== MÉTHODES PRIVÉES ====================

  /// Notifier les admins d'une nouvelle soumission KYC
  static Future<void> _notifyAdminNewVerification(
    String userId,
    UserType userType,
  ) async {
    try {
      // Récupérer tous les admins
      final adminsSnapshot = await _firestore
          .collection(FirebaseCollections.users)
          .where('userType', isEqualTo: UserType.admin.value)
          .get();

      final userTypeLabel = userType == UserType.vendeur ? 'Vendeur' : 'Livreur';

      // Créer une notification pour chaque admin
      for (final adminDoc in adminsSnapshot.docs) {
        await NotificationService().createNotification(
          userId: adminDoc.id,
          type: 'system',
          title: 'Nouvelle vérification KYC',
          body: 'Un nouveau $userTypeLabel a soumis ses documents pour validation',
          data: {
            'kycUserId': userId,
            'userType': userType.value,
            'action': 'kyc_validation',
          },
        );
      }

      debugPrint('✅ Admins notifiés de la nouvelle soumission KYC');
    } catch (e) {
      debugPrint('⚠️ Erreur notification admins KYC: $e');
    }
  }

  /// Notifier l'utilisateur de la décision KYC
  static Future<void> _notifyUserKYCDecision(
    String userId,
    bool approved,
    String? rejectionReason,
  ) async {
    try {
      final title = approved
          ? 'Vérification approuvée ✅'
          : 'Vérification refusée ❌';

      final message = approved
          ? 'Votre compte a été vérifié avec succès ! Vous pouvez maintenant utiliser toutes les fonctionnalités.'
          : 'Votre vérification a été refusée. Raison: ${rejectionReason ?? "Non spécifiée"}. Vous pouvez soumettre de nouveaux documents.';

      await NotificationService().createNotification(
        userId: userId,
        type: 'system',
        title: title,
        body: message,
        data: {
          'action': 'kyc_decision',
          'approved': approved,
          if (!approved && rejectionReason != null)
            'rejectionReason': rejectionReason,
        },
      );

      debugPrint('✅ Utilisateur $userId notifié de la décision KYC');
    } catch (e) {
      debugPrint('⚠️ Erreur notification utilisateur KYC: $e');
    }
  }
}