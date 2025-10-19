// ===== lib/models/notification_model.dart =====
// Modèle de données pour les notifications - SOCIAL BUSINESS Pro

import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle de notification
class NotificationModel {
  final String id;
  final String userId;
  final String type; // order, delivery, payment, message, promotion, system
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.isRead,
    required this.createdAt,
    this.readAt,
  });

  /// Créer depuis Firestore
  factory NotificationModel.fromMap(Map<String, dynamic> data) {
    return NotificationModel(
      id: data['id'] ?? '',
      userId: data['userId'] ?? '',
      type: data['type'] ?? 'general',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      data: Map<String, dynamic>.from(data['data'] ?? {}),
      isRead: data['isRead'] ?? false,
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      readAt: data['readAt']?.toDate(),
    );
  }

  /// Convertir en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'title': title,
      'body': body,
      'data': data,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
    };
  }

  /// Copier avec modifications
  NotificationModel copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }

  /// Obtenir l'icône selon le type
  String get iconName {
    switch (type) {
      case 'order':
        return 'shopping_cart';
      case 'delivery':
        return 'local_shipping';
      case 'payment':
        return 'payment';
      case 'message':
        return 'message';
      case 'promotion':
        return 'local_offer';
      case 'system':
        return 'info';
      default:
        return 'notifications';
    }
  }

  /// Obtenir la couleur selon le type
  String get colorHex {
    switch (type) {
      case 'order':
        return '#f97316'; // Orange
      case 'delivery':
        return '#3b82f6'; // Blue
      case 'payment':
        return '#10b981'; // Green
      case 'message':
        return '#8b5cf6'; // Purple
      case 'promotion':
        return '#ef4444'; // Red
      case 'system':
        return '#6b7280'; // Gray
      default:
        return '#6b7280';
    }
  }

  /// Obtenir le temps relatif (ex: "Il y a 5 min")
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours} h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} j';
    } else {
      return 'Il y a ${(difference.inDays / 7).floor()} sem';
    }
  }
}
