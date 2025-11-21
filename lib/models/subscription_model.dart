import 'package:cloud_firestore/cloud_firestore.dart';

/// Types de plans d'abonnement pour vendeurs
enum VendeurSubscriptionTier {
  basique, // Gratuit - 20 produits, commission 10%
  pro, // 5,000 FCFA/mois - 100 produits, commission 10%, AI GPT-3.5
  premium, // 10,000 FCFA/mois - Illimité, commission 7%, AI GPT-4
}

/// Types de niveaux pour livreurs (Hybride : Performance + Abonnement payant)
/// Conformément au modèle business finalisé (voir BUSINESS_MODEL.md)
enum LivreurTier {
  starter, // Gratuit - Commission 25% - Débloqué au démarrage
  pro, // 10,000 FCFA/mois - Commission 20% - Débloqué à 50 livraisons + 4.0★
  premium, // 30,000 FCFA/mois - Commission 15% - Débloqué à 200 livraisons + 4.5★
}

/// Statut de déblocage d'un niveau livreur
enum LivreurTierUnlockStatus {
  locked, // Pas encore atteint les critères de performance
  unlocked, // Critères atteints, peut souscrire
  subscribed, // Souscription active et payée
}

/// Statut de l'abonnement
enum SubscriptionStatus {
  active, // Abonnement actif
  expired, // Expiré
  cancelled, // Annulé par l'utilisateur
  pending, // En attente de paiement
  suspended, // Suspendu (non paiement)
}

/// Modèle pour les abonnements vendeurs
class VendeurSubscription {
  final String id;
  final String vendeurId;
  final VendeurSubscriptionTier tier;
  final SubscriptionStatus status;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime? nextBillingDate;
  final double monthlyPrice;
  final int productLimit;
  final double commissionRate;
  final bool hasAIAgent;
  final String? aiModel;
  final int? aiMessagesPerDay;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> metadata;

  VendeurSubscription({
    required this.id,
    required this.vendeurId,
    required this.tier,
    required this.status,
    required this.startDate,
    this.endDate,
    this.nextBillingDate,
    required this.monthlyPrice,
    required this.productLimit,
    required this.commissionRate,
    required this.hasAIAgent,
    this.aiModel,
    this.aiMessagesPerDay,
    required this.createdAt,
    required this.updatedAt,
    this.metadata = const {},
  });

  /// Crée un abonnement BASIQUE par défaut (gratuit)
  factory VendeurSubscription.createBasique(String vendeurId) {
    final now = DateTime.now();
    return VendeurSubscription(
      id: '', // Sera généré par Firestore
      vendeurId: vendeurId,
      tier: VendeurSubscriptionTier.basique,
      status: SubscriptionStatus.active,
      startDate: now,
      endDate: null, // Pas d'expiration pour le plan gratuit
      nextBillingDate: null,
      monthlyPrice: 0,
      productLimit: 20,
      commissionRate: 0.10,
      hasAIAgent: false,
      createdAt: now,
      updatedAt: now,
      metadata: {'autoCreated': true},
    );
  }

  /// Crée un abonnement depuis les données Firestore
  factory VendeurSubscription.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VendeurSubscription.fromMap(data, doc.id);
  }

  /// Crée un abonnement depuis une Map
  factory VendeurSubscription.fromMap(Map<String, dynamic> map, [String? id]) {
    return VendeurSubscription(
      id: id ?? map['id'] ?? '',
      vendeurId: map['vendeurId'] ?? '',
      tier: VendeurSubscriptionTier.values.firstWhere(
        (t) => t.name == map['tier'],
        orElse: () => VendeurSubscriptionTier.basique,
      ),
      status: SubscriptionStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => SubscriptionStatus.active,
      ),
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: map['endDate'] != null ? (map['endDate'] as Timestamp).toDate() : null,
      nextBillingDate:
          map['nextBillingDate'] != null ? (map['nextBillingDate'] as Timestamp).toDate() : null,
      monthlyPrice: (map['monthlyPrice'] ?? 0).toDouble(),
      productLimit: map['productLimit'] ?? 20,
      commissionRate: (map['commissionRate'] ?? 0.10).toDouble(),
      hasAIAgent: map['hasAIAgent'] ?? false,
      aiModel: map['aiModel'],
      aiMessagesPerDay: map['aiMessagesPerDay'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  /// Convertit l'abonnement en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'vendeurId': vendeurId,
      'tier': tier.name,
      'status': status.name,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'nextBillingDate': nextBillingDate != null ? Timestamp.fromDate(nextBillingDate!) : null,
      'monthlyPrice': monthlyPrice,
      'productLimit': productLimit,
      'commissionRate': commissionRate,
      'hasAIAgent': hasAIAgent,
      'aiModel': aiModel,
      'aiMessagesPerDay': aiMessagesPerDay,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
    };
  }

  /// Copie avec modifications
  VendeurSubscription copyWith({
    String? id,
    String? vendeurId,
    VendeurSubscriptionTier? tier,
    SubscriptionStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? nextBillingDate,
    double? monthlyPrice,
    int? productLimit,
    double? commissionRate,
    bool? hasAIAgent,
    String? aiModel,
    int? aiMessagesPerDay,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return VendeurSubscription(
      id: id ?? this.id,
      vendeurId: vendeurId ?? this.vendeurId,
      tier: tier ?? this.tier,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      nextBillingDate: nextBillingDate ?? this.nextBillingDate,
      monthlyPrice: monthlyPrice ?? this.monthlyPrice,
      productLimit: productLimit ?? this.productLimit,
      commissionRate: commissionRate ?? this.commissionRate,
      hasAIAgent: hasAIAgent ?? this.hasAIAgent,
      aiModel: aiModel ?? this.aiModel,
      aiMessagesPerDay: aiMessagesPerDay ?? this.aiMessagesPerDay,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Vérifie si l'abonnement est expiré
  bool get isExpired {
    if (endDate == null) return false;
    return DateTime.now().isAfter(endDate!);
  }

  /// Vérifie si l'abonnement est actif
  bool get isActive {
    return status == SubscriptionStatus.active && !isExpired;
  }

  /// Nombre de jours restants avant expiration
  int? get daysRemaining {
    if (endDate == null) return null;
    final now = DateTime.now();
    if (now.isAfter(endDate!)) return 0;
    return endDate!.difference(now).inDays;
  }

  /// Obtient le nom du plan en français
  String get tierName {
    switch (tier) {
      case VendeurSubscriptionTier.basique:
        return 'BASIQUE';
      case VendeurSubscriptionTier.pro:
        return 'PRO';
      case VendeurSubscriptionTier.premium:
        return 'PREMIUM';
    }
  }

  /// Obtient la description courte du plan
  String get tierDescription {
    switch (tier) {
      case VendeurSubscriptionTier.basique:
        return 'Gratuit - Idéal pour débuter';
      case VendeurSubscriptionTier.pro:
        return '5,000 FCFA/mois - Pour vendre plus';
      case VendeurSubscriptionTier.premium:
        return '10,000 FCFA/mois - Sans limites';
    }
  }
}

/// Modèle pour les souscriptions livreurs (Hybride : Performance + Paiement)
/// Les livreurs débloquent les niveaux PRO et PREMIUM par leurs performances,
/// puis doivent payer un abonnement mensuel pour les activer
class LivreurSubscription {
  final String id;
  final String livreurId;
  final LivreurTier tier;
  final SubscriptionStatus status;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime? nextBillingDate;
  final double monthlyPrice; // 0 pour STARTER, 10000 pour PRO, 30000 pour PREMIUM
  final double commissionRate; // 0.25, 0.20, 0.15
  final bool hasPriority; // Priorité dans l'attribution des livraisons
  final bool has24x7Support;

  // Critères de déblocage (performance)
  final int requiredDeliveries; // 0, 50, 200
  final double requiredRating; // 0.0, 4.0, 4.5
  final LivreurTierUnlockStatus unlockStatus;

  // Stats actuelles du livreur
  final int currentDeliveries;
  final double currentRating;

  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> metadata;

  LivreurSubscription({
    required this.id,
    required this.livreurId,
    required this.tier,
    required this.status,
    required this.startDate,
    this.endDate,
    this.nextBillingDate,
    required this.monthlyPrice,
    required this.commissionRate,
    required this.hasPriority,
    required this.has24x7Support,
    required this.requiredDeliveries,
    required this.requiredRating,
    required this.unlockStatus,
    required this.currentDeliveries,
    required this.currentRating,
    required this.createdAt,
    required this.updatedAt,
    this.metadata = const {},
  });

  /// Crée un abonnement STARTER gratuit par défaut
  factory LivreurSubscription.createStarter(String livreurId) {
    final now = DateTime.now();
    return LivreurSubscription(
      id: '',
      livreurId: livreurId,
      tier: LivreurTier.starter,
      status: SubscriptionStatus.active,
      startDate: now,
      endDate: null, // Pas d'expiration pour STARTER
      nextBillingDate: null,
      monthlyPrice: 0,
      commissionRate: 0.25,
      hasPriority: false,
      has24x7Support: false,
      requiredDeliveries: 0,
      requiredRating: 0.0,
      unlockStatus: LivreurTierUnlockStatus.subscribed, // Toujours actif
      currentDeliveries: 0,
      currentRating: 0.0,
      createdAt: now,
      updatedAt: now,
      metadata: {'autoCreated': true},
    );
  }

  factory LivreurSubscription.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LivreurSubscription.fromMap(data, doc.id);
  }

  factory LivreurSubscription.fromMap(Map<String, dynamic> map, [String? id]) {
    return LivreurSubscription(
      id: id ?? map['id'] ?? '',
      livreurId: map['livreurId'] ?? '',
      tier: LivreurTier.values.firstWhere(
        (t) => t.name == map['tier'],
        orElse: () => LivreurTier.starter,
      ),
      status: SubscriptionStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => SubscriptionStatus.active,
      ),
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: map['endDate'] != null ? (map['endDate'] as Timestamp).toDate() : null,
      nextBillingDate:
          map['nextBillingDate'] != null ? (map['nextBillingDate'] as Timestamp).toDate() : null,
      monthlyPrice: (map['monthlyPrice'] ?? 0).toDouble(),
      commissionRate: (map['commissionRate'] ?? 0.25).toDouble(),
      hasPriority: map['hasPriority'] ?? false,
      has24x7Support: map['has24x7Support'] ?? false,
      requiredDeliveries: map['requiredDeliveries'] ?? 0,
      requiredRating: (map['requiredRating'] ?? 0.0).toDouble(),
      unlockStatus: LivreurTierUnlockStatus.values.firstWhere(
        (s) => s.name == map['unlockStatus'],
        orElse: () => LivreurTierUnlockStatus.subscribed,
      ),
      currentDeliveries: map['currentDeliveries'] ?? 0,
      currentRating: (map['currentRating'] ?? 0.0).toDouble(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'livreurId': livreurId,
      'tier': tier.name,
      'status': status.name,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'nextBillingDate': nextBillingDate != null ? Timestamp.fromDate(nextBillingDate!) : null,
      'monthlyPrice': monthlyPrice,
      'commissionRate': commissionRate,
      'hasPriority': hasPriority,
      'has24x7Support': has24x7Support,
      'requiredDeliveries': requiredDeliveries,
      'requiredRating': requiredRating,
      'unlockStatus': unlockStatus.name,
      'currentDeliveries': currentDeliveries,
      'currentRating': currentRating,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
    };
  }

  LivreurSubscription copyWith({
    String? id,
    String? livreurId,
    LivreurTier? tier,
    SubscriptionStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? nextBillingDate,
    double? monthlyPrice,
    double? commissionRate,
    bool? hasPriority,
    bool? has24x7Support,
    int? requiredDeliveries,
    double? requiredRating,
    LivreurTierUnlockStatus? unlockStatus,
    int? currentDeliveries,
    double? currentRating,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return LivreurSubscription(
      id: id ?? this.id,
      livreurId: livreurId ?? this.livreurId,
      tier: tier ?? this.tier,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      nextBillingDate: nextBillingDate ?? this.nextBillingDate,
      monthlyPrice: monthlyPrice ?? this.monthlyPrice,
      commissionRate: commissionRate ?? this.commissionRate,
      hasPriority: hasPriority ?? this.hasPriority,
      has24x7Support: has24x7Support ?? this.has24x7Support,
      requiredDeliveries: requiredDeliveries ?? this.requiredDeliveries,
      requiredRating: requiredRating ?? this.requiredRating,
      unlockStatus: unlockStatus ?? this.unlockStatus,
      currentDeliveries: currentDeliveries ?? this.currentDeliveries,
      currentRating: currentRating ?? this.currentRating,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isExpired {
    if (endDate == null) return false;
    return DateTime.now().isAfter(endDate!);
  }

  bool get isActive {
    return status == SubscriptionStatus.active && !isExpired;
  }

  int? get daysRemaining {
    if (endDate == null) return null;
    final now = DateTime.now();
    if (now.isAfter(endDate!)) return 0;
    return endDate!.difference(now).inDays;
  }

  /// Vérifie si le livreur a atteint les critères pour débloquer ce niveau
  bool get hasMetPerformanceCriteria {
    return currentDeliveries >= requiredDeliveries && currentRating >= requiredRating;
  }

  /// Vérifie si le niveau suivant est débloqué (peut souscrire)
  bool get canUpgrade {
    if (tier == LivreurTier.premium) return false; // Niveau max
    return hasMetPerformanceCriteria;
  }

  String get tierName {
    switch (tier) {
      case LivreurTier.starter:
        return 'STARTER';
      case LivreurTier.pro:
        return 'PRO';
      case LivreurTier.premium:
        return 'PREMIUM';
    }
  }

  String get tierDescription {
    switch (tier) {
      case LivreurTier.starter:
        return 'Gratuit - Pour commencer';
      case LivreurTier.pro:
        return '10,000 FCFA/mois - Pour livrer plus';
      case LivreurTier.premium:
        return '30,000 FCFA/mois - Pour les experts';
    }
  }
}

/// Modèle pour le niveau livreur (pas d'abonnement, juste progression)
class LivreurTierInfo {
  final String id;
  final String livreurId;
  final LivreurTier currentTier;
  final int totalDeliveries;
  final double averageRating;
  final double currentCommissionRate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> metadata;

  LivreurTierInfo({
    required this.id,
    required this.livreurId,
    required this.currentTier,
    required this.totalDeliveries,
    required this.averageRating,
    required this.currentCommissionRate,
    required this.createdAt,
    required this.updatedAt,
    this.metadata = const {},
  });

  /// Crée un niveau STARTER par défaut (nouveau livreur)
  factory LivreurTierInfo.createStarter(String livreurId) {
    final now = DateTime.now();
    return LivreurTierInfo(
      id: '',
      livreurId: livreurId,
      currentTier: LivreurTier.starter,
      totalDeliveries: 0,
      averageRating: 0.0,
      currentCommissionRate: 0.25,
      createdAt: now,
      updatedAt: now,
      metadata: {'autoCreated': true},
    );
  }

  factory LivreurTierInfo.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LivreurTierInfo.fromMap(data, doc.id);
  }

  factory LivreurTierInfo.fromMap(Map<String, dynamic> map, [String? id]) {
    return LivreurTierInfo(
      id: id ?? map['id'] ?? '',
      livreurId: map['livreurId'] ?? '',
      currentTier: LivreurTier.values.firstWhere(
        (t) => t.name == map['currentTier'],
        orElse: () => LivreurTier.starter,
      ),
      totalDeliveries: map['totalDeliveries'] ?? 0,
      averageRating: (map['averageRating'] ?? 0.0).toDouble(),
      currentCommissionRate: (map['currentCommissionRate'] ?? 0.25).toDouble(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'livreurId': livreurId,
      'currentTier': currentTier.name,
      'totalDeliveries': totalDeliveries,
      'averageRating': averageRating,
      'currentCommissionRate': currentCommissionRate,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
    };
  }

  /// Vérifie si le livreur peut passer au niveau PRO
  bool get canUpgradeToPro {
    return currentTier == LivreurTier.starter && totalDeliveries >= 50 && averageRating >= 4.0;
  }

  /// Vérifie si le livreur peut passer au niveau PREMIUM
  bool get canUpgradeToPremium {
    return currentTier == LivreurTier.pro && totalDeliveries >= 200 && averageRating >= 4.5;
  }

  /// Obtient le prochain niveau disponible
  LivreurTier? get nextTier {
    if (canUpgradeToPremium) return LivreurTier.premium;
    if (canUpgradeToPro) return LivreurTier.pro;
    return null;
  }

  /// Nombre de livraisons restantes pour le prochain niveau
  int? get deliveriesUntilNextTier {
    switch (currentTier) {
      case LivreurTier.starter:
        return 50 - totalDeliveries;
      case LivreurTier.pro:
        return 200 - totalDeliveries;
      case LivreurTier.premium:
        return null; // Niveau max atteint
    }
  }

  /// Note minimum requise pour le prochain niveau
  double? get ratingRequiredForNextTier {
    switch (currentTier) {
      case LivreurTier.starter:
        return 4.0;
      case LivreurTier.pro:
        return 4.5;
      case LivreurTier.premium:
        return null;
    }
  }

  String get tierName {
    switch (currentTier) {
      case LivreurTier.starter:
        return 'STARTER';
      case LivreurTier.pro:
        return 'PRO';
      case LivreurTier.premium:
        return 'PREMIUM';
    }
  }

  String get tierDescription {
    switch (currentTier) {
      case LivreurTier.starter:
        return 'Commission 25% - Débutant';
      case LivreurTier.pro:
        return 'Commission 20% - Confirmé';
      case LivreurTier.premium:
        return 'Commission 15% - Expert';
    }
  }

  LivreurTierInfo copyWith({
    String? id,
    String? livreurId,
    LivreurTier? currentTier,
    int? totalDeliveries,
    double? averageRating,
    double? currentCommissionRate,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return LivreurTierInfo(
      id: id ?? this.id,
      livreurId: livreurId ?? this.livreurId,
      currentTier: currentTier ?? this.currentTier,
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
      averageRating: averageRating ?? this.averageRating,
      currentCommissionRate: currentCommissionRate ?? this.currentCommissionRate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Historique de paiement d'abonnement vendeur
class SubscriptionPayment {
  final String id;
  final String subscriptionId;
  final String vendeurId;
  final double amount;
  final String paymentMethod;
  final String status; // pending, completed, failed
  final DateTime paymentDate;
  final VendeurSubscriptionTier tier;
  final String? transactionId;
  final String? invoiceUrl;
  final DateTime createdAt;

  SubscriptionPayment({
    required this.id,
    required this.subscriptionId,
    required this.vendeurId,
    required this.amount,
    required this.paymentMethod,
    required this.status,
    required this.paymentDate,
    required this.tier,
    this.transactionId,
    this.invoiceUrl,
    required this.createdAt,
  });

  factory SubscriptionPayment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SubscriptionPayment.fromMap(data, doc.id);
  }

  factory SubscriptionPayment.fromMap(Map<String, dynamic> map, [String? id]) {
    return SubscriptionPayment(
      id: id ?? map['id'] ?? '',
      subscriptionId: map['subscriptionId'] ?? '',
      vendeurId: map['vendeurId'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      paymentMethod: map['paymentMethod'] ?? '',
      status: map['status'] ?? 'pending',
      paymentDate: (map['paymentDate'] as Timestamp).toDate(),
      tier: VendeurSubscriptionTier.values.firstWhere(
        (t) => t.name == map['tier'],
        orElse: () => VendeurSubscriptionTier.basique,
      ),
      transactionId: map['transactionId'],
      invoiceUrl: map['invoiceUrl'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subscriptionId': subscriptionId,
      'vendeurId': vendeurId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'status': status,
      'paymentDate': Timestamp.fromDate(paymentDate),
      'tier': tier.name,
      'transactionId': transactionId,
      'invoiceUrl': invoiceUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

/// Historique de paiement d'abonnement livreur
class LivreurSubscriptionPayment {
  final String id;
  final String subscriptionId;
  final String livreurId;
  final double amount;
  final String paymentMethod;
  final String status; // pending, completed, failed
  final DateTime paymentDate;
  final LivreurTier tier;
  final String? transactionId;
  final String? invoiceUrl;
  final DateTime createdAt;

  LivreurSubscriptionPayment({
    required this.id,
    required this.subscriptionId,
    required this.livreurId,
    required this.amount,
    required this.paymentMethod,
    required this.status,
    required this.paymentDate,
    required this.tier,
    this.transactionId,
    this.invoiceUrl,
    required this.createdAt,
  });

  factory LivreurSubscriptionPayment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LivreurSubscriptionPayment.fromMap(data, doc.id);
  }

  factory LivreurSubscriptionPayment.fromMap(Map<String, dynamic> map, [String? id]) {
    return LivreurSubscriptionPayment(
      id: id ?? map['id'] ?? '',
      subscriptionId: map['subscriptionId'] ?? '',
      livreurId: map['livreurId'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      paymentMethod: map['paymentMethod'] ?? '',
      status: map['status'] ?? 'pending',
      paymentDate: (map['paymentDate'] as Timestamp).toDate(),
      tier: LivreurTier.values.firstWhere(
        (t) => t.name == map['tier'],
        orElse: () => LivreurTier.starter,
      ),
      transactionId: map['transactionId'],
      invoiceUrl: map['invoiceUrl'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subscriptionId': subscriptionId,
      'livreurId': livreurId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'status': status,
      'paymentDate': Timestamp.fromDate(paymentDate),
      'tier': tier.name,
      'transactionId': transactionId,
      'invoiceUrl': invoiceUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
