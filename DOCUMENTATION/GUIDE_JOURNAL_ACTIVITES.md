# 📋 Guide : Journal des Activités Admin

## 🎯 Objectif

Le **Journal des activités** permet aux administrateurs de suivre toutes les actions importantes qui se passent sur la plateforme :
- Création/modification/suppression de produits
- Inscription/approbation d'utilisateurs
- Validation de KYC
- Commandes passées/livrées/annulées
- Événements système (maintenances, backups, alertes)

---

## ❓ Pourquoi "Aucune activité récente" ?

### Explication

L'index Firestore a été créé et déployé avec succès, mais la page affiche "Aucune activité récente" car la collection `activity_logs` dans Firestore est **vide**.

**C'est NORMAL** : l'index Firestore fonctionne sur les données existantes ET futures. Le problème n'est pas l'index, mais l'absence de données dans la collection.

### Analogie

Imaginez une bibliothèque (Firestore) avec un catalogue (index) bien organisé, mais sans livres (documents) sur les étagères. Le catalogue fonctionne parfaitement, mais il n'y a rien à cataloguer !

---

## ✅ Solution 1 : Générer des données de test (Recommandé)

### Étapes

1. **Aller sur le Dashboard Admin**
   - Connectez-vous en tant qu'admin
   - Allez sur la page d'accueil admin

2. **Cliquer sur "Générer données de test"**
   - Dans la section "Actions rapides"
   - Bouton avec icône 🧪 (science)
   - Couleur orange

3. **Attendre la confirmation**
   - Un loader s'affiche pendant la création
   - Message de succès : "✅ 12 activités de test créées avec succès"

4. **Vérifier le Journal des activités**
   - Cliquer sur "Voir toutes les activités"
   - Les 12 activités de test s'affichent
   - Tester les filtres : Toutes, Utilisateurs, Produits, Commandes, Système

### Activités de test créées

| Type | Nombre | Exemples |
|------|--------|----------|
| **Utilisateurs** | 3 | Nouvel acheteur, Vendeur approuvé, KYC vérifié |
| **Produits** | 3 | Produit ajouté, modifié, supprimé |
| **Commandes** | 3 | Commande passée, livrée, annulée |
| **Système** | 3 | Maintenance, backup, alerte sécurité |

### Fichier créé

[lib/utils/create_test_activities.dart](lib/utils/create_test_activities.dart)

**Fonctionnalités** :
- `seedTestActivities()` : Crée 12 activités de test
- `clearAllActivities()` : Supprime toutes les activités (pour nettoyage)
- `logActivity()` : Enregistre une activité réelle depuis l'app

---

## ✅ Solution 2 : Logging automatique des activités (Production)

### Principe

Pour que le Journal des activités se remplisse automatiquement en production, il faut intégrer la fonction `ActivityLogSeeder.logActivity()` dans les services métier.

### Exemples d'intégration

#### 1. Dans le service produit ([product_service.dart](lib/services/product_service.dart))

```dart
import 'package:social_business_pro/utils/create_test_activities.dart';

Future<void> createProduct(ProductModel product) async {
  try {
    // Créer le produit dans Firestore
    await _firestore.collection('products').doc(product.id).set(product.toMap());

    // Logger l'activité
    await ActivityLogSeeder.logActivity(
      type: 'products',
      action: 'product_created',
      userName: product.vendeurName,
      description: 'Nouveau produit ajouté: ${product.name}',
    );
  } catch (e) {
    debugPrint('❌ Erreur création produit: $e');
    rethrow;
  }
}
```

#### 2. Dans le service utilisateur ([firebase_service.dart](lib/services/firebase_service.dart))

```dart
Future<void> approveVendor(String vendorId, String vendorName) async {
  try {
    // Approuver le vendeur
    await _firestore.collection('users').doc(vendorId).update({
      'accountStatus': 'approved',
      'approvedAt': FieldValue.serverTimestamp(),
    });

    // Logger l'activité
    await ActivityLogSeeder.logActivity(
      type: 'users',
      action: 'vendor_approved',
      userName: 'Admin Système',
      description: 'Vendeur approuvé: $vendorName',
    );
  } catch (e) {
    debugPrint('❌ Erreur approbation vendeur: $e');
    rethrow;
  }
}
```

#### 3. Dans le service KYC

```dart
Future<void> verifyKYC(String userId, String userName) async {
  try {
    // Vérifier le KYC
    await _firestore.collection('users').doc(userId).update({
      'kycVerificationStatus': 'approved',
      'kycVerifiedAt': FieldValue.serverTimestamp(),
    });

    // Logger l'activité
    await ActivityLogSeeder.logActivity(
      type: 'users',
      action: 'kyc_verified',
      userName: 'Admin Système',
      description: 'KYC vérifié pour: $userName',
    );
  } catch (e) {
    debugPrint('❌ Erreur vérification KYC: $e');
    rethrow;
  }
}
```

#### 4. Dans le service commandes ([order_service.dart](lib/services/order_service.dart))

```dart
Future<void> createOrder(OrderModel order, String buyerName) async {
  try {
    // Créer la commande
    await _firestore.collection('orders').doc(order.id).set(order.toMap());

    // Logger l'activité
    await ActivityLogSeeder.logActivity(
      type: 'orders',
      action: 'order_placed',
      userName: buyerName,
      description: 'Nouvelle commande #${order.orderNumber} - Montant: ${order.total} FCFA',
    );
  } catch (e) {
    debugPrint('❌ Erreur création commande: $e');
    rethrow;
  }
}
```

### Actions à logger

| Service | Action | Type | Description |
|---------|--------|------|-------------|
| **Auth** | Inscription | `users` | Nouvel utilisateur inscrit |
| **Auth** | Approbation vendeur | `users` | Vendeur approuvé par admin |
| **Auth** | Suspension | `users` | Compte utilisateur suspendu |
| **KYC** | Vérification | `users` | KYC vérifié/rejeté |
| **Produit** | Création | `products` | Nouveau produit ajouté |
| **Produit** | Modification | `products` | Produit modifié (prix, stock, etc.) |
| **Produit** | Suppression | `products` | Produit supprimé |
| **Commande** | Création | `orders` | Nouvelle commande passée |
| **Commande** | Livraison | `orders` | Commande livrée |
| **Commande** | Annulation | `orders` | Commande annulée |
| **Système** | Maintenance | `system` | Maintenance programmée |
| **Système** | Backup | `system` | Sauvegarde effectuée |
| **Système** | Alerte | `system` | Alerte sécurité/technique |

---

## 🔍 Structure des activités dans Firestore

### Collection : `activity_logs`

```javascript
{
  "type": "users" | "products" | "orders" | "system",
  "action": "user_created" | "product_updated" | "order_placed" | ...,
  "userName": "Nom de l'utilisateur qui a effectué l'action",
  "description": "Description lisible de l'activité",
  "timestamp": Timestamp (date/heure de l'action),
  "createdAt": Timestamp (date de création du document)
}
```

### Index Firestore nécessaire

Déjà ajouté dans [firestore.indexes.json](firestore.indexes.json) :

```json
{
  "collectionGroup": "activity_logs",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "type", "order": "ASCENDING" },
    { "fieldPath": "timestamp", "order": "DESCENDING" }
  ]
}
```

**Déploiement** :
```bash
firebase deploy --only firestore:indexes
```

---

## 🎨 Interface du Journal des activités

### Fonctionnalités

1. **Filtres par type**
   - Toutes les activités
   - Utilisateurs (inscriptions, approbations, KYC)
   - Produits (créations, modifications, suppressions)
   - Commandes (nouvelles, livrées, annulées)
   - Système (maintenances, backups, alertes)

2. **Affichage chronologique**
   - Tri par date décroissante (plus récent en premier)
   - Limite de 100 activités par page
   - Scroll infini possible

3. **Informations affichées**
   - Icône selon le type
   - Nom de l'utilisateur
   - Description de l'action
   - Date/heure relative (il y a 2h, hier, etc.)

---

## 🚀 Prochaines étapes

### Court terme (cette semaine)

1. **Tester le bouton "Générer données de test"**
   - Vérifier que les 12 activités sont bien créées
   - Tester tous les filtres
   - Vérifier l'affichage chronologique

2. **Nettoyer les données de test** (optionnel)
   - Appeler `ActivityLogSeeder.clearAllActivities()` depuis la console Firebase
   - Ou supprimer manuellement depuis la console Firestore

### Moyen terme (2-4 semaines)

1. **Intégrer le logging dans les services principaux**
   - `product_service.dart` : créations, modifications, suppressions
   - `firebase_service.dart` : approbations, suspensions
   - `order_service.dart` : créations, mises à jour de statut
   - Service KYC : vérifications, rejets

2. **Ajouter des activités système**
   - Tâches CRON (nettoyage, rappels)
   - Détection d'anomalies
   - Backups automatiques

### Long terme (1-3 mois)

1. **Améliorer l'interface**
   - Pagination avancée
   - Recherche par mot-clé
   - Export CSV/PDF pour audits

2. **Ajouter des analytics**
   - Nombre d'actions par type/jour
   - Utilisateurs les plus actifs
   - Détection de patterns anormaux

3. **Notifications temps réel**
   - Alertes pour actions critiques
   - Push notifications admin
   - Emails de rapport quotidien

---

## 📝 Notes importantes

### Performance

- Limite de 100 activités par requête (ligne 98 de `activity_log_screen.dart`)
- Index Firestore optimise les requêtes filtrées
- Pas d'impact sur les performances globales de l'app

### Sécurité

- Seuls les admins peuvent accéder au Journal des activités
- Route protégée : `/admin/activities`
- Logs non modifiables (audit trail)

### Coûts Firestore

- Lecture : ~100 documents à chaque chargement de page
- Écriture : 1 document par activité loggée
- Estimé : <100 activités/jour → coût négligeable (<0.01€/mois)

---

Généré le : 21/11/2025 à 05:30
