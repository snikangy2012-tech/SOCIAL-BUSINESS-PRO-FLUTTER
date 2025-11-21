// ===== lib/utils/test_data_helper.dart =====
// Helper pour créer des données de test - SOCIAL BUSINESS Pro

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../config/constants.dart';

class TestDataHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Créer des commandes de test "ready" pour tester le système de livraison
  static Future<void> createTestOrders({
    required String vendeurId,
    required String buyerId,
    int count = 3,
  }) async {
    try {
      debugPrint('🧪 === Création de $count commandes de test ===');

      // Coordonnées de test autour d'Abidjan
      final List<Map<String, dynamic>> testLocations = [
        {
          'name': 'Cocody',
          'pickupLat': 5.3599517,
          'pickupLng': -3.9864074,
          'deliveryLat': 5.3699517,
          'deliveryLng': -3.9764074,
          'address': 'Cocody, Abidjan',
        },
        {
          'name': 'Plateau',
          'pickupLat': 5.3199,
          'pickupLng': -4.0267,
          'deliveryLat': 5.3299,
          'deliveryLng': -4.0167,
          'address': 'Plateau, Abidjan',
        },
        {
          'name': 'Yopougon',
          'pickupLat': 5.3396,
          'pickupLng': -4.0856,
          'deliveryLat': 5.3496,
          'deliveryLng': -4.0756,
          'address': 'Yopougon, Abidjan',
        },
        {
          'name': 'Adjamé',
          'pickupLat': 5.3506,
          'pickupLng': -4.0242,
          'deliveryLat': 5.3606,
          'deliveryLng': -4.0142,
          'address': 'Adjamé, Abidjan',
        },
        {
          'name': 'Marcory',
          'pickupLat': 5.2844,
          'pickupLng': -3.9969,
          'deliveryLat': 5.2944,
          'deliveryLng': -3.9869,
          'address': 'Marcory, Abidjan',
        },
      ];

      for (int i = 0; i < count; i++) {
        final location = testLocations[i % testLocations.length];
        final orderNumber = 'TEST-${DateTime.now().millisecondsSinceEpoch}-$i';

        final orderData = {
          'orderNumber': orderNumber,
          'displayNumber': '#${1000 + i}',
          'vendeurId': vendeurId,
          'buyerId': buyerId,
          'buyerName': 'Client Test ${i + 1}',
          'buyerPhone': '+225 07 ${i}0 00 00 00',
          'items': [
            {
              'productId': 'test-product-1',
              'productName': 'Produit Test ${i + 1}',
              'quantity': 2,
              'price': 5000.0,
              'total': 10000.0,
            },
          ],
          'totalAmount': 10000.0,
          'status': 'ready', // Commande prête pour livraison
          'deliveryAddress': location['address'],
          'notes': 'Commande de test créée automatiquement',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),

          // Coordonnées GPS pour la livraison
          'pickupLatitude': location['pickupLat'],
          'pickupLongitude': location['pickupLng'],
          'deliveryLatitude': location['deliveryLat'],
          'deliveryLongitude': location['deliveryLng'],

          // Pas de livreur assigné
          'livreurId': null,
        };

        await _firestore
            .collection(FirebaseCollections.orders)
            .add(orderData);

        debugPrint('✅ Commande test créée: $orderNumber (${location['name']})');
      }

      debugPrint('✅ === $count commandes de test créées avec succès ===');
    } catch (e) {
      debugPrint('❌ Erreur création commandes de test: $e');
      throw Exception('Impossible de créer les commandes de test: $e');
    }
  }

  /// Supprimer toutes les commandes de test
  static Future<void> deleteTestOrders() async {
    try {
      debugPrint('🧹 Suppression des commandes de test...');

      final querySnapshot = await _firestore
          .collection(FirebaseCollections.orders)
          .where('orderNumber', isGreaterThanOrEqualTo: 'TEST-')
          .where('orderNumber', isLessThanOrEqualTo: 'TEST-\uf8ff')
          .get();

      int count = 0;
      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
        count++;
      }

      debugPrint('✅ $count commandes de test supprimées');
    } catch (e) {
      debugPrint('❌ Erreur suppression commandes de test: $e');
    }
  }

  /// Créer un utilisateur livreur de test
  static Future<String> createTestLivreur() async {
    try {
      debugPrint('🧪 Création livreur de test...');

      final livreurData = {
        'email': 'livreur.test@socialbusiness.ci',
        'displayName': 'Livreur Test',
        'phoneNumber': '+225 07 99 99 99 99',
        'userType': 'livreur',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'profile': {
          'vehicleType': 'moto',
          'vehicleNumber': 'AB-1234-CI',
          'isAvailable': true,
          'currentLocation': {
            'latitude': 5.3599517,
            'longitude': -3.9864074,
          },
        },
      };

      final docRef = await _firestore
          .collection(FirebaseCollections.users)
          .add(livreurData);

      debugPrint('✅ Livreur test créé: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Erreur création livreur de test: $e');
      throw Exception('Impossible de créer le livreur de test: $e');
    }
  }

  /// Obtenir un vendeur existant (le premier trouvé)
  static Future<String?> getFirstVendeurId() async {
    try {
      final querySnapshot = await _firestore
          .collection(FirebaseCollections.users)
          .where('userType', isEqualTo: 'vendeur')
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        debugPrint('⚠️ Aucun vendeur trouvé');
        return null;
      }

      return querySnapshot.docs.first.id;
    } catch (e) {
      debugPrint('❌ Erreur récupération vendeur: $e');
      return null;
    }
  }

  /// Obtenir un acheteur existant (le premier trouvé)
  static Future<String?> getFirstBuyerId() async {
    try {
      final querySnapshot = await _firestore
          .collection(FirebaseCollections.users)
          .where('userType', isEqualTo: 'acheteur')
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        debugPrint('⚠️ Aucun acheteur trouvé');
        return null;
      }

      return querySnapshot.docs.first.id;
    } catch (e) {
      debugPrint('❌ Erreur récupération acheteur: $e');
      return null;
    }
  }
}
