import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../config/constants.dart';
import '../providers/auth_provider_firebase.dart';

class LivreurDrawer extends StatelessWidget {
  const LivreurDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

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
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.8),
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
                  child: user?.profile['photoURL'] != null || user?.profile['photoUrl'] != null
                      ? ClipOval(
                          child: Image.network(
                            (user!.profile['photoURL'] ?? user.profile['photoUrl']) as String,
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.local_shipping, size: 40, color: AppColors.primary);
                            },
                          ),
                        )
                      : const Icon(Icons.local_shipping, size: 40, color: AppColors.primary),
                ),
                const SizedBox(height: 12),
                // Nom
                Text(
                  user?.displayName ?? 'Livreur',
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
                  icon: Icons.dashboard_rounded,
                  title: 'Dashboard',
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/livreur');
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.person_rounded,
                  title: 'Mon Profil',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/livreur/profile');
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.local_shipping_rounded,
                  title: 'Mes Livraisons',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/livreur/deliveries');
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.attach_money_rounded,
                  title: 'Gains & Commissions',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/livreur/commissions');
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.folder_outlined,
                  title: 'Mes Documents',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/livreur/documents');
                  },
                ),
                const Divider(height: 1),
                _buildMenuItem(
                  context,
                  icon: Icons.subscriptions_rounded,
                  title: 'Abonnement',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/livreur/subscription');
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.rate_review_rounded,
                  title: 'Mes Avis',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/livreur/reviews');
                  },
                ),
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
                    context.push('/user-settings');
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.help_rounded,
                  title: 'Aide & Support',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/help');
                  },
                ),
                const Divider(height: 1),
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
                            child: const Text('Déconnexion', style: TextStyle(color: AppColors.error)),
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
                  'Version 1.0.0',
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
