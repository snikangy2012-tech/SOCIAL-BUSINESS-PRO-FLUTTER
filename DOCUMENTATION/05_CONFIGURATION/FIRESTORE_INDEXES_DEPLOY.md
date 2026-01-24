# 🔥 Guide de Déploiement des Index Firestore

## 📋 Vue d'ensemble

Ce document liste tous les **index Firestore composés** nécessaires pour le bon fonctionnement de l'application Social Business Pro.

**Dernière mise à jour** : 21 novembre 2025
**Fichier de configuration** : [firestore.indexes.json](firestore.indexes.json)
**Index déployés** : 5 index composés

---

## 🚀 Déploiement Rapide

### Commande unique

```bash
firebase deploy --only firestore:indexes
```

### Temps estimé
- ⏱️ **2-5 minutes** pour la construction de tous les index

---

## 📊 Index Déployés

### 1. Journal des Activités Admin (`activity_logs`)

**Page** : [activity_log_screen.dart](lib/screens/admin/activity_log_screen.dart)
**Lignes** : 94-105

**Requête Firestore** :
```dart
FirebaseFirestore.instance
  .collection('activity_logs')
  .where('type', isEqualTo: 'users') // Filtre par type
  .orderBy('timestamp', descending: true)
  .limit(100)
```

**Index** :
```json
{
  "collectionGroup": "activity_logs",
  "fields": [
    { "fieldPath": "type", "order": "ASCENDING" },
    { "fieldPath": "timestamp", "order": "DESCENDING" }
  ]
}
```

**Filtres disponibles** :
- `all` : Toutes les activités
- `users` : Utilisateurs (inscriptions, approbations, KYC)
- `products` : Produits (créations, modifications, suppressions)
- `orders` : Commandes (nouvelles, livrées, annulées)
- `system` : Système (maintenances, backups, alertes)

---

### 2. Historique des Paiements Vendeur (`payments`)

**Page** : [payment_history_screen.dart](lib/screens/vendeur/payment_history_screen.dart)
**Lignes** : 423-446

L'historique des paiements utilise **4 index différents** selon les combinaisons de filtres :

#### Index 2.1 : Base (vendeur + date)

**Requête** :
```dart
.where('vendeurId', isEqualTo: vendeurId)
.orderBy('createdAt', descending: true)
```

**Index** :
```json
{
  "collectionGroup": "payments",
  "fields": [
    { "fieldPath": "vendeurId", "order": "ASCENDING" },
    { "fieldPath": "createdAt", "order": "DESCENDING" }
  ]
}
```

**Utilisation** : Tous les paiements sans filtre

---

#### Index 2.2 : Vendeur + Méthode + Date

**Requête** :
```dart
.where('vendeurId', isEqualTo: vendeurId)
.where('paymentMethod', isEqualTo: 'mobile_money')
.orderBy('createdAt', descending: true)
```

**Index** :
```json
{
  "collectionGroup": "payments",
  "fields": [
    { "fieldPath": "vendeurId", "order": "ASCENDING" },
    { "fieldPath": "paymentMethod", "order": "ASCENDING" },
    { "fieldPath": "createdAt", "order": "DESCENDING" }
  ]
}
```

**Utilisation** : Filtre par méthode (Mobile Money, Espèces, Carte)

---

#### Index 2.3 : Vendeur + Statut + Date

**Requête** :
```dart
.where('vendeurId', isEqualTo: vendeurId)
.where('status', isEqualTo: 'completed')
.orderBy('createdAt', descending: true)
```

**Index** :
```json
{
  "collectionGroup": "payments",
  "fields": [
    { "fieldPath": "vendeurId", "order": "ASCENDING" },
    { "fieldPath": "status", "order": "ASCENDING" },
    { "fieldPath": "createdAt", "order": "DESCENDING" }
  ]
}
```

**Utilisation** : Filtre par statut (Validés, En attente, Échoués)

---

#### Index 2.4 : Vendeur + Méthode + Statut + Date (Complet)

**Requête** :
```dart
.where('vendeurId', isEqualTo: vendeurId)
.where('paymentMethod', isEqualTo: 'mobile_money')
.where('status', isEqualTo: 'completed')
.orderBy('createdAt', descending: true)
```

**Index** :
```json
{
  "collectionGroup": "payments",
  "fields": [
    { "fieldPath": "vendeurId", "order": "ASCENDING" },
    { "fieldPath": "paymentMethod", "order": "ASCENDING" },
    { "fieldPath": "status", "order": "ASCENDING" },
    { "fieldPath": "createdAt", "order": "DESCENDING" }
  ]
}
```

**Utilisation** : Combinaison de tous les filtres

---

## 🎯 Options de Filtrage

### Historique des Paiements

| Filtre | Valeurs disponibles |
|--------|---------------------|
| **Période** | 7 jours, 30 jours, 90 jours, Tout |
| **Méthode** | Tous, Mobile Money, Espèces, Carte |
| **Statut** | Tous, Validés ✅, En attente ⏳, Échoués ❌ |

### Journal des Activités

| Filtre | Valeurs disponibles |
|--------|---------------------|
| **Type** | Toutes, Utilisateurs, Produits, Commandes, Système |

---

## 📝 Procédure de Déploiement

### Étape 1 : Préparation

```bash
# Vérifier que Firebase CLI est installé
firebase --version

# Si non installé :
npm install -g firebase-tools

# Se connecter à Firebase
firebase login
```

### Étape 2 : Déploiement

```bash
# Se positionner dans le répertoire du projet
cd c:\Users\ALLAH-PC\social_media_business_pro

# Déployer uniquement les index
firebase deploy --only firestore:indexes
```

**Sortie attendue** :
```
=== Deploying to 'your-project-id'...

i  firestore: reading indexes from firestore.indexes.json...
✔  firestore: indexes deployed successfully

✔  Deploy complete!
```

### Étape 3 : Vérification

1. **Console Firebase** :
   - Aller sur https://console.firebase.google.com
   - Sélectionner votre projet
   - Firestore Database → Index
   - Vérifier que tous les index sont **"Enabled"** (vert)

2. **Test dans l'application** :
   - Aller sur l'**Historique des Paiements** (vendeur)
   - Tester tous les filtres :
     - ✅ Méthode : Mobile Money
     - ✅ Statut : Validés
     - ✅ Combinaison : Mobile Money + Validés
   - Aller sur le **Journal des Activités** (admin)
   - Tester tous les filtres (Utilisateurs, Produits, Commandes, Système)

---

## 🚨 Résolution de Problèmes

### Erreur : Index manquant

```
[cloud_firestore/failed-precondition] The query requires an index.
You can create it here: https://console.firebase.google.com/...
```

**Solution 1** : Déployer via CLI (recommandé)
```bash
firebase deploy --only firestore:indexes
```

**Solution 2** : Créer manuellement
- Copier l'URL de l'erreur
- Ouvrir dans un navigateur
- Cliquer sur "Créer l'index"

---

### Erreur : Index en construction

```
The index is still being built. Please wait...
```

**Solution** :
- ⏱️ **Patienter 2-5 minutes**
- Rafraîchir la page
- Vérifier le statut dans la Console Firebase

---

### Erreur : JSON invalide

```
Error parsing firestore.indexes.json
```

**Solution** :
```bash
# Vérifier la syntaxe JSON
cat firestore.indexes.json | jq .

# Ou ouvrir dans VSCode (détection automatique d'erreurs)
code firestore.indexes.json
```

---

## 💡 Pourquoi ces Index ?

### Principe Firestore

Firestore nécessite un **index composé** pour :
- 2+ conditions `where()` sur des champs différents
- 1+ condition `where()` + 1 `orderBy()` sur un champ différent

### Exemple concret

❌ **Sans index** (requête échoue) :
```dart
.where('vendeurId', isEqualTo: 'abc')
.where('status', isEqualTo: 'completed')
.orderBy('createdAt', descending: true)
```

✅ **Avec index** (requête réussit) :
```json
{
  "fields": [
    { "fieldPath": "vendeurId", "order": "ASCENDING" },
    { "fieldPath": "status", "order": "ASCENDING" },
    { "fieldPath": "createdAt", "order": "DESCENDING" }
  ]
}
```

---

## 📊 Impact sur les Performances

### Sans index
- ⚠️ Scan de **toute la collection**
- 💰 Coût élevé (1 lecture par document)
- 🐌 Lent (plusieurs secondes)

### Avec index
- ✅ Recherche **optimisée**
- 💚 Coût réduit (~90% moins de lectures)
- ⚡ Rapide (millisecondes)

### Exemple chiffré

| Collection | Sans index | Avec index | Gain |
|-----------|-----------|-----------|------|
| 100 paiements | 100 lectures | 10 lectures | 90% |
| 1000 paiements | 1000 lectures | 100 lectures | 90% |
| 10000 paiements | 10000 lectures | 1000 lectures | 90% |

---

## 📚 Ressources

- [Documentation Firestore - Index](https://firebase.google.com/docs/firestore/query-data/indexing)
- [Meilleures pratiques](https://firebase.google.com/docs/firestore/query-data/index-overview)
- [Tarification Firestore](https://firebase.google.com/pricing)

---

## ✅ Checklist de Déploiement

- [ ] Firebase CLI installé et configuré
- [ ] Fichier `firestore.indexes.json` vérifié
- [ ] Commande `firebase deploy --only firestore:indexes` exécutée
- [ ] Message "Deploy complete!" affiché
- [ ] Tous les index "Enabled" dans la Console Firebase
- [ ] Historique des paiements testé avec filtres
- [ ] Journal des activités testé avec filtres
- [ ] Aucune erreur de précondition

---

Généré le : 21/11/2025 à 05:50
