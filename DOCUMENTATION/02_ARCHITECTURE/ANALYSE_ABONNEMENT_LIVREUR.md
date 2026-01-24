# Analyse: Problème Abonnement Livreur

## Problème Signalé
"Lorsque je suis connecté en livreur, l'abonnement qui apparaît est celui du vendeur qui affiche BASIQUE au lieu de STARTER"

## Cause Racine
Le fichier `subscription_dashboard_screen.dart` est conçu UNIQUEMENT pour les vendeurs:
- Ligne 31: Charge toujours `loadVendeurSubscription()`
- Ligne 40: Utilise toujours `vendeurSubscription`
- Lignes 135-756: Toutes les méthodes utilisent `VendeurSubscription` et `VendeurSubscriptionTier`

## Solutions Possibles

### Option 1: Créer deux écrans séparés ✅ RECOMMANDÉ
- `VendeurSubscriptionDashboardScreen` (actuel)
- `LivreurSubscriptionDashboardScreen` (nouveau)
- Avantages: Code propre, maintenable
- Inconvénients: Duplication

### Option 2: Écran adaptatif avec dynamic ❌ COMPLEXE
- Utiliser `dynamic` pour accepter les deux types
- Avantages: Un seul fichier
- Inconvénients: Perte du type safety, complexe

### Option 3: Interface commune ❌ REFACTORING MASSIF
- Créer une interface `Subscription`
- Faire hériter les deux modèles
- Avantages: Type safe
- Inconvénients: Refactoring massif

## Solution Choisie: Option 1

Créer un nouveau fichier `livreur_subscription_dashboard_screen.dart` et modifier les routes:
- Route `/vendeur/subscription` → `VendeurSubscriptionDashboardScreen`
- Route `/livreur/subscription` → `LivreurSubscriptionDashboardScreen`

## Implémentation

### Étape 1: Créer livreur_subscription_dashboard_screen.dart
Adapter le code actuel pour:
- Utiliser `LivreurSubscription` au lieu de `VendeurSubscription`
- Utiliser `LivreurTier` au lieu de `VendeurSubscriptionTier`
- Afficher les métriques livreur (livraisons, note, priorité) au lieu de vendeur (produits, ventes)
- Plans: STARTER (gratuit), PRO (10k FCFA), PREMIUM (30k FCFA)

### Étape 2: Mettre à jour app_router.dart
```dart
// Vendeur
GoRoute(path: '/vendeur/subscription', builder: (context, state) => const VendeurSubscriptionDashboardScreen()),

// Livreur
GoRoute(path: '/livreur/subscription', builder: (context, state) => const LivreurSubscriptionDashboardScreen()),
```

### Étape 3: Renommer subscription_dashboard_screen.dart
Renommer en `vendeur_subscription_dashboard_screen.dart` pour clarté

## Différences Livreur vs Vendeur

### Vendeur
- Plans: BASIQUE (gratuit), PRO (5k), PREMIUM (10k)
- Limite produits: 20, 100, illimité
- Commission: 10%, 8%, 7%
- Agent AI: Non, GPT-3.5 (50/j), GPT-4 (200/j)

### Livreur
- Plans: STARTER (gratuit), PRO (10k), PREMIUM (30k)
- Commission: 25%, 20%, 15%
- Priorité livraisons: Non, Oui, Oui++
- Support: Email, Chat, 24/7
- Critères déblocage: 0 livraisons, 50 livraisons (4.0★), 200 livraisons (4.5★)
