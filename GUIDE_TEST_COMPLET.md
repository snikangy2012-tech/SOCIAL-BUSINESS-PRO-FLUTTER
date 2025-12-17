# Guide de Test Complet - SOCIAL BUSINESS Pro

**Date**: 13 Décembre 2025
**Version**: 1.0

---

## 📋 Vue d'Ensemble

Ce guide détaille tous les tests à effectuer pour valider les **3 systèmes majeurs** implémentés:
1. Click & Collect
2. Paliers de Confiance Livreur
3. Tarification Dynamique

---

## 🎯 Test 1: Click & Collect

### Prérequis
- 1 compte acheteur actif
- 1 compte vendeur avec boutique configurée
- 1 produit en stock chez le vendeur
- Firebase Cloud Messaging configuré

### Étape 1: Création Commande Click & Collect (Acheteur)

**Actions**:
1. Se connecter comme acheteur
2. Ajouter un produit au panier
3. Aller au checkout
4. **Vérifier**: Affichage de 2 options de livraison:
   - ⭕ Livraison à domicile (1000-2500 FCFA)
   - ⭕ Retrait en boutique (GRATUIT)
5. Sélectionner "Retrait en boutique"
6. **Vérifier**: Frais de livraison passe à 0 FCFA
7. **Vérifier**: Total mis à jour automatiquement
8. Confirmer la commande

**Résultats attendus**:
- ✅ Commande créée avec `deliveryMethod = 'store_pickup'`
- ✅ `deliveryFee = 0`
- ✅ `pickupQRCode` généré (format: `ORDER_{id}_{buyerId}_{timestamp}_{random}`)
- ✅ **Notification 1 reçue**: "📱 Votre QR Code de retrait est prêt"

**Console logs attendus**:
```
✅ Commande créée: ORDxxx
📱 QR Code généré: ORDER_xyz_abc_1702434567890_123456
✅ Notification QR prêt envoyée
```

### Étape 2: Visualiser QR Code (Acheteur)

**Actions**:
1. Taper sur la notification OU
2. Aller dans Historique commandes → Sélectionner la commande
3. **Vérifier**: Écran affiche:
   - Numéro de commande: #XXX
   - QR code (250x250 pixels)
   - Badge statut: "En préparation" (orange)
   - Détails commande (articles, quantités, total)
   - Badge "Retrait gratuit" (vert)
   - Message: "Présentez ce code au vendeur lors du retrait"

**Résultats attendus**:
- ✅ QR code visible et scannable
- ✅ Détails affichés correctement
- ✅ Aucun bouton "Confirmer retrait" (réservé au vendeur)

### Étape 3: Préparer Commande (Vendeur)

**Actions**:
1. Se connecter comme vendeur
2. Aller dans Gestion des commandes
3. **Vérifier**: Nouvelle commande apparaît avec:
   - Badge "Click & Collect" ou icône magasin
   - Frais livraison = 0 FCFA
   - Statut: "pending" ou "confirmed"
4. Préparer les articles physiquement
5. Ouvrir détail de la commande
6. Changer statut → "ready" (Prêt pour retrait)

**Résultats attendus**:
- ✅ Statut mis à jour vers "ready"
- ✅ Champ `pickupReadyAt` enregistré avec timestamp
- ✅ **Notification 2 envoyée** à l'acheteur: "🎉 Votre commande est prête !"

**Console logs attendus**:
```
🔄 MAJ statut commande → ready
✅ pickupReadyAt: 2025-12-13T14:30:00
✅ Notification "Commande prête" envoyée à acheteur
```

### Étape 4: Notification Commande Prête (Acheteur)

**Actions**:
1. **Vérifier**: Notification push reçue
2. Taper sur la notification
3. **Vérifier**: Redirigé vers écran QR code
4. **Vérifier**: Badge statut passe à "Prêt pour retrait" (vert)

**Résultats attendus**:
- ✅ Notification affichée avec titre et corps corrects
- ✅ Deep link fonctionne (`/acheteur/pickup-qr/{orderId}`)
- ✅ Badge vert affiché
- ✅ QR code toujours visible

### Étape 5: Scanner QR Code (Vendeur)

**Actions**:
1. En boutique, acheteur arrive et affiche QR code
2. Vendeur ouvre Dashboard → Bouton "Scanner QR"
3. Autoriser accès caméra si demandé
4. Pointer caméra vers QR code de l'acheteur
5. **Vérifier**: Scan automatique détecté
6. **Vérifier**: Dialogue de confirmation affiche:
   - ✅ "Commande validée" (titre)
   - N° Commande: #XXX
   - Client: [Nom de l'acheteur]
   - Montant: X FCFA
   - Liste des articles avec quantités
   - Boutons: "Annuler" | "Confirmer retrait"

**Résultats attendus**:
- ✅ QR code détecté en <2 secondes
- ✅ Validations passées:
  - Format QR valide
  - Commande trouvée
  - Mode Click & Collect confirmé
  - Pas déjà récupéré
  - QR correspond à la commande
  - Statut = "ready"
- ✅ Détails affichés correctement

**Console logs attendus**:
```
📱 QR Code scanné: Order=xyz123, Buyer=abc456
✅ Validation réussie: 6/6 vérifications OK
```

### Étape 6: Confirmer Retrait (Vendeur)

**Actions**:
1. Vérifier physiquement l'identité du client (optionnel)
2. Remettre les articles au client
3. Appuyer sur "Confirmer retrait"

**Résultats attendus**:
- ✅ Commande mise à jour:
  - `status = 'delivered'`
  - `pickedUpAt` = timestamp actuel
  - `deliveredAt` = timestamp actuel
- ✅ **Notification 3 envoyée**: "✅ Commande récupérée"
- ✅ Message succès affiché au vendeur
- ✅ Retour automatique à l'écran précédent

**Console logs attendus**:
```
✅ Commande #123 marquée comme récupérée
✅ Notification retrait confirmé envoyée à l'acheteur
```

### Étape 7: Confirmation Finale (Acheteur)

**Actions**:
1. **Vérifier**: Notification "Commande récupérée" reçue
2. Taper sur notification
3. **Vérifier**: Redirigé vers historique commandes
4. Ouvrir écran QR de la commande
5. **Vérifier**: Affichage changé:
   - Badge vert: "Commande déjà récupérée"
   - Date et heure du retrait
   - Plus de QR code visible

**Résultats attendus**:
- ✅ Statut final correct
- ✅ Horodatage affiché
- ✅ Transaction complète

---

## 🛡️ Test 2: Paliers de Confiance Livreur

### Prérequis
- 1 compte livreur actif (nouveau, 0 livraison)
- Plusieurs commandes de montants variés (20k, 50k, 120k FCFA)

### Test 2.1: Niveau Débutant - Vérification Limites

**Données initiales**:
```json
{
  "completedDeliveries": 0,
  "averageRating": 0.0,
  "cautionDeposited": 0
}
```

**Actions**:
1. Se connecter comme livreur
2. Aller dans Profil ou Dashboard
3. **Vérifier**: Badge "Débutant" affiché avec:
   - Icône niveau (gris)
   - Limites: 30k/commande, 50k impayé max

**Test assignation commande 25k FCFA**:
1. Admin/Vendeur assigne commande de 25 000 FCFA
2. **Vérifier**: Livraison apparaît dans "Commandes disponibles"
3. Accepter la livraison
4. **Résultat attendu**: ✅ Acceptée (25k < 30k)

**Test assignation commande 50k FCFA**:
1. Admin/Vendeur assigne commande de 50 000 FCFA
2. **Vérifier**: Livraison N'apparaît PAS dans "Commandes disponibles"
3. **Résultat attendu**: ✅ Refusée automatiquement (50k > 30k)

**Console logs attendus**:
```
📊 Niveau calculé: Débutant (0 livraisons, 0.0★)
✅ Commande 25k FCFA: Acceptée
⚠️ Commande 50k FCFA: Refusée (dépasse limite 30k)
```

### Test 2.2: Progression vers Confirmé

**Actions pour monter de niveau**:
1. Effectuer 12 livraisons réussies
2. Obtenir note moyenne ≥ 4.0★
3. Rafraîchir profil

**Données mises à jour**:
```json
{
  "completedDeliveries": 12,
  "averageRating": 4.2,
  "cautionDeposited": 0
}
```

**Vérifications**:
1. **Vérifier**: Badge passe à "Confirmé" (bleu)
2. **Vérifier**: Nouvelles limites affichées:
   - 100k/commande
   - 200k impayé max
3. **Vérifier**: Délai reversement = 48h (au lieu de 24h)

**Test acceptation**:
1. Commande 75k FCFA assignée
2. **Résultat attendu**: ✅ Acceptée (75k < 100k)
3. Commande 120k FCFA assignée
4. **Résultat attendu**: ❌ Refusée (120k > 100k)

**Console logs attendus**:
```
🎉 Niveau mis à jour: Confirmé (12 livraisons, 4.2★)
✅ Nouvelles limites: 100k/200k
```

### Test 2.3: Solde Impayé

**Scénario**:
- Livreur Confirmé (limite 200k impayé)
- Livraison 1: 80k FCFA (en attente paiement)
- Livraison 2: 90k FCFA (en attente paiement)
- **Solde impayé actuel**: 170k FCFA

**Test nouvelle commande 50k FCFA**:
1. Admin assigne commande 50k FCFA
2. Calcul: 170k + 50k = 220k > 200k (limite)
3. **Résultat attendu**: ❌ Refusée automatiquement

**Message d'erreur**:
```
⚠️ Impossible d'accepter cette commande
Raison: Solde impayé trop élevé (170k + 50k = 220k > limite 200k)
Solution: Attendez le reversement des paiements en cours
```

**Test après reversement**:
1. Système reverse 80k de la livraison 1
2. **Nouveau solde**: 90k FCFA
3. Réassigner même commande 50k FCFA
4. Calcul: 90k + 50k = 140k < 200k
5. **Résultat attendu**: ✅ Acceptée

---

## 💰 Test 3: Tarification Dynamique

### Prérequis
- Livreurs avec différents niveaux (Débutant, Confirmé, Expert, VIP)
- Abonnements variés (STARTER, PRO, PREMIUM)

### Test 3.1: Calcul Commission - Débutant STARTER

**Profil livreur**:
```json
{
  "level": "debutant",
  "completedDeliveries": 5,
  "averageRating": 3.8,
  "subscription": "STARTER"
}
```

**Commande test**: 40 000 FCFA

**Calcul attendu**:
```
Taux base (STARTER): 25%
Bonus confiance (Débutant): 0%
Bonus performance (3.8★): 0%
---
Taux final: 25%

Commission plateforme: 10 000 FCFA
Gains livreur: 30 000 FCFA
```

**Vérification**:
1. Accepter la livraison
2. Compléter la livraison
3. Ouvrir détail livraison ou écran gains
4. **Vérifier**: Card "Détails de commission" affiche:
   - Montant: 40 000 FCFA
   - Taux base: 25%
   - Bonus confiance: 0%
   - Bonus performance: 0%
   - Taux final: 25%
   - Commission: 10 000 FCFA (rouge)
   - Vos gains: 30 000 FCFA (vert)

### Test 3.2: Calcul Commission - Expert PRO avec Bonne Note

**Profil livreur**:
```json
{
  "level": "expert",
  "completedDeliveries": 75,
  "averageRating": 4.7,
  "subscription": "PRO"
}
```

**Commande test**: 80 000 FCFA

**Calcul attendu**:
```
Taux base (PRO): 20%
Bonus confiance (Expert): -4%
Bonus performance (4.7★ ≥ 4.5): -2%
---
Taux final: 14%

Commission plateforme: 11 200 FCFA
Gains livreur: 68 800 FCFA
```

**Économie vs Débutant**:
- Débutant aurait payé: 20 000 FCFA (25%)
- Expert paie: 11 200 FCFA (14%)
- **Économie**: 8 800 FCFA (+11% de gains)

**Vérification**:
1. **Vérifier**: Affichage correct dans card commission
2. **Vérifier**: Badge niveau "Expert" (violet)
3. **Vérifier**: Note 4.7★ affichée

### Test 3.3: Simulation Gains par Niveau

**Actions**:
1. Livreur Débutant ouvre écran "Mes Gains" ou "Progression"
2. Section "Gagnez plus en montant de niveau"
3. Saisir montant exemple: 100 000 FCFA
4. **Vérifier**: Card affiche comparaison:

```
Pour une commande de 100 000 FCFA

[Débutant]  75 000 FCFA
[Confirmé]  78 000 FCFA  (+3 000 vs Débutant)
[Expert]    80 000 FCFA  (+5 000 vs Débutant)
[VIP]       81 000 FCFA  (+6 000 vs Débutant)
```

**Résultat attendu**:
- ✅ Calculs corrects
- ✅ Affichage visuel avec couleurs par niveau
- ✅ Économies affichées en vert

### Test 3.4: Résumé Gains Période

**Actions**:
1. Livreur avec 10 livraisons complétées ce mois
2. Ouvrir écran "Statistiques" ou "Gains"
3. Sélectionner période: "Ce mois"
4. **Vérifier**: Card "Résumé de la période" affiche:
   - Nombre total livraisons: 10
   - Montant total commandes: XXX FCFA
   - Total commissions payées: YYY FCFA
   - Total gains reçus: ZZZ FCFA
   - Taux moyen: XX%

**Exemple attendu**:
```
10 livraisons complétées
Montant total: 500 000 FCFA
Commissions: 100 000 FCFA
Vos gains: 400 000 FCFA
Taux moyen: 20%
```

---

## 📱 Test 4: Navigation et Appels

### Test 4.1: Navigation GPS - Pickup

**Scénario**: Livraison assignée (statut = "assigned")

**Actions**:
1. Ouvrir détail livraison
2. Appuyer sur bouton "Itinéraire"
3. **Vérifier**: Google Maps s'ouvre avec:
   - Destination = adresse du vendeur (pickup)
   - Mode = navigation
   - Position actuelle détectée

**Résultat attendu**:
- ✅ Maps lance avec coordonnées pickup correctes
- ✅ Itinéraire calculé depuis position actuelle

**Console logs**:
```
📍 Itinéraire vers VENDEUR (pickup)
Coordonnées: 5.3599517, -4.0082648
✅ Google Maps lancé
```

### Test 4.2: Navigation GPS - Delivery

**Scénario**: Livraison récupérée (statut = "picked_up")

**Actions**:
1. Marquer livraison comme "Récupérée"
2. Ouvrir détail livraison
3. Appuyer sur bouton "Itinéraire"
4. **Vérifier**: Google Maps s'ouvre avec:
   - Destination = adresse du client (delivery)

**Résultat attendu**:
- ✅ Maps lance avec coordonnées delivery correctes
- ✅ Itinéraire vers le client calculé

**Console logs**:
```
📍 Itinéraire vers CLIENT (delivery)
Coordonnées: 5.3454321, -4.0123456
✅ Google Maps lancé
```

### Test 4.3: Appel Téléphonique Client

**Actions**:
1. Ouvrir détail livraison
2. Appuyer sur bouton "Appeler"
3. **Vérifier**: Application téléphone s'ouvre avec:
   - Numéro pré-rempli (ex: +225 07 12 34 56 78)
   - Prêt à composer

**Résultat attendu**:
- ✅ Appel lancé avec bon numéro
- ✅ Pas de préfixe manquant
- ✅ Format international correct (+225...)

**Console logs**:
```
✅ Appel téléphonique initié vers +225XXXXXXXXX
```

**Test erreur - Numéro manquant**:
1. Commande sans numéro de téléphone
2. Appuyer sur "Appeler"
3. **Vérifier**: Message erreur:
   - "Numéro de téléphone du client non disponible"
   - SnackBar rouge

---

## ✅ Checklist Globale

### Click & Collect
- [ ] Choix mode livraison affiché au checkout
- [ ] Frais = 0 FCFA pour Click & Collect
- [ ] QR code généré et stocké
- [ ] Notification 1 (QR prêt) envoyée et reçue
- [ ] Écran QR affiche code et détails
- [ ] Vendeur peut marquer "ready"
- [ ] Notification 2 (Commande prête) envoyée
- [ ] Scanner QR fonctionne
- [ ] Validation QR (6 vérifications) OK
- [ ] Confirmation retrait met à jour statut
- [ ] Notification 3 (Retrait confirmé) envoyée
- [ ] Écran QR affiche "Déjà récupérée"

### Paliers de Confiance
- [ ] Badge Débutant affiché (nouveau livreur)
- [ ] Limites Débutant respectées (30k/50k)
- [ ] Refus automatique commande >30k
- [ ] Progression Confirmé après 11 livraisons + 4.0★
- [ ] Nouvelles limites Confirmé (100k/200k)
- [ ] Calcul solde impayé correct
- [ ] Refus si solde impayé + nouvelle commande > limite
- [ ] Acceptation après reversement

### Tarification Dynamique
- [ ] Calcul taux base selon abonnement
- [ ] Bonus confiance appliqué correctement
- [ ] Bonus performance selon note
- [ ] Taux final plafonné (10%-30%)
- [ ] Commission card affiche décomposition
- [ ] Gains livreur calculés correctement
- [ ] Simulation gains par niveau fonctionne
- [ ] Résumé période affiche stats correctes

### Navigation et Appels
- [ ] Bouton "Itinéraire" ouvre Maps
- [ ] Destination = pickup si status assigned
- [ ] Destination = delivery si status picked_up
- [ ] Bouton "Appeler" lance appel
- [ ] Numéro client affiché correctement
- [ ] Gestion erreur si numéro manquant

---

## 🐛 Gestion des Erreurs

### Erreurs à Tester

#### Click & Collect
1. **QR expiré** (>30 jours):
   - Scanner QR ancien
   - **Attendu**: Message "QR Code invalide ou expiré"

2. **QR déjà utilisé**:
   - Scanner QR d'une commande déjà récupérée
   - **Attendu**: Message "Cette commande a déjà été récupérée"

3. **Mauvais QR**:
   - Scanner QR d'une autre commande
   - **Attendu**: Message "QR Code non valide pour cette commande"

4. **Commande pas prête**:
   - Scanner QR alors que statut = "pending"
   - **Attendu**: Message "Commande non prête pour le retrait"

#### Paliers de Confiance
1. **Commande trop élevée**:
   - Livreur Débutant, commande 60k
   - **Attendu**: Pas visible dans liste + log console

2. **Solde impayé dépassé**:
   - Solde 45k, nouvelle 10k, limite 50k
   - **Attendu**: Refusée + message explicatif

#### Tarification Dynamique
1. **Données manquantes**:
   - Livreur sans historique
   - **Attendu**: Taux par défaut 25%

2. **Livreur introuvable**:
   - ID invalide
   - **Attendu**: Exception catchée, taux par défaut

---

## 📊 Métriques de Succès

### Performance
- Scan QR: <2 secondes
- Calcul commission: <500ms
- Chargement écran QR: <1 seconde
- Envoi notification: <3 secondes

### Taux de Succès
- QR validation: 100% (si valide)
- Notifications envoyées: ≥95%
- Calculs commission: 100%
- Navigation GPS: ≥98%

### UX
- Aucune étape manuelle complexe
- Messages d'erreur clairs
- Retours visuels immédiats
- 0 freeze UI

---

## 🎯 Conclusion

Une fois tous ces tests passés:
1. Documenter résultats dans fichier TEST_RESULTS.md
2. Créer issues GitHub pour bugs trouvés
3. Valider avec utilisateurs réels (beta test)
4. Déployer en production

**Bon test !** 🚀
