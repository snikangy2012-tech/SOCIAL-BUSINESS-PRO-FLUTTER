# Guide de Test Complet - Système KYC Adaptatif

## 📋 Objectif
Ce document décrit tous les scénarios de test pour valider le système KYC adaptatif anti-fraude avant sa mise en production.

---

## 🚀 Préparation de l'Environnement de Test

### 1. Pré-requis
```bash
# Vérifier que le projet compile
flutter analyze

# Vérifier que les index Firestore sont déployés
firebase deploy --only firestore:indexes

# Lancer l'application en mode debug
flutter run
```

### 2. Créer des Comptes de Test

Créer les comptes suivants pour les tests :

| Email | Rôle | Mot de passe | Usage |
|-------|------|--------------|-------|
| vendeur.test1@test.ci | Vendeur | Test123! | Tier NEW → VERIFIED |
| vendeur.test2@test.ci | Vendeur | Test123! | Tier MODERATE (device partagé) |
| vendeur.test3@test.ci | Vendeur | Test123! | Blacklist test |
| livreur.test1@test.ci | Livreur | Test123! | Progression tiers |
| admin@socialbusiness.ci | Admin | (existant) | Gestion KYC |

---

## 📊 Test 1 : Inscription et Évaluation Initiale

### Objectif
Vérifier que le système évalue correctement le risque lors de l'inscription.

### Étapes

#### 1.1 - Inscription Nouvel Utilisateur (NEW TIER)
1. Démarrer l'app sur **Device 1** (émulateur ou téléphone)
2. S'inscrire comme vendeur avec `vendeur.test1@test.ci`
3. Compléter le formulaire d'inscription :
   - Nom: Test Vendeur 1
   - Téléphone: +225 07 12 34 56 78
   - Nom commercial: Boutique Test 1
   - Catégorie: Électronique

**Résultats attendus :**
- ✅ Compte créé avec succès
- ✅ Document créé dans `risk_assessments/{userId}` avec :
  ```json
  {
    "tier": "newUser",
    "riskScore": 50-70,
    "userId": "...",
    "phoneNumber": "+225 07 12 34 56 78",
    "deviceId": "...",
    "blacklistCheckPassed": true
  }
  ```
- ✅ Document créé dans `device_registry/{deviceId}` avec :
  ```json
  {
    "associatedUserIds": ["..."],
    "riskLevel": "low",
    "accountCreatedCount": 1
  }
  ```

#### 1.2 - Vérifier le Dashboard Vendeur
1. Accéder au dashboard vendeur
2. Observer la bannière KYC en haut de l'écran

**Résultats attendus :**
- ✅ Bannière affichée avec :
  - Tier: **NEW USER** (icône grise)
  - Score: ~50-70/100
  - Limites:
    - Montant maximum: 250 000 FCFA
    - Commandes/jour: 5
    - Délai retrait: 24h
  - Message: "Complétez votre KYC → bonus 5 000 FCFA"
  - Bouton: **"Vérifier"** (vert)

---

## 🎯 Test 2 : Vérification des Limites

### Objectif
Tester que les limites tier sont correctement appliquées.

### Étapes

#### 2.1 - Commande dans la Limite (OK)
1. Connecté comme `vendeur.test1@test.ci`
2. Créer une commande de **150 000 FCFA** (< 250k)
   - Ajouter 3 produits au panier
   - Total: 150 000 FCFA
   - Valider la commande

**Résultats attendus :**
- ✅ Commande créée avec succès
- ✅ Stock réservé automatiquement
- ✅ Message de confirmation
- ✅ Compteur quotidien: 1/5

#### 2.2 - Commande Hors Limite (BLOQUÉ)
1. Toujours connecté comme `vendeur.test1@test.ci`
2. Tenter une commande de **300 000 FCFA** (> 250k)

**Résultats attendus :**
- ❌ Commande refusée
- ✅ Dialog affiché :
  ```
  Limite atteinte

  Montant maximum: 250 000 FCFA (Tier: NEW USER)

  💡 Complétez votre KYC pour augmenter les limites

  Avantages :
  - Limite portée à 1 000 000 FCFA
  - Bonus de 5 000 FCFA
  - Vérification en 2 minutes

  [Annuler] [Compléter KYC]
  ```
- ✅ Commande **non créée** dans Firestore

#### 2.3 - Limite Quotidienne (5 commandes max)
1. Créer **4 commandes** supplémentaires de 50k chacune
2. Tenter une **6ème commande**

**Résultats attendus :**
- ✅ Les 4 premières passent (total: 5/5)
- ❌ La 6ème est refusée
- ✅ Message: "Limite quotidienne atteinte: 5 commandes"
- ✅ Suggestion: "Réessayez demain ou complétez votre KYC"

---

## 🔐 Test 3 : Complétion KYC et Upgrade

### Objectif
Vérifier que le KYC upgrade correctement le tier.

### Étapes

#### 3.1 - Soumettre KYC
1. Connecté comme `vendeur.test1@test.ci`
2. Cliquer sur "Vérifier" dans la bannière KYC
3. Uploader :
   - Photo CNI recto
   - Photo CNI verso
   - Selfie avec CNI
4. Soumettre

**Résultats attendus :**
- ✅ Document créé dans `kyc_verifications/{docId}` :
  ```json
  {
    "userId": "...",
    "status": "pending",
    "documentType": "CNI",
    "documentUrls": ["url1", "url2", "url3"],
    "submittedAt": "..."
  }
  ```
- ✅ Message: "KYC soumis, en attente de validation"

#### 3.2 - Validation Admin
1. Se connecter comme `admin@socialbusiness.ci`
2. Aller dans **"Gestion KYC Adaptative"**
3. Onglet **"Validations KYC"**
4. Voir la demande de `vendeur.test1@test.ci`
5. Cliquer sur **"Approuver"**

**Résultats attendus :**
- ✅ `kyc_verifications/{docId}` :
  ```json
  {
    "status": "approved",
    "reviewedAt": "..."
  }
  ```
- ✅ `risk_assessments/{userId}` mis à jour :
  ```json
  {
    "tier": "verified",
    "riskScore": 80,
    "lastUpdated": "..."
  }
  ```

#### 3.3 - Vérifier Nouvelles Limites
1. Retourner au dashboard vendeur (`vendeur.test1@test.ci`)
2. Observer la bannière KYC

**Résultats attendus :**
- ✅ Bannière mise à jour :
  - Tier: **VERIFIED** (icône bleue)
  - Score: 80/100
  - Limites:
    - Montant maximum: **1 000 000 FCFA** ⬆️
    - Commandes/jour: **20** ⬆️
    - Délai retrait: **2h** ⬆️
  - Message: "KYC recommandé pour limites supérieures"

#### 3.4 - Tester Nouvelle Limite
1. Créer une commande de **800 000 FCFA**

**Résultats attendus :**
- ✅ Commande créée avec succès (< 1M)

---

## 🚨 Test 4 : Device Partagé (MODERATE TIER)

### Objectif
Détecter et gérer les devices partagés.

### Étapes

#### 4.1 - Inscription sur Device Déjà Utilisé
1. **Sans fermer l'app** (même device que Test 1)
2. Se déconnecter de `vendeur.test1@test.ci`
3. S'inscrire avec `vendeur.test2@test.ci`
   - Téléphone: +225 07 98 76 54 32

**Résultats attendus :**
- ✅ Compte créé
- ✅ `risk_assessments/{userId}` :
  ```json
  {
    "tier": "moderateRisk",
    "riskScore": 40-50,
    "riskFactors": ["device_multi_account"],
    "blacklistCheckPassed": true
  }
  ```
- ✅ `device_registry/{deviceId}` :
  ```json
  {
    "associatedUserIds": ["user1Id", "user2Id"],
    "accountCreatedCount": 2,
    "riskLevel": "medium"
  }
  ```

#### 4.2 - Vérifier Dashboard Moderate Risk
1. Accéder au dashboard de `vendeur.test2@test.ci`

**Résultats attendus :**
- ✅ Bannière **ORANGE** affichée :
  - Tier: **MODERATE RISK**
  - Score: 40-50/100
  - Limites:
    - Montant max: **100 000 FCFA** ⚠️
    - Commandes/jour: **2** ⚠️
    - Retraits: **BLOQUÉS** 🔒
  - Message: "KYC simplifié requis pour retirer vos gains"
  - Bouton: **"Compléter ma vérification"** (orange, urgent)

#### 4.3 - Test Limite Retraits
1. Aller dans "Mes gains"
2. Tenter un retrait

**Résultats attendus :**
- ❌ Retrait refusé
- ✅ Dialog :
  ```
  Retraits bloqués

  Votre niveau actuel ne permet pas les retraits.

  💡 Complétez votre KYC pour débloquer les retraits

  [Fermer] [Compléter KYC]
  ```

---

## 🔴 Test 5 : Blacklist

### Objectif
Tester la détection et le blocage des utilisateurs blacklistés.

### Étapes

#### 5.1 - Ajouter Manuellement à la Blacklist
1. Connecté comme `admin@socialbusiness.ci`
2. **Gestion KYC Adaptative** → Onglet **"Blacklist"**
3. Cliquer sur **"Ajouter"**
4. Remplir :
   - CNI: CI0123456789
   - Téléphone: +225 07 55 55 55 55
   - Raison: Dette commission 50 000 FCFA
5. Cliquer sur **"Ajouter"**

**Résultats attendus :**
- ✅ Document créé dans `blacklist/{docId}` :
  ```json
  {
    "cniNumber": "CI0123456789",
    "phoneNumber": "+225 07 55 55 55 55",
    "reason": "Dette commission 50 000 FCFA",
    "status": "active",
    "type": "other",
    "severity": "high",
    "addedAt": "..."
  }
  ```

#### 5.2 - Tentative Inscription avec CNI Blacklistée
1. Tenter de s'inscrire avec :
   - Email: `vendeur.test3@test.ci`
   - CNI: **CI0123456789** (blacklistée)

**Résultats attendus :**
- ❌ Inscription **REFUSÉE**
- ✅ Message :
  ```
  Inscription impossible

  Votre inscription ne peut être traitée pour le moment.

  Raison: Dette commission 50 000 FCFA

  📞 Contactez le support :
  - Email: support@socialbusiness.ci
  - WhatsApp: +225 XX XX XX XX
  - Disponible 24/7
  ```
- ✅ Compte **NON CRÉÉ** dans Firebase Auth
- ✅ Log dans `audit_logs` :
  ```json
  {
    "action": "registration_blocked_blacklist",
    "severity": "high",
    "category": "security",
    "metadata": {
      "cniNumber": "CI0123456789",
      "blacklistReason": "Dette commission 50 000 FCFA"
    }
  }
  ```

#### 5.3 - Tentative avec Téléphone Blacklisté
1. Tenter de s'inscrire avec :
   - Email: `vendeur.test4@test.ci`
   - Téléphone: **+225 07 55 55 55 55** (blacklisté)

**Résultats attendus :**
- ❌ Inscription **REFUSÉE** (même message que 5.2)

---

## ⚡ Test 6 : Progression Automatique (NEW → VERIFIED)

### Objectif
Vérifier que le système upgrade automatiquement les utilisateurs fiables.

### Étapes

#### 6.1 - Créer 5 Commandes Réussies
1. Connecté comme `vendeur.test1@test.ci` (NEW tier)
2. Créer 5 commandes avec statut **"livree"** :
   - Commande 1: 50k - Livrer immédiatement
   - Commande 2: 75k - Livrer
   - Commande 3: 100k - Livrer
   - Commande 4: 120k - Livrer
   - Commande 5: 150k - Livrer

**Note**: Utiliser l'admin pour forcer le statut à "livree"

#### 6.2 - Attendre 7 Jours (Simulation)
Pour simuler sans attendre :
1. Admin → Firestore
2. Modifier `users/{userId}/createdAt` → -7 jours

#### 6.3 - Déclencher Vérification Auto
1. Créer une 6ème commande

**Résultats attendus :**
- ✅ Après création de commande, `upgradeTierIfEligible()` s'exécute
- ✅ `risk_assessments/{userId}` mis à jour :
  ```json
  {
    "tier": "verified",
    "riskScore": 75,
    "lastUpdated": "...",
    "upgradeReason": "auto_progression"
  }
  ```
- ✅ Bannière mise à jour immédiatement (tier VERIFIED)

---

## 👨‍💼 Test 7 : Écran Admin de Gestion

### Objectif
Tester toutes les fonctionnalités de l'écran admin.

### Étapes

#### 7.1 - Onglet Statistiques
1. Admin → **Gestion KYC Adaptative**
2. Onglet **"Statistiques"**

**Résultats attendus :**
- ✅ Cartes affichées avec compteurs en temps réel:
  - Total Utilisateurs: (nombre)
  - TRUSTED: (nombre)
  - VERIFIED: (nombre)
  - NEW USER: (nombre)
  - MODERATE RISK: (nombre)
  - HIGH RISK: (nombre)
  - BLACKLISTED: (nombre)
- ✅ Graphique de distribution avec barres de progression
- ✅ Pourcentages corrects

#### 7.2 - Onglet Utilisateurs par Tier
1. Onglet **"Utilisateurs par Tier"**
2. Filtrer par **"NEW USER"**

**Résultats attendus :**
- ✅ Liste affichée avec uniquement les users NEW
- ✅ Pour chaque user :
  - User ID (8 premiers caractères)
  - Badge tier coloré
  - Score de risque
  - Dernière MAJ
  - Actions : Upgrade, Downgrade, Blacklister

#### 7.3 - Tester Upgrade Manuel
1. Sélectionner un utilisateur NEW
2. Cliquer sur **"Upgrade Tier"**

**Résultats attendus :**
- ✅ Tier changé vers VERIFIED
- ✅ Message: "Tier upgradé vers VERIFIED"
- ✅ Firestore mis à jour immédiatement
- ✅ Bannière user mise à jour (si connecté)

#### 7.4 - Onglet Blacklist
1. Onglet **"Blacklist"**

**Résultats attendus :**
- ✅ Liste des entrées blacklist avec:
  - User ID
  - CNI / Téléphone
  - Raison
  - Date ajout
  - Bouton "Supprimer"

#### 7.5 - Retirer de la Blacklist
1. Cliquer sur **"Supprimer"** pour une entrée
2. Confirmer

**Résultats attendus :**
- ✅ `blacklist/{docId}` :
  ```json
  {
    "status": "removed"
  }
  ```
- ✅ Si userId connu, `risk_assessments/{userId}` :
  ```json
  {
    "tier": "moderateRisk"
  }
  ```
- ✅ Message: "Retiré de la blacklist"

#### 7.6 - Onglet Validations KYC
1. Onglet **"Validations KYC"**

**Résultats attendus :**
- ✅ Liste des KYC `status: pending`
- ✅ Pour chaque demande:
  - User ID
  - Type document
  - Date soumission
  - Boutons "Voir" pour chaque document
  - Actions: Approuver / Rejeter

---

## 🎭 Test 8 : Cas Limites

### Test 8.1 - Utilisateur Sans Risk Assessment
1. Créer un user directement dans Firebase Auth (bypass inscription)
2. Tenter de créer une commande

**Résultats attendus :**
- ❌ Commande refusée
- ✅ Message: "Profil utilisateur non trouvé"

### Test 8.2 - Stock Insuffisant + Limite OK
1. User NEW avec 200k de limite
2. Produit avec stock = 1
3. Créer commande 150k (dans limite) mais quantité > stock

**Résultats attendus :**
- ✅ Vérification KYC passe
- ❌ Réservation stock échoue
- ✅ Message: "Stock insuffisant pour un ou plusieurs produits"
- ✅ Commande **non créée**

### Test 8.3 - Erreur Firestore
1. Désactiver temporairement la connexion réseau
2. Tenter une action KYC

**Résultats attendus :**
- ✅ Fail gracefully avec message clair
- ✅ Pas de crash

---

## 📊 Tableau de Validation

| # | Test | Statut | Notes |
|---|------|--------|-------|
| 1.1 | Inscription NEW tier | ⬜ | |
| 1.2 | Bannière dashboard | ⬜ | |
| 2.1 | Commande dans limite | ⬜ | |
| 2.2 | Commande hors limite | ⬜ | |
| 2.3 | Limite quotidienne | ⬜ | |
| 3.1 | Soumission KYC | ⬜ | |
| 3.2 | Validation admin | ⬜ | |
| 3.3 | Nouvelles limites | ⬜ | |
| 3.4 | Test nouvelle limite | ⬜ | |
| 4.1 | Device partagé détecté | ⬜ | |
| 4.2 | Dashboard MODERATE | ⬜ | |
| 4.3 | Retraits bloqués | ⬜ | |
| 5.1 | Ajout blacklist | ⬜ | |
| 5.2 | Blocage CNI blacklistée | ⬜ | |
| 5.3 | Blocage tél blacklisté | ⬜ | |
| 6.1-6.3 | Progression auto | ⬜ | |
| 7.1 | Stats admin | ⬜ | |
| 7.2 | Liste users | ⬜ | |
| 7.3 | Upgrade manuel | ⬜ | |
| 7.4-7.5 | Gestion blacklist | ⬜ | |
| 7.6 | Validations KYC | ⬜ | |
| 8.1-8.3 | Cas limites | ⬜ | |

---

## ✅ Checklist de Mise en Production

Avant de déployer en production :

### Backend
- [ ] Tous les index Firestore déployés
- [ ] Firestore rules configurées et testées
- [ ] Audit logs activés
- [ ] Backup Firestore configuré

### Frontend
- [ ] Tous les tests passent
- [ ] Aucune erreur dans `flutter analyze`
- [ ] Performance testée (>60 FPS)
- [ ] Build APK release réussi

### Configuration
- [ ] Limites tier ajustées selon business
- [ ] Messages utilisateur validés (français correct)
- [ ] Contact support configuré (email, WhatsApp)
- [ ] Analytics configuré

### Documentation
- [ ] Support formé aux nouveaux messages
- [ ] FAQ créée pour utilisateurs
- [ ] Runbook incident créé

### Monitoring
- [ ] Dashboard Firebase Analytics configuré
- [ ] Alertes configurées (taux de blocage > 10%)
- [ ] Métriques KPIs définies

---

## 📞 Support en Cas de Problème

**Problème** : Bannière ne s'affiche pas
**Solution** : Vérifier que `risk_assessments/{userId}` existe dans Firestore

**Problème** : Tous les users sont MODERATE
**Solution** : Tester sur device réel (pas émulateur), ajuster scoring

**Problème** : Limites pas appliquées
**Solution** : Vérifier que `canPerformAction()` est appelé avant `createOrder()`

---

🎉 **Bon test !**
