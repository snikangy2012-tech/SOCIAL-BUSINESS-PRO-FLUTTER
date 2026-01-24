// ===== lib/screens/admin/admin_dashboard.dart =====
// Dashboard administrateur moderne avec design professionnel

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:social_business_pro/config/constants.dart';
import '../../providers/auth_provider_firebase.dart' as auth;
import '../../providers/notification_provider.dart';
import '../../widgets/system_ui_scaffold.dart';
import '../../widgets/admin_drawer.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  Timer? _refreshTimer;
  final _refreshInterval = const Duration(minutes: 5);
  bool _isLoading = true;

  // Statistiques
  Map<String, int> _stats = {
    'vendeurs': 0,
    'acheteurs': 0,
    'livreurs': 0,
    'commandes': 0,
    'commandesEnCours': 0,
    'kycPending': 0,
    'produitsActifs': 0,
  };

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });

    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(_refreshInterval, (timer) {
      if (mounted) {
        _loadDashboardData();
      }
    });
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final stats = await _fetchStatistics();

      if (!mounted) return;

      setState(() {
        _stats = stats;
        _isLoading = false;
      });

      _animationController.forward(from: 0);
    } catch (e) {
      debugPrint('❌ Erreur chargement dashboard: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<Map<String, int>> _fetchStatistics() async {
    try {
      // Compter les vendeurs
      final vendeursSnapshot = await FirebaseFirestore.instance
          .collection(FirebaseCollections.users)
          .where('userType', isEqualTo: 'vendeur')
          .count()
          .get();

      // Compter les acheteurs
      final acheteursSnapshot = await FirebaseFirestore.instance
          .collection(FirebaseCollections.users)
          .where('userType', isEqualTo: 'acheteur')
          .count()
          .get();

      // Compter les livreurs
      final livreursSnapshot = await FirebaseFirestore.instance
          .collection(FirebaseCollections.users)
          .where('userType', isEqualTo: 'livreur')
          .count()
          .get();

      // Compter les commandes
      final commandesSnapshot =
          await FirebaseFirestore.instance.collection(FirebaseCollections.orders).count().get();

      // Compter les commandes en cours
      final commandesEnCoursSnapshot = await FirebaseFirestore.instance
          .collection(FirebaseCollections.orders)
          .where('status', whereIn: ['en_attente', 'en_cours']).count()
          .get();

      // Compter les produits actifs
      final produitsSnapshot = await FirebaseFirestore.instance
          .collection(FirebaseCollections.products)
          .where('isActive', isEqualTo: true)
          .count()
          .get();

      // Compter les KYC en attente
      int kycPending = 0;
      try {
        final vendeurKycSnapshot = await FirebaseFirestore.instance
            .collection(FirebaseCollections.users)
            .where('userType', isEqualTo: 'vendeur')
            .get();

        for (var doc in vendeurKycSnapshot.docs) {
          final kycStatus = doc.data()['kycVerificationStatus'] as String?;
          if (kycStatus == 'pending') kycPending++;
        }

        final livreurKycSnapshot = await FirebaseFirestore.instance
            .collection(FirebaseCollections.users)
            .where('userType', isEqualTo: 'livreur')
            .get();

        for (var doc in livreurKycSnapshot.docs) {
          final kycStatus = doc.data()['kycVerificationStatus'] as String?;
          if (kycStatus == 'pending') kycPending++;
        }
      } catch (e) {
        debugPrint('⚠️ Erreur comptage KYC: $e');
      }

      return {
        'vendeurs': vendeursSnapshot.count ?? 0,
        'acheteurs': acheteursSnapshot.count ?? 0,
        'livreurs': livreursSnapshot.count ?? 0,
        'commandes': commandesSnapshot.count ?? 0,
        'commandesEnCours': commandesEnCoursSnapshot.count ?? 0,
        'kycPending': kycPending,
        'produitsActifs': produitsSnapshot.count ?? 0,
      };
    } catch (e) {
      debugPrint('❌ Erreur récupération stats: $e');
      return {
        'vendeurs': 0,
        'acheteurs': 0,
        'livreurs': 0,
        'commandes': 0,
        'commandesEnCours': 0,
        'kycPending': 0,
        'produitsActifs': 0,
      };
    }
  }

  Future<void> _handleRefresh() async {
    await _loadDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SystemUIScaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.warning,
                AppColors.warning.withValues(alpha: 0.7),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
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
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.warning),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Chargement du tableau de bord...',
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        // Le bouton retour Android reste sur le dashboard admin
        // On ne fait rien pour éviter de sortir accidentellement
      },
      child: SystemUIScaffold(
        drawer: const AdminDrawer(),
        body: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: AppColors.warning,
          child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header moderne avec gradient
            SliverAppBar(
              expandedHeight: 220,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: AppColors.warning,
              leading: Builder(
                builder: (BuildContext scaffoldContext) {
                  return IconButton(
                    icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 28),
                    onPressed: () => Scaffold.of(scaffoldContext).openDrawer(),
                    tooltip: 'Menu',
                    splashRadius: 24,
                  );
                },
              ),
              actions: [
                // Notifications avec badge
                Consumer<NotificationProvider>(
                  builder: (context, notificationProvider, child) {
                    final unreadCount = notificationProvider.unreadCount;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
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
                // Photo de profil
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Consumer<auth.AuthProvider>(
                    builder: (context, authProvider, child) {
                      final user = authProvider.user;
                      return GestureDetector(
                        onTap: () => context.push('/admin/profile'),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.white,
                          backgroundImage: user?.profile['photoURL'] != null
                              ? NetworkImage(user!.profile['photoURL'])
                              : null,
                          child: user?.profile['photoURL'] == null
                              ? Text(
                                  user?.displayName.isNotEmpty == true
                                      ? user!.displayName[0].toUpperCase()
                                      : 'A',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.warning,
                                  ),
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.warning,
                        AppColors.warning.withValues(alpha: 0.85),
                        const Color(0xFFf59e0b),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.admin_panel_settings_rounded,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Panneau Administrateur',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Consumer<auth.AuthProvider>(
                                      builder: (context, authProvider, _) {
                                        return Text(
                                          'Bienvenue, ${authProvider.user?.displayName ?? 'Admin'} 👋',
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.95),
                                            fontSize: 15,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Contenu
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Alertes KYC si nécessaire
                      if (_stats['kycPending']! > 0) ...[
                        _buildKYCAlert(),
                        const SizedBox(height: 20),
                      ],

                      // Vue d'ensemble - Statistiques utilisateurs
                      _buildSectionHeader('Vue d\'ensemble', Icons.dashboard_rounded),
                      const SizedBox(height: 16),
                      _buildUserStatsGrid(),

                      const SizedBox(height: 28),

                      // Activité - Commandes et produits
                      _buildSectionHeader('Activité de la plateforme', Icons.trending_up_rounded),
                      const SizedBox(height: 16),
                      _buildActivityStats(),

                      const SizedBox(height: 28),

                      // Actions rapides
                      _buildSectionHeader('Actions rapides', Icons.flash_on_rounded),
                      const SizedBox(height: 16),
                      _buildQuickActions(),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.warning, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildKYCAlert() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.warning.withValues(alpha: 0.1),
            AppColors.warning.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.priority_high_rounded, color: AppColors.warning, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vérifications KYC en attente',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_stats['kycPending']} demande(s) nécessitent votre attention',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => context.push('/admin/kyc-verification'),
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
            tooltip: 'Voir les demandes',
          ),
        ],
      ),
    );
  }

  Widget _buildUserStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5, // Augmenté de 1.4 à 1.5 pour éviter l'overflow
      children: [
        _buildModernStatCard(
          title: 'Vendeurs',
          value: _stats['vendeurs'].toString(),
          icon: Icons.store_rounded,
          color: AppColors.primary,
          onTap: () => context.push('/admin/vendor-management'),
        ),
        _buildModernStatCard(
          title: 'Acheteurs',
          value: _stats['acheteurs'].toString(),
          icon: Icons.shopping_bag_rounded,
          color: AppColors.success,
          onTap: () => context.push('/admin/user-management'),
        ),
        _buildModernStatCard(
          title: 'Livreurs',
          value: _stats['livreurs'].toString(),
          icon: Icons.delivery_dining_rounded,
          color: AppColors.info,
          onTap: () => context.push('/admin/livreur-management'),
        ),
        _buildModernStatCard(
          title: 'Produits actifs',
          value: _stats['produitsActifs'].toString(),
          icon: Icons.inventory_2_rounded,
          color: AppColors.secondary,
          onTap: () => context.push('/admin/product-management'),
        ),
      ],
    );
  }

  Widget _buildActivityStats() {
    return Row(
      children: [
        Expanded(
          child: _buildActivityCard(
            title: 'Commandes totales',
            value: _stats['commandes'].toString(),
            icon: Icons.receipt_long_rounded,
            color: const Color(0xFF6366f1),
            onTap: () => context.push('/admin/order-management'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActivityCard(
            title: 'En cours',
            value: _stats['commandesEnCours'].toString(),
            icon: Icons.pending_actions_rounded,
            color: AppColors.warning,
            onTap: () => context.push('/admin/order-management'),
          ),
        ),
      ],
    );
  }

  Widget _buildModernStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
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
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                if (onTap != null)
                  Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey[400]),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color,
              color.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final authProvider = context.watch<auth.AuthProvider>();
    final isSuperAdmin = authProvider.user?.isSuperAdmin ?? false;

    return Column(
      children: [
        _buildQuickActionCard(
          icon: Icons.verified_user_rounded,
          title: 'Gestion KYC',
          subtitle: 'Vérifier les documents KYC',
          color: AppColors.success,
          onTap: () => context.push('/admin/kyc-verification'),
        ),
        const SizedBox(height: 12),
        _buildQuickActionCard(
          icon: Icons.category_rounded,
          title: 'Gestion Catégories',
          subtitle: 'Gérer les catégories de produits',
          color: AppColors.secondary,
          onTap: () => context.go('/admin/categories-management'),
        ),
        const SizedBox(height: 12),
        _buildQuickActionCard(
          icon: Icons.security_rounded,
          title: 'Logs d\'Audit',
          subtitle: 'Consulter l\'historique des actions',
          color: AppColors.info,
          onTap: () => context.push('/admin/audit-logs'),
        ),
        if (isSuperAdmin) ...[
          const SizedBox(height: 12),
          _buildQuickActionCard(
            icon: Icons.assessment_rounded,
            title: 'Rapports Globaux',
            subtitle: 'Statistiques et analyses détaillées',
            color: AppColors.primary,
            onTap: () => context.push('/admin/reports'),
          ),
        ],
        const SizedBox(height: 12),
        _buildQuickActionCard(
          icon: Icons.settings_rounded,
          title: 'Paramètres',
          subtitle: 'Configuration de la plateforme',
          color: Colors.grey[700]!,
          onTap: () => context.push('/admin/settings'),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
