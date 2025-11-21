// ===== lib/services/stock_management_service.dart =====
// Service de gestion du stock des produits - SOCIAL BUSINESS Pro

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../config/constants.dart';

class StockManagementService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Réserver du stock lors de la création d'une commande
  /// Retourne true si la réservation a réussi, false sinon
  static Future<bool> reserveStock({
    required String productId,
    required int quantity,
  }) async {
    try {
      debugPrint('📦 Réservation stock: $productId (quantité: $quantity)');

      return await _firestore.runTransaction((transaction) async {
        final productRef = _firestore
            .collection(FirebaseCollections.products)
            .doc(productId);

        final productDoc = await transaction.get(productRef);

        if (!productDoc.exists) {
          debugPrint('❌ Produit $productId non trouvé');
          return false;
        }

        final productData = productDoc.data()!;
        final currentStock = productData['stock'] as int? ?? 0;
        final currentReserved = productData['reservedStock'] as int? ?? 0;
        final availableStock = currentStock - currentReserved;

        // Vérifier si stock disponible suffisant
        if (availableStock < quantity) {
          debugPrint('❌ Stock insuffisant: disponible=$availableStock, demandé=$quantity');
          return false;
        }

        // Réserver le stock
        transaction.update(productRef, {
          'reservedStock': currentReserved + quantity,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        debugPrint('✅ Stock réservé: $quantity unités (nouveau reservedStock: ${currentReserved + quantity})');
        return true;
      });
    } catch (e) {
      debugPrint('❌ Erreur réservation stock: $e');
      return false;
    }
  }

  /// Réserver du stock pour plusieurs produits (batch)
  static Future<bool> reserveStockBatch({
    required Map<String, int> productsQuantities,
  }) async {
    try {
      debugPrint('📦 Réservation stock batch: ${productsQuantities.length} produits');

      return await _firestore.runTransaction((transaction) async {
        // 1. Récupérer tous les produits et vérifier le stock
        final productRefs = <DocumentReference>[];
        final productDocs = <DocumentSnapshot>[];

        for (final productId in productsQuantities.keys) {
          final ref = _firestore.collection(FirebaseCollections.products).doc(productId);
          productRefs.add(ref);
          final doc = await transaction.get(ref);
          productDocs.add(doc);
        }

        // 2. Vérifier que tous les produits ont du stock suffisant
        for (int i = 0; i < productDocs.length; i++) {
          final doc = productDocs[i];
          final productId = productsQuantities.keys.elementAt(i);
          final quantity = productsQuantities[productId]!;

          if (!doc.exists) {
            debugPrint('❌ Produit $productId non trouvé');
            return false;
          }

          final data = doc.data() as Map<String, dynamic>;
          final currentStock = data['stock'] as int? ?? 0;
          final currentReserved = data['reservedStock'] as int? ?? 0;
          final availableStock = currentStock - currentReserved;

          if (availableStock < quantity) {
            debugPrint('❌ Stock insuffisant pour $productId: disponible=$availableStock, demandé=$quantity');
            return false;
          }
        }

        // 3. Réserver le stock pour tous les produits
        for (int i = 0; i < productRefs.length; i++) {
          final ref = productRefs[i];
          final doc = productDocs[i];
          final productId = productsQuantities.keys.elementAt(i);
          final quantity = productsQuantities[productId]!;

          final data = doc.data() as Map<String, dynamic>;
          final currentReserved = data['reservedStock'] as int? ?? 0;

          transaction.update(ref, {
            'reservedStock': currentReserved + quantity,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        debugPrint('✅ Stock réservé pour ${productsQuantities.length} produits');
        return true;
      });
    } catch (e) {
      debugPrint('❌ Erreur réservation stock batch: $e');
      return false;
    }
  }

  /// Libérer du stock réservé (lors annulation ou expiration)
  static Future<void> releaseStock({
    required String productId,
    required int quantity,
  }) async {
    try {
      debugPrint('📤 Libération stock: $productId (quantité: $quantity)');

      await _firestore.runTransaction((transaction) async {
        final productRef = _firestore
            .collection(FirebaseCollections.products)
            .doc(productId);

        final productDoc = await transaction.get(productRef);

        if (!productDoc.exists) {
          debugPrint('⚠️ Produit $productId non trouvé');
          return;
        }

        final productData = productDoc.data()!;
        final currentReserved = productData['reservedStock'] as int? ?? 0;
        final newReserved = (currentReserved - quantity).clamp(0, currentReserved);

        transaction.update(productRef, {
          'reservedStock': newReserved,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        debugPrint('✅ Stock libéré: $quantity unités (nouveau reservedStock: $newReserved)');
      });
    } catch (e) {
      debugPrint('❌ Erreur libération stock: $e');
    }
  }

  /// Libérer du stock pour plusieurs produits (batch)
  static Future<void> releaseStockBatch({
    required Map<String, int> productsQuantities,
  }) async {
    try {
      debugPrint('📤 Libération stock batch: ${productsQuantities.length} produits');

      await _firestore.runTransaction((transaction) async {
        for (final entry in productsQuantities.entries) {
          final productId = entry.key;
          final quantity = entry.value;

          final productRef = _firestore
              .collection(FirebaseCollections.products)
              .doc(productId);

          final productDoc = await transaction.get(productRef);

          if (productDoc.exists) {
            final productData = productDoc.data()!;
            final currentReserved = productData['reservedStock'] as int? ?? 0;
            final newReserved = (currentReserved - quantity).clamp(0, currentReserved);

            transaction.update(productRef, {
              'reservedStock': newReserved,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }
      });

      debugPrint('✅ Stock libéré pour ${productsQuantities.length} produits');
    } catch (e) {
      debugPrint('❌ Erreur libération stock batch: $e');
    }
  }

  /// Déduire définitivement du stock (lors de la livraison)
  static Future<void> deductStock({
    required String productId,
    required int quantity,
  }) async {
    try {
      debugPrint('➖ Déduction stock: $productId (quantité: $quantity)');

      await _firestore.runTransaction((transaction) async {
        final productRef = _firestore
            .collection(FirebaseCollections.products)
            .doc(productId);

        final productDoc = await transaction.get(productRef);

        if (!productDoc.exists) {
          debugPrint('⚠️ Produit $productId non trouvé');
          return;
        }

        final productData = productDoc.data()!;
        final currentStock = productData['stock'] as int? ?? 0;
        final currentReserved = productData['reservedStock'] as int? ?? 0;

        // Déduire du stock total et libérer la réservation
        final newStock = (currentStock - quantity).clamp(0, currentStock);
        final newReserved = (currentReserved - quantity).clamp(0, currentReserved);

        transaction.update(productRef, {
          'stock': newStock,
          'reservedStock': newReserved,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        debugPrint('✅ Stock déduit: $quantity unités (nouveau stock: $newStock, reservedStock: $newReserved)');
      });
    } catch (e) {
      debugPrint('❌ Erreur déduction stock: $e');
    }
  }

  /// Déduire du stock pour plusieurs produits (batch)
  static Future<void> deductStockBatch({
    required Map<String, int> productsQuantities,
  }) async {
    try {
      debugPrint('➖ Déduction stock batch: ${productsQuantities.length} produits');

      await _firestore.runTransaction((transaction) async {
        for (final entry in productsQuantities.entries) {
          final productId = entry.key;
          final quantity = entry.value;

          final productRef = _firestore
              .collection(FirebaseCollections.products)
              .doc(productId);

          final productDoc = await transaction.get(productRef);

          if (productDoc.exists) {
            final productData = productDoc.data()!;
            final currentStock = productData['stock'] as int? ?? 0;
            final currentReserved = productData['reservedStock'] as int? ?? 0;

            final newStock = (currentStock - quantity).clamp(0, currentStock);
            final newReserved = (currentReserved - quantity).clamp(0, currentReserved);

            transaction.update(productRef, {
              'stock': newStock,
              'reservedStock': newReserved,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }
      });

      debugPrint('✅ Stock déduit pour ${productsQuantities.length} produits');
    } catch (e) {
      debugPrint('❌ Erreur déduction stock batch: $e');
    }
  }

  /// Vérifier si le stock est disponible pour une commande
  static Future<bool> checkStockAvailability({
    required String productId,
    required int quantity,
  }) async {
    try {
      final productDoc = await _firestore
          .collection(FirebaseCollections.products)
          .doc(productId)
          .get();

      if (!productDoc.exists) {
        return false;
      }

      final data = productDoc.data()!;
      final currentStock = data['stock'] as int? ?? 0;
      final currentReserved = data['reservedStock'] as int? ?? 0;
      final availableStock = currentStock - currentReserved;

      return availableStock >= quantity;
    } catch (e) {
      debugPrint('❌ Erreur vérification stock: $e');
      return false;
    }
  }
}
