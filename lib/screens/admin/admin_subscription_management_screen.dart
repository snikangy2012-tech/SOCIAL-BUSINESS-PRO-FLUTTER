// ===== lib/screens/admin/admin_subscription_management_screen.dart =====
// Gestion des abonnements vendeurs et livreurs - SOCIAL BUSINESS Pro

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/constants.dart';
import '../../models/subscription_model.dart';
import '../../models/user_model.dart';
import '../../widgets/system_ui_scaffold.dart';

class AdminSubscriptionManagementScreen extends StatefulWidget {
  const AdminSubscriptionManagementScreen({super.key});

  @override
  State<AdminSubscriptionManagementScreen> createState() =>
      _AdminSubscriptionManagementScreenState();
}

class _AdminSubscriptionManagementScreenState extends State<AdminSubscriptionManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;

  // Abonnements avec informations utilisateur
  List<Map<String, dynamic>> _vendeurSubscriptionsWithUser = [];
  List<Map<String, dynamic>> _livreurSubscriptionsWithUser = [];
  List<Map<String, dynamic>> _filteredSubscriptions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadSubscriptions();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      _filterSubscriptions();
    }
  }

  Future<void> _loadSubscriptions() async {
    setState(() => _isLoading = true);

    try {
      // Charger les abonnements vendeurs
      final vendeurSnapshot = await FirebaseFirestore.instance
          .collection(FirebaseCollections.vendeurSubscriptions)
          .get();

      // Charger les abonnements vendeurs (regrouper par utilisateur)
      final Map<String, Map<String, dynamic>> vendeurSubscriptionsMap = {};

      for (var doc in vendeurSnapshot.docs) {
        final subscription = VendeurSubscription.fromFirestore(doc);
        final vendeurId = subscription.vendeurId;

        // Si on a déjà un abonnement pour cet utilisateur, garder le plus récent
        if (vendeurSubscriptionsMap.containsKey(vendeurId)) {
          final existing =
              vendeurSubscriptionsMap[vendeurId]!['subscription'] as VendeurSubscription;
          // Garder le plus récent (ou le plus actif)
          if (subscription.createdAt.isAfter(existing.createdAt)) {
            vendeurSubscriptionsMap[vendeurId] = {'subscription': subscription, 'user': null};
          }
        } else {
          vendeurSubscriptionsMap[vendeurId] = {'subscription': subscription, 'user': null};
        }
      }

      // Charger les infos utilisateur pour chaque vendeur unique
      _vendeurSubscriptionsWithUser = [];
      for (var entry in vendeurSubscriptionsMap.entries) {
        final userDoc = await FirebaseFirestore.instance
            .collection(FirebaseCollections.users)
            .doc(entry.key)
            .get();

        if (userDoc.exists) {
          final user = UserModel.fromFirestore(userDoc);
          _vendeurSubscriptionsWithUser.add({
            'subscription': entry.value['subscription'],
            'user': user,
          });
        }
      }

      // Charger les abonnements livreurs (regrouper par utilisateur)
      final livreurSnapshot = await FirebaseFirestore.instance
          .collection(FirebaseCollections.livreurSubscriptions)
          .get();

      final Map<String, Map<String, dynamic>> livreurSubscriptionsMap = {};

      for (var doc in livreurSnapshot.docs) {
        final subscription = LivreurSubscription.fromFirestore(doc);
        final livreurId = subscription.livreurId;

        // Si on a déjà un abonnement pour cet utilisateur, garder le plus récent
        if (livreurSubscriptionsMap.containsKey(livreurId)) {
          final existing =
              livreurSubscriptionsMap[livreurId]!['subscription'] as LivreurSubscription;
          if (subscription.createdAt.isAfter(existing.createdAt)) {
            livreurSubscriptionsMap[livreurId] = {'subscription': subscription, 'user': null};
          }
        } else {
          livreurSubscriptionsMap[livreurId] = {'subscription': subscription, 'user': null};
        }
      }

      // Charger les infos utilisateur pour chaque livreur unique
      _livreurSubscriptionsWithUser = [];
      for (var entry in livreurSubscriptionsMap.entries) {
        final userDoc = await FirebaseFirestore.instance
            .collection(FirebaseCollections.users)
            .doc(entry.key)
            .get();

        if (userDoc.exists) {
          final user = UserModel.fromFirestore(userDoc);
          _livreurSubscriptionsWithUser.add({
            'subscription': entry.value['subscription'],
            'user': user,
          });
        }
      }

      // Trier par date de création (plus récents en premier)
      _vendeurSubscriptionsWithUser.sort((a, b) {
        final subA = a['subscription'] as VendeurSubscription;
        final subB = b['subscription'] as VendeurSubscription;
        return subB.createdAt.compareTo(subA.createdAt);
      });

      _livreurSubscriptionsWithUser.sort((a, b) {
        final subA = a['subscription'] as LivreurSubscription;
        final subB = b['subscription'] as LivreurSubscription;
        return subB.createdAt.compareTo(subA.createdAt);
      });

      setState(() {
        _filterSubscriptions();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Erreur chargement abonnements: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _filterSubscriptions() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (_tabController.index == 0) {
        // Filtrer vendeurs
        _filteredSubscriptions = _vendeurSubscriptionsWithUser.where((item) {
          final subscription = item['subscription'] as VendeurSubscription;
          final user = item['user'] as UserModel;
          return query.isEmpty ||
              user.displayName.toLowerCase().contains(query) ||
              user.email.toLowerCase().contains(query) ||
              subscription.tierName.toLowerCase().contains(query) ||
              _getStatusText(subscription.status).toLowerCase().contains(query);
        }).toList();
      } else {
        // Filtrer livreurs
        _filteredSubscriptions = _livreurSubscriptionsWithUser.where((item) {
          final subscription = item['subscription'] as LivreurSubscription;
          final user = item['user'] as UserModel;
          return query.isEmpty ||
              user.displayName.toLowerCase().contains(query) ||
              user.email.toLowerCase().contains(query) ||
              subscription.tierName.toLowerCase().contains(query) ||
              _getStatusText(subscription.status).toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  String _getStatusText(SubscriptionStatus status) {
    switch (status) {
      case SubscriptionStatus.active:
        return 'Actif';
      case SubscriptionStatus.expired:
        return 'Expiré';
      case SubscriptionStatus.cancelled:
        return 'Annulé';
      case SubscriptionStatus.pending:
        return 'En attente';
      case SubscriptionStatus.suspended:
        return 'Suspendu';
    }
  }

  Color _getStatusColor(SubscriptionStatus status) {
    switch (status) {
      case SubscriptionStatus.active:
        return AppColors.success;
      case SubscriptionStatus.expired:
        return AppColors.textSecondary;
      case SubscriptionStatus.cancelled:
        return AppColors.error;
      case SubscriptionStatus.pending:
        return AppColors.warning;
      case SubscriptionStatus.suspended:
        return AppColors.error;
    }
  }

  Future<void> _updateSubscriptionStatus(
    dynamic subscription,
    SubscriptionStatus newStatus,
    bool isVendeur,
  ) async {
    try {
      final collection = isVendeur
          ? FirebaseCollections.vendeurSubscriptions
          : FirebaseCollections.livreurSubscriptions;

      await FirebaseFirestore.instance.collection(collection).doc(subscription.id).update({
        'status': newStatus.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _loadSubscriptions();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Statut mis à jour: ${_getStatusText(newStatus)}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Erreur mise à jour statut: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _changeSubscriptionTier(
    dynamic subscription,
    dynamic newTier,
    bool isVendeur,
  ) async {
    try {
      final collection = isVendeur
          ? FirebaseCollections.vendeurSubscriptions
          : FirebaseCollections.livreurSubscriptions;

      // Extraire le nom du tier de manière sécurisée
      String tierName;
      if (isVendeur) {
        tierName = (newTier as VendeurSubscriptionTier).name;
      } else {
        tierName = (newTier as LivreurTier).name;
      }

      // Calculer les nouvelles valeurs selon le tier
      Map<String, dynamic> updateData = {
        'tier': tierName,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (isVendeur) {
        final tier = newTier as VendeurSubscriptionTier;
        switch (tier) {
          case VendeurSubscriptionTier.basique:
            updateData['monthlyPrice'] = 0;
            updateData['productLimit'] = 20;
            updateData['commissionRate'] = 0.10;
            updateData['hasAIAgent'] = false;
            updateData['aiModel'] = null;
            updateData['aiMessagesPerDay'] = null;
            break;
          case VendeurSubscriptionTier.pro:
            updateData['monthlyPrice'] = 5000;
            updateData['productLimit'] = 100;
            updateData['commissionRate'] = 0.10;
            updateData['hasAIAgent'] = true;
            updateData['aiModel'] = 'GPT-3.5';
            updateData['aiMessagesPerDay'] = 50;
            break;
          case VendeurSubscriptionTier.premium:
            updateData['monthlyPrice'] = 10000;
            updateData['productLimit'] = -1; // Illimité
            updateData['commissionRate'] = 0.07;
            updateData['hasAIAgent'] = true;
            updateData['aiModel'] = 'GPT-4';
            updateData['aiMessagesPerDay'] = 200;
            break;
        }
      } else {
        final tier = newTier as LivreurTier;
        switch (tier) {
          case LivreurTier.starter:
            updateData['monthlyPrice'] = 0;
            updateData['commissionRate'] = 0.25;
            updateData['hasPriority'] = false;
            updateData['has24x7Support'] = false;
            updateData['requiredDeliveries'] = 0;
            updateData['requiredRating'] = 0.0;
            break;
          case LivreurTier.pro:
            updateData['monthlyPrice'] = 10000;
            updateData['commissionRate'] = 0.20;
            updateData['hasPriority'] = true;
            updateData['has24x7Support'] = false;
            updateData['requiredDeliveries'] = 50;
            updateData['requiredRating'] = 4.0;
            break;
          case LivreurTier.premium:
            updateData['monthlyPrice'] = 30000;
            updateData['commissionRate'] = 0.15;
            updateData['hasPriority'] = true;
            updateData['has24x7Support'] = true;
            updateData['requiredDeliveries'] = 200;
            updateData['requiredRating'] = 4.5;
            break;
        }
      }

      await FirebaseFirestore.instance
          .collection(collection)
          .doc(subscription.id)
          .update(updateData);

      await _loadSubscriptions();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Plan modifié avec succès'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Erreur changement de plan: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildPlanButton(
    String title,
    String price,
    String features,
    Color color,
    bool isCurrentPlan,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: isCurrentPlan ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isCurrentPlan ? Colors.grey[300] : color,
        foregroundColor: isCurrentPlan ? Colors.grey[700] : Colors.white,
        padding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isCurrentPlan ? BorderSide(color: AppColors.primary, width: 2) : BorderSide.none,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isCurrentPlan)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Actuel',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            price,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            features,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _showChangeTierDialog(Map<String, dynamic> item, bool isVendeur) {
    final subscription = item['subscription'];
    final user = item['user'] as UserModel;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Changer le plan de ${user.displayName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Plan actuel: ${subscription.tierName}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            const Text('Choisir un nouveau plan:'),
            const SizedBox(height: 16),
            if (isVendeur) ...[
              _buildPlanButton(
                'BASIQUE',
                '0 FCFA/mois',
                '20 produits',
                AppColors.success,
                subscription.tierName == 'basique',
                () {
                  Navigator.pop(context);
                  _changeSubscriptionTier(
                    subscription,
                    VendeurSubscriptionTier.basique,
                    true,
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildPlanButton(
                'PRO',
                '5,000 FCFA/mois',
                '100 produits + AI GPT-3.5',
                AppColors.primary,
                subscription.tierName == 'pro',
                () {
                  Navigator.pop(context);
                  _changeSubscriptionTier(
                    subscription,
                    VendeurSubscriptionTier.pro,
                    true,
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildPlanButton(
                'PREMIUM',
                '10,000 FCFA/mois',
                'Illimité + AI GPT-4',
                const Color(0xFFFFD700),
                subscription.tierName == 'premium',
                () {
                  Navigator.pop(context);
                  _changeSubscriptionTier(
                    subscription,
                    VendeurSubscriptionTier.premium,
                    true,
                  );
                },
              ),
            ] else ...[
              _buildPlanButton(
                'STARTER',
                '0 FCFA/mois',
                'Commission 25%',
                AppColors.success,
                subscription.tierName == 'starter',
                () {
                  Navigator.pop(context);
                  _changeSubscriptionTier(
                    subscription,
                    LivreurTier.starter,
                    false,
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildPlanButton(
                'PRO',
                '10,000 FCFA/mois',
                'Commission 20%',
                AppColors.primary,
                subscription.tierName == 'pro',
                () {
                  Navigator.pop(context);
                  _changeSubscriptionTier(
                    subscription,
                    LivreurTier.pro,
                    false,
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildPlanButton(
                'PREMIUM',
                '30,000 FCFA/mois',
                'Commission 15%',
                const Color(0xFFFFD700),
                subscription.tierName == 'premium',
                () {
                  Navigator.pop(context);
                  _changeSubscriptionTier(
                    subscription,
                    LivreurTier.premium,
                    false,
                  );
                },
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(Map<String, dynamic> item, bool isVendeur) {
    final subscription = item['subscription'];
    final user = item['user'] as UserModel;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Icon(
                    isVendeur ? Icons.store : Icons.delivery_dining,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(subscription.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _getStatusColor(subscription.status)),
                  ),
                  child: Text(
                    _getStatusText(subscription.status),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _getStatusColor(subscription.status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Plan',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subscription.tierName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Prix mensuel',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${subscription.monthlyPrice.toStringAsFixed(0)} FCFA',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (!isVendeur) ...[
                  Icon(Icons.local_shipping, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Livraisons: ${subscription.currentDeliveries}/${subscription.requiredDeliveries}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                ] else ...[
                  Icon(Icons.shopping_bag, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Commandes: ${_getVendeurTotalOrders(user)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(width: 16),
                ],
                Icon(Icons.star, size: 16, color: Colors.amber[700]),
                const SizedBox(width: 4),
                Text(
                  isVendeur
                      ? 'Note: ${_getVendeurRating(user)}/5.0'
                      : 'Note: ${subscription.currentRating.toStringAsFixed(1)}/5.0',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showChangeTierDialog(item, isVendeur),
                  icon: const Icon(Icons.upgrade, size: 16),
                  label: const Text('Changer de plan'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  itemBuilder: (context) => [
                    if (subscription.status != SubscriptionStatus.active)
                      const PopupMenuItem(
                        value: 'activate',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, size: 16, color: AppColors.success),
                            SizedBox(width: 8),
                            Text('Activer'),
                          ],
                        ),
                      ),
                    if (subscription.status != SubscriptionStatus.suspended)
                      const PopupMenuItem(
                        value: 'suspend',
                        child: Row(
                          children: [
                            Icon(Icons.block, size: 16, color: AppColors.error),
                            SizedBox(width: 8),
                            Text('Suspendre'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'cancel',
                      child: Row(
                        children: [
                          Icon(Icons.cancel, size: 16, color: AppColors.textSecondary),
                          SizedBox(width: 8),
                          Text('Annuler'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) async {
                    SubscriptionStatus? newStatus;
                    switch (value) {
                      case 'activate':
                        newStatus = SubscriptionStatus.active;
                        break;
                      case 'suspend':
                        newStatus = SubscriptionStatus.suspended;
                        break;
                      case 'cancel':
                        newStatus = SubscriptionStatus.cancelled;
                        break;
                    }
                    if (newStatus != null) {
                      await _updateSubscriptionStatus(subscription, newStatus, isVendeur);
                    }
                  },
                  icon: const Icon(Icons.more_vert),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vendeurCount = _vendeurSubscriptionsWithUser.length;
    final livreurCount = _livreurSubscriptionsWithUser.length;

    return SystemUIScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/admin-dashboard');
            }
          },
          tooltip: 'Retour',
        ),
        title: const Text('Gestion des Abonnements'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'Vendeurs ($vendeurCount)'),
            Tab(text: 'Livreurs ($livreurCount)'),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher par nom, email, plan...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterSubscriptions();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppColors.background,
              ),
              onChanged: (value) {
                setState(() {});
                _filterSubscriptions();
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredSubscriptions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.card_membership_outlined,
                              size: 80,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucun abonnement trouvé',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadSubscriptions,
                        child: ListView.builder(
                          itemCount: _filteredSubscriptions.length,
                          itemBuilder: (context, index) {
                            return _buildSubscriptionCard(
                              _filteredSubscriptions[index],
                              _tabController.index == 0,
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  /// Helper pour extraire totalOrders du profile vendeur
  int _getVendeurTotalOrders(UserModel user) {
    try {
      if (user.profile is Map<String, dynamic>) {
        final profile = user.profile as Map<String, dynamic>;
        final stats = profile['stats'] as Map<String, dynamic>?;
        return stats?['totalOrders'] as int? ?? 0;
      }
      return 0;
    } catch (e) {
      debugPrint('⚠️ Erreur extraction totalOrders: $e');
      return 0;
    }
  }

  /// Helper pour extraire averageRating du profile vendeur
  String _getVendeurRating(UserModel user) {
    try {
      if (user.profile is Map<String, dynamic>) {
        final profile = user.profile as Map<String, dynamic>;
        final stats = profile['stats'] as Map<String, dynamic>?;
        final rating = stats?['averageRating'] as num? ?? 0.0;
        return rating.toStringAsFixed(1);
      }
      return '0.0';
    } catch (e) {
      debugPrint('⚠️ Erreur extraction rating: $e');
      return '0.0';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}

