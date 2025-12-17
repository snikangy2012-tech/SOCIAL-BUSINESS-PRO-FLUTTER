import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:social_business_pro/config/constants.dart';
import '../../models/subscription_model.dart';
import '../../providers/auth_provider_firebase.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/system_ui_scaffold.dart';

/// Écran de présentation des plans d'abonnement (Vendeur ou Livreur)
/// S'adapte automatiquement selon le type d'utilisateur connecté
class SubscriptionPlansScreen extends StatefulWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  State<SubscriptionPlansScreen> createState() => _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  UserType? _userType;

  @override
  void initState() {
    super.initState();
    _loadCurrentSubscription();
  }

  Future<void> _loadCurrentSubscription() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);

    if (authProvider.user != null) {
      setState(() {
        _userType = authProvider.user!.userType;
      });

      // Charger l'abonnement selon le type d'utilisateur
      if (_userType == UserType.vendeur) {
        await subscriptionProvider.loadVendeurSubscription(authProvider.user!.id);
      } else if (_userType == UserType.livreur) {
        await subscriptionProvider.loadLivreurSubscription(authProvider.user!.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userType == null) {
      return SystemUIScaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Afficher les plans selon le type d'utilisateur
    return _userType == UserType.vendeur ? _buildVendeurPlans() : _buildLivreurPlans();
  }

  // ==================== PLANS VENDEUR ====================

  Widget _buildVendeurPlans() {
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);
    final currentTier =
        subscriptionProvider.vendeurSubscription?.tier ?? VendeurSubscriptionTier.basique;

    return SystemUIScaffold(
      appBar: AppBar(
        title: const Text('Plans d\'abonnement'),
        centerTitle: true,
      ),
      body: subscriptionProvider.isLoadingSubscription
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // En-tête
                  _buildHeader(currentTier),
                  const SizedBox(height: 32),

                  // Cartes de plans
                  _buildPlanCard(
                    tier: VendeurSubscriptionTier.basique,
                    title: 'BASIQUE',
                    subtitle: 'Gratuit',
                    price: 0,
                    color: Colors.grey,
                    icon: Icons.store,
                    features: [
                      '✅ 20 produits maximum',
                      '✅ Commission fixe 10%',
                      '✅ Paiements Mobile Money',
                      '✅ Support par email',
                      '❌ Pas d\'agent AI',
                      '❌ Statistiques limitées',
                    ],
                    isCurrentPlan: currentTier == VendeurSubscriptionTier.basique,
                  ),
                  const SizedBox(height: 16),

                  _buildPlanCard(
                    tier: VendeurSubscriptionTier.pro,
                    title: 'PRO',
                    subtitle: 'Pour vendre plus',
                    price: 5000,
                    color: AppColors.primary,
                    icon: Icons.rocket_launch,
                    features: [
                      '✅ 100 produits maximum',
                      '✅ Commission fixe 10%',
                      '✅ Agent AI GPT-3.5',
                      '✅ 50 messages AI/jour',
                      '✅ Statistiques avancées',
                      '✅ Support prioritaire',
                      '✅ Badge PRO visible',
                    ],
                    isCurrentPlan: currentTier == VendeurSubscriptionTier.pro,
                    isRecommended: true,
                  ),
                  const SizedBox(height: 16),

                  _buildPlanCard(
                    tier: VendeurSubscriptionTier.premium,
                    title: 'PREMIUM',
                    subtitle: 'Sans limites',
                    price: 10000,
                    color: const Color(0xFFFFD700),
                    icon: Icons.diamond,
                    features: [
                      '✅ Produits ILLIMITÉS',
                      '🎉 Commission réduite 7%',
                      '✅ Agent AI GPT-4',
                      '✅ 200 messages AI/jour',
                      '✅ Analyses business',
                      '✅ Support 24/7',
                      '✅ Badge PREMIUM',
                      '✅ Visibilité prioritaire',
                    ],
                    isCurrentPlan: currentTier == VendeurSubscriptionTier.premium,
                  ),
                  const SizedBox(height: 32),

                  // Tableau comparatif
                  _buildComparisonTable(),
                  const SizedBox(height: 24),

                  // FAQ rapide
                  _buildQuickFAQ(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(VendeurSubscriptionTier currentTier) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.workspace_premium, color: Colors.white, size: 48),
          const SizedBox(height: 12),
          const Text(
            'Choisissez le plan qui vous convient',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Plan actuel: ${_getTierName(currentTier)}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required VendeurSubscriptionTier tier,
    required String title,
    required String subtitle,
    required double price,
    required Color color,
    required IconData icon,
    required List<String> features,
    required bool isCurrentPlan,
    bool isRecommended = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isCurrentPlan ? color : Colors.grey.shade300,
          width: isCurrentPlan ? 3 : 1,
        ),
        borderRadius: BorderRadius.circular(16),
        color: isCurrentPlan ? color.withValues(alpha: 0.05) : Colors.white,
      ),
      child: Stack(
        children: [
          // Badge "Recommandé"
          if (isRecommended)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: const BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
                child: const Text(
                  'RECOMMANDÉ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          // Badge "Plan actuel"
          if (isCurrentPlan)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'PLAN ACTUEL',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icône et titre
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Prix
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price == 0 ? 'GRATUIT' : '${price.toStringAsFixed(0)} FCFA',
                      style: TextStyle(
                        fontSize: price == 0 ? 28 : 32,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    if (price > 0) ...[
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '/mois',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),

                // Fonctionnalités
                ...features.map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            feature.substring(0, 2),
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              feature.substring(3),
                              style: TextStyle(
                                fontSize: 15,
                                color: feature.startsWith('❌')
                                    ? Colors.grey.shade500
                                    : Colors.grey.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 20),

                // Bouton d'action
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isCurrentPlan ? null : () => _selectPlan(tier),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: Colors.grey.shade300,
                      disabledForegroundColor: Colors.grey.shade600,
                    ),
                    child: Text(
                      isCurrentPlan
                          ? 'Plan actuel'
                          : tier == VendeurSubscriptionTier.basique
                              ? 'Rétrograder'
                              : 'Choisir ce plan',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonTable() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Comparaison détaillée',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildComparisonRow('Nombre de produits', '20', '100', 'Illimité'),
            _buildComparisonRow('Commission', '10%', '10%', '7%'),
            _buildComparisonRow('Agent AI', '❌', 'GPT-3.5', 'GPT-4'),
            _buildComparisonRow('Messages AI/jour', '-', '50', '200'),
            _buildComparisonRow('Support', 'Email', 'Prioritaire', '24/7'),
            _buildComparisonRow('Statistiques', 'Basiques', 'Avancées', 'Complètes'),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonRow(String feature, String basique, String pro, String premium) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(feature, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(
              child:
                  Text(basique, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13))),
          Expanded(
              child: Text(pro, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13))),
          Expanded(
              child:
                  Text(premium, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildQuickFAQ() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Questions fréquentes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildFAQItem(
              '💳 Puis-je changer de plan à tout moment ?',
              'Oui, vous pouvez upgrader ou downgrader votre plan quand vous voulez.',
            ),
            _buildFAQItem(
              '🔄 Que se passe-t-il si je dépasse la limite ?',
              'Vous serez invité à upgrader votre plan pour continuer.',
            ),
            _buildFAQItem(
              '💰 Comment se calcule la commission ?',
              'La commission est prélevée sur chaque vente validée.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            answer,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  String _getTierName(VendeurSubscriptionTier tier) {
    switch (tier) {
      case VendeurSubscriptionTier.basique:
        return 'BASIQUE';
      case VendeurSubscriptionTier.pro:
        return 'PRO';
      case VendeurSubscriptionTier.premium:
        return 'PREMIUM';
    }
  }

  void _selectPlan(VendeurSubscriptionTier tier) {
    if (tier == VendeurSubscriptionTier.basique) {
      _showDowngradeConfirmation();
    } else {
      context.push('/subscription/subscribe', extra: tier);
    }
  }

  void _showDowngradeConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la rétrogradation'),
        content: const Text(
          'Êtes-vous sûr de vouloir revenir au plan BASIQUE gratuit ?\n\n'
          'Vous perdrez :\n'
          '• L\'accès à l\'agent AI\n'
          '• Les statistiques avancées\n'
          '• La limite de produits sera réduite à 20',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final subscriptionProvider =
                  Provider.of<SubscriptionProvider>(context, listen: false);

              if (authProvider.user?.id != null) {
                final success =
                    await subscriptionProvider.downgradeSubscription(authProvider.user!.id);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success
                          ? '✅ Plan rétrogradé vers BASIQUE'
                          : '❌ Erreur lors de la rétrogradation'),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  // ==================== PLANS LIVREUR ====================

  Widget _buildLivreurPlans() {
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);
    final currentTier = subscriptionProvider.livreurSubscription?.tier ?? LivreurTier.starter;

    return SystemUIScaffold(
      appBar: AppBar(
        title: const Text('Plans d\'abonnement'),
        centerTitle: true,
      ),
      body: subscriptionProvider.isLoadingLivreurSubscription
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // En-tête
                  _buildLivreurHeader(currentTier),
                  const SizedBox(height: 32),

                  // Plan STARTER (Gratuit - NOUVEAU MODÈLE HYBRIDE)
                  _buildLivreurPlanCard(
                    tier: LivreurTier.starter,
                    title: '🚴 STARTER',
                    subtitle: 'Gratuit à vie',
                    price: 0,
                    color: Colors.grey,
                    icon: Icons.delivery_dining,
                    features: [
                      '✅ Gratuit pour toujours',
                      '✅ Commission 25%',
                      '✅ Support par FAQ',
                      '✅ Notifications en temps réel',
                      '✅ Zone de livraison normale',
                      '❌ Pas de priorité',
                      '❌ Statistiques limitées',
                    ],
                    isCurrentPlan: currentTier == LivreurTier.starter,
                    unlockCondition: 'Débloqué dès le départ',
                  ),
                  const SizedBox(height: 16),

                  // Plan PRO (NOUVEAU : 10,000 FCFA/mois - Hybride)
                  _buildLivreurPlanCard(
                    tier: LivreurTier.pro,
                    title: '🏍️ PRO',
                    subtitle: '10,000 FCFA/mois',
                    price: 10000,
                    color: Colors.blue,
                    icon: Icons.two_wheeler,
                    features: [
                      '✅ Commission réduite 20%',
                      '✅ Zone étendue',
                      '✅ Badge PRO',
                      '✅ Statistiques avancées',
                      '✅ Support téléphonique',
                      '✅ Notifications prioritaires',
                    ],
                    isCurrentPlan: currentTier == LivreurTier.pro,
                    isRecommended: true,
                    unlockCondition: 'Débloqué à 50 livraisons + 4.0★',
                  ),
                  const SizedBox(height: 16),

                  // Plan PREMIUM (NOUVEAU : 30,000 FCFA/mois - Hybride)
                  _buildLivreurPlanCard(
                    tier: LivreurTier.premium,
                    title: '🚚 PREMIUM',
                    subtitle: '30,000 FCFA/mois',
                    price: 30000,
                    color: Colors.amber.shade700,
                    icon: Icons.electric_bike,
                    features: [
                      '🎉 Commission optimale 15%',
                      '✅ Priorité MAXIMALE',
                      '✅ Support 24/7',
                      '✅ Tableau de bord complet',
                      '✅ Badge PREMIUM',
                      '✅ Bonus de performance',
                      '✅ Formation gratuite',
                      '✅ Statistiques complètes',
                    ],
                    isCurrentPlan: currentTier == LivreurTier.premium,
                    unlockCondition: 'Débloqué à 200 livraisons + 4.5★',
                  ),
                  const SizedBox(height: 32),

                  // Tableau comparatif
                  _buildLivreurComparisonTable(),
                  const SizedBox(height: 24),

                  // FAQ rapide
                  _buildLivreurQuickFAQ(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildLivreurHeader(LivreurTier currentTier) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange, Colors.orange.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.delivery_dining, color: Colors.white, size: 48),
          const SizedBox(height: 12),
          const Text(
            'Choisissez votre plan de livreur',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Plan actuel: ${_getLivreurTierName(currentTier)}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLivreurPlanCard({
    required LivreurTier tier,
    required String title,
    required String subtitle,
    required double price,
    required Color color,
    required IconData icon,
    required List<String> features,
    required bool isCurrentPlan,
    bool isRecommended = false,
    String? unlockCondition,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isCurrentPlan ? color : Colors.grey.shade300,
          width: isCurrentPlan ? 3 : 1,
        ),
        borderRadius: BorderRadius.circular(16),
        color: isCurrentPlan ? color.withValues(alpha: 0.05) : Colors.white,
      ),
      child: Stack(
        children: [
          if (isRecommended)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: const BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
                child: const Text(
                  'RECOMMANDÉ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          if (isCurrentPlan)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'PLAN ACTUEL',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price == 0 ? 'GRATUIT' : '${price.toStringAsFixed(0)} FCFA',
                      style: TextStyle(
                        fontSize: price == 0 ? 28 : 32,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    if (price > 0) ...[
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '/mois',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                // Condition de déblocage (NOUVEAU MODÈLE HYBRIDE)
                if (unlockCondition != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lock_open, color: color, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '🔓 $unlockCondition',
                            style: TextStyle(
                              fontSize: 13,
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                ...features.map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            feature.substring(0, 2),
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              feature.substring(3),
                              style: TextStyle(
                                fontSize: 15,
                                color: feature.startsWith('❌')
                                    ? Colors.grey.shade500
                                    : Colors.grey.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isCurrentPlan ? null : () => _selectLivreurPlan(tier),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: Colors.grey.shade300,
                      disabledForegroundColor: Colors.grey.shade600,
                    ),
                    child: Text(
                      isCurrentPlan
                          ? 'Plan actuel'
                          : tier == LivreurTier.starter
                              ? 'Rétrograder'
                              : 'Choisir ce plan',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLivreurComparisonTable() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Comparaison détaillée',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildComparisonRow('Prix/mois', 'Gratuit', '10,000', '30,000'),
            _buildComparisonRow('Commission', '25%', '20%', '15%'),
            _buildComparisonRow('Déblocage', 'Immédiat', '50 liv. + 4.0★', '200 liv. + 4.5★'),
            _buildComparisonRow('Support', 'FAQ', 'Téléphone', '24/7'),
            _buildComparisonRow('Statistiques', 'Basiques', 'Avancées', 'Complètes'),
            _buildComparisonRow('Bonus performance', '❌', '❌', '✅'),
          ],
        ),
      ),
    );
  }

  Widget _buildLivreurQuickFAQ() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Questions fréquentes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildFAQItem(
              '💳 Puis-je changer de plan à tout moment ?',
              'Oui, vous pouvez upgrader ou downgrader votre plan quand vous voulez.',
            ),
            _buildFAQItem(
              '🔄 Que se passe-t-il si je dépasse ma limite ?',
              'Vous devrez upgrader pour accepter de nouvelles livraisons ce mois-ci.',
            ),
            _buildFAQItem(
              '💰 Comment fonctionne la commission ?',
              'La commission est prélevée sur chaque livraison effectuée.',
            ),
          ],
        ),
      ),
    );
  }

  String _getLivreurTierName(LivreurTier tier) {
    switch (tier) {
      case LivreurTier.starter:
        return 'STARTER';
      case LivreurTier.pro:
        return 'PRO';
      case LivreurTier.premium:
        return 'PREMIUM';
    }
  }

  void _selectLivreurPlan(LivreurTier tier) {
    if (tier == LivreurTier.starter) {
      _showLivreurDowngradeConfirmation();
    } else {
      context.push('/subscription/subscribe', extra: tier);
    }
  }

  void _showLivreurDowngradeConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la rétrogradation'),
        content: const Text(
          'Êtes-vous sûr de vouloir revenir au plan STARTER gratuit ?\n\n'
          'Vous perdrez :\n'
          '• La commission réduite (retour à 25%)\n'
          '• La priorité dans l\'attribution\n'
          '• Les statistiques avancées\n'
          '• Votre badge PRO/PREMIUM',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final subscriptionProvider =
                  Provider.of<SubscriptionProvider>(context, listen: false);

              if (authProvider.user?.id != null) {
                final success =
                    await subscriptionProvider.downgradeLivreurSubscription(authProvider.user!.id);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success
                          ? '✅ Plan rétrogradé vers STARTER'
                          : '❌ Erreur lors de la rétrogradation'),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }
}
