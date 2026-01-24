# Configuration Android Studio pour Tests

## 🎯 Objectif

Configurer Android Studio pour tester votre application Flutter sur un émulateur ou appareil Android physique.

## 📋 Prérequis

### 1. Installer Android Studio

Si pas encore installé:
1. Téléchargez depuis: https://developer.android.com/studio
2. Installez avec les paramètres par défaut
3. Acceptez toutes les licences Android SDK

### 2. Vérifier l'Installation Flutter

```bash
# Ouvrir PowerShell et vérifier Flutter
flutter doctor -v
```

Vous devriez voir quelque chose comme:
```
[✓] Flutter (Channel stable, 3.x.x)
[✓] Android toolchain - develop for Android devices (Android SDK version XX)
[✓] Chrome - develop for the web
[!] Android Studio (version 202x.x)
```

## 🔧 Configuration Étape par Étape

### Étape 1: Configurer Android SDK

1. **Ouvrir Android Studio**
2. **Tools** → **SDK Manager**
3. **SDK Platforms** tab:
   - ✅ Cocher **Android 13.0 (Tiramisu)** - API Level 33
   - ✅ Cocher **Android 12.0 (S)** - API Level 31
   - ✅ Cocher **Android 11.0 (R)** - API Level 30
4. **SDK Tools** tab:
   - ✅ Android SDK Build-Tools
   - ✅ Android SDK Platform-Tools
   - ✅ Android Emulator
   - ✅ Google Play Services
5. **Cliquer "Apply"** et attendre l'installation

### Étape 2: Accepter les Licences Android

```bash
# Dans PowerShell
flutter doctor --android-licenses
```

Tapez `y` pour accepter toutes les licences.

### Étape 3: Créer un Émulateur Android

1. **Android Studio** → **Tools** → **Device Manager**
2. **Cliquer "Create Device"**
3. **Choisir un modèle**:
   - Recommandé: **Pixel 5** ou **Pixel 6**
4. **Choisir une image système**:
   - Recommandé: **API 33 (Android 13.0 Tiramisu)**
   - Sélectionner **x86_64** (plus rapide)
   - Cliquer **Download** si nécessaire
5. **Cliquer "Next"** puis **"Finish"**

### Étape 4: Configurer Firebase pour Android

#### 4.1. Vérifier firebase_options.dart

Votre fichier `lib/config/firebase_options.dart` doit contenir la configuration Android:

```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'VOTRE_API_KEY',
  appId: 'VOTRE_APP_ID',
  messagingSenderId: 'VOTRE_SENDER_ID',
  projectId: 'social-business-pro',
  storageBucket: 'social-business-pro.appspot.com',
);
```

#### 4.2. Vérifier AndroidManifest.xml

Fichier: `android/app/src/main/AndroidManifest.xml`

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Permissions Internet -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>

    <application
        android:label="SOCIAL BUSINESS Pro"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">

            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme" />

            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>

        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
</manifest>
```

#### 4.3. Vérifier build.gradle

**Fichier**: `android/app/build.gradle`

```gradle
android {
    namespace = "ci.socialbusiness.social_business_pro"
    compileSdk = 34

    defaultConfig {
        applicationId = "ci.socialbusiness.social_business_pro"
        minSdk = 21
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.debug
        }
    }
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
}
```

**Fichier**: `android/build.gradle`

```gradle
buildscript {
    ext.kotlin_version = '1.9.0'
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:8.1.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version")
        classpath("com.google.gms:google-services:4.4.0")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
```

### Étape 5: Ajouter google-services.json

1. **Aller sur Firebase Console**: https://console.firebase.google.com
2. **Sélectionner votre projet**: social-business-pro
3. **Project Settings** (⚙️ en haut à gauche)
4. **Scroll vers le bas** → Section "Your apps"
5. **Cliquer sur l'icône Android** pour ajouter une app Android
6. **Package name**: `ci.socialbusiness.social_business_pro`
7. **Télécharger google-services.json**
8. **Copier le fichier** dans: `android/app/google-services.json`

## 🚀 Lancer l'Application sur Android

### Option 1: Via Android Studio

1. **Ouvrir Android Studio**
2. **File** → **Open** → Sélectionner le dossier de votre projet
3. **Device Manager** → **Démarrer l'émulateur**
4. **Attendre que l'émulateur démarre** (1-2 minutes)
5. **Terminal** dans Android Studio:
   ```bash
   flutter run
   ```

### Option 2: Via VS Code

1. **Ouvrir VS Code** dans votre projet
2. **Démarrer l'émulateur** depuis Android Studio Device Manager
3. **VS Code** → **Run and Debug** (Ctrl+Shift+D)
4. **Sélectionner "Flutter"** et cliquer **Start Debugging**

### Option 3: Via PowerShell/Terminal

```bash
# Lister les appareils disponibles
flutter devices

# Démarrer un émulateur
flutter emulators
flutter emulators --launch <emulator_id>

# Lancer l'app sur l'émulateur
cd C:\Users\ALLAH-PC\social_media_business_pro
flutter run -d <device_id>
```

## 🔍 Vérification et Débogage

### Vérifier Flutter Doctor

```bash
flutter doctor -v
```

Toutes les lignes doivent être ✓ vertes pour Android:
```
[✓] Flutter
[✓] Android toolchain
[✓] Android Studio
[✓] VS Code
[✓] Connected device (emulator)
```

### Résoudre les Problèmes Courants

#### Problème 1: "No connected devices"
```bash
# Vérifier que l'émulateur tourne
flutter devices

# Si vide, démarrer l'émulateur depuis Android Studio
```

#### Problème 2: "Android license not accepted"
```bash
flutter doctor --android-licenses
# Taper 'y' pour accepter toutes les licences
```

#### Problème 3: "Gradle build failed"
```bash
# Nettoyer le build
cd android
./gradlew clean

# Revenir à la racine
cd ..

# Rebuilder
flutter clean
flutter pub get
flutter run
```

#### Problème 4: "google-services.json missing"
- Télécharger depuis Firebase Console
- Placer dans `android/app/google-services.json`
- Redémarrer le build

### Hot Reload pendant le Développement

Une fois l'app lancée:
- **r** → Hot reload (recharge le code sans redémarrer)
- **R** → Hot restart (redémarre complètement)
- **q** → Quitter

## 📱 Tester sur un Appareil Physique

### 1. Activer le Mode Développeur

Sur votre téléphone Android:
1. **Paramètres** → **À propos du téléphone**
2. **Taper 7 fois sur "Numéro de build"**
3. Mode développeur activé!

### 2. Activer le Débogage USB

1. **Paramètres** → **Options de développement**
2. **Activer "Débogage USB"**

### 3. Connecter le Téléphone

1. **Brancher le câble USB** au PC
2. **Autoriser le débogage** sur le téléphone (popup)
3. **Vérifier la connexion**:
   ```bash
   flutter devices
   ```
4. **Lancer l'app**:
   ```bash
   flutter run
   ```

## 🎯 Tester les Fonctionnalités

Une fois l'app lancée sur Android:

### Test 1: Inscription
1. Aller sur l'écran d'inscription
2. Sélectionner "Vendeur"
3. Remplir le formulaire
4. Créer le compte
5. ✅ Vérifier la redirection vers login

### Test 2: Connexion
1. Se connecter avec les identifiants
2. ✅ Vérifier que Firestore fonctionne sur mobile
3. ✅ Vérifier la redirection vers vendeur-dashboard

### Test 3: Navigation
1. Tester tous les écrans
2. Vérifier les menus
3. Tester les fonctionnalités

## 📊 Différences Web vs Mobile

| Fonctionnalité | Web | Mobile Android |
|----------------|-----|----------------|
| **Firebase Auth** | ✅ | ✅ |
| **Firestore** | ❌ (timeout) | ✅ (devrait marcher) |
| **Config locale** | ✅ Nécessaire | ⚠️ Fallback seulement |
| **Performances** | Moyen | Excellent |
| **Permissions** | Limitées | Complètes |

## 🔧 Commandes Utiles

```bash
# Nettoyer le projet
flutter clean

# Réinstaller les dépendances
flutter pub get

# Build APK de test
flutter build apk --debug

# Build APK de release
flutter build apk --release

# Installer l'APK sur le device
flutter install

# Voir les logs
flutter logs

# Analyser le code
flutter analyze
```

## 📝 Checklist Avant de Tester

- [ ] Android Studio installé
- [ ] Flutter SDK installé et configuré
- [ ] Licences Android acceptées (`flutter doctor --android-licenses`)
- [ ] Émulateur créé ou téléphone connecté
- [ ] `google-services.json` dans `android/app/`
- [ ] Firebase configuré pour Android
- [ ] Build réussi (`flutter build apk --debug`)

## 🎉 Prochaines Étapes

Une fois que ça fonctionne sur Android:
1. ✅ Firestore devrait fonctionner normalement (pas de timeout comme sur Web)
2. ✅ Vous pourrez tester toutes les fonctionnalités
3. ✅ L'authentification sera plus rapide
4. ✅ Vous pourrez tester les notifications push
5. ✅ Vous pourrez tester la géolocalisation

## ❓ Besoin d'Aide?

Si vous rencontrez des problèmes:
1. Exécutez `flutter doctor -v` et partagez le résultat
2. Partagez les messages d'erreur complets
3. Vérifiez que tous les fichiers de configuration sont corrects
