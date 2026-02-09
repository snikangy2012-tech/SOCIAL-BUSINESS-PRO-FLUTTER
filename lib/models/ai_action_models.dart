// ===== lib/models/ai_action_models.dart =====
// Modèles pour les actions exécutables par l'assistant IA

/// Types d'actions exécutables par l'IA
enum AIActionType {
  // === Actions Vendeur ===
  confirmOrder,           // Confirmer une commande spécifique
  confirmAllPendingOrders,// Confirmer toutes les commandes en attente
  cancelOrder,            // Annuler/refuser une commande
  updateStock,            // Mettre à jour le stock d'un produit
  toggleProductStatus,    // Activer/désactiver un produit

  // === Actions Livreur ===
  acceptDelivery,         // Accepter une livraison
  markPickedUp,           // Marquer comme récupéré
  markDelivered,          // Marquer comme livré
  updateDeliveryStatus,   // Mettre à jour le statut de livraison

  // === Actions Acheteur ===
  cancelMyOrder,          // Annuler ma propre commande
  reorder,                // Recommander la même commande
}

/// Niveau de risque de l'action
enum ActionRiskLevel {
  low,      // Navigation, lecture seule - pas de confirmation
  medium,   // Modifications réversibles - confirmation simple
  high,     // Modifications critiques/irréversibles - confirmation renforcée
}

/// Définition d'une action exécutable
class AIExecutableAction {
  final AIActionType type;
  final String intentId;
  final String label;
  final String description;
  final ActionRiskLevel riskLevel;
  final List<String> requiredRoles;
  final List<String> requiredParams;
  final String confirmationTitle;
  final String confirmationMessage;
  final String successMessage;
  final String errorMessage;
  final bool requiresConfirmation;

  const AIExecutableAction({
    required this.type,
    required this.intentId,
    required this.label,
    this.description = '',
    required this.riskLevel,
    required this.requiredRoles,
    this.requiredParams = const [],
    required this.confirmationTitle,
    required this.confirmationMessage,
    required this.successMessage,
    this.errorMessage = 'Une erreur est survenue lors de l\'exécution.',
    this.requiresConfirmation = true,
  });

  /// Vérifie si l'utilisateur a le rôle requis
  bool canBeExecutedBy(String userType) {
    return requiredRoles.contains(userType);
  }

  /// Icône de risque selon le niveau
  String get riskIcon {
    switch (riskLevel) {
      case ActionRiskLevel.low:
        return '🟢';
      case ActionRiskLevel.medium:
        return '🟡';
      case ActionRiskLevel.high:
        return '🔴';
    }
  }

  /// Couleur de risque (pour UI)
  int get riskColorValue {
    switch (riskLevel) {
      case ActionRiskLevel.low:
        return 0xFF4CAF50; // Green
      case ActionRiskLevel.medium:
        return 0xFFFF9800; // Orange
      case ActionRiskLevel.high:
        return 0xFFF44336; // Red
    }
  }
}

/// Résultat d'exécution d'une action
class AIActionResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;
  final String? errorCode;
  final DateTime executedAt;
  final String? auditLogId;
  final List<ActionResultItem>? items; // Pour les actions en lot

  AIActionResult({
    required this.success,
    required this.message,
    this.data,
    this.errorCode,
    DateTime? executedAt,
    this.auditLogId,
    this.items,
  }) : executedAt = executedAt ?? DateTime.now();

  factory AIActionResult.success({
    required String message,
    Map<String, dynamic>? data,
    String? auditLogId,
    List<ActionResultItem>? items,
  }) {
    return AIActionResult(
      success: true,
      message: message,
      data: data,
      auditLogId: auditLogId,
      items: items,
    );
  }

  factory AIActionResult.failure({
    required String message,
    String? errorCode,
    Map<String, dynamic>? data,
  }) {
    return AIActionResult(
      success: false,
      message: message,
      errorCode: errorCode,
      data: data,
    );
  }

  Map<String, dynamic> toMap() => {
    'success': success,
    'message': message,
    'data': data,
    'errorCode': errorCode,
    'executedAt': executedAt.toIso8601String(),
    'auditLogId': auditLogId,
    'items': items?.map((i) => i.toMap()).toList(),
  };
}

/// Élément de résultat pour actions en lot
class ActionResultItem {
  final String id;
  final String label;
  final bool success;
  final String? error;

  const ActionResultItem({
    required this.id,
    required this.label,
    required this.success,
    this.error,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'label': label,
    'success': success,
    'error': error,
  };
}

/// Contexte d'exécution d'une action
class AIActionContext {
  final String userId;
  final String userType;
  final String? targetId;        // ID de la ressource cible
  final String? targetType;      // Type: order, product, delivery
  final Map<String, dynamic> parameters;
  final List<String>? targetIds; // Pour actions en lot
  final String? vendorId;        // ID du vendeur (pour contexte)

  const AIActionContext({
    required this.userId,
    required this.userType,
    this.targetId,
    this.targetType,
    this.parameters = const {},
    this.targetIds,
    this.vendorId,
  });

  /// Crée un contexte avec un paramètre ajouté
  AIActionContext copyWith({
    String? targetId,
    String? targetType,
    Map<String, dynamic>? parameters,
    List<String>? targetIds,
    String? vendorId,
  }) {
    return AIActionContext(
      userId: userId,
      userType: userType,
      targetId: targetId ?? this.targetId,
      targetType: targetType ?? this.targetType,
      parameters: parameters ?? this.parameters,
      targetIds: targetIds ?? this.targetIds,
      vendorId: vendorId ?? this.vendorId,
    );
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'userType': userType,
    'targetId': targetId,
    'targetType': targetType,
    'parameters': parameters,
    'targetIds': targetIds,
    'vendorId': vendorId,
  };
}

/// Résultat de validation avant exécution
class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  final String? errorCode;
  final Map<String, dynamic>? validationDetails;

  const ValidationResult({
    required this.isValid,
    this.errorMessage,
    this.errorCode,
    this.validationDetails,
  });

  factory ValidationResult.valid() => const ValidationResult(isValid: true);

  factory ValidationResult.invalid({
    required String message,
    String? code,
    Map<String, dynamic>? details,
  }) {
    return ValidationResult(
      isValid: false,
      errorMessage: message,
      errorCode: code,
      validationDetails: details,
    );
  }
}

/// Données de confirmation à afficher à l'utilisateur
class ConfirmationData {
  final String title;
  final String message;
  final ActionRiskLevel riskLevel;
  final List<ConfirmationDetailItem> details;
  final String? warningMessage;
  final String confirmButtonText;
  final String cancelButtonText;
  final int? totalAmount; // Montant total si applicable (en FCFA)
  final int? itemCount;   // Nombre d'éléments si action en lot

  const ConfirmationData({
    required this.title,
    required this.message,
    required this.riskLevel,
    this.details = const [],
    this.warningMessage,
    this.confirmButtonText = 'Confirmer',
    this.cancelButtonText = 'Annuler',
    this.totalAmount,
    this.itemCount,
  });
}

/// Détail à afficher dans la confirmation
class ConfirmationDetailItem {
  final String label;
  final String value;
  final String? icon;

  const ConfirmationDetailItem({
    required this.label,
    required this.value,
    this.icon,
  });
}

/// Intention d'action détectée dans un message
class DetectedActionIntent {
  final AIExecutableAction action;
  final double confidence; // 0.0 à 1.0
  final Map<String, String> extractedParams;
  final String matchedPattern;

  const DetectedActionIntent({
    required this.action,
    required this.confidence,
    this.extractedParams = const {},
    required this.matchedPattern,
  });

  bool get isHighConfidence => confidence >= 0.7;
}

/// Pattern de détection d'intention
class ActionIntentPattern {
  final AIActionType actionType;
  final List<String> keywords;
  final List<RegExp> patterns;
  final double baseConfidence;

  const ActionIntentPattern({
    required this.actionType,
    required this.keywords,
    this.patterns = const [],
    this.baseConfidence = 0.8,
  });
}
