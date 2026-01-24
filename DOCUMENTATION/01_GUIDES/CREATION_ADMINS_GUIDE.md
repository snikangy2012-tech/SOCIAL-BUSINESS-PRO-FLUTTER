# Guide de Création d'Administrateurs - SOCIAL BUSINESS Pro

## Problème résolu ✅

Avant, lorsqu'un super admin créait un nouvel administrateur via l'interface :
- ❌ Seul un document Firestore était créé
- ❌ Aucun compte Firebase Auth n'était créé
- ❌ Le mot de passe saisi était inutile et jamais utilisé
- ❌ L'admin ne pouvait pas se connecter

**Maintenant :**
- ✅ Le compte Firebase Auth ET le document Firestore sont créés automatiquement
- ✅ Un mot de passe sécurisé est généré automatiquement (12 caractères, majuscules, minuscules, chiffres, symboles)
- ✅ Le mot de passe est affiché UNE SEULE FOIS au super admin
- ✅ L'admin peut se connecter immédiatement
- ✅ L'admin DOIT changer son mot de passe à la première connexion

## Architecture

```
┌─────────────────┐
│  Flutter App    │
│  (Super Admin)  │
└────────┬────────┘
         │ HTTP POST /api/admin/create
         │ (JWT Token)
         ▼
┌─────────────────┐
│  Backend Node.js │
│  admin_backend_  │
│  server.js       │
└────────┬────────┘
         │ Firebase Admin SDK
         ├─────────────────┐
         ▼                 ▼
┌──────────────┐   ┌─────────────┐
│ Firebase Auth│   │  Firestore  │
│  (Compte)    │   │  (Profil)   │
└──────────────┘   └─────────────┘
```

## Installation et Démarrage

### 1. Backend Node.js

Le backend doit être démarré AVANT de créer des admins depuis l'interface.

```bash
# Installer les dépendances (déjà fait)
npm install

# Démarrer le serveur backend
node admin_backend_server.js
```

Le serveur démarre sur **http://localhost:3001**

Vous devriez voir :
```
🚀 Admin Backend Server démarré
📡 Port: 3001
✅ Routes disponibles:
   GET  /health - Vérifier le statut
   POST /api/admin/create - Créer un admin
   POST /api/admin/reset-password - Réinitialiser mot de passe
```

### 2. Application Flutter

L'application Flutter se connecte automatiquement au backend via le service `AdminCreationService`.

**URL du backend** (configurable dans `lib/services/admin_creation_service.dart`) :
- Développement local : `http://localhost:3001`
- Production : À définir selon votre hébergement

## Utilisation

### Créer un nouvel administrateur

1. **Connectez-vous en tant que Super Admin**

2. **Allez dans** : Menu → Gestion des Administrateurs

3. **Cliquez sur** : "Nouvel Admin"

4. **Remplissez le formulaire** :
   - Nom complet
   - Email
   - Rôle (Support, Modérateur, Éditeur, etc.)
   - ⚠️ **PAS DE MOT DE PASSE** : généré automatiquement

5. **Cliquez sur "Créer"**

6. **Notez le mot de passe temporaire** :
   - Un dialogue s'affiche avec le mot de passe
   - ⚠️ **IMPORTANT** : Ce mot de passe ne sera affiché qu'une seule fois
   - Cliquez sur l'icône 📋 pour le copier
   - Partagez-le de manière sécurisée avec le nouvel admin

7. **L'admin peut maintenant se connecter** :
   - Email : celui que vous avez saisi
   - Mot de passe : le mot de passe temporaire affiché
   - À la première connexion, il sera redirigé vers la page de changement de mot de passe obligatoire

### Réinitialiser le mot de passe d'un admin

Si un admin a perdu son mot de passe, vous pouvez le réinitialiser :

1. Depuis l'écran "Gestion des Administrateurs"
2. Cliquez sur "Détails" ou "Modifier" de l'admin concerné
3. (Fonctionnalité de réinitialisation à ajouter dans l'interface - le backend est prêt)

**Appel direct au backend** (temporaire) :
```bash
curl -X POST http://localhost:3001/api/admin/reset-password \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_FIREBASE_TOKEN" \
  -d '{"adminUid": "UID_DE_L_ADMIN"}'
```

## Sécurité

### Génération de mot de passe

Les mots de passe temporaires sont générés avec :
- **12 caractères** minimum
- Au moins **1 majuscule** (A-Z)
- Au moins **1 minuscule** (a-z)
- Au moins **1 chiffre** (0-9)
- Au moins **1 symbole** (@#$%&*!)
- Ordre aléatoire

Exemple : `aB3@xYz9!mN2`

### Authentification du backend

Le backend vérifie :
1. ✅ Token JWT Firebase valide
2. ✅ L'utilisateur existe dans Firestore
3. ✅ L'utilisateur est de type `admin`
4. ✅ L'utilisateur a le flag `isSuperAdmin: true`

Si une seule condition échoue → **403 Forbidden**

### Changement obligatoire du mot de passe

Lors de la création, le compte est marqué avec :
```json
{
  "needsPasswordChange": true
}
```

Le router Flutter redirige automatiquement vers `/change-initial-password` si ce flag est `true`.

Après changement réussi :
```json
{
  "needsPasswordChange": false,
  "passwordChangedAt": "2025-12-11T02:30:00Z"
}
```

## Fichiers modifiés/créés

### Nouveaux fichiers

- `admin_backend_server.js` - Serveur backend Node.js + Express
- `lib/services/admin_creation_service.dart` - Service Flutter pour appeler le backend
- `CREATION_ADMINS_GUIDE.md` - Ce guide

### Fichiers modifiés

- `lib/screens/admin/admin_management_screen.dart` - Interface de création d'admins
- `package.json` - Ajout de `express`
- `lib/routes/app_router.dart` - Redirection pour changement de mot de passe
- `lib/screens/auth/change_password_screen.dart` - Unification des écrans de changement de mot de passe

## Dépannage

### Erreur : "Délai dépassé. Vérifiez que le serveur backend est démarré"

**Solution** : Démarrez le backend :
```bash
node admin_backend_server.js
```

### Erreur : "Token manquant" ou "Token invalide"

**Causes possibles** :
- L'utilisateur n'est pas connecté
- Le token a expiré
- Le token est invalide

**Solution** : Déconnectez-vous et reconnectez-vous

### Erreur : "Accès refusé: Super Admin requis"

**Cause** : L'utilisateur connecté n'est pas un super admin

**Solution** : Vérifiez que dans Firestore, l'utilisateur a :
```json
{
  "userType": "admin",
  "isSuperAdmin": true
}
```

### Erreur : "Cet email est déjà utilisé"

**Cause** : Un compte Firebase Auth existe déjà avec cet email

**Solutions** :
1. Utiliser un autre email
2. Supprimer l'ancien compte depuis Firebase Console → Authentication
3. Modifier l'email de l'ancien compte

## Scripts utiles

### Créer des comptes Auth pour admins existants (migration)

Si vous avez des admins dans Firestore SANS compte Auth :

```bash
node create_admin_auth_accounts.js
```

Ce script :
- Cherche tous les `userType: admin` dans Firestore
- Vérifie si un compte Auth existe
- Crée le compte Auth si manquant
- Utilise le mot de passe temporaire par défaut : `Admin@2025`

### Corriger les admins existants

```bash
node fix_admin_users.js
```

Ce script :
- Marque les emails comme vérifiés
- Active les comptes
- Ajoute le flag `needsPasswordChange: true`

## Production

Pour déployer en production, il est recommandé d'utiliser :

### Option 1 : Firebase Cloud Functions (recommandé)

Migrer `admin_backend_server.js` vers une Cloud Function Firebase pour une meilleure sécurité et scalabilité.

### Option 2 : Serveur dédié

Héberger `admin_backend_server.js` sur un serveur (Heroku, Railway, DigitalOcean, etc.) et mettre à jour l'URL dans `admin_creation_service.dart`.

### Option 3 : API Gateway

Utiliser un API Gateway (AWS API Gateway, Google Cloud API Gateway) devant le serveur Node.js.

## Support

En cas de problème :

1. Vérifier que le backend est démarré
2. Vérifier les logs du backend dans la console
3. Vérifier les logs Flutter (Run → Debug Console)
4. Consulter ce guide

---

**Dernière mise à jour** : 11 décembre 2025
**Version** : 1.0
