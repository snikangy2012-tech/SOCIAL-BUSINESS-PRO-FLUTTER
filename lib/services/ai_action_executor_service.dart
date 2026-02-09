// ===== lib/services/ai_action_executor_service.dart =====
// Service d'exécution des actions via l'assistant IA
// Gère la détection d'intentions, validation et exécution des actions

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/ai_action_models.dart';
import '../models/order_model.dart';
import '../models/delivery_model.dart';
import '../models/audit_log_model.dart';
import '../config/constants.dart';
import 'order_service.dart';
import 'delivery_service.dart';
import 'audit_service.dart';
// import 'kyc_adaptive_service.dart'; // Reserved for future KYC tier checks
import 'kyc_verification_service.dart';
import '../utils/number_formatter.dart';

class AIActionExecutorService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ========== REGISTRE DES ACTIONS ==========

  /// Registre de toutes les actions disponibles par type
  static final Map<AIActionType, AIExecutableAction> _actionDefinitions = {
    // === ACTIONS VENDEUR ===
    AIActionType.confirmOrder: const AIExecutableAction(
      type: AIActionType.confirmOrder,
      intentId: 'confirm_order',
      label: 'Confirmer la commande',
      description: 'Marque la commande comme confirmée et prête pour la livraison',
      riskLevel: ActionRiskLevel.medium,
      requiredRoles: ['vendeur'],
      requiredParams: ['orderId'],
      confirmationTitle: 'Confirmer cette commande ?',
      confirmationMessage: 'La commande #{orderNumber} sera marquée comme confirmée et le client sera notifié.',
      successMessage: 'Commande #{orderNumber} confirmée avec succès !',
      errorMessage: 'Impossible de confirmer la commande.',
      requiresConfirmation: true,
    ),

    AIActionType.confirmAllPendingOrders: const AIExecutableAction(
      type: AIActionType.confirmAllPendingOrders,
      intentId: 'confirm_all_orders',
      label: 'Confirmer toutes les commandes en attente',
      description: 'Confirme toutes les commandes en attente en une seule action',
      riskLevel: ActionRiskLevel.high,
      requiredRoles: ['vendeur'],
      requiredParams: [],
      confirmationTitle: 'Confirmer TOUTES les commandes ?',
      confirmationMessage: 'Vous allez confirmer {count} commande(s) en attente pour un total de {totalAmount}.',
      successMessage: '{count} commande(s) confirmée(s) avec succès !',
      errorMessage: 'Erreur lors de la confirmation des commandes.',
      requiresConfirmation: true,
    ),

    AIActionType.cancelOrder: const AIExecutableAction(
      type: AIActionType.cancelOrder,
      intentId: 'cancel_order',
      label: 'Annuler la commande',
      description: 'Annule la commande et libère le stock réservé',
      riskLevel: ActionRiskLevel.high,
      requiredRoles: ['vendeur'],
      requiredParams: ['orderId'],
      confirmationTitle: 'Annuler cette commande ?',
      confirmationMessage: 'La commande #{orderNumber} sera annulée. Cette action est irréversible.',
      successMessage: 'Commande #{orderNumber} annulée.',
      errorMessage: 'Impossible d\'annuler la commande.',
      requiresConfirmation: true,
    ),

    AIActionType.updateStock: const AIExecutableAction(
      type: AIActionType.updateStock,
      intentId: 'update_stock',
      label: 'Mettre à jour le stock',
      description: 'Modifie le stock disponible d\'un produit',
      riskLevel: ActionRiskLevel.medium,
      requiredRoles: ['vendeur'],
      requiredParams: ['productId', 'quantity'],
      confirmationTitle: 'Modifier le stock ?',
      confirmationMessage: 'Le stock de "{productName}" passera à {newQuantity} unités.',
      successMessage: 'Stock mis à jour avec succès !',
      errorMessage: 'Impossible de mettre à jour le stock.',
      requiresConfirmation: true,
    ),

    AIActionType.toggleProductStatus: const AIExecutableAction(
      type: AIActionType.toggleProductStatus,
      intentId: 'toggle_product',
      label: 'Activer/Désactiver le produit',
      description: 'Active ou désactive la visibilité d\'un produit',
      riskLevel: ActionRiskLevel.medium,
      requiredRoles: ['vendeur'],
      requiredParams: ['productId'],
      confirmationTitle: 'Modifier la visibilité du produit ?',
      confirmationMessage: 'Le produit "{productName}" sera {action}.',
      successMessage: 'Produit {action} avec succès !',
      errorMessage: 'Impossible de modifier le produit.',
      requiresConfirmation: true,
    ),

    // === ACTIONS LIVREUR ===
    AIActionType.acceptDelivery: const AIExecutableAction(
      type: AIActionType.acceptDelivery,
      intentId: 'accept_delivery',
      label: 'Accepter la livraison',
      description: 'Accepte une livraison disponible',
      riskLevel: ActionRiskLevel.medium,
      requiredRoles: ['livreur'],
      requiredParams: ['deliveryId'],
      confirmationTitle: 'Accepter cette livraison ?',
      confirmationMessage: 'Vous acceptez la livraison vers {address}.\nMontant: {amount}',
      successMessage: 'Livraison acceptée ! Dirigez-vous vers le point de retrait.',
      errorMessage: 'Impossible d\'accepter la livraison.',
      requiresConfirmation: true,
    ),

    AIActionType.markPickedUp: const AIExecutableAction(
      type: AIActionType.markPickedUp,
      intentId: 'mark_picked_up',
      label: 'Marquer comme récupéré',
      description: 'Indique que le colis a été récupéré chez le vendeur',
      riskLevel: ActionRiskLevel.low,
      requiredRoles: ['livreur'],
      requiredParams: ['deliveryId'],
      confirmationTitle: 'Confirmer la récupération ?',
      confirmationMessage: 'Vous confirmez avoir récupéré le colis pour la commande #{orderNumber}.',
      successMessage: 'Colis marqué comme récupéré. Dirigez-vous vers le client.',
      errorMessage: 'Impossible de mettre à jour le statut.',
      requiresConfirmation: false,
    ),

    AIActionType.markDelivered: const AIExecutableAction(
      type: AIActionType.markDelivered,
      intentId: 'mark_delivered',
      label: 'Marquer comme livré',
      description: 'Indique que la livraison est terminée',
      riskLevel: ActionRiskLevel.medium,
      requiredRoles: ['livreur'],
      requiredParams: ['deliveryId'],
      confirmationTitle: 'Confirmer la livraison ?',
      confirmationMessage: 'Vous confirmez avoir remis le colis au client pour la commande #{orderNumber}.',
      successMessage: 'Livraison terminée avec succès !',
      errorMessage: 'Impossible de marquer la livraison comme terminée.',
      requiresConfirmation: true,
    ),

    // === ACTIONS ACHETEUR ===
    AIActionType.cancelMyOrder: const AIExecutableAction(
      type: AIActionType.cancelMyOrder,
      intentId: 'cancel_my_order',
      label: 'Annuler ma commande',
      description: 'Annule votre propre commande (si encore possible)',
      riskLevel: ActionRiskLevel.high,
      requiredRoles: ['acheteur'],
      requiredParams: ['orderId'],
      confirmationTitle: 'Annuler votre commande ?',
      confirmationMessage: 'La commande #{orderNumber} de {totalAmount} sera annulée.\nCette action est irréversible.',
      successMessage: 'Votre commande a été annulée.',
      errorMessage: 'Impossible d\'annuler la commande. Elle est peut-être déjà en cours de préparation.',
      requiresConfirmation: true,
    ),

    AIActionType.reorder: const AIExecutableAction(
      type: AIActionType.reorder,
      intentId: 'reorder',
      label: 'Recommander',
      description: 'Crée une nouvelle commande identique à une commande précédente',
      riskLevel: ActionRiskLevel.medium,
      requiredRoles: ['acheteur'],
      requiredParams: ['orderId'],
      confirmationTitle: 'Recommander ?',
      confirmationMessage: 'Vous allez créer une nouvelle commande identique à #{orderNumber} pour {totalAmount}.',
      successMessage: 'Nouvelle commande créée avec succès !',
      errorMessage: 'Impossible de recréer la commande.',
      requiresConfirmation: true,
    ),
  };

  /// Patterns de détection d'intentions pour chaque action
  static final List<ActionIntentPattern> _intentPatterns = [
    // Confirmer commande
    ActionIntentPattern(
      actionType: AIActionType.confirmOrder,
      keywords: ['confirme', 'confirmer', 'valide', 'valider', 'accepte', 'accepter'],
      patterns: [
        RegExp(r'confirme?\s*(?:la\s*)?commande\s*#?(\d+)?', caseSensitive: false),
        RegExp(r'valide?\s*(?:la\s*)?commande\s*#?(\d+)?', caseSensitive: false),
        RegExp(r'accepte?\s*(?:la\s*)?commande\s*#?(\d+)?', caseSensitive: false),
      ],
      baseConfidence: 0.85,
    ),

    // Confirmer toutes les commandes
    ActionIntentPattern(
      actionType: AIActionType.confirmAllPendingOrders,
      keywords: ['confirme toutes', 'valide tout', 'toutes les commandes', 'confirmer tout'],
      patterns: [
        RegExp(r'confirme[rs]?\s*(?:toutes?\s*)?(?:les\s*)?commandes?\s*(?:en\s*attente)?', caseSensitive: false),
        RegExp(r'valide[rs]?\s*(?:tout(?:es)?|les\s*commandes)', caseSensitive: false),
        RegExp(r'tout\s*confirmer', caseSensitive: false),
      ],
      baseConfidence: 0.9,
    ),

    // Annuler commande (vendeur)
    ActionIntentPattern(
      actionType: AIActionType.cancelOrder,
      keywords: ['annule', 'annuler', 'refuse', 'refuser', 'rejette', 'rejeter'],
      patterns: [
        RegExp(r'annule[rs]?\s*(?:la\s*)?commande\s*#?(\d+)?', caseSensitive: false),
        RegExp(r'refuse[rs]?\s*(?:la\s*)?commande\s*#?(\d+)?', caseSensitive: false),
        RegExp(r'rejette[rs]?\s*(?:la\s*)?commande\s*#?(\d+)?', caseSensitive: false),
      ],
      baseConfidence: 0.85,
    ),

    // Mettre à jour stock
    ActionIntentPattern(
      actionType: AIActionType.updateStock,
      keywords: ['stock', 'ajoute stock', 'maj stock', 'modifier stock', 'mettre à jour stock'],
      patterns: [
        RegExp(r'(?:met(?:s|tre)?\s*[àa]\s*jour|maj|modifier?)\s*(?:le\s*)?stock', caseSensitive: false),
        RegExp(r'ajoute[rs]?\s*(\d+)\s*(?:au\s*)?stock', caseSensitive: false),
        RegExp(r'stock\s*[=:à]\s*(\d+)', caseSensitive: false),
      ],
      baseConfidence: 0.8,
    ),

    // Activer/désactiver produit
    ActionIntentPattern(
      actionType: AIActionType.toggleProductStatus,
      keywords: ['désactive', 'active', 'masque', 'affiche', 'cache', 'montre'],
      patterns: [
        RegExp(r'(?:dés)?activer?\s*(?:le\s*)?produit', caseSensitive: false),
        RegExp(r'masque[rs]?\s*(?:le\s*)?produit', caseSensitive: false),
        RegExp(r'cache[rs]?\s*(?:le\s*)?produit', caseSensitive: false),
      ],
      baseConfidence: 0.8,
    ),

    // Accepter livraison
    ActionIntentPattern(
      actionType: AIActionType.acceptDelivery,
      keywords: ['accepte livraison', 'prends livraison', 'je prends', "j'accepte"],
      patterns: [
        RegExp("(?:j')?accepte[rs]?\\s*(?:la\\s*|cette\\s*)?livraison", caseSensitive: false),
        RegExp("(?:je\\s*)?prends?\\s*(?:la\\s*|cette\\s*)?livraison", caseSensitive: false),
        RegExp(r'assigne[rs]?\s*(?:-moi\s*)?(?:la\s*)?livraison', caseSensitive: false),
      ],
      baseConfidence: 0.85,
    ),

    // Marquer récupéré
    ActionIntentPattern(
      actionType: AIActionType.markPickedUp,
      keywords: ['recupere', "j'ai le colis", 'colis recupere', "j'ai recupere"],
      patterns: [
        RegExp("(?:j'ai\\s*)?r[eé]cup[eé]r[eé](?:\\s*le\\s*colis)?", caseSensitive: false),
        RegExp(r'colis\s*r[eé]cup[eé]r[eé]', caseSensitive: false),
        RegExp("j'ai\\s*(?:le\\s*)?colis", caseSensitive: false),
      ],
      baseConfidence: 0.85,
    ),

    // Marquer livré
    ActionIntentPattern(
      actionType: AIActionType.markDelivered,
      keywords: ['livre', 'livraison terminee', 'client a recu', 'remis au client'],
      patterns: [
        RegExp(r'(?:commande\s*)?livr[eé]e?', caseSensitive: false),
        RegExp(r'livraison\s*termin[eé]e', caseSensitive: false),
        RegExp("(?:j'ai\\s*)?remis\\s*(?:au\\s*)?client", caseSensitive: false),
        RegExp(r'client\s*a\s*re[cç]u', caseSensitive: false),
      ],
      baseConfidence: 0.85,
    ),

    // Annuler ma commande (acheteur)
    ActionIntentPattern(
      actionType: AIActionType.cancelMyOrder,
      keywords: ['annule ma commande', 'annuler ma commande', 'je veux annuler'],
      patterns: [
        RegExp(r'annule[rs]?\s*ma\s*commande', caseSensitive: false),
        RegExp(r'je\s*veux?\s*annule[rs]?\s*(?:ma\s*)?commande', caseSensitive: false),
      ],
      baseConfidence: 0.9,
    ),

    // Recommander
    ActionIntentPattern(
      actionType: AIActionType.reorder,
      keywords: ['recommande', 'recommander', 'meme commande', 'refaire la commande'],
      patterns: [
        RegExp(r'recommande[rs]?\s*(?:la\s*)?(?:m[eê]me\s*)?(?:commande)?', caseSensitive: false),
        RegExp(r'refaire?\s*(?:la\s*)?(?:m[eê]me\s*)?commande', caseSensitive: false),
        RegExp("(?:la\\s*)?m[eê]me\\s*commande\\s*(?:svp|s'il\\s*vous\\s*pla[iî]t)?", caseSensitive: false),
      ],
      baseConfidence: 0.85,
    ),
  ];

  // ========== DÉTECTION D'INTENTIONS ==========

  /// Détecte si le message contient une intention d'action
  /// Retourne null si aucune action n'est détectée
  static DetectedActionIntent? detectActionIntent(String message, String userType) {
    final normalizedMessage = message.toLowerCase().trim();

    DetectedActionIntent? bestMatch;
    double bestConfidence = 0.0;

    for (final pattern in _intentPatterns) {
      // Vérifier si l'action est disponible pour ce type d'utilisateur
      final actionDef = _actionDefinitions[pattern.actionType];
      if (actionDef == null || !actionDef.canBeExecutedBy(userType)) {
        continue;
      }

      double confidence = 0.0;
      String matchedPattern = '';
      final extractedParams = <String, String>{};

      // Vérifier les mots-clés
      for (final keyword in pattern.keywords) {
        if (normalizedMessage.contains(keyword.toLowerCase())) {
          confidence = pattern.baseConfidence * 0.7; // 70% du score de base pour les keywords
          matchedPattern = keyword;
          break;
        }
      }

      // Vérifier les patterns regex (score plus élevé)
      for (final regex in pattern.patterns) {
        final match = regex.firstMatch(normalizedMessage);
        if (match != null) {
          confidence = pattern.baseConfidence;
          matchedPattern = match.group(0) ?? '';

          // Extraire les paramètres capturés
          for (var i = 1; i <= match.groupCount; i++) {
            final group = match.group(i);
            if (group != null && group.isNotEmpty) {
              // Le premier groupe capturé est souvent un ID ou nombre
              if (i == 1) {
                extractedParams['capturedId'] = group;
              } else {
                extractedParams['param$i'] = group;
              }
            }
          }
          break;
        }
      }

      // Mettre à jour le meilleur match si meilleure confiance
      if (confidence > bestConfidence) {
        bestConfidence = confidence;
        bestMatch = DetectedActionIntent(
          action: actionDef,
          confidence: confidence,
          extractedParams: extractedParams,
          matchedPattern: matchedPattern,
        );
      }
    }

    // Ne retourner que si la confiance est suffisante
    if (bestMatch != null && bestMatch.confidence >= 0.6) {
      debugPrint('🎯 Action détectée: ${bestMatch.action.label} (confiance: ${(bestMatch.confidence * 100).toStringAsFixed(0)}%)');
      return bestMatch;
    }

    return null;
  }

  /// Obtient la définition d'une action par son type
  static AIExecutableAction? getActionDefinition(AIActionType type) {
    return _actionDefinitions[type];
  }

  /// Retourne les actions disponibles pour un type d'utilisateur
  static List<AIExecutableAction> getAvailableActions(String userType) {
    return _actionDefinitions.values
        .where((action) => action.canBeExecutedBy(userType))
        .toList();
  }

  // ========== VALIDATION ==========

  /// Valide les préconditions avant exécution
  static Future<ValidationResult> validateAction(
    AIExecutableAction action,
    AIActionContext context,
  ) async {
    try {
      debugPrint('🔍 Validation de l\'action: ${action.label}');

      // 1. Vérifier le rôle utilisateur
      if (!action.canBeExecutedBy(context.userType)) {
        return ValidationResult.invalid(
          message: 'Vous n\'avez pas les droits pour effectuer cette action.',
          code: 'unauthorized_role',
        );
      }

      // 2. Vérifier les paramètres requis
      for (final param in action.requiredParams) {
        if (param == 'orderId' && context.targetId == null && context.targetIds == null) {
          return ValidationResult.invalid(
            message: 'Veuillez spécifier la commande concernée.',
            code: 'missing_order_id',
          );
        }
        if (param == 'deliveryId' && context.targetId == null) {
          return ValidationResult.invalid(
            message: 'Veuillez spécifier la livraison concernée.',
            code: 'missing_delivery_id',
          );
        }
        if (param == 'productId' && context.targetId == null) {
          return ValidationResult.invalid(
            message: 'Veuillez spécifier le produit concerné.',
            code: 'missing_product_id',
          );
        }
      }

      // 3. Validations spécifiques par action
      switch (action.type) {
        case AIActionType.confirmOrder:
        case AIActionType.cancelOrder:
          return _validateOrderAction(action, context);

        case AIActionType.confirmAllPendingOrders:
          return _validateConfirmAllOrders(context);

        case AIActionType.acceptDelivery:
          return _validateAcceptDelivery(context);

        case AIActionType.markPickedUp:
        case AIActionType.markDelivered:
          return _validateDeliveryStatusUpdate(action, context);

        case AIActionType.cancelMyOrder:
          return _validateBuyerCancelOrder(context);

        case AIActionType.updateStock:
        case AIActionType.toggleProductStatus:
          return ValidationResult.valid();

        case AIActionType.reorder:
          return _validateReorder(context);

        default:
          return ValidationResult.valid();
      }
    } catch (e) {
      debugPrint('❌ Erreur validation: $e');
      return ValidationResult.invalid(
        message: 'Erreur lors de la validation: $e',
        code: 'validation_error',
      );
    }
  }

  /// Valide une action sur une commande (vendeur)
  static Future<ValidationResult> _validateOrderAction(
    AIExecutableAction action,
    AIActionContext context,
  ) async {
    if (context.targetId == null) {
      return ValidationResult.invalid(
        message: 'ID de commande manquant.',
        code: 'missing_order_id',
      );
    }

    final order = await OrderService.getOrderById(context.targetId!);
    if (order == null) {
      return ValidationResult.invalid(
        message: 'Commande introuvable.',
        code: 'order_not_found',
      );
    }

    // Vérifier que la commande appartient au vendeur
    if (order.vendeurId != context.userId && order.vendeurId != context.vendorId) {
      return ValidationResult.invalid(
        message: 'Cette commande ne vous appartient pas.',
        code: 'unauthorized_order',
      );
    }

    // Vérifications spécifiques selon l'action
    if (action.type == AIActionType.confirmOrder) {
      if (order.status != OrderStatus.enAttente.value) {
        return ValidationResult.invalid(
          message: 'Cette commande n\'est pas en attente de confirmation.',
          code: 'invalid_order_status',
          details: {'currentStatus': order.status},
        );
      }
    }

    if (action.type == AIActionType.cancelOrder) {
      if (order.status == OrderStatus.livree.value) {
        return ValidationResult.invalid(
          message: 'Cette commande a déjà été livrée et ne peut pas être annulée.',
          code: 'order_already_delivered',
        );
      }
      if (order.status == OrderStatus.annulee.value) {
        return ValidationResult.invalid(
          message: 'Cette commande est déjà annulée.',
          code: 'order_already_cancelled',
        );
      }
    }

    return ValidationResult.valid();
  }

  /// Valide la confirmation de toutes les commandes en attente
  static Future<ValidationResult> _validateConfirmAllOrders(AIActionContext context) async {
    final vendorId = context.vendorId ?? context.userId;
    final pendingOrders = await _getPendingOrdersForVendor(vendorId);

    if (pendingOrders.isEmpty) {
      return ValidationResult.invalid(
        message: 'Vous n\'avez aucune commande en attente à confirmer.',
        code: 'no_pending_orders',
      );
    }

    return ValidationResult.valid();
  }

  /// Valide l'acceptation d'une livraison
  static Future<ValidationResult> _validateAcceptDelivery(AIActionContext context) async {
    // Vérifier KYC du livreur
    final canDeliver = await KYCVerificationService.canPerformAction(
      context.userId,
      'deliver',
    );

    if (!canDeliver) {
      return ValidationResult.invalid(
        message: 'Votre compte doit être vérifié avant d\'accepter des livraisons. Complétez vos documents dans "Profil > Gestion des documents".',
        code: 'kyc_required',
      );
    }

    return ValidationResult.valid();
  }

  /// Valide une mise à jour de statut de livraison
  static Future<ValidationResult> _validateDeliveryStatusUpdate(
    AIExecutableAction action,
    AIActionContext context,
  ) async {
    if (context.targetId == null) {
      return ValidationResult.invalid(
        message: 'ID de livraison manquant.',
        code: 'missing_delivery_id',
      );
    }

    final delivery = await DeliveryService.getDeliveryByOrderId(context.targetId!);
    if (delivery == null) {
      return ValidationResult.invalid(
        message: 'Livraison introuvable.',
        code: 'delivery_not_found',
      );
    }

    // Vérifier que c'est bien le livreur assigné
    if (delivery.livreurId != context.userId) {
      return ValidationResult.invalid(
        message: 'Cette livraison ne vous est pas assignée.',
        code: 'unauthorized_delivery',
      );
    }

    return ValidationResult.valid();
  }

  /// Valide l'annulation d'une commande par l'acheteur
  static Future<ValidationResult> _validateBuyerCancelOrder(AIActionContext context) async {
    if (context.targetId == null) {
      return ValidationResult.invalid(
        message: 'ID de commande manquant.',
        code: 'missing_order_id',
      );
    }

    final order = await OrderService.getOrderById(context.targetId!);
    if (order == null) {
      return ValidationResult.invalid(
        message: 'Commande introuvable.',
        code: 'order_not_found',
      );
    }

    // Vérifier que la commande appartient à l'acheteur
    if (order.buyerId != context.userId) {
      return ValidationResult.invalid(
        message: 'Cette commande ne vous appartient pas.',
        code: 'unauthorized_order',
      );
    }

    // L'acheteur ne peut annuler que les commandes en attente
    if (order.status != OrderStatus.enAttente.value) {
      return ValidationResult.invalid(
        message: 'Cette commande ne peut plus être annulée car elle est déjà en cours de traitement.',
        code: 'order_processing',
        details: {'currentStatus': order.status},
      );
    }

    return ValidationResult.valid();
  }

  /// Valide une recommande
  static Future<ValidationResult> _validateReorder(AIActionContext context) async {
    if (context.targetId == null) {
      return ValidationResult.invalid(
        message: 'ID de commande manquant.',
        code: 'missing_order_id',
      );
    }

    final order = await OrderService.getOrderById(context.targetId!);
    if (order == null) {
      return ValidationResult.invalid(
        message: 'Commande introuvable.',
        code: 'order_not_found',
      );
    }

    // Vérifier que la commande appartient à l'acheteur
    if (order.buyerId != context.userId) {
      return ValidationResult.invalid(
        message: 'Cette commande ne vous appartient pas.',
        code: 'unauthorized_order',
      );
    }

    return ValidationResult.valid();
  }

  // ========== PRÉPARATION DE LA CONFIRMATION ==========

  /// Prépare les données de confirmation à afficher
  static Future<ConfirmationData> prepareConfirmation(
    AIExecutableAction action,
    AIActionContext context,
  ) async {
    switch (action.type) {
      case AIActionType.confirmOrder:
      case AIActionType.cancelOrder:
      case AIActionType.cancelMyOrder:
        return _prepareOrderConfirmation(action, context);

      case AIActionType.confirmAllPendingOrders:
        return _prepareConfirmAllOrdersConfirmation(context);

      case AIActionType.acceptDelivery:
        return _prepareDeliveryConfirmation(action, context);

      case AIActionType.markPickedUp:
      case AIActionType.markDelivered:
        return _prepareDeliveryStatusConfirmation(action, context);

      default:
        return ConfirmationData(
          title: action.confirmationTitle,
          message: action.confirmationMessage,
          riskLevel: action.riskLevel,
        );
    }
  }

  /// Prépare la confirmation pour une action sur commande
  static Future<ConfirmationData> _prepareOrderConfirmation(
    AIExecutableAction action,
    AIActionContext context,
  ) async {
    final order = await OrderService.getOrderById(context.targetId!);
    if (order == null) {
      return ConfirmationData(
        title: 'Erreur',
        message: 'Commande introuvable',
        riskLevel: ActionRiskLevel.high,
      );
    }

    final details = <ConfirmationDetailItem>[
      ConfirmationDetailItem(
        label: 'Commande',
        value: '#${order.displayNumber}',
        icon: '📦',
      ),
      ConfirmationDetailItem(
        label: 'Client',
        value: order.buyerName,
        icon: '👤',
      ),
      ConfirmationDetailItem(
        label: 'Montant',
        value: formatPriceWithCurrency(order.totalAmount.toInt(), currency: 'FCFA'),
        icon: '💰',
      ),
      ConfirmationDetailItem(
        label: 'Articles',
        value: '${order.items.length} article(s)',
        icon: '🛒',
      ),
    ];

    String? warning;
    if (action.type == AIActionType.cancelOrder || action.type == AIActionType.cancelMyOrder) {
      warning = '⚠️ Cette action est irréversible. Le stock sera libéré et le client sera notifié.';
    }

    return ConfirmationData(
      title: action.confirmationTitle.replaceAll('{orderNumber}', '${order.displayNumber}'),
      message: action.confirmationMessage
          .replaceAll('{orderNumber}', '${order.displayNumber}')
          .replaceAll('{totalAmount}', formatPriceWithCurrency(order.totalAmount.toInt(), currency: 'FCFA')),
      riskLevel: action.riskLevel,
      details: details,
      warningMessage: warning,
      totalAmount: order.totalAmount.toInt(),
    );
  }

  /// Prépare la confirmation pour confirmer toutes les commandes
  static Future<ConfirmationData> _prepareConfirmAllOrdersConfirmation(
    AIActionContext context,
  ) async {
    final vendorId = context.vendorId ?? context.userId;
    final pendingOrders = await _getPendingOrdersForVendor(vendorId);

    final totalAmount = pendingOrders.fold<double>(
      0.0,
      (sum, order) => sum + order.totalAmount,
    );

    final details = <ConfirmationDetailItem>[];
    for (final order in pendingOrders.take(5)) {
      details.add(ConfirmationDetailItem(
        label: '#${order.displayNumber}',
        value: '${formatPriceWithCurrency(order.totalAmount.toInt(), currency: 'FCFA')} - ${order.buyerName}',
        icon: '📦',
      ));
    }

    if (pendingOrders.length > 5) {
      details.add(ConfirmationDetailItem(
        label: '...',
        value: '+ ${pendingOrders.length - 5} autre(s) commande(s)',
        icon: '📦',
      ));
    }

    final action = _actionDefinitions[AIActionType.confirmAllPendingOrders]!;

    return ConfirmationData(
      title: action.confirmationTitle,
      message: action.confirmationMessage
          .replaceAll('{count}', '${pendingOrders.length}')
          .replaceAll('{totalAmount}', formatPriceWithCurrency(totalAmount.toInt(), currency: 'FCFA')),
      riskLevel: action.riskLevel,
      details: details,
      warningMessage: pendingOrders.length > 3
          ? '⚠️ Attention: Vous allez confirmer ${pendingOrders.length} commandes en même temps.'
          : null,
      totalAmount: totalAmount.toInt(),
      itemCount: pendingOrders.length,
    );
  }

  /// Prépare la confirmation pour accepter une livraison
  static Future<ConfirmationData> _prepareDeliveryConfirmation(
    AIExecutableAction action,
    AIActionContext context,
  ) async {
    DeliveryModel? delivery;
    if (context.targetId != null) {
      delivery = await DeliveryService.getDeliveryByOrderId(context.targetId!);
    }

    if (delivery == null) {
      return ConfirmationData(
        title: action.confirmationTitle,
        message: 'Détails de la livraison non disponibles.',
        riskLevel: action.riskLevel,
      );
    }

    final details = <ConfirmationDetailItem>[
      ConfirmationDetailItem(
        label: 'Point de retrait',
        value: delivery.pickupAddress['address'] ?? 'Non spécifié',
        icon: '📍',
      ),
      ConfirmationDetailItem(
        label: 'Destination',
        value: delivery.deliveryAddress['address'] ?? 'Non spécifié',
        icon: '🏠',
      ),
      ConfirmationDetailItem(
        label: 'Distance',
        value: '${delivery.distance.toStringAsFixed(1)} km',
        icon: '🛣️',
      ),
      ConfirmationDetailItem(
        label: 'Gain estimé',
        value: formatPriceWithCurrency(delivery.deliveryFee.toInt(), currency: 'FCFA'),
        icon: '💰',
      ),
    ];

    return ConfirmationData(
      title: action.confirmationTitle,
      message: action.confirmationMessage
          .replaceAll('{address}', delivery.deliveryAddress['address'] ?? 'l\'adresse indiquée')
          .replaceAll('{amount}', formatPriceWithCurrency(delivery.deliveryFee.toInt(), currency: 'FCFA')),
      riskLevel: action.riskLevel,
      details: details,
      totalAmount: delivery.deliveryFee.toInt(),
    );
  }

  /// Prépare la confirmation pour mise à jour statut livraison
  static Future<ConfirmationData> _prepareDeliveryStatusConfirmation(
    AIExecutableAction action,
    AIActionContext context,
  ) async {
    final order = await OrderService.getOrderById(context.targetId!);

    return ConfirmationData(
      title: action.confirmationTitle.replaceAll('{orderNumber}', '${order?.displayNumber ?? context.targetId}'),
      message: action.confirmationMessage.replaceAll('{orderNumber}', '${order?.displayNumber ?? context.targetId}'),
      riskLevel: action.riskLevel,
      details: order != null
          ? [
              ConfirmationDetailItem(
                label: 'Client',
                value: order.buyerName,
                icon: '👤',
              ),
              ConfirmationDetailItem(
                label: 'Adresse',
                value: order.deliveryAddress.isNotEmpty ? order.deliveryAddress : 'Non spécifiée',
                icon: '📍',
              ),
            ]
          : [],
    );
  }

  // ========== EXÉCUTION ==========

  /// Exécute l'action après confirmation
  static Future<AIActionResult> executeAction(
    AIExecutableAction action,
    AIActionContext context, {
    String? userEmail,
    String? userName,
  }) async {
    try {
      debugPrint('⚡ Exécution de l\'action: ${action.label}');

      // Exécuter selon le type d'action
      AIActionResult result;

      switch (action.type) {
        case AIActionType.confirmOrder:
          result = await _executeConfirmOrder(context, userEmail, userName);
          break;

        case AIActionType.confirmAllPendingOrders:
          result = await _executeConfirmAllOrders(context, userEmail, userName);
          break;

        case AIActionType.cancelOrder:
          result = await _executeCancelOrder(context, userEmail, userName, isVendor: true);
          break;

        case AIActionType.updateStock:
          result = await _executeUpdateStock(context);
          break;

        case AIActionType.toggleProductStatus:
          result = await _executeToggleProduct(context);
          break;

        case AIActionType.acceptDelivery:
          result = await _executeAcceptDelivery(context);
          break;

        case AIActionType.markPickedUp:
          result = await _executeMarkPickedUp(context);
          break;

        case AIActionType.markDelivered:
          result = await _executeMarkDelivered(context);
          break;

        case AIActionType.cancelMyOrder:
          result = await _executeCancelOrder(context, userEmail, userName, isVendor: false);
          break;

        case AIActionType.reorder:
          result = await _executeReorder(context);
          break;

        default:
          result = AIActionResult.failure(
            message: 'Action non implémentée.',
            errorCode: 'not_implemented',
          );
      }

      // Logger l'action dans l'audit
      if (result.success) {
        await _logActionToAudit(action, context, result, userEmail, userName);
      }

      return result;
    } catch (e) {
      debugPrint('❌ Erreur exécution action: $e');
      return AIActionResult.failure(
        message: 'Erreur lors de l\'exécution: $e',
        errorCode: 'execution_error',
      );
    }
  }

  // ========== IMPLÉMENTATIONS DES ACTIONS ==========

  /// Confirme une seule commande
  static Future<AIActionResult> _executeConfirmOrder(
    AIActionContext context,
    String? userEmail,
    String? userName,
  ) async {
    try {
      final order = await OrderService.getOrderById(context.targetId!);
      if (order == null) {
        return AIActionResult.failure(message: 'Commande introuvable.');
      }

      await OrderService.updateOrderStatus(
        context.targetId!,
        'en_cours',
        userId: context.userId,
        userEmail: userEmail ?? '',
        userName: userName,
        userType: context.userType,
      );

      return AIActionResult.success(
        message: 'Commande #${order.displayNumber} confirmée avec succès !',
        data: {
          'orderId': context.targetId,
          'orderNumber': order.displayNumber,
          'newStatus': 'en_cours',
        },
      );
    } catch (e) {
      return AIActionResult.failure(message: 'Erreur: $e');
    }
  }

  /// Confirme toutes les commandes en attente
  static Future<AIActionResult> _executeConfirmAllOrders(
    AIActionContext context,
    String? userEmail,
    String? userName,
  ) async {
    try {
      final vendorId = context.vendorId ?? context.userId;
      final pendingOrders = await _getPendingOrdersForVendor(vendorId);

      if (pendingOrders.isEmpty) {
        return AIActionResult.failure(message: 'Aucune commande en attente.');
      }

      final results = <ActionResultItem>[];
      int successCount = 0;

      for (final order in pendingOrders) {
        try {
          await OrderService.updateOrderStatus(
            order.id,
            'en_cours',
            userId: context.userId,
            userEmail: userEmail ?? '',
            userName: userName,
            userType: context.userType,
          );

          results.add(ActionResultItem(
            id: order.id,
            label: '#${order.displayNumber}',
            success: true,
          ));
          successCount++;
        } catch (e) {
          results.add(ActionResultItem(
            id: order.id,
            label: '#${order.displayNumber}',
            success: false,
            error: e.toString(),
          ));
        }
      }

      return AIActionResult.success(
        message: '$successCount commande(s) confirmée(s) avec succès !',
        data: {
          'totalCount': pendingOrders.length,
          'successCount': successCount,
          'failedCount': pendingOrders.length - successCount,
        },
        items: results,
      );
    } catch (e) {
      return AIActionResult.failure(message: 'Erreur: $e');
    }
  }

  /// Annule une commande
  static Future<AIActionResult> _executeCancelOrder(
    AIActionContext context,
    String? userEmail,
    String? userName, {
    required bool isVendor,
  }) async {
    try {
      final order = await OrderService.getOrderById(context.targetId!);
      if (order == null) {
        return AIActionResult.failure(message: 'Commande introuvable.');
      }

      final reason = context.parameters['reason'] as String? ??
          (isVendor ? 'Annulée par le vendeur via Assistant IA' : 'Annulée par le client via Assistant IA');

      await OrderService.cancelOrder(
        context.targetId!,
        reason,
        userId: context.userId,
        userEmail: userEmail ?? '',
        userName: userName,
        userType: context.userType,
      );

      return AIActionResult.success(
        message: 'Commande #${order.displayNumber} annulée.',
        data: {
          'orderId': context.targetId,
          'orderNumber': order.displayNumber,
          'reason': reason,
        },
      );
    } catch (e) {
      return AIActionResult.failure(message: 'Erreur: $e');
    }
  }

  /// Met à jour le stock d'un produit
  static Future<AIActionResult> _executeUpdateStock(AIActionContext context) async {
    try {
      final productId = context.targetId;
      final newQuantity = context.parameters['quantity'] as int?;

      if (productId == null || newQuantity == null) {
        return AIActionResult.failure(message: 'Paramètres manquants.');
      }

      await _firestore.collection(FirebaseCollections.products).doc(productId).update({
        'stock': newQuantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return AIActionResult.success(
        message: 'Stock mis à jour: $newQuantity unités.',
        data: {
          'productId': productId,
          'newStock': newQuantity,
        },
      );
    } catch (e) {
      return AIActionResult.failure(message: 'Erreur: $e');
    }
  }

  /// Active/désactive un produit
  static Future<AIActionResult> _executeToggleProduct(AIActionContext context) async {
    try {
      final productId = context.targetId;
      final activate = context.parameters['activate'] as bool? ?? true;

      if (productId == null) {
        return AIActionResult.failure(message: 'ID produit manquant.');
      }

      await _firestore.collection(FirebaseCollections.products).doc(productId).update({
        'isActive': activate,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return AIActionResult.success(
        message: 'Produit ${activate ? "activé" : "désactivé"} avec succès.',
        data: {
          'productId': productId,
          'isActive': activate,
        },
      );
    } catch (e) {
      return AIActionResult.failure(message: 'Erreur: $e');
    }
  }

  /// Accepte une livraison
  static Future<AIActionResult> _executeAcceptDelivery(AIActionContext context) async {
    try {
      final orderId = context.targetId;
      if (orderId == null) {
        return AIActionResult.failure(message: 'ID commande/livraison manquant.');
      }

      final delivery = await DeliveryService.createDeliveryFromOrder(
        orderId: orderId,
        livreurId: context.userId,
      );

      return AIActionResult.success(
        message: 'Livraison acceptée ! Dirigez-vous vers le point de retrait.',
        data: {
          'deliveryId': delivery.id,
          'orderId': orderId,
          'pickupAddress': delivery.pickupAddress['address'],
        },
      );
    } catch (e) {
      return AIActionResult.failure(message: 'Erreur: $e');
    }
  }

  /// Marque comme récupéré
  static Future<AIActionResult> _executeMarkPickedUp(AIActionContext context) async {
    try {
      final delivery = await DeliveryService.getDeliveryByOrderId(context.targetId!);
      if (delivery == null) {
        return AIActionResult.failure(message: 'Livraison introuvable.');
      }

      await DeliveryService().updateDeliveryStatus(
        deliveryId: delivery.id,
        status: 'picked_up',
      );

      return AIActionResult.success(
        message: 'Colis marqué comme récupéré. Dirigez-vous vers le client.',
        data: {
          'deliveryId': delivery.id,
          'newStatus': 'picked_up',
        },
      );
    } catch (e) {
      return AIActionResult.failure(message: 'Erreur: $e');
    }
  }

  /// Marque comme livré
  static Future<AIActionResult> _executeMarkDelivered(AIActionContext context) async {
    try {
      final delivery = await DeliveryService.getDeliveryByOrderId(context.targetId!);
      if (delivery == null) {
        return AIActionResult.failure(message: 'Livraison introuvable.');
      }

      await DeliveryService().updateDeliveryStatus(
        deliveryId: delivery.id,
        status: 'delivered',
      );

      return AIActionResult.success(
        message: 'Livraison terminée avec succès ! Merci.',
        data: {
          'deliveryId': delivery.id,
          'newStatus': 'delivered',
        },
      );
    } catch (e) {
      return AIActionResult.failure(message: 'Erreur: $e');
    }
  }

  /// Recrée une commande existante
  static Future<AIActionResult> _executeReorder(AIActionContext context) async {
    // Cette fonctionnalité nécessite le CartProvider
    // Pour l'instant, retournons un message indiquant de procéder manuellement
    return AIActionResult.failure(
      message: 'La fonctionnalité de recommande n\'est pas encore disponible via l\'assistant. Veuillez passer par votre historique de commandes.',
      errorCode: 'not_implemented',
    );
  }

  // ========== UTILITAIRES ==========

  /// Récupère les commandes en attente d'un vendeur
  static Future<List<OrderModel>> _getPendingOrdersForVendor(String vendorId) async {
    try {
      final orders = await OrderService.getOrdersByStatus(vendorId, 'en_attente');
      return orders;
    } catch (e) {
      debugPrint('❌ Erreur récupération commandes en attente: $e');
      return [];
    }
  }

  /// Enregistre l'action dans les logs d'audit
  static Future<void> _logActionToAudit(
    AIExecutableAction action,
    AIActionContext context,
    AIActionResult result,
    String? userEmail,
    String? userName,
  ) async {
    try {
      await AuditService.log(
        userId: context.userId,
        userType: context.userType,
        userEmail: userEmail ?? '',
        userName: userName,
        action: 'ai_action_${action.intentId}',
        actionLabel: 'Action IA: ${action.label}',
        category: AuditCategory.userAction,
        severity: action.riskLevel == ActionRiskLevel.high
            ? AuditSeverity.medium
            : AuditSeverity.low,
        description: 'Action exécutée via Assistant IA: ${action.label}',
        targetType: context.targetType,
        targetId: context.targetId,
        metadata: {
          'actionType': action.type.name,
          'riskLevel': action.riskLevel.name,
          'success': result.success,
          'resultMessage': result.message,
          'executedViaAI': true,
          ...?result.data,
        },
      );
    } catch (e) {
      debugPrint('⚠️ Erreur logging audit: $e');
    }
  }
}
