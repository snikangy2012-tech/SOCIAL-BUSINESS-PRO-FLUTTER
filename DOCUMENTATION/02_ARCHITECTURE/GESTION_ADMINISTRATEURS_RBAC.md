# Système de Gestion des Administrateurs et Contrôle d'Accès Basé sur les Rôles (RBAC)

## Vue d'ensemble

Ce document décrit le système complet de gestion des administrateurs mis en place dans **SOCIAL BUSINESS Pro**, incluant :
- La hiérarchie des rôles administratifs
- Le système de privilèges granulaires
- La gestion des administrateurs (CRUD)
- L'accès aux fonctionnalités financières
- La sécurité et le contrôle d'accès

## Architecture du Système

### 1. Hiérarchie des Rôles

Le système définit **5 types de rôles administratifs** avec des niveaux d'accès différents :

#### 🔴 Super Administrateur (Super Admin)
- **Accès** : Total et illimité
- **Privilèges** : TOUS les privilèges disponibles (18 au total)
- **Capacités spéciales** :
  - Créer, modifier et supprimer d'autres administrateurs
  - Accès à la gestion financière complète
  - Modifier les paramètres système
  - Gérer les abonnements et commissions
- **Restrictions** : Aucune
- **Nombre recommandé** : 1-2 maximum par plateforme

#### 🟠 Administrateur (Admin)
- **Accès** : Gestion générale de la plateforme
- **Privilèges** : 12 privilèges
  - Gestion des utilisateurs (voir, gérer)
  - Gestion des vendeurs (voir, gérer, KYC)
  - Gestion des livreurs (voir, gérer, KYC)
  - Gestion des produits (voir, gérer)
  - Gestion des commandes (voir, gérer)
  - Voir les abonnements
  - Gestion des signalements
- **Restrictions** :
  - ❌ Pas d'accès à la gestion financière
  - ❌ Ne peut pas créer d'autres admins
  - ❌ Ne peut pas modifier les paramètres système
- **Usage** : Gestion quotidienne de la plateforme

#### 🟡 Modérateur (Moderator)
- **Accès** : Modération du contenu
- **Privilèges** : 6 privilèges
  - Voir les utilisateurs, vendeurs, produits
  - Gérer les produits (modération)
  - Voir et gérer les signalements
- **Restrictions** :
  - ❌ Pas de gestion des utilisateurs (suspension, suppression)
  - ❌ Pas d'accès aux commandes
  - ❌ Pas d'accès aux finances
- **Usage** : Modération du contenu et gestion des signalements

#### 🟢 Support Client (Support)
- **Accès** : Consultation uniquement
- **Privilèges** : 6 privilèges (lecture seule)
  - Voir utilisateurs, vendeurs, livreurs
  - Voir produits, commandes, abonnements
- **Restrictions** :
  - ❌ Aucune modification possible
  - ❌ Lecture seule sur tout
- **Usage** : Assistance client et support

#### 🔵 Gestionnaire Financier (Finance)
- **Accès** : Gestion des abonnements et consultation financière
- **Privilèges** : 6 privilèges
  - Voir utilisateurs, vendeurs, livreurs
  - Voir et gérer les abonnements
  - Voir les commandes
- **Restrictions** :
  - ❌ Pas d'accès aux revenus de la plateforme (super admin only)
  - ❌ Pas de gestion des utilisateurs
- **Usage** : Gestion des abonnements vendeurs/livreurs

### 2. Système de Privilèges

Le système définit **18 privilèges granulaires** répartis en 7 catégories :

#### Gestion des Utilisateurs
- `viewUsers` : Voir la liste des utilisateurs
- `manageUsers` : Gérer (suspendre, activer) les utilisateurs
- `deleteUsers` : Supprimer des utilisateurs

#### Gestion des Vendeurs
- `viewVendors` : Voir les vendeurs
- `manageVendors` : Gérer les vendeurs (KYC, vérification)

#### Gestion des Livreurs
- `viewDelivery` : Voir les livreurs
- `manageDelivery` : Gérer les livreurs (KYC, vérification)

#### Gestion des Produits
- `viewProducts` : Voir les produits
- `manageProducts` : Gérer (modifier, supprimer) les produits

#### Gestion des Commandes
- `viewOrders` : Voir les commandes
- `manageOrders` : Gérer les commandes

#### Gestion Financière ⭐ (SUPER ADMIN ONLY)
- `viewFinance` : Voir les statistiques financières
- `manageFinance` : Gérer les revenus et commissions

#### Gestion des Abonnements
- `viewSubscriptions` : Voir les abonnements
- `manageSubscriptions` : Gérer les abonnements

#### Gestion des Administrateurs ⭐ (SUPER ADMIN ONLY)
- `viewAdmins` : Voir la liste des admins
- `manageAdmins` : Créer, modifier, supprimer des admins

#### Gestion du Contenu
- `viewReports` : Voir les signalements
- `manageReports` : Gérer les signalements

#### Paramètres Système ⭐ (SUPER ADMIN ONLY)
- `viewSettings` : Voir les paramètres
- `manageSettings` : Modifier les paramètres système

## Interface Utilisateur

### Navigation Dynamique

La barre de navigation en bas de l'écran s'adapte selon le rôle de l'administrateur :

#### Pour le Super Admin (5 onglets)
1. 📊 **Dashboard** : Vue d'ensemble
2. 👥 **Utilisateurs** : Gestion des utilisateurs
3. 📈 **Statistiques** : Statistiques globales
4. 💰 **Finance** : Gestion financière ⭐ (SUPER ADMIN ONLY)
5. 👤 **Profil** : Profil admin

#### Pour les Autres Admins (4 onglets)
1. 📊 **Dashboard** : Vue d'ensemble
2. 👥 **Utilisateurs** : Gestion des utilisateurs
3. 📈 **Statistiques** : Statistiques globales
4. 👤 **Profil** : Profil admin

### Écran de Gestion des Administrateurs

Accessible depuis le Dashboard (bouton "Gérer les Administrateurs"), cet écran permet :

#### Fonctionnalités :
- ✅ **Créer un nouvel administrateur**
  - Nom complet
  - Email
  - Mot de passe initial
  - Attribution du rôle
  - Note : Impossible de créer un Super Admin (sécurité)

- ✅ **Rechercher des administrateurs**
  - Recherche par nom ou email
  - Résultats en temps réel

- ✅ **Voir la liste des administrateurs**
  - Nom, email, rôle
  - Statut (actif/suspendu)
  - Badge Super Admin visible

- ✅ **Modifier un administrateur**
  - Changer le rôle
  - Ajouter/retirer des privilèges personnalisés
  - Suspendre/activer le compte

- ✅ **Voir les privilèges détaillés**
  - Liste complète des privilèges par rôle
  - Privilèges personnalisés affichés séparément

#### Restrictions de Sécurité :
- ❌ Un admin ne peut pas créer un Super Admin
- ❌ Un admin ne peut pas se modifier lui-même
- ❌ Un admin ne peut pas se supprimer lui-même
- ✅ Seul le Super Admin peut accéder à cet écran

## Écran de Gestion Financière

### Accès : Super Admin Uniquement

L'écran financier est accessible via l'onglet "Finance" dans la navigation (visible uniquement pour le super admin).

### Fonctionnalités :

#### 1. Filtres de Période
- 7 derniers jours
- 30 derniers jours (mois)
- 3 derniers mois
- 1 an
- Toutes les données

#### 2. Cartes Statistiques
- **Revenu Total** : Somme de tous les revenus
- **Commissions Ventes** : Commissions sur les ventes (5% à 15%)
- **Commissions Livraisons** : Commissions sur les livraisons (10% à 25%)
- **Abonnements** : Revenus des abonnements vendeurs + livreurs

#### 3. Résumé du Mois en Cours
- Nombre de commandes livrées
- Nombre de livraisons effectuées
- Abonnements vendeurs actifs
- Abonnements livreurs actifs
- Total du mois

#### 4. Transactions Récentes
- 10 dernières transactions affichées
- Type de revenu (commission vente, livraison, abonnement)
- Description détaillée
- Date et heure
- Montant en FCFA

## Implémentation Technique

### Fichiers Principaux

#### 1. `lib/models/admin_role_model.dart`
Définit les modèles de données pour les rôles et privilèges :

```dart
enum AdminPrivilege {
  viewUsers, manageUsers, deleteUsers,
  viewVendors, manageVendors,
  viewDelivery, manageDelivery,
  viewProducts, manageProducts,
  viewOrders, manageOrders,
  viewFinance, manageFinance,
  viewSubscriptions, manageSubscriptions,
  viewAdmins, manageAdmins,
  viewReports, manageReports,
  viewSettings, manageSettings,
}

enum AdminRoleType {
  superAdmin, admin, moderator, support, finance
}

class AdminRole {
  final AdminRoleType type;
  final String name;
  final String description;
  final List<AdminPrivilege> privileges;

  // Méthodes utiles
  bool hasPrivilege(AdminPrivilege privilege);
  bool hasAllPrivileges(List<AdminPrivilege> requiredPrivileges);
  bool hasAnyPrivilege(List<AdminPrivilege> requiredPrivileges);
}

class AdminUser {
  final String uid;
  final AdminRoleType role;
  final bool isSuperAdmin;
  final List<AdminPrivilege> customPrivileges;
  final bool isActive;

  // Obtenir tous les privilèges (rôle + custom)
  List<AdminPrivilege> get allPrivileges;

  // Vérifier si cet admin a un privilège
  bool hasPrivilege(AdminPrivilege privilege);
}
```

#### 2. `lib/screens/admin/admin_management_screen.dart`
Interface de gestion des administrateurs :
- Formulaire de création d'admin
- Liste des admins avec recherche
- Modification et suspension
- Affichage détaillé des privilèges

#### 3. `lib/screens/admin/admin_main_screen.dart`
Navigation principale avec logique conditionnelle :

```dart
final isSuperAdmin = user.isSuperAdmin;

// Écrans dynamiques selon le rôle
final List<Widget> screens = isSuperAdmin
    ? [Dashboard, Users, Stats, Finance, Profile]  // 5 écrans
    : [Dashboard, Users, Stats, Profile];          // 4 écrans

// Navigation dynamique selon le rôle
final List<BottomNavigationBarItem> navItems = isSuperAdmin
    ? [Dashboard, Users, Stats, Finance, Profile]  // 5 onglets
    : [Dashboard, Users, Stats, Profile];          // 4 onglets
```

#### 4. `lib/screens/admin/super_admin_finance_screen.dart`
Écran de gestion financière avec :
- Sélecteur de période
- Cartes statistiques
- Résumé mensuel
- Liste des transactions

#### 5. `lib/services/platform_revenue_service.dart`
Service de gestion des revenus :
- `recordSaleCommission()` : Enregistrer commission vente
- `recordDeliveryCommission()` : Enregistrer commission livraison
- `recordVendeurSubscriptionRevenue()` : Enregistrer abonnement vendeur
- `recordLivreurSubscriptionRevenue()` : Enregistrer abonnement livreur
- `getRevenueByPeriod()` : Récupérer revenus par période
- `getMonthlySummary()` : Résumé mensuel
- `getGlobalStats()` : Statistiques globales

#### 6. `lib/models/user_model.dart`
Modèle utilisateur étendu avec :

```dart
class UserModel {
  final bool isSuperAdmin;  // Flag super admin

  // ... autres champs
}
```

### Collections Firestore

#### Collection `users`
```json
{
  "uid": "string",
  "email": "string",
  "displayName": "string",
  "userType": "admin",
  "adminRole": "superAdmin|admin|moderator|support|finance",
  "isSuperAdmin": true/false,
  "customPrivileges": ["privilege1", "privilege2"],
  "isActive": true/false,
  "createdAt": timestamp,
  "updatedAt": timestamp,
  "createdBy": "uid_of_creator"
}
```

#### Collection `platform_revenue`
```json
{
  "id": "auto_generated",
  "type": "commissionVente|commissionLivraison|abonnementVendeur|abonnementLivreur",
  "amount": 5000,
  "sourceId": "order_id|subscription_id",
  "userId": "uid",
  "userType": "vendeur|livreur",
  "description": "Commission 15% sur commande #123",
  "metadata": {
    "orderId": "...",
    "commissionRate": 0.15,
    "subscriptionTier": "BASIQUE"
  },
  "createdAt": timestamp,
  "month": 11,
  "year": 2025
}
```

#### Collection `financial_summary`
```json
{
  "id": "2025-11",
  "month": 11,
  "year": 2025,
  "commissionsVente": 150000,
  "commissionsLivraison": 75000,
  "abonnementsVendeurs": 50000,
  "abonnementsLivreurs": 30000,
  "total": 305000,
  "nbCommandesLivrees": 45,
  "nbLivraisons": 60,
  "nbAbonnementsVendeursActifs": 12,
  "nbAbonnementsLivreursActifs": 8,
  "vendeursParTier": {
    "basique": 5,
    "pro": 4,
    "premium": 3
  },
  "livreursParTier": {
    "starter": 3,
    "pro": 3,
    "premium": 2
  },
  "updatedAt": timestamp
}
```

## Sécurité et Règles Firestore

### Règles de Sécurité Recommandées

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Fonction helper pour vérifier si l'utilisateur est super admin
    function isSuperAdmin() {
      return request.auth != null
        && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isSuperAdmin == true;
    }

    // Fonction helper pour vérifier si l'utilisateur est admin
    function isAdmin() {
      return request.auth != null
        && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.userType == 'admin';
    }

    // Collection users (admins)
    match /users/{userId} {
      // Lecture : tous les admins
      allow read: if isAdmin();

      // Création/modification : super admin uniquement
      allow create, update: if isSuperAdmin();

      // Suppression : super admin uniquement (sauf lui-même)
      allow delete: if isSuperAdmin() && userId != request.auth.uid;
    }

    // Collection platform_revenue
    match /platform_revenue/{revenueId} {
      // Lecture : super admin uniquement
      allow read: if isSuperAdmin();

      // Écriture : système backend uniquement (via Admin SDK)
      allow write: if false;
    }

    // Collection financial_summary
    match /financial_summary/{summaryId} {
      // Lecture : super admin uniquement
      allow read: if isSuperAdmin();

      // Écriture : système backend uniquement
      allow write: if false;
    }
  }
}
```

## Guide d'Utilisation

### Pour le Super Administrateur

#### 1. Créer un Nouvel Administrateur

1. Accédez au **Dashboard**
2. Cliquez sur **"Gérer les Administrateurs"** dans les actions rapides
3. Cliquez sur le bouton **"+"** en haut à droite
4. Remplissez le formulaire :
   - Nom complet de l'admin
   - Email professionnel
   - Mot de passe initial (minimum 8 caractères)
   - Sélectionnez le rôle approprié
5. Cliquez sur **"Créer"**

**Note** : L'admin recevra ses identifiants et devra changer son mot de passe à la première connexion.

#### 2. Modifier un Administrateur

1. Dans la liste des administrateurs, recherchez l'admin
2. Cliquez sur son nom ou son email
3. Dans la boîte de dialogue :
   - Changez le rôle si nécessaire
   - Ajoutez des privilèges personnalisés si besoin
   - Suspendez le compte si nécessaire
4. Cliquez sur **"Enregistrer"**

#### 3. Suspendre un Administrateur

1. Trouvez l'admin dans la liste
2. Cliquez sur son profil
3. Désactivez le toggle **"Actif"**
4. Confirmez

**Effet** : L'admin ne pourra plus se connecter jusqu'à réactivation.

#### 4. Consulter les Finances

1. Cliquez sur l'onglet **"Finance"** dans la navigation
2. Sélectionnez la période à analyser
3. Consultez :
   - Les revenus totaux
   - Les commissions par type
   - Les transactions récentes
4. Rafraîchissez avec le bouton en haut à droite

### Pour les Administrateurs Standards

Les administrateurs non-super admin ont accès à :
- Dashboard (vue d'ensemble)
- Gestion des utilisateurs (selon privilèges)
- Statistiques globales
- Leur profil

Ils **n'ont PAS accès** à :
- La gestion financière
- La création d'autres admins
- Les paramètres système

## Flux de Travail Recommandé

### Création d'un Nouveau Super Admin (Rare)

1. **Accès Firebase Console** requis
2. Créer un utilisateur dans Authentication
3. Ajouter dans Firestore `/users/{uid}` :
   ```json
   {
     "userType": "admin",
     "adminRole": "superAdmin",
     "isSuperAdmin": true,
     "isActive": true,
     "createdAt": "now",
     "updatedAt": "now"
   }
   ```

### Création d'Administrateurs Réguliers

1. Le Super Admin utilise l'interface dédiée
2. Sélection du rôle approprié selon les besoins
3. L'admin reçoit ses accès
4. Première connexion : changement de mot de passe obligatoire

### Révocation d'Accès

1. Suspension immédiate via le toggle "Actif"
2. Si révocation définitive : suppression du compte
3. Les logs d'activité restent conservés

## Diagramme des Rôles et Privilèges

```
┌─────────────────────────────────────────────────────┐
│                  SUPER ADMIN                        │
│  ✓ Tous les privilèges (18)                        │
│  ✓ Gestion admins                                  │
│  ✓ Gestion finances                                │
│  ✓ Paramètres système                              │
└──────────────┬──────────────────────────────────────┘
               │
               ├───────────────────────────────────────┐
               │                                       │
      ┌────────▼────────┐                    ┌────────▼────────┐
      │      ADMIN      │                    │   MODERATOR     │
      │  12 privilèges  │                    │   6 privilèges  │
      │  ✓ Users        │                    │  ✓ View users   │
      │  ✓ Vendors      │                    │  ✓ View vendors │
      │  ✓ Delivery     │                    │  ✓ Products     │
      │  ✓ Products     │                    │  ✓ Reports      │
      │  ✓ Orders       │                    │  ✗ No orders    │
      │  ✓ Reports      │                    │  ✗ No finance   │
      │  ✗ No finance   │                    └─────────────────┘
      │  ✗ No admins    │
      └─────────────────┘
               │
               ├───────────────────────────────────────┐
               │                                       │
      ┌────────▼────────┐                    ┌────────▼────────┐
      │    SUPPORT      │                    │    FINANCE      │
      │   6 privilèges  │                    │   6 privilèges  │
      │  ✓ View only    │                    │  ✓ View users   │
      │  ✓ Users        │                    │  ✓ Subscriptions│
      │  ✓ Vendors      │                    │  ✓ Orders       │
      │  ✓ Delivery     │                    │  ✗ No finance   │
      │  ✓ Products     │                    │     (plateforme)│
      │  ✓ Orders       │                    └─────────────────┘
      │  ✗ No mods      │
      └─────────────────┘
```

## Maintenance et Évolution

### Ajouter un Nouveau Privilège

1. Ajouter l'enum dans `AdminPrivilege` (`admin_role_model.dart`)
2. Ajouter le privilège aux rôles concernés
3. Mettre à jour les règles Firestore
4. Tester les vérifications d'accès

### Ajouter un Nouveau Rôle

1. Ajouter l'enum dans `AdminRoleType`
2. Créer l'objet `AdminRole` avec ses privilèges
3. Ajouter dans `getAllRoles()`
4. Mettre à jour `getRole()` switch case
5. Tester la création et l'utilisation

### Audit et Logs

**Recommandation** : Implémenter un système de logs pour :
- Création/modification/suppression d'admins
- Accès aux données financières
- Modifications de privilèges
- Tentatives d'accès non autorisées

**Collection suggérée** : `admin_audit_logs`
```json
{
  "adminId": "uid",
  "action": "create_admin|view_finance|...",
  "targetId": "uid_of_target",
  "timestamp": "...",
  "metadata": {}
}
```

## FAQ

### Q : Peut-on avoir plusieurs Super Admins ?
**R** : Oui, mais il est recommandé d'en limiter le nombre (1-2 maximum) pour des raisons de sécurité.

### Q : Un admin peut-il changer son propre rôle ?
**R** : Non, seul un Super Admin peut modifier les rôles, et un admin ne peut pas se modifier lui-même.

### Q : Comment révoquer l'accès d'un admin immédiatement ?
**R** : Utilisez la fonction "Suspendre" qui désactive instantanément le compte sans le supprimer.

### Q : Les privilèges personnalisés sont-ils cumulatifs ?
**R** : Oui, les privilèges personnalisés s'ajoutent à ceux du rôle de base.

### Q : Peut-on créer un Super Admin via l'interface ?
**R** : Non, pour des raisons de sécurité. La création d'un Super Admin nécessite un accès direct à Firestore.

### Q : Comment un admin change son mot de passe ?
**R** : Via l'écran Profil, option "Changer le mot de passe".

### Q : Les données financières sont-elles visibles par les admins réguliers ?
**R** : Non, seul le Super Admin peut voir l'onglet Finance et les données de revenus de la plateforme.

## Conclusion

Ce système de gestion des administrateurs offre :
- ✅ Contrôle d'accès granulaire et sécurisé
- ✅ Séparation claire des responsabilités
- ✅ Interface intuitive de gestion
- ✅ Protection des données financières sensibles
- ✅ Évolutivité pour ajouter de nouveaux rôles/privilèges

Il permet au Super Admin de déléguer des tâches spécifiques tout en gardant le contrôle total sur les aspects critiques de la plateforme (finances, création d'admins, paramètres système).

---

**Document créé le** : 28 Novembre 2025
**Version** : 1.0
**Auteur** : Équipe SOCIAL BUSINESS Pro
