// ===== lib/screens/acheteur/business_pro_screen.dart =====
// Écran Mon Business Pro - Connexion/Profil - SOCIAL BUSINESS Pro

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import 'package:social_business_pro/config/constants.dart';
import '../../providers/auth_provider_firebase.dart';
import '../../services/analytics_service.dart';
import '../../widgets/system_ui_scaffold.dart';

class BusinessProScreen extends StatefulWidget {
  const BusinessProScreen({super.key});

  @override
  State<BusinessProScreen> createState() => _BusinessProScreenState();
}

class _BusinessProScreenState extends State<BusinessProScreen> {
  final AnalyticsService _analytics = AnalyticsService();
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _analytics.logScreenView('BusinessProScreen');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        // ✅ REDIRECTION SELON LE TYPE
        if (auth.isAuthenticated && auth.user != null) {
          // Rediriger vers le bon dashboard selon le type
          WidgetsBinding.instance.addPostFrameCallback((_) {
            switch (auth.user!.userType) {
              case UserType.admin:
                context.go('/admin-dashboard');
                break;
              case UserType.vendeur:
                context.go('/vendeur-dashboard');
                break;
              case UserType.livreur:
                context.go('/livreur-dashboard');
                break;
              case UserType.acheteur:
                // Afficher le contenu acheteur (reste sur cette page)
                break;
            }
          });
        }
        return SystemUIScaffold(
          appBar: AppBar(
            title: const Text('Mon Business Pro'),
          ),
          body: auth.isAuthenticated ? _buildAuthenticatedView(auth) : _buildGuestView(),
        );
      },
    );
  }

  // Vue pour utilisateur NON connecté
  Widget _buildGuestView() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.xl),

            // Logo
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.business_center,
                size: 60,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            const Text(
              'Mon Business Pro',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            const Text(
              'Gérez votre activité commerciale en toute simplicité',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),

            // Types de comptes
            _buildAccountTypeCard(
              icon: Icons.shopping_cart,
              title: 'Acheteur',
              description: 'Achetez et suivez vos commandes',
              color: AppColors.secondary,
            ),

            const SizedBox(height: AppSpacing.md),

            _buildAccountTypeCard(
              icon: Icons.store,
              title: 'Vendeur',
              description: 'Vendez vos produits en ligne',
              color: AppColors.primary,
            ),

            const SizedBox(height: AppSpacing.md),

            _buildAccountTypeCard(
              icon: Icons.delivery_dining,
              title: 'Livreur',
              description: 'Effectuez des livraisons et gagnez',
              color: AppColors.warning,
            ),

            const SizedBox(height: AppSpacing.xxl),

            // Boutons d'action
            ElevatedButton.icon(
              onPressed: () => context.push('/login'),
              icon: const Icon(Icons.login),
              label: const Text('Se connecter'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            OutlinedButton.icon(
              onPressed: () => context.push('/register'),
              icon: const Icon(Icons.person_add),
              label: const Text('Créer un compte'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Avantages
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pourquoi créer un compte ?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildBenefitItem(
                    icon: Icons.history,
                    text: 'Suivre vos commandes',
                  ),
                  _buildBenefitItem(
                    icon: Icons.favorite,
                    text: 'Sauvegarder vos favoris',
                  ),
                  _buildBenefitItem(
                    icon: Icons.notifications,
                    text: 'Recevoir des notifications',
                  ),
                  _buildBenefitItem(
                    icon: Icons.local_offer,
                    text: 'Accéder aux offres exclusives',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Vue pour utilisateur CONNECTÉ
  Widget _buildAuthenticatedView(AuthProvider auth) {
    // ✅ CORRIGÉ : Utiliser user au lieu de userData
    final user = auth.user;
    final userName = user?.displayName ?? user?.email.split('@')[0] ?? 'Utilisateur';
    final userEmail = user?.email ?? '';
    final String userType = auth.userType?.toString() ?? 'acheteur'; // ✅ OK

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.lg),

            // Avatar
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primary,
              child: Text(
                userName.toString()[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 40,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Nom
            Text(
              userName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: AppSpacing.xs),

            // Email
            Text(
              userEmail,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // Badge type de compte
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: _getColorForUserType(userType),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getIconForUserType(userType),
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _getLabelForUserType(userType),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),

            // Section: Mon Activité
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Mon Activité',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),

            _buildMenuItem(
              icon: Icons.person_outline,
              title: 'Mon Profil',
              subtitle: 'Informations personnelles et paramètres',
              onTap: () => context.push('/acheteur/profile'),
            ),

            _buildMenuItem(
              icon: Icons.shopping_bag_outlined,
              title: 'Mes commandes',
              subtitle: 'Historique et suivi de vos achats',
              onTap: () => context.push('/acheteur/orders'),
            ),

            _buildMenuItem(
              icon: Icons.favorite_outline,
              title: 'Mes favoris',
              subtitle: 'Produits que vous aimez',
              onTap: () => context.push('/favorites'),
            ),

            _buildMenuItem(
              icon: Icons.history,
              title: 'Historique de navigation',
              subtitle: 'Produits récemment consultés',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fonctionnalité à venir')),
                );
              },
            ),

            _buildMenuItem(
              icon: Icons.rate_review_outlined,
              title: 'Mes avis',
              subtitle: 'Évaluations et commentaires',
              onTap: () => context.push('/acheteur/my-reviews'),
            ),

            const SizedBox(height: AppSpacing.md),

            // Section: Business
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Business',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),

            _buildMenuItem(
              icon: Icons.local_offer,
              title: 'Offres exclusives',
              subtitle: 'Promotions et réductions',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fonctionnalité à venir')),
                );
              },
            ),

            _buildMenuItem(
              icon: Icons.card_giftcard,
              title: 'Programme fidélité',
              subtitle: 'Points et récompenses',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fonctionnalité à venir')),
                );
              },
            ),

            _buildMenuItem(
              icon: Icons.store,
              title: 'Devenir vendeur',
              subtitle: 'Vendre sur la plateforme',
              onTap: () {
                // Navigation vers la page d'enregistrement avec profil vendeur présélectionné
                context.push('/register?userType=vendeur');
              },
            ),

            _buildMenuItem(
              icon: Icons.local_shipping,
              title: 'Devenir livreur',
              subtitle: 'Gagner en livrant',
              onTap: () {
                // Navigation vers la page d'enregistrement avec profil livreur présélectionné
                context.push('/register?userType=livreur');
              },
            ),

            const SizedBox(height: AppSpacing.lg),

            // Bouton déconnexion
            OutlinedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Déconnexion'),
                    content: const Text('Voulez-vous vraiment vous déconnecter ?'),
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
                        child: const Text('Déconnexion'),
                      ),
                    ],
                  ),
                );

                if (confirm == true && mounted) {
                  // ✅ CORRIGÉ : Gestion de déconnexion
                  try {
                    await _auth.signOut();
                    if (mounted) {
                      // Redirection immédiate
                      context.go('/');

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Déconnexion réussie'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erreur: ${e.toString()}'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('Se déconnecter'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Carte type de compte
  Widget _buildAccountTypeCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Item d'avantage
  Widget _buildBenefitItem({
    required IconData icon,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // Item de menu
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            )
          : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    );
  }

  // Helpers
  Color _getColorForUserType(String type) {
    switch (type) {
      case 'vendeur':
        return AppColors.primary;
      case 'livreur':
        return AppColors.warning;
      default:
        return AppColors.secondary;
    }
  }

  IconData _getIconForUserType(String type) {
    switch (type) {
      case 'vendeur':
        return Icons.store;
      case 'livreur':
        return Icons.delivery_dining;
      default:
        return Icons.shopping_cart;
    }
  }

  String _getLabelForUserType(String type) {
    switch (type) {
      case 'vendeur':
        return 'Vendeur';
      case 'livreur':
        return 'Livreur';
      default:
        return 'Acheteur';
    }
  }
}
