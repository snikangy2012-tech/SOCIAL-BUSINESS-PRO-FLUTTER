# SYSTÈME D'ABONNEMENTS - SOCIAL BUSINESS Pro

Documentation complète du système d'abonnements pour vendeurs et livreurs.

## 📋 Table des matières

1. [Vue d'ensemble](#vue-densemble)
2. [Architecture](#architecture)
3. [Modèles de données](#modèles-de-données)
4. [Plans vendeurs](#plans-vendeurs)
5. [Niveaux livreurs](#niveaux-livreurs)
6. [Écrans et navigation](#écrans-et-navigation)
7. [Intégration paiement](#intégration-paiement)
8. [Tests](#tests)
9. [Collections Firestore](#collections-firestore)

---

## 📌 Vue d'ensemble

Le système d'abonnements SOCIAL BUSINESS Pro gère deux types d'utilisateurs payants :

### **VENDEURS** - Système d'abonnement mensuel
- **BASIQUE** (Gratuit) : 20 produits, commission 10%
- **PRO** (5,000 FCFA/mois) : 100 produits, commission 10%, AI GPT-3.5
- **PREMIUM** (10,000 FCFA/mois) : Produits illimités, commission 7%, AI GPT-4

### **LIVREURS** - Système de progression par commission
- **STARTER** : Commission 25% (déverrouillé au démarrage)
- **PRO** : Commission 20% (50 livraisons + 4.0★)
- **PREMIUM** : Commission 15% (200 livraisons + 4.5★)

---

## 🏗️ Architecture

```
lib/
├── models/
│   └── subscription_model.dart         # Modèles de données
├── services/
│   └── subscription_service.dart       # Logique métier
├── providers/
│   └── subscription_provider.dart      # Gestion d'état
├── screens/subscription/               # 👈 Module transversal
│   ├── subscription_plans_screen.dart      # Comparaison plans
│   ├── subscription_subscribe_screen.dart  # Paiement
│   ├── subscription_dashboard_screen.dart  # Mon abonnement
│   └── limit_reached_screen.dart           # Alertes limites
└── utils/
    └── subscription_test_helper.dart   # Outils de test
```

### Flux de données

```
UI (Screens)
    ↓
Provider (SubscriptionProvider)
    ↓
Service (SubscriptionService)
    ↓
Firestore (Collections)
```

---

## 📊 Modèles de données

### VendeurSubscription

```dart
class VendeurSubscription {
  final String id;
  final String vendeurId;
  final VendeurSubscriptionTier tier;  // basique | pro | premium
  final SubscriptionStatus status;     // active | expired | cancelled | pending | suspended
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime? nextBillingDate;
  final double monthlyPrice;
  final int productLimit;
  final double commissionRate;
  final bool hasAIAgent;
  final String? aiModel;               // "gpt-3.5-turbo" | "gpt-4"
  final int? aiMessagesPerDay;
  // ...
}
```

### LivreurTierInfo

```dart
class LivreurTierInfo {
  final String id;
  final String livreurId;
  final LivreurTier currentTier;       // starter | pro | premium
  final int totalDeliveries;
  final double averageRating;
  final double currentCommissionRate;
  // ...
}
```

### SubscriptionPayment

```dart
class SubscriptionPayment {
  final String id;
  final String subscriptionId;
  final String vendeurId;
  final double amount;
  final String paymentMethod;          // "Orange Money" | "Wave" | "MTN Money" | "Moov Money"
  final String status;                 // "pending" | "completed" | "failed"
  final DateTime paymentDate;
  final VendeurSubscriptionTier tier;
  final String? transactionId;
  final String? invoiceUrl;
  // ...
}
```

---

## 💼 Plans vendeurs

### BASIQUE (Gratuit)

```yaml
Prix: 0 FCFA/mois
Produits: 20 maximum
Commission: 10% fixe
Agent AI: ❌ Non
Statistiques: Basiques
Support: Email
Badge: Aucun
```

**Création automatique:**
```dart
final subscription = VendeurSubscription.createBasique(vendeurId);
```

### PRO (5,000 FCFA/mois)

```yaml
Prix: 5,000 FCFA/mois
Produits: 100 maximum
Commission: 10% fixe
Agent AI: ✅ GPT-3.5 Turbo (50 messages/jour)
Statistiques: Avancées
Support: Prioritaire
Badge: PRO visible
```

**Revenus pour SOCIAL BUSINESS:**
- Abonnement: 5,000 FCFA/vendeur/mois
- Commission: 10% sur chaque vente
- AI (coût): ~150 FCFA/mois
- **Marge nette: 4,850 FCFA (97%)** + commissions

### PREMIUM (10,000 FCFA/mois)

```yaml
Prix: 10,000 FCFA/mois
Produits: ILLIMITÉS
Commission: 7% réduite (vs 10%)
Agent AI: ✅ GPT-4 (200 messages/jour)
Statistiques: Complètes + analyses business
Support: 24/7
Badge: PREMIUM visible
Visibilité: Prioritaire dans les résultats
```

**Revenus pour SOCIAL BUSINESS:**
- Abonnement: 10,000 FCFA/vendeur/mois
- Commission: 7% sur chaque vente (réduite)
- AI (coût): ~20,000 FCFA/mois *(subsidié par commissions)*
- **Marge: Variable selon volume de ventes**

---

## 🚚 Niveaux livreurs

### STARTER (Par défaut)

```yaml
Prix: Gratuit (commission uniquement)
Commission: 25%
Déverrouillé: À l'inscription
Conditions: Aucune
```

**Revenus pour le livreur:**
- Exemple: 50 livraisons/mois × 800 FCFA/livraison × 75% = **30,000 FCFA/mois**

### PRO

```yaml
Prix: Gratuit (commission uniquement)
Commission: 20%
Déverrouillé: 50 livraisons + 4.0★ de note
Conditions: Automatiques
```

**Revenus pour le livreur:**
- Exemple: 100 livraisons/mois × 1,000 FCFA/livraison × 80% = **80,000 FCFA/mois**

### PREMIUM

```yaml
Prix: Gratuit (commission uniquement)
Commission: 15%
Déverrouillé: 200 livraisons + 4.5★ de note
Conditions: Automatiques
```

**Revenus pour le livreur:**
- Exemple: 200 livraisons/mois × 1,000 FCFA/livraison × 85% = **170,000 FCFA/mois**

### Upgrade automatique

Les livreurs sont automatiquement upgradés lorsqu'ils atteignent les conditions :

```dart
// Dans updateLivreurStats()
if (totalDeliveries >= 50 && averageRating >= 4.0) {
  // Upgrade automatique vers PRO
}

if (totalDeliveries >= 200 && averageRating >= 4.5) {
  // Upgrade automatique vers PREMIUM
}
```

---

## 🖥️ Écrans et navigation

### 1. Plans d'abonnement (`/subscription/plans`)

**Fichier:** `subscription_plans_screen.dart`

**Fonctionnalités:**
- Comparaison visuelle des 3 plans
- Badge "Plan actuel" sur le plan actif
- Badge "RECOMMANDÉ" sur le plan PRO
- Tableau comparatif détaillé
- FAQ intégrée
- Boutons d'action (Choisir / Rétrograder)

**Navigation:**
- Depuis le dashboard vendeur
- Depuis l'écran "Limites atteintes"

### 2. Souscription/Paiement (`/subscription/subscribe`)

**Fichier:** `subscription_subscribe_screen.dart`

**Fonctionnalités:**
- Résumé du plan choisi
- Sélection du fournisseur Mobile Money (Orange, MTN, Wave, Moov)
- Saisie du numéro de téléphone
- Détails de facturation
- Checkbox conditions générales
- Paiement sécurisé Mobile Money
- Modal de succès avec redirection

**Extra parameter:**
```dart
context.push('/subscription/subscribe',
  extra: VendeurSubscriptionTier.pro
);
```

### 3. Mon abonnement (`/subscription/dashboard`)

**Fichier:** `subscription_dashboard_screen.dart`

**Fonctionnalités:**
- Carte du plan actuel (couleur dynamique)
- Alertes d'expiration/renouvellement
- Statistiques d'utilisation (produits, messages AI, ventes)
- Avantages inclus
- Prochain renouvellement
- Historique des paiements (3 derniers)
- Actions : Changer de plan / Annuler

**Pull to refresh:** Oui

### 4. Limites atteintes (`/subscription/limit-reached`)

**Fichier:** `limit_reached_screen.dart`

**Fonctionnalités:**
- Message personnalisé selon le type de limite
- Illustration visuelle
- Carte de la limite actuelle
- Suggestions d'upgrade ciblées
- Alternatives (supprimer produits, désactiver, etc.)

**Extra parameter:**
```dart
context.push('/subscription/limit-reached',
  extra: 'products' // ou 'ai_messages'
);
```

### Navigation - Routes définies

```dart
// Dans app_router.dart
GoRoute(path: '/subscription/plans', ...),
GoRoute(path: '/subscription/subscribe', ...),
GoRoute(path: '/subscription/dashboard', ...),
GoRoute(path: '/subscription/limit-reached', ...),
```

---

## 💳 Intégration paiement

### Fournisseurs supportés

1. **Orange Money** 🟠
2. **MTN Money** 🟡
3. **Wave** 💙
4. **Moov Money** 🔵

### Flux de paiement

```mermaid
User → Sélection plan → Sélection fournisseur → Saisie numéro →
Validation → Mobile Money API → Confirmation → Activation abonnement
```

### Simulation (développement)

```dart
// Dans subscription_subscribe_screen.dart
// Simuler le paiement Mobile Money
await Future.delayed(const Duration(seconds: 2));

// Générer un ID de transaction simulé
final transactionId = 'MM_${DateTime.now().millisecondsSinceEpoch}';

// Upgrader l'abonnement
final success = await subscriptionProvider.upgradeSubscription(
  vendeurId: authProvider.user!.id,
  newTier: widget.tier,
  paymentMethod: _selectedProvider,
  transactionId: transactionId,
);
```

**⚠️ PRODUCTION:** Remplacer par l'intégration réelle de `MobileMoneyService`.

### Enregistrement paiement

Chaque paiement est enregistré dans Firestore :

```dart
SubscriptionPayment(
  subscriptionId: docRef.id,
  vendeurId: vendeurId,
  amount: 5000,
  paymentMethod: 'Orange Money',
  status: 'completed',
  paymentDate: DateTime.now(),
  tier: VendeurSubscriptionTier.pro,
  transactionId: 'OM_123456789',
);
```

---

## 🧪 Tests

### Créer des données de test

```dart
import 'package:social_business_pro/utils/subscription_test_helper.dart';

// Créer tous les utilisateurs de test
final testHelper = SubscriptionTestHelper();
await testHelper.createAllTestData();

// Résultat:
// ✅ test_vendeur_basique (BASIQUE)
// ✅ test_vendeur_pro (PRO)
// ✅ test_vendeur_premium (PREMIUM)
// ✅ test_livreur_starter (STARTER)
// ✅ test_livreur_pro (PRO)
// ✅ test_livreur_premium (PREMIUM)
```

### Afficher un abonnement

```dart
await testHelper.displayVendeurSubscription('test_vendeur_pro');

// Affiche:
// ✅ PLAN: PRO
//    💰 Prix: 5000 FCFA/mois
//    📦 Limite produits: 100
//    💳 Commission: 10%
//    🤖 Agent AI: ✅ gpt-3.5-turbo (50 msgs/jour)
//    ...
```

### Test flux complet vendeur

```dart
await testHelper.testVendeurFlow();

// Exécute:
// 1. Créer BASIQUE
// 2. Upgrade vers PRO
// 3. Upgrade vers PREMIUM
// 4. Test limite produits
// 5. Test taux commission
// 6. Downgrade vers BASIQUE
```

### Test flux complet livreur

```dart
await testHelper.testLivreurFlow();

// Exécute:
// 1. Créer STARTER
// 2. Stats 30 livraisons (pas upgrade)
// 3. Stats 55 livraisons → Upgrade PRO
// 4. Stats 210 livraisons → Upgrade PREMIUM
```

### Nettoyer les données

```dart
await testHelper.cleanAllTestData();
```

### Lancer tous les tests

```dart
await testHelper.runAllTests();

// Exécute:
// - Création données
// - Affichage abonnements
// - Test flux vendeur
// - Test flux livreur
```

---

## 🗄️ Collections Firestore

### `subscriptions`

**Document ID:** Auto-généré

```json
{
  "vendeurId": "user_123",
  "tier": "pro",
  "status": "active",
  "startDate": Timestamp,
  "endDate": null,
  "nextBillingDate": Timestamp,
  "monthlyPrice": 5000,
  "productLimit": 100,
  "commissionRate": 0.10,
  "hasAIAgent": true,
  "aiModel": "gpt-3.5-turbo",
  "aiMessagesPerDay": 50,
  "createdAt": Timestamp,
  "updatedAt": Timestamp,
  "metadata": {}
}
```

**Index requis:**
- `vendeurId` (ASC) + `status` (ASC) + `createdAt` (DESC)

### `livreur_tiers`

**Document ID:** Auto-généré

```json
{
  "livreurId": "user_456",
  "currentTier": "pro",
  "totalDeliveries": 55,
  "averageRating": 4.2,
  "currentCommissionRate": 0.20,
  "createdAt": Timestamp,
  "updatedAt": Timestamp,
  "metadata": {}
}
```

**Index requis:**
- `livreurId` (ASC)

### `subscription_payments`

**Document ID:** Auto-généré

```json
{
  "subscriptionId": "sub_123",
  "vendeurId": "user_123",
  "amount": 5000,
  "paymentMethod": "Orange Money",
  "status": "completed",
  "paymentDate": Timestamp,
  "tier": "pro",
  "transactionId": "OM_987654321",
  "invoiceUrl": null,
  "createdAt": Timestamp
}
```

**Index requis:**
- `vendeurId` (ASC) + `paymentDate` (DESC)

---

## 🔧 API du service

### SubscriptionService

```dart
// VENDEURS
Future<VendeurSubscription?> getVendeurSubscription(String vendeurId)
Future<VendeurSubscription> createBasiqueSubscription(String vendeurId)
Future<VendeurSubscription> upgradeSubscription({...})
Future<VendeurSubscription> downgradeSubscription(String vendeurId)
Future<bool> renewSubscription({...})
Future<bool> checkProductLimit(String vendeurId, int currentProductCount)
Future<double> getVendeurCommissionRate(String vendeurId)
Stream<VendeurSubscription?> subscriptionStream(String vendeurId)

// LIVREURS
Future<LivreurTierInfo?> getLivreurTier(String livreurId)
Future<LivreurTierInfo> createStarterTier(String livreurId)
Future<LivreurTierInfo?> updateLivreurStats({...})
Future<double> getLivreurCommissionRate(String livreurId)
Stream<LivreurTierInfo?> livreurTierStream(String livreurId)

// PAIEMENTS
Future<List<SubscriptionPayment>> getPaymentHistory(String vendeurId)

// TESTS (debug uniquement)
Future<void> createTestData()
Future<void> cleanTestData()
```

### SubscriptionProvider

```dart
// État
VendeurSubscription? vendeurSubscription
LivreurTierInfo? livreurTier
List<SubscriptionPayment> paymentHistory
bool isLoadingSubscription
bool isLoadingTier

// Getters utilitaires
String currentTierName
int productLimit
double commissionRate
bool hasAIAgent
String? alertMessage

// Méthodes
Future<void> loadVendeurSubscription(String vendeurId)
Future<void> loadLivreurTier(String livreurId)
Future<bool> upgradeSubscription({...})
Future<bool> downgradeSubscription(String vendeurId)
Future<bool> renewSubscription({...})
Future<bool> canAddProduct(String vendeurId, int currentProductCount)
Future<void> updateLivreurStats({...})
Future<void> loadPaymentHistory(String vendeurId)
void listenToSubscription(String vendeurId)
void listenToLivreurTier(String livreurId)
void reset()
```

---

## 📚 Cas d'usage

### Vérifier avant d'ajouter un produit

```dart
final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
final authProvider = Provider.of<AuthProvider>(context, listen: false);

// Compter les produits actuels
final currentCount = await countVendeurProducts(authProvider.user!.id);

// Vérifier la limite
final canAdd = await subscriptionProvider.canAddProduct(
  authProvider.user!.id,
  currentCount
);

if (!canAdd) {
  // Rediriger vers l'écran limite atteinte
  context.push('/subscription/limit-reached', extra: 'products');
  return;
}

// Continuer l'ajout
```

### Calculer la commission sur une vente

```dart
final subscriptionService = SubscriptionService();

final commissionRate = await subscriptionService.getVendeurCommissionRate(vendeurId);

final saleAmount = 50000; // FCFA
final commission = saleAmount * commissionRate;
final vendeurReceives = saleAmount - commission;

debugPrint('Vente: $saleAmount FCFA');
debugPrint('Commission (${ (commissionRate * 100).toStringAsFixed(0)}%): $commission FCFA');
debugPrint('Vendeur reçoit: $vendeurReceives FCFA');
```

### Mettre à jour les stats livreur après livraison

```dart
final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);

// Après une livraison réussie
await subscriptionProvider.updateLivreurStats(
  livreurId: livreurId,
  totalDeliveries: newTotalDeliveries,
  averageRating: newAverageRating,
);

// Vérifier si upgrade
if (subscriptionProvider.canUpgradeToPro) {
  // Afficher notification "Vous êtes passé PRO !"
}
```

---

## ⚠️ Points d'attention

### 1. Gestion des expirations

**TODO:** Implémenter un Cloud Function pour gérer les expirations automatiques :

```javascript
// Firebase Cloud Function (à créer)
exports.checkSubscriptionExpiration = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();

    const expiredSubs = await admin.firestore()
      .collection('subscriptions')
      .where('nextBillingDate', '<=', now)
      .where('status', '==', 'active')
      .get();

    for (const sub of expiredSubs.docs) {
      await sub.ref.update({
        status: 'expired',
        endDate: now
      });

      // Créer abonnement BASIQUE de remplacement
      // ...
    }
  });
```

### 2. Renouvellement automatique

**TODO:** Implémenter le renouvellement automatique via Mobile Money récurrent.

### 3. Sécurité

- ✅ Validation côté client
- ⚠️ **À FAIRE:** Règles de sécurité Firestore
- ⚠️ **À FAIRE:** Cloud Functions pour logique métier critique

### 4. Performance

- ✅ Index Firestore créés
- ✅ Streams pour mises à jour temps réel
- ⚠️ **À OPTIMISER:** Cache local pour abonnements actifs

---

## 📈 Prochaines étapes

1. **Intégration Mobile Money réelle**
   - Remplacer simulation par vraies API
   - Gérer callbacks de paiement
   - Webhooks de confirmation

2. **Génération factures PDF**
   - Facture mensuelle d'abonnement
   - Facture de commission hebdomadaire
   - Historique complet

3. **Cloud Functions**
   - Expiration automatique
   - Renouvellement automatique
   - Notifications push

4. **Dashboard admin**
   - Vue sur tous les abonnements
   - Statistiques revenus
   - Gestion manuelle des plans

5. **Agent AI**
   - Intégration OpenAI API
   - Tracking utilisation quotidienne
   - Contexte métier par type utilisateur

---

## 📞 Support

Pour toute question sur le système d'abonnements :
- 📧 Email: dev@socialbusiness.ci
- 📱 Téléphone: +225 07 07 07 07 07

---

**Dernière mise à jour:** Décembre 2024
**Version:** 1.0.0
**Auteur:** Équipe SOCIAL BUSINESS Pro
