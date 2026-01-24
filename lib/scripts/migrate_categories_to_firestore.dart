// ===== lib/scripts/migrate_categories_to_firestore.dart =====
// Script de migration des catégories vers Firestore

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../config/product_categories.dart';
import '../models/category_model.dart';

/// Script pour migrer les catégories codées en dur vers Firestore
///
/// UTILISATION:
/// - Depuis l'écran admin de gestion des catégories
/// - Ou via un bouton "Migrer les catégories" dans les paramètres admin
///
/// ATTENTION: Ce script ne doit être exécuté qu'une seule fois
class CategoryMigrationScript {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'product_categories';

  /// Vérifier si des catégories existent déjà dans Firestore
  static Future<bool> categoriesExist() async {
    try {
      final snapshot = await _firestore.collection(_collection).limit(1).get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('❌ Erreur vérification catégories: $e');
      return false;
    }
  }

  /// Compter le nombre de catégories dans Firestore
  static Future<int> countCategories() async {
    try {
      final snapshot = await _firestore.collection(_collection).count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('❌ Erreur comptage catégories: $e');
      return 0;
    }
  }

  /// Migrer toutes les catégories de product_categories.dart vers Firestore
  static Future<void> migrateCategories({bool force = false}) async {
    try {
      debugPrint('🔄 Début de la migration des catégories...');

      // Vérifier si des catégories existent déjà
      if (!force) {
        final exists = await categoriesExist();
        if (exists) {
          debugPrint('⚠️  Des catégories existent déjà dans Firestore');
          debugPrint('ℹ️  Utilisez force=true pour écraser les catégories existantes');
          throw Exception('Des catégories existent déjà. Utilisez force=true pour écraser.');
        }
      }

      // Migrer chaque catégorie
      int successCount = 0;
      int errorCount = 0;

      for (int i = 0; i < ProductCategories.allCategories.length; i++) {
        final category = ProductCategories.allCategories[i];

        try {
          debugPrint('📝 Migration de: ${category.name}...');

          final iconData = IconHelper.iconDataToMap(category.icon);

          await _firestore.collection(_collection).doc(category.id).set({
            'name': category.name,
            'iconCodePoint': iconData['iconCodePoint'],
            'iconFontFamily': iconData['iconFontFamily'],
            'subCategories': category.subCategories ?? [],
            'isActive': true,
            'displayOrder': i, // Conserver l'ordre actuel
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': null,
          });

          successCount++;
          debugPrint('   ✅ ${category.name} - ${category.subCategories?.length ?? 0} sous-catégories');
        } catch (e) {
          errorCount++;
          debugPrint('   ❌ Erreur pour ${category.name}: $e');
        }
      }

      debugPrint('');
      debugPrint('=' * 50);
      debugPrint('📊 Résultat de la migration:');
      debugPrint('   ✅ Réussites: $successCount');
      debugPrint('   ❌ Échecs: $errorCount');
      debugPrint('   📝 Total: ${ProductCategories.allCategories.length}');
      debugPrint('=' * 50);

      if (errorCount == 0) {
        debugPrint('🎉 Migration terminée avec succès!');
      } else {
        debugPrint('⚠️  Migration terminée avec des erreurs');
      }
    } catch (e) {
      debugPrint('❌ Erreur lors de la migration: $e');
      rethrow;
    }
  }

  /// Supprimer toutes les catégories de Firestore (pour recommencer)
  static Future<void> deleteAllCategories() async {
    try {
      debugPrint('🗑️  Suppression de toutes les catégories...');

      final snapshot = await _firestore.collection(_collection).get();
      final batch = _firestore.batch();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      debugPrint('✅ ${snapshot.docs.length} catégories supprimées');
    } catch (e) {
      debugPrint('❌ Erreur lors de la suppression: $e');
      rethrow;
    }
  }

  /// Afficher un rapport sur les catégories
  static Future<void> showReport() async {
    try {
      debugPrint('');
      debugPrint('=' * 50);
      debugPrint('📊 RAPPORT DES CATÉGORIES');
      debugPrint('=' * 50);

      // Compter dans Firestore
      final firestoreCount = await countCategories();
      debugPrint('📦 Catégories dans Firestore: $firestoreCount');

      // Compter dans le code
      final codeCount = ProductCategories.allCategories.length;
      debugPrint('💻 Catégories dans le code: $codeCount');

      debugPrint('');

      if (firestoreCount == 0) {
        debugPrint('⚠️  Aucune catégorie dans Firestore');
        debugPrint('💡 Exécutez migrateCategories() pour migrer');
      } else if (firestoreCount < codeCount) {
        debugPrint('⚠️  Moins de catégories dans Firestore que dans le code');
        debugPrint('💡 Certaines catégories pourraient être manquantes');
      } else if (firestoreCount > codeCount) {
        debugPrint('ℹ️  Plus de catégories dans Firestore que dans le code');
        debugPrint('💡 Des catégories ont été ajoutées manuellement');
      } else {
        debugPrint('✅ Nombre de catégories identique');
      }

      debugPrint('');

      // Lister les catégories Firestore
      if (firestoreCount > 0) {
        final snapshot = await _firestore
            .collection(_collection)
            .orderBy('displayOrder')
            .get();

        debugPrint('📋 Catégories dans Firestore:');
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final subCategoriesCount = (data['subCategories'] as List?)?.length ?? 0;
          final isActive = data['isActive'] ?? true;
          final status = isActive ? '✅' : '❌';

          debugPrint('   $status ${data['name']} ($subCategoriesCount sous-catégories)');
        }
      }

      debugPrint('=' * 50);
      debugPrint('');
    } catch (e) {
      debugPrint('❌ Erreur lors de la génération du rapport: $e');
    }
  }

  /// Fonction helper pour tester la migration
  static Future<void> testMigration() async {
    debugPrint('🧪 Test de migration...');
    await showReport();
    debugPrint('');
    debugPrint('Pour migrer les catégories, exécutez:');
    debugPrint('  await CategoryMigrationScript.migrateCategories();');
  }
}
