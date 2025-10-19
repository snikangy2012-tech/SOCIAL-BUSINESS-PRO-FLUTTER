// ===== lib/providers/cart_provider.dart =====
// Provider de gestion du panier - SOCIAL BUSINESS Pro

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../config/constants.dart';
import '../models/product_model.dart';
import '../services/analytics_service.dart';

/// Item du panier
class CartItem {
  final String productId;
  final String productName;
  final String productImage;
  final double price;
  int quantity;
  final int maxStock;
  final String vendeurId;

  CartItem({
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.price,
    required this.quantity,
    required this.maxStock,
    required this.vendeurId,
  });

  double get total => price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'price': price,
      'quantity': quantity,
      'maxStock': maxStock,
      'vendeurId': vendeurId,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> data) {
    return CartItem(
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      productImage: data['productImage'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      quantity: data['quantity'] ?? 0,
      maxStock: data['maxStock'] ?? 0,
      vendeurId: data['vendeurId'] ?? '',
    );
  }
}

/// Provider de gestion du panier
class CartProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AnalyticsService _analytics = AnalyticsService();

  String? _userId;
  List<CartItem> _items = [];
  bool _isLoading = false;

  // Getters
  List<CartItem> get items => _items;
  bool get isLoading => _isLoading;
  int get itemCount => _items.length;
  int get totalQuantity => _items.fold(0, (total, item) => total + item.quantity);
  
  double get subtotal {
    return _items.fold(0, (total, item) => total + item.total);
  }

  double get deliveryFee {
    // Frais de livraison dynamiques selon le vendeur
    // Pour l'instant, frais fixe
    return _items.isEmpty ? 0 : 1500;
  }

  double get total => subtotal + deliveryFee;

  // Définir l'utilisateur
  void setUserId(String userId) {
    if (_userId != userId) {
      _userId = userId;
      _loadCart();
    }
  }

  // ===== GESTION DU PANIER =====

  /// Charger le panier depuis Firestore
  Future<void> _loadCart() async {
    if (_userId == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      final doc = await _db
          .collection(FirebaseCollections.users)
          .doc(_userId)
          .collection('cart')
          .doc('current')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final itemsList = data['items'] as List<dynamic>? ?? [];
        
        _items = itemsList
            .map((item) => CartItem.fromMap(item as Map<String, dynamic>))
            .toList();
      } else {
        _items = [];
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur chargement panier: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sauvegarder le panier dans Firestore
  Future<void> _saveCart() async {
    if (_userId == null) return;

    try {
      await _db
          .collection(FirebaseCollections.users)
          .doc(_userId)
          .collection('cart')
          .doc('current')
          .set({
        'items': _items.map((item) => item.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Erreur sauvegarde panier: $e');
    }
  }

  /// Ajouter un produit au panier
  Future<void> addProduct(ProductModel product, {int quantity = 1}) async {
    try {
      // Vérifier si le produit existe déjà
      final existingIndex = _items.indexWhere(
        (item) => item.productId == product.id,
      );

      if (existingIndex >= 0) {
        // Augmenter la quantité
        final newQuantity = _items[existingIndex].quantity + quantity;
        
        if (newQuantity <= product.stock) {
          _items[existingIndex].quantity = newQuantity;
        } else {
          throw Exception('Stock insuffisant (${product.stock} disponibles)');
        }
      } else {
        // Ajouter un nouveau produit
        if (quantity > product.stock) {
          throw Exception('Stock insuffisant (${product.stock} disponibles)');
        }

        _items.add(CartItem(
          productId: product.id,
          productName: product.name,
          productImage: product.images.isNotEmpty ? product.images.first : '',
          price: product.price,
          quantity: quantity,
          maxStock: product.stock,
          vendeurId: product.vendeurId,
        ));
      }

      // Logger l'événement
      await _analytics.logAddToCart(
        productId: product.id,
        productName: product.name,
        price: product.price,
        quantity: quantity,
      );

      await _saveCart();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Mettre à jour la quantité d'un item
  Future<void> updateQuantity(String productId, int newQuantity) async {
    try {
      final index = _items.indexWhere((item) => item.productId == productId);
      
      if (index < 0) return;

      if (newQuantity <= 0) {
        await removeItem(productId);
        return;
      }

      if (newQuantity > _items[index].maxStock) {
        throw Exception('Stock insuffisant');
      }

      _items[index].quantity = newQuantity;

      await _saveCart();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Augmenter la quantité
  Future<void> incrementQuantity(String productId) async {
    try {
      final item = _items.firstWhere((item) => item.productId == productId);
      await updateQuantity(productId, item.quantity + 1);
    } catch (e) {
      throw Exception('Produit introuvable dans le panier');
    }
  }

  /// Diminuer la quantité
  Future<void> decrementQuantity(String productId) async {
    try {
      final item = _items.firstWhere((item) => item.productId == productId);
      await updateQuantity(productId, item.quantity - 1);
    } catch (e) {
      throw Exception('Produit introuvable dans le panier');
    }
  }

  /// Retirer un item du panier
  Future<void> removeItem(String productId) async {
    try {
      final item = _items.firstWhere((item) => item.productId == productId);
      
      _items.removeWhere((item) => item.productId == productId);

      // Logger l'événement
      await _analytics.logRemoveFromCart(
        productId: item.productId,
        productName: item.productName,
      );

      await _saveCart();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Vider le panier
  Future<void> clearCart() async {
    try {
      _items.clear();
      await _saveCart();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// Vérifier si un produit est dans le panier
  bool isInCart(String productId) {
    return _items.any((item) => item.productId == productId);
  }

  /// Obtenir la quantité d'un produit dans le panier
  int getQuantity(String productId) {
    final item = _items.firstWhere(
      (item) => item.productId == productId,
      orElse: () => CartItem(
        productId: '',
        productName: '',
        productImage: '',
        price: 0,
        quantity: 0,
        maxStock: 0,
        vendeurId: '',
      ),
    );
    return item.quantity;
  }

  /// Grouper les items par vendeur
  Map<String, List<CartItem>> getItemsByVendeur() {
    final Map<String, List<CartItem>> grouped = {};

    for (var item in _items) {
      if (!grouped.containsKey(item.vendeurId)) {
        grouped[item.vendeurId] = [];
      }
      grouped[item.vendeurId]!.add(item);
    }

    return grouped;
  }

  /// Calculer le sous-total par vendeur
  double getVendeurSubtotal(String vendeurId) {
    return _items
        .where((item) => item.vendeurId == vendeurId)
        .fold(0, (total, item) => total + item.total);
  }
}
