// ===== lib/services/product_service.dart =====
// Service de gestion des produits - SOCIAL BUSINESS Pro
// Migré depuis src/services/product.service.ts

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import 'package:social_business_pro/config/constants.dart';
import '../models/product_model.dart';
import 'kyc_verification_service.dart';

class ProductService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ===== RÉCUPÉRATION DES PRODUITS =====

  /// Récupérer tous les produits
  Future<List<ProductModel>> getProducts({
    bool? isActive,
    String? category,
    int limit = 100,
  }) async {
    try {
      Query query = _db.collection(FirebaseCollections.products);

      if (isActive != null) {
        query = query.where('isActive', isEqualTo: isActive);
      }

      if (category != null && category != 'all') {
        query = query.where('category', isEqualTo: category);
      }

      query = query.orderBy('createdAt', descending: true).limit(limit);

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ Erreur récupération produits: $e');
      return [];
    }
  }

  /// Récupérer un produit par ID
  Future<ProductModel?> getProduct(String productId) async {
    try {
      final doc = await _db
          .collection(FirebaseCollections.products)
          .doc(productId)
          .get();

      if (!doc.exists) return null;

      return ProductModel.fromMap(doc.data()!);
    } catch (e) {
      debugPrint('❌ Erreur récupération produit: $e');
      return null;
    }
  }

  /// Récupérer les produits d'un vendeur
  Future<List<ProductModel>> getVendorProducts(String vendeurId) async {
    try {
      debugPrint('📊 Récupération produits pour vendeur: $vendeurId');

      final snapshot = await _db
          .collection(FirebaseCollections.products)
          .where('vendeurId', isEqualTo: vendeurId)
          .orderBy('createdAt', descending: true)
          .get();

      debugPrint('✅ Produits récupérés: ${snapshot.docs.length}');
      for (var doc in snapshot.docs) {
        debugPrint('  - ${doc.id}: ${doc.data()['name']} (actif: ${doc.data()['isActive']})');
      }

      return snapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data()))
          .toList();
    } catch (e, stackTrace) {
      debugPrint('❌ Erreur récupération produits vendeur: $e');
      debugPrint('📍 Stack trace: $stackTrace');
      return [];
    }
  }

  /// Rechercher des produits
  Future<List<ProductModel>> searchProducts({
    required String query,
    String? category,
    double? minPrice,
    double? maxPrice,
  }) async {
    try {
      Query firestoreQuery = _db
          .collection(FirebaseCollections.products)
          .where('isActive', isEqualTo: true);

      if (category != null && category != 'all') {
        firestoreQuery = firestoreQuery.where('category', isEqualTo: category);
      }

      final snapshot = await firestoreQuery.limit(100).get();

      // Filtrage local pour la recherche
      var products = snapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Recherche textuelle
      if (query.isNotEmpty) {
        final searchTerm = query.toLowerCase();
        products = products.where((p) {
          return p.name.toLowerCase().contains(searchTerm) ||
              p.description.toLowerCase().contains(searchTerm) ||
              p.tags.any((tag) => tag.toLowerCase().contains(searchTerm));
        }).toList();
      }

      // Filtre par prix
      if (minPrice != null) {
        products = products.where((p) => p.price >= minPrice).toList();
      }

      if (maxPrice != null) {
        products = products.where((p) => p.price <= maxPrice).toList();
      }

      return products;
    } catch (e) {
      debugPrint('❌ Erreur recherche produits: $e');
      return [];
    }
  }

  // ===== CRÉATION ET MODIFICATION =====

  /// Créer un nouveau produit
  Future<String> createProduct(CreateProductData product) async {
    try {
      // 🔐 VÉRIFICATION KYC: Le vendeur doit être vérifié pour créer des produits
      final canSell = await KYCVerificationService.canPerformAction(
        product.vendeurId,
        'sell',
      );

      if (!canSell) {
        debugPrint('❌ Vendeur ${product.vendeurId} non vérifié - création produit bloquée');
        throw Exception(
          'Votre compte doit être vérifié avant d\'ajouter des produits. '
          'Complétez votre vérification d\'identité dans "Profil > Vérification".',
        );
      }

      final productRef = _db.collection(FirebaseCollections.products).doc();
      final productId = productRef.id;

      // Upload des images
      List<String> imageUrls = [];
      for (int i = 0; i < product.images.length; i++) {
        final imageUrl = await _uploadImage(
          productId,
          product.images[i],
          i,
        );
        if (imageUrl != null) {
          imageUrls.add(imageUrl);
        }
      }

      // Créer le produit
      final productModel = ProductModel(
        id: productId,
        name: product.name,
        description: product.description,
        price: product.price,
        originalPrice: product.originalPrice,
        category: product.category,
        subCategory: product.subCategory,
        brand: product.brand,
        images: imageUrls,
        stock: product.stock,
        sku: product.sku,
        tags: product.tags,
        isActive: product.isActive,
        isFeatured: product.isFeatured ?? false,
        vendeurId: product.vendeurId,
        vendeurName: product.vendeurName,
        specifications: product.specifications,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isFlashSale: product.originalPrice != null && product.originalPrice! > product.price, // ✅ AJOUT : Déterminer si en promotion flash
        isNew: true, // ✅ AJOUT : Par défaut, un produit est nouveau à sa création
      );

      await productRef.set(productModel.toMap());

      debugPrint('✅ Produit créé: $productId');
      return productId;
    } catch (e) {
      debugPrint('❌ Erreur création produit: $e');
      rethrow;
    }
  }

  /// Mettre à jour un produit
  Future<void> updateProduct(
    String productId,
    Map<String, dynamic> updates,
  ) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();

      await _db
          .collection(FirebaseCollections.products)
          .doc(productId)
          .update(updates);

      debugPrint('✅ Produit mis à jour: $productId');
    } catch (e) {
      debugPrint('❌ Erreur mise à jour produit: $e');
      rethrow;
    }
  }

  /// Mettre à jour le stock
  Future<void> updateStock(String productId, int newStock) async {
    try {
      await _db
          .collection(FirebaseCollections.products)
          .doc(productId)
          .update({
        'stock': newStock,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Stock mis à jour: $productId → $newStock');
    } catch (e) {
      debugPrint('❌ Erreur mise à jour stock: $e');
      rethrow;
    }
  }

  /// Mettre à jour un produit avec upload de nouvelles images
  /// Combine les images existantes avec les nouvelles images uploadées
  Future<void> updateProductWithImages({
    required String productId,
    required Map<String, dynamic> updates,
    List<String>? existingImageUrls,
    List<File>? newImages,
  }) async {
    try {
      debugPrint('🔄 Mise à jour produit avec images: $productId');

      // Combiner images existantes et nouvelles
      List<String> allImageUrls = [];

      // Ajouter les images existantes (URLs Firebase Storage valides)
      if (existingImageUrls != null) {
        for (var url in existingImageUrls) {
          // Garder seulement les URLs Firebase Storage valides
          if (url.contains('firebasestorage.googleapis.com') ||
              url.contains('https://') ||
              url.contains('http://')) {
            allImageUrls.add(url);
          } else {
            debugPrint('⚠️ URL invalide ignorée: $url');
          }
        }
      }

      // Uploader les nouvelles images
      if (newImages != null && newImages.isNotEmpty) {
        debugPrint('📤 Upload de ${newImages.length} nouvelle(s) image(s)...');

        // Commencer l'index après les images existantes
        int startIndex = allImageUrls.length;

        for (int i = 0; i < newImages.length; i++) {
          final imageUrl = await _uploadImage(
            productId,
            newImages[i],
            startIndex + i,
          );

          if (imageUrl != null) {
            allImageUrls.add(imageUrl);
          } else {
            debugPrint('⚠️ Échec upload image ${i + 1}');
          }
        }
      }

      // Mettre à jour avec toutes les images
      final updatesWithImages = Map<String, dynamic>.from(updates);
      updatesWithImages['images'] = allImageUrls;
      updatesWithImages['updatedAt'] = FieldValue.serverTimestamp();

      await _db
          .collection(FirebaseCollections.products)
          .doc(productId)
          .update(updatesWithImages);

      debugPrint('✅ Produit mis à jour avec ${allImageUrls.length} image(s)');
    } catch (e) {
      debugPrint('❌ Erreur mise à jour produit avec images: $e');
      rethrow;
    }
  }

  /// Supprimer un produit
  Future<void> deleteProduct(String productId) async {
    try {
      // Supprimer les images
      await _deleteProductImages(productId);

      // Supprimer le document
      await _db
          .collection(FirebaseCollections.products)
          .doc(productId)
          .delete();

      debugPrint('✅ Produit supprimé: $productId');
    } catch (e) {
      debugPrint('❌ Erreur suppression produit: $e');
      rethrow;
    }
  }

  // ===== GESTION DES IMAGES =====

  /// Upload d'une image
  Future<String?> _uploadImage(
    String productId,
    File imageFile,
    int index,
  ) async {
    try {
      final fileName = 'products/$productId/image_$index.jpg';
      final ref = _storage.ref().child(fileName);

      await ref.putFile(imageFile);
      final url = await ref.getDownloadURL();

      debugPrint('✅ Image uploadée: $url');
      return url;
    } catch (e) {
      debugPrint('❌ Erreur upload image: $e');
      return null;
    }
  }

  /// Supprimer les images d'un produit
  Future<void> _deleteProductImages(String productId) async {
    try {
      final ref = _storage.ref().child('products/$productId');
      final listResult = await ref.listAll();

      for (var item in listResult.items) {
        await item.delete();
      }

      debugPrint('✅ Images supprimées pour produit: $productId');
    } catch (e) {
      debugPrint('⚠️ Erreur suppression images: $e');
    }
  }

  // ===== STATISTIQUES =====

  /// Obtenir les statistiques des produits d'un vendeur
  Future<ProductStats> getVendorProductStats(String vendeurId) async {
    try {
      final products = await getVendorProducts(vendeurId);

      final totalProducts = products.length;
      final activeProducts = products.where((p) => p.isActive).length;
      final featuredProducts = products.where((p) => p.isFeatured).length;
      final outOfStock = products.where((p) => p.stock == 0).length;
      final lowStock = products.where((p) => p.stock > 0 && p.stock <= 5).length;
      final totalValue = products.fold<double>(
        0,
        (sum, p) => sum + (p.price * p.stock),
      );

      return ProductStats(
        totalProducts: totalProducts,
        activeProducts: activeProducts,
        featuredProducts: featuredProducts,
        outOfStock: outOfStock,
        lowStock: lowStock,
        totalValue: totalValue,
      );
    } catch (e) {
      debugPrint('❌ Erreur stats produits: $e');
      return ProductStats(
        totalProducts: 0,
        activeProducts: 0,
        featuredProducts: 0,
        outOfStock: 0,
        lowStock: 0,
        totalValue: 0,
      );
    }
  }

  /// Obtenir les produits populaires
  Future<List<ProductModel>> getPopularProducts({int limit = 10}) async {
    try {
      // TODO: Implémenter tri par popularité (vues, ventes)
      // Pour l'instant, on retourne les produits featured
      final snapshot = await _db
          .collection(FirebaseCollections.products)
          .where('isActive', isEqualTo: true)
          .where('isFeatured', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('❌ Erreur produits populaires: $e');
      return [];
    }
  }

  /// Obtenir les nouveaux produits
  Future<List<ProductModel>> getNewProducts({int limit = 10}) async {
    try {
      final snapshot = await _db
          .collection(FirebaseCollections.products)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('❌ Erreur nouveaux produits: $e');
      return [];
    }
  }

  /// Obtenir les produits en promotion
  Future<List<ProductModel>> getPromotionalProducts({int limit = 10}) async {
    try {
      final snapshot = await _db
          .collection(FirebaseCollections.products)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();

      // Filtrer localement les produits avec originalPrice
      final products = snapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data()))
          .where((p) => p.originalPrice != null && p.originalPrice! > p.price)
          .take(limit)
          .toList();

      return products;
    } catch (e) {
      debugPrint('❌ Erreur produits en promo: $e');
      return [];
    }
  }

  // ===== FAVORIS (OPTIONNEL) =====

  /// Ajouter aux favoris
  Future<void> addToFavorites(String userId, String productId) async {
    try {
      await _db
          .collection(FirebaseCollections.users)
          .doc(userId)
          .update({
        'favorites': FieldValue.arrayUnion([productId]),
      });

      debugPrint('✅ Produit ajouté aux favoris: $productId');
    } catch (e) {
      debugPrint('❌ Erreur ajout favoris: $e');
      rethrow;
    }
  }

  /// Retirer des favoris
  Future<void> removeFromFavorites(String userId, String productId) async {
    try {
      await _db
          .collection(FirebaseCollections.users)
          .doc(userId)
          .update({
        'favorites': FieldValue.arrayRemove([productId]),
      });

      debugPrint('✅ Produit retiré des favoris: $productId');
    } catch (e) {
      debugPrint('❌ Erreur retrait favoris: $e');
      rethrow;
    }
  }

  /// Obtenir les produits favoris d'un utilisateur
  Future<List<ProductModel>> getFavoriteProducts(String userId) async {
    try {
      final userDoc = await _db
          .collection(FirebaseCollections.users)
          .doc(userId)
          .get();

      if (!userDoc.exists) return [];

      final favorites = List<String>.from(userDoc.data()?['favorites'] ?? []);

      if (favorites.isEmpty) return [];

      final products = <ProductModel>[];
      for (var productId in favorites) {
        final product = await getProduct(productId);
        if (product != null) {
          products.add(product);
        }
      }

      return products;
    } catch (e) {
      debugPrint('❌ Erreur produits favoris: $e');
      return [];
    }
  }
}

/// Données pour créer un produit
class CreateProductData {
  final String name;
  final String description;
  final double price;
  final double? originalPrice;
  final String category;
  final String? subCategory;
  final String? brand;
  final List<File> images;
  final int stock;
  final String? sku;
  final List<String> tags;
  final bool isActive;
  final bool? isFeatured;
  final String vendeurId;
  final String vendeurName;
  final Map<String, String>? specifications;

  CreateProductData({
    required this.name,
    required this.description,
    required this.price,
    this.originalPrice,
    required this.category,
    this.subCategory,
    this.brand,
    required this.images,
    required this.stock,
    this.sku,
    this.tags = const [],
    this.isActive = true,
    this.isFeatured,
    required this.vendeurId,
    required this.vendeurName,
    this.specifications,
  });
}

/// Statistiques des produits
class ProductStats {
  final int totalProducts;
  final int activeProducts;
  final int featuredProducts;
  final int outOfStock;
  final int lowStock;
  final double totalValue;

  ProductStats({
    required this.totalProducts,
    required this.activeProducts,
    required this.featuredProducts,
    required this.outOfStock,
    required this.lowStock,
    required this.totalValue,
  });
}