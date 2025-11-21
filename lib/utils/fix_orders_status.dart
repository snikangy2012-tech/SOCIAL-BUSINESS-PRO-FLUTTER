// ===== lib/utils/fix_orders_status.dart =====
// Script pour corriger les statuts des commandes - SOCIAL BUSINESS Pro

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../config/constants.dart';

class FixOrdersStatus {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Remettre les commandes 'in_delivery' à 'ready' pour respecter la nouvelle logique
  /// Nouvelle logique: le statut passe à 'in_delivery' UNIQUEMENT quand le livreur accepte
  static Future<void> resetInDeliveryToReady() async {
    try {
      debugPrint('🔧 === Correction des statuts de commandes ===');

      // Récupérer toutes les commandes avec statut 'in_delivery'
      final querySnapshot = await _firestore
          .collection(FirebaseCollections.orders)
          .where('status', isEqualTo: 'in_delivery')
          .get();

      if (querySnapshot.docs.isEmpty) {
        debugPrint('✅ Aucune commande à corriger');
        return;
      }

      debugPrint('📦 ${querySnapshot.docs.length} commandes trouvées avec statut "in_delivery"');

      int correctedCount = 0;
      int skippedCount = 0;

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final livreurId = data['livreurId'];
        final orderNumber = data['orderNumber'] ?? doc.id;

        // Si la commande a déjà un livreur assigné, on la laisse en 'in_delivery'
        if (livreurId != null && livreurId.toString().isNotEmpty) {
          debugPrint('  ⏭️ ${orderNumber}: a un livreur assigné, on garde "in_delivery"');
          skippedCount++;
          continue;
        }

        // Sinon, on remet à 'ready'
        await doc.reference.update({
          'status': 'ready',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        debugPrint('  ✅ ${orderNumber}: "in_delivery" → "ready"');
        correctedCount++;
      }

      debugPrint('');
      debugPrint('📊 === Résultat de la correction ===');
      debugPrint('  ✅ Commandes corrigées: $correctedCount');
      debugPrint('  ⏭️ Commandes conservées: $skippedCount');
      debugPrint('  📦 Total traité: ${querySnapshot.docs.length}');

    } catch (e) {
      debugPrint('❌ Erreur correction statuts: $e');
      throw Exception('Impossible de corriger les statuts: $e');
    }
  }

  /// Supprimer le livreurId des commandes qui n'ont pas encore été vraiment assignées
  static Future<void> clearUnassignedLivreurIds() async {
    try {
      debugPrint('🔧 === Nettoyage des livreurId non assignés ===');

      // Récupérer toutes les commandes avec un livreurId mais pas en 'in_delivery'
      final querySnapshot = await _firestore
          .collection(FirebaseCollections.orders)
          .get();

      int clearedCount = 0;

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final status = data['status'] ?? '';
        final livreurId = data['livreurId'];
        final orderNumber = data['orderNumber'] ?? doc.id;

        // Si la commande a un livreurId mais n'est pas en 'in_delivery', on supprime le livreurId
        if (livreurId != null &&
            livreurId.toString().isNotEmpty &&
            status != 'in_delivery' &&
            status != 'delivered' &&
            status != 'completed') {

          await doc.reference.update({
            'livreurId': null,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          debugPrint('  🧹 ${orderNumber}: livreurId supprimé (statut: $status)');
          clearedCount++;
        }
      }

      debugPrint('');
      debugPrint('📊 === Résultat du nettoyage ===');
      debugPrint('  🧹 livreurId supprimés: $clearedCount');

    } catch (e) {
      debugPrint('❌ Erreur nettoyage livreurId: $e');
      throw Exception('Impossible de nettoyer les livreurId: $e');
    }
  }

  /// Exécuter toutes les corrections
  static Future<void> fixAll() async {
    debugPrint('🚀 === Lancement de toutes les corrections ===');

    await resetInDeliveryToReady();
    await clearUnassignedLivreurIds();

    debugPrint('');
    debugPrint('✅ === Toutes les corrections terminées ===');
  }
}
