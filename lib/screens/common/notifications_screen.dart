// lib/screens/common/notifications_screen.dart
// Écran de gestion des notifications - SOCIAL BUSINESS Pro
// Transversal : utilisable par tous les types d'utilisateurs

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:social_business_pro/config/constants.dart';
import '../../models/notification_model.dart';
import '../../providers/auth_provider_firebase.dart';
import '../../widgets/system_ui_scaffold.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _selectedFilter = 'all'; // all, unread, read
  bool _isLoading = true;
  List<NotificationModel> _notifications = [];
  List<NotificationModel> _filteredNotifications = [];
  Timer? _refreshTimer;
  final _refreshInterval = const Duration(seconds: 20); // Rafraîchir toutes les 20 secondes

  @override
  void initState() {
    super.initState();
    _loadNotifications();

    // 🔄 Démarrer le rafraîchissement automatique
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(_refreshInterval, (timer) {
      if (mounted) {
        debugPrint('🔄 Auto-refresh notifications');
        _loadNotifications();
      }
    });
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.user?.id;

      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Charger les notifications depuis Firestore
      final snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();

      final notifications =
          snapshot.docs.map((doc) => NotificationModel.fromMap(doc.data())).toList();

      if (mounted) {
        setState(() {
          _notifications = notifications;
          _applyFilter();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement notifications: $e');
      if (mounted) {
        setState(() {
          _notifications = [];
          _filteredNotifications = [];
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilter() {
    switch (_selectedFilter) {
      case 'unread':
        _filteredNotifications = _notifications.where((n) => !n.isRead).toList();
        break;
      case 'read':
        _filteredNotifications = _notifications.where((n) => n.isRead).toList();
        break;
      default:
        _filteredNotifications = List.from(_notifications);
    }
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (notification.isRead) return;

    try {
      await FirebaseFirestore.instance.collection('notifications').doc(notification.id).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });

      // Mettre à jour localement
      if (mounted) {
        setState(() {
          final index = _notifications.indexWhere((n) => n.id == notification.id);
          if (index != -1) {
            _notifications[index] = notification.copyWith(
              isRead: true,
              readAt: DateTime.now(),
            );
          }
          _applyFilter();
        });
      }
    } catch (e) {
      debugPrint('❌ Erreur marquage notification lue: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    final unreadNotifications = _notifications.where((n) => !n.isRead).toList();
    if (unreadNotifications.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aucune notification non lue'),
            backgroundColor: AppColors.info,
          ),
        );
      }
      return;
    }

    try {
      // Mettre à jour toutes les notifications non lues
      final batch = FirebaseFirestore.instance.batch();
      for (final notification in unreadNotifications) {
        final docRef = FirebaseFirestore.instance.collection('notifications').doc(notification.id);
        batch.update(docRef, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();

      // Recharger les notifications
      await _loadNotifications();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Toutes les notifications ont été marquées comme lues'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Erreur marquage tout comme lu: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteNotification(NotificationModel notification) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la notification'),
        content: const Text('Voulez-vous vraiment supprimer cette notification ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance.collection('notifications').doc(notification.id).delete();

      if (mounted) {
        setState(() {
          _notifications.removeWhere((n) => n.id == notification.id);
          _applyFilter();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Notification supprimée'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Erreur suppression notification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteAllRead() async {
    final readNotifications = _notifications.where((n) => n.isRead).toList();
    if (readNotifications.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aucune notification lue à supprimer'),
            backgroundColor: AppColors.info,
          ),
        );
      }
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer toutes les notifications lues'),
        content: Text(
          'Voulez-vous vraiment supprimer ${readNotifications.length} notification(s) lue(s) ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final notification in readNotifications) {
        final docRef = FirebaseFirestore.instance.collection('notifications').doc(notification.id);
        batch.delete(docRef);
      }
      await batch.commit();

      await _loadNotifications();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${readNotifications.length} notification(s) supprimée(s)'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Erreur suppression notifications lues: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _handleNotificationTap(NotificationModel notification) {
    // Marquer comme lue
    _markAsRead(notification);

    // Navigation selon le type de notification
    final data = notification.data;
    switch (notification.type) {
      case 'order':
        if (data.containsKey('orderId')) {
          context.push('/order/${data['orderId']}');
        }
        break;
      case 'delivery':
        if (data.containsKey('deliveryId')) {
          context.push('/delivery/${data['deliveryId']}');
        }
        break;
      case 'message':
        if (data.containsKey('chatId')) {
          context.push('/chat/${data['chatId']}');
        }
        break;
      case 'promotion':
        if (data.containsKey('productId')) {
          context.push('/product/${data['productId']}');
        }
        break;
      default:
        // Afficher les détails dans un bottom sheet
        _showNotificationDetails(notification);
    }
  }

  void _showNotificationDetails(NotificationModel notification) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: AppSpacing.lg +
              MediaQuery.of(context).viewInsets.bottom +
              MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barre de poignée
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Icône et type
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: _getNotificationColor(notification.type).withValues(alpha: 0.2),
                  child: Icon(
                    _getNotificationIcon(notification.type),
                    color: _getNotificationColor(notification.type),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getNotificationTypeLabel(notification.type),
                        style: TextStyle(
                          fontSize: AppFontSizes.sm,
                          color: _getNotificationColor(notification.type),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        notification.timeAgo,
                        style: const TextStyle(
                          fontSize: AppFontSizes.sm,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            // Titre
            Text(
              notification.title,
              style: const TextStyle(
                fontSize: AppFontSizes.xl,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // Corps
            Text(
              notification.body,
              style: const TextStyle(
                fontSize: AppFontSizes.md,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Date complète
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    DateFormat('dd/MM/yyyy à HH:mm').format(notification.createdAt),
                    style: const TextStyle(
                      fontSize: AppFontSizes.sm,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Bouton fermer
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return SystemUIScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/');
            }
          },
          tooltip: 'Retour',
        ),
        title: Column(
          children: [
            const Text('Notifications'),
            if (unreadCount > 0)
              Text(
                '$unreadCount non lue${unreadCount > 1 ? 's' : ''}',
                style: const TextStyle(
                  fontSize: AppFontSizes.sm,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Menu d'actions
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'mark_all_read':
                  _markAllAsRead();
                  break;
                case 'delete_read':
                  _deleteAllRead();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_all_read',
                child: Row(
                  children: [
                    Icon(Icons.done_all, size: 20),
                    SizedBox(width: AppSpacing.sm),
                    Text('Tout marquer comme lu'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete_read',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, size: 20, color: AppColors.error),
                    SizedBox(width: AppSpacing.sm),
                    Text('Supprimer les notifications lues',
                        style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtres
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            color: Colors.white,
            child: Row(
              children: [
                _buildFilterChip('Toutes', 'all', _notifications.length, showBadge: false),
                const SizedBox(width: AppSpacing.sm),
                _buildFilterChip('Non lues', 'unread', unreadCount, showBadge: true),
                const SizedBox(width: AppSpacing.sm),
                _buildFilterChip('Lues', 'read', _notifications.length - unreadCount,
                    showBadge: false),
              ],
            ),
          ),

          const Divider(height: 1),

          // Liste des notifications
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredNotifications.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadNotifications,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          itemCount: _filteredNotifications.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, index) {
                            final notification = _filteredNotifications[index];
                            return _buildNotificationCard(notification);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, int count, {bool showBadge = true}) {
    final isSelected = _selectedFilter == value;
    return Expanded(
      child: ChoiceChip(
        label: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Afficher le badge uniquement si showBadge est true ET count > 0
            if (showBadge && count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: AppFontSizes.xs,
                    color: isSelected ? AppColors.primary : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = value;
            _applyFilter();
          });
        },
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) => _deleteNotification(notification),
      child: Card(
        elevation: notification.isRead ? 0 : 2,
        color: notification.isRead ? Colors.grey[50] : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(
            color:
                notification.isRead ? Colors.grey[200]! : AppColors.primary.withValues(alpha: 0.3),
            width: notification.isRead ? 1 : 2,
          ),
        ),
        child: InkWell(
          onTap: () => _handleNotificationTap(notification),
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icône
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _getNotificationColor(notification.type).withValues(alpha: 0.2),
                  child: Icon(
                    _getNotificationIcon(notification.type),
                    color: _getNotificationColor(notification.type),
                    size: 20,
                  ),
                ),

                const SizedBox(width: AppSpacing.md),

                // Contenu
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // En-tête (titre + badge non lu)
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: AppFontSizes.md,
                                fontWeight:
                                    notification.isRead ? FontWeight.normal : FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!notification.isRead) ...[
                            const SizedBox(width: AppSpacing.xs),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: AppSpacing.xs),

                      // Corps
                      Text(
                        notification.body,
                        style: const TextStyle(
                          fontSize: AppFontSizes.sm,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: AppSpacing.xs),

                      // Heure
                      Text(
                        notification.timeAgo,
                        style: TextStyle(
                          fontSize: AppFontSizes.xs,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                // Action
                IconButton(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onPressed: () => _showNotificationActions(notification),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNotificationActions(NotificationModel notification) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!notification.isRead)
              ListTile(
                leading: const Icon(Icons.done),
                title: const Text('Marquer comme lue'),
                onTap: () {
                  Navigator.pop(context);
                  _markAsRead(notification);
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.error),
              title: const Text('Supprimer', style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(context);
                _deleteNotification(notification);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    String message;
    IconData icon;
    switch (_selectedFilter) {
      case 'unread':
        message = 'Aucune notification non lue';
        icon = Icons.notifications_none;
        break;
      case 'read':
        message = 'Aucune notification lue';
        icon = Icons.notifications_off_outlined;
        break;
      default:
        message = 'Aucune notification';
        icon = Icons.notifications_none;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[300]),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            style: TextStyle(
              fontSize: AppFontSizes.lg,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'order':
        return Icons.shopping_cart;
      case 'delivery':
        return Icons.local_shipping;
      case 'payment':
        return Icons.payment;
      case 'message':
        return Icons.message;
      case 'promotion':
        return Icons.local_offer;
      case 'system':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'order':
        return AppColors.warning;
      case 'delivery':
        return AppColors.info;
      case 'payment':
        return AppColors.success;
      case 'message':
        return Colors.purple;
      case 'promotion':
        return AppColors.error;
      case 'system':
        return AppColors.textSecondary;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getNotificationTypeLabel(String type) {
    switch (type) {
      case 'order':
        return 'Commande';
      case 'delivery':
        return 'Livraison';
      case 'payment':
        return 'Paiement';
      case 'message':
        return 'Message';
      case 'promotion':
        return 'Promotion';
      case 'system':
        return 'Système';
      default:
        return 'Notification';
    }
  }
}

