// ===== lib/services/firestore_service.dart =====
// Service Firestore pour SOCIAL BUSINESS Pro - Flutter
// Équivalent de vos services Firebase React Native

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/user_model.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ===== GESTION DES UTILISATEURS =====

  /// Créer un document utilisateur dans Firestore
  static Future<bool> createUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).set(user.toFirestore());
      debugPrint('✅ Utilisateur créé dans Firestore: ${user.id}');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur création utilisateur: $e');
      return false;
    }
  }

  /// Obtenir un utilisateur par son ID
  static Future<UserModel?> getUser(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Erreur récupération utilisateur: $e');
      return null;
    }
  }

  /// Mettre à jour un utilisateur
  static Future<bool> updateUser(String userId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = Timestamp.now();
      await _firestore.collection('users').doc(userId).update(updates);
      debugPrint('✅ Utilisateur mis à jour: $userId');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur mise à jour utilisateur: $e');
      return false;
    }
  }

  /// Obtenir l'utilisateur actuel connecté
  static Future<UserModel?> getCurrentUser() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      return await getUser(currentUser.uid);
    }
    return null;
  }

  /// Écouter les changements d'un utilisateur
  static Stream<UserModel?> watchUser(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }

  // ===== GESTION DES STATISTIQUES VENDEUR =====

  /// Obtenir les statistiques du dashboard vendeur
  static Future<Map<String, dynamic>> getVendeurStats(String vendeurId) async {
    try {
      // Pour l'instant, retourner des données simulées
      // TODO: Implémenter les vraies requêtes Firestore
      
      // Simuler un délai réseau
      await Future.delayed(const Duration(milliseconds: 800));
      
      return {
        'totalSales': 15,
        'monthlyRevenue': 125000,
        'totalOrders': 42,
        'pendingOrders': 7,
        'completedOrders': 32,
        'totalProducts': 18,
        'activeProducts': 15,
        'viewsThisMonth': 1200,
        'averageRating': 4.3,
        'responseTime': '2h',
      };

      // Vraie implémentation (à décommenter plus tard):
      /*
      final orders = await _firestore
          .collection('orders')
          .where('vendeurId', isEqualTo: vendeurId)
          .get();

      final products = await _firestore
          .collection('products')
          .where('vendeurId', isEqualTo: vendeurId)
          .get();

      // Calculer les statistiques réelles
      int totalOrders = orders.docs.length;
      int pendingOrders = orders.docs.where((doc) => 
          doc.data()['status'] == 'pending').length;
      
      double totalRevenue = orders.docs
          .where((doc) => doc.data()['status'] == 'completed')
          .fold(0.0, (sum, doc) => sum + (doc.data()['totalAmount'] ?? 0));

      return {
        'totalSales': orders.docs.where((doc) => 
            doc.data()['status'] == 'completed').length,
        'monthlyRevenue': totalRevenue,
        'totalOrders': totalOrders,
        'pendingOrders': pendingOrders,
        'completedOrders': orders.docs.where((doc) => 
            doc.data()['status'] == 'completed').length,
        'totalProducts': products.docs.length,
        'activeProducts': products.docs.where((doc) => 
            doc.data()['isActive'] == true).length,
        'viewsThisMonth': 1200, // TODO: Implémenter analytics
        'averageRating': 4.3, // TODO: Calculer depuis les reviews
        'responseTime': '2h', // TODO: Calculer temps de réponse moyen
      };
      */
    } catch (e) {
      debugPrint('❌ Erreur récupération stats vendeur: $e');
      return {};
    }
  }

  /// Obtenir les commandes récentes d'un vendeur
  static Future<List<Map<String, dynamic>>> getRecentOrders(String vendeurId, {int limit = 5}) async {
    try {
      // Pour l'instant, retourner des données simulées
      await Future.delayed(const Duration(milliseconds: 600));
      
      return [
        {
          'id': '1',
          'orderNumber': 'SBP-001',
          'customerName': 'Amadou Traoré',
          'customerPhone': '+2250748123456',
          'amount': 15000,
          'status': 'pending',
          'date': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 2))),
          'items': [
            {'name': 'Chaussures Nike', 'quantity': 1, 'price': 15000}
          ],
        },
        {
          'id': '2',
          'orderNumber': 'SBP-002',
          'customerName': 'Fatou Koné',
          'customerPhone': '+2250751987654',
          'amount': 8500,
          'status': 'confirmed',
          'date': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 5))),
          'items': [
            {'name': 'Robe Ankara', 'quantity': 1, 'price': 8500}
          ],
        },
        {
          'id': '3',
          'orderNumber': 'SBP-003',
          'customerName': 'Ibrahim Diallo',
          'customerPhone': '+2250759876543',
          'amount': 25000,
          'status': 'delivered',
          'date': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
          'items': [
            {'name': 'Smartphone Samsung', 'quantity': 1, 'price': 25000}
          ],
        },
        {
          'id': '4',
          'orderNumber': 'SBP-004',
          'customerName': 'Mariam Ouattara',
          'customerPhone': '+2250752468135',
          'amount': 12000,
          'status': 'processing',
          'date': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 8))),
          'items': [
            {'name': 'Sac à main', 'quantity': 1, 'price': 12000}
          ],
        },
        {
          'id': '5',
          'orderNumber': 'SBP-005',
          'customerName': 'Koffi Asante',
          'customerPhone': '+2250747891234',
          'amount': 18500,
          'status': 'shipped',
          'date': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 12))),
          'items': [
            {'name': 'Montre connectée', 'quantity': 1, 'price': 18500}
          ],
        },
      ];

      // Vraie implémentation (à décommenter plus tard):
      /*
      final querySnapshot = await _firestore
          .collection('orders')
          .where('vendeurId', isEqualTo: vendeurId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      */
    } catch (e) {
      debugPrint('❌ Erreur récupération commandes récentes: $e');
      return [];
    }
  }

  // ===== GESTION DES PRODUITS =====

  /// Obtenir les produits d'un vendeur
  static Future<List<Map<String, dynamic>>> getVendeurProducts(String vendeurId) async {
    try {
      final querySnapshot = await _firestore
          .collection('products')
          .where('vendeurId', isEqualTo: vendeurId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('❌ Erreur récupération produits: $e');
      return [];
    }
  }

  /// Créer un nouveau produit
  static Future<String?> createProduct(Map<String, dynamic> productData) async {
    try {
      productData['createdAt'] = Timestamp.now();
      productData['updatedAt'] = Timestamp.now();
      
      final docRef = await _firestore.collection('products').add(productData);
      debugPrint('✅ Produit créé: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Erreur création produit: $e');
      return null;
    }
  }

  /// Mettre à jour un produit
  static Future<bool> updateProduct(String productId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = Timestamp.now();
      await _firestore.collection('products').doc(productId).update(updates);
      debugPrint('✅ Produit mis à jour: $productId');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur mise à jour produit: $e');
      return false;
    }
  }

  /// Supprimer un produit
  static Future<bool> deleteProduct(String productId) async {
    try {
      await _firestore.collection('products').doc(productId).delete();
      debugPrint('✅ Produit supprimé: $productId');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur suppression produit: $e');
      return false;
    }
  }

  // ===== GESTION DES COMMANDES =====

  /// Obtenir toutes les commandes d'un vendeur
  static Future<List<Map<String, dynamic>>> getVendeurOrders(String vendeurId) async {
    try {
      final querySnapshot = await _firestore
          .collection('orders')
          .where('vendeurId', isEqualTo: vendeurId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('❌ Erreur récupération commandes: $e');
      return [];
    }
  }

  /// Mettre à jour le statut d'une commande
  static Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': newStatus,
        'updatedAt': Timestamp.now(),
      });
      debugPrint('✅ Statut commande mis à jour: $orderId -> $newStatus');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur mise à jour statut commande: $e');
      return false;
    }
  }

  // ===== GESTION DES NOTIFICATIONS =====

  /// Créer une notification
  static Future<bool> createNotification({
    required String userId,
    required String title,
    required String message,
    String type = 'info',
    Map<String, dynamic>? data,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'message': message,
        'type': type,
        'data': data,
        'isRead': false,
        'createdAt': Timestamp.now(),
      });
      debugPrint('✅ Notification créée pour: $userId');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur création notification: $e');
      return false;
    }
  }

  /// Obtenir les notifications d'un utilisateur
  static Future<List<Map<String, dynamic>>> getUserNotifications(String userId, {int limit = 20}) async {
    try {
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('❌ Erreur récupération notifications: $e');
      return [];
    }
  }

  /// Marquer une notification comme lue
  static Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'readAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      debugPrint('❌ Erreur marquage notification: $e');
      return false;
    }
  }

  // ===== UTILITAIRES =====

  /// Vérifier si un document existe
  static Future<bool> documentExists(String collection, String documentId) async {
    try {
      final doc = await _firestore.collection(collection).doc(documentId).get();
      return doc.exists;
    } catch (e) {
      debugPrint('❌ Erreur vérification existence document: $e');
      return false;
    }
  }

  /// Obtenir le nombre de documents dans une collection avec filtre
  static Future<int> getCollectionCount(String collection, {Map<String, dynamic>? filters}) async {
    try {
      Query query = _firestore.collection(collection);
      
      if (filters != null) {
        filters.forEach((field, value) {
          query = query.where(field, isEqualTo: value);
        });
      }
      
      final snapshot = await query.get();
      return snapshot.docs.length;
    } catch (e) {
      debugPrint('❌ Erreur comptage collection: $e');
      return 0;
    }
  }

  /// Écouter les changements d'une collection
  static Stream<List<Map<String, dynamic>>> watchCollection(
    String collection, {
    Map<String, dynamic>? filters,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    try {
      Query query = _firestore.collection(collection);
      
      if (filters != null) {
        filters.forEach((field, value) {
          query = query.where(field, isEqualTo: value);
        });
      }
      
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }
      
      if (limit != null) {
        query = query.limit(limit);
      }
      
      return query.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList();
      });
    } catch (e) {
      debugPrint('❌ Erreur watch collection: $e');
      return Stream.value([]);
    }
  }

  // ===== GESTION DES ERREURS ET LOGS =====

  /// Logger une erreur dans Firestore (pour le debugging)
  static Future<void> logError({
    required String errorType,
    required String errorMessage,
    String? userId,
    Map<String, dynamic>? context,
  }) async {
    try {
      if (!kDebugMode) return; // Seulement en debug
      
      await _firestore.collection('error_logs').add({
        'errorType': errorType,
        'errorMessage': errorMessage,
        'userId': userId,
        'context': context,
        'timestamp': Timestamp.now(),
        'platform': 'flutter',
      });
    } catch (e) {
      debugPrint('❌ Erreur lors du logging: $e');
    }
  }

  /// Obtenir les statistiques globales de l'app (pour admin)
  static Future<Map<String, dynamic>> getAppStats() async {
    try {
      final users = await _firestore.collection('users').get();
      final products = await _firestore.collection('products').get();
      final orders = await _firestore.collection('orders').get();

      final vendeurs = users.docs.where((doc) => doc.data()['userType'] == 'vendeur').length;
      final acheteurs = users.docs.where((doc) => doc.data()['userType'] == 'acheteur').length;
      final livreurs = users.docs.where((doc) => doc.data()['userType'] == 'livreur').length;

      return {
        'totalUsers': users.docs.length,
        'totalVendeurs': vendeurs,
        'totalAcheteurs': acheteurs,
        'totalLivreurs': livreurs,
        'totalProducts': products.docs.length,
        'totalOrders': orders.docs.length,
        'lastUpdated': Timestamp.now(),
      };
    } catch (e) {
      debugPrint('❌ Erreur récupération stats app: $e');
      return {};
    }
  }

  // ===== BATCH OPERATIONS =====

  /// Exécuter plusieurs opérations en batch
  static Future<bool> executeBatch(List<Map<String, dynamic>> operations) async {
    try {
      final batch = _firestore.batch();
      
      for (final operation in operations) {
        final type = operation['type'] as String;
        final collection = operation['collection'] as String;
        final data = operation['data'] as Map<String, dynamic>?;
        
        switch (type) {
          case 'create':
            final docRef = _firestore.collection(collection).doc();
            batch.set(docRef, data!);
            break;
          case 'update':
            final docId = operation['docId'] as String;
            final docRef = _firestore.collection(collection).doc(docId);
            batch.update(docRef, data!);
            break;
          case 'delete':
            final docId = operation['docId'] as String;
            final docRef = _firestore.collection(collection).doc(docId);
            batch.delete(docRef);
            break;
        }
      }
      
      await batch.commit();
      debugPrint('✅ Batch operations exécutées avec succès');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur batch operations: $e');
      return false;
    }
  }
}