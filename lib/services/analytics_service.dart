// ===== lib/services/analytics_service.dart =====
// Service d'analytics et de suivi des événements - SOCIAL BUSINESS Pro

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../config/constants.dart';

/// Service d'analytics
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String? _userId;
  String? _userType;

  // ===== INITIALISATION =====

  /// Initialiser le service
  void initialize(String userId, String userType) {
    _userId = userId;
    _userType = userType;
    debugPrint('✅ Analytics initialisé pour: $userId ($userType)');
  }

  // ===== ÉVÉNEMENTS UTILISATEUR =====

  /// Enregistrer une vue d'écran
  Future<void> logScreenView(String screenName) async {
    try {
      await _logEvent('screen_view', {
        'screen_name': screenName,
        'user_type': _userType,
      });
    } catch (e) {
      debugPrint('❌ Erreur log screen view: $e');
    }
  }

  /// Enregistrer une connexion
  Future<void> logLogin(String method) async {
    try {
      await _logEvent('login', {
        'method': method, // email, google, phone
        'user_type': _userType,
      });
    } catch (e) {
      debugPrint('❌ Erreur log login: $e');
    }
  }

  /// Enregistrer une inscription
  Future<void> logSignUp(String method, String userType) async {
    try {
      await _logEvent('sign_up', {
        'method': method,
        'user_type': userType,
      });
    } catch (e) {
      debugPrint('❌ Erreur log sign up: $e');
    }
  }

  /// Enregistrer une recherche
  Future<void> logSearch(String searchTerm, String? category) async {
    try {
      await _logEvent('search', {
        'search_term': searchTerm,
        'category': category,
      });
    } catch (e) {
      debugPrint('❌ Erreur log search: $e');
    }
  }

  // ===== ÉVÉNEMENTS PRODUITS =====

  /// Enregistrer une vue de produit
  Future<void> logViewProduct({
    required String productId,
    required String productName,
    required String category,
    required double price,
  }) async {
    try {
      await _logEvent('view_product', {
        'product_id': productId,
        'product_name': productName,
        'category': category,
        'price': price,
      });

      // Incrémenter le compteur de vues du produit
      await _incrementProductMetric(productId, 'views');
    } catch (e) {
      debugPrint('❌ Erreur log view product: $e');
    }
  }

  /// Enregistrer un ajout au panier
  Future<void> logAddToCart({
    required String productId,
    required String productName,
    required double price,
    required int quantity,
  }) async {
    try {
      await _logEvent('add_to_cart', {
        'product_id': productId,
        'product_name': productName,
        'price': price,
        'quantity': quantity,
        'value': price * quantity,
      });

      // Incrémenter le compteur d'ajouts au panier
      await _incrementProductMetric(productId, 'cart_adds');
    } catch (e) {
      debugPrint('❌ Erreur log add to cart: $e');
    }
  }

  /// Enregistrer une suppression du panier
  Future<void> logRemoveFromCart({
    required String productId,
    required String productName,
  }) async {
    try {
      await _logEvent('remove_from_cart', {
        'product_id': productId,
        'product_name': productName,
      });
    } catch (e) {
      debugPrint('❌ Erreur log remove from cart: $e');
    }
  }

  // ===== ÉVÉNEMENTS COMMANDES =====

  /// Enregistrer le début d'un checkout
  Future<void> logBeginCheckout({
    required double value,
    required int itemCount,
  }) async {
    try {
      await _logEvent('begin_checkout', {
        'value': value,
        'item_count': itemCount,
        'currency': 'XOF',
      });
    } catch (e) {
      debugPrint('❌ Erreur log begin checkout: $e');
    }
  }

  /// Enregistrer un achat
  Future<void> logPurchase({
    required String orderId,
    required double value,
    required double deliveryFee,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      await _logEvent('purchase', {
        'transaction_id': orderId,
        'value': value,
        'delivery_fee': deliveryFee,
        'currency': 'XOF',
        'items': items,
      });

      // Incrémenter les métriques des produits achetés
      for (var item in items) {
        await _incrementProductMetric(item['productId'], 'purchases');
        await _incrementProductRevenue(
          item['productId'],
          item['price'] * item['quantity'],
        );
      }
    } catch (e) {
      debugPrint('❌ Erreur log purchase: $e');
    }
  }

  /// Enregistrer une annulation de commande
  Future<void> logCancelOrder({
    required String orderId,
    required String reason,
  }) async {
    try {
      await _logEvent('cancel_order', {
        'order_id': orderId,
        'reason': reason,
      });
    } catch (e) {
      debugPrint('❌ Erreur log cancel order: $e');
    }
  }

  // ===== ÉVÉNEMENTS VENDEUR =====

  /// Enregistrer l'ajout d'un produit
  Future<void> logAddProduct({
    required String productId,
    required String category,
    required double price,
  }) async {
    try {
      await _logEvent('add_product', {
        'product_id': productId,
        'category': category,
        'price': price,
      });
    } catch (e) {
      debugPrint('❌ Erreur log add product: $e');
    }
  }

  /// Enregistrer la modification d'un produit
  Future<void> logEditProduct(String productId) async {
    try {
      await _logEvent('edit_product', {
        'product_id': productId,
      });
    } catch (e) {
      debugPrint('❌ Erreur log edit product: $e');
    }
  }

  /// Enregistrer la suppression d'un produit
  Future<void> logDeleteProduct(String productId) async {
    try {
      await _logEvent('delete_product', {
        'product_id': productId,
      });
    } catch (e) {
      debugPrint('❌ Erreur log delete product: $e');
    }
  }

  // ===== ÉVÉNEMENTS LIVRAISON =====

  /// Enregistrer l'acceptation d'une livraison
  Future<void> logAcceptDelivery({
    required String deliveryId,
    required double deliveryFee,
  }) async {
    try {
      await _logEvent('accept_delivery', {
        'delivery_id': deliveryId,
        'delivery_fee': deliveryFee,
      });
    } catch (e) {
      debugPrint('❌ Erreur log accept delivery: $e');
    }
  }

  /// Enregistrer la complétion d'une livraison
  Future<void> logCompleteDelivery({
    required String deliveryId,
    required double deliveryFee,
    required double distance,
    required int duration,
  }) async {
    try {
      await _logEvent('complete_delivery', {
        'delivery_id': deliveryId,
        'delivery_fee': deliveryFee,
        'distance': distance,
        'duration': duration,
      });
    } catch (e) {
      debugPrint('❌ Erreur log complete delivery: $e');
    }
  }

  // ===== ÉVÉNEMENTS PAIEMENT =====

  /// Enregistrer un paiement réussi
  Future<void> logPaymentSuccess({
    required String paymentMethod,
    required double amount,
  }) async {
    try {
      await _logEvent('payment_success', {
        'payment_method': paymentMethod,
        'amount': amount,
        'currency': 'XOF',
      });
    } catch (e) {
      debugPrint('❌ Erreur log payment success: $e');
    }
  }

  /// Enregistrer un échec de paiement
  Future<void> logPaymentFailed({
    required String paymentMethod,
    required double amount,
    required String reason,
  }) async {
    try {
      await _logEvent('payment_failed', {
        'payment_method': paymentMethod,
        'amount': amount,
        'currency': 'XOF',
        'reason': reason,
      });
    } catch (e) {
      debugPrint('❌ Erreur log payment failed: $e');
    }
  }

  // ===== ÉVÉNEMENTS SOCIAUX =====

  /// Enregistrer un partage
  Future<void> logShare({
    required String contentType,
    required String contentId,
    required String method,
  }) async {
    try {
      await _logEvent('share', {
        'content_type': contentType,
        'content_id': contentId,
        'method': method,
      });
    } catch (e) {
      debugPrint('❌ Erreur log share: $e');
    }
  }

  /// Enregistrer un ajout aux favoris
  Future<void> logAddToFavorites(String productId) async {
    try {
      await _logEvent('add_to_favorites', {
        'product_id': productId,
      });
    } catch (e) {
      debugPrint('❌ Erreur log add to favorites: $e');
    }
  }

  // ===== MÉTRIQUES PRODUITS =====

  /// Incrémenter une métrique de produit
  Future<void> _incrementProductMetric(String productId, String metric) async {
    try {
      final productRef = _db
          .collection(FirebaseCollections.products)
          .doc(productId);

      await productRef.update({
        'analytics.$metric': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('❌ Erreur increment product metric: $e');
    }
  }

  /// Incrémenter le revenu d'un produit
  Future<void> _incrementProductRevenue(String productId, double amount) async {
    try {
      final productRef = _db
          .collection(FirebaseCollections.products)
          .doc(productId);

      await productRef.update({
        'analytics.revenue': FieldValue.increment(amount),
      });
    } catch (e) {
      debugPrint('❌ Erreur increment product revenue: $e');
    }
  }

  // ===== ENREGISTREMENT GÉNÉRIQUE =====

  /// Enregistrer un événement générique
  Future<void> _logEvent(String eventName, Map<String, dynamic> parameters) async {
    try {
      // Ajouter les métadonnées communes
      parameters['timestamp'] = FieldValue.serverTimestamp();
      parameters['user_id'] = _userId;
      parameters['user_type'] = _userType;
      parameters['platform'] = defaultTargetPlatform.toString();

      // Enregistrer dans Firestore
      await _db.collection(FirebaseCollections.analytics).add({
        'event_name': eventName,
        'parameters': parameters,
      });

      debugPrint('📊 Event logged: $eventName');
    } catch (e) {
      debugPrint('❌ Erreur log event: $e');
    }
  }

  // ===== STATISTIQUES =====

  /// Obtenir les produits les plus vus
  Future<List<Map<String, dynamic>>> getTopViewedProducts({
    int limit = 10,
    String? category,
  }) async {
    try {
      Query query = _db
          .collection(FirebaseCollections.products)
          .where('isActive', isEqualTo: true)
          .orderBy('analytics.views', descending: true)
          .limit(limit);

      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();
    } catch (e) {
      debugPrint('❌ Erreur récupération top viewed: $e');
      return [];
    }
  }

  /// Obtenir les tendances de recherche
  Future<List<Map<String, dynamic>>> getSearchTrends({
    int limit = 10,
    DateTime? from,
  }) async {
    try {
      Query query = _db
          .collection(FirebaseCollections.analytics)
          .where('event_name', isEqualTo: 'search')
          .orderBy('parameters.timestamp', descending: true)
          .limit(limit * 5); // Plus pour agréger

      if (from != null) {
        query = query.where('parameters.timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(from));
      }

      final snapshot = await query.get();

      // Compter les occurrences de chaque terme
      final Map<String, int> termCounts = {};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final term = data['parameters']['search_term'] as String?;
        if (term != null) {
          termCounts[term] = (termCounts[term] ?? 0) + 1;
        }
      }

      // Trier et limiter
      final sortedTerms = termCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedTerms
          .take(limit)
          .map((e) => {
                'term': e.key,
                'count': e.value,
              })
          .toList();
    } catch (e) {
      debugPrint('❌ Erreur récupération search trends: $e');
      return [];
    }
  }

}
