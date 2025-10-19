import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import '../models/subscription_model.dart';
import '../services/subscription_service.dart';

/// Provider pour la gestion d'état des abonnements
/// Conforme au modèle business finalisé:
/// - Vendeurs: Abonnements payants (BASIQUE gratuit, PRO 5k, PREMIUM 10k)
/// - Livreurs: Progression gratuite basée sur performance (commission 25% → 20% → 15%)
class SubscriptionProvider with ChangeNotifier {
  final SubscriptionService _subscriptionService = SubscriptionService();

  // ==================== ÉTAT VENDEUR ====================
  VendeurSubscription? _vendeurSubscription;
  bool _isLoadingSubscription = false;
  String? _subscriptionError;
  List<SubscriptionPayment> _paymentHistory = [];
  bool _isLoadingPayments = false;

  // ==================== ÉTAT LIVREUR (Modèle HYBRIDE: Performance + Abonnement payant) ====================
  LivreurSubscription? _livreurSubscription; // Abonnement actif (STARTER gratuit, PRO 10k, PREMIUM 30k)
  bool _isLoadingLivreurSubscription = false;
  String? _livreurSubscriptionError;

  LivreurTierInfo? _livreurTier; // Info de performance (tracking séparé, optionnel)
  bool _isLoadingTier = false;
  String? _tierError;

  // ==================== GETTERS VENDEUR ====================
  VendeurSubscription? get vendeurSubscription => _vendeurSubscription;
  bool get isLoadingSubscription => _isLoadingSubscription;
  String? get subscriptionError => _subscriptionError;
  List<SubscriptionPayment> get paymentHistory => _paymentHistory;
  bool get isLoadingPayments => _isLoadingPayments;

  // Getters utilitaires vendeur
  bool get hasActiveSubscription => _vendeurSubscription?.isActive ?? false;
  String get currentTierName => _vendeurSubscription?.tierName ?? 'BASIQUE';
  int get productLimit => _vendeurSubscription?.productLimit ?? 20;
  double get commissionRate => _vendeurSubscription?.commissionRate ?? 0.10;
  bool get hasAIAgent => _vendeurSubscription?.hasAIAgent ?? false;
  String? get aiModel => _vendeurSubscription?.aiModel;
  int? get aiMessagesPerDay => _vendeurSubscription?.aiMessagesPerDay;

  bool get isBasiqueTier => _vendeurSubscription?.tier == VendeurSubscriptionTier.basique;
  bool get isProTier => _vendeurSubscription?.tier == VendeurSubscriptionTier.pro;
  bool get isPremiumTier => _vendeurSubscription?.tier == VendeurSubscriptionTier.premium;

  int? get daysUntilExpiration => _vendeurSubscription?.daysRemaining;

  bool get isExpiringsSoon {
    final days = daysUntilExpiration;
    return days != null && days <= 7 && days > 0;
  }

  String? get alertMessage {
    if (_vendeurSubscription == null) return null;

    if (_vendeurSubscription!.status == SubscriptionStatus.expired) {
      return '⚠️ Votre abonnement a expiré. Renouvelez pour continuer à profiter des avantages ${_vendeurSubscription!.tierName}.';
    }

    if (_vendeurSubscription!.status == SubscriptionStatus.suspended) {
      return '⚠️ Votre abonnement est suspendu. Veuillez régulariser votre paiement.';
    }

    if (isExpiringsSoon) {
      return '⏰ Votre abonnement expire dans $daysUntilExpiration jour${daysUntilExpiration! > 1 ? 's' : ''}. Pensez à le renouveler !';
    }

    return null;
  }

  // ==================== GETTERS LIVREUR (Abonnement hybride) ====================
  LivreurSubscription? get livreurSubscription => _livreurSubscription;
  LivreurSubscription? get currentLivreurSubscription => _livreurSubscription; // Alias pour compatibilité
  bool get isLoadingLivreurSubscription => _isLoadingLivreurSubscription;
  String? get livreurSubscriptionError => _livreurSubscriptionError;

  // Getters pour le niveau de performance (tracking optionnel)
  LivreurTierInfo? get livreurTier => _livreurTier;
  LivreurTierInfo? get livreurTierInfo => _livreurTier; // Alias pour compatibilité
  bool get isLoadingTier => _isLoadingTier;
  String? get tierError => _tierError;

  // Getters utilitaires livreur (basé sur l'abonnement HYBRIDE)
  bool get hasActiveLivreurSubscription => _livreurSubscription?.isActive ?? false;
  String get livreurTierName => _livreurSubscription?.tierName ?? 'STARTER';
  double get livreurCommissionRate => _livreurSubscription?.commissionRate ?? 0.25;
  int get totalDeliveries => _livreurSubscription?.currentDeliveries ?? 0;
  double get averageRating => _livreurSubscription?.currentRating ?? 0.0;
  bool get canUpgradeToPro => _livreurSubscription?.canUpgrade ?? false;
  bool get canUpgradeToPremium => _livreurSubscription?.canUpgrade ?? false;
  bool get hasPriority => _livreurSubscription?.hasPriority ?? false;
  bool get has24x7Support => _livreurSubscription?.has24x7Support ?? false;

  bool get isStarterTier => _livreurSubscription?.tier == LivreurTier.starter;
  bool get isLivreurProTier => _livreurSubscription?.tier == LivreurTier.pro;
  bool get isLivreurPremiumTier => _livreurSubscription?.tier == LivreurTier.premium;

  Map<String, dynamic> get livreurProgressStats {
    if (_livreurTier == null) {
      return {
        'currentTier': 'STARTER',
        'nextTier': 'PRO',
        'deliveriesNeeded': 50,
        'ratingNeeded': 4.0,
        'progress': 0.0,
      };
    }

    return {
      'currentTier': _livreurTier!.tierName,
      'nextTier': _livreurTier!.nextTier?.name.toUpperCase(),
      'deliveriesNeeded': _livreurTier!.deliveriesUntilNextTier,
      'ratingNeeded': _livreurTier!.ratingRequiredForNextTier,
      'progress': _calculateLivreurProgress(),
      'totalDeliveries': _livreurTier!.totalDeliveries,
      'averageRating': _livreurTier!.averageRating,
      'commissionRate': _livreurTier!.currentCommissionRate,
    };
  }

  double _calculateLivreurProgress() {
    if (_livreurTier == null) return 0.0;

    switch (_livreurTier!.currentTier) {
      case LivreurTier.starter:
        return (_livreurTier!.totalDeliveries / 50).clamp(0.0, 1.0);
      case LivreurTier.pro:
        return (_livreurTier!.totalDeliveries / 200).clamp(0.0, 1.0);
      case LivreurTier.premium:
        return 1.0;
    }
  }

  // ==================== MÉTHODES VENDEUR ====================

  /// Charge l'abonnement d'un vendeur
  Future<void> loadVendeurSubscription(String vendeurId) async {
    _isLoadingSubscription = true;
    _subscriptionError = null;

    // ✅ Différer notifyListeners après le build pour éviter "setState() during build"
    SchedulerBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      debugPrint('📊 Chargement abonnement vendeur: $vendeurId');
      _vendeurSubscription = await _subscriptionService.getVendeurSubscription(vendeurId);
      debugPrint('✅ Abonnement chargé: ${_vendeurSubscription?.tierName}');
    } catch (e) {
      _subscriptionError = e.toString();
      debugPrint('❌ Erreur chargement abonnement: $e');
    } finally {
      _isLoadingSubscription = false;
      notifyListeners();
    }
  }

  /// Upgrader l'abonnement vendeur
  Future<bool> upgradeSubscription({
    required String vendeurId,
    required VendeurSubscriptionTier newTier,
    required String paymentMethod,
    required String transactionId,
  }) async {
    _isLoadingSubscription = true;
    _subscriptionError = null;
    notifyListeners();

    try {
      debugPrint('⬆️ Upgrade vers ${newTier.name}...');

      _vendeurSubscription = await _subscriptionService.upgradeSubscription(
        vendeurId: vendeurId,
        newTier: newTier,
        paymentMethod: paymentMethod,
        transactionId: transactionId,
      );

      debugPrint('✅ Upgrade réussi !');
      _isLoadingSubscription = false;
      notifyListeners();
      return true;
    } catch (e) {
      _subscriptionError = e.toString();
      debugPrint('❌ Erreur upgrade: $e');
      _isLoadingSubscription = false;
      notifyListeners();
      return false;
    }
  }

  /// Rétrograder l'abonnement vendeur vers BASIQUE
  Future<bool> downgradeSubscription(String vendeurId) async {
    _isLoadingSubscription = true;
    _subscriptionError = null;
    notifyListeners();

    try {
      debugPrint('⬇️ Downgrade vers BASIQUE...');
      _vendeurSubscription = await _subscriptionService.downgradeSubscription(vendeurId);
      debugPrint('✅ Downgrade réussi !');
      _isLoadingSubscription = false;
      notifyListeners();
      return true;
    } catch (e) {
      _subscriptionError = e.toString();
      debugPrint('❌ Erreur downgrade: $e');
      _isLoadingSubscription = false;
      notifyListeners();
      return false;
    }
  }

  /// Renouveler l'abonnement
  Future<bool> renewSubscription({
    required String subscriptionId,
    required String paymentMethod,
    required String transactionId,
  }) async {
    _isLoadingSubscription = true;
    _subscriptionError = null;
    notifyListeners();

    try {
      debugPrint('🔄 Renouvellement abonnement...');

      final success = await _subscriptionService.renewSubscription(
        subscriptionId: subscriptionId,
        paymentMethod: paymentMethod,
        transactionId: transactionId,
      );

      if (success && _vendeurSubscription != null) {
        await loadVendeurSubscription(_vendeurSubscription!.vendeurId);
      }

      debugPrint(success ? '✅ Renouvellement réussi !' : '❌ Échec renouvellement');
      _isLoadingSubscription = false;
      notifyListeners();
      return success;
    } catch (e) {
      _subscriptionError = e.toString();
      debugPrint('❌ Erreur renouvellement: $e');
      _isLoadingSubscription = false;
      notifyListeners();
      return false;
    }
  }

  /// Vérifie si un vendeur peut ajouter un produit
  Future<bool> canAddProduct(String vendeurId, int currentProductCount) async {
    try {
      return await _subscriptionService.checkProductLimit(vendeurId, currentProductCount);
    } catch (e) {
      debugPrint('❌ Erreur vérification limite: $e');
      return false;
    }
  }

  /// Charge l'historique des paiements vendeur
  Future<void> loadPaymentHistory(String vendeurId) async {
    _isLoadingPayments = true;

    // ✅ Différer notifyListeners après le build pour éviter "setState() during build"
    SchedulerBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      debugPrint('📊 Chargement historique paiements...');
      _paymentHistory = await _subscriptionService.getPaymentHistory(vendeurId);
      debugPrint('✅ ${_paymentHistory.length} paiements chargés');
    } catch (e) {
      debugPrint('❌ Erreur chargement historique: $e');
    } finally {
      _isLoadingPayments = false;
      notifyListeners();
    }
  }

  /// Écoute les mises à jour en temps réel de l'abonnement vendeur
  void listenToSubscription(String vendeurId) {
    _subscriptionService.subscriptionStream(vendeurId).listen((subscription) {
      if (subscription != null) {
        _vendeurSubscription = subscription;
        debugPrint('🔄 Abonnement mis à jour: ${subscription.tierName}');
        notifyListeners();
      }
    }, onError: (error) {
      _subscriptionError = error.toString();
      debugPrint('❌ Erreur stream abonnement: $error');
      notifyListeners();
    });
  }

  // ==================== MÉTHODES LIVREUR (Abonnement HYBRIDE) ====================

  /// Charge l'abonnement d'un livreur (STARTER gratuit, PRO 10k, PREMIUM 30k)
  Future<void> loadLivreurSubscription(String livreurId) async {
    _isLoadingLivreurSubscription = true;
    _livreurSubscriptionError = null;

    // ✅ Différer notifyListeners après le build pour éviter "setState() during build"
    SchedulerBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      debugPrint('📊 Chargement abonnement livreur: $livreurId');
      _livreurSubscription = await _subscriptionService.getLivreurSubscription(livreurId);
      debugPrint('✅ Abonnement livreur chargé: ${_livreurSubscription?.tierName}');
    } catch (e) {
      _livreurSubscriptionError = e.toString();
      debugPrint('❌ Erreur chargement abonnement livreur: $e');
    } finally {
      _isLoadingLivreurSubscription = false;
      notifyListeners();
    }
  }

  /// Upgrade vers PRO ou PREMIUM (après avoir débloqué + paiement)
  Future<bool> upgradeLivreurSubscription({
    required String livreurId,
    required LivreurTier newTier,
    required String paymentMethod,
    required String transactionId,
    required int currentDeliveries,
    required double currentRating,
  }) async {
    _isLoadingLivreurSubscription = true;
    _livreurSubscriptionError = null;
    notifyListeners();

    try {
      debugPrint('⬆️ Upgrade livreur vers ${newTier.name}...');

      _livreurSubscription = await _subscriptionService.upgradeLivreurSubscription(
        livreurId: livreurId,
        newTier: newTier,
        paymentMethod: paymentMethod,
        transactionId: transactionId,
        currentDeliveries: currentDeliveries,
        currentRating: currentRating,
      );

      debugPrint('✅ Upgrade livreur réussi !');
      _isLoadingLivreurSubscription = false;
      notifyListeners();
      return true;
    } catch (e) {
      _livreurSubscriptionError = e.toString();
      debugPrint('❌ Erreur upgrade livreur: $e');
      _isLoadingLivreurSubscription = false;
      notifyListeners();
      return false;
    }
  }

  /// Rétrograde vers STARTER (gratuit)
  Future<bool> downgradeLivreurSubscription(String livreurId) async {
    _isLoadingLivreurSubscription = true;
    _livreurSubscriptionError = null;
    notifyListeners();

    try {
      debugPrint('⬇️ Downgrade livreur vers STARTER...');
      _livreurSubscription = await _subscriptionService.downgradeLivreurSubscription(livreurId);
      debugPrint('✅ Downgrade livreur réussi !');
      _isLoadingLivreurSubscription = false;
      notifyListeners();
      return true;
    } catch (e) {
      _livreurSubscriptionError = e.toString();
      debugPrint('❌ Erreur downgrade livreur: $e');
      _isLoadingLivreurSubscription = false;
      notifyListeners();
      return false;
    }
  }

  /// Met à jour les stats de performance (vérifie déblocage automatique)
  Future<void> updateLivreurPerformanceStats({
    required String livreurId,
    required int totalDeliveries,
    required double averageRating,
  }) async {
    _isLoadingLivreurSubscription = true;
    notifyListeners();

    try {
      debugPrint('📊 Mise à jour stats performance livreur...');

      _livreurSubscription = await _subscriptionService.updateLivreurPerformanceStats(
        livreurId: livreurId,
        totalDeliveries: totalDeliveries,
        averageRating: averageRating,
      );

      debugPrint('✅ Stats performance mises à jour !');
    } catch (e) {
      _livreurSubscriptionError = e.toString();
      debugPrint('❌ Erreur mise à jour stats: $e');
    } finally {
      _isLoadingLivreurSubscription = false;
      notifyListeners();
    }
  }

  /// Écoute les mises à jour en temps réel de l'abonnement livreur
  void listenToLivreurSubscription(String livreurId) {
    _subscriptionService.livreurSubscriptionStream(livreurId).listen((subscription) {
      if (subscription != null) {
        _livreurSubscription = subscription;
        debugPrint('🔄 Abonnement livreur mis à jour: ${subscription.tierName}');
        notifyListeners();
      }
    }, onError: (error) {
      _livreurSubscriptionError = error.toString();
      debugPrint('❌ Erreur stream abonnement livreur: $error');
      notifyListeners();
    });
  }

  // ==================== MÉTHODES LIVREUR (Niveau de performance - tracking optionnel) ====================

  /// Charge le niveau d'un livreur (tracking séparé, optionnel)
  Future<void> loadLivreurTier(String livreurId) async {
    _isLoadingTier = true;
    _tierError = null;
    notifyListeners();

    try {
      debugPrint('📊 Chargement niveau livreur: $livreurId');
      _livreurTier = await _subscriptionService.getLivreurTier(livreurId);
      debugPrint('✅ Niveau chargé: ${_livreurTier?.tierName}');
    } catch (e) {
      _tierError = e.toString();
      debugPrint('❌ Erreur chargement niveau: $e');
    } finally {
      _isLoadingTier = false;
      notifyListeners();
    }
  }

  /// Met à jour les stats d'un livreur (déclenche upgrade automatique si critères atteints)
  Future<void> updateLivreurStats({
    required String livreurId,
    required int totalDeliveries,
    required double averageRating,
  }) async {
    _isLoadingTier = true;
    notifyListeners();

    try {
      debugPrint('📊 Mise à jour stats livreur...');

      _livreurTier = await _subscriptionService.updateLivreurStats(
        livreurId: livreurId,
        totalDeliveries: totalDeliveries,
        averageRating: averageRating,
      );

      debugPrint('✅ Stats mises à jour !');
    } catch (e) {
      _tierError = e.toString();
      debugPrint('❌ Erreur mise à jour stats: $e');
    } finally {
      _isLoadingTier = false;
      notifyListeners();
    }
  }

  /// Écoute les mises à jour en temps réel du niveau livreur
  void listenToLivreurTier(String livreurId) {
    _subscriptionService.livreurTierStream(livreurId).listen((tierInfo) {
      if (tierInfo != null) {
        _livreurTier = tierInfo;
        debugPrint('🔄 Niveau livreur mis à jour: ${tierInfo.tierName}');
        notifyListeners();
      }
    }, onError: (error) {
      _tierError = error.toString();
      debugPrint('❌ Erreur stream niveau: $error');
      notifyListeners();
    });
  }

  // ==================== MÉTHODES GÉNÉRALES ====================

  /// Réinitialise l'état
  void reset() {
    _vendeurSubscription = null;
    _livreurSubscription = null;
    _livreurTier = null;
    _paymentHistory = [];
    _isLoadingSubscription = false;
    _isLoadingLivreurSubscription = false;
    _isLoadingTier = false;
    _isLoadingPayments = false;
    _subscriptionError = null;
    _livreurSubscriptionError = null;
    _tierError = null;
    notifyListeners();
  }
}
