// ===== lib/screens/vendeur/vendeur_dashboard.dart =====
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:provider/provider.dart';

import 'package:social_business_pro/config/constants.dart';
import '../../providers/auth_provider_firebase.dart' as auth;
import '../../providers/vendeur_navigation_provider.dart';
import '../../providers/notification_provider.dart';
import '../../services/review_service.dart';
import '../../services/vendor_stats_service.dart';
import '../../utils/order_status_helper.dart';
import '../../utils/number_formatter.dart';
import '../../widgets/system_ui_scaffold.dart';

class VendeurDashboard extends StatefulWidget {
  const VendeurDashboard({super.key});

  @override
  State<VendeurDashboard> createState() => _VendeurDashboardState();
}

class _VendeurDashboardState extends State<VendeurDashboard> {
  bool _isLoading = true;
  Timer? _refreshTimer;
  final _refreshInterval = const Duration(minutes: 15); // ✅ Rafraîchir toutes les 15 minutes

  // Données du dashboard
  DashboardStats _stats = DashboardStats();
  List<RecentOrderData> _recentOrders = []; // ✅ Utilise RecentOrderData du service

  @override
  void initState() {
    super.initState();
    debugPrint('🚀 === VendeurDashboard initState ===');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('📄 PostFrameCallback - Démarrage chargement');
      _loadDashboardData();
    });

    // 🔄 Démarrer le rafraîchissement automatique
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Intentionnellement vide
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(_refreshInterval, (timer) {
      if (mounted) {
        debugPrint('🔄 Auto-refresh vendeur dashboard');
        _loadDashboardData();
      }
    });
  }

  Future<void> _loadDashboardData() async {
    debugPrint('📊 === DÉBUT CHARGEMENT DASHBOARD ===');

    if (!mounted) {
      debugPrint('❌ Widget non monté, abandon');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<auth.AuthProvider>();
      final user = authProvider.user;

      debugPrint('👤 User: ${user?.displayName}');
      debugPrint('📋 UserType: ${user?.userType.value}');

      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      if (user.userType != UserType.vendeur) {
        debugPrint('❌ Type incorrect: ${user.userType.value}');
        throw Exception('Accès non autorisé');
      }

      debugPrint('✅ Utilisateur validé');
      debugPrint('📊 Chargement données réelles...');

      // ✅ Charger les statistiques réelles depuis Firestore
      final vendorStats = await VendorStatsService.getVendorStats(user.id);
      debugPrint('✅ Statistiques chargées');

      // ✅ Charger les commandes récentes réelles
      final recentOrders = await VendorStatsService.getRecentOrders(user.id, limit: 5);
      debugPrint('✅ Commandes récentes chargées');

      // Charger la note moyenne réelle depuis ReviewService
      final reviewService = ReviewService();
      double avgRating = 0.0;
      try {
        avgRating = await reviewService.getAverageRating(user.id, 'vendor');
        debugPrint('⭐ Note moyenne chargée: $avgRating');
      } catch (e) {
        debugPrint('⚠️ Erreur chargement note: $e');
      }

      if (!mounted) {
        debugPrint('❌ Widget démonté pendant le chargement');
        return;
      }

      // ✅ Utiliser les données réelles
      setState(() {
        _stats = DashboardStats(
          totalSales: vendorStats.deliveredOrders,
          monthlyRevenue: vendorStats.monthlyRevenue,
          totalOrders: vendorStats.totalOrders,
          pendingOrders: vendorStats.pendingOrders,
          completedOrders: vendorStats.completedOrders,
          totalProducts: vendorStats.totalProducts,
          activeProducts: vendorStats.activeProducts,
          viewsThisMonth: vendorStats.viewsThisMonth,
          averageRating: avgRating,
          responseTime: '2h', // TODO: Calculer le temps de réponse réel
        );

        _recentOrders = recentOrders;
      });

      debugPrint('✅ Données chargées avec succès');
    } catch (e) {
      debugPrint('❌ Erreur chargement: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      debugPrint('🏁 Arrêt du loading');
      if (mounted) {
        setState(() => _isLoading = false);
      }
      debugPrint('✅ Loading arrêté - _isLoading = false');
      debugPrint('🎯 === FIN CHARGEMENT DASHBOARD ===\n');
    }
  }

  Future<void> _handleRefresh() async {
    debugPrint('🔄 Refresh dashboard');
    await _loadDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    // Écran de chargement
    if (_isLoading) {
      return SystemUIScaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primary.withValues(alpha: 0.7),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const CircularProgressIndicator(
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Chargement du dashboard...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Dashboard
    return SystemUIScaffold(
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header avec gradient
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: AppColors.primary,
              actions: [
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
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary,
                        AppColors.secondary,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Ma Boutique',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Bienvenue ! 👋',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Contenu
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Revenus du mois
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.success,
                            AppColors.success.withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.success.withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Revenus du mois',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  formatPriceWithCurrency(_stats.monthlyRevenue, currency: 'FCFA'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.trending_up,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 💳 Bouton Paiement Commissions
                    Card(
                      elevation: 2,
                      child: InkWell(
                        onTap: () => context.go('/vendeur/commission-payment'),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.payment,
                                  color: AppColors.primary,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Payer mes commissions',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Effectuer un versement Mobile Money',
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

                    const SizedBox(height: 24),

                    // Statistiques
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.5,
                      children: [
                        _buildStatCard(
                          'Commandes',
                          '${_stats.totalOrders}',
                          Icons.shopping_cart_outlined,
                          AppColors.primary,
                        ),
                        _buildStatCard(
                          'Produits actifs',
                          '${_stats.activeProducts}/${_stats.totalProducts}',
                          Icons.inventory_2_outlined,
                          AppColors.info,
                        ),
                        _buildStatCard(
                          'Note moyenne',
                          '${_stats.averageRating}/5',
                          Icons.star_outline,
                          AppColors.warning,
                        ),
                        _buildStatCard(
                          'Vues',
                          '${_stats.viewsThisMonth}',
                          Icons.visibility_outlined,
                          AppColors.secondary,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Commandes récentes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Commandes récentes',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            context.read<VendeurNavigationProvider>().goToOrders();
                          },
                          child: const Text('Voir tout'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ✅ VÉRIFIER SI VIDE
                    _recentOrders.isEmpty
                        ? Card(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.shopping_cart_outlined,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Aucune commande récente',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Column(
                            children: _recentOrders.map((order) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(order.status).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.shopping_bag_outlined,
                                      color: _getStatusColor(order.status),
                                    ),
                                  ),
                                  title: Text(
                                    order.customerName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text('Commande ${order.displayNumber}'),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        formatPriceWithCurrency(order.amount, currency: 'FCFA'),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.right,
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              _getStatusColor(order.status).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          _getStatusLabel(order.status),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: _getStatusColor(order.status),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    context.read<VendeurNavigationProvider>().goToOrders();
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Carte de statistique
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return InkWell(
      onTap: () {
        final navProvider = context.read<VendeurNavigationProvider>();

        if (title.contains('Commandes')) {
          navProvider.goToOrders();
        } else if (title.contains('Produits') || title.contains('actifs')) {
          navProvider.goToProducts();
        } else if (title.contains('Note')) {
          // Navigation vers l'écran des avis
          context.push('/vendeur/reviews');
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helpers
  Color _getStatusColor(String status) {
    return OrderStatusHelper.getStatusColor(status);
  }

  String _getStatusLabel(String status) {
    return OrderStatusHelper.getStatusLabel(status);
  }
}

// Classes de données
class DashboardStats {
  final int totalSales;
  final num monthlyRevenue;
  final int totalOrders;
  final int pendingOrders;
  final int completedOrders;
  final int totalProducts;
  final int activeProducts;
  final int viewsThisMonth;
  final double averageRating;
  final String responseTime;

  DashboardStats({
    this.totalSales = 0,
    this.monthlyRevenue = 0,
    this.totalOrders = 0,
    this.pendingOrders = 0,
    this.completedOrders = 0,
    this.totalProducts = 0,
    this.activeProducts = 0,
    this.viewsThisMonth = 0,
    this.averageRating = 0.0,
    this.responseTime = '0h',
  });
}

// ✅ RecentOrder supprimé - on utilise maintenant RecentOrderData du VendorStatsService
