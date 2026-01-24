import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/subscription_model.dart';
import '../config/constants.dart';

/// Service de gestion des abonnements vendeurs et niveaux livreurs
class SubscriptionService {
  static final _firestore = FirebaseFirestore.instance;

  // Collections Firestore
  static const String _subscriptionsCollection = 'vendeur_subscriptions'; // Abonnements VENDEURS
  static const String _livreurSubscriptionsCollection =
      'livreur_subscriptions'; // Abonnements LIVREURS (hybride)
  static const String _livreurTiersCollection =
      'livreur_tiers'; // Info niveau LIVREURS (performance tracking)
  static const String _subscriptionPaymentsCollection =
      'subscription_payments'; // Paiements vendeurs
  static const String _livreurSubscriptionPaymentsCollection =
      'livreur_subscription_payments'; // Paiements livreurs

  /// Récupère l'abonnement actif d'un vendeur
  Future<VendeurSubscription?> getVendeurSubscription(String vendeurId) async {
    try {
      debugPrint('📊 Récupération abonnement vendeur: $vendeurId');

      final querySnapshot = await _firestore
          .collection(_subscriptionsCollection)
          .where('vendeurId', isEqualTo: vendeurId)
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return await createBasiqueSubscription(vendeurId);
      }

      final subscription = VendeurSubscription.fromFirestore(querySnapshot.docs.first);
      debugPrint('✅ Abonnement trouvé: ${subscription.tierName}');
      return subscription;
    } catch (e) {
      debugPrint('❌ Erreur récupération abonnement: $e');
      return null;
    }
  }

  /// Crée un abonnement BASIQUE gratuit pour un nouveau vendeur
  Future<VendeurSubscription> createBasiqueSubscription(String vendeurId) async {
    try {
      debugPrint('🆕 Création abonnement BASIQUE pour: $vendeurId');

      final subscription = VendeurSubscription.createBasique(vendeurId);

      // ✅ ACTIVER L'ÉCRITURE FIRESTORE pour que l'admin puisse voir les abonnements
      try {
        final docRef = await _firestore
            .collection(_subscriptionsCollection)
            .add(subscription.toMap())
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                throw TimeoutException('Timeout création abonnement BASIQUE');
              },
            );
        debugPrint('✅ Abonnement BASIQUE créé dans Firestore: ${docRef.id}');
        return subscription.copyWith(id: docRef.id);
      } catch (e) {
        debugPrint('❌ Erreur Firestore, fallback local: $e');
        // Fallback vers abonnement local uniquement en cas d'échec
        final localSubscription = subscription.copyWith(id: 'local_${vendeurId}_basique');
        debugPrint('⚠️ Abonnement BASIQUE créé en local: local_${vendeurId}_basique');
        return localSubscription;
      }
    } catch (e) {
      debugPrint('❌ Erreur création abonnement BASIQUE: $e');
      return VendeurSubscription.createBasique(vendeurId)
          .copyWith(id: 'local_${vendeurId}_basique');
    }
  }

  /// Alias pour créer l'abonnement par défaut d'un vendeur (appelé lors de l'inscription)
  Future<VendeurSubscription> createDefaultVendeurSubscription(String vendeurId) async {
    return await createBasiqueSubscription(vendeurId);
  }

  /// Crée ou met à niveau vers un abonnement PRO ou PREMIUM
  Future<VendeurSubscription> upgradeSubscription({
    required String vendeurId,
    required VendeurSubscriptionTier newTier,
    required String paymentMethod,
    required String transactionId,
  }) async {
    try {
      debugPrint('⬆️ Upgrade abonnement vers ${newTier.name} pour: $vendeurId');

      // Récupérer l'abonnement actuel
      final currentSubscription = await getVendeurSubscription(vendeurId);

      // Annuler l'abonnement actuel si existant ET s'il n'est pas local
      if (currentSubscription != null &&
          currentSubscription.id.isNotEmpty &&
          !currentSubscription.id.startsWith('local_')) {
        try {
          await _firestore.collection(_subscriptionsCollection).doc(currentSubscription.id).update({
            'status': SubscriptionStatus.cancelled.name,
            'endDate': Timestamp.fromDate(DateTime.now()),
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });
          debugPrint('🔄 Ancien abonnement annulé');
        } catch (e) {
          debugPrint('⚠️ Impossible d\'annuler ancien abonnement (probablement local): $e');
        }
      } else if (currentSubscription != null && currentSubscription.id.startsWith('local_')) {
        debugPrint('⚠️ Abonnement local détecté, skip annulation Firestore');
      }

      // Créer le nouvel abonnement
      final now = DateTime.now();
      final nextBillingDate = DateTime(now.year, now.month + 1, now.day);

      final newSubscription = _createSubscriptionForTier(
        vendeurId: vendeurId,
        tier: newTier,
        startDate: now,
        nextBillingDate: nextBillingDate,
      );

      final docRef =
          await _firestore.collection(_subscriptionsCollection).add(newSubscription.toMap());

      // Enregistrer le paiement
      await _recordPayment(
        subscriptionId: docRef.id,
        vendeurId: vendeurId,
        tier: newTier,
        paymentMethod: paymentMethod,
        transactionId: transactionId,
      );

      final createdSubscription = newSubscription.copyWith(id: docRef.id);
      debugPrint('✅ Nouvel abonnement créé: ${docRef.id}');
      return createdSubscription;
    } catch (e) {
      debugPrint('❌ Erreur upgrade abonnement: $e');
      rethrow;
    }
  }

  /// Rétrograde un abonnement (PRO/PREMIUM → BASIQUE)
  Future<VendeurSubscription> downgradeSubscription(String vendeurId) async {
    try {
      debugPrint('⬇️ Downgrade abonnement pour: $vendeurId');

      final currentSubscription = await getVendeurSubscription(vendeurId);

      if (currentSubscription == null) {
        throw Exception('Aucun abonnement actif trouvé');
      }

      // Marquer l'abonnement actuel comme annulé (sauf si local)
      if (!currentSubscription.id.startsWith('local_')) {
        try {
          await _firestore.collection(_subscriptionsCollection).doc(currentSubscription.id).update({
            'status': SubscriptionStatus.cancelled.name,
            'endDate': Timestamp.fromDate(DateTime.now()),
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });
          debugPrint('🔄 Abonnement annulé');
        } catch (e) {
          debugPrint('⚠️ Impossible d\'annuler abonnement (probablement local): $e');
        }
      } else {
        debugPrint('⚠️ Abonnement local détecté, skip annulation Firestore');
      }

      // Créer un abonnement BASIQUE
      return await createBasiqueSubscription(vendeurId);
    } catch (e) {
      debugPrint('❌ Erreur downgrade abonnement: $e');
      rethrow;
    }
  }

  /// Renouvelle un abonnement existant
  Future<bool> renewSubscription({
    required String subscriptionId,
    required String paymentMethod,
    required String transactionId,
  }) async {
    try {
      debugPrint('🔄 Renouvellement abonnement: $subscriptionId');

      final doc = await _firestore.collection(_subscriptionsCollection).doc(subscriptionId).get();

      if (!doc.exists) {
        throw Exception('Abonnement non trouvé');
      }

      final subscription = VendeurSubscription.fromFirestore(doc);
      final now = DateTime.now();
      final nextBillingDate = DateTime(now.year, now.month + 1, now.day);

      await _firestore.collection(_subscriptionsCollection).doc(subscriptionId).update({
        'status': SubscriptionStatus.active.name,
        'nextBillingDate': Timestamp.fromDate(nextBillingDate),
        'updatedAt': Timestamp.fromDate(now),
      });

      // Enregistrer le paiement
      await _recordPayment(
        subscriptionId: subscriptionId,
        vendeurId: subscription.vendeurId,
        tier: subscription.tier,
        paymentMethod: paymentMethod,
        transactionId: transactionId,
      );

      debugPrint('✅ Abonnement renouvelé jusqu\'au: $nextBillingDate');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur renouvellement abonnement: $e');
      return false;
    }
  }

  /// Vérifie et applique les limites d'un vendeur
  Future<bool> checkProductLimit(String vendeurId, int currentProductCount) async {
    try {
      final subscription = await getVendeurSubscription(vendeurId);
      if (subscription == null) return false;

      final canAdd = currentProductCount < subscription.productLimit;
      debugPrint(
          '📊 Vérification limite produits: $currentProductCount/${subscription.productLimit} - Peut ajouter: $canAdd');
      return canAdd;
    } catch (e) {
      debugPrint('❌ Erreur vérification limite: $e');
      return false;
    }
  }

  /// Récupère le taux de commission actuel d'un vendeur
  Future<double> getVendeurCommissionRate(String vendeurId) async {
    try {
      final subscription = await getVendeurSubscription(vendeurId);
      return subscription?.commissionRate ?? 0.10;
    } catch (e) {
      debugPrint('❌ Erreur récupération taux commission: $e');
      return 0.10;
    }
  }

  // ==================== ABONNEMENTS LIVREURS (Hybride: Performance + Paiement) ====================

  /// NOTE: Modèle HYBRIDE pour livreurs:
  /// 1. STARTER: Gratuit automatique (commission 25%)
  /// 2. PRO: Débloqué à 50 livraisons + 4.0★, puis PAYANT 10k/mois (commission 20%)
  /// 3. PREMIUM: Débloqué à 200 livraisons + 4.5★, puis PAYANT 30k/mois (commission 15%)

  /// Récupère l'abonnement actif d'un livreur
  Future<LivreurSubscription?> getLivreurSubscription(String livreurId) async {
    try {
      debugPrint('📊 Récupération abonnement livreur: $livreurId');

      // ✅ Ajouter timeout pour éviter blocage sur Web (Firestore offline)
      final querySnapshot = await _firestore
          .collection(_livreurSubscriptionsCollection)
          .where('livreurId', isEqualTo: livreurId)
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get()
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('⏱️ Timeout récupération abonnement, création STARTER');
          throw TimeoutException('Timeout récupération abonnement livreur');
        },
      );

      if (querySnapshot.docs.isEmpty) {
        debugPrint('⚠️ Aucun abonnement trouvé, création STARTER par défaut');
        return await createStarterLivreurSubscription(livreurId);
      }

      final subscription = LivreurSubscription.fromFirestore(querySnapshot.docs.first);
      debugPrint('✅ Abonnement livreur trouvé: ${subscription.tierName}');
      return subscription;
    } catch (e) {
      debugPrint('❌ Erreur récupération abonnement livreur: $e');
      // ✅ En cas de timeout, créer un abonnement STARTER par défaut
      if (e is TimeoutException || e.toString().contains('client is offline')) {
        debugPrint('🔄 Création abonnement STARTER par défaut (mode offline)');
        return await createStarterLivreurSubscription(livreurId);
      }
      return null;
    }
  }

  /// Crée un abonnement STARTER gratuit pour un nouveau livreur
  Future<LivreurSubscription> createStarterLivreurSubscription(String livreurId) async {
    try {
      debugPrint('🆕 Création abonnement STARTER pour livreur: $livreurId');

      final subscription = LivreurSubscription.createStarter(livreurId);

      // ✅ ACTIVER L'ÉCRITURE FIRESTORE pour que l'admin puisse voir les abonnements
      try {
        final docRef = await _firestore
            .collection('livreur_subscriptions')
            .add(subscription.toMap())
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                throw TimeoutException('Timeout création abonnement STARTER');
              },
            );
        debugPrint('✅ Abonnement STARTER créé dans Firestore: ${docRef.id}');
        return subscription.copyWith(id: docRef.id);
      } catch (e) {
        debugPrint('❌ Erreur Firestore, fallback local: $e');
        // Fallback vers abonnement local uniquement en cas d'échec
        final localSubscription = subscription.copyWith(id: 'local_${livreurId}_starter');
        debugPrint('⚠️ Abonnement STARTER créé en local: local_${livreurId}_starter');
        return localSubscription;
      }
    } catch (e) {
      debugPrint('❌ Erreur création abonnement STARTER: $e');
      return LivreurSubscription.createStarter(livreurId)
          .copyWith(id: 'local_${livreurId}_starter');
    }
  }

  /// Upgrade vers PRO ou PREMIUM (nécessite paiement + avoir débloqué le niveau)
  Future<LivreurSubscription> upgradeLivreurSubscription({
    required String livreurId,
    required LivreurTier newTier,
    required String paymentMethod,
    required String transactionId,
    required int currentDeliveries,
    required double currentRating,
  }) async {
    try {
      debugPrint('⬆️ Upgrade livreur vers ${newTier.name} pour: $livreurId');

      // Vérifier que le livreur a atteint les critères
      final requirements = _getLivreurTierRequirements(newTier);
      if (currentDeliveries < requirements['deliveries'] ||
          currentRating < requirements['rating']) {
        throw Exception(
            'Critères non atteints: ${requirements['deliveries']} livraisons et ${requirements['rating']}★ requis');
      }

      // Récupérer l'abonnement actuel
      final currentSubscription = await getLivreurSubscription(livreurId);

      // Annuler l'abonnement actuel si existant
      if (currentSubscription != null && currentSubscription.id.isNotEmpty) {
        await _firestore
            .collection(_livreurSubscriptionsCollection)
            .doc(currentSubscription.id)
            .update({
          'status': SubscriptionStatus.cancelled.name,
          'endDate': Timestamp.fromDate(DateTime.now()),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
        debugPrint('🔄 Ancien abonnement annulé');
      }

      // Créer le nouvel abonnement
      final now = DateTime.now();
      final nextBillingDate = DateTime(now.year, now.month + 1, now.day);

      final newSubscription = _createLivreurSubscriptionForTier(
        livreurId: livreurId,
        tier: newTier,
        startDate: now,
        nextBillingDate: nextBillingDate,
        currentDeliveries: currentDeliveries,
        currentRating: currentRating,
      );

      final docRef =
          await _firestore.collection(_livreurSubscriptionsCollection).add(newSubscription.toMap());

      // Enregistrer le paiement
      await _recordLivreurPayment(
        subscriptionId: docRef.id,
        livreurId: livreurId,
        tier: newTier,
        paymentMethod: paymentMethod,
        transactionId: transactionId,
      );

      final createdSubscription = newSubscription.copyWith(id: docRef.id);
      debugPrint('✅ Nouvel abonnement livreur créé: ${docRef.id}');
      return createdSubscription;
    } catch (e) {
      debugPrint('❌ Erreur upgrade abonnement livreur: $e');
      rethrow;
    }
  }

  /// Rétrograde un abonnement livreur (PRO/PREMIUM → STARTER)
  Future<LivreurSubscription> downgradeLivreurSubscription(String livreurId) async {
    try {
      debugPrint('⬇️ Downgrade abonnement livreur pour: $livreurId');

      final currentSubscription = await getLivreurSubscription(livreurId);

      if (currentSubscription == null) {
        throw Exception('Aucun abonnement actif trouvé');
      }

      // Marquer l'abonnement actuel comme annulé
      await _firestore
          .collection(_livreurSubscriptionsCollection)
          .doc(currentSubscription.id)
          .update({
        'status': SubscriptionStatus.cancelled.name,
        'endDate': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Créer un abonnement STARTER
      return await createStarterLivreurSubscription(livreurId);
    } catch (e) {
      debugPrint('❌ Erreur downgrade abonnement livreur: $e');
      rethrow;
    }
  }

  /// Renouvelle un abonnement livreur existant (PRO ou PREMIUM)
  Future<bool> renewLivreurSubscription({
    required String subscriptionId,
    required String paymentMethod,
    required String transactionId,
  }) async {
    try {
      debugPrint('🔄 Renouvellement abonnement livreur: $subscriptionId');

      final doc =
          await _firestore.collection(_livreurSubscriptionsCollection).doc(subscriptionId).get();

      if (!doc.exists) {
        throw Exception('Abonnement non trouvé');
      }

      final subscription = LivreurSubscription.fromFirestore(doc);
      final now = DateTime.now();
      final nextBillingDate = DateTime(now.year, now.month + 1, now.day);

      await _firestore.collection(_livreurSubscriptionsCollection).doc(subscriptionId).update({
        'status': SubscriptionStatus.active.name,
        'nextBillingDate': Timestamp.fromDate(nextBillingDate),
        'updatedAt': Timestamp.fromDate(now),
      });

      // Enregistrer le paiement
      await _recordLivreurPayment(
        subscriptionId: subscriptionId,
        livreurId: subscription.livreurId,
        tier: subscription.tier,
        paymentMethod: paymentMethod,
        transactionId: transactionId,
      );

      debugPrint('✅ Abonnement livreur renouvelé jusqu\'au: $nextBillingDate');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur renouvellement abonnement livreur: $e');
      return false;
    }
  }

  /// Met à jour les stats de performance d'un livreur dans son abonnement
  Future<LivreurSubscription?> updateLivreurPerformanceStats({
    required String livreurId,
    required int totalDeliveries,
    required double averageRating,
  }) async {
    try {
      debugPrint('📊 Mise à jour stats performance livreur: $livreurId');

      final subscription = await getLivreurSubscription(livreurId);
      if (subscription == null) return null;

      // Vérifier si de nouveaux niveaux sont débloqués
      LivreurTierUnlockStatus newUnlockStatus = subscription.unlockStatus;

      if (subscription.tier == LivreurTier.starter) {
        // Vérifier déblocage PRO
        if (totalDeliveries >= 50 && averageRating >= 4.0) {
          newUnlockStatus = LivreurTierUnlockStatus.unlocked;
          debugPrint('🎉 Niveau PRO débloqué ! Le livreur peut maintenant souscrire.');
        }
      } else if (subscription.tier == LivreurTier.pro) {
        // Vérifier déblocage PREMIUM
        if (totalDeliveries >= 200 && averageRating >= 4.5) {
          newUnlockStatus = LivreurTierUnlockStatus.unlocked;
          debugPrint('🎉 Niveau PREMIUM débloqué ! Le livreur peut maintenant souscrire.');
        }
      }

      final updatedSubscription = subscription.copyWith(
        currentDeliveries: totalDeliveries,
        currentRating: averageRating,
        unlockStatus: newUnlockStatus,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(_livreurSubscriptionsCollection)
          .doc(subscription.id)
          .update(updatedSubscription.toMap());

      debugPrint('✅ Stats performance livreur mises à jour');
      return updatedSubscription;
    } catch (e) {
      debugPrint('❌ Erreur mise à jour stats performance: $e');
      return null;
    }
  }

  /// Récupère le taux de commission actuel d'un livreur
  Future<double> getLivreurCommissionRate(String livreurId) async {
    try {
      final subscription = await getLivreurSubscription(livreurId);
      return subscription?.commissionRate ?? 0.25;
    } catch (e) {
      debugPrint('❌ Erreur récupération taux commission livreur: $e');
      return 0.25;
    }
  }

  /// Récupère l'historique des paiements d'un livreur
  Future<List<LivreurSubscriptionPayment>> getLivreurPaymentHistory(String livreurId) async {
    try {
      debugPrint('📊 Récupération historique paiements livreur: $livreurId');

      final querySnapshot = await _firestore
          .collection(_livreurSubscriptionPaymentsCollection)
          .where('livreurId', isEqualTo: livreurId)
          .orderBy('paymentDate', descending: true)
          .limit(50)
          .get();

      final payments =
          querySnapshot.docs.map((doc) => LivreurSubscriptionPayment.fromFirestore(doc)).toList();

      debugPrint('✅ ${payments.length} paiements livreur récupérés');
      return payments;
    } catch (e) {
      debugPrint('❌ Erreur récupération historique livreur: $e');
      return [];
    }
  }

  /// Stream de l'abonnement d'un livreur (pour mises à jour en temps réel)
  Stream<LivreurSubscription?> livreurSubscriptionStream(String livreurId) {
    return _firestore
        .collection(_livreurSubscriptionsCollection)
        .where('livreurId', isEqualTo: livreurId)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return LivreurSubscription.fromFirestore(snapshot.docs.first);
    });
  }

  // ==================== NIVEAUX LIVREURS (Performance tracking) ====================

  /// Récupère les informations de niveau d'un livreur
  Future<LivreurTierInfo?> getLivreurTier(String livreurId) async {
    try {
      debugPrint('📊 Récupération niveau livreur: $livreurId');

      final querySnapshot = await _firestore
          .collection(_livreurTiersCollection)
          .where('livreurId', isEqualTo: livreurId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        debugPrint('⚠️ Aucun niveau trouvé, création STARTER par défaut');
        return await createStarterTier(livreurId);
      }

      final tierInfo = LivreurTierInfo.fromFirestore(querySnapshot.docs.first);
      debugPrint('✅ Niveau trouvé: ${tierInfo.tierName}');
      return tierInfo;
    } catch (e) {
      debugPrint('❌ Erreur récupération niveau livreur: $e');
      return null;
    }
  }

  /// Crée un niveau STARTER pour un nouveau livreur
  Future<LivreurTierInfo> createStarterTier(String livreurId) async {
    try {
      debugPrint('🆕 Création niveau STARTER pour: $livreurId');

      final tierInfo = LivreurTierInfo.createStarter(livreurId);
      final docRef = await _firestore.collection(_livreurTiersCollection).add(tierInfo.toMap());

      final createdTier = tierInfo.copyWith(id: docRef.id);
      debugPrint('✅ Niveau STARTER créé: ${docRef.id}');
      return createdTier;
    } catch (e) {
      debugPrint('❌ Erreur création niveau STARTER: $e');
      rethrow;
    }
  }

  /// Met à jour les stats d'un livreur et vérifie les upgrades automatiques
  Future<LivreurTierInfo?> updateLivreurStats({
    required String livreurId,
    required int totalDeliveries,
    required double averageRating,
  }) async {
    try {
      debugPrint('📊 Mise à jour stats livreur: $livreurId');

      final tierInfo = await getLivreurTier(livreurId);
      if (tierInfo == null) return null;

      // Vérifier si upgrade automatique possible
      LivreurTier? newTier;
      double? newCommissionRate;

      if (tierInfo.currentTier == LivreurTier.starter &&
          totalDeliveries >= 50 &&
          averageRating >= 4.0) {
        newTier = LivreurTier.pro;
        newCommissionRate = 0.20;
        debugPrint('🎉 Upgrade automatique vers PRO !');
      } else if (tierInfo.currentTier == LivreurTier.pro &&
          totalDeliveries >= 200 &&
          averageRating >= 4.5) {
        newTier = LivreurTier.premium;
        newCommissionRate = 0.15;
        debugPrint('🎉 Upgrade automatique vers PREMIUM !');
      }

      final updatedTierInfo = tierInfo.copyWith(
        totalDeliveries: totalDeliveries,
        averageRating: averageRating,
        currentTier: newTier ?? tierInfo.currentTier,
        currentCommissionRate: newCommissionRate ?? tierInfo.currentCommissionRate,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(_livreurTiersCollection)
          .doc(tierInfo.id)
          .update(updatedTierInfo.toMap());

      debugPrint('✅ Stats livreur mises à jour');
      return updatedTierInfo;
    } catch (e) {
      debugPrint('❌ Erreur mise à jour stats livreur: $e');
      return null;
    }
  }

  /// Récupère l'historique des paiements d'un vendeur
  Future<List<SubscriptionPayment>> getPaymentHistory(String vendeurId) async {
    try {
      debugPrint('📊 Récupération historique paiements: $vendeurId');

      // ✅ Ajouter timeout pour éviter blocage sur Web (Firestore offline)
      final querySnapshot = await _firestore
          .collection(_subscriptionPaymentsCollection)
          .where('vendeurId', isEqualTo: vendeurId)
          .orderBy('paymentDate', descending: true)
          .limit(50)
          .get()
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('⏱️ Timeout récupération historique, retour liste vide');
          throw TimeoutException('Timeout récupération historique paiements');
        },
      );

      final payments =
          querySnapshot.docs.map((doc) => SubscriptionPayment.fromFirestore(doc)).toList();

      debugPrint('✅ ${payments.length} paiements récupérés');
      return payments;
    } catch (e) {
      debugPrint('❌ Erreur récupération historique: $e');
      // ✅ Retourner liste vide en cas de timeout ou erreur
      return [];
    }
  }

  /// Stream de l'abonnement d'un vendeur (pour mises à jour en temps réel)
  Stream<VendeurSubscription?> subscriptionStream(String vendeurId) {
    return _firestore
        .collection(_subscriptionsCollection)
        .where('vendeurId', isEqualTo: vendeurId)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return VendeurSubscription.fromFirestore(snapshot.docs.first);
    });
  }

  /// Stream du niveau d'un livreur
  Stream<LivreurTierInfo?> livreurTierStream(String livreurId) {
    return _firestore
        .collection(_livreurTiersCollection)
        .where('livreurId', isEqualTo: livreurId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return LivreurTierInfo.fromFirestore(snapshot.docs.first);
    });
  }

  // ==================== MÉTHODES PRIVÉES ====================

  /// Crée un abonnement selon le tier
  VendeurSubscription _createSubscriptionForTier({
    required String vendeurId,
    required VendeurSubscriptionTier tier,
    required DateTime startDate,
    required DateTime nextBillingDate,
  }) {
    final now = DateTime.now();

    switch (tier) {
      case VendeurSubscriptionTier.pro:
        return VendeurSubscription(
          id: '',
          vendeurId: vendeurId,
          tier: tier,
          status: SubscriptionStatus.active,
          startDate: startDate,
          nextBillingDate: nextBillingDate,
          monthlyPrice: 5000,
          productLimit: 100,
          commissionRate: 0.10,
          hasAIAgent: true,
          aiModel: 'gpt-3.5-turbo',
          aiMessagesPerDay: 50,
          createdAt: now,
          updatedAt: now,
        );

      case VendeurSubscriptionTier.premium:
        return VendeurSubscription(
          id: '',
          vendeurId: vendeurId,
          tier: tier,
          status: SubscriptionStatus.active,
          startDate: startDate,
          nextBillingDate: nextBillingDate,
          monthlyPrice: 10000,
          productLimit: 999999, // Illimité
          commissionRate: 0.07,
          hasAIAgent: true,
          aiModel: 'gpt-4',
          aiMessagesPerDay: 200,
          createdAt: now,
          updatedAt: now,
        );

      case VendeurSubscriptionTier.basique:
        return VendeurSubscription.createBasique(vendeurId);
    }
  }

  /// Enregistre un paiement d'abonnement vendeur
  Future<void> _recordPayment({
    required String subscriptionId,
    required String vendeurId,
    required VendeurSubscriptionTier tier,
    required String paymentMethod,
    required String transactionId,
  }) async {
    try {
      final payment = SubscriptionPayment(
        id: '',
        subscriptionId: subscriptionId,
        vendeurId: vendeurId,
        amount: tier == VendeurSubscriptionTier.pro
            ? 5000
            : tier == VendeurSubscriptionTier.premium
                ? 10000
                : 0,
        paymentMethod: paymentMethod,
        status: 'completed',
        paymentDate: DateTime.now(),
        tier: tier,
        transactionId: transactionId,
        createdAt: DateTime.now(),
      );

      await _firestore.collection(_subscriptionPaymentsCollection).add(payment.toMap());
      debugPrint('✅ Paiement enregistré: $transactionId');
    } catch (e) {
      debugPrint('❌ Erreur enregistrement paiement: $e');
    }
  }

  /// Crée un abonnement livreur selon le tier
  LivreurSubscription _createLivreurSubscriptionForTier({
    required String livreurId,
    required LivreurTier tier,
    required DateTime startDate,
    required DateTime nextBillingDate,
    required int currentDeliveries,
    required double currentRating,
  }) {
    final now = DateTime.now();
    final requirements = _getLivreurTierRequirements(tier);

    switch (tier) {
      case LivreurTier.pro:
        return LivreurSubscription(
          id: '',
          livreurId: livreurId,
          tier: tier,
          status: SubscriptionStatus.active,
          startDate: startDate,
          nextBillingDate: nextBillingDate,
          monthlyPrice: 10000,
          commissionRate: 0.20,
          hasPriority: true,
          has24x7Support: false,
          requiredDeliveries: requirements['deliveries'] as int,
          requiredRating: requirements['rating'] as double,
          unlockStatus: LivreurTierUnlockStatus.subscribed,
          currentDeliveries: currentDeliveries,
          currentRating: currentRating,
          createdAt: now,
          updatedAt: now,
        );

      case LivreurTier.premium:
        return LivreurSubscription(
          id: '',
          livreurId: livreurId,
          tier: tier,
          status: SubscriptionStatus.active,
          startDate: startDate,
          nextBillingDate: nextBillingDate,
          monthlyPrice: 30000,
          commissionRate: 0.15,
          hasPriority: true,
          has24x7Support: true,
          requiredDeliveries: requirements['deliveries'] as int,
          requiredRating: requirements['rating'] as double,
          unlockStatus: LivreurTierUnlockStatus.subscribed,
          currentDeliveries: currentDeliveries,
          currentRating: currentRating,
          createdAt: now,
          updatedAt: now,
        );

      case LivreurTier.starter:
        return LivreurSubscription.createStarter(livreurId);
    }
  }

  /// Obtient les critères requis pour un niveau livreur
  Map<String, dynamic> _getLivreurTierRequirements(LivreurTier tier) {
    switch (tier) {
      case LivreurTier.starter:
        return {'deliveries': 0, 'rating': 0.0};
      case LivreurTier.pro:
        return {'deliveries': 50, 'rating': 4.0};
      case LivreurTier.premium:
        return {'deliveries': 200, 'rating': 4.5};
    }
  }

  /// Enregistre un paiement d'abonnement livreur
  Future<void> _recordLivreurPayment({
    required String subscriptionId,
    required String livreurId,
    required LivreurTier tier,
    required String paymentMethod,
    required String transactionId,
  }) async {
    try {
      final payment = LivreurSubscriptionPayment(
        id: '',
        subscriptionId: subscriptionId,
        livreurId: livreurId,
        amount: tier == LivreurTier.pro
            ? 10000
            : tier == LivreurTier.premium
                ? 30000
                : 0,
        paymentMethod: paymentMethod,
        status: 'completed',
        paymentDate: DateTime.now(),
        tier: tier,
        transactionId: transactionId,
        createdAt: DateTime.now(),
      );

      await _firestore.collection(_livreurSubscriptionPaymentsCollection).add(payment.toMap());
      debugPrint('✅ Paiement livreur enregistré: $transactionId');
    } catch (e) {
      debugPrint('❌ Erreur enregistrement paiement livreur: $e');
    }
  }

  // ==================== MÉTHODES DE MIGRATION ====================

  /// Crée les abonnements manquants pour tous les vendeurs existants
  Future<void> createMissingVendeurSubscriptions() async {
    try {
      debugPrint('🔄 Création abonnements manquants pour vendeurs...');

      // Récupérer tous les vendeurs
      final vendeurs = await _firestore
          .collection(FirebaseCollections.users)
          .where('userType', isEqualTo: 'vendeur')
          .get();

      int created = 0;
      for (var vendeurDoc in vendeurs.docs) {
        final vendeurId = vendeurDoc.id;

        // Vérifier si l'abonnement existe déjà
        final existingSub = await _firestore
            .collection(_subscriptionsCollection)
            .where('vendeurId', isEqualTo: vendeurId)
            .limit(1)
            .get();

        if (existingSub.docs.isEmpty) {
          // Créer abonnement BASIQUE
          final subscription = VendeurSubscription.createBasique(vendeurId);
          await _firestore
              .collection(_subscriptionsCollection)
              .add(subscription.toMap());
          created++;
          debugPrint('✅ Abonnement créé pour vendeur: $vendeurId');
        }
      }

      debugPrint('✅ Migration terminée: $created abonnements vendeurs créés');
    } catch (e) {
      debugPrint('❌ Erreur migration abonnements vendeurs: $e');
    }
  }

  /// Crée les abonnements manquants pour tous les livreurs existants
  Future<void> createMissingLivreurSubscriptions() async {
    try {
      debugPrint('🔄 Création abonnements manquants pour livreurs...');

      // Récupérer tous les livreurs
      final livreurs = await _firestore
          .collection(FirebaseCollections.users)
          .where('userType', isEqualTo: 'livreur')
          .get();

      int created = 0;
      for (var livreurDoc in livreurs.docs) {
        final livreurId = livreurDoc.id;

        // Vérifier si l'abonnement existe déjà
        final existingSub = await _firestore
            .collection('livreur_subscriptions')
            .where('livreurId', isEqualTo: livreurId)
            .limit(1)
            .get();

        if (existingSub.docs.isEmpty) {
          // Créer abonnement STARTER
          final subscription = LivreurSubscription.createStarter(livreurId);
          await _firestore
              .collection('livreur_subscriptions')
              .add(subscription.toMap());
          created++;
          debugPrint('✅ Abonnement créé pour livreur: $livreurId');
        }
      }

      debugPrint('✅ Migration terminée: $created abonnements livreurs créés');
    } catch (e) {
      debugPrint('❌ Erreur migration abonnements livreurs: $e');
    }
  }

  /// Crée tous les abonnements manquants (vendeurs + livreurs)
  Future<void> createAllMissingSubscriptions() async {
    debugPrint('🔄 Début migration complète des abonnements...');
    await createMissingVendeurSubscriptions();
    await createMissingLivreurSubscriptions();
    debugPrint('✅ Migration complète terminée !');
  }

  // ==================== MÉTHODES DE TEST ====================

  /// Crée des données de test pour les abonnements (à utiliser en développement uniquement)
  Future<void> createTestData() async {
    if (!kDebugMode) {
      debugPrint('⚠️ createTestData() disponible uniquement en mode debug');
      return;
    }

    try {
      debugPrint('🧪 Création données de test...');

      // Test vendeur BASIQUE
      await createBasiqueSubscription('test_vendeur_basique');

      // Test vendeur PRO
      await upgradeSubscription(
        vendeurId: 'test_vendeur_pro',
        newTier: VendeurSubscriptionTier.pro,
        paymentMethod: 'Orange Money',
        transactionId: 'TEST_OM_${DateTime.now().millisecondsSinceEpoch}',
      );

      // Test vendeur PREMIUM
      await upgradeSubscription(
        vendeurId: 'test_vendeur_premium',
        newTier: VendeurSubscriptionTier.premium,
        paymentMethod: 'Wave',
        transactionId: 'TEST_WAVE_${DateTime.now().millisecondsSinceEpoch}',
      );

      // Test livreur STARTER
      await createStarterTier('test_livreur_starter');

      // Test livreur PRO (51 livraisons, 4.2★)
      await createStarterTier('test_livreur_pro');
      await updateLivreurStats(
        livreurId: 'test_livreur_pro',
        totalDeliveries: 51,
        averageRating: 4.2,
      );

      // Test livreur PREMIUM (205 livraisons, 4.7★)
      await createStarterTier('test_livreur_premium');
      await updateLivreurStats(
        livreurId: 'test_livreur_premium',
        totalDeliveries: 205,
        averageRating: 4.7,
      );

      debugPrint('✅ Données de test créées avec succès !');
      debugPrint('   - 3 vendeurs (BASIQUE, PRO, PREMIUM)');
      debugPrint('   - 3 livreurs (STARTER, PRO, PREMIUM)');
    } catch (e) {
      debugPrint('❌ Erreur création données de test: $e');
    }
  }

  /// Nettoie les données de test
  Future<void> cleanTestData() async {
    if (!kDebugMode) {
      debugPrint('⚠️ cleanTestData() disponible uniquement en mode debug');
      return;
    }

    try {
      debugPrint('🧹 Nettoyage données de test...');

      // Supprimer abonnements de test
      final subscriptions = await _firestore.collection(_subscriptionsCollection).where('vendeurId',
          whereIn: ['test_vendeur_basique', 'test_vendeur_pro', 'test_vendeur_premium']).get();

      for (var doc in subscriptions.docs) {
        await doc.reference.delete();
      }

      // Supprimer tiers de test
      final tiers = await _firestore.collection(_livreurTiersCollection).where('livreurId',
          whereIn: ['test_livreur_starter', 'test_livreur_pro', 'test_livreur_premium']).get();

      for (var doc in tiers.docs) {
        await doc.reference.delete();
      }

      debugPrint('✅ Données de test nettoyées');
    } catch (e) {
      debugPrint('❌ Erreur nettoyage données de test: $e');
    }
  }
}
