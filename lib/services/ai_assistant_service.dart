// ===== lib/services/ai_assistant_service.dart =====
// Service Assistant IA avec FAQ offline et support online (Claude API)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import '../models/ai_assistant_models.dart';

/// Contexte utilisateur pour réponses enrichies
class UserContext {
  final String userType;
  final String userId;

  // Acheteur
  final int? cartItemsCount;
  final int? pendingOrdersCount;
  final int? deliveredOrdersCount;

  // Vendeur
  final int? productsCount;
  final int? pendingOrdersToConfirm;
  final int? lowStockProductsCount;
  final double? walletBalance;
  final int? totalSales;

  // Livreur
  final int? availableDeliveriesCount;
  final int? activeDeliveryCount;
  final int? completedDeliveriesCount;
  final double? earningsBalance;

  UserContext({
    required this.userType,
    required this.userId,
    this.cartItemsCount,
    this.pendingOrdersCount,
    this.deliveredOrdersCount,
    this.productsCount,
    this.pendingOrdersToConfirm,
    this.lowStockProductsCount,
    this.walletBalance,
    this.totalSales,
    this.availableDeliveriesCount,
    this.activeDeliveryCount,
    this.completedDeliveriesCount,
    this.earningsBalance,
  });

  Map<String, dynamic> toSummary() {
    switch (userType) {
      case 'acheteur':
        return {
          'panier': '$cartItemsCount articles',
          'commandes_en_cours': pendingOrdersCount,
          'commandes_livrees': deliveredOrdersCount,
        };
      case 'vendeur':
        return {
          'produits': productsCount,
          'commandes_a_confirmer': pendingOrdersToConfirm,
          'produits_stock_faible': lowStockProductsCount,
          'solde': '${walletBalance?.toStringAsFixed(0) ?? 0} FCFA',
          'ventes_totales': totalSales,
        };
      case 'livreur':
        return {
          'livraisons_disponibles': availableDeliveriesCount,
          'livraison_en_cours': activeDeliveryCount,
          'livraisons_terminees': completedDeliveriesCount,
          'gains': '${earningsBalance?.toStringAsFixed(0) ?? 0} FCFA',
        };
      default:
        return {};
    }
  }
}

class AIAssistantService {
  static const String assistantName = 'SOCIAL Assistant';

  // ========== FAQ OFFLINE - BASE DE CONNAISSANCES ==========

  static const List<FAQItem> _faqDatabase = [
    // === GÉNÉRAL ===
    FAQItem(
      id: 'gen_1',
      question: "C'est quoi SOCIAL BUSINESS Pro ?",
      answer: "SOCIAL BUSINESS Pro est une application e-commerce qui permet aux vendeurs informels de Côte d'Ivoire de vendre leurs produits en ligne. Elle connecte vendeurs, acheteurs et livreurs dans un écosystème sécurisé avec paiement Mobile Money.",
      keywords: ['social', 'business', 'appli', 'application', 'quoi', 'cest'],
      category: 'general',
    ),
    FAQItem(
      id: 'gen_2',
      question: "Comment fonctionne l'application ?",
      answer: "C'est simple !\n\n1️⃣ Les vendeurs publient leurs produits\n2️⃣ Les acheteurs commandent et paient via Mobile Money\n3️⃣ Les livreurs récupèrent et livrent les commandes\n4️⃣ Tout le monde est satisfait !",
      keywords: ['fonctionne', 'marche', 'comment', 'utiliser'],
      category: 'general',
    ),
    FAQItem(
      id: 'gen_3',
      question: "L'application est-elle gratuite ?",
      answer: "Oui ! L'inscription est gratuite pour tous. Les acheteurs utilisent l'app gratuitement. Les vendeurs ont un plan gratuit (BASIQUE) avec 20 produits. Les livreurs ne paient rien, ils reçoivent une commission sur chaque livraison.",
      keywords: ['gratuit', 'prix', 'coute', 'payer', 'free'],
      category: 'general',
    ),

    // === ACHETEUR ===
    FAQItem(
      id: 'ach_1',
      question: "Comment passer une commande ?",
      answer: "Pour commander :\n\n1️⃣ Parcourez les produits ou recherchez\n2️⃣ Ajoutez au panier 🛒\n3️⃣ Validez votre panier\n4️⃣ Choisissez votre adresse de livraison\n5️⃣ Payez via Mobile Money\n6️⃣ Suivez votre livraison en temps réel !",
      keywords: ['commander', 'commande', 'acheter', 'panier', 'achat'],
      category: 'acheteur',
      actionRoute: '/acheteur-home',
    ),
    FAQItem(
      id: 'ach_2',
      question: "Comment payer ma commande ?",
      answer: "Nous acceptons :\n\n📱 Orange Money\n📱 MTN Mobile Money\n📱 Moov Money\n📱 Wave\n\nAprès validation, vous recevez un code USSD pour confirmer le paiement depuis votre téléphone.",
      keywords: ['payer', 'paiement', 'mobile', 'money', 'orange', 'mtn', 'wave'],
      category: 'acheteur',
    ),
    FAQItem(
      id: 'ach_3',
      question: "Comment suivre ma livraison ?",
      answer: "Une fois votre commande confirmée :\n\n1️⃣ Allez dans 'Mes Commandes'\n2️⃣ Cliquez sur la commande\n3️⃣ Suivez le livreur en temps réel sur la carte GPS\n\nVous recevrez des notifications à chaque étape !",
      keywords: ['suivre', 'livraison', 'tracking', 'ou', 'commande', 'livreur'],
      category: 'acheteur',
      actionRoute: '/acheteur/orders',
    ),
    FAQItem(
      id: 'ach_4',
      question: "Comment annuler une commande ?",
      answer: "Vous pouvez annuler tant que le vendeur n'a pas confirmé :\n\n1️⃣ Allez dans 'Mes Commandes'\n2️⃣ Sélectionnez la commande\n3️⃣ Appuyez sur 'Annuler'\n\n⚠️ Si déjà en préparation, contactez le vendeur.",
      keywords: ['annuler', 'annulation', 'cancel', 'rembourser'],
      category: 'acheteur',
    ),
    FAQItem(
      id: 'ach_5',
      question: "Comment ajouter un produit aux favoris ?",
      answer: "Appuyez sur le cœur ❤️ sur n'importe quel produit pour l'ajouter à vos favoris. Retrouvez-les dans l'onglet 'Favoris' de votre profil.",
      keywords: ['favori', 'favoris', 'coeur', 'sauvegarder', 'like'],
      category: 'acheteur',
    ),

    // === VENDEUR ===
    FAQItem(
      id: 'ven_1',
      question: "Comment ajouter un produit ?",
      answer: "Pour ajouter un produit :\n\n1️⃣ Allez dans 'Mes Produits'\n2️⃣ Appuyez sur '+' ou 'Ajouter'\n3️⃣ Remplissez : nom, description, prix, photos\n4️⃣ Choisissez la catégorie\n5️⃣ Définissez le stock\n6️⃣ Publiez !\n\nConseil : De belles photos = plus de ventes !",
      keywords: ['ajouter', 'produit', 'creer', 'nouveau', 'vendre'],
      category: 'vendeur',
      actionRoute: '/vendeur/add-product',
    ),
    FAQItem(
      id: 'ven_2',
      question: "Comment gérer mes commandes ?",
      answer: "Dans 'Gestion Commandes' :\n\n📋 'En attente' → Nouvelles commandes à confirmer\n🔄 'En cours' → Commandes en préparation\n✅ 'Livrées' → Commandes terminées\n❌ 'Annulées' → Commandes annulées\n\nConfirmez rapidement pour satisfaire vos clients !",
      keywords: ['commandes', 'gerer', 'gestion', 'confirmer', 'ordre'],
      category: 'vendeur',
      actionRoute: '/vendeur/order-management',
    ),
    FAQItem(
      id: 'ven_3',
      question: "Quels sont les abonnements vendeur ?",
      answer: "3 plans disponibles :\n\n🆓 BASIQUE (Gratuit)\n• 20 produits max\n• Commission 10%\n\n💼 PRO (5,000 FCFA/mois)\n• 100 produits\n• Badge Pro\n• Assistant IA\n\n👑 PREMIUM (10,000 FCFA/mois)\n• Produits illimités\n• Commission 7%\n• IA Expert\n• Support VIP",
      keywords: ['abonnement', 'plan', 'tarif', 'prix', 'pro', 'premium', 'basique'],
      category: 'vendeur',
      actionRoute: '/vendeur/subscription',
    ),
    FAQItem(
      id: 'ven_4',
      question: "Comment retirer mon argent ?",
      answer: "Pour retirer vos gains :\n\n1️⃣ Allez dans 'Portefeuille'\n2️⃣ Vérifiez votre solde disponible\n3️⃣ Appuyez sur 'Retirer'\n4️⃣ Entrez le montant et votre numéro Mobile Money\n5️⃣ Confirmez\n\n💰 Délai : 24-48h ouvrées",
      keywords: ['retirer', 'argent', 'gains', 'solde', 'portefeuille', 'retrait'],
      category: 'vendeur',
    ),
    FAQItem(
      id: 'ven_5',
      question: "Comment améliorer mes ventes ?",
      answer: "Conseils pour vendre plus :\n\n📸 Photos de qualité (lumière naturelle)\n✍️ Descriptions détaillées\n💰 Prix compétitifs\n⚡ Répondez vite aux commandes\n⭐ Soignez les avis clients\n📢 Partagez sur WhatsApp/Facebook\n\nPassez au plan PRO pour plus de visibilité !",
      keywords: ['ventes', 'ameliorer', 'vendre', 'plus', 'conseils', 'tips'],
      category: 'vendeur',
    ),

    // === LIVREUR ===
    FAQItem(
      id: 'liv_1',
      question: "Comment devenir livreur ?",
      answer: "Pour devenir livreur :\n\n1️⃣ Inscrivez-vous comme 'Livreur'\n2️⃣ Téléchargez vos documents :\n   • CNI\n   • Permis (si moto/voiture)\n   • Carte grise\n   • Selfie avec véhicule\n3️⃣ Attendez la validation (48h)\n4️⃣ Commencez à livrer !",
      keywords: ['devenir', 'livreur', 'inscription', 'documents', 'commencer'],
      category: 'livreur',
    ),
    FAQItem(
      id: 'liv_2',
      question: "Comment accepter une livraison ?",
      answer: "Quand une livraison est disponible :\n\n1️⃣ Vous recevez une notification\n2️⃣ Consultez les détails (distance, montant)\n3️⃣ Appuyez sur 'Accepter'\n4️⃣ Rendez-vous chez le vendeur\n5️⃣ Récupérez le colis\n6️⃣ Livrez au client\n7️⃣ Confirmez la livraison",
      keywords: ['accepter', 'livraison', 'course', 'commande', 'prendre'],
      category: 'livreur',
      actionRoute: '/livreur/available-orders',
    ),
    FAQItem(
      id: 'liv_3',
      question: "Combien je gagne par livraison ?",
      answer: "Vos gains dépendent de la distance :\n\n📍 0-5km : 1,000 FCFA\n📍 5-10km : 1,500 FCFA\n📍 10-20km : 2,000 FCFA\n📍 +20km : 2,500 FCFA+\n\nCommission plateforme : 15-25% selon niveau\n\n🏆 Niveau PREMIUM = 85% pour vous !",
      keywords: ['gagner', 'gains', 'combien', 'salaire', 'revenu', 'argent'],
      category: 'livreur',
    ),
    FAQItem(
      id: 'liv_4',
      question: "Comment monter en niveau ?",
      answer: "Niveaux livreur :\n\n🚴 STARTER → PRO\n• 50 livraisons\n• Note ≥ 4.0/5\n\n🏍️ PRO → PREMIUM\n• 200 livraisons\n• Note ≥ 4.5/5\n• Taux annulation < 5%\n\nPlus vous montez, moins de commission !",
      keywords: ['niveau', 'monter', 'pro', 'premium', 'evoluer', 'progression'],
      category: 'livreur',
    ),

    // === SÉCURITÉ ===
    FAQItem(
      id: 'sec_1',
      question: "Comment changer mon mot de passe ?",
      answer: "Pour changer votre mot de passe :\n\n1️⃣ Allez dans Profil > Paramètres\n2️⃣ 'Sécurité du compte'\n3️⃣ 'Changer mot de passe'\n4️⃣ Entrez l'ancien puis le nouveau\n\nOu utilisez 'Mot de passe oublié' sur la page de connexion.",
      keywords: ['mot', 'passe', 'password', 'changer', 'modifier', 'securite'],
      category: 'securite',
    ),
    FAQItem(
      id: 'sec_2',
      question: "Comment contacter le support ?",
      answer: "Plusieurs options :\n\n📧 Email : support@socialbusinesspro.ci\n📱 WhatsApp : +225 07 49 70 54 04\n💬 Chat in-app (PRO/PREMIUM)\n\nDélai de réponse :\n• Email : 48-72h\n• WhatsApp : 24h\n• Chat : Immédiat",
      keywords: ['support', 'contacter', 'aide', 'probleme', 'contact'],
      category: 'securite',
    ),

    // === PROBLÈMES COURANTS ===
    FAQItem(
      id: 'pb_1',
      question: "Ma commande n'arrive pas",
      answer: "Si votre commande tarde :\n\n1️⃣ Vérifiez le statut dans 'Mes Commandes'\n2️⃣ Consultez la position du livreur sur la carte\n3️⃣ Contactez le livreur via l'app\n4️⃣ Si problème persistant, contactez le support\n\n⚠️ Retard possible en cas de trafic ou intempéries.",
      keywords: ['commande', 'arrive', 'pas', 'retard', 'attente', 'livraison'],
      category: 'problemes',
    ),
    FAQItem(
      id: 'pb_2',
      question: "Le paiement a échoué",
      answer: "Si le paiement échoue :\n\n1️⃣ Vérifiez votre solde Mobile Money\n2️⃣ Assurez-vous d'avoir validé le code USSD\n3️⃣ Réessayez après 5 minutes\n4️⃣ Essayez un autre opérateur\n\n💡 Aucun débit si échec. Votre argent est sécurisé.",
      keywords: ['paiement', 'echoue', 'echec', 'erreur', 'marche', 'pas'],
      category: 'problemes',
    ),
  ];

  // ========== MESSAGES DE BIENVENUE PAR RÔLE ==========

  static String getWelcomeMessage(String userType, String? userName) {
    final name = userName ?? 'ami(e)';

    switch (userType) {
      case 'acheteur':
        return "Bonjour $name ! 👋\n\nJe suis votre assistant SOCIAL BUSINESS. Je peux vous aider à :\n\n🛒 Trouver des produits\n📦 Suivre vos commandes\n💳 Questions sur le paiement\n\nQue puis-je faire pour vous ?";
      case 'vendeur':
        return "Bonjour $name ! 👋\n\nJe suis votre assistant business. Je suis là pour vous aider à :\n\n📦 Gérer vos produits et commandes\n📊 Comprendre vos statistiques\n💡 Améliorer vos ventes\n\nComment puis-je vous aider aujourd'hui ?";
      case 'livreur':
        return "Salut $name ! 👋\n\nJe suis votre assistant livreur. Je peux vous aider avec :\n\n🛵 Vos livraisons\n💰 Vos gains et retraits\n📈 Votre progression de niveau\n\nQue voulez-vous savoir ?";
      default:
        return "Bonjour ! 👋\n\nJe suis l'assistant SOCIAL BUSINESS Pro. Comment puis-je vous aider ?";
    }
  }

  // ========== QUICK REPLIES PAR CONTEXTE ==========

  static List<String> getQuickReplies(String userType) {
    switch (userType) {
      case 'acheteur':
        return [
          "Comment commander ?",
          "Suivre ma livraison",
          "Moyens de paiement",
          "Annuler commande",
        ];
      case 'vendeur':
        return [
          "Ajouter un produit",
          "Gérer mes commandes",
          "Les abonnements",
          "Retirer mon argent",
        ];
      case 'livreur':
        return [
          "Accepter une livraison",
          "Mes gains",
          "Monter en niveau",
          "Mes documents",
        ];
      default:
        return [
          "C'est quoi l'appli ?",
          "Comment ça marche ?",
          "C'est gratuit ?",
        ];
    }
  }

  // ========== RECHERCHE FAQ ==========

  /// Recherche une réponse dans la FAQ offline
  static FAQItem? searchFAQ(String query, {String? userType}) {
    final queryLower = query.toLowerCase();
    final words = queryLower.split(RegExp(r'\s+'));

    FAQItem? bestMatch;
    int bestScore = 0;

    for (final faq in _faqDatabase) {
      // Filtrer par catégorie si userType spécifié
      if (userType != null &&
          faq.category != userType &&
          faq.category != 'general' &&
          faq.category != 'securite' &&
          faq.category != 'problemes') {
        continue;
      }

      int score = 0;

      // Score par mots-clés
      for (final keyword in faq.keywords) {
        if (queryLower.contains(keyword)) {
          score += 10;
        }
        for (final word in words) {
          if (keyword.contains(word) || word.contains(keyword)) {
            score += 5;
          }
        }
      }

      // Score par question
      if (faq.question.toLowerCase().contains(queryLower)) {
        score += 20;
      }

      if (score > bestScore) {
        bestScore = score;
        bestMatch = faq;
      }
    }

    // Seuil minimum de pertinence
    return bestScore >= 10 ? bestMatch : null;
  }

  /// Obtenir toutes les FAQ d'une catégorie
  static List<FAQItem> getFAQByCategory(String category) {
    return _faqDatabase.where((faq) => faq.category == category).toList();
  }

  /// Obtenir toutes les catégories
  static List<String> getCategories() {
    return _faqDatabase.map((f) => f.category).toSet().toList();
  }

  // ========== INTENTIONS PAR RÔLE ==========

  static const Map<String, List<Map<String, dynamic>>> _intentsByRole = {
    'acheteur': [
      {
        'intent': 'view_cart',
        'keywords': ['panier', 'mon panier', 'voir panier', 'cart'],
        'response': 'Voici votre panier d\'achats.',
        'route': '/acheteur/cart',
        'label': 'Voir mon panier',
        'icon': 'shopping_cart',
      },
      {
        'intent': 'view_orders',
        'keywords': ['commandes', 'mes commandes', 'historique', 'suivi', 'suivre'],
        'response': 'Consultez vos commandes et leur statut.',
        'route': '/acheteur/orders',
        'label': 'Mes commandes',
        'icon': 'receipt_long',
      },
      {
        'intent': 'view_favorites',
        'keywords': ['favoris', 'mes favoris', 'coeur', 'aimé', 'sauvegardé'],
        'response': 'Voici vos produits favoris.',
        'route': '/favorites',
        'label': 'Mes favoris',
        'icon': 'favorite',
      },
      {
        'intent': 'view_profile',
        'keywords': ['profil', 'mon compte', 'paramètres', 'modifier profil'],
        'response': 'Gérez votre profil et vos paramètres.',
        'route': '/acheteur/profile',
        'label': 'Mon profil',
        'icon': 'person',
      },
      {
        'intent': 'view_addresses',
        'keywords': ['adresse', 'adresses', 'livraison', 'localisation'],
        'response': 'Gérez vos adresses de livraison.',
        'route': '/acheteur/addresses',
        'label': 'Mes adresses',
        'icon': 'location_on',
      },
      {
        'intent': 'browse_categories',
        'keywords': ['catégories', 'categories', 'parcourir', 'explorer'],
        'response': 'Explorez nos catégories de produits.',
        'route': '/acheteur-home',
        'label': 'Explorer',
        'icon': 'category',
      },
    ],
    'vendeur': [
      {
        'intent': 'add_product',
        'keywords': ['ajouter', 'nouveau produit', 'créer produit', 'publier'],
        'response': 'Ajoutez un nouveau produit à votre boutique.',
        'route': '/vendeur/add-product',
        'label': 'Ajouter produit',
        'icon': 'add_box',
      },
      {
        'intent': 'view_products',
        'keywords': ['mes produits', 'produits', 'stock', 'inventaire', 'catalogue'],
        'response': 'Gérez vos produits et votre stock.',
        'route': '/vendeur/products',
        'label': 'Mes produits',
        'icon': 'inventory',
      },
      {
        'intent': 'view_orders',
        'keywords': ['commandes', 'commande', 'gestion', 'en attente', 'confirmer'],
        'response': 'Consultez et gérez vos commandes.',
        'route': '/vendeur/order-management',
        'label': 'Mes commandes',
        'icon': 'receipt_long',
      },
      {
        'intent': 'view_stats',
        'keywords': ['statistiques', 'stats', 'ventes', 'chiffres', 'revenus', 'gains'],
        'response': 'Consultez vos statistiques de vente.',
        'route': '/vendeur/vendeur-statistics',
        'label': 'Statistiques',
        'icon': 'bar_chart',
      },
      {
        'intent': 'view_wallet',
        'keywords': ['portefeuille', 'argent', 'solde', 'retrait', 'retirer'],
        'response': 'Gérez votre portefeuille et vos retraits.',
        'route': '/vendeur/finance',
        'label': 'Mon portefeuille',
        'icon': 'account_balance_wallet',
      },
      {
        'intent': 'view_subscription',
        'keywords': ['abonnement', 'plan', 'upgrade', 'pro', 'premium'],
        'response': 'Gérez votre abonnement vendeur.',
        'route': '/vendeur/subscription',
        'label': 'Mon abonnement',
        'icon': 'card_membership',
      },
      {
        'intent': 'view_shop',
        'keywords': ['boutique', 'shop', 'magasin', 'ma boutique'],
        'response': 'Personnalisez votre boutique.',
        'route': '/vendeur/my-shop',
        'label': 'Ma boutique',
        'icon': 'storefront',
      },
    ],
    'livreur': [
      {
        'intent': 'view_available',
        'keywords': ['disponible', 'livraisons', 'courses', 'accepter', 'nouvelle'],
        'response': 'Consultez les livraisons disponibles.',
        'route': '/livreur/available-orders',
        'label': 'Livraisons dispo',
        'icon': 'local_shipping',
      },
      {
        'intent': 'view_active',
        'keywords': ['en cours', 'active', 'actuelle', 'mission'],
        'response': 'Votre livraison en cours.',
        'route': '/livreur/deliveries',
        'label': 'En cours',
        'icon': 'delivery_dining',
      },
      {
        'intent': 'view_history',
        'keywords': ['historique', 'terminées', 'passées', 'anciennes'],
        'response': 'Consultez votre historique de livraisons.',
        'route': '/livreur/deliveries',
        'label': 'Historique',
        'icon': 'history',
      },
      {
        'intent': 'view_earnings',
        'keywords': ['gains', 'argent', 'revenus', 'salaire', 'combien'],
        'response': 'Consultez vos gains et retraits.',
        'route': '/livreur/earnings',
        'label': 'Mes gains',
        'icon': 'payments',
      },
      {
        'intent': 'view_documents',
        'keywords': ['documents', 'kyc', 'vérification', 'cni', 'permis'],
        'response': 'Gérez vos documents de vérification.',
        'route': '/livreur/documents',
        'label': 'Mes documents',
        'icon': 'description',
      },
    ],
  };

  /// Détecte si la requête est une question (pas une commande de navigation)
  static bool _isQuestionQuery(String query) {
    final q = query.toLowerCase().trim();

    // Mots interrogatifs et expressions de question
    final questionKeywords = [
      // Interrogatifs
      'combien', 'quel', 'quelle', 'quels', 'quelles', 'comment',
      'où', 'ou est', 'ou en est', 'pourquoi',
      // Expressions de quantité/état
      'nombre', 'total', 'montant', 'solde',
      'j\'ai quoi', 'ai-je', 'est-ce que', 'y a-t-il', 'y a t il',
      // Possessifs avec contexte de question
      'dans mon', 'de mon', 'mon solde', 'mes gains', 'mes commandes',
      'j\'ai combien', 'ai combien', 'il y a quoi',
      // Questions informelles
      'c\'est quoi', 'cest quoi', 'quoi dans', 'quoi de',
    ];

    // Expressions de DONNÉES (doivent afficher les données, pas naviguer)
    // Format: "mon/mes + nom" sans verbe d'action
    final dataExpressions = [
      // Acheteur
      'mon panier', 'mes commandes', 'mes favoris',
      // Vendeur
      'mes produits', 'mon stock', 'mes ventes', 'mes chiffres', 'mon portefeuille',
      // Livreur
      'mes livraisons', 'mes courses', 'mes gains',
      // Génériques
      'mon historique', 'mon compte', 'mon profil',
    ];

    // Verbes d'ACTION (doivent naviguer ou exécuter, pas afficher)
    // Si le message contient ces verbes, ce n'est PAS une question de données
    final actionVerbs = [
      'ouvre', 'ouvrir', 'voir', 'va', 'aller', 'montre', 'affiche',
      'navigue', 'accède', 'accéder', 'redirige',
    ];

    // Si c'est une expression de données SANS verbe d'action → question
    final hasDataExpression = dataExpressions.any((k) => q.contains(k));
    final hasActionVerb = actionVerbs.any((k) => q.contains(k));

    if (hasDataExpression && !hasActionVerb) {
      return true;
    }

    // Verbes d'état en début de phrase (questions implicites)
    final startsWithQuestion = [
      'ai-je', 'ai je', 'est-ce', 'y a', 'il y a',
    ];

    // Vérifier les mots-clés
    if (questionKeywords.any((k) => q.contains(k))) return true;

    // Vérifier début de phrase
    if (startsWithQuestion.any((k) => q.startsWith(k))) return true;

    return false;
  }

  /// Détecte une intention basée sur les mots-clés du rôle
  static Map<String, dynamic>? _detectIntent(String query, String userType) {
    final queryLower = query.toLowerCase();
    final intents = _intentsByRole[userType] ?? [];

    for (final intent in intents) {
      final keywords = intent['keywords'] as List<String>;
      for (final keyword in keywords) {
        if (queryLower.contains(keyword)) {
          return intent;
        }
      }
    }
    return null;
  }

  // ========== DÉTECTION RECHERCHE PRODUIT ==========

  /// Détecte si l'utilisateur cherche un produit
  static Map<String, dynamic>? _detectProductSearch(String query) {
    final queryLower = query.toLowerCase();

    // Mots-clés de recherche
    final searchKeywords = ['cherche', 'recherche', 'trouve', 'trouver', 'veux', 'voudrais', 'besoin', 'acheter', 'où', 'ou'];
    final hasSearchIntent = searchKeywords.any((k) => queryLower.contains(k));

    if (!hasSearchIntent) return null;

    // Extraire le terme de recherche
    String searchTerm = query;
    for (final keyword in ['je cherche', 'je recherche', 'je veux', 'je voudrais', 'j\'ai besoin de', 'j\'ai besoin d\'', 'où trouver', 'ou trouver', 'acheter']) {
      if (queryLower.contains(keyword)) {
        final index = queryLower.indexOf(keyword);
        searchTerm = query.substring(index + keyword.length).trim();
        break;
      }
    }

    // Nettoyer les articles
    searchTerm = searchTerm.replaceAll(RegExp(r'^(un|une|des|du|de la|le|la|les)\s+', caseSensitive: false), '');

    if (searchTerm.isNotEmpty && searchTerm.length > 2) {
      return {
        'type': 'product_search',
        'searchTerm': searchTerm,
      };
    }
    return null;
  }

  // ========== DONNÉES DÉTAILLÉES ==========

  /// Récupère et formate les données détaillées selon la requête
  static Future<String?> _getDetailedDataResponse(String query, String userType, String userId) async {
    final q = query.toLowerCase();

    switch (userType) {
      case 'vendeur':
        return await _getVendeurDetailedData(q, userId);
      case 'livreur':
        return await _getLivreurDetailedData(q, userId);
      case 'acheteur':
        return await _getAcheteurDetailedData(q, userId);
    }
    return null;
  }

  /// Données détaillées pour le vendeur
  static Future<String?> _getVendeurDetailedData(String q, String userId) async {
    // Commandes en attente avec détails
    if (q.contains('commande') || q.contains('attente') || q.contains('confirmer')) {
      final orders = await _firestore
          .collection('orders')
          .where('vendorId', isEqualTo: userId)
          .where('status', isEqualTo: 'en_attente')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get()
          .timeout(const Duration(seconds: 8));

      if (orders.docs.isEmpty) {
        return "✅ **Aucune commande en attente**\n\nToutes vos commandes sont traitées. Bravo !";
      }

      final buffer = StringBuffer();
      buffer.writeln("📋 **${orders.docs.length} commande(s) en attente :**\n");

      for (int i = 0; i < orders.docs.length; i++) {
        final data = orders.docs[i].data();
        final total = (data['totalAmount'] as num?)?.toInt() ?? 0;
        final items = (data['items'] as List?)?.length ?? 0;
        final buyerName = data['buyerName'] ?? 'Client';
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        final timeAgo = createdAt != null ? _formatTimeAgo(createdAt) : '';

        buffer.writeln("${i + 1}. **$buyerName** - $total FCFA");
        buffer.writeln("   📦 $items article(s) • $timeAgo");
      }

      buffer.writeln("\n💡 Dites \"confirme mes commandes\" pour les traiter.");
      return buffer.toString();
    }

    // Produits avec stock faible
    if (q.contains('stock') || q.contains('produit') || q.contains('rupture') || q.contains('inventaire')) {
      final products = await _firestore
          .collection('products')
          .where('vendorId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get()
          .timeout(const Duration(seconds: 8));

      if (products.docs.isEmpty) {
        return "📦 **Aucun produit**\n\nVotre catalogue est vide. Ajoutez des produits pour commencer à vendre !";
      }

      final lowStock = products.docs.where((doc) {
        final stock = (doc.data()['stock'] as num?)?.toInt() ?? 0;
        return stock < 5;
      }).toList();

      final outOfStock = products.docs.where((doc) {
        final stock = (doc.data()['stock'] as num?)?.toInt() ?? 0;
        return stock == 0;
      }).toList();

      final buffer = StringBuffer();
      buffer.writeln("📦 **Inventaire : ${products.docs.length} produit(s)**\n");

      if (outOfStock.isNotEmpty) {
        buffer.writeln("🔴 **${outOfStock.length} en rupture :**");
        for (final doc in outOfStock.take(3)) {
          final name = doc.data()['name'] ?? 'Produit';
          buffer.writeln("   • $name");
        }
        buffer.writeln("");
      }

      if (lowStock.isNotEmpty && lowStock.length > outOfStock.length) {
        final justLow = lowStock.where((doc) => (doc.data()['stock'] as num?)?.toInt() != 0).toList();
        if (justLow.isNotEmpty) {
          buffer.writeln("🟠 **${justLow.length} stock faible (<5) :**");
          for (final doc in justLow.take(3)) {
            final name = doc.data()['name'] ?? 'Produit';
            final stock = (doc.data()['stock'] as num?)?.toInt() ?? 0;
            buffer.writeln("   • $name ($stock restants)");
          }
        }
      }

      if (outOfStock.isEmpty && lowStock.isEmpty) {
        buffer.writeln("✅ Tous vos produits ont un stock suffisant !");
      }

      return buffer.toString();
    }

    // Ventes récentes
    if (q.contains('vente') || q.contains('chiffre') || q.contains('revenu') || q.contains('aujourd')) {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final todaySales = await _firestore
          .collection('orders')
          .where('vendorId', isEqualTo: userId)
          .where('status', isEqualTo: 'livree')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .get()
          .timeout(const Duration(seconds: 8));

      final allSales = await _firestore
          .collection('orders')
          .where('vendorId', isEqualTo: userId)
          .where('status', isEqualTo: 'livree')
          .get()
          .timeout(const Duration(seconds: 8));

      double todayTotal = 0;
      for (final doc in todaySales.docs) {
        todayTotal += (doc.data()['totalAmount'] as num?)?.toDouble() ?? 0;
      }

      double allTimeTotal = 0;
      for (final doc in allSales.docs) {
        allTimeTotal += (doc.data()['totalAmount'] as num?)?.toDouble() ?? 0;
      }

      final buffer = StringBuffer();
      buffer.writeln("📊 **Vos ventes :**\n");
      buffer.writeln("📅 **Aujourd'hui :** ${todaySales.docs.length} vente(s) • ${todayTotal.toStringAsFixed(0)} FCFA");
      buffer.writeln("📈 **Total :** ${allSales.docs.length} vente(s) • ${allTimeTotal.toStringAsFixed(0)} FCFA");

      return buffer.toString();
    }

    return null;
  }

  /// Données détaillées pour le livreur
  static Future<String?> _getLivreurDetailedData(String q, String userId) async {
    // Livraisons disponibles avec détails
    if (q.contains('disponible') || q.contains('course') || q.contains('opportunit') || q.contains('nouvelle')) {
      final deliveries = await _firestore
          .collection('deliveries')
          .where('status', isEqualTo: 'available')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get()
          .timeout(const Duration(seconds: 8));

      if (deliveries.docs.isEmpty) {
        return "📭 **Aucune livraison disponible**\n\nRestez connecté, de nouvelles courses arrivent bientôt !";
      }

      final buffer = StringBuffer();
      buffer.writeln("🛵 **${deliveries.docs.length} livraison(s) disponible(s) :**\n");

      for (int i = 0; i < deliveries.docs.length; i++) {
        final data = deliveries.docs[i].data();
        final fee = (data['deliveryFee'] as num?)?.toInt() ?? 0;
        final distance = (data['distance'] as num?)?.toStringAsFixed(1) ?? '?';
        final pickupAddress = data['pickupAddress'] ?? 'Adresse inconnue';

        buffer.writeln("${i + 1}. **$fee FCFA** - $distance km");
        buffer.writeln("   📍 $pickupAddress");
      }

      buffer.writeln("\n💡 Dites \"accepte la livraison\" pour en prendre une.");
      return buffer.toString();
    }

    // Livraison en cours
    if (q.contains('livraison') || q.contains('en cours') || q.contains('active') || q.contains('mission')) {
      final active = await _firestore
          .collection('deliveries')
          .where('livreurId', isEqualTo: userId)
          .where('status', whereIn: ['assigned', 'picked_up', 'in_transit'])
          .get()
          .timeout(const Duration(seconds: 8));

      if (active.docs.isEmpty) {
        return "📦 **Aucune livraison en cours**\n\nVous êtes disponible pour accepter de nouvelles courses !";
      }

      final buffer = StringBuffer();
      buffer.writeln("🚴 **${active.docs.length} livraison(s) en cours :**\n");

      for (final doc in active.docs) {
        final data = doc.data();
        final status = data['status'] ?? 'assigned';
        final fee = (data['deliveryFee'] as num?)?.toInt() ?? 0;
        final deliveryAddress = data['deliveryAddress'] ?? 'Adresse inconnue';

        String statusIcon = '📋';
        String statusText = 'Assignée';
        if (status == 'picked_up') {
          statusIcon = '📦';
          statusText = 'Colis récupéré';
        } else if (status == 'in_transit') {
          statusIcon = '🚴';
          statusText = 'En route';
        }

        buffer.writeln("$statusIcon **$statusText** - $fee FCFA");
        buffer.writeln("   📍 Livrer à: $deliveryAddress");
      }

      return buffer.toString();
    }

    // Gains détaillés
    if (q.contains('gain') || q.contains('argent') || q.contains('revenu') || q.contains('salaire')) {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final startOfWeek = today.subtract(Duration(days: today.weekday - 1));

      final todayDeliveries = await _firestore
          .collection('deliveries')
          .where('livreurId', isEqualTo: userId)
          .where('status', isEqualTo: 'delivered')
          .where('deliveredAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .get()
          .timeout(const Duration(seconds: 8));

      final weekDeliveries = await _firestore
          .collection('deliveries')
          .where('livreurId', isEqualTo: userId)
          .where('status', isEqualTo: 'delivered')
          .where('deliveredAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
          .get()
          .timeout(const Duration(seconds: 8));

      double todayEarnings = 0;
      for (final doc in todayDeliveries.docs) {
        todayEarnings += (doc.data()['livreurEarnings'] as num?)?.toDouble() ?? 0;
      }

      double weekEarnings = 0;
      for (final doc in weekDeliveries.docs) {
        weekEarnings += (doc.data()['livreurEarnings'] as num?)?.toDouble() ?? 0;
      }

      final buffer = StringBuffer();
      buffer.writeln("💰 **Vos gains :**\n");
      buffer.writeln("📅 **Aujourd'hui :** ${todayDeliveries.docs.length} course(s) • ${todayEarnings.toStringAsFixed(0)} FCFA");
      buffer.writeln("📆 **Cette semaine :** ${weekDeliveries.docs.length} course(s) • ${weekEarnings.toStringAsFixed(0)} FCFA");

      return buffer.toString();
    }

    return null;
  }

  /// Données détaillées pour l'acheteur
  static Future<String?> _getAcheteurDetailedData(String q, String userId) async {
    // Commandes en cours avec détails
    if (q.contains('commande') || q.contains('suivi') || q.contains('livraison')) {
      final orders = await _firestore
          .collection('orders')
          .where('buyerId', isEqualTo: userId)
          .where('status', whereIn: ['en_attente', 'en_cours', 'ready'])
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get()
          .timeout(const Duration(seconds: 8));

      if (orders.docs.isEmpty) {
        return "📦 **Aucune commande en cours**\n\nVous n'avez pas de commande active. Explorez nos produits !";
      }

      final buffer = StringBuffer();
      buffer.writeln("📦 **${orders.docs.length} commande(s) en cours :**\n");

      for (int i = 0; i < orders.docs.length; i++) {
        final data = orders.docs[i].data();
        final status = data['status'] ?? 'en_attente';
        final total = (data['totalAmount'] as num?)?.toInt() ?? 0;
        final vendorName = data['vendorName'] ?? 'Vendeur';

        String statusIcon = '⏳';
        String statusText = 'En attente';
        if (status == 'en_cours') {
          statusIcon = '🔄';
          statusText = 'En préparation';
        } else if (status == 'ready') {
          statusIcon = '✅';
          statusText = 'Prête';
        }

        buffer.writeln("${i + 1}. $statusIcon **$statusText** - $total FCFA");
        buffer.writeln("   🏪 $vendorName");
      }

      return buffer.toString();
    }

    // Panier avec détails - Structure: users/{userId}/cart/current -> items[]
    if (q.contains('panier') || q.contains('cart')) {
      final cartDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .doc('current')
          .get()
          .timeout(const Duration(seconds: 8));

      if (!cartDoc.exists) {
        return "🛒 **Votre panier est vide**\n\nExplorez nos produits pour trouver ce qu'il vous faut !";
      }

      final data = cartDoc.data();
      final items = (data?['items'] as List<dynamic>?) ?? [];

      if (items.isEmpty) {
        return "🛒 **Votre panier est vide**\n\nExplorez nos produits pour trouver ce qu'il vous faut !";
      }

      double total = 0;
      final buffer = StringBuffer();
      buffer.writeln("🛒 **Votre panier (${items.length} article(s)) :**\n");

      for (int i = 0; i < items.length && i < 5; i++) {
        final item = items[i] as Map<String, dynamic>;
        final name = item['productName'] ?? 'Produit';
        final price = (item['price'] as num?)?.toInt() ?? 0;
        final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
        total += price * quantity;

        buffer.writeln("• $name x$quantity - ${price * quantity} FCFA");
      }

      if (items.length > 5) {
        buffer.writeln("• ... et ${items.length - 5} autre(s)");
      }

      buffer.writeln("\n**Total : ${total.toStringAsFixed(0)} FCFA**");
      return buffer.toString();
    }

    return null;
  }

  /// Formatte le temps écoulé
  static String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) {
      return "il y a ${diff.inMinutes} min";
    } else if (diff.inHours < 24) {
      return "il y a ${diff.inHours}h";
    } else {
      return "il y a ${diff.inDays}j";
    }
  }

  // ========== RÉPONSE INTELLIGENTE ==========

  /// Génère une réponse (offline d'abord, puis online si autorisé)
  static Future<AIMessage> getResponse({
    required String query,
    required String userType,
    required AIAccessLevel accessLevel,
    String? userId,
  }) async {
    // 0. Essayer d'abord les réponses détaillées (données réelles)
    if (userId != null) {
      try {
        final detailedResponse = await _getDetailedDataResponse(query, userType, userId);
        if (detailedResponse != null) {
          return AIMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content: detailedResponse,
            isUser: false,
            timestamp: DateTime.now(),
            type: AIMessageType.text,
            metadata: {'source': 'detailed_data'},
          );
        }
      } catch (e) {
        debugPrint('⚠️ Erreur données détaillées: $e');
      }
    }

    // 1. Charger le contexte utilisateur pour TOUS (questions simples gratuites)
    if (userId != null) {
      try {
        final context = await loadUserContext(userId: userId, userType: userType);
        if (context != null) {
          final contextualResponse = generateContextualResponse(query, context);
          if (contextualResponse != null) {
            return AIMessage(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              content: contextualResponse,
              isUser: false,
              timestamp: DateTime.now(),
              type: AIMessageType.text,
              metadata: {
                'source': 'contextual_data',
                'context': context.toSummary(),
              },
            );
          }
        }
      } catch (e) {
        debugPrint('⚠️ Erreur contexte, fallback FAQ: $e');
      }
    }

    // 1. Détecter intention par mots-clés du rôle (seulement si pas une question)
    final isQuestion = _isQuestionQuery(query);
    final detectedIntent = isQuestion ? null : _detectIntent(query, userType);
    if (detectedIntent != null) {
      return AIMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: detectedIntent['response'] as String,
        isUser: false,
        timestamp: DateTime.now(),
        type: AIMessageType.action,
        metadata: {
          'source': 'intent_detection',
          'intent': detectedIntent['intent'],
          'actionRoute': detectedIntent['route'],
          'actionLabel': detectedIntent['label'],
        },
      );
    }

    // 1. Détecter recherche produit (acheteur)
    if (userType == 'acheteur') {
      final productSearch = _detectProductSearch(query);
      if (productSearch != null) {
        final searchTerm = productSearch['searchTerm'] as String;
        return AIMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: "Je vais vous aider à trouver \"$searchTerm\" ! 🔍",
          isUser: false,
          timestamp: DateTime.now(),
          type: AIMessageType.action,
          metadata: {
            'source': 'intent_detection',
            'intent': 'product_search',
            'searchTerm': searchTerm,
            'actionRoute': '/acheteur/search',
            'actionLabel': 'Rechercher "$searchTerm"',
          },
        );
      }
    }

    // 2. Chercher dans FAQ offline
    final faqMatch = searchFAQ(query, userType: userType);

    if (faqMatch != null) {
      return AIMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: faqMatch.answer,
        isUser: false,
        timestamp: DateTime.now(),
        type: AIMessageType.text,
        metadata: {
          'source': 'faq',
          'faqId': faqMatch.id,
          'actionRoute': faqMatch.actionRoute,
        },
      );
    }

    // 3. Si pas de match FAQ et accès online autorisé → appel LLM
    if ((accessLevel == AIAccessLevel.pro || accessLevel == AIAccessLevel.premium) && userId != null) {
      // Vérifier le quota
      final quotaStatus = await checkLLMQuota(userId: userId, accessLevel: accessLevel, userType: userType);

      if (!quotaStatus.allowed) {
        return AIMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: "⚠️ ${quotaStatus.reason}\n\nVoici des suggestions qui pourraient vous aider :",
          isUser: false,
          timestamp: DateTime.now(),
          type: AIMessageType.quickReplies,
          metadata: {
            'source': 'quota_exceeded',
            'quickReplies': getQuickReplies(userType),
          },
        );
      }

      try {
        final response = await _callClaudeAPI(
          message: query,
          userType: userType,
          userId: userId,
        );

        if (response != null) {
          // Incrémenter le quota après succès
          await incrementLLMQuota(userId);

          final remainingInfo = quotaStatus.isUnlimited
              ? ''
              : '\n\n_💡 Quota IA : ${quotaStatus.remaining - 1}/${quotaStatus.limit} cette semaine_';

          return AIMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content: '$response$remainingInfo',
            isUser: false,
            timestamp: DateTime.now(),
            type: AIMessageType.text,
            metadata: {
              'source': 'claude_api',
              'quotaRemaining': quotaStatus.remaining - 1,
            },
          );
        }
      } catch (e) {
        debugPrint('❌ Erreur appel Claude API: $e');
        // Fallback en cas d'erreur (ne pas décompter le quota)
      }

      // Fallback si l'API échoue
      return AIMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: "Je n'ai pas pu traiter votre demande. Voici des suggestions qui pourraient vous aider :",
        isUser: false,
        timestamp: DateTime.now(),
        type: AIMessageType.quickReplies,
        metadata: {
          'source': 'fallback',
          'quickReplies': getQuickReplies(userType),
        },
      );
    }

    // 3. Réponse par défaut
    return AIMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: "Je n'ai pas trouvé de réponse à votre question. Essayez de reformuler ou choisissez une question ci-dessous :",
      isUser: false,
      timestamp: DateTime.now(),
      type: AIMessageType.quickReplies,
      metadata: {
        'source': 'no_match',
        'quickReplies': getQuickReplies(userType),
      },
    );
  }

  // ========== NIVEAU D'ACCÈS ==========

  /// Détermine le niveau d'accès IA selon l'abonnement
  static AIAccessLevel getAccessLevel({
    required String userType,
    String? subscriptionTier,
  }) {
    switch (userType) {
      case 'acheteur':
        // Acheteur = accès complet gratuit (données, alertes, LLM)
        return AIAccessLevel.premium;

      case 'vendeur':
        switch (subscriptionTier?.toUpperCase()) {
          case 'PREMIUM':
            return AIAccessLevel.premium;
          case 'PRO':
            return AIAccessLevel.pro;
          default: // BASIQUE
            return AIAccessLevel.basic;
        }

      case 'livreur':
        switch (subscriptionTier?.toUpperCase()) {
          case 'PREMIUM':
            return AIAccessLevel.premium;
          case 'PRO':
            return AIAccessLevel.pro;
          default: // STARTER
            return AIAccessLevel.basic;
        }

      default:
        return AIAccessLevel.none;
    }
  }

  // ========== CHARGEMENT CONTEXTE UTILISATEUR ==========

  static final _firestore = FirebaseFirestore.instance;

  /// Charge le contexte utilisateur depuis Firestore (PRO+ uniquement)
  static Future<UserContext?> loadUserContext({
    required String userId,
    required String userType,
  }) async {
    try {
      debugPrint('📊 Chargement contexte $userType: $userId');

      switch (userType) {
        case 'acheteur':
          return await _loadAcheteurContext(userId);
        case 'vendeur':
          return await _loadVendeurContext(userId);
        case 'livreur':
          return await _loadLivreurContext(userId);
        default:
          return null;
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement contexte: $e');
      return null;
    }
  }

  static Future<UserContext> _loadAcheteurContext(String userId) async {
    // Compter articles panier - Structure: users/{userId}/cart/current -> items[]
    final cartDoc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('cart')
        .doc('current')
        .get()
        .timeout(const Duration(seconds: 5), onTimeout: () => throw 'Timeout');

    final cartItems = cartDoc.exists
        ? ((cartDoc.data()?['items'] as List<dynamic>?) ?? [])
        : [];

    // Commandes en cours
    final pendingOrders = await _firestore
        .collection('orders')
        .where('buyerId', isEqualTo: userId)
        .where('status', whereIn: ['en_attente', 'en_cours'])
        .get()
        .timeout(const Duration(seconds: 5), onTimeout: () => throw 'Timeout');

    // Commandes livrées
    final deliveredOrders = await _firestore
        .collection('orders')
        .where('buyerId', isEqualTo: userId)
        .where('status', isEqualTo: 'livree')
        .get()
        .timeout(const Duration(seconds: 5), onTimeout: () => throw 'Timeout');

    return UserContext(
      userType: 'acheteur',
      userId: userId,
      cartItemsCount: cartItems.length,
      pendingOrdersCount: pendingOrders.docs.length,
      deliveredOrdersCount: deliveredOrders.docs.length,
    );
  }

  static Future<UserContext> _loadVendeurContext(String userId) async {
    // Nombre de produits
    final products = await _firestore
        .collection('products')
        .where('vendorId', isEqualTo: userId)
        .get()
        .timeout(const Duration(seconds: 5), onTimeout: () => throw 'Timeout');

    // Produits stock faible (<5)
    final lowStock = products.docs.where((doc) {
      final stock = doc.data()['stock'] as int? ?? 0;
      return stock < 5 && stock > 0;
    }).length;

    // Commandes à confirmer
    final pendingOrders = await _firestore
        .collection('orders')
        .where('vendorId', isEqualTo: userId)
        .where('status', isEqualTo: 'en_attente')
        .get()
        .timeout(const Duration(seconds: 5), onTimeout: () => throw 'Timeout');

    // Toutes les ventes
    final allOrders = await _firestore
        .collection('orders')
        .where('vendorId', isEqualTo: userId)
        .where('status', isEqualTo: 'livree')
        .get()
        .timeout(const Duration(seconds: 5), onTimeout: () => throw 'Timeout');

    // Solde portefeuille
    final walletDoc = await _firestore
        .collection('wallets')
        .doc(userId)
        .get()
        .timeout(const Duration(seconds: 5), onTimeout: () => throw 'Timeout');

    final balance = walletDoc.exists
        ? (walletDoc.data()?['balance'] as num?)?.toDouble() ?? 0.0
        : 0.0;

    return UserContext(
      userType: 'vendeur',
      userId: userId,
      productsCount: products.docs.length,
      lowStockProductsCount: lowStock,
      pendingOrdersToConfirm: pendingOrders.docs.length,
      totalSales: allOrders.docs.length,
      walletBalance: balance,
    );
  }

  static Future<UserContext> _loadLivreurContext(String userId) async {
    // Livraisons disponibles
    final available = await _firestore
        .collection('deliveries')
        .where('status', isEqualTo: 'available')
        .get()
        .timeout(const Duration(seconds: 5), onTimeout: () => throw 'Timeout');

    // Livraison en cours
    final active = await _firestore
        .collection('deliveries')
        .where('livreurId', isEqualTo: userId)
        .where('status', whereIn: ['assigned', 'picked_up', 'in_transit'])
        .get()
        .timeout(const Duration(seconds: 5), onTimeout: () => throw 'Timeout');

    // Livraisons terminées
    final completed = await _firestore
        .collection('deliveries')
        .where('livreurId', isEqualTo: userId)
        .where('status', isEqualTo: 'delivered')
        .get()
        .timeout(const Duration(seconds: 5), onTimeout: () => throw 'Timeout');

    // Gains
    final walletDoc = await _firestore
        .collection('wallets')
        .doc(userId)
        .get()
        .timeout(const Duration(seconds: 5), onTimeout: () => throw 'Timeout');

    final balance = walletDoc.exists
        ? (walletDoc.data()?['balance'] as num?)?.toDouble() ?? 0.0
        : 0.0;

    return UserContext(
      userType: 'livreur',
      userId: userId,
      availableDeliveriesCount: available.docs.length,
      activeDeliveryCount: active.docs.length,
      completedDeliveriesCount: completed.docs.length,
      earningsBalance: balance,
    );
  }

  /// Génère une réponse contextuelle basée sur les données
  static String? generateContextualResponse(String query, UserContext context) {
    final q = query.toLowerCase();

    switch (context.userType) {
      case 'acheteur':
        // Questions sur le panier
        if (q.contains('panier') || q.contains('cart')) {
          if (context.cartItemsCount == 0 || context.cartItemsCount == null) {
            return "🛒 Votre panier est vide. Explorez nos produits pour trouver ce qu'il vous faut !";
          }
          return "🛒 Vous avez ${context.cartItemsCount} article(s) dans votre panier.";
        }
        // Questions sur les commandes
        if (q.contains('commande')) {
          if (context.pendingOrdersCount == 0 || context.pendingOrdersCount == null) {
            final delivered = context.deliveredOrdersCount ?? 0;
            if (delivered == 0) {
              return "📦 Vous n'avez aucune commande pour le moment.";
            }
            return "📦 Vous n'avez aucune commande en cours. $delivered commande(s) livrée(s) au total.";
          }
          return "📦 Vous avez ${context.pendingOrdersCount} commande(s) en cours de traitement.";
        }
        break;

      case 'vendeur':
        // Questions sur les commandes
        if (q.contains('commande')) {
          final pending = context.pendingOrdersToConfirm ?? 0;
          if (pending == 0) {
            return "✅ Aucune commande en attente. Tout est à jour !";
          }
          return "📋 Vous avez $pending commande(s) à confirmer.";
        }
        // Questions sur les produits/stock
        if (q.contains('produit') || q.contains('stock') || q.contains('article') || q.contains('catalogue')) {
          final products = context.productsCount ?? 0;
          final lowStock = context.lowStockProductsCount ?? 0;
          String response = "📦 Vous avez $products produit(s) en ligne.";
          if (lowStock > 0) {
            response += "\n⚠️ $lowStock produit(s) ont un stock faible (<5).";
          }
          return response;
        }
        // Questions sur l'argent/solde/gains
        if (q.contains('solde') || q.contains('argent') || q.contains('gain') || q.contains('portefeuille') || q.contains('revenu')) {
          final balance = context.walletBalance?.toStringAsFixed(0) ?? '0';
          final sales = context.totalSales ?? 0;
          return "💰 Votre solde : $balance FCFA\n📊 Ventes totales : $sales";
        }
        // Questions sur les ventes/stats
        if (q.contains('vente') || q.contains('stat') || q.contains('chiffre') || q.contains('performance')) {
          final sales = context.totalSales ?? 0;
          final balance = context.walletBalance?.toStringAsFixed(0) ?? '0';
          return "📊 Vous avez réalisé $sales vente(s).\n💰 Solde disponible : $balance FCFA";
        }
        break;

      case 'livreur':
        // Questions sur les livraisons disponibles
        if (q.contains('disponible') || q.contains('course') || q.contains('nouvelle') || q.contains('opportunit')) {
          final available = context.availableDeliveriesCount ?? 0;
          if (available == 0) {
            return "📭 Aucune livraison disponible pour le moment. Restez connecté !";
          }
          return "🛵 $available livraison(s) disponible(s) près de vous !";
        }
        // Questions sur les livraisons en cours
        if (q.contains('livraison') || q.contains('en cours') || q.contains('active') || q.contains('mission')) {
          final active = context.activeDeliveryCount ?? 0;
          if (active == 0) {
            return "📦 Vous n'avez pas de livraison en cours.";
          }
          return "🚴 Vous avez $active livraison(s) en cours.";
        }
        // Questions sur les gains/argent
        if (q.contains('gain') || q.contains('argent') || q.contains('solde') || q.contains('revenu') || q.contains('salaire')) {
          final earnings = context.earningsBalance?.toStringAsFixed(0) ?? '0';
          final completed = context.completedDeliveriesCount ?? 0;
          return "💰 Vos gains : $earnings FCFA\n✅ Livraisons effectuées : $completed";
        }
        // Questions sur l'historique/stats
        if (q.contains('historique') || q.contains('stat') || q.contains('effectu') || q.contains('termin')) {
          final completed = context.completedDeliveriesCount ?? 0;
          final earnings = context.earningsBalance?.toStringAsFixed(0) ?? '0';
          return "📊 Livraisons terminées : $completed\n💰 Gains totaux : $earnings FCFA";
        }
        break;
    }
    return null;
  }

  // ========== ALERTES INTELLIGENTES (PRO+) ==========

  /// Représente une alerte pour l'utilisateur
  static List<SmartAlert> generateAlerts(UserContext context) {
    final alerts = <SmartAlert>[];

    switch (context.userType) {
      case 'acheteur':
        // Panier abandonné
        if (context.cartItemsCount != null && context.cartItemsCount! > 0) {
          alerts.add(SmartAlert(
            type: AlertType.info,
            title: 'Panier en attente',
            message: 'Vous avez ${context.cartItemsCount} article(s) dans votre panier.',
            actionLabel: 'Voir le panier',
            actionRoute: '/acheteur/cart',
          ));
        }
        break;

      case 'vendeur':
        // Commandes à confirmer (urgent)
        if (context.pendingOrdersToConfirm != null && context.pendingOrdersToConfirm! > 0) {
          alerts.add(SmartAlert(
            type: context.pendingOrdersToConfirm! >= 3 ? AlertType.urgent : AlertType.warning,
            title: 'Commandes en attente',
            message: '${context.pendingOrdersToConfirm} commande(s) à confirmer rapidement !',
            actionLabel: 'Gérer',
            actionRoute: '/vendeur/order-management',
          ));
        }
        // Stock faible
        if (context.lowStockProductsCount != null && context.lowStockProductsCount! > 0) {
          alerts.add(SmartAlert(
            type: AlertType.warning,
            title: 'Stock faible',
            message: '${context.lowStockProductsCount} produit(s) ont moins de 5 unités.',
            actionLabel: 'Voir produits',
            actionRoute: '/vendeur/products',
          ));
        }
        // Pas de produits
        if (context.productsCount == 0) {
          alerts.add(SmartAlert(
            type: AlertType.info,
            title: 'Boutique vide',
            message: 'Ajoutez des produits pour commencer à vendre.',
            actionLabel: 'Ajouter',
            actionRoute: '/vendeur/add-product',
          ));
        }
        break;

      case 'livreur':
        // Livraison en cours
        if (context.activeDeliveryCount != null && context.activeDeliveryCount! > 0) {
          alerts.add(SmartAlert(
            type: AlertType.info,
            title: 'Livraison active',
            message: 'Vous avez ${context.activeDeliveryCount} livraison(s) en cours.',
            actionLabel: 'Voir',
            actionRoute: '/livreur/deliveries',
          ));
        }
        // Livraisons disponibles
        if (context.availableDeliveriesCount != null && context.availableDeliveriesCount! > 0) {
          alerts.add(SmartAlert(
            type: AlertType.success,
            title: 'Opportunités',
            message: '${context.availableDeliveriesCount} livraison(s) disponible(s) !',
            actionLabel: 'Accepter',
            actionRoute: '/livreur/available-orders',
          ));
        }
        break;
    }

    return alerts;
  }

  /// Formate les alertes en message texte
  static String formatAlertsAsMessage(List<SmartAlert> alerts) {
    if (alerts.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('📋 **Alertes pour vous :**\n');

    for (final alert in alerts) {
      final icon = _getAlertIcon(alert.type);
      buffer.writeln('$icon **${alert.title}**');
      buffer.writeln('   ${alert.message}\n');
    }

    return buffer.toString();
  }

  static String _getAlertIcon(AlertType type) {
    switch (type) {
      case AlertType.urgent:
        return '🔴';
      case AlertType.warning:
        return '🟠';
      case AlertType.info:
        return '🔵';
      case AlertType.success:
        return '🟢';
    }
  }

  // ========== QUOTA LLM (PRO: 50/semaine, PREMIUM/Acheteur: illimité) ==========

  static const int _proWeeklyQuotaLimit = 50;

  /// Vérifie si l'utilisateur peut faire un appel LLM
  static Future<QuotaStatus> checkLLMQuota({
    required String userId,
    required AIAccessLevel accessLevel,
    String? userType,
  }) async {
    // Acheteur = illimité gratuit
    if (userType == 'acheteur') {
      return QuotaStatus(allowed: true, remaining: -1, limit: -1);
    }

    // PREMIUM = illimité
    if (accessLevel == AIAccessLevel.premium) {
      return QuotaStatus(allowed: true, remaining: -1, limit: -1);
    }

    // BASIC/STARTER = pas d'accès LLM
    if (accessLevel == AIAccessLevel.basic || accessLevel == AIAccessLevel.none) {
      return QuotaStatus(allowed: false, remaining: 0, limit: 0, reason: 'Passez PRO pour accéder à l\'IA');
    }

    // PRO = 20/semaine
    try {
      final weekKey = _getWeekKey();
      final quotaDoc = await _firestore
          .collection('ai_quotas')
          .doc('${userId}_$weekKey')
          .get()
          .timeout(const Duration(seconds: 5));

      final currentCount = quotaDoc.exists
          ? (quotaDoc.data()?['count'] as int? ?? 0)
          : 0;

      final remaining = _proWeeklyQuotaLimit - currentCount;
      final resetDate = _getNextMondayDate();

      if (remaining <= 0) {
        return QuotaStatus(
          allowed: false,
          remaining: 0,
          limit: _proWeeklyQuotaLimit,
          reason: 'Quota hebdo atteint (20/sem). Renouvellement $resetDate ou passez PREMIUM pour l\'illimité.',
        );
      }

      return QuotaStatus(
        allowed: true,
        remaining: remaining,
        limit: _proWeeklyQuotaLimit,
      );
    } catch (e) {
      debugPrint('⚠️ Erreur vérification quota: $e');
      return QuotaStatus(allowed: true, remaining: _proWeeklyQuotaLimit, limit: _proWeeklyQuotaLimit);
    }
  }

  /// Incrémente le compteur de quota après un appel LLM réussi
  static Future<void> incrementLLMQuota(String userId) async {
    try {
      final weekKey = _getWeekKey();
      final docRef = _firestore.collection('ai_quotas').doc('${userId}_$weekKey');

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);

        if (doc.exists) {
          transaction.update(docRef, {
            'count': FieldValue.increment(1),
            'lastUsed': FieldValue.serverTimestamp(),
          });
        } else {
          transaction.set(docRef, {
            'userId': userId,
            'weekKey': weekKey,
            'count': 1,
            'createdAt': FieldValue.serverTimestamp(),
            'lastUsed': FieldValue.serverTimestamp(),
            'resetsAt': _getNextMonday(),
          });
        }
      });

      debugPrint('✅ Quota LLM incrémenté pour $userId');
    } catch (e) {
      debugPrint('⚠️ Erreur incrémentation quota: $e');
    }
  }

  /// Retourne la clé de la semaine (YYYY-WXX)
  static String _getWeekKey() {
    final now = DateTime.now();
    final firstDayOfYear = DateTime(now.year, 1, 1);
    final daysSinceFirstDay = now.difference(firstDayOfYear).inDays;
    final weekNumber = ((daysSinceFirstDay + firstDayOfYear.weekday - 1) / 7).ceil();
    return '${now.year}-W${weekNumber.toString().padLeft(2, '0')}';
  }

  /// Retourne le prochain lundi (Timestamp)
  static DateTime _getNextMonday() {
    final now = DateTime.now();
    final daysUntilMonday = (DateTime.monday - now.weekday + 7) % 7;
    final nextMonday = daysUntilMonday == 0 ? 7 : daysUntilMonday;
    return DateTime(now.year, now.month, now.day + nextMonday, 0, 0, 0);
  }

  /// Retourne la date du prochain lundi formatée
  static String _getNextMondayDate() {
    final nextMonday = _getNextMonday();
    return '${nextMonday.day.toString().padLeft(2, '0')}/${nextMonday.month.toString().padLeft(2, '0')}';
  }

  // ========== APPEL API CLAUDE VIA CLOUD FUNCTION ==========

  /// Historique de conversation pour le contexte
  static final List<Map<String, String>> _conversationHistory = [];

  /// Appelle la Cloud Function qui communique avec l'API Claude
  static Future<String?> _callClaudeAPI({
    required String message,
    required String userType,
    String? userId,
    String? userName,
  }) async {
    try {
      // Référence à la Cloud Function (région europe-west1)
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      final callable = functions.httpsCallable(
        'claudeChat',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 60),
        ),
      );

      // Préparer les données
      final requestData = {
        'message': message,
        'userType': userType,
        'userName': userName,
        'conversationHistory': _conversationHistory.take(10).toList(),
      };

      // Appeler la fonction
      final result = await callable.call(requestData);
      final data = result.data as Map<String, dynamic>;

      if (data['success'] == true && data['message'] != null) {
        // Ajouter à l'historique
        _conversationHistory.add({'role': 'user', 'content': message});
        _conversationHistory.add({'role': 'assistant', 'content': data['message']});

        // Limiter l'historique à 20 messages
        if (_conversationHistory.length > 20) {
          _conversationHistory.removeRange(0, _conversationHistory.length - 20);
        }

        debugPrint('✅ Claude API - Tokens: ${data['usage']}');
        return data['message'] as String;
      }

      return null;
    } on FirebaseFunctionsException catch (e) {
      debugPrint('❌ Firebase Functions Error: ${e.code} - ${e.message}');

      // Messages d'erreur personnalisés
      switch (e.code) {
        case 'unauthenticated':
          throw Exception('Veuillez vous connecter pour utiliser l\'assistant IA.');
        case 'resource-exhausted':
          throw Exception('L\'assistant est très sollicité. Réessayez dans un moment.');
        case 'invalid-argument':
          throw Exception('Message invalide. Veuillez reformuler.');
        default:
          throw Exception('Erreur de l\'assistant. Veuillez réessayer.');
      }
    } catch (e) {
      debugPrint('❌ Erreur Claude API: $e');
      return null;
    }
  }

  /// Vérifier le quota IA de l'utilisateur
  static Future<Map<String, dynamic>> checkAIQuota() async {
    try {
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      final callable = functions.httpsCallable('checkAIQuota');

      final result = await callable.call();
      return result.data as Map<String, dynamic>;
    } catch (e) {
      debugPrint('❌ Erreur vérification quota: $e');
      return {
        'allowed': false,
        'reason': 'Impossible de vérifier le quota',
      };
    }
  }

  /// Réinitialiser l'historique de conversation
  static void clearConversationHistory() {
    _conversationHistory.clear();
  }
}
