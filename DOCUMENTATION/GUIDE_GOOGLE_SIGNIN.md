# 🔐 Guide de Configuration Google Sign-In pour Android

## ❌ Erreur Actuelle

```
PlatformException(sign_in_failed, com.google.android.gms.common.api.ApiException: 10:)
```

**Code d'erreur 10** = `DEVELOPER_ERROR` - Configuration OAuth2 incorrecte

---

## 🛠️ Solution en 3 Étapes

### Étape 1: Obtenir l'Empreinte SHA-1

#### Option A: Avec Gradle (Recommandé)
```bash
cd android
./gradlew signingReport
```

Cherchez dans la sortie:
```
Variant: debug
Config: debug
Store: C:\Users\ALLAH-PC\.android\debug.keystore
Alias: AndroidDebugKey
MD5: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
SHA1: AA:BB:CC:DD:EE:FF:11:22:33:44:55:66:77:88:99:00:AA:BB:CC:DD  ⬅️ COPIEZ CECI
SHA-256: XX:XX:...
```

#### Option B: Avec keytool directement
```bash
keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android
```

---

### Étape 2: Configurer Firebase Console

1. **Aller sur**: https://console.firebase.google.com/
2. **Sélectionner** votre projet: `social_media_business_pro`
3. **Aller dans**: Paramètres du projet ⚙️ (en haut à gauche)
4. **Onglet**: "Général"
5. **Section**: "Vos applications" → Android
6. **Cliquer** sur votre application Android
7. **Ajouter l'empreinte SHA-1** copiée à l'étape 1
8. **Cliquer** sur "Enregistrer"
9. **Télécharger** le nouveau fichier `google-services.json`
10. **Remplacer** le fichier existant dans `android/app/google-services.json`

---

### Étape 3: Configurer Google Cloud Console (Important!)

1. **Aller sur**: https://console.cloud.google.com/
2. **Sélectionner** le projet lié à Firebase
3. **Menu** → APIs et services → Identifiants
4. **Trouver**: "Client OAuth 2.0 pour Android"
5. **Vérifier** que le SHA-1 est bien enregistré
6. Si le client n'existe pas:
   - Cliquer sur **"+ CRÉER DES IDENTIFIANTS"**
   - Sélectionner **"ID client OAuth"**
   - Type d'application: **Android**
   - Nom: `Social Business Pro (Android)`
   - Nom du package: `com.socialbusiness.social_media_business_pro`
   - Empreinte du certificat SHA-1: Coller le SHA-1
   - Cliquer sur **"CRÉER"**

---

## 🧪 Vérification de Configuration

### Fichier `android/app/google-services.json`

Vérifier que ce fichier contient:
```json
{
  "project_info": {
    "project_id": "votre-project-id",
    "project_number": "123456789"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:123456789:android:...",
        "android_client_info": {
          "package_name": "com.socialbusiness.social_media_business_pro"
        }
      },
      "oauth_client": [
        {
          "client_id": "123456789-xxxxx.apps.googleusercontent.com",
          "client_type": 1,
          "android_info": {
            "package_name": "com.socialbusiness.social_media_business_pro",
            "certificate_hash": "votre_sha1_ici"  ⬅️ VÉRIFIEZ CECI
          }
        }
      ]
    }
  ]
}
```

### Fichier `android/app/build.gradle.kts`

Vérifier que le package name correspond:
```kotlin
android {
    namespace = "com.socialbusiness.social_media_business_pro"  // ✅ Doit correspondre

    defaultConfig {
        applicationId = "com.socialbusiness.social_media_business_pro"  // ✅ Doit correspondre
        // ...
    }
}
```

---

## 🔄 Après Configuration

### 1. Nettoyer le build
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

### 2. Reconstruire l'APK
```bash
flutter build apk --debug
```

### 3. Désinstaller l'ancienne app
```bash
adb uninstall com.socialbusiness.social_media_business_pro
```

### 4. Réinstaller la nouvelle app
```bash
flutter install
```

---

## 📱 Test de Connexion Google

1. Lancer l'application
2. Cliquer sur **"Continuer avec Google"**
3. Sélectionner un compte Google
4. Autoriser l'application
5. ✅ La connexion devrait réussir

---

## 🐛 Dépannage

### Erreur persiste après configuration?

**Vérifier les logs détaillés:**
```bash
adb logcat | grep -E "GoogleSignIn|OAuth|ApiException"
```

**Points de contrôle:**
- ✅ SHA-1 enregistré dans Firebase Console
- ✅ SHA-1 enregistré dans Google Cloud Console
- ✅ `google-services.json` téléchargé et remplacé
- ✅ Package name identique partout
- ✅ Application reconstruite après modification
- ✅ Ancienne version désinstallée avant réinstallation

### SHA-1 ne correspond pas?

Si vous avez modifié le keystore ou changé de machine:
1. Obtenir le nouveau SHA-1
2. Ajouter le nouveau SHA-1 dans Firebase (pas besoin de supprimer l'ancien)
3. Mettre à jour Google Cloud Console
4. Télécharger le nouveau `google-services.json`
5. Rebuild complet

---

## 📚 Ressources

- [Firebase Android Setup](https://firebase.google.com/docs/android/setup)
- [Google Sign-In for Android](https://developers.google.com/identity/sign-in/android/start)
- [SHA-1 Certificate Fingerprint](https://developers.google.com/android/guides/client-auth)

---

## ✅ Checklist Complète

- [ ] SHA-1 obtenu avec `gradlew signingReport`
- [ ] SHA-1 ajouté dans Firebase Console
- [ ] SHA-1 ajouté dans Google Cloud Console
- [ ] Client OAuth Android créé dans Google Cloud
- [ ] `google-services.json` téléchargé et remplacé
- [ ] Package name vérifié (`com.socialbusiness.social_media_business_pro`)
- [ ] `flutter clean` exécuté
- [ ] `./gradlew clean` exécuté
- [ ] Ancienne app désinstallée
- [ ] Nouvelle app installée
- [ ] Test de connexion Google réussi ✅
