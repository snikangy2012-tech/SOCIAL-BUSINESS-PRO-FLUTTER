// ===== lib/screens/livreur/livreur_dashboard.dart =====

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:social_business_pro/config/constants.dart';
import '../../providers/auth_provider_firebase.dart' as auth;
import '../../providers/notification_provider.dart';
import '../../services/livreur_stats_service.dart';
import '../../services/review_service.dart';
import '../../utils/number_formatter.dart';
import '../../widgets/system_ui_scaffold.dart';
import '../../widgets/kyc_tier_banner.dart';

class DeliveryDashboard extends StatefulWidget {
  const DeliveryDashboard({super.key});

  @override
  State<DeliveryDashboard> createState() => _DeliveryDashboardState();
}

class _DeliveryDashboardState extends State<DeliveryDashboard> {
  bool _isLoading = true;
  bool _isAvailable = true;
  Timer? _refreshTimer;
  final _refreshInterval = const Duration(minutes: 15); // ✅ Rafraîchir toutes les 15 minutes

  // Stats réelles (initialisées vides)
  Map<String, dynamic> _stats = {
    'todayDeliveries': 0,
    'todayEarnings': 0.0,
    'avgRating': 0.0,
    'totalDeliveries': 0,
    'totalDistance': 0.0,
  };

  // Livraisons récentes (chargées depuis Firestore)
  List<RecentDeliveryData> _recentDeliveries = [];

  @override
  void initState() {
    super.initState();
    debugPrint('🚚 === DeliveryDashboard initState ===');
    _loadDashboard();

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
        debugPrint('🔄 Auto-refresh livreur dashboard');
        _loadDashboard();
      }
    });
  }

  Future<void> _loadDashboard() async {
    debugPrint('🔄 Chargement dashboard livreur');

    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      // Vérifier l'utilisateur
      final authProvider = context.read<auth.AuthProvider>();
      final user = authProvider.user;

      if (user == null || user.userType != UserType.livreur) {
        debugPrint('❌ User null ou pas livreur: ${user?.userType.value}');
        throw Exception('Accès non autorisé');
      }

      debugPrint('✅ User validé: ${user.displayName} (livreur)');

      // ✅ Charger les statistiques réelles depuis Firestore
      debugPrint('📊 Chargement statistiques livreur...');
      final livreurStats = await LivreurStatsService.getLivreurStats(user.id);

      // ✅ Charger les livraisons récentes
      debugPrint('📋 Chargement livraisons récentes...');
      final recentDeliveries = await LivreurStatsService.getRecentDeliveries(user.id, limit: 5);

      // ✅ Charger la note moyenne
      debugPrint('⭐ Chargement note moyenne...');
      double avgRating = 0.0;
      try {
        final reviewService = ReviewService();
        avgRating = await reviewService.getAverageRating(user.id, 'livreur');
      } catch (e) {
        debugPrint('⚠️ Erreur chargement note: $e');
      }

      // ✅ Mettre à jour l'état avec les vraies données
      if (mounted) {
        setState(() {
          _stats = {
            'todayDeliveries': livreurStats.deliveredDeliveries,
            'todayEarnings': livreurStats.todayEarnings,
            'avgRating': avgRating,
            'totalDeliveries': livreurStats.totalDeliveries,
            'totalDistance': 0.0, // TODO: Calculer distance totale
          };
          _recentDeliveries = recentDeliveries;
        });
      }

      debugPrint('✅ Dashboard livreur chargé avec succès');
      debugPrint(
          '📊 Stats: ${_stats['todayDeliveries']} livraisons, ${_stats['todayEarnings']} FCFA, Note: ${_stats['avgRating']}');
    } catch (e) {
      debugPrint('❌ Erreur chargement dashboard: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<auth.AuthProvider>();
    final user = authProvider.user;

    // Vérification sécurité
    if (user == null || user.userType != UserType.livreur) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          debugPrint('❌ Accès refusé - Redirection vers /');
          context.go('/');
        }
      });

      return SystemUIScaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_isLoading) {
      return SystemUIScaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)],
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 16),
                Text(
                  'Chargement...',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SystemUIScaffold(
      appBar: AppBar(
        title: const Text('Dashboard Livreur'),
        backgroundColor: AppColors.primary,
        actions: [
          // ✅ Bouton Accueil
          IconButton(
            icon: const Icon(Icons.home_outlined),
            tooltip: 'Accueil',
            onPressed: () {
              // Retour à l'accueil acheteur
              context.go('/');
            },
          ),

          // Bouton notifications avec badge
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              final unreadCount = notificationProvider.unreadCount;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () => context.push('/notifications'),
                    tooltip: 'Notifications',
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ✨ Bannière KYC adaptative
            KYCTierBanner(userId: user.id),

            // Switch Disponibilité
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            (_isAvailable ? AppColors.success : Colors.grey).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _isAvailable ? Icons.check_circle : Icons.cancel,
                        color: _isAvailable ? AppColors.success : Colors.grey,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Statut de disponibilité',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isAvailable ? 'Vous recevez des demandes' : 'Vous êtes hors ligne',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isAvailable,
                      onChanged: (value) {
                        setState(() => _isAvailable = value);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              value
                                  ? 'Vous êtes maintenant disponible'
                                  : 'Vous êtes maintenant hors ligne',
                            ),
                            backgroundColor: value ? AppColors.success : Colors.grey,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      activeThumbColor: AppColors.success,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Bouton Commandes Disponibles
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/livreur/available-orders'),
                icon: const Icon(Icons.search, size: 28),
                label: const Text(
                  'Commandes disponibles',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Statistiques du jour
            const Text(
              'Aujourd\'hui',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            // 💳 Bouton Dépôt Paiements
            Card(
              elevation: 2,
              child: InkWell(
                onTap: () => context.go('/livreur/payment-deposit'),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet,
                          color: AppColors.success,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Effectuer un dépôt',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Reverser les montants collectés',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.grey,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              padding: EdgeInsets.zero,
              children: [
                _buildStatCard(
                  'Livraisons',
                  '${_stats['todayDeliveries']}',
                  Icons.delivery_dining,
                  AppColors.primary,
                ),
                _buildStatCard(
                  'Gains',
                  '${_stats['todayEarnings']} F',
                  Icons.payments,
                  AppColors.success,
                ),
                _buildStatCard(
                  'Distance',
                  '${_stats['totalDistance']} km',
                  Icons.map,
                  AppColors.info,
                ),
                _buildStatCard(
                  'Note',
                  '${_stats['avgRating']}/5',
                  Icons.star,
                  AppColors.warning,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Livraisons récentes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Livraisons récentes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_recentDeliveries.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_recentDeliveries.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Liste des livraisons
            if (!_isAvailable)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.notifications_off,
                        size: 64,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Vous êtes hors ligne',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Activez votre disponibilité pour recevoir des livraisons',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else if (_recentDeliveries.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 80,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Aucune livraison récente',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Dès que vous effectuerez des livraisons, elles apparaîtront ici.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppColors.info,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Restez disponible pour recevoir des commandes',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.info,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._recentDeliveries.map((delivery) {
                return _buildRecentDeliveryCard(delivery);
              }),
          ],
        ),
      ),
    );
  }

  // Carte de statistique
  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Carte de livraison récente
  Widget _buildRecentDeliveryCard(RecentDeliveryData delivery) {
    // Déterminer la couleur selon le statut
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (delivery.status.toLowerCase()) {
      case 'pending':
        statusColor = AppColors.warning;
        statusIcon = Icons.hourglass_empty;
        statusText = 'En attente';
        break;
      case 'picked_up':
        statusColor = AppColors.info;
        statusIcon = Icons.inventory;
        statusText = 'Récupéré';
        break;
      case 'in_progress':
        statusColor = AppColors.primary;
        statusIcon = Icons.local_shipping;
        statusText = 'En cours';
        break;
      case 'delivered':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
        statusText = 'Livré';
        break;
      case 'cancelled':
        statusColor = AppColors.error;
        statusIcon = Icons.cancel;
        statusText = 'Annulé';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
        statusText = 'Inconnu';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          context.push('/livreur/delivery-detail/${delivery.id}');
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec badge statut
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.delivery_dining,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                formatDeliveryNumber(delivery.id),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                delivery.customerName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusIcon,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const Divider(height: 24),

              // Montant et date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.payments,
                        size: 16,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        formatPriceWithCurrency(delivery.amount, currency: 'FCFA'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${delivery.date.day}/${delivery.date.month}/${delivery.date.year}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Bouton voir détails
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    context.push('/livreur/delivery-detail/${delivery.id}');
                  },
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('Voir détails'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
