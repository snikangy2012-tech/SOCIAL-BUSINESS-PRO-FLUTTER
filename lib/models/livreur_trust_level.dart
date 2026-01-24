// ===== lib/models/livreur_trust_level.dart =====
// Modèle pour la gestion des paliers de confiance des livreurs

enum LivreurTrustLevel {
  debutant,   // 0-10 livraisons
  confirme,   // 11-50 livraisons + note ≥ 4.0
  expert,     // 51-150 livraisons + note ≥ 4.3
  vip,        // 151+ livraisons + note ≥ 4.5 + caution 100k
}

class LivreurTrustConfig {
  final LivreurTrustLevel level;
  final double cautionRequired;      // Caution à déposer (FCFA)
  final double maxOrderAmount;       // Montant max par commande (FCFA)
  final double maxUnpaidBalance;     // Total max non reversé (FCFA)
  final int reversementDelayHours;   // Délai de reversement (heures)
  final int maxActiveDeliveries;     // Nombre max de livraisons simultanées
  final String displayName;          // Nom d'affichage
  final String badgeIcon;            // Icône du badge

  const LivreurTrustConfig({
    required this.level,
    required this.cautionRequired,
    required this.maxOrderAmount,
    required this.maxUnpaidBalance,
    required this.reversementDelayHours,
    required this.maxActiveDeliveries,
    required this.displayName,
    required this.badgeIcon,
  });

  /// Calculer la configuration de confiance d'un livreur
  static LivreurTrustConfig getConfig({
    required int completedDeliveries,
    required double averageRating,
    required double cautionDeposited,
  }) {
    // Niveau VIP : 151+ livraisons + note ≥ 4.5 + caution 100k
    if (completedDeliveries >= 151 &&
        averageRating >= 4.5 &&
        cautionDeposited >= 100000) {
      return const LivreurTrustConfig(
        level: LivreurTrustLevel.vip,
        cautionRequired: 100000,
        maxOrderAmount: 300000,
        maxUnpaidBalance: 500000,
        reversementDelayHours: 168, // 7 jours
        maxActiveDeliveries: 5, // Maximum confiance
        displayName: 'VIP',
        badgeIcon: '🌟',
      );
    }

    // Niveau Expert : 51-150 livraisons + note ≥ 4.3
    if (completedDeliveries >= 51 && averageRating >= 4.3) {
      return const LivreurTrustConfig(
        level: LivreurTrustLevel.expert,
        cautionRequired: 50000,
        maxOrderAmount: 150000,
        maxUnpaidBalance: 300000,
        reversementDelayHours: 72, // 3 jours
        maxActiveDeliveries: 3, // Très fiable
        displayName: 'Expert',
        badgeIcon: '⚡',
      );
    }

    // Niveau Confirmé : 11-50 livraisons + note ≥ 4.0
    if (completedDeliveries >= 11 && averageRating >= 4.0) {
      return const LivreurTrustConfig(
        level: LivreurTrustLevel.confirme,
        cautionRequired: 20000,
        maxOrderAmount: 100000,
        maxUnpaidBalance: 200000,
        reversementDelayHours: 48, // 2 jours
        maxActiveDeliveries: 2, // A prouvé sa fiabilité
        displayName: 'Confirmé',
        badgeIcon: '✓',
      );
    }

    // Niveau Débutant (par défaut)
    return const LivreurTrustConfig(
      level: LivreurTrustLevel.debutant,
      cautionRequired: 0,
      maxOrderAmount: 30000,
      maxUnpaidBalance: 50000,
      reversementDelayHours: 24, // 1 jour
      maxActiveDeliveries: 1, // Strict: une livraison à la fois
      displayName: 'Débutant',
      badgeIcon: '🔰',
    );
  }

  /// Obtenir la configuration par niveau
  static LivreurTrustConfig getConfigByLevel(LivreurTrustLevel level) {
    switch (level) {
      case LivreurTrustLevel.vip:
        return const LivreurTrustConfig(
          level: LivreurTrustLevel.vip,
          cautionRequired: 100000,
          maxOrderAmount: 300000,
          maxUnpaidBalance: 500000,
          reversementDelayHours: 168,
          maxActiveDeliveries: 5,
          displayName: 'VIP',
          badgeIcon: '🌟',
        );
      case LivreurTrustLevel.expert:
        return const LivreurTrustConfig(
          level: LivreurTrustLevel.expert,
          cautionRequired: 50000,
          maxOrderAmount: 150000,
          maxUnpaidBalance: 300000,
          reversementDelayHours: 72,
          maxActiveDeliveries: 3,
          displayName: 'Expert',
          badgeIcon: '⚡',
        );
      case LivreurTrustLevel.confirme:
        return const LivreurTrustConfig(
          level: LivreurTrustLevel.confirme,
          cautionRequired: 20000,
          maxOrderAmount: 100000,
          maxUnpaidBalance: 200000,
          reversementDelayHours: 48,
          maxActiveDeliveries: 2,
          displayName: 'Confirmé',
          badgeIcon: '✓',
        );
      case LivreurTrustLevel.debutant:
        return const LivreurTrustConfig(
          level: LivreurTrustLevel.debutant,
          cautionRequired: 0,
          maxOrderAmount: 30000,
          maxUnpaidBalance: 50000,
          reversementDelayHours: 24,
          maxActiveDeliveries: 1,
          displayName: 'Débutant',
          badgeIcon: '🔰',
        );
    }
  }

  /// Calculer la progression vers le niveau suivant
  ///  Retourne un objet avec les infos de progression
  static Map<String, dynamic> getProgressToNextLevel({
    required int completedDeliveries,
    required double averageRating,
    required double cautionDeposited,
  }) {
    final currentConfig = getConfig(
      completedDeliveries: completedDeliveries,
      averageRating: averageRating,
      cautionDeposited: cautionDeposited,
    );

    // Si déjà VIP, pas de niveau suivant
    if (currentConfig.level == LivreurTrustLevel.vip) {
      return {
        'hasNextLevel': false,
        'currentLevel': 'VIP',
        'message': 'Vous avez atteint le niveau maximum ! 🎉',
      };
    }

    // Calculer les requirements pour le niveau suivant
    Map<String, dynamic> nextLevelRequirements = {};
    String nextLevelName = '';

    switch (currentConfig.level) {
      case LivreurTrustLevel.debutant:
        nextLevelName = 'Confirmé';
        nextLevelRequirements = {
          'deliveriesNeeded': 11 - completedDeliveries,
          'ratingNeeded': averageRating >= 4.0 ? 0 : 4.0 - averageRating,
          'cautionNeeded': 0,
        };
        break;
      case LivreurTrustLevel.confirme:
        nextLevelName = 'Expert';
        nextLevelRequirements = {
          'deliveriesNeeded': 51 - completedDeliveries,
          'ratingNeeded': averageRating >= 4.3 ? 0 : 4.3 - averageRating,
          'cautionNeeded': 0,
        };
        break;
      case LivreurTrustLevel.expert:
        nextLevelName = 'VIP';
        nextLevelRequirements = {
          'deliveriesNeeded': 151 - completedDeliveries,
          'ratingNeeded': averageRating >= 4.5 ? 0 : 4.5 - averageRating,
          'cautionNeeded': cautionDeposited >= 100000 ? 0 : 100000 - cautionDeposited,
        };
        break;
      case LivreurTrustLevel.vip:
        // Déjà traité ci-dessus
        break;
    }

    return {
      'hasNextLevel': true,
      'currentLevel': currentConfig.displayName,
      'nextLevel': nextLevelName,
      'requirements': nextLevelRequirements,
      'progressMessage': _buildProgressMessage(
        nextLevelName,
        nextLevelRequirements,
      ),
    };
  }

  static String _buildProgressMessage(
    String nextLevel,
    Map<String, dynamic> requirements,
  ) {
    final List<String> messages = [];

    if (requirements['deliveriesNeeded'] > 0) {
      messages.add('${requirements['deliveriesNeeded']} livraisons');
    }

    if (requirements['ratingNeeded'] > 0) {
      messages.add('Note ≥ ${(4.0 + requirements['ratingNeeded']).toStringAsFixed(1)}');
    }

    if (requirements['cautionNeeded'] > 0) {
      final caution = (requirements['cautionNeeded'] as double).toStringAsFixed(0);
      messages.add('Caution $caution FCFA');
    }

    if (messages.isEmpty) {
      return 'Vous pouvez passer au niveau $nextLevel !';
    }

    return 'Pour atteindre $nextLevel : ${messages.join(', ')}';
  }

  /// Vérifier si un livreur peut accepter une commande (montant)
  bool canAcceptOrder(double orderAmount) {
    return orderAmount <= maxOrderAmount;
  }

  /// Vérifier si un livreur peut accepter plus de livraisons (limite simultanée)
  bool canAcceptMoreDeliveries(int currentActiveDeliveries) {
    return currentActiveDeliveries < maxActiveDeliveries;
  }

  /// Obtenir le nombre de livraisons restantes que le livreur peut accepter
  int getRemainingDeliverySlots(int currentActiveDeliveries) {
    final remaining = maxActiveDeliveries - currentActiveDeliveries;
    return remaining > 0 ? remaining : 0;
  }

  /// Vérifier si le solde non reversé dépasse la limite
  bool exceedsUnpaidLimit(double currentUnpaidBalance) {
    return currentUnpaidBalance >= maxUnpaidBalance;
  }

  /// Obtenir le pourcentage du solde non reversé
  double getUnpaidBalancePercentage(double currentUnpaidBalance) {
    if (maxUnpaidBalance == 0) return 0;
    return (currentUnpaidBalance / maxUnpaidBalance) * 100;
  }
}
