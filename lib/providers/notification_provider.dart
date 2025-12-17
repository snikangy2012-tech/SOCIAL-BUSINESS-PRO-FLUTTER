// ===== lib/providers/notification_provider.dart =====
// Provider pour gérer le badge de notifications - SOCIAL BUSINESS Pro

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/constants.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  int _unreadCount = 0;
  String? _userId;
  StreamSubscription<QuerySnapshot>? _notificationSubscription;
  bool _isInitialized = false;

  int get unreadCount => _unreadCount;

  /// Initialiser le provider avec l'ID utilisateur
  Future<void> initialize(String userId) async {
    // ✅ Protection contre la ré-initialisation multiple
    if (_isInitialized && _userId == userId) {
      debugPrint('⚠️ NotificationProvider déjà initialisé pour $userId');
      return;
    }

    // Si changement d'utilisateur, nettoyer l'ancien listener
    if (_userId != null && _userId != userId) {
      debugPrint('🔄 Changement d\'utilisateur: $_userId → $userId');
      _notificationSubscription?.cancel();
      _unreadCount = 0;
    }

    _userId = userId;
    _isInitialized = true;
    await _loadUnreadCount();
    _listenToNotifications();
  }

  /// Charger le nombre de notifications non lues
  Future<void> _loadUnreadCount() async {
    if (_userId == null) return;

    try {
      final count = await NotificationService().getUnreadCount(_userId!);
      _unreadCount = count;
      notifyListeners();
      debugPrint('📊 Notifications non lues: $_unreadCount');
    } catch (e) {
      debugPrint('❌ Erreur chargement notifications: $e');
    }
  }

  /// Écouter les changements de notifications en temps réel
  void _listenToNotifications() {
    if (_userId == null) return;

    _notificationSubscription?.cancel();

    _notificationSubscription = FirebaseFirestore.instance
        .collection(FirebaseCollections.notifications)
        .where('userId', isEqualTo: _userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      _unreadCount = snapshot.docs.length;
      notifyListeners();
      debugPrint('🔔 Mise à jour notifications: $_unreadCount non lues');
    });
  }

  /// Marquer une notification comme lue
  Future<void> markAsRead(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection(FirebaseCollections.notifications)
          .doc(notificationId)
          .update({'isRead': true, 'readAt': FieldValue.serverTimestamp()});

      if (_unreadCount > 0) {
        _unreadCount--;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Erreur marquage notification: $e');
    }
  }

  /// Marquer toutes les notifications comme lues
  Future<void> markAllAsRead() async {
    if (_userId == null) return;

    try {
      final batch = FirebaseFirestore.instance.batch();
      final notifications = await FirebaseFirestore.instance
          .collection(FirebaseCollections.notifications)
          .where('userId', isEqualTo: _userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true, 'readAt': FieldValue.serverTimestamp()});
      }

      await batch.commit();
      _unreadCount = 0;
      notifyListeners();
      debugPrint('✅ Toutes les notifications marquées comme lues');
    } catch (e) {
      debugPrint('❌ Erreur marquage toutes notifications: $e');
    }
  }

  /// Rafraîchir le compteur
  Future<void> refresh() async {
    await _loadUnreadCount();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _isInitialized = false;
    _userId = null;
    _unreadCount = 0;
    super.dispose();
  }
}
