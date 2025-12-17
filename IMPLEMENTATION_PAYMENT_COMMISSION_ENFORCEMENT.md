# IMPLÉMENTATION COMPLÈTE - SYSTÈME DE VERSEMENT DES COMMISSIONS ET PAIEMENTS

## Date d'implémentation
13 décembre 2025

## Vue d'ensemble

Implémentation de deux systèmes parallèles de gestion des versements :
1. **Commission Enforcement** - Pour les vendeurs (Click & Collect)
2. **Payment Enforcement** - Pour les livreurs (Livraison à domicile)

## Architecture des commissions

### Structure de commission (CORRIGÉE)
La plateforme prélève des commissions sur DEUX sources :

1. **Ventes de produits** → Commission vendeur (7-10%)
   - BASIQUE : 10%
   - PRO : 10%
   - PREMIUM : 7%

2. **Frais de livraison** → Commission livreur (15-25%)
   - STARTER : 25%
   - PRO : 20%
   - PREMIUM : 15%

### Flux de paiement

#### 1. Livraison à domicile
```
Acheteur paie livreur (cash/Mobile Money)
  ↓
Livreur collecte le montant TOTAL (produits + livraison)
  ↓
Livreur DOIT verser à la plateforme
  ↓
Plateforme redistribue au vendeur (après déduction commission vendeur)
```

#### 2. Click & Collect
```
Acheteur paie vendeur directement (cash/Mobile Money)
  ↓
Vendeur collecte le montant des produits
  ↓
Vendeur DOIT verser sa commission à la plateforme
```

## Fichiers créés

### 1. Services Backend

#### `lib/services/commission_enforcement_service.dart`
**Rôle** : Gestion des versements de commissions pour vendeurs

**Fonctionnalités** :
- Vérification du statut des commissions impayées
- Système d'alertes progressives (Warning → Soft Block → Hard Block)
- Blocage automatique du compte vendeur
- Enregistrement des versements
- Statistiques et historique

**Seuils par tier d'abonnement** :
- BASIQUE : 50 000 FCFA
- PRO : 100 000 FCFA
- PREMIUM : 150 000 FCFA

**Méthodes principales** :
```dart
checkCommissionStatus(vendorId)  // Vérifie et met à jour le statut
isVendorBlocked(vendorId)        // Vérifie si compte bloqué
recordCommissionPayment(...)     // Enregistre un versement
getCommissionStats(vendorId)     // Statistiques du vendeur
getPaymentHistory(vendorId)      // Historique des versements
```

**Champs Firestore ajoutés au profil vendeur** :
```dart
profile: {
  unpaidCommissions: 0.0,           // Montant total impayé
  commissionAlertLevel: 'none',     // none|warning|softBlock|hardBlock
  isBlockedForCommission: false,    // Compte bloqué ou non
  lastCommissionPayment: Timestamp,
  lastCommissionDate: Timestamp,
  lastCommissionCheck: Timestamp,
  totalCommissionsPaid: 0.0,
}
```

#### `lib/services/payment_enforcement_service.dart`
**Rôle** : Gestion des versements pour livreurs

**Fonctionnalités** :
- Vérification du statut des paiements non effectués
- Système d'alertes progressives
- Blocage automatique du compte livreur
- Enregistrement des dépôts
- Statistiques et historique

**Seuils par niveau de confiance** :
- DÉBUTANT : 30 000 FCFA
- CONFIRMÉ : 75 000 FCFA
- EXPERT : 100 000 FCFA
- VIP : 150 000 FCFA

**Méthodes principales** :
```dart
checkPaymentStatus(livreurId)      // Vérifie et met à jour le statut
isLivreurBlocked(livreurId)        // Vérifie si compte bloqué
recordPaymentDeposit(...)          // Enregistre un dépôt
incrementUnpaidBalance(...)        // Ajoute au solde impayé
getPaymentStats(livreurId)         // Statistiques du livreur
getDepositHistory(livreurId)       // Historique des dépôts
```

**Champs Firestore ajoutés au profil livreur** :
```dart
profile: {
  unpaidBalance: 0.0,                // Montant collecté non versé
  paymentAlertLevel: 'none',         // none|warning|softBlock|hardBlock
  isBlockedForPayment: false,        // Compte bloqué ou non
  lastPaymentDate: Timestamp,
  lastCollectionDate: Timestamp,
  lastPaymentCheck: Timestamp,
  totalPaymentsDeposited: 0.0,
}
```

### 2. Modification de dynamic_commission_service.dart

**Méthodes ajoutées** :

#### `calculateVendorCommission()`
Calcule la commission du vendeur sur une vente
```dart
{
  'productAmount': 50000.0,      // Montant produits (hors livraison)
  'commissionRate': 0.10,        // 10% (selon abonnement)
  'commissionAmount': 5000.0,    // Commission à verser
  'vendorEarnings': 45000.0,     // Ce que garde le vendeur
  'tier': 'basique',
  'deliveryFee': 1500.0,
  'totalAmount': 51500.0,
}
```

#### `getVendorCommissionSummary()`
Résumé des commissions sur une période
```dart
{
  'totalOrders': 25,
  'totalSales': 1250000.0,       // Total ventes (hors livraison)
  'totalCommission': 125000.0,   // Total commissions dues
  'totalEarnings': 1125000.0,    // Total gains vendeur
  'averageCommissionRate': 0.10,
  'periodStart': DateTime,
  'periodEnd': DateTime,
}
```

### 3. Écrans utilisateur

#### `lib/screens/vendeur/commission_payment_screen.dart`
**Écran de versement des commissions pour vendeurs**

**Fonctionnalités** :
- Affichage du solde impayé avec barre de progression
- Indicateur visuel du niveau d'alerte (couleurs)
- Formulaire de paiement Mobile Money
- Historique des versements
- Statistiques de commissions

**Intégration Mobile Money** :
- Orange Money
- MTN Mobile Money
- Moov Money
- Wave

**Workflow** :
1. Vendeur voit son solde impayé
2. Renseigne montant + numéro + provider
3. API Mobile Money initiée
4. Code USSD affiché
5. Vendeur confirme sur téléphone
6. Versement enregistré dans Firestore
7. Statut d'alerte mis à jour automatiquement

#### `lib/screens/livreur/payment_deposit_screen.dart`
**Écran de dépôt pour livreurs**

**Fonctionnalités** :
- Affichage du solde collecté non déposé
- Badge de niveau de confiance
- Indicateur visuel du niveau d'alerte
- Formulaire de dépôt Mobile Money
- Historique des dépôts
- Statistiques de paiements

**Workflow identique à commission_payment_screen**

### 4. Modification du QR Scanner

#### `lib/screens/vendeur/qr_scanner_screen.dart`
**Ajout du tracking automatique des commissions**

**Nouvelles fonctionnalités** (lignes 265-295) :
```dart
// Après confirmation du retrait Click & Collect
1. Calcule le montant des produits (totalAmount - deliveryFee)
2. Récupère le taux de commission du vendeur
3. Calcule la commission due
4. Incrémente profile.unpaidCommissions dans Firestore
5. Met à jour profile.lastCommissionDate
```

**Exemple de calcul** :
```dart
Commande : 50 000 FCFA (produits) + 0 FCFA (Click & Collect)
Vendeur BASIQUE : 10% de commission
Commission due : 5 000 FCFA
→ profile.unpaidCommissions += 5 000 FCFA
```

## Nouvelles collections Firestore

### `commission_payments`
Collection des versements de commissions vendeurs
```dart
{
  vendorId: String,
  amount: double,
  paymentMethod: String,         // 'orange_money'|'mtn_momo'|'moov_money'|'wave'
  transactionId: String?,
  previousBalance: double,
  newBalance: double,
  paidAt: Timestamp,
  createdAt: Timestamp,
}
```

### `livreur_deposits`
Collection des dépôts livreurs
```dart
{
  livreurId: String,
  amount: double,
  paymentMethod: String,
  transactionId: String?,
  previousBalance: double,
  newBalance: double,
  depositedAt: Timestamp,
  createdAt: Timestamp,
}
```

## Indexes Firestore ajoutés

Dans `firestore.indexes.json` :

```json
// Recherche des versements vendeurs
{
  "collectionGroup": "commission_payments",
  "fields": [
    { "fieldPath": "vendorId", "order": "ASCENDING" },
    { "fieldPath": "paidAt", "order": "DESCENDING" }
  ]
},

// Recherche des dépôts livreurs
{
  "collectionGroup": "livreur_deposits",
  "fields": [
    { "fieldPath": "livreurId", "order": "ASCENDING" },
    { "fieldPath": "depositedAt", "order": "DESCENDING" }
  ]
},

// Recherche commandes livrées (pour calcul commissions vendeurs)
{
  "collectionGroup": "orders",
  "fields": [
    { "fieldPath": "vendeurId", "order": "ASCENDING" },
    { "fieldPath": "deliveredAt", "order": "ASCENDING" },
    { "fieldPath": "status", "order": "ASCENDING" }
  ]
},

// Recherche livraisons terminées (pour calcul commissions livreurs)
{
  "collectionGroup": "deliveries",
  "fields": [
    { "fieldPath": "livreurId", "order": "ASCENDING" },
    { "fieldPath": "deliveredAt", "order": "ASCENDING" },
    { "fieldPath": "status", "order": "ASCENDING" }
  ]
}
```

## Système d'alertes progressives

### Niveaux d'alerte (identiques pour vendeurs et livreurs)

1. **NONE** (0-49% du seuil)
   - ✅ Statut : OK
   - Couleur : Vert
   - Aucune restriction

2. **WARNING** (50-74% du seuil)
   - ⚠️ Statut : Attention
   - Couleur : Ambre
   - Notification envoyée
   - Pas de blocage

3. **SOFT BLOCK** (75-99% du seuil)
   - 🚨 Statut : Urgent - Versement requis
   - Couleur : Orange
   - Notification urgente envoyée
   - Pas encore de blocage (avertissement sévère)

4. **HARD BLOCK** (≥100% du seuil)
   - 🔒 Statut : Compte bloqué
   - Couleur : Rouge
   - Notification critique envoyée
   - **Compte bloqué** :
     - Vendeur : Ne peut plus créer de nouveaux produits
     - Livreur : Ne peut plus accepter de nouvelles livraisons

### Notifications automatiques

**Type** : Firebase Cloud Messaging via `NotificationService`

**Déclenchement** : Automatique lors de changement de niveau d'alerte

**Exemples de notifications** :

```dart
// Warning
type: 'commission_warning'
title: '⚠️ Attention - Commissions à verser'
body: 'Vous avez 35 000 FCFA de commissions impayées (seuil: 50 000 FCFA)'

// Soft Block
type: 'commission_soft_block'
title: '🚨 Urgent - Versement requis'
body: 'Vous approchez du seuil de blocage. Versez 45 000 FCFA rapidement.'

// Hard Block
type: 'commission_hard_block'
title: '🔒 Compte bloqué - Commissions impayées'
body: 'Votre compte est bloqué. Versez 55 000 FCFA pour le débloquer.'
```

## Workflow complet d'exemple

### Scénario 1 : Vendeur BASIQUE - Click & Collect

1. **Vente**
   - Acheteur commande pour 100 000 FCFA
   - Click & Collect (0 FCFA livraison)
   - Vendeur confirme commande

2. **Retrait**
   - Acheteur scanne QR code
   - Vendeur confirme retrait via `qr_scanner_screen.dart`
   - **Tracking automatique** :
     ```dart
     productAmount = 100 000 FCFA
     commissionRate = 0.10 (BASIQUE)
     commission = 10 000 FCFA
     profile.unpaidCommissions += 10 000 FCFA
     ```

3. **Accumulation**
   - Après 5 commandes similaires : 50 000 FCFA impayé
   - **ALERTE WARNING déclenchée** (100% du seuil)
   - Notification envoyée

4. **Blocage**
   - Continue sans payer → 60 000 FCFA impayé
   - **HARD BLOCK déclenché**
   - `profile.isBlockedForCommission = true`
   - Ne peut plus vendre

5. **Versement**
   - Vendeur va sur `/vendeur/commission-payment`
   - Verse 60 000 FCFA via Orange Money
   - `profile.unpaidCommissions = 0 FCFA`
   - `profile.isBlockedForCommission = false`
   - Compte débloqué ✅

### Scénario 2 : Livreur CONFIRMÉ - Livraison à domicile

1. **Livraison complétée**
   - Commande : 80 000 FCFA (produits) + 1 500 FCFA (livraison)
   - Livreur collecte 81 500 FCFA
   - **Incrémentation automatique** (à implémenter dans delivery completion) :
     ```dart
     PaymentEnforcementService.incrementUnpaidBalance(
       livreurId: livreurId,
       amount: 81500.0,
       orderId: orderId,
     )
     profile.unpaidBalance += 81 500 FCFA
     ```

2. **Accumulation**
   - Après plusieurs livraisons : 60 000 FCFA collecté
   - Niveau CONFIRMÉ : seuil = 75 000 FCFA
   - 80% du seuil → **SOFT BLOCK**
   - Notification urgente envoyée

3. **Dépôt**
   - Livreur va sur `/livreur/payment-deposit`
   - Dépose 60 000 FCFA via MTN MoMo
   - `profile.unpaidBalance = 0 FCFA`
   - Statut revient à NONE ✅

## Intégration Mobile Money

### Service utilisé
`lib/services/unified_mobile_money_service.dart`

### Méthode d'appel
```dart
final result = await UnifiedMobileMoneyService.initiateClientPayment(
  orderId: transactionId,          // ID unique de transaction
  customerPhone: phoneNumber,      // Numéro du payeur
  amount: amount,                  // Montant en FCFA
  provider: MobileMoneyProvider,   // orange|mtn|moov|wave
);

if (result.success) {
  // Afficher code USSD : result.ussdCode
  // Enregistrer transaction : result.reference
} else {
  // Afficher erreur : result.error
}
```

### Providers supportés
- Orange Money (07/08/09)
- MTN Mobile Money (05/06)
- Moov Money (01)
- Wave

## Points d'intégration requis

### ⚠️ TODO : À implémenter dans d'autres parties du code

1. **Lors de la livraison complétée** (`delivery_service.dart` ou `order_service.dart`)
   ```dart
   // Quand status passe à 'delivered' pour livraison à domicile
   if (deliveryMethod == 'home_delivery') {
     await PaymentEnforcementService.incrementUnpaidBalance(
       livreurId: livreurId,
       amount: totalAmount,
       orderId: orderId,
     );
   }
   ```

2. **Vérification avant acceptation de livraison** (`available_orders_screen.dart`)
   ```dart
   final isBlocked = await PaymentEnforcementService.isLivreurBlocked(livreurId);
   if (isBlocked) {
     // Afficher message : "Compte bloqué. Effectuez un dépôt."
     // Rediriger vers /livreur/payment-deposit
     return;
   }
   ```

3. **Vérification avant création de produit** (`add_product.dart`)
   ```dart
   final isBlocked = await CommissionEnforcementService.isVendorBlocked(vendorId);
   if (isBlocked) {
     // Afficher message : "Compte bloqué. Versez vos commissions."
     // Rediriger vers /vendeur/commission-payment
     return;
   }
   ```

4. **Routes à ajouter** (dans `app_router.dart`)
   ```dart
   GoRoute(
     path: '/vendeur/commission-payment',
     builder: (context, state) => const CommissionPaymentScreen(),
   ),
   GoRoute(
     path: '/livreur/payment-deposit',
     builder: (context, state) => const PaymentDepositScreen(),
   ),
   ```

5. **Liens dans les menus**
   - Menu vendeur : Ajouter "Versements commissions"
   - Menu livreur : Ajouter "Dépôts"
   - Badge de notification si alerte active

## Déploiement Firebase

### 1. Déployer les indexes Firestore
```bash
firebase deploy --only firestore:indexes
```

### 2. Créer les nouvelles collections
Les collections seront créées automatiquement lors du premier document.

### 3. Tester les notifications
Vérifier que FCM est bien configuré pour les notifications.

## Tests recommandés

### Test 1 : Vendeur - Cycle complet de commission
1. Créer compte vendeur BASIQUE
2. Effectuer 5 ventes Click & Collect de 10 000 FCFA chacune
3. Vérifier que `unpaidCommissions = 5 000 FCFA` (10% de 50k)
4. Atteindre le seuil → vérifier alerte WARNING
5. Continuer → vérifier HARD BLOCK
6. Effectuer versement via `/vendeur/commission-payment`
7. Vérifier déblocage du compte

### Test 2 : Livreur - Cycle complet de paiement
1. Créer compte livreur DÉBUTANT
2. Effectuer 2 livraisons de 15 000 FCFA chacune
3. Vérifier que `unpaidBalance = 30 000 FCFA`
4. Atteindre le seuil → vérifier HARD BLOCK
5. Effectuer dépôt via `/livreur/payment-deposit`
6. Vérifier déblocage du compte

### Test 3 : Intégration Mobile Money
1. Tester chaque provider (Orange, MTN, Moov, Wave)
2. Vérifier génération code USSD
3. Vérifier enregistrement transaction
4. Vérifier mise à jour du solde

## Statistiques et métriques

Les services fournissent des statistiques détaillées :

### Vendeur
- Total commissions générées
- Total commissions versées
- Solde impayé actuel
- Pourcentage du seuil atteint
- Tier d'abonnement

### Livreur
- Total collecté
- Total déposé
- Solde impayé actuel
- Pourcentage du seuil atteint
- Niveau de confiance

## Sécurité

### Prévention de fraude
- Tous les versements/dépôts sont horodatés
- Historique complet conservé
- Transactions Mobile Money tracées
- Audit logs recommandés

### Validation
- Montants > 0 requis
- Numéros de téléphone validés (10 chiffres minimum)
- Provider Mobile Money obligatoire
- Vérification du seuil avant blocage

## Performance

### Optimisations implémentées
- Indexes Firestore pour requêtes rapides
- Calculs côté client (pas de cloud functions)
- Mise en cache du statut d'alerte
- Requêtes paginées pour historiques (limit: 10-20)

### Points de vigilance
- Appel API Mobile Money peut prendre 2-5 secondes
- Vérifier connexion réseau avant paiement
- Timeout sur les appels Firestore (10 secondes)

## Documentation technique

### Dépendances requises
```yaml
dependencies:
  firebase_auth: ^latest
  cloud_firestore: ^latest
  http: ^latest          # Pour API Mobile Money
  uuid: ^latest          # Pour IDs de transaction
```

### Imports nécessaires
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/commission_enforcement_service.dart';
import '../services/payment_enforcement_service.dart';
import '../services/unified_mobile_money_service.dart';
```

## Conclusion

✅ **Implémentation complète des 2 systèmes de versement**
- Commission enforcement pour vendeurs
- Payment enforcement pour livreurs
- Alertes progressives avec 4 niveaux
- Blocage automatique des comptes
- Intégration Mobile Money (4 providers)
- Écrans UI complets
- Tracking automatique des commissions
- Indexes Firestore optimisés

🎯 **Prochaines étapes recommandées** :
1. Ajouter les routes dans `app_router.dart`
2. Intégrer les vérifications de blocage dans les workflows
3. Ajouter `incrementUnpaidBalance()` lors des livraisons complétées
4. Tester le workflow complet end-to-end
5. Déployer les indexes Firestore
6. Configurer les comptes marchands Mobile Money

📊 **Impact business** :
- Meilleur contrôle des flux financiers
- Réduction du risque de non-paiement
- Transparence totale pour vendeurs/livreurs
- Automatisation des relances
- Historique complet des transactions
