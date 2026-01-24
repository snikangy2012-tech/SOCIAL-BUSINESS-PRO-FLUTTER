import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../config/constants.dart';
import '../providers/auth_provider_firebase.dart';

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final isSuperAdmin = user?.isSuperAdmin ?? false;

    return Drawer(
      child: Column(
        children: [
          // Header avec profil utilisateur
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.warning,
                  AppColors.warning.withValues(alpha: 0.8),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.white,
                  child: user?.profile['photoURL'] != null
                      ? ClipOval(
                          child: Image.network(
                            user!.profile['photoURL'],
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.admin_panel_settings,
                                  size: 40, color: AppColors.warning);
                            },
                          ),
                        )
                      : const Icon(Icons.admin_panel_settings,
                          size: 40, color: AppColors.warning),
                ),
                const SizedBox(height: 12),
                // Nom
                Text(
                  user?.displayName ?? 'Administrateur',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                // Email
                Text(
                  user?.email ?? '',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
                if (isSuperAdmin) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'SUPER ADMIN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Menu items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMenuItem(
                  context,
                  icon: Icons.dashboard_customize_outlined,
                  title: 'Tableau de bord',
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/admin-dashboard');
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.person_rounded,
                  title: 'Mon Profil',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/admin/profile');
                  },
                ),
                const Divider(height: 1),

                // Gestion utilisateurs
                _buildMenuItem(
                  context,
                  icon: Icons.people_rounded,
                  title: 'Gestion Utilisateurs',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/admin/user-management');
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.store_rounded,
                  title: 'Gestion Vendeurs',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/admin/vendor-management');
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.delivery_dining_rounded,
                  title: 'Gestion Livreurs',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/admin/livreur-management');
                  },
                ),

                const Divider(height: 1),

                // KYC et Vérifications
                _buildMenuItem(
                  context,
                  icon: Icons.verified_user_rounded,
                  title: 'Vérification KYC',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/admin/kyc-verification');
                  },
                ),

                // Commandes et produits
                _buildMenuItem(
                  context,
                  icon: Icons.shopping_cart_rounded,
                  title: 'Gestion Commandes',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/admin/order-management');
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.inventory_rounded,
                  title: 'Gestion Produits',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/admin/product-management');
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.category_rounded,
                  title: 'Gestion Catégories',
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/admin/categories-management');
                  },
                ),

                const Divider(height: 1),

                // Abonnements et finances (SUPER ADMIN)
                if (isSuperAdmin) ...[
                  _buildMenuItem(
                    context,
                    icon: Icons.subscriptions_rounded,
                    title: 'Gestion Abonnements',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/admin/subscription-management');
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.account_balance_wallet_rounded,
                    title: 'Finances Globales',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/admin/finance');
                    },
                  ),
                  const Divider(height: 1),
                ],

                // Statistiques et rapports
                _buildMenuItem(
                  context,
                  icon: Icons.analytics_rounded,
                  title: 'Statistiques Globales',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/admin/statistics');
                  },
                ),
                if (isSuperAdmin)
                  _buildMenuItem(
                    context,
                    icon: Icons.assessment_rounded,
                    title: 'Rapports Globaux',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/admin/reports');
                    },
                  ),
                _buildMenuItem(
                  context,
                  icon: Icons.security_rounded,
                  title: 'Logs d\'Audit',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/admin/audit-logs');
                  },
                ),

                const Divider(height: 1),

                // Paramètres
                _buildMenuItem(
                  context,
                  icon: Icons.notifications_rounded,
                  title: 'Notifications',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/notifications');
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.settings_rounded,
                  title: 'Paramètres',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/admin/settings');
                  },
                ),

                const Divider(height: 1),

                // Déconnexion
                _buildMenuItem(
                  context,
                  icon: Icons.logout_rounded,
                  title: 'Déconnexion',
                  textColor: AppColors.error,
                  onTap: () async {
                    // Fermer le drawer
                    Navigator.pop(context);

                    // Afficher la confirmation
                    final confirm = await showDialog<bool>(
                      context: context,
                      barrierDismissible: false,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Déconnexion'),
                        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext, false),
                            child: const Text('Annuler'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext, true),
                            child: const Text('Déconnexion',
                                style: TextStyle(color: AppColors.error)),
                          ),
                        ],
                      ),
                    );

                    // Si confirmé, déconnecter
                    if (confirm == true) {
                      if (!context.mounted) return;

                      try {
                        // Afficher un loading pendant la déconnexion
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );

                        await authProvider.logout();

                        if (context.mounted) {
                          // Fermer le loading
                          Navigator.pop(context);
                          // Naviguer vers login
                          context.go('/login');
                        }
                      } catch (e) {
                        if (context.mounted) {
                          // Fermer le loading en cas d'erreur
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Erreur lors de la déconnexion: $e'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    }
                  },
                ),
              ],
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'SOCIAL BUSINESS Pro',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version 1.0.0 - Admin Panel',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? AppColors.textPrimary),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }
}
