// ===== lib/services/category_service.dart =====
// Service de gestion des catégories de produits

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../config/constants.dart';

class CategoryService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'product_categories';

  /// Récupérer toutes les catégories actives (triées par displayOrder)
  static Future<List<CategoryModel>> getActiveCategories() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .orderBy('displayOrder')
          .orderBy('name')
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              debugPrint('⚠️ Timeout lors du chargement des catégories');
              throw Exception('Timeout: Impossible de charger les catégories');
            },
          );

      return querySnapshot.docs
          .map((doc) => CategoryModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('❌ Erreur lors du chargement des catégories: $e');
      rethrow;
    }
  }

  /// Récupérer toutes les catégories (actives et inactives)
  static Future<List<CategoryModel>> getAllCategories() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('displayOrder')
          .orderBy('name')
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              debugPrint('⚠️ Timeout lors du chargement des catégories');
              throw Exception('Timeout: Impossible de charger les catégories');
            },
          );

      return querySnapshot.docs
          .map((doc) => CategoryModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('❌ Erreur lors du chargement des catégories: $e');
      rethrow;
    }
  }

  /// Récupérer une catégorie par son ID
  static Future<CategoryModel?> getCategoryById(String id) async {
    try {
      final doc = await _firestore
          .collection(_collection)
          .doc(id)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              debugPrint('⚠️ Timeout lors du chargement de la catégorie $id');
              throw Exception('Timeout: Impossible de charger la catégorie');
            },
          );

      if (!doc.exists) return null;

      return CategoryModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('❌ Erreur lors du chargement de la catégorie $id: $e');
      rethrow;
    }
  }

  /// Créer une nouvelle catégorie
  static Future<String> createCategory({
    required String name,
    required IconData icon,
    List<String> subCategories = const [],
    int displayOrder = 0,
  }) async {
    try {
      final iconData = IconHelper.iconDataToMap(icon);

      final docRef = await _firestore.collection(_collection).add({
        'name': name,
        'iconCodePoint': iconData['iconCodePoint'],
        'iconFontFamily': iconData['iconFontFamily'],
        'subCategories': subCategories,
        'isActive': true,
        'displayOrder': displayOrder,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': null,
      });

      debugPrint('✅ Catégorie créée: $name (${docRef.id})');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Erreur lors de la création de la catégorie: $e');
      rethrow;
    }
  }

  /// Mettre à jour une catégorie
  static Future<void> updateCategory({
    required String id,
    String? name,
    IconData? icon,
    List<String>? subCategories,
    bool? isActive,
    int? displayOrder,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updateData['name'] = name;
      if (subCategories != null) updateData['subCategories'] = subCategories;
      if (isActive != null) updateData['isActive'] = isActive;
      if (displayOrder != null) updateData['displayOrder'] = displayOrder;

      if (icon != null) {
        final iconData = IconHelper.iconDataToMap(icon);
        updateData['iconCodePoint'] = iconData['iconCodePoint'];
        updateData['iconFontFamily'] = iconData['iconFontFamily'];
      }

      await _firestore.collection(_collection).doc(id).update(updateData);

      debugPrint('✅ Catégorie mise à jour: $id');
    } catch (e) {
      debugPrint('❌ Erreur lors de la mise à jour de la catégorie $id: $e');
      rethrow;
    }
  }

  /// Supprimer une catégorie (soft delete - désactivation)
  static Future<void> deleteCategory(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Catégorie désactivée: $id');
    } catch (e) {
      debugPrint('❌ Erreur lors de la suppression de la catégorie $id: $e');
      rethrow;
    }
  }

  /// Supprimer définitivement une catégorie (hard delete)
  static Future<void> hardDeleteCategory(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();

      debugPrint('✅ Catégorie supprimée définitivement: $id');
    } catch (e) {
      debugPrint('❌ Erreur lors de la suppression définitive de la catégorie $id: $e');
      rethrow;
    }
  }

  /// Ajouter une sous-catégorie à une catégorie existante
  static Future<void> addSubCategory(String categoryId, String subCategoryName) async {
    try {
      final category = await getCategoryById(categoryId);
      if (category == null) {
        throw Exception('Catégorie non trouvée');
      }

      if (category.subCategories.contains(subCategoryName)) {
        throw Exception('Cette sous-catégorie existe déjà');
      }

      final updatedSubCategories = [...category.subCategories, subCategoryName];

      await updateCategory(
        id: categoryId,
        subCategories: updatedSubCategories,
      );

      debugPrint('✅ Sous-catégorie ajoutée: $subCategoryName à $categoryId');
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'ajout de la sous-catégorie: $e');
      rethrow;
    }
  }

  /// Supprimer une sous-catégorie
  static Future<void> removeSubCategory(String categoryId, String subCategoryName) async {
    try {
      final category = await getCategoryById(categoryId);
      if (category == null) {
        throw Exception('Catégorie non trouvée');
      }

      final updatedSubCategories = category.subCategories
          .where((sub) => sub != subCategoryName)
          .toList();

      await updateCategory(
        id: categoryId,
        subCategories: updatedSubCategories,
      );

      debugPrint('✅ Sous-catégorie supprimée: $subCategoryName de $categoryId');
    } catch (e) {
      debugPrint('❌ Erreur lors de la suppression de la sous-catégorie: $e');
      rethrow;
    }
  }

  /// Stream pour écouter les changements de catégories actives
  static Stream<List<CategoryModel>> watchActiveCategories() {
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('displayOrder')
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CategoryModel.fromFirestore(doc))
            .toList());
  }

  /// Stream pour écouter toutes les catégories
  static Stream<List<CategoryModel>> watchAllCategories() {
    return _firestore
        .collection(_collection)
        .orderBy('displayOrder')
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CategoryModel.fromFirestore(doc))
            .toList());
  }

  /// Réorganiser l'ordre d'affichage des catégories
  static Future<void> reorderCategories(List<CategoryModel> categories) async {
    try {
      final batch = _firestore.batch();

      for (int i = 0; i < categories.length; i++) {
        final docRef = _firestore.collection(_collection).doc(categories[i].id);
        batch.update(docRef, {
          'displayOrder': i,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      debugPrint('✅ Ordre des catégories mis à jour');
    } catch (e) {
      debugPrint('❌ Erreur lors de la réorganisation des catégories: $e');
      rethrow;
    }
  }

  /// Vérifier si une catégorie est utilisée par des produits
  static Future<int> countProductsInCategory(String categoryId) async {
    try {
      final querySnapshot = await _firestore
          .collection(FirebaseCollections.products)
          .where('category', isEqualTo: categoryId)
          .count()
          .get();

      return querySnapshot.count ?? 0;
    } catch (e) {
      debugPrint('❌ Erreur lors du comptage des produits: $e');
      return 0;
    }
  }
}
