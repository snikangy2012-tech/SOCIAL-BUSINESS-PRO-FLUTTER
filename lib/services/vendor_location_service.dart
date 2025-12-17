// ===== lib/services/vendor_location_service.dart =====
// Service pour récupérer les coordonnées GPS de la boutique d'un vendeur
// Système HYBRIDE avec fallback

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../config/constants.dart';

class VendorLocationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Récupérer les coordonnées GPS du pickup (boutique du vendeur)
  ///
  /// SYSTÈME HYBRIDE avec 3 niveaux de fallback:
  /// 1. Utiliser businessLatitude/businessLongitude du profil vendeur si disponibles
  /// 2. Utiliser les coordonnées d'Abidjan (centre-ville) comme fallback
  /// 3. Retourner null si aucune coordonnée n'est disponible
  static Future<Map<String, double>?> getVendorPickupCoordinates(
    String vendeurId,
  ) async {
    try {
      debugPrint('📍 Récupération coordonnées pickup pour vendeur: $vendeurId');

      // Récupérer le profil du vendeur
      final vendorDoc = await _firestore
          .collection(FirebaseCollections.users)
          .doc(vendeurId)
          .get();

      if (!vendorDoc.exists) {
        debugPrint('❌ Vendeur introuvable: $vendeurId');
        return null;
      }

      final vendorData = vendorDoc.data()!;
      final profile = vendorData['profile'] as Map<String, dynamic>?;

      // NIVEAU 1: Utiliser les coordonnées GPS configurées par le vendeur
      if (profile != null) {
        final businessLat = profile['businessLatitude'] as num?;
        final businessLng = profile['businessLongitude'] as num?;

        if (businessLat != null && businessLng != null) {
          debugPrint('✅ Coordonnées GPS boutique trouvées: $businessLat, $businessLng');
          return {
            'latitude': businessLat.toDouble(),
            'longitude': businessLng.toDouble(),
          };
        }
      }

      // NIVEAU 2: Fallback sur coordonnées par défaut (centre d'Abidjan, Côte d'Ivoire)
      debugPrint('⚠️ Coordonnées GPS boutique non configurées, utilisation fallback Abidjan');
      return _getAbidjanCenterCoordinates();

    } catch (e) {
      debugPrint('❌ Erreur récupération coordonnées vendeur: $e');
      // En cas d'erreur, retourner coordonnées Abidjan comme fallback
      return _getAbidjanCenterCoordinates();
    }
  }

  /// Coordonnées du centre d'Abidjan (Place de la République)
  /// Utilisé comme fallback quand le vendeur n'a pas configuré sa position
  static Map<String, double> _getAbidjanCenterCoordinates() {
    return {
      'latitude': 5.316667,   // Place de la République, Abidjan
      'longitude': -4.033333,
    };
  }

  /// Vérifier si un vendeur a configuré ses coordonnées GPS
  static Future<bool> hasVendorConfiguredGPS(String vendeurId) async {
    try {
      final vendorDoc = await _firestore
          .collection(FirebaseCollections.users)
          .doc(vendeurId)
          .get();

      if (!vendorDoc.exists) return false;

      final vendorData = vendorDoc.data()!;
      final profile = vendorData['profile'] as Map<String, dynamic>?;

      if (profile == null) return false;

      final businessLat = profile['businessLatitude'] as num?;
      final businessLng = profile['businessLongitude'] as num?;

      return businessLat != null && businessLng != null;
    } catch (e) {
      debugPrint('❌ Erreur vérification GPS vendeur: $e');
      return false;
    }
  }

  /// Mettre à jour les coordonnées GPS de la boutique du vendeur
  static Future<bool> updateVendorGPSCoordinates({
    required String vendeurId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      debugPrint('📍 Mise à jour coordonnées boutique vendeur $vendeurId: $latitude, $longitude');

      await _firestore.collection(FirebaseCollections.users).doc(vendeurId).update({
        'profile.businessLatitude': latitude,
        'profile.businessLongitude': longitude,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Coordonnées GPS boutique mises à jour avec succès');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur mise à jour coordonnées GPS: $e');
      return false;
    }
  }

  /// Récupérer les coordonnées de pickup pour une liste de vendeurs
  /// Utile pour optimiser les requêtes quand on a plusieurs vendeurs
  static Future<Map<String, Map<String, double>>> getBulkVendorPickupCoordinates(
    List<String> vendeurIds,
  ) async {
    final coordinates = <String, Map<String, double>>{};

    for (final vendeurId in vendeurIds) {
      final coords = await getVendorPickupCoordinates(vendeurId);
      if (coords != null) {
        coordinates[vendeurId] = coords;
      }
    }

    return coordinates;
  }
}
