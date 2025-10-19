// ===== lib/screens/admin/admin_dashboard.dart =====
// Dashboard administrateur avec gestion de tous les profils

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../config/constants.dart';
import '../../providers/auth_provider_firebase.dart' as auth;
import '../../widgets/custom_widgets.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  Future<void> _createFirestoreProfileIfNeeded() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !kIsWeb) return; // Seulement sur Web

    try {
      // Vérifier si le profil existe
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        debugPrint('📝 Création profil Admin Firestore...');
        
        // Créer le profil Admin Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
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
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: _buildAppBar(),
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
            
            // Gestion des utilisateurs
            _buildUserManagementSection(),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Gestion de la plateforme
            _buildPlatformManagementSection(),
            
            const SizedBox(height: AppSpacing.xl),
            
            // Actions rapides admin
            _buildQuickActionsSection(),
          ],
        ),
      ),
    );
  }

  // AppBar personnalisée pour admin
  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Administration SOCIAL BUSINESS'),
      backgroundColor: AppColors.warning,
      foregroundColor: Colors.white,
      elevation: 2,
      actions: [
        // ✅ Bouton Accueil
        IconButton(
          icon: const Icon(Icons.home_outlined),
          tooltip: 'Accueil',
          onPressed: () {
            // Retour à l'accueil acheteur
            context.go('/acheteur-home');
          },
        ),
        // Bouton notifications
        IconButton(
          icon: Stack(
            children: [
              const Icon(Icons.notifications),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      '3',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          onPressed: () => context.go('/notifications'),
        ),
        
        // Menu admin
        PopupMenuButton<String>(
          icon: const Icon(Icons.admin_panel_settings),
          onSelected: (value) {
            switch (value) {
              case 'profile':
                context.go('/admin/profile');
                break;
              case 'settings':
                context.go('/settings');
                break;
              case 'logout':
                _handleLogout();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.person, color: AppColors.textSecondary),
                  SizedBox(width: 8),
                  Text('Mon Profil'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings, color: AppColors.textSecondary),
                  SizedBox(width: 8),
                  Text('Paramètres'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, color: AppColors.error),
                  SizedBox(width: 8),
                  Text('Déconnexion', style: TextStyle(color: AppColors.error)),
                ],
              ),
            ),
          ],
        ),
      ],
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

  // Statistiques rapides
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
        
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.5,
          children: const [
            _StatCard(
              title: 'Vendeurs',
              value: '1,247',
              icon: Icons.store,
              color: AppColors.primary,
              trend: '+12%',
            ),
            _StatCard(
              title: 'Acheteurs',
              value: '8,956',
              icon: Icons.shopping_bag,
              color: AppColors.secondary,
              trend: '+8%',
            ),
            _StatCard(
              title: 'Livreurs',
              value: '342',
              icon: Icons.delivery_dining,
              color: AppColors.success,
              trend: '+15%',
            ),
            _StatCard(
              title: 'Commandes',
              value: '15,623',
              icon: Icons.receipt_long,
              color: AppColors.info,
              trend: '+23%',
            ),
          ],
        ),
      ],
    );
  }

  // Section gestion des utilisateurs
  Widget _buildUserManagementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gestion des utilisateurs',
          style: TextStyle(
            fontSize: AppFontSizes.lg,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        
        Row(
          children: [
            Expanded(
              child: _ManagementCard(
                title: 'Vendeurs',
                subtitle: 'Gérer les comptes vendeurs',
                icon: Icons.store,
                color: AppColors.primary,
                onTap: () => _switchToUserView(UserType.vendeur),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _ManagementCard(
                title: 'Acheteurs',
                subtitle: 'Gérer les comptes acheteurs',
                icon: Icons.shopping_bag,
                color: AppColors.secondary,
                onTap: () => _switchToUserView(UserType.acheteur),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: AppSpacing.md),
        
        _ManagementCard(
          title: 'Livreurs',
          subtitle: 'Gérer les comptes livreurs et livraisons',
          icon: Icons.delivery_dining,
          color: AppColors.success,
          onTap: () => _switchToUserView(UserType.livreur),
        ),
      ],
    );
  }

  // Section gestion de la plateforme
  Widget _buildPlatformManagementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gestion de la plateforme',
          style: TextStyle(
            fontSize: AppFontSizes.lg,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        
        Row(
          children: [
            Expanded(
              child: _ManagementCard(
                title: 'Produits',
                subtitle: 'Modération et gestion',
                icon: Icons.inventory_2,
                color: AppColors.info,
                onTap: () => context.go('/admin/products'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _ManagementCard(
                title: 'Commandes',
                subtitle: 'Suivi et résolution',
                icon: Icons.receipt_long,
                color: AppColors.warning,
                onTap: () => context.go('/admin/orders'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Actions rapides admin
  Widget _buildQuickActionsSection() {
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
        
        CustomButton(
          text: 'Gestion complète des utilisateurs',
          icon: Icons.people,
          backgroundColor: AppColors.info,
          onPressed: () => context.go('/admin/users'),
        ),
        
        const SizedBox(height: AppSpacing.sm),
        
        CustomButton(
          text: 'Rapports et analytiques',
          icon: Icons.analytics,
          backgroundColor: AppColors.secondary,
          isOutlined: true,
          onPressed: () => context.go('/admin/global-stats'),
        ),

        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }

  // Méthode pour changer de vue utilisateur
  void _switchToUserView(UserType targetType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Changer de vue vers ${targetType.value}'),
        content: Text(
          'Voulez-vous basculer temporairement en mode ${targetType.value} '
          'pour voir l\'interface utilisateur ?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Redirection vers la vue correspondante
              switch (targetType) {
                case UserType.vendeur:
                  context.go('/vendeur');
                  break;
                case UserType.acheteur:
                  context.go('/acheteur');
                  break;
                case UserType.livreur:
                  context.go('/livreur');
                  break;
                case UserType.admin:
                  break;
              }
            },
            child: const Text('Basculer'),
          ),
        ],
      ),
    );
  }

  // Méthode de déconnexion
  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<auth.AuthProvider>().logout();
              if (mounted) {
                context.go('/login');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }
}

// Widget carte de statistiques
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String trend;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha:0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha:0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
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
                  color: AppColors.success.withValues(alpha:0.2),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  trend,
                  style: const TextStyle(
                    fontSize: AppFontSizes.xs,
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: const TextStyle(
              fontSize: AppFontSizes.xl,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: AppFontSizes.sm,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// Widget carte de gestion
class _ManagementCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ManagementCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withValues(alpha:0.2),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: const TextStyle(
                fontSize: AppFontSizes.md,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: AppFontSizes.sm,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}