// ===== lib/screens/admin/admin_dashboard.dart =====
// Dashboard administrateur avec gestion de tous les profils

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:social_business_pro/config/constants.dart';
import 'package:social_business_pro/utils/create_test_activities.dart';
import 'package:social_business_pro/screens/admin/admin_management_screen.dart';
import 'package:social_business_pro/screens/admin/audit_logs_screen.dart';
import 'package:social_business_pro/screens/admin/global_reports_screen.dart';
import '../../providers/auth_provider_firebase.dart' as auth;
import '../../providers/notification_provider.dart';
import '../../widgets/custom_widgets.dart';
import '../../widgets/system_ui_scaffold.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  Timer? _refreshTimer;
  final _refreshInterval = const Duration(seconds: 30); // Rafraîchir toutes les 30 secondes

  Future<void> _createFirestoreProfileIfNeeded() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !kIsWeb) return; // Seulement sur Web

    try {
      // Vérifier si le profil existe
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (!doc.exists) {
        debugPrint('📝 Création profil Admin Firestore...');

        // Créer le profil Admin Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName,
          'userType': 'admin',
          'isVerified': true, // ✅ Admin vérifié par défaut
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
          'profile': {
            'role': 'admin',
            'permissions': ['all'], // ✅ Toutes les permissions
            'department': 'Administration',
          },
        }, SetOptions(merge: true));

        debugPrint('✅ Profil Admin créé avec succès');
      }
    } catch (e) {
      debugPrint('⚠️ Erreur création profil Admin: $e');
      // Pas grave, on réessaiera plus tard
    }
  }

  @override
  void initState() {
    super.initState();

    // ✅ Créer le profil Firestore après 3 secondes (non bloquant)
    if (kIsWeb) {
      Future.delayed(const Duration(seconds: 3), _createFirestoreProfileIfNeeded);
    }

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
        setState(() {
          // Force le rebuild pour rafraîchir les StreamBuilders
          debugPrint('🔄 Auto-refresh admin dashboard');
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SystemUIScaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        title: const Text('Administration'),
        backgroundColor: AppColors.warning,
        foregroundColor: Colors.white,
        elevation: 2,
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête de bienvenue
            _buildWelcomeHeader(),

            const SizedBox(height: AppSpacing.xl),

            // Statistiques rapides
            _buildQuickStats(),

            const SizedBox(height: AppSpacing.xl),

            // Activités récentes
            _buildRecentActivities(),

            const SizedBox(height: AppSpacing.xl),

            // Actions rapides admin
            _buildQuickActionsSection(),
          ],
        ),
      ),
    );
  }

  // En-tête de bienvenue
  Widget _buildWelcomeHeader() {
    return Consumer<auth.AuthProvider>(
      builder: (context, authProvider, _) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.warning, Color(0xFFf59e0b)],
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings,
                      size: 30,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bienvenue ${authProvider.user?.displayName ?? 'Admin'}',
                          style: const TextStyle(
                            fontSize: AppFontSizes.xl,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          'Tableau de bord administrateur',
                          style: TextStyle(
                            fontSize: AppFontSizes.md,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Gérez tous les aspects de la plateforme SOCIAL BUSINESS Pro',
                style: TextStyle(
                  fontSize: AppFontSizes.sm,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Statistiques rapides avec données réelles
  Widget _buildQuickStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statistiques de la plateforme',
          style: TextStyle(
            fontSize: AppFontSizes.lg,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        StreamBuilder<Map<String, int>>(
          stream: _getStatisticsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final stats = snapshot.data ??
                {
                  'vendeurs': 0,
                  'acheteurs': 0,
                  'livreurs': 0,
                  'commandes': 0,
                  'kycPending': 0,
                };

            final kycPending = stats['kycPending'] as int? ?? 0;

            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 1.5,
              children: [
                // Carte Vendeurs - Cliquable
                GestureDetector(
                  onTap: () => context.push('/admin/vendor-management'),
                  child: _StatCard(
                    title: 'Vendeurs',
                    value: stats['vendeurs'].toString(),
                    icon: Icons.store,
                    color: AppColors.primary,
                    trend: '+12%',
                  ),
                ),
                // Carte Acheteurs - Cliquable
                GestureDetector(
                  onTap: () => context.push('/admin/user-management'),
                  child: _StatCard(
                    title: 'Acheteurs',
                    value: stats['acheteurs'].toString(),
                    icon: Icons.shopping_bag,
                    color: AppColors.secondary,
                    trend: '+8%',
                  ),
                ),
                // Carte Livreurs - Cliquable
                GestureDetector(
                  onTap: () => context.push('/admin/livreur-management'),
                  child: _StatCard(
                    title: 'Livreurs',
                    value: stats['livreurs'].toString(),
                    icon: Icons.delivery_dining,
                    color: AppColors.success,
                    trend: '+15%',
                  ),
                ),
                // Carte Commandes - Non cliquable pour l'instant (pas d'écran dédié)
                _StatCard(
                  title: 'Commandes',
                  value: stats['commandes'].toString(),
                  icon: Icons.receipt_long,
                  color: AppColors.info,
                  trend: '+23%',
                ),
                // Carte KYC - Cliquable si en attente
                GestureDetector(
                  onTap: kycPending > 0 ? () => context.go('/admin/kyc-verification') : null,
                  child: _StatCard(
                    title: 'KYC à vérifier',
                    value: kycPending.toString(),
                    icon: Icons.verified_user,
                    color: kycPending > 0 ? AppColors.warning : AppColors.success,
                    trend: kycPending > 0 ? 'Action requise' : 'À jour',
                    isAlert: kycPending > 0,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  // Stream pour récupérer les statistiques en temps réel
  Stream<Map<String, int>> _getStatisticsStream() async* {
    // Émettre les stats initiales immédiatement
    yield await _fetchStatistics();

    // Puis continuer avec un rafraîchissement périodique
    await for (final _ in Stream.periodic(const Duration(seconds: 30))) {
      yield await _fetchStatistics();
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

      // Compter les KYC en attente (vendeurs et livreurs)
      int kycPending = 0;
      try {
        // KYC vendeurs en attente
        final vendeurKycSnapshot = await FirebaseFirestore.instance
            .collection(FirebaseCollections.users)
            .where('userType', isEqualTo: 'vendeur')
            .get();

        for (var doc in vendeurKycSnapshot.docs) {
          final kycStatus = doc.data()['kycVerificationStatus'] as String?;
          if (kycStatus == 'pending') {
            kycPending++;
          }
        }

        // KYC livreurs en attente
        final livreurKycSnapshot = await FirebaseFirestore.instance
            .collection(FirebaseCollections.users)
            .where('userType', isEqualTo: 'livreur')
            .get();

        for (var doc in livreurKycSnapshot.docs) {
          final kycStatus = doc.data()['kycVerificationStatus'] as String?;
          if (kycStatus == 'pending') {
            kycPending++;
          }
        }
      } catch (e) {
        debugPrint('⚠️ Erreur comptage KYC: $e');
      }

      return {
        'vendeurs': vendeursSnapshot.count ?? 0,
        'acheteurs': acheteursSnapshot.count ?? 0,
        'livreurs': livreursSnapshot.count ?? 0,
        'commandes': commandesSnapshot.count ?? 0,
        'kycPending': kycPending,
      };
    } catch (e) {
      debugPrint('❌ Erreur récupération stats: $e');
      return {
        'vendeurs': 0,
        'acheteurs': 0,
        'livreurs': 0,
        'commandes': 0,
        'kycPending': 0,
      };
    }
  }

  // Activités récentes avec alertes importantes
  Widget _buildRecentActivities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Activités récentes',
          style: TextStyle(
            fontSize: AppFontSizes.lg,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        StreamBuilder<Map<String, dynamic>>(
          stream: _getRecentActivitiesStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final activities = snapshot.data ?? {};
            final pendingVendors = activities['pendingVendors'] ?? 0;
            final pendingLivreurs = activities['pendingLivreurs'] ?? 0;
            final suspendedUsers = activities['suspendedUsers'] ?? 0;
            final recentOrders = activities['recentOrders'] ?? 0;
            final activeSubscriptions = activities['activeSubscriptions'] ?? 0;
            final expiredSubscriptions = activities['expiredSubscriptions'] ?? 0;
            final kycVendeursPending = activities['kycVendeursPending'] ?? 0;
            final kycLivreursPending = activities['kycLivreursPending'] ?? 0;
            final totalKycPending = kycVendeursPending + kycLivreursPending;

            return Column(
              children: [
                // Alertes KYC (priorité haute)
                if (totalKycPending > 0)
                  _buildAlertCard(
                    title: 'Vérifications KYC en attente',
                    items: [
                      if (kycVendeursPending > 0)
                        _AlertItem(
                          icon: Icons.store_outlined,
                          label: '$kycVendeursPending KYC vendeur(s) à vérifier',
                          color: AppColors.warning,
                          onTap: () => context.go('/admin/kyc-verification'),
                        ),
                      if (kycLivreursPending > 0)
                        _AlertItem(
                          icon: Icons.delivery_dining_outlined,
                          label: '$kycLivreursPending KYC livreur(s) à vérifier',
                          color: AppColors.warning,
                          onTap: () => context.go('/admin/kyc-verification'),
                        ),
                    ],
                  ),

                if (totalKycPending > 0) const SizedBox(height: AppSpacing.sm),

                // Alertes urgentes (en attente d'approbation)
                if (pendingVendors > 0 || pendingLivreurs > 0)
                  _buildAlertCard(
                    title: 'Approbations en attente',
                    items: [
                      if (pendingVendors > 0)
                        _AlertItem(
                          icon: Icons.store,
                          label: '$pendingVendors vendeur(s) en attente',
                          color: AppColors.warning,
                          onTap: () => context.go('/admin/vendors'),
                        ),
                      if (pendingLivreurs > 0)
                        _AlertItem(
                          icon: Icons.delivery_dining,
                          label: '$pendingLivreurs livreur(s) en attente',
                          color: AppColors.warning,
                          onTap: () => context.go('/admin/livreurs'),
                        ),
                    ],
                  ),

                const SizedBox(height: AppSpacing.sm),

                // Utilisateurs suspendus
                if (suspendedUsers > 0)
                  _buildAlertCard(
                    title: 'Utilisateurs suspendus',
                    items: [
                      _AlertItem(
                        icon: Icons.block,
                        label: '$suspendedUsers utilisateur(s) suspendu(s)',
                        color: AppColors.error,
                        onTap: () => context.push('/admin/suspended-users'),
                      ),
                    ],
                  ),

                const SizedBox(height: AppSpacing.sm),

                // Abonnements expirés
                if (expiredSubscriptions > 0)
                  _buildAlertCard(
                    title: 'Abonnements expirés',
                    items: [
                      _AlertItem(
                        icon: Icons.card_membership,
                        label: '$expiredSubscriptions abonnement(s) expiré(s)',
                        color: AppColors.error,
                        onTap: () => context.go('/admin/subscription-management'),
                      ),
                    ],
                  ),

                const SizedBox(height: AppSpacing.sm),

                // Informations générales
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline, color: AppColors.info, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Informations générales',
                              style: TextStyle(
                                fontSize: AppFontSizes.md,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _buildInfoRow(
                          Icons.receipt_long,
                          'Commandes récentes (7j)',
                          recentOrders.toString(),
                          AppColors.info,
                        ),
                        const Divider(height: 16),
                        _buildInfoRow(
                          Icons.verified,
                          'Abonnements actifs',
                          activeSubscriptions.toString(),
                          AppColors.success,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  // Card d'alerte avec liste d'items
  Widget _buildAlertCard({
    required String title,
    required List<_AlertItem> items,
  }) {
    return Card(
      color: AppColors.warning.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber, color: AppColors.warning, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: AppFontSizes.md,
                    fontWeight: FontWeight.bold,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ...items.map((item) => InkWell(
                  onTap: item.onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(item.icon, color: item.color, size: 18),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.label,
                            style: const TextStyle(fontSize: AppFontSizes.sm),
                          ),
                        ),
                        const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  // Ligne d'information
  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: AppFontSizes.sm),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: AppFontSizes.sm,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  // Stream pour récupérer les activités récentes
  Stream<Map<String, dynamic>> _getRecentActivitiesStream() async* {
    // Émettre les activités initiales immédiatement
    yield await _fetchRecentActivities();

    // Puis continuer avec un rafraîchissement périodique
    await for (final _ in Stream.periodic(const Duration(seconds: 30))) {
      yield await _fetchRecentActivities();
    }
  }

  Future<Map<String, dynamic>> _fetchRecentActivities() async {
    try {
      // Vendeurs en attente
      final pendingVendorsSnapshot = await FirebaseFirestore.instance
          .collection(FirebaseCollections.users)
          .where('userType', isEqualTo: 'vendeur')
          .get();

      final pendingVendors = pendingVendorsSnapshot.docs.where((doc) {
        final status = doc.data()['profile']?['status'] as String?;
        return status?.toLowerCase() == 'pending';
      }).length;

      // Livreurs en attente
      final pendingLivreursSnapshot = await FirebaseFirestore.instance
          .collection(FirebaseCollections.users)
          .where('userType', isEqualTo: 'livreur')
          .get();

      final pendingLivreurs = pendingLivreursSnapshot.docs.where((doc) {
        final status = doc.data()['profile']?['status'] as String?;
        return status?.toLowerCase() == 'pending';
      }).length;

      // Utilisateurs suspendus (tous types)
      final allUsersSnapshot =
          await FirebaseFirestore.instance.collection(FirebaseCollections.users).get();

      final suspendedUsers = allUsersSnapshot.docs.where((doc) {
        final status = doc.data()['profile']?['status'] as String?;
        return status?.toLowerCase() == 'suspended';
      }).length;

      // Commandes récentes (derniers 7 jours)
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final recentOrdersSnapshot = await FirebaseFirestore.instance
          .collection(FirebaseCollections.orders)
          .where('createdAt', isGreaterThan: Timestamp.fromDate(sevenDaysAgo))
          .count()
          .get();

      // Abonnements actifs vendeurs
      final activeVendeurSubsSnapshot = await FirebaseFirestore.instance
          .collection(FirebaseCollections.vendeurSubscriptions)
          .where('status', isEqualTo: 'active')
          .count()
          .get();

      // Abonnements actifs livreurs
      final activeLivreurSubsSnapshot = await FirebaseFirestore.instance
          .collection(FirebaseCollections.livreurSubscriptions)
          .where('status', isEqualTo: 'active')
          .count()
          .get();

      // Abonnements expirés vendeurs
      final expiredVendeurSubsSnapshot = await FirebaseFirestore.instance
          .collection(FirebaseCollections.vendeurSubscriptions)
          .where('status', isEqualTo: 'expired')
          .count()
          .get();

      // Abonnements expirés livreurs
      final expiredLivreurSubsSnapshot = await FirebaseFirestore.instance
          .collection(FirebaseCollections.livreurSubscriptions)
          .where('status', isEqualTo: 'expired')
          .count()
          .get();

      // Compter les KYC en attente par type
      int kycVendeursPending = 0;
      int kycLivreursPending = 0;

      try {
        // KYC vendeurs en attente
        for (var doc in pendingVendorsSnapshot.docs) {
          final kycStatus = doc.data()['kycVerificationStatus'] as String?;
          if (kycStatus == 'pending') {
            kycVendeursPending++;
          }
        }

        // KYC livreurs en attente
        for (var doc in pendingLivreursSnapshot.docs) {
          final kycStatus = doc.data()['kycVerificationStatus'] as String?;
          if (kycStatus == 'pending') {
            kycLivreursPending++;
          }
        }
      } catch (e) {
        debugPrint('⚠️ Erreur comptage KYC activités: $e');
      }

      return {
        'pendingVendors': pendingVendors,
        'pendingLivreurs': pendingLivreurs,
        'suspendedUsers': suspendedUsers,
        'recentOrders': recentOrdersSnapshot.count ?? 0,
        'activeSubscriptions':
            (activeVendeurSubsSnapshot.count ?? 0) + (activeLivreurSubsSnapshot.count ?? 0),
        'expiredSubscriptions':
            (expiredVendeurSubsSnapshot.count ?? 0) + (expiredLivreurSubsSnapshot.count ?? 0),
        'kycVendeursPending': kycVendeursPending,
        'kycLivreursPending': kycLivreursPending,
      };
    } catch (e) {
      debugPrint('❌ Erreur récupération activités: $e');
      return {
        'pendingVendors': 0,
        'pendingLivreurs': 0,
        'suspendedUsers': 0,
        'recentOrders': 0,
        'activeSubscriptions': 0,
        'expiredSubscriptions': 0,
        'kycVendeursPending': 0,
        'kycLivreursPending': 0,
      };
    }
  }

  // Actions rapides admin
  Widget _buildQuickActionsSection() {
    return Consumer<auth.AuthProvider>(
      builder: (context, authProvider, _) {
        final isSuperAdmin = authProvider.user?.isSuperAdmin ?? false;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions rapides',
              style: TextStyle(
                fontSize: AppFontSizes.lg,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Bouton Gérer les Administrateurs (SUPER ADMIN ONLY)
            if (isSuperAdmin) ...[
              CustomButton(
                text: 'Gérer les Administrateurs',
                icon: Icons.admin_panel_settings,
                backgroundColor: AppColors.primary,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminManagementScreen(),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],

            CustomButton(
              text: 'Logs d\'Audit',
              icon: Icons.security,
              backgroundColor: AppColors.info,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AuditLogsScreen(),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // Bouton Rapports Globaux (SUPER ADMIN ONLY)
            if (isSuperAdmin) ...[
              CustomButton(
                text: 'Rapports Globaux',
                icon: Icons.assessment,
                backgroundColor: AppColors.primary,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GlobalReportsScreen(),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],

            CustomButton(
              text: 'Voir toutes les activités',
              icon: Icons.timeline,
              backgroundColor: AppColors.info,
              isOutlined: true,
              onPressed: () => context.go('/admin/activities'),
            ),

            const SizedBox(height: AppSpacing.sm),

            CustomButton(
              text: 'Gérer les paramètres',
              icon: Icons.settings,
              backgroundColor: AppColors.secondary,
              isOutlined: true,
              onPressed: () => context.go('/admin/settings'),
            ),

            const SizedBox(height: AppSpacing.sm),

            // Bouton pour générer des données de test
            CustomButton(
              text: 'Générer données de test',
              icon: Icons.science,
              backgroundColor: AppColors.warning,
              isOutlined: true,
              onPressed: () async {
                try {
                  // Afficher un loader
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );

                  // Générer les activités de test
                  await ActivityLogSeeder.seedTestActivities();

                  // Fermer le loader
                  if (context.mounted) {
                    Navigator.of(context).pop();

                    // Afficher un message de succès
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ 12 activités de test créées avec succès'),
                        backgroundColor: AppColors.success,
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                } catch (e) {
                  // Fermer le loader
                  if (context.mounted) {
                    Navigator.of(context).pop();

                    // Afficher l'erreur
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('❌ Erreur: $e'),
                        backgroundColor: AppColors.error,
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }
}

// Helper class pour les items d'alerte
class _AlertItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AlertItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

// Widget carte de statistiques
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String trend;
  final bool isAlert;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.trend,
    this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: isAlert
                      ? AppColors.warning.withValues(alpha: 0.2)
                      : AppColors.success.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  trend,
                  style: TextStyle(
                    fontSize: AppFontSizes.xs,
                    color: isAlert ? AppColors.warning : AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: AppFontSizes.xl,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Flexible(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: AppFontSizes.sm,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
