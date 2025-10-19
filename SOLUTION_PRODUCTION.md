# Solution de Production pour Firestore

## Problème Actuel

Votre application Flutter Web ne peut pas se connecter à Firestore depuis `localhost`, donc nous utilisons une configuration locale temporaire (`user_type_config.dart`) qui mappe les emails aux types d'utilisateurs.

**Cette solution ne fonctionnera PAS en production** car:
- Vous devez ajouter manuellement chaque utilisateur dans le code
- Non scalable pour des centaines/milliers d'utilisateurs
- Les nouveaux utilisateurs seront toujours "acheteur" par défaut

## Solution Recommandée: Firebase Hosting

### Étape 1: Installer Firebase CLI

```bash
npm install -g firebase-tools
```

### Étape 2: Initialiser Firebase Hosting

```bash
# Dans le dossier de votre projet
firebase login
firebase init hosting
```

Répondez aux questions:
- **What do you want to use as your public directory?** → `build/web`
- **Configure as a single-page app?** → `Yes`
- **Set up automatic builds?** → `No`

### Étape 3: Build et Déployer

```bash
# Build Flutter Web
flutter build web --release

# Déployer
firebase deploy --only hosting
```

Votre app sera accessible à: `https://social-business-pro.web.app`

### Pourquoi Ça Fonctionne?

1. **CORS configuré** - Firebase Hosting a les bonnes entêtes CORS
2. **Pas de firewall** - Les serveurs Firebase communiquent entre eux
3. **HTTPS** - Connexion sécurisée requise par Firestore
4. **Domaine Firebase** - Reconnu et autorisé automatiquement

### Étape 4: Supprimer la Configuration Temporaire

Une fois déployé sur Firebase Hosting, Firestore fonctionnera normalement. Vous pourrez alors:

1. **Supprimer** `lib/config/user_type_config.dart`
2. **Restaurer** la logique originale dans `auth_service_web.dart`:

```dart
// Au lieu de:
userType = UserTypeConfig.getUserTypeFromEmail(userEmail);

// Revenir à:
userType = userData?['userType'] ?? 'acheteur';
```

## Alternative: Modifier l'Inscription

Si vous ne pouvez pas déployer immédiatement, modifiez votre écran d'inscription pour demander le type d'utilisateur:

### Étape 1: Ajouter un Sélecteur de Type

Dans `lib/screens/auth/register_screen.dart`:

```dart
// Ajouter une variable d'état
UserType _selectedUserType = UserType.acheteur;

// Ajouter un dropdown
DropdownButtonFormField<UserType>(
  value: _selectedUserType,
  decoration: InputDecoration(labelText: 'Type de compte'),
  items: [
    DropdownMenuItem(value: UserType.acheteur, child: Text('Acheteur')),
    DropdownMenuItem(value: UserType.vendeur, child: Text('Vendeur')),
    DropdownMenuItem(value: UserType.livreur, child: Text('Livreur')),
  ],
  onChanged: (value) => setState(() => _selectedUserType = value!),
)
```

### Étape 2: Utiliser le Type à l'Inscription

```dart
await authProvider.register(
  username: _usernameController.text,
  email: _emailController.text,
  phone: _phoneController.text,
  password: _passwordController.text,
  confirmPassword: _confirmPasswordController.text,
  userType: _selectedUserType, // Utiliser le type sélectionné
);
```

Ainsi, chaque nouvel utilisateur choisit son type lors de l'inscription, et ça sera stocké dans Firebase Auth (qui fonctionne) puis dans Firestore quand la connexion sera rétablie.

## Diagnostic du Problème Firestore

Pour comprendre pourquoi Firestore ne fonctionne pas sur localhost:

### 1. Vérifier les Logs du Navigateur

Ouvrez la Console du Navigateur (F12) et cherchez:
- Erreurs WebSocket
- Erreurs CORS
- Requêtes bloquées vers `firestore.googleapis.com`

### 2. Tester avec un Navigateur Différent

- **Chrome** → Essayer
- **Firefox** → Essayer
- **Edge** → Essayer
- **Mode Incognito** → Essayer (sans extensions)

### 3. Vérifier le Firewall/Antivirus

```bash
# Tester la connectivité à Firestore
ping firestore.googleapis.com
```

Si ça échoue, votre firewall bloque Firestore.

### 4. Essayer un Autre Réseau

- WiFi différent
- Hotspot mobile
- VPN activé/désactivé

## Configuration Actuelle (Temporaire)

Pour ajouter des utilisateurs maintenant, éditez `lib/config/user_type_config.dart`:

```dart
static final Map<String, String> emailToUserType = {
  // Admins
  'admin@socialbusiness.ci': 'admin',

  // Livreurs
  'livreurtest@test.ci': 'livreur',

  // Vendeurs
  'vendeurtest@test.ci': 'vendeur',
  'armo@test.com': 'vendeur',
  'nouvel-vendeur@example.com': 'vendeur',  // Ajouter ici

  // Acheteurs
  'acheteurtest@test.ci': 'acheteur',
  'snikangy2012@gmail.com': 'acheteur',
  'nouvel-acheteur@example.com': 'acheteur',  // Ajouter ici
};
```

## Prochaines Étapes

1. **Court terme**: Continuer à utiliser `user_type_config.dart` pour le développement
2. **Moyen terme**: Déployer sur Firebase Hosting pour résoudre le problème Firestore
3. **Long terme**: Implémenter un système d'inscription avec sélection de type

## Questions?

Si vous avez besoin d'aide pour:
- Configurer Firebase Hosting
- Diagnostiquer le problème Firestore
- Implémenter une autre solution

N'hésitez pas à demander!
