import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:social_business_pro/config/constants.dart';
import '../../models/subscription_model.dart';
import '../../providers/auth_provider_firebase.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/system_ui_scaffold.dart';

class SubscriptionManagementScreen extends StatelessWidget {
  const SubscriptionManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return SystemUIScaffold(
      appBar: AppBar(
        title: const Text('Gestion de l\'Abonnement'),
        centerTitle: true,
      ),
      body: Consumer<SubscriptionProvider>(
        builder: (context, subscriptionProvider, child) {
          if (subscriptionProvider.isLoadingSubscription ||
              subscriptionProvider.isLoadingLivreurSubscription) {
            return const Center(child: CircularProgressIndicator());
          }

          if (user?.userType == UserType.vendeur) {
            return _buildVendeurContent(context, subscriptionProvider);
          } else if (user?.userType == UserType.livreur) {
            return _buildLivreurContent(context, subscriptionProvider);
          }

          return const Center(
            child: Text("La gestion d'abonnement n'est pas disponible pour ce compte."),
          );
        },
      ),
    );
  }

  // ======== VENDEUR UI ========
  Widget _buildVendeurContent(BuildContext context, SubscriptionProvider provider) {
    final VendeurSubscription? subscription = provider.vendeurSubscription;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCurrentVendeurPlanCard(context, subscription),
          const SizedBox(height: 24),
          const Text(
            'Changer de plan',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildPlanOptionCard(
            context,
            tier: VendeurSubscriptionTier.pro,
            title: 'Plan PRO',
            price: '5,000 FCFA / mois',
            features: [
              '100 produits dans votre boutique',
              'Accès à l\'assistant IA (GPT-3.5)',
              'Commission de 10%',
            ],
            color: AppColors.primary,
            currentTier: subscription?.tier,
          ),
          const SizedBox(height: 16),
          _buildPlanOptionCard(
            context,
            tier: VendeurSubscriptionTier.premium,
            title: 'Plan PREMIUM',
            price: '10,000 FCFA / mois',
            features: [
              'Produits illimités',
              'Accès à l\'assistant IA avancé (GPT-4)',
              'Commission réduite à 7%',
              'Support prioritaire',
            ],
            color: const Color(0xFFFFD700),
            currentTier: subscription?.tier,
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentVendeurPlanCard(BuildContext context, VendeurSubscription? subscription) {
    if (subscription == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Aucun abonnement actif.'),
        ),
      );
    }

    return InkWell(
      onTap: () => context.push('/subscription/dashboard'),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.primary.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Votre Plan Actuel: ${subscription.tierName}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subscription.tierDescription,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const Divider(color: Colors.white54, height: 32),
              if (subscription.endDate != null)
                _buildInfoRow(
                  Icons.calendar_today,
                  'Expire le: ${subscription.endDate!.day}/${subscription.endDate!.month}/${subscription.endDate!.year}',
                )
              else
                _buildInfoRow(Icons.all_inclusive, 'Plan gratuit à vie'),
              const SizedBox(height: 12),
              _buildInfoRow(Icons.inventory_2, 'Limite de produits: ${subscription.productLimit}'),
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerRight,
                child: Text('Voir détails →', style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ======== LIVREUR UI ========
  // NOTE: Modèle HYBRIDE - Performance débloque les niveaux, paiement les active
  // STARTER: Gratuit - 25% commission
  // PRO: 10,000 FCFA/mois - 20% commission (débloqué à 50 livraisons + 4.0★)
  // PREMIUM: 30,000 FCFA/mois - 15% commission (débloqué à 200 livraisons + 4.5★)
  Widget _buildLivreurContent(BuildContext context, SubscriptionProvider provider) {
    final LivreurSubscription? subscription = provider.livreurSubscription;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCurrentLivreurSubscriptionCard(context, subscription),
          const SizedBox(height: 24),
          const Text(
            '🎯 Plans d\'Abonnement',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Débloquez de nouveaux niveaux par vos performances, puis souscrivez pour les activer',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          _buildLivreurSubscriptionCard(
            context,
            subscription: subscription,
            tier: LivreurTier.starter,
            title: '🚴 STARTER',
            price: 'Gratuit',
            commission: '25%',
            unlockCondition: 'Débloqué dès le départ',
            features: [
              'Commission 25% par livraison',
              'Zone de livraison normale',
              'Support par FAQ'
            ],
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          _buildLivreurSubscriptionCard(
            context,
            subscription: subscription,
            tier: LivreurTier.pro,
            title: '🏍️ PRO',
            price: '10,000 FCFA/mois',
            commission: '20%',
            unlockCondition: '50 livraisons + Note 4.0★',
            features: [
              'Commission réduite 20%',
              'Zone étendue',
              'Badge PRO',
              'Statistiques avancées'
            ],
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildLivreurSubscriptionCard(
            context,
            subscription: subscription,
            tier: LivreurTier.premium,
            title: '🚚 PREMIUM',
            price: '30,000 FCFA/mois',
            commission: '15%',
            unlockCondition: '200 livraisons + Note 4.5★',
            features: [
              'Commission optimale 15%',
              'Priorité maximale',
              'Badge PREMIUM',
              'Support 24/7',
              'Statistiques complètes'
            ],
            color: Colors.amber.shade700,
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentLivreurSubscriptionCard(
      BuildContext context, LivreurSubscription? subscription) {
    if (subscription == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Aucun abonnement disponible.'),
        ),
      );
    }

    final Color tierColor = subscription.tier == LivreurTier.premium
        ? Colors.amber.shade700
        : subscription.tier == LivreurTier.pro
            ? Colors.blue
            : Colors.grey;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [tierColor, tierColor.withValues(alpha: 0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Plan Actuel: ${subscription.tierName}',
              style:
                  const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              subscription.tierDescription,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const Divider(color: Colors.white54, height: 32),
            _buildInfoRow(Icons.local_shipping, 'Livraisons: ${subscription.currentDeliveries}'),
            const SizedBox(height: 12),
            _buildInfoRow(
                Icons.star, 'Note moyenne: ${subscription.currentRating.toStringAsFixed(1)}★'),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.percent,
                'Commission: ${(subscription.commissionRate * 100).toStringAsFixed(0)}%'),
            if (subscription.monthlyPrice > 0) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                  Icons.payments, '${subscription.monthlyPrice.toStringAsFixed(0)} FCFA/mois'),
            ],
            if (subscription.endDate != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.calendar_today,
                'Expire le: ${subscription.endDate!.day}/${subscription.endDate!.month}/${subscription.endDate!.year}',
              ),
            ],

            // Progression vers le prochain niveau
            if (subscription.tier != LivreurTier.premium) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subscription.tier == LivreurTier.starter
                          ? 'Progression vers PRO:'
                          : 'Progression vers PREMIUM:',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (subscription.tier == LivreurTier.starter) ...[
                      if (subscription.currentDeliveries < 50)
                        Text(
                          '• Encore ${50 - subscription.currentDeliveries} livraisons',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      if (subscription.currentRating < 4.0)
                        Text(
                          '• Note minimum: 4.0★ (actuelle: ${subscription.currentRating.toStringAsFixed(1)}★)',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      if (subscription.currentDeliveries >= 50 && subscription.currentRating >= 4.0)
                        const Text(
                          '✅ Niveau PRO débloqué! Vous pouvez souscrire.',
                          style: TextStyle(
                              color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                    ],
                    if (subscription.tier == LivreurTier.pro) ...[
                      if (subscription.currentDeliveries < 200)
                        Text(
                          '• Encore ${200 - subscription.currentDeliveries} livraisons',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      if (subscription.currentRating < 4.5)
                        Text(
                          '• Note minimum: 4.5★ (actuelle: ${subscription.currentRating.toStringAsFixed(1)}★)',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      if (subscription.currentDeliveries >= 200 &&
                          subscription.currentRating >= 4.5)
                        const Text(
                          '✅ Niveau PREMIUM débloqué! Vous pouvez souscrire.',
                          style: TextStyle(
                              color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLivreurSubscriptionCard(
    BuildContext context, {
    required LivreurSubscription? subscription,
    required LivreurTier tier,
    required String title,
    required String price,
    required String commission,
    required String unlockCondition,
    required List<String> features,
    required Color color,
  }) {
    final bool isCurrentTier = subscription?.tier == tier;

    // Déterminer le statut de déblocage pour ce tier
    LivreurTierUnlockStatus unlockStatus = LivreurTierUnlockStatus.locked;

    if (subscription != null) {
      if (tier == LivreurTier.starter) {
        unlockStatus = LivreurTierUnlockStatus.unlocked; // STARTER toujours débloqué
      } else if (tier == LivreurTier.pro) {
        if (subscription.currentDeliveries >= 50 && subscription.currentRating >= 4.0) {
          unlockStatus = subscription.tier == LivreurTier.pro &&
                  subscription.unlockStatus == LivreurTierUnlockStatus.subscribed
              ? LivreurTierUnlockStatus.subscribed
              : LivreurTierUnlockStatus.unlocked;
        }
      } else if (tier == LivreurTier.premium) {
        if (subscription.currentDeliveries >= 200 && subscription.currentRating >= 4.5) {
          unlockStatus = subscription.tier == LivreurTier.premium &&
                  subscription.unlockStatus == LivreurTierUnlockStatus.subscribed
              ? LivreurTierUnlockStatus.subscribed
              : LivreurTierUnlockStatus.unlocked;
        }
      }
    }

    final bool isLocked = unlockStatus == LivreurTierUnlockStatus.locked;
    final bool isUnlocked = unlockStatus == LivreurTierUnlockStatus.unlocked;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isCurrentTier ? color : Colors.transparent,
          width: 2,
        ),
      ),
      child: Opacity(
        opacity: isLocked ? 0.6 : 1.0,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                  if (isCurrentTier)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'ACTUEL',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else if (isUnlocked)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'DÉBLOQUÉ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else if (isLocked)
                    const Icon(Icons.lock, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                price,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Commission: $commission',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '🔓 $unlockCondition',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const Divider(height: 24),
              ...features.map((feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(Icons.check, color: color, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(feature)),
                      ],
                    ),
                  )),
              const SizedBox(height: 16),

              // Bouton d'action selon le statut
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isCurrentTier
                      ? null
                      : isUnlocked && !isCurrentTier && tier != LivreurTier.starter
                          ? () {
                              // Navigation vers la souscription avec le tier livreur
                              context.push('/subscription/subscribe', extra: tier);
                            }
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: Text(
                    isCurrentTier
                        ? 'Plan Actuel'
                        : isUnlocked && tier != LivreurTier.starter
                            ? 'Souscrire Maintenant'
                            : tier == LivreurTier.starter
                                ? 'Gratuit'
                                : 'Verrouillé',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ======== GENERIC WIDGETS ========
  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 14)),
      ],
    );
  }

  Widget _buildPlanOptionCard(
    BuildContext context, {
    required Object tier,
    required String title,
    required String price,
    required List<String> features,
    required Color color,
    Object? currentTier,
  }) {
    final bool isCurrentPlan = tier == currentTier;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isCurrentPlan ? color : Colors.transparent, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(price, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
            const Divider(height: 24),
            ...features.map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.check, color: color, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(feature)),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isCurrentPlan
                    ? null
                    : () => context.push('/subscription/subscribe', extra: tier),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                child: Text(isCurrentPlan ? 'Plan Actuel' : 'Choisir ce plan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
