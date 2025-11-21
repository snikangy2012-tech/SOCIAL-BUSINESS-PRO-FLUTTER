// ===== lib/screens/admin/activity_log_screen.dart =====
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_business_pro/config/constants.dart';
import 'package:intl/intl.dart';

class ActivityLogScreen extends StatefulWidget {
  const ActivityLogScreen({super.key});

  @override
  State<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  String _selectedFilter = 'all'; // all, users, products, orders, system
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal des activités'),
        backgroundColor: AppColors.info,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            initialValue: _selectedFilter,
            onSelected: (value) => setState(() => _selectedFilter = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('Toutes les activités')),
              const PopupMenuItem(value: 'users', child: Text('Utilisateurs')),
              const PopupMenuItem(value: 'products', child: Text('Produits')),
              const PopupMenuItem(value: 'orders', child: Text('Commandes')),
              const PopupMenuItem(value: 'system', child: Text('Système')),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getActivityStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: AppSpacing.md),
                  Text('Erreur: ${snapshot.error}'),
                ],
              ),
            );
          }

          final activities = snapshot.data?.docs ?? [];

          if (activities.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timeline, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: AppSpacing.md),
                  const Text('Aucune activité récente'),
                ],
              ),
            );
          }

          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final activity = activities[index].data() as Map<String, dynamic>;
              return _buildActivityItem(activity);
            },
          );
        },
      ),
    );
  }

  Stream<QuerySnapshot> _getActivityStream() {
    Query query = FirebaseFirestore.instance
        .collection('activity_logs')
        .orderBy('timestamp', descending: true)
        .limit(100);

    if (_selectedFilter != 'all') {
      query = query.where('type', isEqualTo: _selectedFilter);
    }

    return query.snapshots();
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    final timestamp = activity['timestamp'] as Timestamp?;
    final type = activity['type'] as String? ?? 'system';
    final action = activity['action'] as String? ?? '';
    final userName = activity['userName'] as String? ?? 'Système';
    final description = activity['description'] as String? ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getTypeColor(type).withValues(alpha: 0.2),
          child: Icon(_getTypeIcon(type), color: _getTypeColor(type)),
        ),
        title: Text(
          action,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.person, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  userName,
                  style: TextStyle(fontSize: AppFontSizes.xs, color: Colors.grey[600]),
                ),
                const SizedBox(width: AppSpacing.md),
                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  _formatTimestamp(timestamp),
                  style: TextStyle(fontSize: AppFontSizes.xs, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'users':
        return Icons.people;
      case 'products':
        return Icons.inventory;
      case 'orders':
        return Icons.shopping_cart;
      case 'system':
        return Icons.settings;
      default:
        return Icons.info;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'users':
        return AppColors.primary;
      case 'products':
        return AppColors.success;
      case 'orders':
        return AppColors.warning;
      case 'system':
        return AppColors.info;
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inHours < 1) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inDays < 1) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays}j';
    } else {
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    }
  }
}
