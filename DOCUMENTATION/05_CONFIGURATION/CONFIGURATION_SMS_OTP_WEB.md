# Configuration SMS OTP sur Web - Firebase Console

## Vue d'ensemble

L'authentification par SMS OTP fonctionne maintenant dans le code pour Web et Mobile, mais nécessite une configuration supplémentaire dans la Firebase Console pour fonctionner sur la plateforme Web.

## État actuel du code

✅ **Code modifié avec succès:**
- `lib/screens/auth/register_screen_extended.dart` : SMS OTP activé pour Web (lignes 143-176)
- `lib/services/auth_service_extended.dart` : Gestion du confirmationResult pour reCAPTCHA
- Le flux Web passe désormais par la même logique que Mobile

## Configuration Firebase Console requise

### Étape 1 : Activer l'authentification par téléphone

1. Accédez à [Firebase Console](https://console.firebase.google.com)
2. Sélectionnez votre projet **social-business-pro-67e92**
3. Dans le menu de gauche, cliquez sur **Authentication**
4. Allez dans l'onglet **Sign-in method**
5. Trouvez **Phone** dans la liste des fournisseurs
6. Cliquez sur **Phone** puis sur le bouton **Enable**
7. Cliquez sur **Save**

### Étape 2 : Configurer les domaines autorisés

1. Toujours dans **Authentication**, allez dans l'onglet **Settings**
2. Descendez jusqu'à la section **Authorized domains**
3. Vérifiez que les domaines suivants sont présents :
   - `localhost` (pour le développement local)
   - Votre domaine de production (si déployé, ex: `socialbusiness.ci`)
4. Si `localhost` n'est pas présent :
   - Cliquez sur **Add domain**
   - Entrez `localhost`
   - Cliquez sur **Add**

### Étape 3 : Configurer reCAPTCHA v2

Le SMS OTP sur Web utilise reCAPTCHA pour prévenir les abus.

#### Option A : Configuration automatique (recommandée pour le développement)

Firebase génère automatiquement une clé reCAPTCHA invisible pour votre domaine. Aucune action requise si vous utilisez les domaines autorisés listés ci-dessus.

#### Option B : Configuration manuelle (pour la production)

1. Accédez à [Google reCAPTCHA Admin Console](https://www.google.com/recaptcha/admin)
2. Cliquez sur le bouton **+** pour créer une nouvelle clé
3. Configurez comme suit :
   - **Label** : "Social Business Pro - SMS OTP"
   - **reCAPTCHA type** : reCAPTCHA v2 → "I'm not a robot" Checkbox
   - **Domains** : Ajoutez vos domaines
     - `localhost` (développement)
     - Votre domaine de production
4. Acceptez les conditions et cliquez sur **Submit**
5. Copiez la **Site Key** générée
6. Dans Firebase Console → Authentication → Sign-in method → Phone
7. Développez la section **reCAPTCHA verifier**
8. Collez votre **Site Key**
9. Cliquez sur **Save**

### Étape 4 : Vérifier les quotas SMS

Firebase impose des limites sur l'envoi de SMS :

1. Dans Firebase Console → Authentication → Sign-in method
2. Cliquez sur **Phone**
3. Vérifiez la section **SMS quota**
4. Par défaut :
   - **Test mode** : 10 SMS/jour
   - **Production** : Nécessite une facturation activée

#### Activer la facturation pour augmenter les quotas

1. Allez dans **Project Settings** (icône engrenage en haut à gauche)
2. Cliquez sur l'onglet **Usage and billing**
3. Cliquez sur **Modify plan** ou **Upgrade**
4. Sélectionnez le plan **Blaze (Pay as you go)**
5. Configurez votre mode de paiement

**Tarification SMS (selon région) :**
- Côte d'Ivoire : ~0.03 USD par SMS
- Vérifiez les tarifs actuels : [Firebase Pricing](https://firebase.google.com/pricing#blaze)

### Étape 5 : Tester l'authentification SMS sur Web

1. **Démarrez l'application en mode Web :**
   ```bash
   flutter run -d chrome
   ```

2. **Accédez à la page d'inscription :**
   - Naviguez vers `/register`

3. **Sélectionnez l'inscription par SMS :**
   - Choisissez le pays (Côte d'Ivoire : +225)
   - Entrez un numéro de téléphone valide
   - Sélectionnez le type d'utilisateur
   - Entrez le nom

4. **Cliquez sur "S'inscrire avec SMS"**
   - ✅ Vous devriez voir une case reCAPTCHA apparaître
   - Cochez la case "I'm not a robot"
   - Un SMS devrait être envoyé à votre numéro

5. **Vérifiez le code OTP :**
   - Entrez le code reçu par SMS
   - L'inscription devrait se terminer avec succès

## Numéros de test (mode développement)

Pour tester sans consommer de quota SMS :

1. Dans Firebase Console → Authentication → Sign-in method → Phone
2. Descendez jusqu'à **Phone numbers for testing**
3. Cliquez sur **Add phone number**
4. Ajoutez des numéros de test avec codes OTP fixes :
   - Numéro : `+22507000001`
   - Code : `123456`
   - Cliquez sur **Add**

**Utilisation :** Ces numéros ne recevront pas de vrais SMS mais accepteront le code configuré.

## Problèmes courants et solutions

### Problème 1 : "reCAPTCHA container is not defined"

**Cause :** Le conteneur pour reCAPTCHA n'est pas présent dans le DOM.

**Solution :** Vérifiez que vous avez bien un élément avec l'ID `recaptcha-container` dans votre page d'inscription.

Dans `register_screen_extended.dart`, ajoutez si nécessaire :

```dart
// Dans le widget build(), après le bouton d'inscription SMS
Container(
  id: 'recaptcha-container', // Pour Web uniquement
  height: kIsWeb ? 80 : 0,
),
```

### Problème 2 : "This domain is not authorized"

**Cause :** Le domaine n'est pas dans la liste des domaines autorisés.

**Solution :**
1. Vérifiez que `localhost` est dans **Authorized domains** (Étape 2)
2. Si vous testez sur un autre domaine, ajoutez-le également

### Problème 3 : "Quota exceeded"

**Cause :** Vous avez dépassé le quota SMS quotidien.

**Solutions :**
1. Utilisez des numéros de test (voir section ci-dessus)
2. Activez la facturation Blaze pour augmenter les quotas
3. Attendez 24h pour que le quota se réinitialise

### Problème 4 : SMS non reçu

**Cause possible :**
- Numéro invalide
- Quota dépassé
- Problème opérateur télécom

**Solutions :**
1. Vérifiez les logs dans la console Firebase :
   - Firebase Console → Functions → Logs
2. Vérifiez que le format du numéro est correct : `+225XXXXXXXX`
3. Essayez avec un numéro de test configuré
4. Vérifiez que le pays supporte les SMS Firebase (la Côte d'Ivoire est supportée)

### Problème 5 : "Invalid verification code"

**Cause :** Code OTP incorrect ou expiré.

**Solutions :**
1. Les codes OTP expirent après **5 minutes**
2. Vérifiez que vous entrez le bon code (6 chiffres)
3. Demandez un nouveau code si le délai est dépassé

## Architecture technique

### Flux d'authentification SMS sur Web

```
1. User clique sur "S'inscrire avec SMS"
   ↓
2. register_screen_extended.dart:_handlePhoneRegistration()
   ↓
3. AuthServiceExtended.sendPhoneOTP(fullPhone)
   ↓
4. firebase_auth.signInWithPhoneNumber()
   → Affiche reCAPTCHA
   → Envoie SMS via Firebase
   → Retourne confirmationResult
   ↓
5. Navigation vers /verify-otp avec confirmationResult
   ↓
6. otp_verification_screen.dart reçoit le confirmationResult
   ↓
7. User entre le code OTP
   ↓
8. confirmationResult.confirm(code)
   ↓
9. Création utilisateur Firebase Auth
   ↓
10. FirestoreSyncService.createUserDocumentAsync()
    (en arrière-plan, non bloquant)
   ↓
11. Navigation vers dashboard selon userType
```

### Différences Web vs Mobile

| Aspect | Web | Mobile |
|--------|-----|--------|
| reCAPTCHA | ✅ Requis | ❌ Non requis |
| Vérification automatique | ❌ Manuelle | ✅ Automatique (parfois) |
| confirmationResult | ✅ Passé via navigation | ❌ Géré par callback |
| Envoi SMS | Via Firebase Cloud | Via Firebase Cloud |

## Monitoring et logs

### Vérifier les SMS envoyés

1. Firebase Console → Authentication → Usage
2. Consultez le graphique **Phone sign-ins**
3. Nombre de SMS envoyés dans les dernières 24h

### Vérifier les erreurs

1. Ouvrez la console développeur du navigateur (F12)
2. Onglet **Console**
3. Recherchez les logs :
   - `📱 Envoi SMS vers: ...`
   - `✅ Code envoyé`
   - `❌ Erreur envoi SMS`

### Logs Firebase Functions (si applicable)

Si vous utilisez des Cloud Functions pour gérer les SMS :

1. Firebase Console → Functions → Logs
2. Filtrez par date/heure de votre test
3. Recherchez les erreurs liées à `auth` ou `sms`

## Checklist de configuration

Avant de considérer SMS OTP Web comme fonctionnel, vérifiez :

- [ ] Phone Authentication activé dans Firebase Console
- [ ] `localhost` ajouté aux domaines autorisés
- [ ] reCAPTCHA configuré (automatique ou manuel)
- [ ] Quota SMS vérifié (test mode ou facturation activée)
- [ ] Numéros de test configurés (pour développement)
- [ ] Test effectué avec succès sur Chrome
- [ ] Test effectué avec numéro réel (si quota disponible)
- [ ] Logs vérifiés dans console navigateur
- [ ] Erreurs corrigées si présentes

## Prochaines étapes recommandées

1. **Configurer Firebase Console** selon les étapes 1-4 ci-dessus
2. **Tester avec numéro de test** avant d'utiliser de vrais SMS
3. **Activer la facturation Blaze** quand vous serez prêt pour la production
4. **Monitorer l'utilisation** pour éviter les dépassements de quota
5. **Documenter les numéros de test** pour votre équipe

## Support et ressources

- [Documentation Firebase Phone Auth](https://firebase.google.com/docs/auth/web/phone-auth)
- [reCAPTCHA Configuration](https://firebase.google.com/docs/auth/web/phone-auth#use-invisible-recaptcha)
- [Tarification Firebase Auth](https://firebase.google.com/pricing#blaze)
- [Pays supportés pour SMS](https://firebase.google.com/support/guides/test-lab/international-sms)

## Statut actuel

✅ **Code complet** : SMS OTP fonctionne dans le code pour Web et Mobile
⏳ **Configuration Firebase** : À effectuer selon ce guide
⏳ **Tests** : À effectuer après configuration

---

**Dernière mise à jour :** 2025-11-20
**Auteur :** Claude Code
**Projet :** SOCIAL BUSINESS Pro
