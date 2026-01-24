# Guide de Gestion Dynamique des Catégories de Produits

## Vue d'ensemble

Un système complet de gestion des catégories de produits a été implémenté. Les administrateurs peuvent maintenant gérer dynamiquement les catégories via une interface dédiée au lieu de modifier le code.

## Fichiers créés

### 1. Modèle de données
- **`lib/models/category_model.dart`**
  - Modèle `CategoryModel` pour Firestore
  - Classe `IconHelper` pour convertir les IconData
  - Champs: id, name, iconCodePoint, subCategories, isActive, displayOrder

### 2. Service
- **`lib/services/category_service.dart`**
  - CRUD complet pour les catégories
  - Méthodes: getActiveCategories(), createCategory(), updateCategory(), deleteCategory()
  - Gestion des sous-catégories
  - Réorganisation par glisser-déposer
  - Comptage des produits utilisant une catégorie

### 3. Interface Admin
- **`lib/screens/admin/categories_management_screen.dart`**
  - Écran de gestion avec liste ReorderableListView
  - Ajouter/modifier/supprimer des catégories
  - Ajouter/modifier/supprimer des sous-catégories
  - Activer/désactiver des catégories (soft delete)
  - Sélecteur d'icônes intégré
  - Stream temps réel (mise à jour automatique)

### 4. Script de Migration
- **`lib/scripts/migrate_categories_to_firestore.dart`**
  - Migrer les catégories de `product_categories.dart` vers Firestore
  - Vérifier l'état de la migration
  - Générer des rapports
  - Supprimer et réinitialiser

### 5. Route
- **Route ajoutée**: `/admin/categories-management`
- Protection: Réservée aux administrateurs

## Structure Firestore

```
product_categories/ (collection)
  ├── {categoryId}/
  │   ├── name: string
  │   ├── iconCodePoint: string (hex)
  │   ├── iconFontFamily: string
  │   ├── subCategories: array<string>
  │   ├── isActive: boolean
  │   ├── displayOrder: number
  │   ├── createdAt: timestamp
  │   └── updatedAt: timestamp
```

## Utilisation

### Pour l'administrateur

#### 1. Première utilisation - Migration des catégories

Avant d'utiliser le système, vous devez migrer les catégories existantes vers Firestore:

**Option A: Via l'interface (à implémenter)**
1. Allez sur `/admin/categories-management`
2. Cliquez sur "Importer catégories par défaut"
3. Confirmez l'import

**Option B: Via script (actuellement)**
```dart
import 'package:social_business_pro/lib/scripts/migrate_categories_to_firestore.dart';

// Vérifier l'état actuel
await CategoryMigrationScript.showReport();

// Migrer les catégories
await CategoryMigrationScript.migrateCategories();

// Forcer la migration (écrase les existantes)
await CategoryMigrationScript.migrateCategories(force: true);
```

#### 2. Gestion quotidienne

**Accéder à l'interface:**
- Menu admin → "Gestion des catégories"
- Ou directement: `/admin/categories-management`

**Ajouter une catégorie:**
1. Cliquez sur le bouton `+` dans l'AppBar
2. Entrez le nom
3. Choisissez une icône
4. Cliquez sur "Créer"

**Modifier une catégorie:**
1. Cliquez sur la catégorie pour l'agrandir
2. Cliquez sur "Modifier"
3. Modifiez le nom et/ou l'icône
4. Sauvegardez

**Ajouter une sous-catégorie:**
1. Agrandissez la catégorie
2. Cliquez sur "Ajouter sous-catégorie"
3. Entrez le nom
4. Validez

**Supprimer une sous-catégorie:**
1. Agrandissez la catégorie
2. Cliquez sur la croix (X) sur le chip de la sous-catégorie
3. Confirmez

**Réorganiser l'ordre:**
1. Maintenez appuyé sur l'icône "drag" (≡)
2. Glissez-déposez à la position souhaitée
3. L'ordre est sauvegardé automatiquement

**Désactiver une catégorie:**
1. Agrandissez la catégorie
2. Cliquez sur "Désactiver"
3. La catégorie reste visible mais n'apparaîtra plus pour les vendeurs

**Supprimer définitivement:**
1. Agrandissez la catégorie
2. Cliquez sur "Supprimer"
3. Si des produits utilisent cette catégorie, un avertissement s'affiche
4. Confirmez la suppression

**Afficher les catégories inactives:**
- Cliquez sur l'icône œil dans l'AppBar pour basculer

### Pour le développeur

#### Charger les catégories dans votre code

**Méthode 1: Future (chargement unique)**
```dart
final categories = await CategoryService.getActiveCategories();

// Utiliser les catégories
for (var category in categories) {
  print('${category.name}: ${category.subCategories.length} sous-catégories');
}
```

**Méthode 2: Stream (mise à jour temps réel)**
```dart
StreamBuilder<List<CategoryModel>>(
  stream: CategoryService.watchActiveCategories(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return CircularProgressIndicator();

    final categories = snapshot.data!;

    return DropdownButton(
      items: categories.map((cat) {
        return DropdownMenuItem(
          value: cat.id,
          child: Row(
            children: [
              Icon(cat.icon),
              SizedBox(width: 8),
              Text(cat.name),
            ],
          ),
        );
      }).toList(),
    );
  },
)
```

#### Obtenir une catégorie spécifique
```dart
final category = await CategoryService.getCategoryById('mode');
if (category != null) {
  print('Catégorie: ${category.name}');
  print('Sous-catégories: ${category.subCategories.join(', ')}');
}
```

## Migration des écrans existants

### add_product.dart et edit_product.dart

**IMPORTANT**: Ces fichiers doivent être mis à jour pour utiliser CategoryService au lieu de ProductCategories.allCategories.

**Changements nécessaires:**

```dart
// AVANT (ancien système)
final categories = ProductCategories.allCategories;

// APRÈS (nouveau système)
// Ajouter dans le State
List<CategoryModel> _categories = [];
bool _isLoadingCategories = true;

// Dans initState
@override
void initState() {
  super.initState();
  _loadCategories();
}

Future<void> _loadCategories() async {
  try {
    final categories = await CategoryService.getActiveCategories();
    setState(() {
      _categories = categories;
      _isLoadingCategories = false;
    });
  } catch (e) {
    debugPrint('❌ Erreur chargement catégories: $e');
    // Fallback vers les catégories statiques si Firestore échoue
    setState(() {
      _categories = ProductCategories.allCategories
          .map((pc) => CategoryModel(
                id: pc.id,
                name: pc.name,
                iconCodePoint: IconHelper.iconToCodePoint(pc.icon),
                subCategories: pc.subCategories ?? [],
                createdAt: DateTime.now(),
              ))
          .toList();
      _isLoadingCategories = false;
    });
  }
}

// Dans le DropdownButton
if (_isLoadingCategories)
  CircularProgressIndicator()
else
  DropdownButton<String>(
    items: _categories
        .where((category) => _allowedCategories.contains(category.name))
        .map((category) {
      return DropdownMenuItem<String>(
        value: category.id,
        child: Row(
          children: [
            Icon(category.icon),
            SizedBox(width: 12),
            Text(category.name),
          ],
        ),
      );
    }).toList(),
  )
```

## Sécurité

### Règles Firestore recommandées

```javascript
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Catégories de produits
    match /product_categories/{categoryId} {
      // Tout le monde peut lire les catégories actives
      allow read: if resource.data.isActive == true;

      // Seuls les admins peuvent écrire
      allow write: if request.auth != null &&
                   get(/databases/$(database)/documents/users/$(request.auth.uid)).data.userType == 'admin';
    }
  }
}
```

### Index Firestore recommandés

```json
{
  "indexes": [
    {
      "collectionGroup": "product_categories",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "isActive", "order": "ASCENDING" },
        { "fieldPath": "displayOrder", "order": "ASCENDING" },
        { "fieldPath": "name", "order": "ASCENDING" }
      ]
    }
  ]
}
```

## Tests recommandés

### 1. Test de migration
```dart
// Vérifier que toutes les catégories sont migrées
await CategoryMigrationScript.showReport();
```

### 2. Test de création
```dart
final categoryId = await CategoryService.createCategory(
  name: 'Test',
  icon: Icons.category,
);
assert(categoryId.isNotEmpty);
```

### 3. Test de lecture
```dart
final categories = await CategoryService.getActiveCategories();
assert(categories.isNotEmpty);
```

### 4. Test de mise à jour
```dart
await CategoryService.updateCategory(
  id: 'test',
  name: 'Test Updated',
);
```

## Problèmes connus et solutions

### Problème: "Aucune catégorie disponible"
**Solution**: Exécutez le script de migration pour peupler Firestore

### Problème: "Les catégories ne s'affichent pas dans add_product"
**Solution**: Mettez à jour add_product.dart pour utiliser CategoryService

### Problème: "Timeout lors du chargement"
**Solution**: Vérifiez votre connexion internet et les règles Firestore

## Prochaines étapes

1. ✅ Créer le modèle CategoryModel
2. ✅ Créer le service CategoryService
3. ✅ Créer l'interface admin
4. ✅ Créer le script de migration
5. ✅ Ajouter la route
6. ⏳ Ajouter un bouton d'import dans l'interface admin
7. ⏳ Migrer add_product.dart
8. ⏳ Migrer edit_product.dart
9. ⏳ Migrer category_products_screen.dart
10. ⏳ Tester l'ensemble du système
11. ⏳ Déployer les règles Firestore
12. ⏳ Déployer les index Firestore
13. ⏳ Exécuter la migration en production

## Support

En cas de problème:
1. Vérifiez les logs de debug
2. Consultez le script de rapport: `CategoryMigrationScript.showReport()`
3. Vérifiez les règles Firestore
4. Contactez l'équipe technique
