# Configuration Firebase Storage - Images Produits

## 📋 État Actuel

### ✅ Déjà Configuré
- [✅] Package `firebase_storage: ^12.3.2` installé
- [✅] Permissions Android (INTERNET, READ/WRITE_EXTERNAL_STORAGE)
- [✅] Règles Storage définies dans `storage.rules`

### ⏳ À Vérifier/Déployer
- [ ] Règles Storage déployées sur Firebase Console
- [ ] Bucket Storage activé dans Firebase Console
- [ ] Images uploadées accessibles

---

## 🚀 Étapes de Configuration

### Étape 1: Déployer les Règles Storage

**Commande** :
```bash
firebase deploy --only storage
```

**Ou déployer tout** :
```bash
firebase deploy
```

### Étape 2: Activer Storage dans Firebase Console

1. Aller sur [Firebase Console](https://console.firebase.google.com/)
2. Sélectionner votre projet
3. Menu latéral → **Storage**
4. Cliquer sur **Get Started** si Storage n'est pas activé
5. Choisir le mode:
   - **Mode test** (recommandé pour développement) : accès lecture/écriture public pendant 30 jours
   - **Mode production** : utiliser les règles de `storage.rules`

### Étape 3: Vérifier le Bucket

Le bucket par défaut devrait être :
```
gs://socialbusinesspro-4f36c.appspot.com
```

---

## 📁 Structure des Images dans Storage

Selon `storage.rules`, la structure est :

```
storage/
├── products/
│   └── {vendeurId}/
│       ├── {imageId1}.jpg
│       ├── {imageId2}.jpg
│       └── ...
├── users/
│   └── {userId}/
│       └── profile/
│           └── {imageId}.jpg
├── deliveries/
│   └── {deliveryId}/
│       └── proof.jpg
└── orders/
    └── {orderId}/
        └── document.pdf
```

---

## 🔐 Règles de Sécurité Actuelles

### Images Produits (lecture publique)
```javascript
match /products/{vendeurId}/{imageId} {
  allow read: if true;  // ✅ Tout le monde peut lire
  allow write: if isAuthenticated() && isOwner(vendeurId);
  allow delete: if isAuthenticated() && isOwner(vendeurId);
}
```

### Images Profil (lecture publique)
```javascript
match /users/{userId}/profile/{imageId} {
  allow read: if true;  // ✅ Tout le monde peut lire
  allow write: if isAuthenticated() && isOwner(userId);
  allow delete: if isAuthenticated() && isOwner(userId);
}
```

---

## 🔧 Utilisation dans le Code

### Image Helper Modifié

Le helper `ImageHelper` a été créé pour gérer:
1. **Images Firebase Storage** (priorité 1)
2. **Images Unsplash** (fallback temporaire)

```dart
static String getValidImageUrl({
  String? imageUrl,
  String? category,
  int index = 0,
}) {
  // Si l'URL existe et est valide (Firebase ou autre)
  if (imageUrl != null && imageUrl.isNotEmpty && _isValidUrl(imageUrl)) {
    return imageUrl;
  }

  // Sinon, fallback vers Unsplash
  if (category != null && category.isNotEmpty) {
    return getPlaceholderForCategory(category, index: index);
  }

  return getGenericPlaceholder(index);
}
```

### URLs Firebase Storage

Les URLs Firebase Storage ont ce format :
```
https://firebasestorage.googleapis.com/v0/b/socialbusinesspro-4f36c.appspot.com/o/products%2F{vendeurId}%2F{imageId}.jpg?alt=media&token={token}
```

**Ces URLs sont déjà valides** si elles sont dans Firestore! Le helper les utilise automatiquement.

---

## 🧪 Test de Configuration

### Test 1: Vérifier que Storage est Activé

```bash
# Dans Firebase Console
# Storage → Files → Vous devriez voir l'arborescence
```

### Test 2: Upload Manuel d'une Image Test

1. Firebase Console → Storage
2. Cliquer "Upload file"
3. Uploader une image dans `products/test/`
4. Copier l'URL de l'image
5. Tester l'URL dans un navigateur

### Test 3: Vérifier les URLs en Firestore

```bash
# Firebase Console → Firestore
# Collection: products
# Choisir un document
# Vérifier le champ "images" → doit contenir des URLs Firebase Storage
```

---

## 🎯 Ce Qui Devrait Fonctionner Maintenant

### Scenario 1: Images Firebase Storage Existantes ✅

Si vos produits ont déjà des URLs Firebase Storage dans Firestore:

```json
{
  "images": [
    "https://firebasestorage.googleapis.com/v0/b/.../products/vendeur1/image1.jpg?alt=media&token=..."
  ]
}
```

→ **Ces images s'afficheront automatiquement** une fois Storage activé et règles déployées!

### Scenario 2: Pas d'Images (champ vide) ⏭️

Si les produits n'ont pas d'images:

```json
{
  "images": []
}
```

→ Le helper utilise les placeholders Unsplash temporaires

---

## 📝 Commandes à Exécuter

```bash
# 1. Déployer les règles Storage
firebase deploy --only storage

# 2. Vérifier le déploiement
firebase deploy --only storage --debug

# 3. Lister les fichiers dans Storage (si firebase-tools configuré)
gsutil ls -r gs://socialbusinesspro-4f36c.appspot.com/products/
```

---

## ⚠️ Problèmes Possibles

### Problème 1: "Storage bucket not found"

**Solution** :
1. Firebase Console → Storage
2. Cliquer "Get Started"
3. Suivre l'assistant d'activation

### Problème 2: "Permission denied"

**Solutions** :
1. Vérifier que les règles sont déployées : `firebase deploy --only storage`
2. Vérifier que le bucket est correct dans `firebase.json`
3. Vérifier les règles dans Firebase Console → Storage → Rules

### Problème 3: Images ne se chargent pas

**Debug** :
1. Ouvrir l'app en mode debug
2. Regarder les logs Flutter : `flutter logs`
3. Chercher les erreurs réseau/Firebase
4. Vérifier que l'URL est valide en la collant dans un navigateur

---

## 🔄 Migration des Images

Si vous devez uploader en masse des images:

### Option 1: Via Firebase Console (petit nombre)
1. Firebase Console → Storage
2. Upload manuel fichier par fichier
3. Copier les URLs générées
4. Mettre à jour Firestore manuellement

### Option 2: Via Script (grand nombre)

Créer un script Node.js :

```javascript
// upload_images.js
const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

admin.initializeApp({
  credential: admin.credential.cert('./serviceAccountKey.json'),
  storageBucket: 'socialbusinesspro-4f36c.appspot.com'
});

const bucket = admin.storage().bucket();
const db = admin.firestore();

async function uploadProductImages() {
  const imagesDir = './product_images'; // Dossier local avec images

  const files = fs.readdirSync(imagesDir);

  for (const file of files) {
    const productId = file.split('_')[0]; // ex: produit123_1.jpg
    const vendeurId = 'vendeur1'; // À adapter

    const localPath = path.join(imagesDir, file);
    const storagePath = `products/${vendeurId}/${file}`;

    // Upload
    await bucket.upload(localPath, {
      destination: storagePath,
      metadata: {
        contentType: 'image/jpeg',
      }
    });

    // Get public URL
    const fileRef = bucket.file(storagePath);
    const [url] = await fileRef.getSignedUrl({
      action: 'read',
      expires: '03-01-2500'
    });

    // Update Firestore
    await db.collection('products').doc(productId).update({
      images: admin.firestore.FieldValue.arrayUnion(url)
    });

    console.log(`✅ Uploaded: ${file} → ${url}`);
  }
}

uploadProductImages().then(() => {
  console.log('✅ Migration terminée!');
  process.exit(0);
});
```

**Exécution** :
```bash
npm install firebase-admin
node upload_images.js
```

---

## ✅ Checklist Finale

- [ ] Storage activé dans Firebase Console
- [ ] Règles déployées (`firebase deploy --only storage`)
- [ ] Images uploadées dans le bon chemin (`products/{vendeurId}/`)
- [ ] URLs dans Firestore mis à jour
- [ ] App testée → Images s'affichent
- [ ] Fallback Unsplash fonctionne si pas d'image

---

## 📞 Aide Supplémentaire

Si les images ne s'affichent toujours pas après ces étapes:

1. Vérifier les logs Flutter : `flutter logs`
2. Vérifier l'URL d'une image en la copiant dans un navigateur
3. Vérifier les permissions Android (INTERNET)
4. Vérifier que firebase_storage est bien initialisé dans `main.dart`

---

**Prochaine étape**: Déployer les règles Storage avec `firebase deploy --only storage` 🚀
