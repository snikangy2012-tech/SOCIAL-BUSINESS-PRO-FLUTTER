import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:social_business_pro/config/constants.dart';
import '../../models/subscription_model.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/auth_provider_firebase.dart';
import '../../widgets/system_ui_scaffold.dart';

/// Écran transversal affiché quand un utilisateur (vendeur ou livreur) atteint une limite
/// - VENDEUR: limite de produits, messages AI
/// - LIVREUR: Note - Dans le nouveau modèle hybride, les livreurs n'ont pas de limites fixes,
///   mais doivent upgrader pour réduire leur commission
class LimitReachedScreen extends StatelessWidget {
  final String limitType; // 'products', 'ai_messages', 'deliveries' (legacy)

  const LimitReachedScreen({
    super.key,
    this.limitType = 'products',
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);
    final userType = authProvider.user?.userType;

    // Déterminer le contexte (vendeur ou livreur)
    if (userType == UserType.vendeur) {
      return _buildVendeurLimitScreen(context, subscriptionProvider);
    } else if (userType == UserType.livreur) {
      return _buildLivreurUpgradeScreen(context, subscriptionProvider);
    }

    // Fallback si le type d'utilisateur n'est pas reconnu
    return SystemUIScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
          tooltip: 'Retour',
        ),
        title: const Text('Limite atteinte'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Type d\'utilisateur non reconnu'),
      ),
    );
  }

  // ==================== VENDEUR LIMIT SCREEN ====================

  Widget _buildVendeurLimitScreen(BuildContext context, SubscriptionProvider subscriptionProvider) {
    final currentTier =
        subscriptionProvider.vendeurSubscription?.tier ?? VendeurSubscriptionTier.basique;

    return SystemUIScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
          tooltip: 'Retour',
        ),
        title: const Text('Limite atteinte'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Illustration
            _buildIllustration(limitType),
            const SizedBox(height: 32),

            // Message principal
            _buildMainMessage(limitType, currentTier),
            const SizedBox(height: 24),

            // Détails de la limite actuelle
            _buildCurrentLimitCard(limitType, subscriptionProvider),
            const SizedBox(height: 32),

            // Suggestions d'upgrade
            const Text(
              'Passez à un plan supérieur',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Cartes de plans suggérés
            if (currentTier == VendeurSubscriptionTier.basique) ...[
              _buildUpgradeCard(
                context,
                tier: VendeurSubscriptionTier.pro,
                title: 'PRO',
                price: 5000,
                highlight: 'Recommandé',
                benefits: [
                  '✅ 100 produits (vs 20)',
                  '✅ Agent AI GPT-3.5',
                  '✅ Statistiques avancées',
                  '✅ Support prioritaire',
                ],
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              _buildUpgradeCard(
                context,
                tier: VendeurSubscriptionTier.premium,
                title: 'PREMIUM',
                price: 10000,
                benefits: [
                  '✅ Produits ILLIMITÉS',
                  '🎉 Commission 7% (vs 10%)',
                  '✅ Agent AI GPT-4',
                  '✅ Support 24/7',
                ],
                color: const Color(0xFFFFD700),
              ),
            ] else if (currentTier == VendeurSubscriptionTier.pro) ...[
              _buildUpgradeCard(
                context,
                tier: VendeurSubscriptionTier.premium,
                title: 'PREMIUM',
                price: 10000,
                highlight: 'Meilleur choix',
                benefits: [
                  '✅ Produits ILLIMITÉS',
                  '🎉 Commission réduite à 7%',
                  '✅ Agent AI GPT-4 (vs GPT-3.5)',
                  '✅ 200 messages AI/jour (vs 50)',
                  '✅ Support 24/7',
                ],
                color: const Color(0xFFFFD700),
              ),
            ],

            const SizedBox(height: 24),

            // Alternatives
            _buildAlternatives(limitType),
          ],
        ),
      ),
    );
  }

  Widget _buildIllustration(String limitType) {
    IconData icon;
    Color color;

    switch (limitType) {
      case 'ai_messages':
        icon = Icons.chat_outlined;
        color = Colors.purple;
        break;
      default: // 'products'
        icon = Icons.inventory_2_outlined;
        color = AppColors.primary;
    }

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 80, color: color),
    );
  }

  Widget _buildMainMessage(String limitType, VendeurSubscriptionTier currentTier) {
    String title;
    String message;

    switch (limitType) {
      case 'ai_messages':
        title = 'Limite de messages AI atteinte';
        message = 'Vous avez utilisé tous vos messages AI pour aujourd\'hui. '
            'Passez à un plan supérieur pour bénéficier de plus de messages quotidiens.';
        break;
      default: // 'products'
        final limit = currentTier == VendeurSubscriptionTier.basique
            ? '20'
            : currentTier == VendeurSubscriptionTier.pro
                ? '100'
                : 'illimité';
        title = 'Limite de produits atteinte';
        message =
            'Votre plan ${_getTierName(currentTier)} vous permet d\'avoir jusqu\'à $limit produits. '
            'Pour ajouter plus de produits, passez à un plan supérieur.';
    }

    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          message,
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey.shade700,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCurrentLimitCard(String limitType, SubscriptionProvider provider) {
    final subscription = provider.vendeurSubscription;
    if (subscription == null) return const SizedBox.shrink();

    String limitLabel;
    String limitValue;
    IconData icon;

    switch (limitType) {
      case 'ai_messages':
        limitLabel = 'Messages AI aujourd\'hui';
        limitValue =
            '${subscription.aiMessagesPerDay ?? 0} / ${subscription.aiMessagesPerDay ?? 0}';
        icon = Icons.message;
        break;
      default: // 'products'
        limitLabel = 'Produits actuels';
        limitValue = subscription.productLimit == 999999
            ? 'Illimité'
            : '${subscription.productLimit} / ${subscription.productLimit}';
        icon = Icons.inventory_2;
    }

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
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.orange.shade700, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    limitLabel,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    limitValue,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'LIMITE',
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpgradeCard(
    BuildContext context, {
    required VendeurSubscriptionTier tier,
    required String title,
    required double price,
    required List<String> benefits,
    required Color color,
    String? highlight,
  }) {
    return Card(
      elevation: highlight != null ? 6 : 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: highlight != null ? color : Colors.transparent,
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          // Badge recommandé
          if (highlight != null)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                  ),
                ),
                child: Text(
                  highlight.toUpperCase(),
                  style: const TextStyle(
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
                // En-tête
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(_getIconForTier(tier), color: color, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          Text(
                            '${price.toStringAsFixed(0)} FCFA / mois',
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

                // Avantages
                ...benefits.map((benefit) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Text(
                            benefit.substring(0, 2),
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              benefit.substring(3),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 16),

                // Bouton d'upgrade
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      context.push('/subscription/subscribe', extra: tier);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Passer au plan $title',
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

  Widget _buildAlternatives(String limitType) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.amber.shade700, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Alternatives',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (limitType == 'products') ...[
              _buildAlternativeItem(
                '📦 Supprimer des produits inactifs',
                'Supprimez les produits que vous ne vendez plus pour libérer de l\'espace.',
              ),
              const SizedBox(height: 8),
              _buildAlternativeItem(
                '⏸️ Désactiver temporairement',
                'Désactivez certains produits pour les réactiver plus tard.',
              ),
            ] else if (limitType == 'ai_messages') ...[
              _buildAlternativeItem(
                '⏰ Réessayer demain',
                'Votre quota de messages AI se renouvelle chaque jour à minuit.',
              ),
              const SizedBox(height: 8),
              _buildAlternativeItem(
                '📚 Consulter la FAQ',
                'De nombreuses réponses sont disponibles dans notre FAQ.',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAlternativeItem(String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              Text(
                description,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
      ],
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

  IconData _getIconForTier(VendeurSubscriptionTier tier) {
    switch (tier) {
      case VendeurSubscriptionTier.basique:
        return Icons.store;
      case VendeurSubscriptionTier.pro:
        return Icons.rocket_launch;
      case VendeurSubscriptionTier.premium:
        return Icons.diamond;
    }
  }

  // ==================== LIVREUR UPGRADE SCREEN ====================
  // Note: Les livreurs n'ont pas de limites strictes dans le nouveau modèle hybride.
  // Cet écran encourage l'upgrade pour réduire la commission et obtenir plus d'avantages.

  Widget _buildLivreurUpgradeScreen(
      BuildContext context, SubscriptionProvider subscriptionProvider) {
    final currentSubscription = subscriptionProvider.livreurSubscription;
    final currentTier = currentSubscription?.tier ?? LivreurTier.starter;

    return SystemUIScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
          tooltip: 'Retour',
        ),
        title: const Text('Améliorer votre plan'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Illustration
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.trending_up, size: 80, color: Colors.blue),
            ),
            const SizedBox(height: 32),

            // Message principal
            const Text(
              'Réduisez vos commissions !',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Passez à un plan supérieur pour réduire vos commissions et augmenter vos revenus sur chaque livraison.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Carte commission actuelle
            if (currentSubscription != null)
              _buildLivreurCurrentCommissionCard(currentSubscription),
            const SizedBox(height: 32),

            // Suggestions d'upgrade
            const Text(
              'Plans disponibles',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Cartes de plans suggérés selon le tier actuel
            if (currentTier == LivreurTier.starter) ...[
              _buildLivreurUpgradeCard(
                context,
                tier: LivreurTier.pro,
                title: '🏍️ PRO',
                price: 10000,
                commission: '20%',
                highlight: 'Recommandé',
                benefits: [
                  '✅ Commission réduite à 20% (vs 25%)',
                  '✅ Zone étendue',
                  '✅ Badge PRO',
                  '✅ Statistiques avancées',
                ],
                unlockRequirement: '50 livraisons + 4.0★',
                isUnlocked: (currentSubscription?.currentDeliveries ?? 0) >= 50 &&
                    (currentSubscription?.currentRating ?? 0) >= 4.0,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              _buildLivreurUpgradeCard(
                context,
                tier: LivreurTier.premium,
                title: '🚚 PREMIUM',
                price: 30000,
                commission: '15%',
                benefits: [
                  '🎉 Commission optimale 15%',
                  '✅ Priorité MAXIMALE',
                  '✅ Support 24/7',
                  '✅ Badge PREMIUM',
                  '✅ Statistiques complètes',
                ],
                unlockRequirement: '200 livraisons + 4.5★',
                isUnlocked: (currentSubscription?.currentDeliveries ?? 0) >= 200 &&
                    (currentSubscription?.currentRating ?? 0) >= 4.5,
                color: Colors.amber.shade700,
              ),
            ] else if (currentTier == LivreurTier.pro) ...[
              _buildLivreurUpgradeCard(
                context,
                tier: LivreurTier.premium,
                title: '🚚 PREMIUM',
                price: 30000,
                commission: '15%',
                highlight: 'Meilleur choix',
                benefits: [
                  '🎉 Commission optimale 15% (vs 20%)',
                  '✅ Priorité MAXIMALE',
                  '✅ Support 24/7',
                  '✅ Badge PREMIUM',
                  '✅ Bonus de performance',
                ],
                unlockRequirement: '200 livraisons + 4.5★',
                isUnlocked: (currentSubscription?.currentDeliveries ?? 0) >= 200 &&
                    (currentSubscription?.currentRating ?? 0) >= 4.5,
                color: Colors.amber.shade700,
              ),
            ],

            const SizedBox(height: 24),

            // Calculateur d'économies
            _buildSavingsCalculator(currentTier),
          ],
        ),
      ),
    );
  }

  Widget _buildLivreurCurrentCommissionCard(LivreurSubscription subscription) {
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
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.percent, color: Colors.orange.shade700, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Commission actuelle',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(subscription.commissionRate * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                subscription.tierName,
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLivreurUpgradeCard(
    BuildContext context, {
    required LivreurTier tier,
    required String title,
    required double price,
    required String commission,
    required List<String> benefits,
    required Color color,
    required String unlockRequirement,
    required bool isUnlocked,
    String? highlight,
  }) {
    return Card(
      elevation: highlight != null ? 6 : 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: highlight != null ? color : Colors.transparent,
          width: 2,
        ),
      ),
      child: Opacity(
        opacity: isUnlocked ? 1.0 : 0.7,
        child: Stack(
          children: [
            // Badge recommandé
            if (highlight != null)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(14),
                      bottomLeft: Radius.circular(14),
                    ),
                  ),
                  child: Text(
                    highlight.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            // Badge débloqué ou verrouillé
            if (!isUnlocked)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock, color: Colors.white, size: 12),
                      SizedBox(width: 4),
                      Text(
                        'VERROUILLÉ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.delivery_dining, color: color, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                            Text(
                              '${price.toStringAsFixed(0)} FCFA / mois',
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
                  const SizedBox(height: 16),

                  // Commission
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.trending_down, color: color, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Commission: $commission',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Condition de déblocage
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUnlocked ? Colors.green.shade50 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isUnlocked ? Colors.green : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isUnlocked ? Icons.check_circle : Icons.lock,
                          color: isUnlocked ? Colors.green : Colors.grey,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isUnlocked ? '✅ Débloqué' : '🔒 $unlockRequirement',
                            style: TextStyle(
                              fontSize: 13,
                              color: isUnlocked ? Colors.green.shade700 : Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Avantages
                  ...benefits.map((benefit) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Text(
                              benefit.substring(0, 2),
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                benefit.substring(3),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 16),

                  // Bouton d'upgrade
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isUnlocked
                          ? () {
                              context.push('/subscription/subscribe', extra: tier);
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                      child: Text(
                        isUnlocked ? 'Passer au plan ${tier.name.toUpperCase()}' : 'Non débloqué',
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
      ),
    );
  }

  Widget _buildSavingsCalculator(LivreurTier currentTier) {
    final currentCommission = currentTier == LivreurTier.starter
        ? 0.25
        : currentTier == LivreurTier.pro
            ? 0.20
            : 0.15;

    // Calculer les économies potentielles (exemple: 50 livraisons x 5000 FCFA)
    const deliveryPrice = 5000.0;
    const monthlyDeliveries = 50;
    final currentCost = deliveryPrice * monthlyDeliveries * currentCommission;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calculate_outlined, color: Colors.green.shade700, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Calculateur d\'économies',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Exemple: 50 livraisons/mois à 5,000 FCFA',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            if (currentTier != LivreurTier.premium) ...[
              _buildSavingsRow(
                'Commission actuelle (${(currentCommission * 100).toInt()}%)',
                '${currentCost.toStringAsFixed(0)} FCFA',
                Colors.red,
              ),
              const SizedBox(height: 8),
              if (currentTier == LivreurTier.starter) ...[
                _buildSavingsRow(
                  'Commission PRO (20%)',
                  '${(deliveryPrice * monthlyDeliveries * 0.20).toStringAsFixed(0)} FCFA',
                  Colors.orange,
                ),
                const SizedBox(height: 8),
                _buildSavingsRow(
                  '💰 Économie mensuelle',
                  '${(currentCost - deliveryPrice * monthlyDeliveries * 0.20).toStringAsFixed(0)} FCFA',
                  Colors.green,
                  isBold: true,
                ),
              ] else if (currentTier == LivreurTier.pro) ...[
                _buildSavingsRow(
                  'Commission PREMIUM (15%)',
                  '${(deliveryPrice * monthlyDeliveries * 0.15).toStringAsFixed(0)} FCFA',
                  Colors.orange,
                ),
                const SizedBox(height: 8),
                _buildSavingsRow(
                  '💰 Économie mensuelle',
                  '${(currentCost - deliveryPrice * monthlyDeliveries * 0.15).toStringAsFixed(0)} FCFA',
                  Colors.green,
                  isBold: true,
                ),
              ],
            ] else ...[
              Text(
                '✅ Vous bénéficiez déjà du meilleur taux de commission !',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSavingsRow(String label, String value, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 15 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

