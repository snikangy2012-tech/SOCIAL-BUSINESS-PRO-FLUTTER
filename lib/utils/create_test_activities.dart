/// Script pour créer des activités de test dans Firestore
/// Exécuter depuis une page admin pour peupler le journal des activités
library;

import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityLogSeeder {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Créer des activités de test pour le journal des activités
  static Future<void> seedTestActivities() async {
    try {
      final now = DateTime.now();

      // Activités utilisateurs
      await _createActivity(
        type: 'users',
        action: 'user_created',
        userName: 'Admin Système',
        description: 'Nouvel acheteur inscrit: Jean Kouassi',
        timestamp: now.subtract(const Duration(hours: 2)),
      );

      await _createActivity(
        type: 'users',
        action: 'vendor_approved',
        userName: 'Admin Système',
        description: 'Vendeur approuvé: Boutique Abidjan Fashion',
        timestamp: now.subtract(const Duration(hours: 5)),
      );

      await _createActivity(
        type: 'users',
        action: 'kyc_verified',
        userName: 'Admin Système',
        description: 'KYC vérifié pour le livreur: Kouakou Patrick',
        timestamp: now.subtract(const Duration(hours: 8)),
      );

      // Activités produits
      await _createActivity(
        type: 'products',
        action: 'product_created',
        userName: 'Boutique Mode CI',
        description: 'Nouveau produit ajouté: Robe Africaine Wax',
        timestamp: now.subtract(const Duration(hours: 1)),
      );

      await _createActivity(
        type: 'products',
        action: 'product_updated',
        userName: 'TechStore Abidjan',
        description: 'Produit modifié: iPhone 13 - Prix réduit de 15%',
        timestamp: now.subtract(const Duration(hours: 4)),
      );

      await _createActivity(
        type: 'products',
        action: 'product_deleted',
        userName: 'Électro Plus',
        description: 'Produit supprimé: Samsung Galaxy A12 (rupture définitive)',
        timestamp: now.subtract(const Duration(hours: 12)),
      );

      // Activités commandes
      await _createActivity(
        type: 'orders',
        action: 'order_placed',
        userName: 'Marie Bamba',
        description: 'Nouvelle commande #CMD-1234 - Montant: 45 000 FCFA',
        timestamp: now.subtract(const Duration(minutes: 30)),
      );

      await _createActivity(
        type: 'orders',
        action: 'order_delivered',
        userName: 'Livreur Express',
        description: 'Commande #CMD-1200 livrée avec succès',
        timestamp: now.subtract(const Duration(hours: 3)),
      );

      await _createActivity(
        type: 'orders',
        action: 'order_cancelled',
        userName: 'Kouadio Aya',
        description: 'Commande #CMD-1180 annulée par le client',
        timestamp: now.subtract(const Duration(hours: 6)),
      );

      // Activités système
      await _createActivity(
        type: 'system',
        action: 'system_maintenance',
        userName: 'Système',
        description: 'Maintenance programmée: Mise à jour base de données',
        timestamp: now.subtract(const Duration(days: 1)),
      );

      await _createActivity(
        type: 'system',
        action: 'backup_completed',
        userName: 'Système',
        description: 'Sauvegarde automatique effectuée avec succès',
        timestamp: now.subtract(const Duration(hours: 24)),
      );

      await _createActivity(
        type: 'system',
        action: 'security_alert',
        userName: 'Système',
        description: 'Tentative de connexion suspecte détectée et bloquée',
        timestamp: now.subtract(const Duration(hours: 10)),
      );

      print('✅ 12 activités de test créées avec succès');
    } catch (e) {
      print('❌ Erreur création activités: $e');
      rethrow;
    }
  }

  /// Créer une activité dans Firestore
  static Future<void> _createActivity({
    required String type,
    required String action,
    required String userName,
    required String description,
    required DateTime timestamp,
  }) async {
    await _firestore.collection('activity_logs').add({
      'type': type,
      'action': action,
      'userName': userName,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Supprimer toutes les activités de test (pour nettoyage)
  static Future<void> clearAllActivities() async {
    try {
      final snapshot = await _firestore.collection('activity_logs').get();
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
      print('✅ ${snapshot.docs.length} activités supprimées');
    } catch (e) {
      print('❌ Erreur suppression activités: $e');
      rethrow;
    }
  }

  /// Créer une activité réelle (à appeler depuis l'app)
  static Future<void> logActivity({
    required String type,
    required String action,
    required String userName,
    required String description,
  }) async {
    try {
      await _firestore.collection('activity_logs').add({
        'type': type,
        'action': action,
        'userName': userName,
        'description': description,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('⚠️ Erreur log activité: $e');
    }
  }
}
