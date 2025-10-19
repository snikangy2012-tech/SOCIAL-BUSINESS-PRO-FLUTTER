import 'package:flutter/foundation.dart';
import '../services/subscription_service.dart';
import '../models/subscription_model.dart';

/// Helper pour tester le système d'abonnement en développement
/// ⚠️ NE PAS UTILISER EN PRODUCTION
class SubscriptionTestHelper {
  final SubscriptionService _subscriptionService = SubscriptionService();

  /// Crée tous les utilisateurs de test avec différents plans d'abonnement
  Future<void> createAllTestData() async {
    if (!kDebugMode) {
      debugPrint('❌ createAllTestData() disponible uniquement en mode debug');
      return;
    }

    debugPrint('🧪 ======================================');
    debugPrint('🧪 CRÉATION DONNÉES DE TEST ABONNEMENTS');
    debugPrint('🧪 ======================================');

    try {
      await _subscriptionService.createTestData();

      debugPrint('');
      debugPrint('✅ DONNÉES DE TEST CRÉÉES AVEC SUCCÈS !');
      debugPrint('');
      debugPrint('📋 UTILISATEURS DE TEST CRÉÉS:');
      debugPrint('');
      debugPrint('🔹 VENDEURS:');
      debugPrint('   • test_vendeur_basique - Plan BASIQUE (gratuit)');
      debugPrint('   • test_vendeur_pro - Plan PRO (5,000 FCFA/mois)');
      debugPrint('   • test_vendeur_premium - Plan PREMIUM (10,000 FCFA/mois)');
      debugPrint('');
      debugPrint('🔹 LIVREURS:');
      debugPrint('   • test_livreur_starter - Niveau STARTER (commission 25%)');
      debugPrint('   • test_livreur_pro - Niveau PRO (commission 20%)');
      debugPrint('   • test_livreur_premium - Niveau PREMIUM (commission 15%)');
      debugPrint('');
      debugPrint('💡 POUR TESTER:');
      debugPrint('   1. Utilisez ces IDs dans vos tests');
      debugPrint('   2. Appelez getVendeurSubscription() ou getLivreurTier()');
      debugPrint('   3. Testez les upgrades et downgrades');
      debugPrint('');
    } catch (e) {
      debugPrint('❌ Erreur création données de test: $e');
    }
  }

  /// Nettoie toutes les données de test
  Future<void> cleanAllTestData() async {
    if (!kDebugMode) {
      debugPrint('❌ cleanAllTestData() disponible uniquement en mode debug');
      return;
    }

    debugPrint('🧹 Nettoyage des données de test...');
    try {
      await _subscriptionService.cleanTestData();
      debugPrint('✅ Données de test nettoyées');
    } catch (e) {
      debugPrint('❌ Erreur nettoyage: $e');
    }
  }

  /// Affiche l'état d'un abonnement vendeur
  Future<void> displayVendeurSubscription(String vendeurId) async {
    debugPrint('');
    debugPrint('📊 ========== ABONNEMENT VENDEUR ==========');
    debugPrint('📊 Vendeur ID: $vendeurId');

    try {
      final subscription = await _subscriptionService.getVendeurSubscription(vendeurId);

      if (subscription == null) {
        debugPrint('❌ Aucun abonnement trouvé');
        return;
      }

      debugPrint('');
      debugPrint('✅ PLAN: ${subscription.tierName}');
      debugPrint('   💰 Prix: ${subscription.monthlyPrice.toStringAsFixed(0)} FCFA/mois');
      debugPrint('   📦 Limite produits: ${subscription.productLimit == 999999 ? 'ILLIMITÉ' : subscription.productLimit}');
      debugPrint('   💳 Commission: ${(subscription.commissionRate * 100).toStringAsFixed(0)}%');
      debugPrint('   🤖 Agent AI: ${subscription.hasAIAgent ? '✅ ${subscription.aiModel} (${subscription.aiMessagesPerDay} msgs/jour)' : '❌ Non'}');
      debugPrint('   📊 Statut: ${subscription.status.name.toUpperCase()}');

      if (subscription.nextBillingDate != null) {
        debugPrint('   📅 Prochain paiement: ${subscription.nextBillingDate}');
        debugPrint('   ⏳ Jours restants: ${subscription.daysRemaining ?? 0}');
      }

      debugPrint('   📅 Créé le: ${subscription.createdAt}');
      debugPrint('');
    } catch (e) {
      debugPrint('❌ Erreur: $e');
    }
  }

  /// Affiche l'état d'un niveau livreur
  Future<void> displayLivreurTier(String livreurId) async {
    debugPrint('');
    debugPrint('📊 ========== NIVEAU LIVREUR ==========');
    debugPrint('📊 Livreur ID: $livreurId');

    try {
      final tierInfo = await _subscriptionService.getLivreurTier(livreurId);

      if (tierInfo == null) {
        debugPrint('❌ Aucun niveau trouvé');
        return;
      }

      debugPrint('');
      debugPrint('✅ NIVEAU: ${tierInfo.tierName}');
      debugPrint('   💳 Commission: ${(tierInfo.currentCommissionRate * 100).toStringAsFixed(0)}%');
      debugPrint('   📦 Livraisons totales: ${tierInfo.totalDeliveries}');
      debugPrint('   ⭐ Note moyenne: ${tierInfo.averageRating.toStringAsFixed(1)}/5');

      if (tierInfo.nextTier != null) {
        debugPrint('   ⬆️ Prochain niveau: ${tierInfo.nextTier!.name.toUpperCase()}');
        debugPrint('   📦 Livraisons restantes: ${tierInfo.deliveriesUntilNextTier}');
        debugPrint('   ⭐ Note requise: ${tierInfo.ratingRequiredForNextTier}');
      } else {
        debugPrint('   🏆 NIVEAU MAXIMUM ATTEINT !');
      }

      debugPrint('   📅 Créé le: ${tierInfo.createdAt}');
      debugPrint('');
    } catch (e) {
      debugPrint('❌ Erreur: $e');
    }
  }

  /// Test complet du flux vendeur
  Future<void> testVendeurFlow() async {
    if (!kDebugMode) return;

    debugPrint('');
    debugPrint('🧪 ========================================');
    debugPrint('🧪 TEST FLUX COMPLET VENDEUR');
    debugPrint('🧪 ========================================');

    const testVendeurId = 'test_flow_vendeur_${1234567890}';

    try {
      // 1. Créer abonnement BASIQUE
      debugPrint('');
      debugPrint('1️⃣ Création abonnement BASIQUE...');
      final basique = await _subscriptionService.createBasiqueSubscription(testVendeurId);
      debugPrint('   ✅ Abonnement BASIQUE créé: ${basique.id}');
      await displayVendeurSubscription(testVendeurId);

      // 2. Upgrade vers PRO
      debugPrint('2️⃣ Upgrade vers PRO...');
      await _subscriptionService.upgradeSubscription(
        vendeurId: testVendeurId,
        newTier: VendeurSubscriptionTier.pro,
        paymentMethod: 'Orange Money',
        transactionId: 'TEST_OM_PRO_${DateTime.now().millisecondsSinceEpoch}',
      );
      debugPrint('   ✅ Upgrade PRO effectué');
      await displayVendeurSubscription(testVendeurId);

      // 3. Upgrade vers PREMIUM
      debugPrint('3️⃣ Upgrade vers PREMIUM...');
      await _subscriptionService.upgradeSubscription(
        vendeurId: testVendeurId,
        newTier: VendeurSubscriptionTier.premium,
        paymentMethod: 'Wave',
        transactionId: 'TEST_WAVE_PREMIUM_${DateTime.now().millisecondsSinceEpoch}',
      );
      debugPrint('   ✅ Upgrade PREMIUM effectué');
      await displayVendeurSubscription(testVendeurId);

      // 4. Test limites
      debugPrint('4️⃣ Test vérification limite produits...');
      final canAdd = await _subscriptionService.checkProductLimit(testVendeurId, 50);
      debugPrint('   ✅ Peut ajouter 50 produits: ${canAdd ? 'OUI' : 'NON'}');

      // 5. Récupérer taux commission
      debugPrint('5️⃣ Test taux de commission...');
      final commissionRate = await _subscriptionService.getVendeurCommissionRate(testVendeurId);
      debugPrint('   ✅ Taux de commission: ${(commissionRate * 100).toStringAsFixed(0)}%');

      // 6. Downgrade vers BASIQUE
      debugPrint('6️⃣ Downgrade vers BASIQUE...');
      await _subscriptionService.downgradeSubscription(testVendeurId);
      debugPrint('   ✅ Downgrade effectué');
      await displayVendeurSubscription(testVendeurId);

      debugPrint('');
      debugPrint('✅ TEST FLUX VENDEUR TERMINÉ AVEC SUCCÈS !');
      debugPrint('');
    } catch (e) {
      debugPrint('❌ Erreur test flux vendeur: $e');
    }
  }

  /// Test complet du flux livreur
  Future<void> testLivreurFlow() async {
    if (!kDebugMode) return;

    debugPrint('');
    debugPrint('🧪 ========================================');
    debugPrint('🧪 TEST FLUX COMPLET LIVREUR');
    debugPrint('🧪 ========================================');

    const testLivreurId = 'test_flow_livreur_${1234567890}';

    try {
      // 1. Créer niveau STARTER
      debugPrint('');
      debugPrint('1️⃣ Création niveau STARTER...');
      final starter = await _subscriptionService.createStarterTier(testLivreurId);
      debugPrint('   ✅ Niveau STARTER créé: ${starter.id}');
      await displayLivreurTier(testLivreurId);

      // 2. Simuler progression (pas assez pour upgrade)
      debugPrint('2️⃣ Mise à jour stats (30 livraisons, 3.8★)...');
      await _subscriptionService.updateLivreurStats(
        livreurId: testLivreurId,
        totalDeliveries: 30,
        averageRating: 3.8,
      );
      debugPrint('   ✅ Stats mises à jour (pas d\'upgrade)');
      await displayLivreurTier(testLivreurId);

      // 3. Atteindre niveau PRO
      debugPrint('3️⃣ Mise à jour stats pour upgrade PRO (55 livraisons, 4.2★)...');
      await _subscriptionService.updateLivreurStats(
        livreurId: testLivreurId,
        totalDeliveries: 55,
        averageRating: 4.2,
      );
      debugPrint('   ✅ Upgrade automatique vers PRO !');
      await displayLivreurTier(testLivreurId);

      // 4. Atteindre niveau PREMIUM
      debugPrint('4️⃣ Mise à jour stats pour upgrade PREMIUM (210 livraisons, 4.6★)...');
      await _subscriptionService.updateLivreurStats(
        livreurId: testLivreurId,
        totalDeliveries: 210,
        averageRating: 4.6,
      );
      debugPrint('   ✅ Upgrade automatique vers PREMIUM !');
      await displayLivreurTier(testLivreurId);

      // 5. Test taux commission
      debugPrint('5️⃣ Test taux de commission...');
      final commissionRate = await _subscriptionService.getLivreurCommissionRate(testLivreurId);
      debugPrint('   ✅ Taux de commission PREMIUM: ${(commissionRate * 100).toStringAsFixed(0)}%');

      debugPrint('');
      debugPrint('✅ TEST FLUX LIVREUR TERMINÉ AVEC SUCCÈS !');
      debugPrint('');
    } catch (e) {
      debugPrint('❌ Erreur test flux livreur: $e');
    }
  }

  /// Exécute tous les tests
  Future<void> runAllTests() async {
    if (!kDebugMode) {
      debugPrint('❌ Tests disponibles uniquement en mode debug');
      return;
    }

    debugPrint('');
    debugPrint('🚀 ========================================');
    debugPrint('🚀 EXÉCUTION COMPLÈTE DES TESTS');
    debugPrint('🚀 ========================================');
    debugPrint('');

    // 1. Créer données de test
    await createAllTestData();

    await Future.delayed(const Duration(seconds: 1));

    // 2. Afficher les abonnements créés
    debugPrint('📋 Vérification des abonnements créés...');
    await displayVendeurSubscription('test_vendeur_basique');
    await displayVendeurSubscription('test_vendeur_pro');
    await displayVendeurSubscription('test_vendeur_premium');

    await Future.delayed(const Duration(seconds: 1));

    // 3. Afficher les niveaux livreur créés
    debugPrint('📋 Vérification des niveaux livreur créés...');
    await displayLivreurTier('test_livreur_starter');
    await displayLivreurTier('test_livreur_pro');
    await displayLivreurTier('test_livreur_premium');

    await Future.delayed(const Duration(seconds: 1));

    // 4. Test flux complet vendeur
    await testVendeurFlow();

    await Future.delayed(const Duration(seconds: 1));

    // 5. Test flux complet livreur
    await testLivreurFlow();

    debugPrint('');
    debugPrint('🎉 ========================================');
    debugPrint('🎉 TOUS LES TESTS TERMINÉS !');
    debugPrint('🎉 ========================================');
    debugPrint('');
    debugPrint('💡 Pour nettoyer les données de test:');
    debugPrint('   SubscriptionTestHelper().cleanAllTestData()');
    debugPrint('');
  }
}
