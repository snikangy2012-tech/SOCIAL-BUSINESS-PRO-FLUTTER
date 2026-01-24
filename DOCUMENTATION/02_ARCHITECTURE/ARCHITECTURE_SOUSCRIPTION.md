# Architecture Transversale de Souscription

## Vue d'ensemble

Le système de souscription de SOCIAL BUSINESS Pro est conçu de manière **transversale** pour gérer intelligemment les deux types d'utilisateurs (vendeurs et livreurs) avec un seul ensemble d'écrans et de composants qui s'adaptent automatiquement selon le type d'utilisateur connecté.

## Principe de conception

### ❌ Ancienne approche (évitée)
```
lib/screens/
├── vendeur/
│   └── subscription/  ← Écrans dédiés vendeurs
├── livreur/
│   └── subscription/  ← Écrans dédiés livreurs (duplication)
```

### ✅ Nouvelle approche (transversale)
```
lib/screens/
└── subscription/  ← Écrans UNIQUES qui s'adaptent au type d'utilisateur
    ├── subscription_management_screen.dart  (actuellement dans /vendeur mais sera déplacé)
    ├── subscription_plans_screen.dart
    ├── subscription_checkout_screen.dart
    └── subscription_dashboard_screen.dart
```

## Modèle Business Finalisé

### Vendeurs - Abonnements Payants Classiques
| Plan | Prix | Produits | Commission | AI Agent |
|------|------|----------|------------|----------|
| **BASIQUE** | 0 FCFA | 20 max | 10% | ❌ |
| **PRO** | 5,000 FCFA/mois | 100 max | 10% | ✅ GPT-3.5 (50 msg/jour) |
| **PREMIUM** | 10,000 FCFA/mois | Illimité | 7% | ✅ GPT-4 (200 msg/jour) |

### Livreurs - Modèle HYBRIDE (Performance + Abonnement)
| Niveau | Prix | Commission | Déblocage | Type |
|--------|------|------------|-----------|------|
| **STARTER** 🚴 | **Gratuit** | 25% | Immédiat | Gratuit à vie |
| **PRO** 🏍️ | **10,000 FCFA/mois** | 20% | 50 livraisons + 4.0★ | Payant après déblocage |
| **PREMIUM** 🚚 | **30,000 FCFA/mois** | 15% | 200 livraisons + 4.5★ | Payant après déblocage |

**Important**: Les livreurs utilisent un **modèle hybride** :
- La **performance** débloque les niveaux (critères de livraisons + note)
- Le **paiement mensuel** active le niveau débloqué
- STARTER reste gratuit à vie (25% commission)
- PRO et PREMIUM nécessitent un abonnement mensuel pour bénéficier de la commission réduite

## Architecture des fichiers

### 1. Modèles de données (`lib/models/subscription_model.dart`)

```dart
// VENDEURS - Abonnements payants classiques
class VendeurSubscription {
  final VendeurSubscriptionTier tier;  // basique, pro, premium
  final double monthlyPrice;           // 0, 5000, 10000
  final int productLimit;              // 20, 100, illimité
  final double commissionRate;         // 0.10, 0.10, 0.07
  final bool hasAIAgent;
  // ...
}

// LIVREURS - Modèle HYBRIDE (Performance + Abonnement)
class LivreurSubscription {
  final LivreurTier tier;                    // starter, pro, premium
  final double monthlyPrice;                 // 0, 10000, 30000
  final double commissionRate;               // 0.25, 0.20, 0.15

  // Critères de déblocage (performance)
  final int requiredDeliveries;              // 0, 50, 200
  final double requiredRating;               // 0.0, 4.0, 4.5
  final LivreurTierUnlockStatus unlockStatus; // locked, unlocked, subscribed

  // Stats actuelles
  final int currentDeliveries;
  final double currentRating;
  // ...
}

enum LivreurTierUnlockStatus {
  locked,      // Pas encore atteint les critères
  unlocked,    // Critères atteints, peut souscrire
  subscribed,  // Souscription active et payée
}
```

**Changements majeurs**:
- ✅ `LivreurSubscription` - NOUVEAU: Modèle hybride avec déblocage par performance + paiement
- ✅ `LivreurSubscriptionPayment` - Gestion des paiements pour PRO et PREMIUM
- ✅ `LivreurTier` - Enum pour starter/pro/premium
- ❌ `LivreurTierInfo` - Remplacé par `LivreurSubscription` complète

### 2. Service (`lib/services/subscription_service.dart`)

```dart
class SubscriptionService {
  // ========== VENDEURS (Abonnements classiques) ==========
  Future<VendeurSubscription?> getVendeurSubscription(String vendeurId);
  Future<VendeurSubscription> upgradeSubscription(...);
  Future<VendeurSubscription> downgradeSubscription(...);
  Future<bool> renewSubscription(...);
  Future<double> getVendeurCommissionRate(String vendeurId);

  // ========== LIVREURS (Modèle HYBRIDE) ==========
  Future<LivreurSubscription?> getLivreurSubscription(String livreurId);
  Future<LivreurSubscription> createStarterLivreurSubscription(String livreurId);

  // Upgrade/Downgrade (avec validation de performance + paiement)
  Future<LivreurSubscription> upgradeLivreurSubscription({
    required String livreurId,
    required LivreurTier newTier,
    required String paymentMethod,
    required String transactionId,
    required int currentDeliveries,    // Vérification perf
    required double currentRating,     // Vérification perf
  });
  Future<LivreurSubscription> downgradeLivreurSubscription(String livreurId);

  // Mise à jour des stats (déclenche déblocage automatique)
  Future<LivreurSubscription?> updateLivreurPerformanceStats({
    required String livreurId,
    required int totalDeliveries,
    required double averageRating,
  });

  Future<double> getLivreurCommissionRate(String livreurId);
  Future<List<LivreurSubscriptionPayment>> getLivreurPaymentHistory(String livreurId);
}
```

### 3. Provider (`lib/providers/subscription_provider.dart`)

```dart
class SubscriptionProvider with ChangeNotifier {
  // État VENDEUR
  VendeurSubscription? _vendeurSubscription;
  bool _isLoadingSubscription;

  // État LIVREUR (modèle HYBRIDE)
  LivreurSubscription? _livreurSubscription;
  bool _isLoadingLivreurSubscription;

  // Getters utilitaires livreur
  bool get hasActiveLivreurSubscription => _livreurSubscription?.isActive ?? false;
  String get livreurTierName => _livreurSubscription?.tierName ?? 'STARTER';
  double get livreurCommissionRate => _livreurSubscription?.commissionRate ?? 0.25;
  int get totalDeliveries => _livreurSubscription?.currentDeliveries ?? 0;
  double get averageRating => _livreurSubscription?.currentRating ?? 0.0;

  // Méthodes VENDEUR
  Future<void> loadVendeurSubscription(String vendeurId);
  Future<bool> upgradeSubscription(...);
  Future<bool> downgradeSubscription(...);

  // Méthodes LIVREUR (modèle HYBRIDE)
  Future<void> loadLivreurSubscription(String livreurId);
  Future<bool> upgradeLivreurSubscription({...});  // Avec paiement
  Future<bool> downgradeLivreurSubscription(String livreurId);
  Future<void> updateLivreurPerformanceStats({...}); // Déclenche déblocage auto
}
```

### 4. Écrans transversaux

#### `subscription_management_screen.dart`
Écran principal qui s'adapte au type d'utilisateur :

```dart
@override
Widget build(BuildContext context) {
  final authProvider = context.watch<AuthProvider>();
  final user = authProvider.user;

  return Scaffold(
    body: Consumer<SubscriptionProvider>(
      builder: (context, subscriptionProvider, child) {
        // Adaptation automatique selon le type d'utilisateur
        if (user?.userType == UserType.vendeur) {
          return _buildVendeurContent(context, subscriptionProvider);
        } else if (user?.userType == UserType.livreur) {
          return _buildLivreurContent(context, subscriptionProvider);
        }

        return const Center(child: Text("Non disponible pour ce type d'utilisateur"));
      },
    ),
  );
}

Widget _buildVendeurContent(BuildContext context, SubscriptionProvider provider) {
  final VendeurSubscription? subscription = provider.vendeurSubscription;
  // Affiche: Plan actuel, upgrade/downgrade, paiement, limites
}

Widget _buildLivreurContent(BuildContext context, SubscriptionProvider provider) {
  final LivreurSubscription? subscription = provider.livreurSubscription;
  // Affiche:
  // - Niveau actuel avec statut de déblocage (locked/unlocked/subscribed)
  // - Stats de performance (livraisons, note)
  // - Progression vers déblocage du prochain niveau
  // - Options de paiement SI niveau débloqué (unlocked) mais pas encore souscrit
  // - Tarifs: STARTER gratuit, PRO 10k/mois, PREMIUM 30k/mois
}
```

## Routes transversales

```dart
// Dans app_router.dart
GoRoute(
  path: '/subscription',
  builder: (context, state) => const SubscriptionManagementScreen(),
  // ☝️ Même route pour vendeurs ET livreurs
),

GoRoute(
  path: '/subscription/plans',
  builder: (context, state) => const SubscriptionPlansScreen(),
  // ☝️ Affiche plans vendeurs OU progression livreurs selon le contexte
),
```

## Avantages de l'approche transversale

### ✅ Avantages

1. **Moins de duplication de code**
   - Un seul écran au lieu de deux
   - Maintenance simplifiée

2. **Cohérence UI/UX**
   - Même structure visuelle pour tous
   - Navigation uniforme

3. **Évolutivité**
   - Facile d'ajouter un nouveau type d'utilisateur (ex: Admin)
   - Facile d'ajouter de nouvelles fonctionnalités

4. **Réutilisabilité**
   - Composants partagés (cartes de plan, boutons, etc.)
   - Logique métier centralisée

### ⚠️ Points d'attention

1. **Logique conditionnelle**
   - Toujours vérifier `user?.userType` avant d'afficher du contenu
   - Ne jamais afficher d'options de paiement pour livreurs

2. **Gestion d'état**
   - Provider doit gérer deux états différents (vendeur ET livreur)
   - Bien séparer les getters et méthodes

3. **Routes**
   - Routes accessibles par tous les types d'utilisateurs
   - Protection au niveau du contenu, pas de la route

## Collections Firestore

```
subscriptions/                 ← Abonnements VENDEURS
  {subscriptionId}/
    - vendeurId
    - tier: 'basique' | 'pro' | 'premium'
    - monthlyPrice: 0 | 5000 | 10000
    - status: 'active' | 'expired' | ...
    - nextBillingDate

livreur_subscriptions/         ← Abonnements LIVREURS (modèle HYBRIDE)
  {subscriptionId}/
    - livreurId
    - tier: 'starter' | 'pro' | 'premium'
    - monthlyPrice: 0 | 10000 | 30000
    - commissionRate: 0.25 | 0.20 | 0.15
    - requiredDeliveries: 0 | 50 | 200
    - requiredRating: 0.0 | 4.0 | 4.5
    - unlockStatus: 'locked' | 'unlocked' | 'subscribed'
    - currentDeliveries
    - currentRating
    - status: 'active' | 'expired' | ...
    - startDate, endDate

subscription_payments/         ← Paiements VENDEURS
  {paymentId}/
    - vendeurId
    - amount
    - tier

livreur_subscription_payments/ ← Paiements LIVREURS (PRO et PREMIUM uniquement)
  {paymentId}/
    - livreurId
    - amount: 10000 | 30000
    - tier: 'pro' | 'premium'
    - paymentMethod
    - transactionId
```

**Note**: Les livreurs STARTER ne paient pas, mais PRO et PREMIUM nécessitent des paiements mensuels.

## Workflow typique

### Pour un vendeur

1. **Connexion** → Provider charge `VendeurSubscription`
2. **Navigation vers /subscription** → Affiche plan actuel (BASIQUE par défaut)
3. **Clic sur "Upgrade vers PRO"** → Processus de paiement
4. **Paiement réussi** → Mise à jour subscription + limitations appliquées
5. **Ajout de produit** → Vérification `canAddProduct()` selon limite

### Pour un livreur (Modèle HYBRIDE)

1. **Connexion** → Provider charge `LivreurSubscription` (STARTER par défaut)
2. **Navigation vers /subscription** → Affiche niveau actuel avec stats de performance
3. **Complète une livraison** → `updateLivreurPerformanceStats()` appelé
4. **50 livraisons + 4.0★ atteint** → **Statut PRO passe à "unlocked"** 🔓
5. **Livreur voit "PRO débloqué"** → Peut cliquer sur "Souscrire pour 10,000 FCFA/mois"
6. **Paiement réussi** → Statut passe à "subscribed", commission 25% → 20%
7. **Renouvellement mensuel** → Paiement automatique ou manuel selon config
8. **Si non renouvelé** → Retour à STARTER (25% commission)

## Migration depuis l'ancien modèle

Si vous avez des données avec l'ancien modèle (livreurs sans abonnements payants):

```dart
// Script de migration (à exécuter une fois)
Future<void> migrateLivreurTiersToHybridSubscriptions() async {
  final tiers = await FirebaseFirestore.instance
      .collection('livreur_tiers')  // Ancienne collection
      .get();

  for (var doc in tiers.docs) {
    final tierInfo = LivreurTierInfo.fromFirestore(doc);

    // Créer un LivreurSubscription avec le nouveau modèle hybride
    final subscription = LivreurSubscription(
      livreurId: tierInfo.livreurId,
      tier: tierInfo.currentTier,
      monthlyPrice: _getPriceForTier(tierInfo.currentTier),  // 0, 10000, 30000
      commissionRate: tierInfo.currentCommissionRate,
      requiredDeliveries: _getRequiredDeliveries(tierInfo.currentTier),
      requiredRating: _getRequiredRating(tierInfo.currentTier),
      unlockStatus: _determineUnlockStatus(tierInfo),  // Basé sur stats actuelles
      currentDeliveries: tierInfo.totalDeliveries,
      currentRating: tierInfo.averageRating,
      status: 'active',
      startDate: DateTime.now(),
      endDate: tierInfo.currentTier == LivreurTier.starter
          ? null  // Gratuit à vie
          : DateTime.now().add(Duration(days: 30)),
    );

    await FirebaseFirestore.instance
        .collection('livreur_subscriptions')
        .add(subscription.toMap());
  }

  // Vérifier puis supprimer l'ancienne collection 'livreur_tiers'
}
```

## Prochaines étapes

- [x] ✅ Architecture transversale complète dans `/subscription`
- [x] ✅ `subscription_management_screen.dart` - Écran principal adaptatif
- [x] ✅ `subscription_plans_screen.dart` - Comparaison des plans
- [x] ✅ `subscription_subscribe_screen.dart` - Processus de paiement
- [x] ✅ `limit_reached_screen.dart` - Gestion des limites/encouragement upgrade
- [x] ✅ Routes transversales dans `app_router.dart`
- [x] ✅ Modèle hybride pour livreurs implémenté
- [x] ✅ Intégration dans profils vendeur et livreur
- [ ] Intégrer les limites dans `ProductService` (vérification avant ajout)
- [ ] Intégrer le calcul de commission dans `DeliveryService`
- [ ] Créer des tests pour vérifier l'adaptation selon le type d'utilisateur
- [ ] Implémenter le renouvellement automatique des abonnements
- [ ] Ajouter des notifications pour déblocage de niveau (livreurs)

## Références

- Modèle business: `BUSINESS_MODEL.md`
- Routes complètes: `ROUTES_DOCUMENTATION.md`
- Guide de déploiement: `SOLUTION_PRODUCTION.md`
