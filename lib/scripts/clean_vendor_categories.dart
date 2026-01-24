// ===== lib/scripts/clean_vendor_categories.dart =====
// Script de nettoyage des catégories vendeur
// À exécuter via une fonction admin ou debug screen

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Catégories valides actuelles
const List<String> validCategories = [
  'Mode & Style',
  'Électronique',
  'Électroménager',
  'Cuisine & Ustensiles',
  'Meubles & Déco',
  'Alimentaire',
  'Maison & Jardin',
  'Beauté & Soins',
  'Sport & Loisirs',
  'Auto & Moto',
  'Services',
];

/// Nettoie les catégories d'un vendeur
Future<Map<String, dynamic>> cleanVendorCategories(String userId) async {
  final firestore = FirebaseFirestore.instance;

  try {
    debugPrint('🔍 Vérification du profil vendeur pour: $userId');

    // Récupérer le document utilisateur
    final userDoc = await firestore.collection('users').doc(userId).get();

    if (!userDoc.exists) {
      throw Exception('Utilisateur non trouvé');
    }

    final userData = userDoc.data()!;
    final profile = userData['profile'] as Map<String, dynamic>?;
    final vendeurProfile = profile?['vendeurProfile'] as Map<String, dynamic>?;

    if (vendeurProfile == null) {
      throw Exception('Pas de profil vendeur trouvé');
    }

    // Récupérer les catégories actuelles
    final dynamic categoriesData = vendeurProfile['businessCategories'];
    List<String> currentCategories = [];

    if (categoriesData is List) {
      currentCategories = categoriesData.map((e) => e.toString()).toList();
    } else if (categoriesData is String) {
      currentCategories = [categoriesData];
    }

    debugPrint('📋 Catégories actuelles: $currentCategories');

    // Identifier les catégories invalides
    final invalidCategories = currentCategories
        .where((cat) => !validCategories.contains(cat))
        .toList();

    final validCurrentCategories = currentCategories
        .where((cat) => validCategories.contains(cat))
        .toList();

    if (invalidCategories.isEmpty) {
      debugPrint('✅ Toutes les catégories sont valides');
      return {
        'success': true,
        'cleaned': false,
        'message': 'Toutes les catégories sont valides',
        'categories': currentCategories,
      };
    }

    debugPrint('⚠️  Catégories invalides: $invalidCategories');
    debugPrint('✅ Catégories valides: $validCurrentCategories');

    // Si aucune catégorie valide, utiliser 'Alimentaire' par défaut
    final cleanedCategories = validCurrentCategories.isNotEmpty
        ? validCurrentCategories
        : ['Alimentaire'];

    debugPrint('🧹 Nettoyage vers: $cleanedCategories');

    // Mettre à jour Firestore
    await firestore.collection('users').doc(userId).update({
      'profile.vendeurProfile.businessCategories': cleanedCategories,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    debugPrint('✅ Catégories nettoyées avec succès');

    return {
      'success': true,
      'cleaned': true,
      'message': 'Catégories nettoyées avec succès',
      'invalidCategories': invalidCategories,
      'oldCategories': currentCategories,
      'newCategories': cleanedCategories,
    };
  } catch (e) {
    debugPrint('❌ Erreur lors du nettoyage: $e');
    return {
      'success': false,
      'error': e.toString(),
    };
  }
}

/// Affiche toutes les catégories disponibles
void printAvailableCategories() {
  debugPrint('📊 Catégories valides disponibles:');
  for (var i = 0; i < validCategories.length; i++) {
    debugPrint('   ${i + 1}. ${validCategories[i]}');
  }
}

/// Vérifie tous les vendeurs et liste ceux avec des catégories invalides
Future<List<Map<String, dynamic>>> checkAllVendorsCategories() async {
  final firestore = FirebaseFirestore.instance;
  final problematicVendors = <Map<String, dynamic>>[];

  try {
    debugPrint('🔍 Vérification de tous les vendeurs...');

    final usersSnapshot = await firestore
        .collection('users')
        .where('userType', isEqualTo: 'vendeur')
        .get();

    debugPrint('📊 Nombre de vendeurs trouvés: ${usersSnapshot.docs.length}');

    for (final doc in usersSnapshot.docs) {
      final userData = doc.data();
      final profile = userData['profile'] as Map<String, dynamic>?;
      final vendeurProfile = profile?['vendeurProfile'] as Map<String, dynamic>?;

      if (vendeurProfile != null) {
        final dynamic categoriesData = vendeurProfile['businessCategories'];
        List<String> categories = [];

        if (categoriesData is List) {
          categories = categoriesData.map((e) => e.toString()).toList();
        } else if (categoriesData is String) {
          categories = [categoriesData];
        }

        final invalidCategories = categories
            .where((cat) => !validCategories.contains(cat))
            .toList();

        if (invalidCategories.isNotEmpty) {
          problematicVendors.add({
            'userId': doc.id,
            'email': userData['email'],
            'businessName': vendeurProfile['businessName'],
            'currentCategories': categories,
            'invalidCategories': invalidCategories,
          });
        }
      }
    }

    if (problematicVendors.isEmpty) {
      debugPrint('✅ Aucun vendeur avec des catégories invalides');
    } else {
      debugPrint('⚠️  ${problematicVendors.length} vendeur(s) avec catégories invalides:');
      for (final vendor in problematicVendors) {
        debugPrint('   - ${vendor['businessName']} (${vendor['email']})');
        debugPrint('     Invalides: ${vendor['invalidCategories']}');
      }
    }

    return problematicVendors;
  } catch (e) {
    debugPrint('❌ Erreur lors de la vérification: $e');
    return [];
  }
}
