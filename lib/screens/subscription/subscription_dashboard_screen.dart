import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:social_business_pro/config/constants.dart';
import '../../models/subscription_model.dart';
import '../../providers/auth_provider_firebase.dart';
import '../../providers/subscription_provider.dart';
import 'package:intl/intl.dart';
import '../../widgets/system_ui_scaffold.dart';

/// Écran Mon Abonnement - Tableau de bord vendeur
class SubscriptionDashboardScreen extends StatefulWidget {
  const SubscriptionDashboardScreen({super.key});

  @override
  State<SubscriptionDashboardScreen> createState() => _SubscriptionDashboardScreenState();
}

class _SubscriptionDashboardScreenState extends State<SubscriptionDashboardScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);

    if (authProvider.user?.id != null) {
      // ✅ Charger l'abonnement selon le type d'utilisateur
      final userType = authProvider.user!.userType;

      if (userType == UserType.livreur) {
        // Charger l'abonnement livreur
        await subscriptionProvider.loadLivreurSubscription(authProvider.user!.id);
      } else {
        // Charger l'abonnement vendeur (par défaut)
        await Future.wait([
          subscriptionProvider.loadVendeurSubscription(authProvider.user!.id),
          subscriptionProvider.loadPaymentHistory(authProvider.user!.id),
        ]);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);

    // ✅ Détecter le type d'utilisateur
    final isLivreur = authProvider.user?.userType == UserType.livreur;

    // ✅ Charger le bon type d'abonnement
    final subscription = isLivreur
        ? subscriptionProvider.livreurSubscription
        : subscriptionProvider.vendeurSubscription;

    final isLoading = isLivreur
        ? subscriptionProvider.isLoadingLivreurSubscription
        : subscriptionProvider.isLoadingSubscription;

    if (isLoading) {
      return SystemUIScaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (subscription == null) {
      return SystemUIScaffold(
        appBar: AppBar(leading: IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => context.pop(),
    ),
    title: const Text('Mon Abonnement')),
        body: const Center(child: Text('Aucun abonnement trouvé')),
      );
    }

    return SystemUIScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/');
            }
          },
          tooltip: 'Retour',
        ),
        title: const Text('Mon Abonnement'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              // Afficher aide
              _showHelpDialog();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Carte du plan actuel
              _buildCurrentPlanCard(subscription),
              const SizedBox(height: 16),

              // Alertes si nécessaire
              if (subscriptionProvider.alertMessage != null)
                _buildAlertBanner(subscriptionProvider.alertMessage!),

              if (subscriptionProvider.alertMessage != null) const SizedBox(height: 16),

              // Statistiques d'utilisation
              _buildUsageStats(subscription),
              const SizedBox(height: 16),

              // Avantages du plan
              _buildBenefitsCard(subscription),
              const SizedBox(height: 16),

              // Prochaine facturation (si applicable) - Vendeurs uniquement
              if (!isLivreur && (subscription as VendeurSubscription).nextBillingDate != null)
                _buildNextBillingCard(subscription),

              if (!isLivreur && (subscription as VendeurSubscription).nextBillingDate != null)
                const SizedBox(height: 16),

              // Historique des paiements - Vendeurs uniquement
              if (!isLivreur) _buildPaymentHistory(),
              const SizedBox(height: 16),

              // Actions
              _buildActionButtons(subscription),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentPlanCard(dynamic subscription) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isLivreur = authProvider.user?.userType == UserType.livreur;

    // ✅ Gérer les deux types d'abonnement
    final tierName = isLivreur
        ? (subscription as LivreurSubscription).tierName
        : (subscription as VendeurSubscription).tierName;

    final tierDescription = isLivreur
        ? (subscription as LivreurSubscription).tierDescription
        : (subscription as VendeurSubscription).tierDescription;

    final monthlyPrice = subscription.monthlyPrice;
    final commissionRate = subscription.commissionRate;

    final color = isLivreur
        ? _getLivreurPlanColor((subscription as LivreurSubscription).tier)
        : _getPlanColor((subscription as VendeurSubscription).tier);

    final icon = isLivreur
        ? _getLivreurPlanIcon((subscription as LivreurSubscription).tier)
        : _getPlanIcon((subscription as VendeurSubscription).tier);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Plan actuel',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tierName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tierDescription,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                Icon(icon, color: Colors.white, size: 56),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Prix mensuel',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        monthlyPrice == 0 ? 'GRATUIT' : '${monthlyPrice.toStringAsFixed(0)} FCFA',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Commission',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(commissionRate * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertBanner(String message) {
    final isWarning = message.contains('⚠️') || message.contains('⏰');
    final isError =
        message.contains('❌') || message.contains('expiré') || message.contains('suspendu');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isError
            ? Colors.red.shade50
            : isWarning
                ? Colors.orange.shade50
                : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isError
              ? Colors.red.shade300
              : isWarning
                  ? Colors.orange.shade300
                  : Colors.blue.shade300,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isError
                ? Icons.error_outline
                : isWarning
                    ? Icons.warning_amber_outlined
                    : Icons.info_outline,
            color: isError
                ? Colors.red.shade700
                : isWarning
                    ? Colors.orange.shade700
                    : Colors.blue.shade700,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: isError
                    ? Colors.red.shade900
                    : isWarning
                        ? Colors.orange.shade900
                        : Colors.blue.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageStats(dynamic subscription) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isLivreur = authProvider.user?.userType == UserType.livreur;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Utilisation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // ✅ Affichage différent selon le type d'utilisateur
            if (isLivreur) ...[
              // Statistiques livreur
              _buildUsageRow(
                icon: Icons.delivery_dining,
                label: 'Livraisons ce mois',
                value: '0 livraisons',
                progress: null,
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              _buildUsageRow(
                icon: Icons.star_outlined,
                label: 'Note moyenne',
                value: '0.0 ⭐',
                progress: null,
                color: Colors.orange,
              ),
              const SizedBox(height: 16),
              _buildUsageRow(
                icon: Icons.local_fire_department,
                label: 'Priorité',
                value: (subscription as LivreurSubscription).tier == LivreurTier.starter
                    ? 'Standard'
                    : (subscription.tier == LivreurTier.pro ? 'Élevée' : 'Maximale'),
                progress: null,
                color: subscription.tier == LivreurTier.starter
                    ? Colors.grey
                    : (subscription.tier == LivreurTier.pro ? Colors.blue : Colors.red),
              ),
            ] else ...[
              // Statistiques vendeur
              _buildUsageRow(
                icon: Icons.inventory_2_outlined,
                label: 'Produits',
                value:
                    '0 / ${(subscription as VendeurSubscription).productLimit == 999999 ? '∞' : subscription.productLimit}',
                progress: subscription.productLimit == 999999 ? 0.0 : 0.0,
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              if (subscription.hasAIAgent) ...[
                _buildUsageRow(
                  icon: Icons.smart_toy_outlined,
                  label: 'Messages AI',
                  value: '0 / ${subscription.aiMessagesPerDay ?? 0} aujourd\'hui',
                  progress: 0.0,
                  color: Colors.purple,
                ),
                const SizedBox(height: 16),
              ],
              _buildUsageRow(
                icon: Icons.shopping_bag_outlined,
                label: 'Ventes ce mois',
                value: '0 commandes',
                progress: null,
                color: Colors.green,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUsageRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    double? progress,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        if (progress != null) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBenefitsCard(dynamic subscription) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isLivreur = authProvider.user?.userType == UserType.livreur;

    // ✅ Obtenir les bénéfices selon le type d'utilisateur
    final benefits = isLivreur
        ? _getLivreurBenefitsForTier((subscription as LivreurSubscription).tier)
        : _getBenefitsForTier((subscription as VendeurSubscription).tier);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Avantages inclus',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...benefits.map((benefit) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(benefit, style: const TextStyle(fontSize: 14)),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildNextBillingCard(dynamic subscription) {
    final formatter = DateFormat('dd MMMM yyyy', 'fr_FR');
    final daysRemaining = subscription.daysRemaining ?? 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.calendar_today, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Prochain renouvellement',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatter.format(subscription.nextBillingDate!),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Dans $daysRemaining jour${daysRemaining > 1 ? 's' : ''}',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentHistory() {
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);
    final payments = subscriptionProvider.paymentHistory;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Historique des paiements',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (payments.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      // Voir tout l'historique
                    },
                    child: const Text('Voir tout'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (subscriptionProvider.isLoadingPayments)
              const Center(child: CircularProgressIndicator())
            else if (payments.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Aucun paiement enregistré',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...payments.take(3).map((payment) => _buildPaymentItem(payment)),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentItem(SubscriptionPayment payment) {
    final formatter = DateFormat('dd MMM yyyy', 'fr_FR');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: payment.status == 'completed' ? Colors.green.shade100 : Colors.orange.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              payment.status == 'completed' ? Icons.check_circle : Icons.pending,
              color: payment.status == 'completed' ? Colors.green.shade700 : Colors.orange.shade700,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.paymentMethod,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  formatter.format(payment.paymentDate),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Text(
            '${payment.amount.toStringAsFixed(0)} FCFA',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(dynamic subscription) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isLivreur = authProvider.user?.userType == UserType.livreur;

    // ✅ Vérifier si on peut upgrade
    final canUpgrade = isLivreur
        ? (subscription as LivreurSubscription).tier != LivreurTier.premium
        : (subscription as VendeurSubscription).tier != VendeurSubscriptionTier.premium;

    return Column(
      children: [
        if (canUpgrade)
          ElevatedButton.icon(
            onPressed: () {
              context.push('/subscription/plans');
            },
            icon: const Icon(Icons.upgrade),
            label: const Text('Changer de plan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {
            _showCancelSubscriptionDialog();
          },
          icon: const Icon(Icons.cancel_outlined),
          label: const Text('Annuler l\'abonnement'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      ],
    );
  }

  Color _getPlanColor(VendeurSubscriptionTier tier) {
    switch (tier) {
      case VendeurSubscriptionTier.basique:
        return Colors.grey;
      case VendeurSubscriptionTier.pro:
        return AppColors.primary;
      case VendeurSubscriptionTier.premium:
        return const Color(0xFFFFD700);
    }
  }

  IconData _getPlanIcon(VendeurSubscriptionTier tier) {
    switch (tier) {
      case VendeurSubscriptionTier.basique:
        return Icons.store;
      case VendeurSubscriptionTier.pro:
        return Icons.rocket_launch;
      case VendeurSubscriptionTier.premium:
        return Icons.diamond;
    }
  }

  List<String> _getBenefitsForTier(VendeurSubscriptionTier tier) {
    switch (tier) {
      case VendeurSubscriptionTier.basique:
        return [
          'Jusqu\'à 20 produits',
          'Paiements Mobile Money',
          'Support par email',
          'Statistiques basiques',
        ];
      case VendeurSubscriptionTier.pro:
        return [
          'Jusqu\'à 100 produits',
          'Agent AI GPT-3.5 (50 msgs/jour)',
          'Statistiques avancées',
          'Support prioritaire',
          'Badge PRO visible',
        ];
      case VendeurSubscriptionTier.premium:
        return [
          'Produits illimités',
          'Commission réduite à 7%',
          'Agent AI GPT-4 (200 msgs/jour)',
          'Analyses business complètes',
          'Support 24/7',
          'Badge PREMIUM',
          'Visibilité prioritaire',
        ];
    }
  }

  List<String> _getLivreurBenefitsForTier(LivreurTier tier) {
    switch (tier) {
      case LivreurTier.starter:
        return [
          'Commission: 25%',
          'Support par email',
          'Priorité standard',
          'Accès aux livraisons de base',
        ];
      case LivreurTier.pro:
        return [
          'Commission réduite à 20%',
          'Priorité élevée sur les livraisons',
          'Support par chat',
          'Badge PRO visible',
          'Statistiques avancées',
          'Bonus de performance',
        ];
      case LivreurTier.premium:
        return [
          'Commission réduite à 15%',
          'Priorité maximale sur les livraisons',
          'Support 24/7',
          'Badge PREMIUM',
          'Analyses de performance complètes',
          'Bonus de performance premium',
          'Accès aux livraisons VIP',
        ];
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aide'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Comment fonctionne l\'abonnement ?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '• Votre abonnement se renouvelle automatiquement chaque mois\n'
                '• Vous pouvez changer de plan à tout moment\n'
                '• Les commissions sont prélevées sur chaque vente\n'
                '• L\'agent AI vous aide dans vos tâches quotidiennes',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 16),
              Text(
                'Besoin d\'aide ?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Contactez-nous:\n'
                '📧 support@socialbusiness.ci\n'
                '📱 +225 07 07 07 07 07',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showCancelSubscriptionDialog() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
    final isLivreur = authProvider.user?.userType == UserType.livreur;

    // ✅ VÉRIFICATION: Empêcher l'annulation si l'abonnement est encore payé et actif
    DateTime? endDate;
    int? daysRemaining;
    bool isPaidTier = false;
    String currentTierName = '';

    if (isLivreur) {
      endDate = subscriptionProvider.livreurSubscription?.endDate;
      daysRemaining = subscriptionProvider.livreurSubscription?.daysRemaining;
      isPaidTier = subscriptionProvider.livreurSubscription?.tier != LivreurTier.starter;
      currentTierName = subscriptionProvider.livreurTierName;
    } else {
      endDate = subscriptionProvider.vendeurSubscription?.endDate;
      daysRemaining = subscriptionProvider.vendeurSubscription?.daysRemaining;
      isPaidTier =
          subscriptionProvider.vendeurSubscription?.tier != VendeurSubscriptionTier.basique;
      currentTierName = subscriptionProvider.currentTierName;
    }

    // ❌ BLOQUER: Si l'abonnement est payant ET qu'il reste du temps
    if (isPaidTier && endDate != null && daysRemaining != null && daysRemaining > 0) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.warning),
              const SizedBox(width: 8),
              const Expanded(child: Text('Abonnement actif')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Votre abonnement $currentTierName est actif et payé.',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16, color: AppColors.warning),
                          const SizedBox(width: 8),
                          Text(
                            'Temps restant: $daysRemaining jour${daysRemaining! > 1 ? 's' : ''}',
                            style: const TextStyle(
                              color: AppColors.warning,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Expire le: ${DateFormat('dd/MM/yyyy').format(endDate!)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '❌ Vous ne pouvez pas annuler un abonnement payé en cours.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Vos avantages resteront actifs jusqu\'à la date d\'expiration. '
                  'Vous retournerez automatiquement au plan ${isLivreur ? 'STARTER' : 'BASIQUE'} gratuit après cette date.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('J\'ai compris'),
            ),
          ],
        ),
      );
      return;
    }

    // ✅ AUTORISER: L'abonnement est gratuit ou expiré
    final freePlanName = isLivreur ? 'STARTER' : 'BASIQUE';
    final message = isLivreur
        ? 'Êtes-vous sûr de vouloir retourner au plan $freePlanName gratuit ?\n\n'
            'Commission: 25%'
        : 'Êtes-vous sûr de vouloir retourner au plan $freePlanName gratuit ?\n\n'
            'Vous perdrez les avantages de votre plan actuel.';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer le retour au plan gratuit'),
        content: Text(message),
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
                // ✅ Appeler la bonne méthode selon le type d'utilisateur
                bool success;
                if (isLivreur) {
                  // Pour les livreurs: downgrade vers STARTER
                  success = await subscriptionProvider
                      .downgradeLivreurSubscription(authProvider.user!.id);
                } else {
                  // Pour les vendeurs: downgrade vers BASIQUE
                  success = await subscriptionProvider.downgradeSubscription(authProvider.user!.id);
                }

                if (mounted) {
                  final freePlanName = isLivreur ? 'STARTER' : 'BASIQUE';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success
                          ? '✅ Retour au plan $freePlanName effectué.'
                          : '❌ Erreur lors du changement de plan'),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );

                  if (success) {
                    await _loadData();
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  // ✅ Méthodes pour les livreurs
  Color _getLivreurPlanColor(LivreurTier tier) {
    switch (tier) {
      case LivreurTier.starter:
        return Colors.grey;
      case LivreurTier.pro:
        return AppColors.primary;
      case LivreurTier.premium:
        return const Color(0xFFFFD700);
    }
  }

  IconData _getLivreurPlanIcon(LivreurTier tier) {
    switch (tier) {
      case LivreurTier.starter:
        return Icons.delivery_dining;
      case LivreurTier.pro:
        return Icons.rocket_launch;
      case LivreurTier.premium:
        return Icons.diamond;
    }
  }
}

