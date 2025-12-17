# Guide de Test - Click & Collect + Paliers de Confiance

**Quick Start Guide** pour tester les nouvelles fonctionnalités implémentées

---

## 🚀 Démarrage Rapide

### 1. Installation des Packages

```bash
# Installer les nouveaux packages QR
flutter pub get

# Vérifier qu'il n'y a pas d'erreurs
flutter analyze
```

### 2. Permissions Nécessaires (Android)

Ajouter dans `android/app/src/main/AndroidManifest.xml` si pas déjà présent:

```xml
<!-- Permission caméra pour scanner QR -->
<uses-permission android:name="android.permission.CAMERA" />
<uses-feature android:name="android.hardware.camera" />
<uses-feature android:name="android.hardware.camera.autofocus" />
```

---

## 🧪 Test 1: Click & Collect (Acheteur)

### Scénario Complet

#### Étape 1: Créer une commande en Click & Collect

1. **Connexion**: Se connecter en tant qu'acheteur
2. **Panier**: Ajouter des produits au panier
3. **Checkout**: Cliquer sur "Commander"
4. **Mode de livraison**:
   - ✅ Sélectionner **"Retrait en boutique"**
   - Vérifier badge **"GRATUIT"**
   - Lire le message: "Vous recevrez un code QR par notification"

5. **Paiement**: Choisir méthode de paiement
6. **Confirmation**:
   - Vérifier récapitulatif montre "🏪 Retrait en boutique (GRATUIT)"
   - Confirmer la commande

7. **Vérification Firestore**:
```javascript
// Commande créée doit avoir:
{
  deliveryMethod: "store_pickup",
  deliveryFee: 0,
  pickupQRCode: "ORDER_xxx_xxx_xxx_xxx",
  pickupReadyAt: null,
  pickedUpAt: null,
  status: "pending"
}
```

#### Étape 2: Voir le QR Code

**Option A: Depuis l'historique commandes**
1. Aller dans "Mes commandes"
2. Cliquer sur la commande Click & Collect
3. Bouton "Voir QR Code" (à ajouter dans order_detail_screen)

**Option B: Navigation directe** (pour test)
```dart
// Naviguer vers:
context.push('/acheteur/pickup-qr/${orderId}');
```

**Vérifications**:
- ⏳ Si status = "pending" → Message "En préparation"
- ✅ Si status = "ready" → QR code affiché
- ✅ Badge statut correct
- 📱 QR code 250x250 visible et net

---

## 🧪 Test 2: Click & Collect (Vendeur)

### Scénario Complet

#### Étape 1: Recevoir et préparer commande

1. **Connexion**: Se connecter en tant que vendeur
2. **Notification**: Recevoir notification nouvelle commande
3. **Dashboard**: Voir commande en "pending"
4. **Confirmer**: Changer status à "ready" ou "confirmed"

#### Étape 2: Scanner QR du client

1. **Scanner QR**:
   - Naviguer vers `/vendeur/qr-scanner`
   - Ou ajouter bouton dans dashboard vendeur

2. **Test du scan**:
   - Activer caméra (accepter permissions)
   - Scanner le QR code de l'acheteur
   - Vérifier dialogue de confirmation s'affiche

3. **Vérifications dialogue**:
   - ✅ N° Commande correct
   - ✅ Nom client
   - ✅ Montant total
   - ✅ Liste articles

4. **Confirmer retrait**:
   - Cliquer "Confirmer retrait"
   - Vérifier message succès
   - Retour automatique après 1s

5. **Vérification Firestore**:
```javascript
// Commande mise à jour:
{
  status: "delivered",
  pickedUpAt: timestamp,
  deliveredAt: timestamp
}
```

#### Cas d'Erreur à Tester

| Cas | Action | Résultat Attendu |
|-----|--------|------------------|
| QR invalide | Scanner code random | "QR Code invalide ou expiré" |
| QR expiré | Scanner QR >30 jours | "QR Code invalide ou expiré" |
| Déjà récupéré | Re-scanner même QR | "Cette commande a déjà été récupérée" |
| Mauvais orderId | QR modifié | "Commande introuvable" |
| Pas Click & Collect | Scanner QR livraison classique | "N'est pas en mode Click & Collect" |

---

## 🧪 Test 3: Paliers de Confiance Livreurs

### Test Calcul Niveau

#### Créer des profils livreurs test

**Livreur 1: Débutant**
```dart
{
  completedDeliveries: 5,
  averageRating: 3.8,
  cautionDeposited: 0,
  currentUnpaidBalance: 15000
}
```
**Attendu**: Niveau Débutant, max 30k/commande, max 50k non reversé

**Livreur 2: Confirmé**
```dart
{
  completedDeliveries: 25,
  averageRating: 4.2,
  cautionDeposited: 20000,
  currentUnpaidBalance: 80000
}
```
**Attendu**: Niveau Confirmé, max 100k/commande, max 200k non reversé

**Livreur 3: Expert**
```dart
{
  completedDeliveries: 75,
  averageRating: 4.4,
  cautionDeposited: 50000,
  currentUnpaidBalance: 150000
}
```
**Attendu**: Niveau Expert, max 150k/commande, max 300k non reversé

**Livreur 4: VIP**
```dart
{
  completedDeliveries: 200,
  averageRating: 4.7,
  cautionDeposited: 100000,
  currentUnpaidBalance: 200000
}
```
**Attendu**: Niveau VIP, max 300k/commande, max 500k non reversé

### Test Assignation Automatique

#### Scénario 1: Commande 25k FCFA
- ✅ Livreur Débutant peut accepter (< 30k)
- ✅ Tous niveaux supérieurs peuvent accepter

#### Scénario 2: Commande 120k FCFA
- ❌ Livreur Débutant bloqué (> 30k)
- ❌ Livreur Confirmé bloqué (> 100k)
- ✅ Livreur Expert peut accepter (< 150k)
- ✅ Livreur VIP peut accepter (< 300k)

#### Scénario 3: Livreur avec solde limite
```dart
// Livreur Confirmé
currentUnpaidBalance: 180000  // Déjà 180k non reversé
maxUnpaidBalance: 200000      // Limite 200k
```

**Test commande 25k**:
- 180000 + 25000 = 205000 > 200000 → ❌ **REFUSÉ**

**Test commande 15k**:
- 180000 + 15000 = 195000 < 200000 → ✅ **ACCEPTÉ**

### Tester l'UI des Badges

**Badge Compact**:
```dart
LivreurTrustBadge(
  level: LivreurTrustLevel.expert,
  showLabel: false,
  size: 24,
)
```

**Badge Complet**:
```dart
LivreurTrustBadge(
  level: LivreurTrustLevel.vip,
  showLabel: true,
  size: 20,
)
```

**Carte Détaillée**:
```dart
LivreurTrustCard(
  config: config,
  completedDeliveries: 75,
  averageRating: 4.4,
  currentBalance: 150000,
)
```

---

## 🔍 Debugging

### Logs à Surveiller

#### Click & Collect
```
✅ QR Code généré pour le retrait
🏪 Click & Collect: Frais de livraison = 0 FCFA
📱 QR Code scanné: Order=xxx, Buyer=xxx
✅ Commande #123 marquée comme récupérée
```

#### Paliers de Confiance
```
✅ Trust level calculé: Expert
❌ Livreur xxx bloqué: Montant 120k > max 100k
❌ Livreur xxx bloqué: Solde atteindrait 220k > max 200k
✅ Livreur xxx peut accepter commande 50k
```

### Firestore Rules à Vérifier

```javascript
// Orders collection doit permettre:
- Read: owner (buyer/vendeur/livreur)
- Write: buyer (création), vendeur (status update), livreur (status update)
- Update pickupQRCode: secured (only on creation)
- Update pickedUpAt: secured (only via scanner)
```

---

## ⚠️ Problèmes Courants

### 1. Erreur Permission Caméra

**Problème**: Scanner QR ne démarre pas
**Solution**:
```bash
# Ajouter permissions dans AndroidManifest.xml
# Redéployer l'app
flutter run
```

### 2. QR Code Ne S'affiche Pas

**Vérifications**:
1. `pickupQRCode` existe dans Firestore ✓
2. Package `qr_flutter` installé ✓
3. `deliveryMethod = 'store_pickup'` ✓
4. Status compatible (ready/confirmed/preparing) ✓

### 3. Scanner Ne Détecte Pas le QR

**Vérifications**:
1. Caméra focalisée ✓
2. QR code bien contrasté (fond blanc recommandé) ✓
3. Distance 10-30cm ✓
4. Lumière suffisante ou flash activé ✓

### 4. Assignation Livreur Échoue

**Vérifications**:
1. Livreur a profil complet ✓
2. `completedDeliveries` field existe ✓
3. `averageRating` field existe ✓
4. `currentUnpaidBalance` calculé ✓

---

## 📊 Vérification Base de Données

### Script de Test Firestore

```javascript
// Vérifier une commande Click & Collect
db.collection('orders').doc('ORDER_ID').get()
  .then(doc => {
    const data = doc.data();
    console.log('Delivery Method:', data.deliveryMethod);
    console.log('QR Code:', data.pickupQRCode);
    console.log('Delivery Fee:', data.deliveryFee);
    console.log('Status:', data.status);
    console.log('Picked Up:', data.pickedUpAt);
  });

// Vérifier config livreur
db.collection('users').doc('LIVREUR_ID').get()
  .then(doc => {
    const profile = doc.data().profile.livreurProfile;
    console.log('Completed Deliveries:', profile.completedDeliveries);
    console.log('Average Rating:', profile.averageRating);
    console.log('Caution Deposited:', profile.cautionDeposited);
    console.log('Unpaid Balance:', profile.currentUnpaidBalance);
  });
```

---

## ✅ Checklist Test Complet

### Click & Collect - Acheteur
- [ ] Sélection mode retrait boutique au checkout
- [ ] Frais livraison = 0 FCFA affiché
- [ ] Commande créée avec `deliveryMethod = store_pickup`
- [ ] QR code généré et stocké
- [ ] Écran QR code accessible
- [ ] QR code scannable (testé avec autre app QR)
- [ ] Statuts affichés correctement (attente/prêt/récupéré)

### Click & Collect - Vendeur
- [ ] Scanner QR accessible
- [ ] Permissions caméra demandées
- [ ] QR code détecté rapidement
- [ ] Validation QR fonctionne
- [ ] Dialogue confirmation affiché
- [ ] Détails commande corrects
- [ ] Confirmation met à jour Firestore
- [ ] Status change à "delivered"
- [ ] pickedUpAt enregistré
- [ ] Cas d'erreur gérés (QR invalide, expiré, etc.)

### Paliers de Confiance
- [ ] Calcul niveau automatique fonctionne
- [ ] Badge affiché correctement
- [ ] Couleurs par niveau respectées
- [ ] Carte détaillée affiche bonnes infos
- [ ] Vérification limite commande fonctionne
- [ ] Vérification solde non reversé fonctionne
- [ ] Assignation filtre livreurs dépassant limite
- [ ] UI progression vers niveau suivant

---

## 🎯 Prochains Tests à Ajouter

1. **Tests Unitaires**
   - QRCodeService.generatePickupQRCode()
   - QRCodeService.validateAndParseQRCode()
   - LivreurTrustConfig.getConfig()
   - LivreurTrustService.canLivreurAcceptOrder()

2. **Tests d'Intégration**
   - Flow complet Click & Collect
   - Assignation avec paliers de confiance
   - Scan QR → Mise à jour Firestore

3. **Tests UI**
   - Navigation checkout → QR screen
   - Scanner QR → Confirmation
   - Badges responsive

---

**Tests estimés**: 30-45 minutes pour couverture complète
**Priorité**: Click & Collect flow complet en premier
