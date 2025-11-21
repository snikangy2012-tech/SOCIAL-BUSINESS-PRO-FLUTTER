# Système de Remboursement et Retour de Produits

## Vue d'ensemble

Le système de remboursement permet aux acheteurs de retourner des produits et d'être remboursés selon le mode de paiement utilisé. Il gère automatiquement la répartition des frais de livraison et assure une traçabilité complète via l'historique des paiements.

## Architecture

### Modèles de données

#### RefundModel (`lib/models/refund_model.dart`)
```dart
class RefundModel {
  final String id;
  final String orderId;
  final String buyerId;
  final String buyerName;
  final String vendeurId;
  final String vendeurName;
  final String? livreurId;
  final String? livreurName;

  // Détails de la demande
  final String reason;              // Raison du retour
  final String description;         // Description détaillée
  final List<String> images;        // Photos du produit

  // Montants
  final double productAmount;       // Montant du produit à rembourser
  final double deliveryFee;         // Frais de livraison aller-retour
  final double vendeurDeliveryCharge;  // Part du vendeur (50%)
  final double livreurDeliveryCharge;  // Part du livreur (50%)

  // Informations paiement
  final String paymentMethod;       // cash_on_delivery, mobile_money, bank_card
  final bool isPrepaid;             // true si payé avant livraison

  // Statut et workflow
  final String status;              // demande_envoyee, approuvee, refusee, produit_retourne, rembourse
  final DateTime requestedAt;
  final DateTime? approvedAt;
  final DateTime? returnedAt;
  final DateTime? refundedAt;

  // Traçabilité
  final String? vendeurNote;        // Note du vendeur
  final String? refundReference;    // Référence du remboursement
}
```

#### Modifications OrderModel (`lib/models/order_model.dart`)
Ajout des champs suivants:
- `String? refundId` - ID du remboursement associé
- `String? refundStatus` - Statut du remboursement
- `String? paymentMethod` - Méthode de paiement utilisée
- `String? vendeurName` - Nom du vendeur

Méthodes helper:
- `bool get canBeReturned` - Vérifie si la commande peut être retournée
- `bool get hasRefundPending` - Vérifie si un remboursement est en cours

### Enums et Constantes (`lib/config/constants.dart`)

#### RefundStatus
- `demandeEnvoyee` - Demande de retour envoyée par l'acheteur
- `approuvee` - Demande approuvée par le vendeur
- `refusee` - Demande refusée par le vendeur
- `produitRetourne` - Produit retourné au vendeur
- `rembourse` - Remboursement effectué par le vendeur

Chaque statut a:
- `label` - Libellé en français
- `color` - Couleur associée (warning, info, error, success)
- `icon` - Icône Material

#### RefundReasons
Raisons prédéfinies:
- `produit_defectueux` - Produit défectueux
- `produit_different` - Produit différent de la commande
- `mauvaise_taille_couleur` - Mauvaise taille ou couleur
- `non_conforme_description` - Non conforme à la description
- `arrive_endommage` - Arrivé endommagé
- `autre` - Autre raison

#### Collection Firestore
- `FirebaseCollections.refunds` - Collection des remboursements

### Services

#### RefundService (`lib/services/refund_service.dart`)

##### Méthodes principales

**1. createRefundRequest()**
Crée une demande de remboursement:
- Vérifie que la commande est livrée ou en cours
- Calcule les montants (produit, frais livraison aller-retour)
- Répartit les frais de livraison 50/50 entre vendeur et livreur
- Upload les photos vers Firebase Storage
- Crée le document dans Firestore
- Met à jour la commande avec `refundId` et `refundStatus`
- Notifie le vendeur

```dart
final refundId = await RefundService.createRefundRequest(
  order: order,
  buyerId: buyerId,
  buyerName: buyerName,
  reason: 'produit_defectueux',
  description: 'Le produit est cassé',
  images: ['url1', 'url2'],
);
```

**2. approveRefund()**
Approuve une demande de retour (vendeur):
- Met à jour le statut à `approuvee`
- Enregistre la note du vendeur (optionnelle)
- Met à jour la commande
- Notifie l'acheteur

**3. refuseRefund()**
Refuse une demande de retour (vendeur):
- Met à jour le statut à `refusee`
- Enregistre la raison du refus
- Met à jour la commande
- Notifie l'acheteur

**4. markProductReturned()**
Marque le produit comme retourné (livreur):
- Met à jour le statut à `produit_retourne`
- Enregistre les frais de livraison dans l'historique des paiements
- Crée 2 entrées de paiement:
  - Débit vendeur (50% des frais)
  - Débit livreur (50% des frais)
- Notifie le vendeur et l'acheteur

**5. markRefundCompleted()**
Marque le remboursement comme effectué (vendeur):
- Met à jour le statut à `rembourse`
- Enregistre la référence de transaction
- Enregistre le remboursement dans l'historique des paiements
- Crée 2 entrées de paiement:
  - Crédit acheteur (montant du produit)
  - Débit vendeur (montant du produit)
- Notifie l'acheteur

**6. getRefundsForUser()**
Stream des remboursements pour un utilisateur (acheteur ou vendeur)

**7. getRefundById()**
Récupère un remboursement par ID

**8. getRefundByOrderId()**
Récupère le remboursement d'une commande

##### Méthodes privées

**_recordDeliveryCharges()**
Enregistre les frais de livraison dans l'historique:
```dart
// Frais vendeur (débit)
{
  'type': 'refund_delivery_charge',
  'amount': -vendeurDeliveryCharge,
  'description': 'Frais de livraison retour (part vendeur)'
}

// Frais livreur (débit)
{
  'type': 'refund_delivery_charge',
  'amount': -livreurDeliveryCharge,
  'description': 'Frais de livraison retour (part livreur)'
}
```

**_recordRefundPayment()**
Enregistre le remboursement dans l'historique:
```dart
// Remboursement acheteur (crédit)
{
  'type': 'refund',
  'amount': productAmount,
  'description': 'Remboursement commande #XXXXX',
  'reference': refundReference
}

// Remboursement vendeur (débit)
{
  'type': 'refund',
  'amount': -productAmount,
  'description': 'Remboursement commande #XXXXX',
  'reference': refundReference
}
```

### Interfaces utilisateur

#### RequestRefundScreen (`lib/screens/acheteur/request_refund_screen.dart`)

Écran de demande de retour pour l'acheteur.

**Fonctionnalités:**
- Affichage des informations de commande
- Sélection de la raison du retour (radio buttons)
- Description détaillée (minimum 20 caractères)
- Upload de photos (max 5) avec preview
- Affichage du montant remboursable (hors frais de livraison)
- Informations importantes sur le processus

**Validation:**
- Raison obligatoire
- Description minimum 20 caractères
- Photos optionnelles

**Actions:**
- Upload des photos vers Firebase Storage
- Création de la demande via RefundService
- Retour avec résultat

#### RefundManagementScreen (`lib/screens/vendeur/refund_management_screen.dart`)

Écran de gestion des retours pour le vendeur.

**Fonctionnalités:**
- Filtrage par statut (onglets):
  - Toutes
  - En attente
  - Approuvées
  - Retournées
  - Remboursées
  - Refusées
- Liste des demandes avec:
  - Numéro de commande
  - Nom de l'acheteur
  - Raison du retour
  - Montant à rembourser
  - Date de demande
  - Badge de statut coloré
- Actions selon le statut:
  - **En attente:** Boutons Approuver / Refuser
  - **Retournée:** Bouton "Marquer comme remboursé"
- Modal de détails complet:
  - Informations client
  - Informations commande
  - Raison et description
  - Photos du produit
  - Détail des frais de livraison
  - Note du vendeur (si refusé)

**Dialogs:**
- Approbation: Confirmation simple
- Refus: Saisie de la raison obligatoire
- Remboursement: Saisie de la référence de transaction obligatoire

#### Intégration dans OrderDetailScreen (`lib/screens/acheteur/order_detail_screen.dart`)

**Bouton de demande de retour:**
- Affiché si `order.canBeReturned && !order.hasRefundPending`
- Style: OutlinedButton avec couleur warning
- Navigation vers RequestRefundScreen
- Rechargement de la commande au retour

**Badge de statut du remboursement:**
- Affiché si `order.hasRefundPending`
- Container avec couleur info
- Affiche le statut actuel du remboursement
- Icône info_outline

### Routing

Route ajoutée dans `lib/routes/app_router.dart`:
```dart
GoRoute(
  path: '/vendeur/refunds',
  builder: (context, state) => const RefundManagementScreen()
)
```

## Workflow complet

### Cas 1: Paiement prépayé (Mobile Money / Carte bancaire)

1. **Acheteur demande un retour**
   - Remplit le formulaire avec raison + description + photos
   - Système crée le remboursement avec statut `demande_envoyee`
   - Vendeur reçoit une notification

2. **Vendeur examine la demande**
   - Option A: Approuve → Statut passe à `approuvee`
   - Option B: Refuse → Statut passe à `refusee` (fin du processus)

3. **Livreur retourne le produit** (si approuvé)
   - Livreur marque le produit comme retourné
   - Statut passe à `produit_retourne`
   - Frais de livraison enregistrés:
     - Vendeur débité de 50% des frais aller-retour
     - Livreur débité de 50% des frais aller-retour
   - Vendeur et acheteur notifiés

4. **Vendeur rembourse l'acheteur**
   - Effectue le remboursement via Mobile Money/Banque
   - Enregistre la référence de transaction dans l'app
   - Statut passe à `rembourse`
   - Remboursement enregistré dans l'historique:
     - Acheteur crédité du montant du produit
     - Vendeur débité du montant du produit
   - Acheteur notifié

### Cas 2: Paiement à la livraison (Cash on delivery)

1. **Refus immédiat à la réception**
   - Acheteur refuse le produit directement au livreur
   - Pas de paiement effectué
   - Livreur retourne le produit au vendeur
   - Pas besoin de créer une demande de remboursement

2. **Retour après réception** (même processus que paiement prépayé)
   - Si l'acheteur a accepté et payé le produit
   - Suit le même workflow que le cas 1
   - Vendeur doit rembourser en cash ou Mobile Money

## Règles de gestion

### Éligibilité au retour
- Commande avec statut `livree` ou `en_cours`
- Pas de demande de remboursement en cours (`refundId == null`)

### Montants
- **Montant remboursé:** Prix du produit uniquement (hors frais de livraison initiaux)
- **Frais de livraison retour:** Calculés = frais de livraison initiaux × 2
- **Répartition frais retour:** 50% vendeur + 50% livreur

### Notifications
À chaque étape, les parties concernées sont notifiées:
- Demande créée → Vendeur
- Demande approuvée → Acheteur
- Demande refusée → Acheteur
- Produit retourné → Vendeur + Acheteur
- Remboursement effectué → Acheteur

### Traçabilité
Toutes les transactions sont enregistrées dans la collection `payments`:
- Type: `refund` ou `refund_delivery_charge`
- Montant positif (crédit) ou négatif (débit)
- Référence vers `orderId` et `refundId`
- Référence de transaction pour les remboursements
- Timestamp de création

## Structure Firestore

### Collection `refunds`
```javascript
{
  id: string,
  orderId: string,
  buyerId: string,
  buyerName: string,
  vendeurId: string,
  vendeurName: string,
  livreurId?: string,
  livreurName?: string,

  reason: string,
  description: string,
  images: string[],

  productAmount: number,
  deliveryFee: number,
  vendeurDeliveryCharge: number,
  livreurDeliveryCharge: number,

  paymentMethod: string,
  isPrepaid: boolean,

  status: string,
  requestedAt: Timestamp,
  approvedAt?: Timestamp,
  returnedAt?: Timestamp,
  refundedAt?: Timestamp,

  vendeurNote?: string,
  refundReference?: string
}
```

### Index Firestore recommandés
```javascript
// Pour récupérer les remboursements d'un vendeur
refunds: vendeurId (ASC), requestedAt (DESC)

// Pour récupérer les remboursements d'un acheteur
refunds: buyerId (ASC), requestedAt (DESC)

// Pour récupérer le remboursement d'une commande
refunds: orderId (ASC)
```

### Collection `payments` (entrées ajoutées)
```javascript
// Frais de livraison retour - Vendeur
{
  id: string,
  userId: vendeurId,
  type: 'refund_delivery_charge',
  amount: -vendeurDeliveryCharge,
  orderId: string,
  refundId: string,
  description: 'Frais de livraison retour (part vendeur)',
  status: 'completed',
  createdAt: Timestamp
}

// Frais de livraison retour - Livreur
{
  id: string,
  userId: livreurId,
  type: 'refund_delivery_charge',
  amount: -livreurDeliveryCharge,
  orderId: string,
  refundId: string,
  description: 'Frais de livraison retour (part livreur)',
  status: 'completed',
  createdAt: Timestamp
}

// Remboursement produit - Acheteur (crédit)
{
  id: string,
  userId: buyerId,
  type: 'refund',
  amount: productAmount,
  orderId: string,
  refundId: string,
  description: 'Remboursement commande #XXXXX',
  status: 'completed',
  reference: string,
  createdAt: Timestamp
}

// Remboursement produit - Vendeur (débit)
{
  id: string,
  userId: vendeurId,
  type: 'refund',
  amount: -productAmount,
  orderId: string,
  refundId: string,
  description: 'Remboursement commande #XXXXX',
  status: 'completed',
  reference: string,
  createdAt: Timestamp
}
```

### Modification `orders`
Champs ajoutés:
```javascript
{
  // ... autres champs
  refundId?: string,
  refundStatus?: string,
  paymentMethod?: string,
  vendeurName?: string
}
```

## Sécurité et validation

### Validation côté client
- Raison du retour obligatoire
- Description minimum 20 caractères
- Maximum 5 photos
- Vérification de l'éligibilité (`canBeReturned`)

### Validation côté service
- Vérification du statut de la commande
- Vérification du stock disponible
- Transactions Firestore pour éviter les conditions de course
- Gestion des erreurs avec retour explicite

### Permissions Firestore requises
```javascript
// Collection refunds
match /refunds/{refundId} {
  // Acheteur peut créer et lire ses propres remboursements
  allow create: if request.auth.uid == request.resource.data.buyerId;
  allow read: if request.auth.uid == resource.data.buyerId
              || request.auth.uid == resource.data.vendeurId
              || request.auth.uid == resource.data.livreurId;

  // Vendeur peut modifier ses remboursements
  allow update: if request.auth.uid == resource.data.vendeurId;
}

// Collection payments (historique)
match /payments/{paymentId} {
  allow read: if request.auth.uid == resource.data.userId;
  // Seul le système peut créer des paiements
  allow create: if false;
  allow update: if false;
  allow delete: if false;
}
```

## Points d'amélioration futurs

### Fonctionnalités additionnelles
1. **Délai de retour configurable**
   - Permettre aux vendeurs de définir une période de retour (7, 14, 30 jours)
   - Bloquer les demandes après expiration

2. **Remboursement partiel**
   - Permettre au vendeur de proposer un remboursement partiel
   - Acheteur peut accepter ou refuser

3. **Chat intégré**
   - Communication directe acheteur-vendeur dans l'interface de remboursement
   - Clarifications sur les photos, état du produit, etc.

4. **Statistiques**
   - Taux de retour par produit
   - Taux de retour par vendeur
   - Raisons de retour les plus fréquentes

5. **Automatisation**
   - Rappels automatiques au vendeur si pas de réponse en 48h
   - Escalade vers admin si délai dépassé
   - Remboursement automatique via API Mobile Money (si disponible)

### Améliorations techniques
1. **Optimisation photos**
   - Compression automatique côté client
   - Génération de thumbnails
   - Lazy loading dans la liste

2. **Backup et archivage**
   - Archiver les remboursements terminés après 6 mois
   - Export CSV pour comptabilité

3. **Analytics**
   - Tracking des événements dans Firebase Analytics
   - Métriques: temps moyen de traitement, taux d'approbation, etc.

## Support et maintenance

### Logs et debug
Tous les services utilisent `debugPrint` avec emojis:
- 📦 Réservation/Libération stock
- 💰 Opérations de remboursement
- ✅ Succès
- ❌ Erreurs
- ⚠️ Avertissements

### Monitoring
Points à surveiller:
- Taux d'échec des uploads de photos
- Durée moyenne de traitement d'une demande
- Nombre de demandes refusées
- Montant total remboursé par période

### Tests recommandés
1. Test unitaire RefundService
2. Test d'intégration workflow complet
3. Test de charge upload photos
4. Test transaction Firestore concurrente

---

**Date de création:** 18/11/2025
**Version:** 1.0.0
**Auteur:** Claude Code
**Dernière mise à jour:** 18/11/2025
