// ===== lib/providers/favorite_provider.dart =====
// Provider de gestion des favoris - SOCIAL BUSINESS Pro

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:social_business_pro/config/constants.dart';
import '../services/analytics_service.dart';

/// Provider de gestion des favoris
class FavoriteProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AnalyticsService _analytics = AnalyticsService();

  String? _userId;
  Set<String> _favoriteIds = {}; // IDs des produits favoris
  Set<String> _favoriteVendorIds = {}; // IDs des vendeurs favoris
  bool _isLoading = false;

  // Getters
  Set<String> get favoriteIds => _favoriteIds;
  Set<String> get favoriteVendorIds => _favoriteVendorIds;
  bool get isLoading => _isLoading;
  int get productCount => _favoriteIds.length;
  int get vendorCount => _favoriteVendorIds.length;
  int get count => _favoriteIds.length + _favoriteVendorIds.length;

  // Définir l'utilisateur
  void setUserId(String userId) {
    debugPrint('🔑 FavoriteProvider: setUserId appelé avec userId: $userId');
    if (_userId != userId) {
      _userId = userId;
      debugPrint('🔑 FavoriteProvider: Chargement des favoris pour userId: $_userId');
      _loadFavorites();
    } else {
      debugPrint('🔑 FavoriteProvider: userId déjà défini, pas de rechargement');
    }
  }

  // ===== GESTION DES FAVORIS =====

  /// Charger les favoris depuis Firestore
  Future<void> _loadFavorites() async {
    if (_userId == null) {
      debugPrint('⚠️ FavoriteProvider: _loadFavorites appelé mais userId est null');
      return;
    }

    try {
      debugPrint('⭐ FavoriteProvider: Chargement des favoris pour userId: $_userId');
      _isLoading = true;
      notifyListeners();

      final doc = await _db
          .collection(FirebaseCollections.users)
          .doc(_userId)
          .collection('favorites')
          .doc('list')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final favoritesList = data['productIds'] as List<dynamic>? ?? [];
        final vendorsList = data['vendorIds'] as List<dynamic>? ?? [];
        _favoriteIds = favoritesList.cast<String>().toSet();
        _favoriteVendorIds = vendorsList.cast<String>().toSet();
        debugPrint('✅ FavoriteProvider: ${_favoriteIds.length} produits favoris et ${_favoriteVendorIds.length} vendeurs favoris chargés');
      } else {
        _favoriteIds = {};
        _favoriteVendorIds = {};
        debugPrint('ℹ️ FavoriteProvider: Aucun favori existant, création d\'une nouvelle liste');
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ FavoriteProvider: Erreur chargement favoris: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sauvegarder les favoris dans Firestore
  Future<void> _saveFavorites() async {
    if (_userId == null) {
      debugPrint('⚠️ FavoriteProvider: _saveFavorites appelé mais userId est null');
      return;
    }

    try {
      debugPrint('💾 FavoriteProvider: Sauvegarde des favoris (${_favoriteIds.length} items) pour userId: $_userId');

      await _db
          .collection(FirebaseCollections.users)
          .doc(_userId)
          .collection('favorites')
          .doc('list')
          .set({
        'productIds': _favoriteIds.toList(),
        'vendorIds': _favoriteVendorIds.toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ FavoriteProvider: Favoris sauvegardés avec succès');
    } catch (e) {
      debugPrint('❌ FavoriteProvider: Erreur sauvegarde favoris: $e');
      rethrow; // Propager l'erreur pour que l'UI puisse la gérer
    }
  }

  /// Vérifier si un produit est favori
  bool isFavorite(String productId) {
    return _favoriteIds.contains(productId);
  }

  /// Basculer le statut favori d'un produit
  Future<void> toggleFavorite(String productId, String productName) async {
    try {
      // Vérifier que l'utilisateur est connecté
      if (_userId == null) {
        debugPrint('❌ FavoriteProvider: userId est null, impossible de modifier les favoris');
        throw Exception('Vous devez être connecté pour gérer vos favoris');
      }

      if (_favoriteIds.contains(productId)) {
        // Retirer des favoris
        _favoriteIds.remove(productId);
        debugPrint('⭐ FavoriteProvider: Produit $productName retiré des favoris');
      } else {
        // Ajouter aux favoris
        _favoriteIds.add(productId);
        debugPrint('⭐ FavoriteProvider: Produit $productName ajouté aux favoris');

        // Logger l'événement
        await _analytics.logAddToFavorites(productId);
      }

      await _saveFavorites();
      notifyListeners();
      debugPrint('✅ FavoriteProvider: Favoris mis à jour avec succès');
    } catch (e) {
      debugPrint('❌ FavoriteProvider: Erreur toggle favori: $e');
      rethrow;
    }
  }

  /// Retirer un produit des favoris
  Future<void> removeFavorite(String productId) async {
    try {
      _favoriteIds.remove(productId);
      await _saveFavorites();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Erreur suppression favori: $e');
      rethrow;
    }
  }

  /// Vider tous les favoris produits
  Future<void> clearFavorites() async {
    try {
      _favoriteIds.clear();
      await _saveFavorites();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Erreur vidage favoris: $e');
      rethrow;
    }
  }

  // ===== GESTION DES VENDEURS FAVORIS =====

  /// Vérifier si un vendeur est favori
  bool isFavoriteVendor(String vendorId) {
    return _favoriteVendorIds.contains(vendorId);
  }

  /// Basculer le statut favori d'un vendeur
  Future<void> toggleFavoriteVendor(String vendorId, String vendorName) async {
    try {
      // Vérifier que l'utilisateur est connecté
      if (_userId == null) {
        debugPrint('❌ FavoriteProvider: userId est null, impossible de modifier les vendeurs favoris');
        throw Exception('Vous devez être connecté pour gérer vos vendeurs favoris');
      }

      if (_favoriteVendorIds.contains(vendorId)) {
        // Retirer des favoris
        _favoriteVendorIds.remove(vendorId);
        debugPrint('⭐ FavoriteProvider: Vendeur $vendorName retiré des favoris');
      } else {
        // Ajouter aux favoris
        _favoriteVendorIds.add(vendorId);
        debugPrint('⭐ FavoriteProvider: Vendeur $vendorName ajouté aux favoris');
      }

      await _saveFavorites();
      notifyListeners();
      debugPrint('✅ FavoriteProvider: Vendeurs favoris mis à jour avec succès');
    } catch (e) {
      debugPrint('❌ FavoriteProvider: Erreur toggle vendeur favori: $e');
      rethrow;
    }
  }

  /// Retirer un vendeur des favoris
  Future<void> removeFavoriteVendor(String vendorId) async {
    try {
      _favoriteVendorIds.remove(vendorId);
      await _saveFavorites();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Erreur suppression vendeur favori: $e');
      rethrow;
    }
  }

  /// Vider tous les vendeurs favoris
  Future<void> clearFavoriteVendors() async {
    try {
      _favoriteVendorIds.clear();
      await _saveFavorites();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Erreur vidage vendeurs favoris: $e');
      rethrow;
    }
  }
}
