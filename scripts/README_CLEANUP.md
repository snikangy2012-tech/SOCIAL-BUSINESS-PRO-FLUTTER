# Script de nettoyage des catégories obsolètes

## Description

Ce script identifie et corrige les produits ayant des catégories qui n'existent plus dans la collection Firestore `categories`.

## Problèmes détectés

Le script détecte trois types de problèmes :

1. **NO_CATEGORY** : Produit sans catégorie définie
2. **CATEGORY_IS_NAME** : Produit avec un nom de catégorie au lieu d'un ID (ex: "Mode & vêtement" au lieu de "mode")
3. **INVALID_CATEGORY** : Produit avec un ID de catégorie qui n'existe pas

## Prérequis

1. Node.js installé (version 14+)
2. Clé de service Firebase (`serviceAccountKey.json`)
3. Package `firebase-admin` installé

### Installation des dépendances

```bash
npm install firebase-admin
```

### Configuration de la clé de service

1. Aller sur Firebase Console → Paramètres du projet → Comptes de service
2. Cliquer sur "Générer une nouvelle clé privée"
3. Télécharger le fichier JSON
4. Renommer en `serviceAccountKey.json`
5. Placer à la racine du projet

## Utilisation

### 1. Mode analyse (DRY RUN)

Affiche les produits problématiques sans les modifier :

```bash
node scripts/cleanup_obsolete_categories.js --dry-run
```

### 2. Mode correction automatique (DRY RUN)

Simule la correction sans appliquer les changements :

```bash
node scripts/cleanup_obsolete_categories.js --dry-run --auto-fix
```

### 3. Mode correction en production

**⚠️ ATTENTION : Modifie réellement les données !**

```bash
node scripts/cleanup_obsolete_categories.js --auto-fix
```

## Logique de correction

### Pour CATEGORY_IS_NAME

Si le produit a "Mode & vêtement" comme catégorie et qu'une catégorie active existe avec ce nom, le script :
- Trouve l'ID correspondant (ex: "mode")
- Met à jour le produit avec l'ID correct

### Pour INVALID_CATEGORY ou NO_CATEGORY

Le script assigne la première catégorie active disponible comme catégorie par défaut.

## Exemple de sortie

```
🚀 Démarrage du script de nettoyage des catégories obsolètes...
Mode: DRY RUN (simulation)
Auto-fix: OUI

📋 Récupération des catégories valides...
✅ 8 catégories valides trouvées:

   - mode: Mode & Vêtements
   - electronique: Électronique
   - alimentation: Alimentation
   ...

🔍 Recherche des produits avec catégories obsolètes...

📊 Résumé de l'analyse:
   - Produits valides: 45
   - Produits avec problèmes: 3

🔧 Correction des produits avec catégories obsolètes...

   Produit: T-shirt vintage (abc123)
   Problème: CATEGORY_IS_NAME
   Valeur actuelle: Mode & vêtement
   ✅ Correction: "Mode & vêtement" → mode

ℹ️  Mode DRY RUN: 3 produits seraient mis à jour

📄 RAPPORT DÉTAILLÉ
============================================================

CATEGORY_IS_NAME (3 produits):
  - T-shirt vintage (abc123)
    Catégorie: Mode & vêtement
    Vendeur: vendor001
  ...

============================================================

✅ Script terminé avec succès!
```

## Recommandations

1. **Toujours faire un DRY RUN d'abord** pour voir les changements prévus
2. **Faire une sauvegarde Firestore** avant d'exécuter en mode production
3. **Vérifier manuellement** les produits après correction
4. **Informer les vendeurs** si leurs produits sont modifiés

## Sauvegarde Firestore

Avant d'exécuter le script en production :

```bash
# Exporter toute la base de données
gcloud firestore export gs://[BUCKET_NAME]/[EXPORT_FOLDER]

# Ou via Firebase CLI
firebase firestore:delete --all-collections --project social-media-business-pro
```

## Support

En cas de problème, contacter l'administrateur système avec :
- Le log complet du script
- La liste des produits affectés
- Le mode d'exécution utilisé
