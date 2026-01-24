# Architecture - Gestion Financière Super Admin

## Vue d'ensemble

Un dashboard financier complet permettant au super administrateur de visualiser tous les revenus générés par la plateforme SOCIAL BUSINESS Pro.

## Sources de revenus

### 1. Commissions sur ventes (Vendeurs)
- **Taux**: Variable selon l'abonnement vendeur
  - BASIQUE (gratuit): 15%
  - PRO: 10% (10,000 FCFA/mois)
  - PREMIUM: 5% (30,000 FCFA/mois)
- **Calcul**: Sur chaque commande livrée
- **Collection Firestore**: `orders` (filtrer par status = 'delivered')

### 2. Commissions sur livraisons (Livreurs)
- **Taux**: Variable selon l'abonnement livreur
  - STARTER (gratuit): 25%
  - PRO: 15% (5,000 FCFA/mois)
  - PREMIUM: 10% (15,000 FCFA/mois)
- **Calcul**: Sur les frais de livraison de chaque commande
- **Collection Firestore**: `orders` ou `deliveries`

### 3. Abonnements (Vendeurs & Livreurs)
- **Vendeurs**:
  - PRO: 10,000 FCFA/mois
  - PREMIUM: 30,000 FCFA/mois
- **Livreurs**:
  - PRO: 5,000 FCFA/mois
  - PREMIUM: 15,000 FCFA/mois
- **Collection Firestore**: `vendeur_subscriptions`, `livreur_subscriptions`

## Structure de données

### Collection: `platform_revenue` (nouvelle)
```dart
{
  'id': 'auto-generated',
  'type': 'commission_vente' | 'commission_livraison' | 'abonnement_vendeur' | 'abonnement_livreur',
  'amount': double, // Montant du revenu en FCFA
  'sourceId': String, // ID de la commande ou de l'abonnement
  'userId': String, // ID du vendeur ou livreur concerné
  'userType': 'vendeur' | 'livreur',
  'description': String, // Description détaillée
  'metadata': {
    // Pour commissions ventes
    'orderId': String?,
    'orderTotal': double?,
    'commissionRate': double?, // Pourcentage

    // Pour commissions livraisons
    'deliveryFee': double?,
    'deliveryId': String?,

    // Pour abonnements
    'subscriptionTier': String?,
    'subscriptionPeriod': 'monthly',
    'startDate': Timestamp?,
    'endDate': Timestamp?,
  },
  'createdAt': Timestamp,
  'month': int, // 1-12
  'year': int, // 2025, etc.
}
```

### Collection: `financial_summary` (agrégations mensuelles)
```dart
{
  'id': 'YYYY-MM', // Ex: '2025-11'
  'month': int,
  'year': int,

  // Totaux par catégorie
  'commissionsVente': double,
  'commissionsLivraison': double,
  'abonnementsVendeurs': double,
  'abonnementsLivreurs': double,
  'total': double,

  // Statistiques
  'nbCommandesLivrees': int,
  'nbLivraisons': int,
  'nbAbonnementsVendeursActifs': int,
  'nbAbonnementsLivreursActifs': int,

  // Répartition par tier
  'vendeursParTier': {
    'basique': int,
    'pro': int,
    'premium': int,
  },
  'livreursParTier': {
    'starter': int,
    'pro': int,
    'premium': int,
  },

  'updatedAt': Timestamp,
}
```

## Écran Super Admin - Dashboard Finances

### Sections principales

#### 1. Vue d'ensemble (cartes statistiques)
- **Revenu total du mois**: Somme de tous les revenus
- **Commissions ventes**: Total des commissions sur ventes
- **Commissions livraisons**: Total des commissions sur livraisons
- **Abonnements**: Total des revenus d'abonnements

#### 2. Graphiques
- **Graphique linéaire**: Évolution des revenus sur 12 mois
- **Graphique en barres**: Répartition par type de revenu
- **Graphique circulaire**: Distribution des sources de revenus

#### 3. Tableaux détaillés
- **Onglet "Commissions Ventes"**: Liste des commandes avec commissions
- **Onglet "Commissions Livraisons"**: Liste des livraisons avec commissions
- **Onglet "Abonnements"**: Liste des abonnements actifs avec revenus
- **Onglet "Historique"**: Toutes les transactions de revenus

#### 4. Filtres
- Période (Aujourd'hui, Cette semaine, Ce mois, 3 derniers mois, Année, Personnalisé)
- Type de revenu (Toutes, Ventes, Livraisons, Abonnements)
- Export PDF/Excel

## Services nécessaires

### 1. `PlatformRevenueService`
```dart
class PlatformRevenueService {
  // Enregistrer un revenu de commission vente
  static Future<void> recordSaleCommission(OrderModel order);

  // Enregistrer un revenu de commission livraison
  static Future<void> recordDeliveryCommission(DeliveryModel delivery);

  // Enregistrer un revenu d'abonnement
  static Future<void> recordSubscriptionRevenue(SubscriptionModel sub);

  // Récupérer les revenus par période
  static Future<List<RevenueModel>> getRevenueByPeriod(DateTime start, DateTime end);

  // Récupérer le résumé financier d'un mois
  static Future<FinancialSummary> getMonthlySummary(int year, int month);

  // Calculer et mettre à jour le résumé mensuel
  static Future<void> updateMonthlySummary(int year, int month);
}
```

### 2. Intégration automatique
- **Sur commande livrée**: Trigger automatique pour enregistrer la commission vente
- **Sur livraison terminée**: Trigger pour enregistrer la commission livraison
- **Sur paiement d'abonnement**: Trigger pour enregistrer le revenu d'abonnement

## Modèles de données

### `RevenueModel`
```dart
class RevenueModel {
  final String id;
  final RevenueType type;
  final double amount;
  final String sourceId;
  final String userId;
  final UserType userType;
  final String description;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final int month;
  final int year;
}

enum RevenueType {
  commissionVente,
  commissionLivraison,
  abonnementVendeur,
  abonnementLivreur,
}
```

### `FinancialSummary`
```dart
class FinancialSummary {
  final String id; // YYYY-MM
  final int month;
  final int year;

  final double commissionsVente;
  final double commissionsLivraison;
  final double abonnementsVendeurs;
  final double abonnementsLivreurs;
  final double total;

  final int nbCommandesLivrees;
  final int nbLivraisons;
  final int nbAbonnementsVendeursActifs;
  final int nbAbonnementsLivreursActifs;

  final Map<String, int> vendeursParTier;
  final Map<String, int> livreursParTier;

  final DateTime updatedAt;
}
```

## Sécurité

- **Accès restreint**: Uniquement le super admin (`isSuperAdmin: true`)
- **Règles Firestore**:
```javascript
match /platform_revenue/{revenueId} {
  allow read: if request.auth != null && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isSuperAdmin == true;
  allow write: if false; // Seulement via Cloud Functions
}

match /financial_summary/{summaryId} {
  allow read: if request.auth != null && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isSuperAdmin == true;
  allow write: if false; // Seulement via Cloud Functions
}
```

## Cloud Functions (recommandé)

Pour garantir l'intégrité des données financières:

```javascript
// Fonction déclenchée quand une commande est livrée
exports.onOrderDelivered = functions.firestore
  .document('orders/{orderId}')
  .onUpdate(async (change, context) => {
    const newStatus = change.after.data().status;
    const oldStatus = change.before.data().status;

    if (newStatus === 'delivered' && oldStatus !== 'delivered') {
      // Calculer et enregistrer la commission
      await recordSaleCommission(change.after.data());
    }
  });

// Fonction déclenchée lors d'un paiement d'abonnement
exports.onSubscriptionPayment = functions.firestore
  .document('vendeur_subscriptions/{subId}')
  .onCreate(async (snap, context) => {
    await recordSubscriptionRevenue(snap.data());
  });
```

## Phase d'implémentation

### Phase 1 (Immédiat)
1. Créer les modèles `RevenueModel` et `FinancialSummary`
2. Créer le service `PlatformRevenueService`
3. Créer l'écran `SuperAdminFinanceScreen` avec vue basique

### Phase 2 (Court terme)
4. Ajouter les graphiques (charts)
5. Implémenter les filtres et exports
6. Ajouter l'historique détaillé

### Phase 3 (Moyen terme)
7. Implémenter les Cloud Functions pour l'automatisation
8. Ajouter des analyses prédictives
9. Tableau de bord analytics avancé

## Notes
- Pour l'instant, on peut calculer les commissions à la volée en interrogeant les collections existantes
- L'enregistrement dans `platform_revenue` sera ajouté progressivement
- Le super admin doit avoir `isSuperAdmin: true` dans son document utilisateur
