# 🔥 GUIDE : Résoudre les erreurs d'index Firestore

Ce guide explique comment créer les index composites nécessaires pour les requêtes Firestore.

## 📋 Pourquoi ces erreurs ?

Firestore nécessite des **index composites** pour les requêtes qui :
- Filtrent sur plusieurs champs (`where()`)
- Combinent filtrage et tri (`orderBy()`)

## 🚀 Solution Rapide : Créer les index automatiquement

### Étape 1 : Identifier les erreurs dans les logs

Les logs affichent des URLs comme :
```
https://console.firebase.google.com/v1/r/project/social-media-business-pro/firestore/indexes?create_composite=...
```

### Étape 2 : Cliquer sur l'URL ou copier-coller dans le navigateur

Firebase Console va :
1. Vous connecter à votre projet
2. Pré-remplir la configuration de l'index
3. Vous demander de confirmer

### Étape 3 : Créer l'index

Cliquez sur **"Créer l'index"** et attendez 1-2 minutes (l'index se construit).

---

## 📊 Index requis pour SOCIAL BUSINESS Pro

Voici tous les index composites nécessaires :

### 1. **Livraisons par livreur** (deliveries)
**Champs** :
- `livreurId` (Ascending)
- `createdAt` (Descending)

**URL** :
```
https://console.firebase.google.com/v1/r/project/social-media-business-pro/firestore/indexes?create_composite=Clxwcm9qZWN0cy9zb2NpYWwtbWVkaWEtYnVzaW5lc3MtcHJvL2RhdGFiYXNlcy8oZGVmYXVsdCkvY29sbGVjdGlvbkdyb3Vwcy9kZWxpdmVyaWVzL2luZGV4ZXMvXxABGg0KCWxpdnJldXJJZBABGg0KCWNyZWF0ZWRBdBACGgwKCF9fbmFtZV9fEAI
```

### 2. **Commandes par vendeur** (orders)
**Champs** :
- `vendeurId` (Ascending)
- `createdAt` (Descending)

**URL** :
```
https://console.firebase.google.com/v1/r/project/social-media-business-pro/firestore/indexes?create_composite=Clhwcm9qZWN0cy9zb2NpYWwtbWVkaWEtYnVzaW5lc3MtcHJvL2RhdGFiYXNlcy8oZGVmYXVsdCkvY29sbGVjdGlvbkdyb3Vwcy9vcmRlcnMvaW5kZXhlcy9fEAEaDQoJdmVuZGV1cklkEAEaDQoJY3JlYXRlZEF0EAIaDAoIX19uYW1lX18QAg
```

### 3. **Abonnements vendeur** (subscriptions)
**Champs** :
- `status` (Ascending)
- `vendeurId` (Ascending)
- `createdAt` (Descending)

**URL** :
```
https://console.firebase.google.com/v1/r/project/social-media-business-pro/firestore/indexes?create_composite=Cl9wcm9qZWN0cy9zb2NpYWwtbWVkaWEtYnVzaW5lc3MtcHJvL2RhdGFiYXNlcy8oZGVmYXVsdCkvY29sbGVjdGlvbkdyb3Vwcy9zdWJzY3JpcHRpb25zL2luZGV4ZXMvXxABGgoKBnN0YXR1cxABGg0KCXZlbmRldXJJZBABGg0KCWNyZWF0ZWRBdBACGgwKCF9fbmFtZV9fEAI
```

### 4. **Abonnements livreur** (livreur_subscriptions)
**Champs** :
- `livreurId` (Ascending)
- `status` (Ascending)
- `createdAt` (Descending)

**URL** :
```
https://console.firebase.google.com/v1/r/project/social-media-business-pro/firestore/indexes?create_composite=Cmdwcm9qZWN0cy9zb2NpYWwtbWVkaWEtYnVzaW5lc3MtcHJvL2RhdGFiYXNlcy8oZGVmYXVsdCkvY29sbGVjdGlvbkdyb3Vwcy9saXZyZXVyX3N1YnNjcmlwdGlvbnMvaW5kZXhlcy9fEAEaDQoJbGl2cmV1cklkEAEaCgoGc3RhdHVzEAEaDQoJY3JlYXRlZEF0EAIaDAoIX19uYW1lX18QAg
```

### 5. **Historique paiements vendeur** (subscription_payments)
**Champs** :
- `vendeurId` (Ascending)
- `paymentDate` (Descending)

**URL** :
```
https://console.firebase.google.com/v1/r/project/social-media-business-pro/firestore/indexes?create_composite=Cmdwcm9qZWN0cy9zb2NpYWwtbWVkaWEtYnVzaW5lc3MtcHJvL2RhdGFiYXNlcy8oZGVmYXVsdCkvY29sbGVjdGlvbkdyb3Vwcy9zdWJzY3JpcHRpb25fcGF5bWVudHMvaW5kZXhlcy9fEAEaDQoJdmVuZGV1cklkEAEaDwoLcGF5bWVudERhdGUQAhoMCghfX25hbWVfXxAC
```

### 6. **Commandes par acheteur** (orders)
**Champs** :
- `buyerId` (Ascending)
- `createdAt` (Descending)

**URL** :
```
https://console.firebase.google.com/v1/r/project/social-media-business-pro/firestore/indexes?create_composite=Clhwcm9qZWN0cy9zb2NpYWwtbWVkaWEtYnVzaW5lc3MtcHJvL2RhdGFiYXNlcy8oZGVmYXVsdCkvY29sbGVjdGlvbkdyb3Vwcy9vcmRlcnMvaW5kZXhlcy9fEAEaCwoHYnV5ZXJJZBABGg0KCWNyZWF0ZWRBdBACGgwKCF9fbmFtZV9fEAI
```

### 7. **Notifications par utilisateur** (notifications)
**Champs** :
- `userId` (Ascending)
- `createdAt` (Descending)

**URL** :
```
https://console.firebase.google.com/v1/r/project/social-media-business-pro/firestore/indexes?create_composite=Cl9wcm9qZWN0cy9zb2NpYWwtbWVkaWEtYnVzaW5lc3MtcHJvL2RhdGFiYXNlcy8oZGVmYXVsdCkvY29sbGVjdGlvbkdyb3Vwcy9ub3RpZmljYXRpb25zL2luZGV4ZXMvXxABGgoKBnVzZXJJZBABGg0KCWNyZWF0ZWRBdBACGgwKCF9fbmFtZV9fEAI
```

---

## 🛠️ Méthode alternative : Créer manuellement depuis Firebase Console

Si les URLs ne marchent pas :

### 1. Accéder à Firebase Console
```
https://console.firebase.google.com/project/social-media-business-pro/firestore/indexes
```

### 2. Cliquer sur "Créer un index"

### 3. Remplir la configuration

**Exemple pour "Livraisons par livreur"** :

| Paramètre | Valeur |
|-----------|--------|
| Collection ID | `deliveries` |
| Champ 1 | `livreurId` → Ascending |
| Champ 2 | `createdAt` → Descending |

### 4. Cliquer sur "Créer"

### 5. Répéter pour chaque index

---

## ⚡ Script automatique (optionnel)

Si vous avez Firebase CLI installé :

```bash
# Générer les index depuis les logs
firebase firestore:indexes > firestore.indexes.json

# Déployer les index
firebase deploy --only firestore:indexes
```

---

## 🎯 Comment savoir si c'est réussi ?

### Dans Firebase Console
- Les index apparaissent dans l'onglet **"Index"**
- Le statut doit être **"Enabled"** (vert)

### Dans l'application
- Les erreurs `failed-precondition` disparaissent des logs
- Les données s'affichent correctement
- Plus de message "The query requires an index"

---

## 📝 Notes importantes

1. **Temps de création** : 1-2 minutes par index (parfois jusqu'à 10 minutes)
2. **Coût** : Les index sont **gratuits** dans le plan Spark (gratuit)
3. **Une seule fois** : Une fois créés, les index restent en place même après redémarrage
4. **Ordre important** : L'ordre des champs dans l'index doit correspondre exactement à la requête

---

## 🆘 Aide supplémentaire

Si vous rencontrez des problèmes :

1. Vérifiez que vous êtes connecté au bon compte Google
2. Vérifiez que vous avez les droits **Propriétaire** ou **Éditeur** sur le projet
3. Attendez 2-3 minutes après création avant de tester
4. Redémarrez l'application après création des index

---

**Date de création** : 3 Novembre 2025
**Projet** : SOCIAL BUSINESS Pro
**Firebase Project ID** : `social-media-business-pro`
