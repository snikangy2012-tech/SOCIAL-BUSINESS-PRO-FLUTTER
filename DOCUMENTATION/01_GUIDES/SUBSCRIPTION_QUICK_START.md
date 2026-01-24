# 🚀 QUICK START - Système d'Abonnements

Guide rapide pour tester le système d'abonnements SOCIAL BUSINESS Pro.

## ✅ Fichiers créés

```
✅ lib/models/subscription_model.dart
✅ lib/services/subscription_service.dart
✅ lib/providers/subscription_provider.dart
✅ lib/screens/subscription/subscription_plans_screen.dart
✅ lib/screens/subscription/subscription_subscribe_screen.dart
✅ lib/screens/subscription/subscription_dashboard_screen.dart
✅ lib/screens/subscription/limit_reached_screen.dart
✅ lib/utils/subscription_test_helper.dart
✅ lib/routes/app_router.dart (modifié - routes ajoutées)
✅ lib/main.dart (modifié - provider ajouté)
```

## 📱 Routes disponibles

```dart
// Plans et tarifs
/subscription/plans

// Souscrire à un plan (nécessite VendeurSubscriptionTier en extra)
/subscription/subscribe

// Tableau de bord Mon Abonnement
/subscription/dashboard

// Alerte limite atteinte (optionnel: 'products' ou 'ai_messages' en extra)
/subscription/limit-reached
```

## 🧪 Tester immédiatement

### Option 1: Créer des données de test

Dans n'importe quel écran de l'app (en mode debug) :

```dart
import 'package:social_business_pro/utils/subscription_test_helper.dart';

// Bouton ou initState
final testHelper = SubscriptionTestHelper();
await testHelper.createAllTestData();
```

Cela crée 6 utilisateurs de test dans Firestore :
- `test_vendeur_basique`
- `test_vendeur_pro`
- `test_vendeur_premium`
- `test_livreur_starter`
- `test_livreur_pro`
- `test_livreur_premium`

### Option 2: Naviguer directement

Depuis le dashboard vendeur, ajoutez un bouton temporaire :

```dart
ElevatedButton(
  onPressed: () {
    context.push('/subscription/plans');
  },
  child: const Text('Voir les plans'),
)
```

### Option 3: Utiliser les tests automatiques

```dart
import 'package:social_business_pro/utils/subscription_test_helper.dart';

// Lance TOUS les tests (création + flux complets)
final testHelper = SubscriptionTestHelper();
await testHelper.runAllTests();

// Check la console pour voir les résultats détaillés
```

## 📊 Vérifier dans Firebase Console

Après avoir créé les données de test :

1. Ouvrir [Firebase Console](https://console.firebase.google.com/)
2. Sélectionner votre projet
3. Aller dans **Firestore Database**
4. Vérifier les collections :
   - `subscriptions` → 3 documents (BASIQUE, PRO, PREMIUM)
   - `livreur_tiers` → 3 documents (STARTER, PRO, PREMIUM)
   - `subscription_payments` → Plusieurs paiements de test

## 🎨 Personnaliser les écrans

### Changer les couleurs des plans

Dans `subscription_plans_screen.dart` :

```dart
_buildPlanCard(
  tier: VendeurSubscriptionTier.pro,
  color: AppColors.primary, // <-- Changer ici
  // ...
)
```

### Modifier les prix

Dans `subscription_service.dart`, méthode `_createSubscriptionForTier()` :

```dart
case VendeurSubscriptionTier.pro:
  return VendeurSubscription(
    monthlyPrice: 5000, // <-- Modifier ici
    // ...
  );
```

### Ajuster les limites

Dans le même fichier :

```dart
case VendeurSubscriptionTier.pro:
  return VendeurSubscription(
    productLimit: 100, // <-- Modifier ici
    // ...
  );
```

## 🔗 Intégrer dans l'UI existante

### Ajouter un lien dans le dashboard vendeur

Dans `vendeur_main_screen.dart` ou équivalent :

```dart
ListTile(
  leading: const Icon(Icons.workspace_premium),
  title: const Text('Mon abonnement'),
  trailing: const Icon(Icons.chevron_right),
  onTap: () {
    context.push('/subscription/dashboard');
  },
)
```

### Ajouter un badge du plan actuel

```dart
Consumer<SubscriptionProvider>(
  builder: (context, subscriptionProvider, _) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        subscriptionProvider.currentTierName,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  },
)
```

### Vérifier la limite avant d'ajouter un produit

Dans `add_product.dart` ou équivalent :

```dart
Future<void> _saveProduct() async {
  final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
  final authProvider = Provider.of<AuthProvider>(context, listen: false);

  // Compter les produits actuels du vendeur
  final currentCount = await _countVendeurProducts(authProvider.user!.id);

  // Vérifier la limite
  final canAdd = await subscriptionProvider.canAddProduct(
    authProvider.user!.id,
    currentCount,
  );

  if (!canAdd) {
    // Rediriger vers écran limite
    if (mounted) {
      context.push('/subscription/limit-reached', extra: 'products');
    }
    return;
  }

  // Continuer la sauvegarde
  // ...
}
```

## 🛠️ Commandes utiles

### Afficher un abonnement dans la console

```dart
final testHelper = SubscriptionTestHelper();
await testHelper.displayVendeurSubscription('test_vendeur_pro');
```

Sortie console :
```
📊 ========== ABONNEMENT VENDEUR ==========
📊 Vendeur ID: test_vendeur_pro

✅ PLAN: PRO
   💰 Prix: 5000 FCFA/mois
   📦 Limite produits: 100
   💳 Commission: 10%
   🤖 Agent AI: ✅ gpt-3.5-turbo (50 msgs/jour)
   📊 Statut: ACTIVE
```

### Tester le flux complet vendeur

```dart
await testHelper.testVendeurFlow();
```

Exécute automatiquement :
1. Création BASIQUE
2. Upgrade PRO
3. Upgrade PREMIUM
4. Vérification limites
5. Test commission
6. Downgrade BASIQUE

### Nettoyer les données de test

```dart
await testHelper.cleanAllTestData();
```

## 🐛 Debugging

### Provider non trouvé ?

Vérifier que `SubscriptionProvider` est bien dans `main.dart` :

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthProvider()),
    ChangeNotifierProvider(create: (_) => SubscriptionProvider()), // ← Vérifier
    // ...
  ],
)
```

### Routes non reconnues ?

Vérifier que les imports sont présents dans `app_router.dart` :

```dart
import '../screens/subscription/subscription_plans_screen.dart';
import '../screens/subscription/subscription_subscribe_screen.dart';
import '../screens/subscription/subscription_dashboard_screen.dart';
import '../screens/subscription/limit_reached_screen.dart';
import '../models/subscription_model.dart';
```

### Erreur Firestore ?

Vérifier que les règles Firestore permettent l'accès :

```javascript
// Temporaire pour le développement
match /{document=**} {
  allow read, write: if request.auth != null;
}
```

⚠️ **À remplacer par des règles sécurisées en production !**

## 📚 Documentation complète

Voir [SUBSCRIPTION_SYSTEM.md](./SUBSCRIPTION_SYSTEM.md) pour :
- Architecture détaillée
- Tous les modèles de données
- API complète
- Collections Firestore
- Cas d'usage avancés

## ✨ Prochaines étapes

1. **Tester en local**
   ```bash
   flutter run -d chrome
   ```

2. **Créer des données de test**
   ```dart
   SubscriptionTestHelper().createAllTestData()
   ```

3. **Naviguer vers les écrans**
   - Plans : `/subscription/plans`
   - Dashboard : `/subscription/dashboard`

4. **Intégrer dans l'UI existante**
   - Ajouter liens dans le menu vendeur
   - Ajouter vérification limites
   - Afficher badge du plan

5. **Déployer sur Firebase**
   ```bash
   flutter build web --release
   firebase deploy --only hosting
   ```

---

**Besoin d'aide ?**
- 📖 Lire [SUBSCRIPTION_SYSTEM.md](./SUBSCRIPTION_SYSTEM.md)
- 📧 Contact: dev@socialbusiness.ci

**Version:** 1.0.0
**Date:** Décembre 2024
