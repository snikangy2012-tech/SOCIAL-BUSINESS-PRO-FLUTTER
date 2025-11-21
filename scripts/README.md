# Scripts de Migration Firestore

Ce dossier contient des scripts pour migrer les données Firestore de votre projet **SOCIAL BUSINESS Pro**.

## 🎯 Problème Résolu

Le script `migrate_user_dates.js` corrige l'erreur suivante qui empêchait la connexion des utilisateurs :

```
❌ Erreur: type 'String' is not a subtype of type 'Timestamp?' in type cast
❌ NoSuchMethodError: Class 'String' has no instance method 'toDate'
```

**Cause** : Les dates (`createdAt`, `updatedAt`, `lastLoginAt`) étaient stockées en String au lieu de Timestamp dans Firestore.

**Solution** : Le script convertit automatiquement toutes les dates String en Timestamp.

---

## 📋 Prérequis

1. **Node.js** : Assurez-vous d'avoir Node.js installé (https://nodejs.org)
   - Vérifiez avec : `node --version`

2. **Clé de Service Firebase** : Vous devez télécharger la clé de service de votre projet Firebase

---

## 🔑 Étape 1 : Télécharger la Clé de Service Firebase

1. Allez sur https://console.firebase.google.com
2. Sélectionnez votre projet `social-media-business-pro`
3. Cliquez sur l'icône ⚙️ (Paramètres) à côté de "Vue d'ensemble du projet"
4. Allez dans **Paramètres du projet**
5. Allez dans l'onglet **Comptes de service**
6. Cliquez sur **Générer une nouvelle clé privée**
7. Un fichier JSON sera téléchargé
8. **IMPORTANT** : Renommez ce fichier en `serviceAccountKey.json`
9. Placez-le dans ce dossier `scripts/`

**⚠️ ATTENTION** : Ne partagez JAMAIS ce fichier ! Il donne un accès complet à votre base de données.

---

## 📦 Étape 2 : Installer les Dépendances

Ouvrez un terminal PowerShell ou CMD dans ce dossier `scripts/` et exécutez :

```bash
npm install
```

Cela installera le package `firebase-admin` nécessaire pour le script.

---

## 🚀 Étape 3 : Exécuter la Migration

Une fois la clé de service en place et les dépendances installées, exécutez :

```bash
npm run migrate
```

Ou directement :

```bash
node migrate_user_dates.js
```

---

## 📊 Ce que fait le Script

Le script va :

1. Se connecter à votre Firestore avec la clé de service
2. Récupérer tous les documents de la collection `users`
3. Pour chaque utilisateur :
   - Vérifier le type des champs `createdAt`, `updatedAt`, `lastLoginAt`
   - Si c'est une String : la convertir en Timestamp Firestore
   - Si c'est déjà un Timestamp : ignorer (aucune modification)
4. Afficher un rapport détaillé :
   - Nombre d'utilisateurs mis à jour
   - Nombre d'utilisateurs ignorés (déjà OK)
   - Nombre d'erreurs éventuelles

---

## 📝 Exemple de Sortie

```
🚀 === DÉBUT MIGRATION DES DATES UTILISATEURS ===

📥 Récupération de tous les utilisateurs...
✅ 5 utilisateurs trouvés

🔄 Traitement: livreurtest@test.ci
   📅 createdAt: String → Timestamp
   📅 updatedAt: String → Timestamp
   ✅ Utilisateur mis à jour

🔄 Traitement: admin@socialbusiness.ci
   📅 createdAt: String → Timestamp
   📅 updatedAt: String → Timestamp
   ✅ Utilisateur mis à jour

🔄 Traitement: vendeurtest@test.ci
   ✓ createdAt: déjà Timestamp
   ✓ updatedAt: déjà Timestamp
   ⏭️  Aucune mise à jour nécessaire

🎉 === MIGRATION TERMINÉE ===
✅ Mis à jour: 2 utilisateurs
⏭️  Ignorés: 3 utilisateurs (déjà OK)
❌ Erreurs: 0 utilisateurs

Total: 5 utilisateurs traités
```

---

## ✅ Étape 4 : Tester l'Application

Après la migration, testez la connexion avec les comptes qui échouaient avant :

- `livreurtest@test.ci`
- `admin@socialbusiness.ci`

Ils devraient maintenant se connecter sans l'erreur Timestamp !

---

## 🧹 Script de Nettoyage RAM

Le fichier `cleanup_processes.ps1` permet de libérer la RAM en arrêtant tous les processus Java/Dart/Flutter/Gradle :

```powershell
powershell -ExecutionPolicy Bypass -File cleanup_processes.ps1
```

Utilisez-le avant de lancer des compilations Flutter si votre PC manque de RAM.

---

## ❓ En cas de Problème

### Le script ne trouve pas `serviceAccountKey.json`

- Assurez-vous que le fichier est bien nommé `serviceAccountKey.json` (pas `serviceAccountKey (1).json` ou autre)
- Assurez-vous qu'il est dans le dossier `scripts/`

### Erreur "firebase-admin not found"

- Relancez `npm install` dans le dossier `scripts/`

### Erreur de permission Firebase

- Vérifiez que vous avez téléchargé la bonne clé de service
- Vérifiez que votre compte Firebase a les droits d'admin

---

## 📁 Structure du Dossier

```
scripts/
├── README.md                    # Ce fichier
├── package.json                 # Configuration Node.js
├── migrate_user_dates.js        # Script de migration
├── cleanup_processes.ps1        # Script de nettoyage RAM
├── serviceAccountKey.json       # ⚠️ À créer (clé Firebase)
└── node_modules/                # (créé après npm install)
```

---

## 🔒 Sécurité

**IMPORTANT** : Le fichier `serviceAccountKey.json` contient des credentials sensibles !

- ❌ Ne le commitez JAMAIS sur Git
- ❌ Ne le partagez JAMAIS publiquement
- ✅ Il est déjà dans `.gitignore`
- ✅ Supprimez-le après la migration si vous le souhaitez
