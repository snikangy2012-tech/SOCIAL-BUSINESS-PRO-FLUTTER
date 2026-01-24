// ===== lib/screens/acheteur/business_pro_screen.dart =====
// Écran Mon Business Pro - Connexion/Profil - SOCIAL BUSINESS Pro

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import 'package:social_business_pro/config/constants.dart';
import '../../providers/auth_provider_firebase.dart';
import '../../services/analytics_service.dart';
import '../../services/order_service.dart';
import '../../models/order_model.dart';
import '../../widgets/system_ui_scaffold.dart';

class BusinessProScreen extends StatefulWidget {
  const BusinessProScreen({super.key});

  @override
  State<BusinessProScreen> createState() => _BusinessProScreenState();
}

class _BusinessProScreenState extends State<BusinessProScreen> {
  final AnalyticsService _analytics = AnalyticsService();
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  // Compteurs de commandes
  Map<String, int> _orderCounts = {};
  bool _isLoadingOrders = false;

  @override
  void initState() {
    super.initState();
    _analytics.logScreenView('BusinessProScreen');
    _loadOrderCounts();
  }

  /// Charger le nombre de commandes par statut
  Future<void> _loadOrderCounts() async {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated || authProvider.user == null) return;

    setState(() => _isLoadingOrders = true);

    try {
      final orders = await OrderService.getOrdersByBuyer(authProvider.user!.id);

      // Compter par statut
      final counts = <String, int>{};
      for (final order in orders) {
        counts[order.status] = (counts[order.status] ?? 0) + 1;
      }

      if (mounted) {
        setState(() {
          _orderCounts = counts;
          _isLoadingOrders = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement commandes: $e');
      if (mounted) {
        setState(() => _isLoadingOrders = false);
      }
    }
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
            leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/acheteur-home');
            }
          },
          tooltip: 'Retour',
        ),
        title: const Text('Mon Business Pro'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
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
    final user = auth.user;
    final userName = user?.displayName ?? user?.email.split('@')[0] ?? 'Utilisateur';
    final userEmail = user?.email ?? '';
    final photoURL = user?.profile['photoURL'] as String?;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.md),

            // En-tête avec photo et nom
            Row(
              children: [
                // Avatar avec photo ou initiale du prénom
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.primary,
                  backgroundImage: photoURL != null ? NetworkImage(photoURL) : null,
                  child: photoURL == null
                      ? Text(
                          userName.toString()[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 32,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: AppSpacing.md),
                // Nom et email
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userEmail,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            // Boutons actions rapides (Wish List, Following, Messages)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickActionButton(
                  icon: Icons.favorite_outline,
                  label: 'Favoris',
                  onTap: () => context.push('/favorites'),
                ),
                _buildQuickActionButton(
                  icon: Icons.store_outlined,
                  label: 'Vendeurs',
                  onTap: () => context.push('/acheteur/vendor-list'),
                ),
                _buildQuickActionButton(
                  icon: Icons.rate_review_outlined,
                  label: 'Mes avis',
                  onTap: () => context.push('/acheteur/my-reviews'),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            // ✅ SECTION MES COMMANDES AVEC RÉSUMÉ PAR STATUT
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Titre et bouton "Voir tout"
                  Row(
                    children: [
                      const Icon(Icons.shopping_bag_outlined,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Mes Commandes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => context.push('/acheteur/orders'),
                        child: const Text('Voir tout'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Liste des statuts avec compteurs
                  if (_isLoadingOrders)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.lg),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else ...[
                    _buildOrderStatusRow('En attente', ['en_attente', 'pending'], Icons.schedule),
                    const Divider(height: 1),
                    _buildOrderStatusRow('En préparation', ['preparing', 'confirmed', 'ready'], Icons.kitchen_outlined),
                    const Divider(height: 1),
                    _buildOrderStatusRow('En cours de livraison', ['en_cours', 'in_delivery'], Icons.delivery_dining),
                    const Divider(height: 1),
                    _buildOrderStatusRow('Livrée', ['livree', 'delivered', 'completed'], Icons.check_circle),
                  ],
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Section: Mon Activité
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Text(
                  'Mon Activité',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
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
              icon: Icons.location_on_outlined,
              title: 'Mes adresses',
              subtitle: 'Gérer vos adresses de livraison',
              onTap: () => context.push('/acheteur/addresses'),
            ),

            _buildMenuItem(
              icon: Icons.payment_outlined,
              title: 'Moyens de paiement',
              subtitle: 'Gérer vos méthodes de paiement',
              onTap: () => context.push('/acheteur/payment-methods'),
            ),

            const SizedBox(height: AppSpacing.md),

            // Section: Business
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Text(
                  'Business',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
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
                context.push('/register?userType=vendeur');
              },
            ),

            _buildMenuItem(
              icon: Icons.local_shipping,
              title: 'Devenir livreur',
              subtitle: 'Gagner en livrant',
              onTap: () {
                context.push('/register?userType=livreur');
              },
            ),

            const SizedBox(height: AppSpacing.lg),

            // Bouton déconnexion
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
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
                  try {
                    await _auth.signOut();
                    if (mounted) {
                      context.go('/acheteur-home');
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
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  'Se déconnecter',
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  // Bouton action rapide
  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: AppColors.primary),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Ligne de statut de commande avec compteur
  Widget _buildOrderStatusRow(String label, List<String> statusKeys, IconData icon) {
    // Compter tous les statuts possibles (ex: 'pending' + 'en_attente')
    int count = 0;
    for (final key in statusKeys) {
      count += _orderCounts[key] ?? 0;
    }

    return InkWell(
      onTap: () => context.push('/acheteur/orders'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: count > 0
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: count > 0 ? AppColors.primary : AppColors.textSecondary,
                ),
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
}

