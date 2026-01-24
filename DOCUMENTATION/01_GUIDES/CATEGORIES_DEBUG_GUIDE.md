# Guide de Gestion des Catégories Vendeur (Administrateur uniquement)

## Politique de Gestion

**IMPORTANT**: La gestion des catégories vendeur est **strictement réservée aux administrateurs**. Les vendeurs ne peuvent pas modifier leurs catégories eux-mêmes.

## Problème

Certains vendeurs peuvent avoir d'anciennes catégories (comme "mode et vêtements") qui n'existent plus dans la liste actuelle des catégories. Ces catégories invalides peuvent causer des problèmes d'affichage et de filtrage.

## Catégories Valides Actuelles

1. **Mode & Style**
2. **Électronique**
3. **Électroménager**
4. **Cuisine & Ustensiles**
5. **Meubles & Déco**
6. **Alimentaire**
7. **Maison & Jardin**
8. **Beauté & Soins**
9. **Sport & Loisirs**
10. **Auto & Moto**
11. **Services**

## Gestion des Catégories (Administrateur uniquement)

### Interface d'Administration

**Accès**: `/admin/debug-categories` (réservé aux comptes admin)

**Fonctionnalités disponibles**:

1. **Vérifier tous les vendeurs**
   - Affiche la liste de tous les vendeurs avec des catégories invalides
   - Montre les catégories problématiques pour chaque vendeur

2. **Nettoyer en masse**
   - Pour chaque vendeur problématique, un bouton permet de nettoyer ses catégories
   - Le système va:
     - Identifier les catégories invalides
     - Garder uniquement les catégories valides
     - Si aucune catégorie valide, définir "Alimentaire" par défaut

3. **Attribuer des catégories**
   - Permet de définir manuellement les catégories pour un vendeur

## Côté Vendeur

Les vendeurs peuvent **uniquement visualiser** leurs catégories dans:
- **Profil vendeur** (`/vendeur-profile`) - Affichage en lecture seule avec message "Les catégories sont gérées par l'administrateur"
- **Configuration de la boutique** (`/shop-setup`) - Les catégories existantes sont affichées mais non modifiables

**Note**: Les vendeurs doivent contacter l'administrateur pour demander des modifications de catégories.

## Scripts Disponibles (Administrateur)

### Script Dart (Intégré à l'App)

Fichier: `lib/scripts/clean_vendor_categories.dart`

Fonctions disponibles:
```dart
// Nettoyer les catégories d'un vendeur spécifique
await cleanVendorCategories(userId);

// Vérifier tous les vendeurs
await checkAllVendorsCategories();

// Afficher les catégories disponibles
printAvailableCategories();
```

### Script Node.js (Standalone)

Fichier: `clean_categories.js`

**Prérequis:**
```bash
npm install firebase-admin
```

**Configuration:**
1. Téléchargez le fichier service account JSON depuis Firebase Console
2. Définissez la variable d'environnement:
   ```bash
   set GOOGLE_APPLICATION_CREDENTIALS=path/to/serviceAccountKey.json
   ```

**Utilisation:**
```bash
node clean_categories.js <userId>
```

**Exemple:**
```bash
node clean_categories.js ABC123XYZ
```

## Structure Firestore

Les catégories sont stockées dans:
```
users/{userId}/
  profile/
    vendeurProfile/
      businessCategories: ["Mode & Style", "Électronique", ...]
```

## Migration Automatique

Le modèle `VendeurProfile` inclut une migration automatique:
- Lit le champ `businessCategories` (nouveau format - liste)
- Si vide, tente de lire `businessCategory` (ancien format - string unique)
- Si les deux sont vides, utilise `['Alimentaire']` par défaut

## Logs de Debug

Tous les scripts affichent des logs détaillés:
- 🔍 Vérification en cours
- 📋 Catégories actuelles
- ⚠️  Catégories invalides détectées
- ✅ Catégories valides
- 🧹 Nettoyage en cours
- ✅ Nettoyage réussi
- ❌ Erreurs

## Exemple de Sortie

```
🔍 Vérification du profil vendeur pour l'utilisateur: ABC123

📋 Profil vendeur actuel:
   Nom de la boutique: Ma Boutique
   Catégories actuelles: ["mode et vêtements", "électronique"]

⚠️  Catégories invalides détectées: ["mode et vêtements"]
✅ Catégories valides: ["électronique"]

🧹 Nettoyage des catégories...
   Nouvelles catégories: ["électronique"]

✅ Catégories nettoyées avec succès!
```

## Prévention Future

Pour éviter ce problème à l'avenir:

1. **Gestion centralisée** - Seuls les administrateurs peuvent modifier les catégories vendeur
2. **Affichage read-only** - Les vendeurs voient leurs catégories mais ne peuvent pas les modifier
3. **Migration automatique** dans `VendeurProfile.fromMap()` - filtre les catégories invalides à la lecture
4. **Écran de debug admin** - permet de détecter et corriger rapidement les problèmes

## Support

En cas de problème:
1. Vérifiez les logs de debug
2. Vérifiez que Firebase est correctement configuré
3. Assurez-vous que l'utilisateur a un profil vendeur
4. Utilisez l'interface `/admin/debug-categories` pour diagnostiquer
5. Contactez l'équipe technique avec l'userId et les logs si nécessaire
