// ===== lib/utils/add_gps_to_orders.dart =====
// Utilitaire pour ajouter des coordonnées GPS aux commandes existantes

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../config/constants.dart';

class AddGpsToOrders {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Coordonnées par défaut pour Abidjan (Place de la République)
  static const double defaultPickupLat = 5.3167;
  static const double defaultPickupLng = -4.0333;
  static const double defaultDeliveryLat = 5.3467;
  static const double defaultDeliveryLng = -4.0083;

  /// Ajouter des coordonnées GPS par défaut aux commandes qui n'en ont pas
  static Future<void> addGpsToOrdersWithoutCoordinates() async {
    try {
      debugPrint('🔧 === Ajout de coordonnées GPS aux commandes ===');

      // Récupérer toutes les commandes
      final querySnapshot = await _firestore
          .collection(FirebaseCollections.orders)
          .get();

      debugPrint('📦 Total commandes trouvées: ${querySnapshot.docs.length}');

      int updatedCount = 0;
      int skippedCount = 0;

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final pickupLat = data['pickupLatitude'];
        final pickupLng = data['pickupLongitude'];
        final deliveryLat = data['deliveryLatitude'];
        final deliveryLng = data['deliveryLongitude'];

        // Vérifier si les coordonnées manquent
        final needsPickup = pickupLat == null || pickupLng == null;
        final needsDelivery = deliveryLat == null || deliveryLng == null;

        if (needsPickup || needsDelivery) {
          debugPrint('  ✏️ Mise à jour ${doc.id} - Pickup: $needsPickup, Delivery: $needsDelivery');

          final updateData = <String, dynamic>{};

          if (needsPickup) {
            // Ajouter des coordonnées de pickup par défaut
            // TODO: À l'avenir, géocoder l'adresse du vendeur
            updateData['pickupLatitude'] = defaultPickupLat + (updatedCount * 0.001); // Varier légèrement
            updateData['pickupLongitude'] = defaultPickupLng + (updatedCount * 0.001);
          }

          if (needsDelivery) {
            // Ajouter des coordonnées de livraison par défaut
            // TODO: À l'avenir, géocoder l'adresse de livraison
            updateData['deliveryLatitude'] = defaultDeliveryLat + (updatedCount * 0.001);
            updateData['deliveryLongitude'] = defaultDeliveryLng + (updatedCount * 0.001);
          }

          await _firestore
              .collection(FirebaseCollections.orders)
              .doc(doc.id)
              .update(updateData);

          updatedCount++;
        } else {
          skippedCount++;
        }
      }

      debugPrint('✅ Mise à jour terminée !');
      debugPrint('   - Commandes mises à jour: $updatedCount');
      debugPrint('   - Commandes ignorées (déjà avec GPS): $skippedCount');

    } catch (e) {
      debugPrint('❌ Erreur lors de l\'ajout de GPS: $e');
      rethrow;
    }
  }

  /// Ajouter des coordonnées GPS à une commande spécifique
  static Future<void> addGpsToOrder({
    required String orderId,
    double? pickupLat,
    double? pickupLng,
    double? deliveryLat,
    double? deliveryLng,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (pickupLat != null && pickupLng != null) {
        updateData['pickupLatitude'] = pickupLat;
        updateData['pickupLongitude'] = pickupLng;
      }

      if (deliveryLat != null && deliveryLng != null) {
        updateData['deliveryLatitude'] = deliveryLat;
        updateData['deliveryLongitude'] = deliveryLng;
      }

      if (updateData.isNotEmpty) {
        await _firestore
            .collection(FirebaseCollections.orders)
            .doc(orderId)
            .update(updateData);

        debugPrint('✅ Coordonnées GPS ajoutées à la commande $orderId');
      }
    } catch (e) {
      debugPrint('❌ Erreur ajout GPS à la commande $orderId: $e');
      rethrow;
    }
  }

  /// Afficher les statistiques des commandes sans GPS
  static Future<Map<String, int>> getStatistics() async {
    try {
      final querySnapshot = await _firestore
          .collection(FirebaseCollections.orders)
          .get();

      int totalOrders = querySnapshot.docs.length;
      int withoutPickupGPS = 0;
      int withoutDeliveryGPS = 0;
      int withoutAnyGPS = 0;
      int withFullGPS = 0;

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final pickupLat = data['pickupLatitude'];
        final pickupLng = data['pickupLongitude'];
        final deliveryLat = data['deliveryLatitude'];
        final deliveryLng = data['deliveryLongitude'];

        final hasPickup = pickupLat != null && pickupLng != null;
        final hasDelivery = deliveryLat != null && deliveryLng != null;

        if (!hasPickup) withoutPickupGPS++;
        if (!hasDelivery) withoutDeliveryGPS++;
        if (!hasPickup && !hasDelivery) withoutAnyGPS++;
        if (hasPickup && hasDelivery) withFullGPS++;
      }

      return {
        'total': totalOrders,
        'withoutPickupGPS': withoutPickupGPS,
        'withoutDeliveryGPS': withoutDeliveryGPS,
        'withoutAnyGPS': withoutAnyGPS,
        'withFullGPS': withFullGPS,
      };
    } catch (e) {
      debugPrint('❌ Erreur calcul statistiques GPS: $e');
      return {};
    }
  }
}
