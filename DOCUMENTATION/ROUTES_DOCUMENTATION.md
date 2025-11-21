# 📍 Documentation des Routes - SOCIAL BUSINESS Pro

## ✅ Routes Corrigées et Ajoutées

### 🛒 ACHETEUR

| Route | Nom | Écran | Statut |
|-------|-----|-------|--------|
| `/acheteur-home` | Accueil Acheteur | MainScaffold | ✅ OK |
| `/acheteur/cart` | Mon panier | CartScreen | ✅ AJOUTÉ |
| `/acheteur/checkout` | Finaliser commande | CheckoutScreen | ✅ OK |
| `/acheteur/orders` | Mes commandes | OrderHistoryScreen | ✅ AJOUTÉ |
| `/acheteur/profile` | Mon profil | AcheteurProfileScreen | ✅ AJOUTÉ |
| `/acheteur/business-pro` | Business Pro | BusinessProScreen | ✅ AJOUTÉ |
| `/acheteur/addresses` | Mes adresses | TempScreen | ⚠️ À créer |
| `/cart` | Panier (legacy) | CartScreen | ✅ OK |
| `/checkout` | Checkout (legacy) | CheckoutScreen | ✅ OK |
| `/profile` | Profil (legacy) | AcheteurProfileScreen | ✅ OK |
| `/favorites` | Favoris | FavoriteScreen | ✅ OK |
| `/product/:id` | Détail produit | ProductDetailScreen | ✅ OK |

### 🏪 VENDEUR

| Route | Nom | Écran | Statut |
|-------|-----|-------|--------|
| `/vendeur-dashboard` | Dashboard Vendeur | VendeurMainScreen | ✅ OK |
| `/vendeur/add-product` | Ajouter produit | AddProduct | ✅ OK |
| `/vendeur/edit-product/:id` | Modifier produit | EditProduct | ✅ OK |
| `/vendeur/order-detail/:id` | Détail commande | OrderDetail | ✅ OK |
| `/vendeur/order-management/:id` | Gestion commandes | OrderManagement | ✅ OK |
| `/vendeur/product-management/:id` | Gestion produits | ProductManagement | ✅ OK |
| `/vendeur/vendeur-profile` | Profil vendeur | VendeurProfile | ✅ OK |
| `/vendeur/vendeur-statistics` | Statistiques | Statistics | ✅ OK |

### 🚚 LIVREUR

| Route | Nom | Écran | Statut |
|-------|-----|-------|--------|
| `/livreur-dashboard` | Dashboard Livreur | LivreurMainScreen | ✅ OK |
| `/livreur/deliveries` | Mes livraisons | DeliveryListScreen | ✅ AJOUTÉ |
| `/livreur/delivery/:id` | Détail livraison | TempScreen | ⚠️ À créer |

### 👨‍💼 ADMIN

| Route | Nom | Écran | Statut |
|-------|-----|-------|--------|
| `/admin-dashboard` | Dashboard Admin | AdminDashboard | ✅ OK |
| `/admin/users` | Gestion utilisateurs | UserManagementScreen | ✅ AJOUTÉ |
| `/admin/vendors` | Gestion vendeurs | TempScreen | ⚠️ À créer |
| `/admin/livreurs` | Gestion livreurs | TempScreen | ⚠️ À créer |

### 🔐 AUTHENTIFICATION

| Route | Nom | Écran | Statut |
|-------|-----|-------|--------|
| `/` | Accueil | MainScaffold | ✅ OK |
| `/login` | Connexion | LoginScreenExtended | ✅ OK |
| `/register` | Inscription | RegisterScreenExtended | ✅ OK |
| `/forgot-password` | Mot de passe oublié | TempScreen | ⚠️ À créer |

### 📱 COMMUN

| Route | Nom | Écran | Statut |
|-------|-----|-------|--------|
| `/notifications` | Notifications | NotificationsScreen | ✅ OK |
| `/settings` | Paramètres | TempScreen | ⚠️ À créer |
| `/help` | Aide & Support | TempScreen | ⚠️ À créer |

---

## 🔧 Corrections Effectuées

### 1. **Routes Acheteur manquantes** ✅
- Ajouté `/acheteur/orders` pour l'historique des commandes
- Ajouté `/acheteur/profile` pour le profil
- Ajouté `/acheteur/business-pro` pour Business Pro
- Ajouté `/acheteur/cart` pour le panier
- Ajouté `/acheteur/addresses` (temporaire)

### 2. **Routes Livreur manquantes** ✅
- Ajouté `/livreur/deliveries` pour la liste des livraisons
- Ajouté `/livreur/delivery/:id` pour le détail (temporaire)

### 3. **Routes Admin manquantes** ✅
- Ajouté `/admin/users` pour la gestion des utilisateurs

### 4. **Routes Legacy** ✅
Pour assurer la compatibilité avec le code existant :
- `/cart` → redirige vers CartScreen
- `/checkout` → redirige vers CheckoutScreen
- `/profile` → redirige vers AcheteurProfileScreen

---

## 🎯 Navigation dans les Écrans

### Depuis le Profil Acheteur (AcheteurProfileScreen)

```dart
// Mes commandes
context.push('/acheteur/orders');

// Mes adresses
context.push('/acheteur/addresses');

// Favoris
context.push('/favorites');

// Notifications
context.push('/notifications');

// Business Pro
context.push('/acheteur/business-pro');
```

### Depuis le Dashboard Livreur

```dart
// Voir mes livraisons
context.push('/livreur/deliveries');

// Voir détail d'une livraison
context.push('/livreur/delivery/$deliveryId');
```

### Depuis le Dashboard Admin

```dart
// Gestion des utilisateurs
context.push('/admin/users');

// Gestion des vendeurs (à créer)
context.push('/admin/vendors');

// Gestion des livreurs (à créer)
context.push('/admin/livreurs');
```

---

## ⚠️ Écrans à Créer

### Priorité HAUTE
1. **Détail de Livraison** (`/livreur/delivery/:id`)
   - Afficher les détails complets d'une livraison
   - Navigation GPS
   - Actions (récupérer, livrer, annuler)

2. **Gestion Vendeurs Admin** (`/admin/vendors`)
   - Validation des nouveaux vendeurs
   - Statistiques par vendeur
   - Gestion des produits

3. **Gestion Livreurs Admin** (`/admin/livreurs`)
   - Validation des nouveaux livreurs
   - Statistiques de livraison
   - Gestion des véhicules

### Priorité MOYENNE
4. **Adresses de Livraison** (`/acheteur/addresses`)
   - CRUD adresses
   - Définir adresse par défaut

5. **Mot de Passe Oublié** (`/forgot-password`)
   - Réinitialisation par email/SMS

6. **Paramètres** (`/settings`)
   - Préférences de notifications
   - Langue
   - Thème

7. **Aide & Support** (`/help`)
   - FAQ
   - Contact support
   - Tutoriels

---

## 🔒 Protection des Routes

Les routes sont protégées selon le type d'utilisateur :

```dart
// Règles de redirection
- Non connecté → /login
- Admin → /admin-dashboard
- Acheteur → /acheteur-home
- Vendeur → /vendeur-dashboard
- Livreur → /livreur-dashboard

// Vérifications d'accès
- Routes /vendeur/* → Vendeur uniquement
- Routes /admin/* → Admin uniquement
- Routes /livreur/* → Livreur uniquement
- Routes /acheteur/* → Acheteur uniquement
```

---

## 📝 Notes pour le Développement

### Différences entre Profil et Business Pro
- **Profil Acheteur** (`/acheteur/profile`) :
  - Informations personnelles
  - Historique commandes
  - Adresses
  - Paramètres basiques

- **Business Pro** (`/acheteur/business-pro`) :
  - Fonctionnalités professionnelles
  - Achats en gros
  - Factures
  - Statistiques d'achat

### Nommage des Routes
- Utiliser des chemins explicites : `/acheteur/orders` plutôt que `/orders`
- Préfixer par rôle pour éviter les conflits
- Garder des routes legacy pour compatibilité
- Utiliser des paramètres pour les IDs : `:id`, `:productId`, etc.

---

**Dernière mise à jour** : $(date)
**Version** : 1.0.0
