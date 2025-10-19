// ===== lib/services/notification_service.dart =====
// Service de gestion des notifications - SOCIAL BUSINESS Pro
// Migré depuis src/services/notification.service.ts

import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

import '../config/constants.dart';
import '../models/notification_model.dart';

/// Service de gestion des notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();

  String? _userId;
  String? _fcmToken;
  StreamSubscription<RemoteMessage>? _messageSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;

  // ===== INITIALISATION =====

  /// Initialiser le service de notifications
  Future<void> initialize(String userId) async {
    try {
      _userId = userId;

      // Demander les permissions
      await _requestPermissions();

      // Initialiser les notifications locales
      await _initializeLocalNotifications();

      // Obtenir le token FCM
      await _getFCMToken();

      // Configurer les listeners
      _setupMessageHandlers();

      // Synchroniser les notifications non lues
      await _syncUnreadNotifications();

      debugPrint('✅ Service de notifications initialisé');
    } catch (e) {
      debugPrint('❌ Erreur initialisation notifications: $e');
    }
  }

  /// Demander les permissions
  Future<void> _requestPermissions() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ Permissions notifications accordées');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('⚠️ Permissions notifications provisoires');
      } else {
        debugPrint('❌ Permissions notifications refusées');
      }
    } catch (e) {
      debugPrint('❌ Erreur demande permissions: $e');
    }
  }

  /// Initialiser les notifications locales
  Future<void> _initializeLocalNotifications() async {
    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      debugPrint('✅ Notifications locales initialisées');
    } catch (e) {
      debugPrint('❌ Erreur init notifications locales: $e');
    }
  }

  /// Obtenir le token FCM
  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      
      if (_fcmToken != null && _userId != null) {
        // Sauvegarder le token dans Firestore
        await _db
            .collection(FirebaseCollections.users)
            .doc(_userId)
            .update({
          'fcmToken': _fcmToken,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        });

        debugPrint('✅ Token FCM obtenu et sauvegardé');
      }

      // Écouter les rafraîchissements de token
      _messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        if (_userId != null) {
          _db.collection(FirebaseCollections.users).doc(_userId).update({
            'fcmToken': newToken,
            'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      debugPrint('❌ Erreur récupération token FCM: $e');
    }
  }

  /// Configurer les gestionnaires de messages
  void _setupMessageHandlers() {
    // Messages en arrière-plan (app fermée ou en arrière-plan)
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    // Messages en avant-plan (app ouverte)
    _messageSubscription = FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Messages ouverts (tap sur notification)
    _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpened);

    // Vérifier si l'app a été ouverte depuis une notification
    _messaging.getInitialMessage().then((message) {
      if (message != null) {
        _handleMessageOpened(message);
      }
    });
  }

  // ===== GESTION DES MESSAGES =====

  /// Gérer les messages en arrière-plan
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    debugPrint('📩 Notification en arrière-plan: ${message.messageId}');
    // Les notifications en arrière-plan sont gérées automatiquement par FCM
  }

  /// Gérer les messages en avant-plan
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('📩 Notification en avant-plan: ${message.messageId}');

    // Afficher une notification locale
    await _showLocalNotification(
      title: message.notification?.title ?? 'Nouvelle notification',
      body: message.notification?.body ?? '',
      payload: message.data.toString(),
    );

    // Sauvegarder la notification dans Firestore
    if (_userId != null) {
      await _saveNotification(message);
    }
  }

  /// Gérer l'ouverture d'une notification
  void _handleMessageOpened(RemoteMessage message) {
    debugPrint('👆 Notification ouverte: ${message.messageId}');
    
    // Navigation selon le type de notification
    final notificationType = message.data['type'] as String?;
    final relatedId = message.data['relatedId'] as String?;

    if (notificationType == null) return;

    // Navigation selon le type
    switch (notificationType) {
      case 'order':
        // Naviguer vers les détails de la commande
        debugPrint('📦 Navigation vers commande: $relatedId');
        // TODO: Implémenter navigation
        break;
      case 'delivery':
        // Naviguer vers la livraison
        debugPrint('🚚 Navigation vers livraison: $relatedId');
        break;
      case 'payment':
        // Naviguer vers les paiements
        debugPrint('💳 Navigation vers paiement: $relatedId');
        break;
      case 'message':
        // Naviguer vers les messages
        debugPrint('💬 Navigation vers messages');
        break;
      case 'promotion':
        // Naviguer vers les promotions
        debugPrint('🎁 Navigation vers promotions');
        break;
      default:
        debugPrint('📱 Type de notification non géré: $notificationType');
    }
  }

  /// Callback pour les taps sur notifications locales
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('👆 Notification locale tapée: ${response.payload}');
    // TODO: Gérer la navigation
  }

  // ===== AFFICHAGE DES NOTIFICATIONS =====

  /// Afficher une notification locale
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'social_business_pro',
        'SOCIAL BUSINESS Pro',
        channelDescription: 'Notifications de l\'application',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('❌ Erreur affichage notification: $e');
    }
  }

  /// Afficher une notification planifiée
  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'social_business_pro',
        'SOCIAL BUSINESS Pro',
        channelDescription: 'Notifications planifiées',
        importance: Importance.high,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      // ignore: unused_local_variable
      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Note: flutter_local_notifications nécessite timezone pour les planifications
      // Vous devrez ajouter le package timezone et l'initialiser
      debugPrint('⚠️ Notification planifiée (nécessite timezone): $title');
    } catch (e) {
      debugPrint('❌ Erreur planification notification: $e');
    }
  }

  // ===== GESTION DANS FIRESTORE =====

  /// Sauvegarder une notification dans Firestore
  Future<void> _saveNotification(RemoteMessage message) async {
    try {
      if (_userId == null) return;

      final notificationRef = _db
          .collection(FirebaseCollections.notifications)
          .doc();

      final notification = NotificationModel(
        id: notificationRef.id,
        userId: _userId!,
        type: message.data['type'] ?? 'general',
        title: message.notification?.title ?? 'Notification',
        body: message.notification?.body ?? '',
        data: message.data,
        isRead: false,
        createdAt: DateTime.now(),
      );

      await notificationRef.set(notification.toMap());
    } catch (e) {
      debugPrint('❌ Erreur sauvegarde notification: $e');
    }
  }

  /// Créer une notification personnalisée
  Future<void> createNotification({
    required String userId,
    required String type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final notificationRef = _db
          .collection(FirebaseCollections.notifications)
          .doc();

      final notification = NotificationModel(
        id: notificationRef.id,
        userId: userId,
        type: type,
        title: title,
        body: body,
        data: data ?? {},
        isRead: false,
        createdAt: DateTime.now(),
      );

      await notificationRef.set(notification.toMap());

      // Envoyer une notification push si l'utilisateur a un token
      final userDoc = await _db.collection(FirebaseCollections.users).doc(userId).get();
      final fcmToken = userDoc.data()?['fcmToken'];

      if (fcmToken != null) {
        // TODO: Envoyer via Cloud Functions ou API
        debugPrint('📤 Envoi notification push à: $userId');
      }
    } catch (e) {
      debugPrint('❌ Erreur création notification: $e');
    }
  }

  /// Récupérer les notifications d'un utilisateur
  Future<List<NotificationModel>> getUserNotifications({
    required String userId,
    int limit = 50,
    bool? isRead,
  }) async {
    try {
      Query query = _db
          .collection(FirebaseCollections.notifications)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (isRead != null) {
        query = query.where('isRead', isEqualTo: isRead);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => NotificationModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ Erreur récupération notifications: $e');
      return [];
    }
  }

  /// Marquer une notification comme lue
  Future<void> markAsRead(String notificationId) async {
    try {
      await _db
          .collection(FirebaseCollections.notifications)
          .doc(notificationId)
          .update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('❌ Erreur marquage notification: $e');
    }
  }

  /// Marquer toutes les notifications comme lues
  Future<void> markAllAsRead(String userId) async {
    try {
      final snapshot = await _db
          .collection(FirebaseCollections.notifications)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _db.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } catch (e) {
      debugPrint('❌ Erreur marquage toutes notifications: $e');
    }
  }

  /// Supprimer une notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _db
          .collection(FirebaseCollections.notifications)
          .doc(notificationId)
          .delete();
    } catch (e) {
      debugPrint('❌ Erreur suppression notification: $e');
    }
  }

  /// Compter les notifications non lues
  Future<int> getUnreadCount(String userId) async {
    try {
      final snapshot = await _db
          .collection(FirebaseCollections.notifications)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('❌ Erreur comptage notifications: $e');
      return 0;
    }
  }

  /// Stream des notifications en temps réel
  Stream<List<NotificationModel>> watchNotifications(String userId) {
    return _db
        .collection(FirebaseCollections.notifications)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromMap(doc.data()))
            .toList());
  }

  /// Synchroniser les notifications non lues (au démarrage)
  Future<void> _syncUnreadNotifications() async {
    try {
      if (_userId == null) return;

      final unreadCount = await getUnreadCount(_userId!);
      
      // Mettre à jour le badge de l'application
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.cancelAll();

      debugPrint('📊 $unreadCount notifications non lues');
    } catch (e) {
      debugPrint('❌ Erreur sync notifications: $e');
    }
  }

  // ===== NETTOYAGE =====

  /// Nettoyer les resources
  void dispose() {
    _messageSubscription?.cancel();
    _openedSubscription?.cancel();
  }
}