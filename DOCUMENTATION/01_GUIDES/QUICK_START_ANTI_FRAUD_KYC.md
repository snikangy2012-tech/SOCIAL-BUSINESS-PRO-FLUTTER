# Guide de Démarrage Rapide - Système KYC Anti-Fraude

## Vue d'Ensemble

Ce guide vous montre comment intégrer le système KYC anti-fraude dans le processus d'inscription des vendeurs et livreurs.

---

## 📦 Ce qui a été créé

### Modèles de données
- ✅ `KYCVerificationModel` - Structure complète de vérification KYC
- ✅ `BlacklistEntryModel` - Entrées de blacklist avec dettes
- ✅ `DeviceFingerprintModel` - Registre des appareils
- ✅ `FaceHashModel` - Index biométrique des visages

### Services
- ✅ `BlacklistService` - Gestion blacklist et réconciliation
- ✅ `DeviceFingerprintService` - Détection appareils multiples

### À implémenter (Phase suivante)
- ⏳ `BiometricVerificationService` - Reconnaissance faciale ML Kit
- ⏳ `KYCRiskScoringService` - Calcul score de risque automatique
- ⏳ `AdvancedKYCService` - Orchestrateur principal
- ⏳ Écrans UI pour soumission et revue KYC

---

## 🚀 Intégration dans le Processus d'Inscription

### Étape 1: Modifier l'Inscription Vendeur/Livreur

Dans `lib/services/auth_service_extended.dart`, ajouter après la création du compte:

```dart
// Après création réussie du compte
Future<void> registerVendeurOrLivreur({
  required String email,
  required String password,
  required String displayName,
  required String userType, // 'vendeur' ou 'livreur'
  // ... autres paramètres
}) async {
  try {
    // 1. Créer le compte Firebase Auth (existant)
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = userCredential.user;
    if (user == null) throw Exception('User creation failed');

    // 2. Créer le profil Firestore (existant)
    await _createUserProfile(
      uid: user.uid,
      email: email,
      displayName: displayName,
      userType: userType,
      // ...
    );

    // 3. ✨ NOUVEAU: Collecter device fingerprint
    final deviceInfo = await DeviceFingerprintService.collectDeviceInfo();

    // 4. ✨ NOUVEAU: Vérifier blacklist immédiatement
    final blacklistCheck = await BlacklistService.checkBlacklist(
      phoneNumber: phoneNumber, // Depuis le formulaire
      deviceId: deviceInfo.deviceId,
    );

    if (blacklistCheck.isBlacklisted) {
      // Utilisateur blacklisté détecté !
      await user.delete(); // Supprimer le compte créé

      throw Exception(
        'Votre inscription ne peut être traitée. '
        'Contactez le support pour plus d\'informations.'
      );
    }

    // 5. ✨ NOUVEAU: Enregistrer l'appareil
    await DeviceFingerprintService.registerDevice(
      deviceInfo.deviceId,
      user.uid,
      deviceInfo,
    );

    // 6. ✨ NOUVEAU: Créer l'entrée KYC en attente
    await _createPendingKYCVerification(user.uid, userType);

    // 7. Rediriger vers le processus KYC
    // L'utilisateur doit compléter le KYC avant d'accéder à l'app

  } catch (e) {
    debugPrint('❌ Error in registration: $e');
    rethrow;
  }
}
```

### Étape 2: Créer une Entrée KYC Initiale

```dart
Future<void> _createPendingKYCVerification(
  String userId,
  String userType,
) async {
  final now = DateTime.now();

  // Créer une entrée KYC vide en attente
  await FirebaseFirestore.instance
      .collection('kyc_verifications')
      .doc(userId)
      .set({
    'userId': userId,
    'userType': userType,
    'status': 'pending',
    'submittedAt': Timestamp.fromDate(now),
    'updatedAt': Timestamp.fromDate(now),
    // Les autres champs seront remplis lors de la soumission KYC
  });

  debugPrint('✅ KYC verification entry created for $userId');
}
```

### Étape 3: Rediriger vers l'Écran KYC

Modifier le router pour rediriger les vendeurs/livreurs non-vérifiés :

```dart
// Dans lib/routes/app_router.dart

GoRoute(
  path: '/vendeur/dashboard',
  builder: (context, state) {
    // Vérifier si KYC complété
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('kyc_verifications')
          .doc(currentUserId)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final kycData = snapshot.data!.data() as Map<String, dynamic>?;
        final status = kycData?['status'] ?? 'pending';

        // Si KYC non approuvé, rediriger
        if (status != 'approved') {
          return const KYCPendingScreen(); // À créer
        }

        // KYC approuvé, afficher dashboard
        return const VendeurDashboard();
      },
    );
  },
),
```

---

## 🔍 Exemple: Vérification Blacklist Multi-Critères

```dart
// Lors de l'inscription ou soumission KYC
final blacklistCheck = await BlacklistService.checkBlacklist(
  cniNumber: 'CI123456789',
  faceHash: generatedFaceHash, // Depuis biométrie
  phoneNumber: '+2250708123456',
  mobileMoneyAccount: '0708123456',
  deviceId: deviceInfo.deviceId,
);

if (blacklistCheck.isBlacklisted) {
  // Afficher les raisons
  print('Blacklisté: ${blacklistCheck.blockedReasons}');
  print('Dette totale: ${blacklistCheck.totalDebtAmount} FCFA');

  if (blacklistCheck.canReconcile) {
    // Proposer la réconciliation
    showReconciliationDialog(context, blacklistCheck);
  } else {
    // Blocage permanent
    showPermanentBlockDialog(context);
  }
}
```

---

## 🎯 Exemple: Détection Appareil Réutilisé

```dart
// Pendant l'inscription
final deviceInfo = await DeviceFingerprintService.collectDeviceInfo();

final deviceRisk = await DeviceFingerprintService.checkDeviceRegistry(
  deviceInfo.deviceId,
  userId,
);

if (deviceRisk.shouldBlock) {
  // Appareil à risque élevé
  print('⚠️ Appareil suspect détecté:');
  for (var factor in deviceRisk.riskFactors) {
    print('  - $factor');
  }

  // Envoyer pour revue manuelle admin
  await _flagForManualReview(userId, deviceRisk);
}
```

---

## 📋 Firestore Security Rules

Ajouter ces règles dans `firestore.rules` :

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // KYC Verifications
    match /kyc_verifications/{kycId} {
      // Lecture: propriétaire ou admin
      allow read: if request.auth != null &&
                     (request.auth.uid == resource.data.userId ||
                      hasRole(request.auth.uid, 'admin'));

      // Écriture: propriétaire (création/update initial)
      allow create: if request.auth != null &&
                       request.auth.uid == request.resource.data.userId;
      allow update: if request.auth != null &&
                       (request.auth.uid == resource.data.userId ||
                        hasRole(request.auth.uid, 'admin'));

      // Suppression: admin uniquement
      allow delete: if request.auth != null &&
                       hasRole(request.auth.uid, 'admin');
    }

    // Blacklist (admin uniquement)
    match /blacklist/{docId} {
      allow read, write: if request.auth != null &&
                            hasRole(request.auth.uid, 'admin');
    }

    // Face Hashes (admin uniquement)
    match /face_hashes/{docId} {
      allow read, write: if request.auth != null &&
                            hasRole(request.auth.uid, 'admin');
    }

    // Device Registry (système et admin)
    match /device_registry/{deviceId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null &&
                      hasRole(request.auth.uid, 'admin');
    }

    // Helper function
    function hasRole(userId, role) {
      return get(/databases/$(database)/documents/users/$(userId)).data.userType == role ||
             get(/databases/$(database)/documents/users/$(userId)).data.isSuperAdmin == true;
    }
  }
}
```

---

## 🔧 Dépendances à Ajouter

Dans `pubspec.yaml` :

```yaml
dependencies:
  # Existantes
  firebase_core: ^latest
  cloud_firestore: ^latest

  # Nouvelles pour KYC anti-fraude
  device_info_plus: ^10.0.0        # Device fingerprinting
  package_info_plus: ^8.0.0        # App version
  google_ml_kit: ^0.16.3           # Face detection (Phase 2)
  image_picker: ^1.0.0             # Capture photos CNI/selfie
  path_provider: ^2.1.0            # Stockage temporaire images
  crypto: ^3.0.3                   # Hash génération
```

Installer :
```bash
flutter pub get
```

---

## 📸 Prochaines Étapes (Phase 2)

### 1. Implémenter la Biométrie
- Intégrer ML Kit Face Detection
- Créer `BiometricVerificationService`
- Liveness detection
- Comparaison visages

### 2. Créer les Écrans UI
- `KYCSubmissionScreen` (5 étapes)
- `AdminKYCReviewScreen`
- `BlacklistManagementScreen`
- `DebtReconciliationScreen`

### 3. Système de Scoring
- `KYCRiskScoringService`
- Auto-décision basée sur score
- ML pattern detection

### 4. APIs Externes
- Intégration Mobile Money APIs
- CNI Government API (si disponible)
- SMS OTP vérification

---

## 🧪 Tests Recommandés

### Test 1: Inscription Normale
```
1. Créer un nouveau compte vendeur
2. Vérifier création entry KYC pending
3. Vérifier enregistrement device
4. Vérifier aucune blacklist détectée
```

### Test 2: Détection Blacklist
```
1. Ajouter manuellement une entrée blacklist (via admin)
2. Tenter inscription avec même CNI/téléphone
3. Vérifier rejet automatique
```

### Test 3: Appareil Réutilisé
```
1. Créer compte A sur appareil X
2. Créer compte B sur même appareil X
3. Vérifier score de risque device augmenté
```

### Test 4: Réconciliation Dette
```
1. Vendeur avec dette active
2. Soumettre preuve paiement
3. Admin approuve réconciliation
4. Vérifier retrait de blacklist
```

---

## 📊 Monitoring

Suivre ces métriques via Analytics ou audit logs :

- **Taux de détection fraude** : `blacklist_detected / total_registrations`
- **Appareils multi-comptes** : Nombre devices avec >2 utilisateurs
- **Réconciliations réussies** : Dette récupérée en FCFA
- **Temps moyen KYC** : De soumission à approbation

---

## ⚠️ Points d'Attention

1. **Privacy RGPD** :
   - Consentement explicite pour biométrie
   - Droit à l'oubli après 5 ans
   - Hash irréversible pour visages

2. **Performance** :
   - Indexer collections Firestore (`cniNumber`, `faceHash`, etc.)
   - Utiliser pagination pour admin screens

3. **Sécurité** :
   - Chiffrer les données sensibles
   - Audit log toutes actions admin
   - Rate limiting sur vérifications

4. **UX** :
   - Messages d'erreur clairs mais non-spécifiques ("Contactez support")
   - Guide utilisateur pour photos CNI/selfie
   - Support multilingue (français)

---

## 📞 Support

Pour questions sur l'implémentation :
1. Consulter `ADVANCED_KYC_ANTI_FRAUD_SYSTEM.md` (documentation complète)
2. Vérifier les logs avec `debugPrint`
3. Tester en environnement de développement d'abord

---

## ✅ Checklist d'Implémentation

Phase 1 (Actuelle) :
- [x] Modèles de données créés
- [x] BlacklistService implémenté et testé
- [x] DeviceFingerprintService implémenté et testé
- [x] Dépendances installées (device_info_plus, package_info_plus, crypto)
- [x] Erreurs de compilation corrigées
- [ ] Intégration dans auth flow
- [ ] Firestore rules configurées
- [ ] Tests manuels

Phase 2 (À venir) :
- [ ] BiometricVerificationService
- [ ] UI Screens KYC
- [ ] Risk scoring automatique
- [ ] APIs externes (Mobile Money, CNI)
- [ ] Dashboard admin
- [ ] Tests automatisés

---

**Statut actuel** : Infrastructure fondamentale complète. Prêt pour intégration dans le flow d'inscription.