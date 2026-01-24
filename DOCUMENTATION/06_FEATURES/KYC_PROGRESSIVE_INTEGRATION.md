# Guide d'Intégration KYC Progressif et Non-Contraignant

## 🎯 Philosophie : Sécurité Sans Friction

**Objectif** : Détecter les fraudeurs SANS frustrer les 95% d'utilisateurs légitimes.

### Principe Clé

```
┌─────────────────────────────────────────────────────────┐
│  BON UTILISATEUR                                        │
│  ✅ Inscription en 30 secondes                          │
│  ✅ Accès immédiat avec limites raisonnables            │
│  ✅ KYC optionnel (bonus si complété)                   │
│  ✅ Progression automatique selon historique            │
│  💎 Expérience fluide et agréable                       │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│  FRAUDEUR POTENTIEL                                     │
│  🛑 Détection silencieuse au background                 │
│  ⚠️  Limites strictes appliquées automatiquement        │
│  🔍 Revue manuelle si signaux forts                     │
│  ❌ Blacklisté → Blocage total                          │
│  🎯 Sécurité maximale sans faux positifs                │
└─────────────────────────────────────────────────────────┘
```

---

## 📊 Système de Niveaux (6 Tiers)

### 1️⃣ **TRUSTED** (Utilisateur de confiance) 🌟
**Comment y accéder** :
- 20+ commandes réussies
- 30+ jours d'ancienneté
- KYC vérifié
- Aucun incident

**Avantages** :
- ✅ Commandes jusqu'à 5M FCFA
- ✅ 50 commandes/jour
- ✅ Retraits instantanés
- ✅ Aucune restriction

**Message utilisateur** : "Compte de confiance - Toutes fonctionnalités débloquées"

---

### 2️⃣ **VERIFIED** (Utilisateur vérifié) ✅
**Comment y accéder** :
- 5+ commandes réussies
- 7+ jours d'ancienneté
- Bon comportement

**Avantages** :
- ✅ Commandes jusqu'à 1M FCFA
- ✅ 20 commandes/jour
- ✅ Retraits sous 2h
- 💡 KYC recommandé (pas obligatoire)

**Message utilisateur** : "Complétez votre KYC pour augmenter vos limites"

---

### 3️⃣ **NEW USER** (Nouveau compte) 🆕
**Conditions** :
- Inscription récente
- Aucun signal de risque
- Device propre

**Avantages** :
- ✅ Commandes jusqu'à 250k FCFA
- ✅ 5 commandes/jour
- ✅ Retraits sous 24h
- 🚀 **Accès immédiat SANS KYC**

**Message utilisateur** : "Nouveau compte - Limites augmentent avec votre activité"

---

### 4️⃣ **MODERATE RISK** (Surveillance) ⚠️
**Déclencheurs** :
- Device partagé (2-3 comptes)
- Email jetable
- Score risque 30-50

**Restrictions** :
- ⚠️  Commandes jusqu'à 100k FCFA
- ⚠️  2 commandes/jour
- ⚠️  Pas de retrait immédiat
- 📸 **KYC simplifié requis pour débloquer**

**Message utilisateur** : "Vérification simple requise pour augmenter vos limites"

---

### 5️⃣ **HIGH RISK** (Risque élevé) 🚨
**Déclencheurs** :
- Device suspect (3+ comptes)
- Émulateur détecté
- Score risque < 30

**Restrictions** :
- 🛑 Aucune commande autorisée
- 🛑 Retraits bloqués
- 🔍 **Revue manuelle obligatoire**

**Message utilisateur** : "Vérification complète requise - Support disponible 24/7"

---

### 6️⃣ **BLACKLISTED** (Compte bloqué) ❌
**Déclencheurs** :
- Dette active détectée
- Multi-compte frauduleux
- Blacklist match

**Restrictions** :
- ❌ Compte entièrement bloqué
- 💰 Réconciliation possible si dette

**Message utilisateur** : "Compte restreint - Contactez le support pour régulariser"

---

## 🔄 Workflow d'Inscription (95% des utilisateurs)

### Étape 1 : Inscription Ultra-Rapide (30 secondes)

```dart
// Dans auth_service_extended.dart
Future<void> registerVendeurOrLivreur({
  required String email,
  required String password,
  required String displayName,
  required String phoneNumber,
  required UserType userType,
}) async {
  // 1. Créer compte Firebase Auth
  final userCredential = await _auth.createUserWithEmailAndPassword(...);
  final user = userCredential.user;

  // 2. Créer profil Firestore
  await _createUserProfile(uid: user.uid, ...);

  // 3. ✨ Évaluation risque silencieuse (non-bloquante)
  final riskAssessment = await KYCAdaptiveService.assessUserRisk(
    userId: user.uid,
    phoneNumber: phoneNumber,
    email: email,
  );

  // 4. Décision automatique selon tier
  if (riskAssessment.tier == RiskTier.blacklisted) {
    // SEUL CAS bloquant : blacklisté confirmé
    await user.delete();
    throw Exception(
      'Votre inscription ne peut être traitée. '
      'Contactez notre support : support@socialbusiness.ci'
    );
  }

  // 5. ✅ Tous les autres cas : ACCÈS IMMÉDIAT
  debugPrint('✅ Utilisateur créé - Tier: ${riskAssessment.tier.displayName}');

  // 6. Notification adaptée selon tier
  if (riskAssessment.limits.requiresKYC) {
    // Suggérer KYC mais NE PAS BLOQUER
    _showKYCSuggestion(context, riskAssessment.limits.kycMessage);
  } else {
    // Utilisateur propre : aucune contrainte
    _showWelcomeMessage(context);
  }
}
```

**Résultat** :
- ✅ 95% des utilisateurs accèdent immédiatement
- ✅ 4% ont des limites mais peuvent commencer
- ❌ 1% sont bloqués (blacklistés avérés)

---

### Étape 2 : Vérification des Limites (Transparente)

```dart
// Avant de créer une commande
Future<void> createOrder(OrderModel order) async {
  // Vérifier si l'utilisateur peut créer cette commande
  final permission = await KYCAdaptiveService.canPerformAction(
    userId: vendorId,
    action: 'create_order',
    orderValue: order.totalAmount,
    currentDailyOrders: await _getDailyOrderCount(vendorId),
  );

  if (!permission.allowed) {
    // Message clair et constructif
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Limite atteinte'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(permission.reason!),
            SizedBox(height: 16),
            Text(
              permission.suggestedAction!,
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            SizedBox(height: 16),
            // Bouton vers KYC si applicable
            if (permission.suggestedAction!.contains('KYC'))
              ElevatedButton(
                onPressed: () => context.go('/kyc-upload'),
                child: Text('Compléter ma vérification'),
              ),
          ],
        ),
      ),
    );
    return;
  }

  // Créer la commande normalement
  await OrderService.createOrder(order);
}
```

**Expérience utilisateur** :
- ✅ Utilisateurs NEW/VERIFIED : Ne voient jamais ces limites
- ⚠️  Utilisateurs MODERATE : Message clair avec solution
- 🚫 Utilisateurs HIGH : Guidés vers support

---

### Étape 3 : Progression Automatique (Gamification)

```dart
// Après chaque commande réussie
await KYCAdaptiveService.upgradeTierIfEligible(userId);

// Critères automatiques :
// NEW USER (0 jours) → VERIFIED (7 jours + 5 commandes)
// VERIFIED (30 jours + 20 commandes + KYC) → TRUSTED
```

**Notifications sympathiques** :
```
🎉 Félicitations !
Vous êtes maintenant "Utilisateur Vérifié"
Nouvelles limites :
✅ 1M FCFA par commande
✅ 20 commandes/jour
```

---

## 🎨 Interface Utilisateur : KYC Optionnel

### Pour les utilisateurs NEW/VERIFIED (95%)

**Bannière non-intrusive** (en haut du dashboard) :

```dart
Card(
  color: Colors.blue.shade50,
  child: ListTile(
    leading: Icon(Icons.verified_user, color: Colors.blue),
    title: Text('Augmentez vos limites'),
    subtitle: Text('Complétez votre KYC en 2 minutes'),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('5 000 FCFA bonus', style: TextStyle(fontWeight: FontWeight.bold)),
        Icon(Icons.arrow_forward_ios),
      ],
    ),
    onTap: () => context.go('/kyc-upload'),
  ),
)
```

**Avantages KYC volontaire** :
- 💰 Bonus 5000 FCFA après validation
- 🚀 Limites augmentées instantanément
- ⭐ Badge "Vérifié" sur le profil
- 🎁 Priorité support client

---

### Pour les utilisateurs MODERATE (4%)

**Dialog doux lors de la première limite** :

```dart
AlertDialog(
  title: Row(
    children: [
      Icon(Icons.info, color: Colors.orange),
      SizedBox(width: 8),
      Text('Vérification rapide'),
    ],
  ),
  content: Text(
    'Pour garantir la sécurité de tous, une vérification '
    'simple est requise.\n\n'
    '📸 CNI + Selfie (2 minutes)\n'
    '✅ Validation sous 24h\n'
    '🎁 Bonus 5000 FCFA offerts',
  ),
  actions: [
    TextButton(
      child: Text('Plus tard'),
      onPressed: () => Navigator.pop(context),
    ),
    ElevatedButton(
      child: Text('Vérifier maintenant'),
      onPressed: () {
        Navigator.pop(context);
        context.go('/kyc-upload');
      },
    ),
  ],
)
```

---

### Pour les utilisateurs HIGH RISK (1%)

**Message clair avec support** :

```dart
AlertDialog(
  title: Text('Vérification requise'),
  content: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.security, size: 64, color: Colors.red),
      SizedBox(height: 16),
      Text(
        'Pour des raisons de sécurité, une vérification '
        'complète est nécessaire avant d\'utiliser votre compte.',
        textAlign: TextAlign.center,
      ),
      SizedBox(height: 16),
      Text(
        'Notre support est disponible 24/7 pour vous aider.',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    ],
  ),
  actions: [
    ElevatedButton.icon(
      icon: Icon(Icons.support_agent),
      label: Text('Contacter le support'),
      onPressed: () => _openWhatsAppSupport(),
    ),
  ],
)
```

---

## 📈 Métriques de Succès

### Objectifs :
- ✅ **95%+ d'utilisateurs** ne voient jamais de friction
- ⚠️  **4% bloqués temporairement** mais guidés
- ❌ **<1% bloqués définitivement** (fraudeurs avérés)

### KPIs à suivre :
1. **Taux d'abandon inscription** : <5%
2. **Temps moyen inscription** : <2 minutes
3. **Taux complétion KYC volontaire** : 30%+
4. **Taux détection fraude** : 90%+
5. **Faux positifs** : <0.5%

---

## 🔧 Paramètres Ajustables

### Limites par défaut (modifiables dans `kyc_adaptive_service.dart`) :

```dart
// NEW USER - À ajuster selon votre volume
maxOrderValue: 250000,      // 250k → peut monter à 500k
maxDailyOrders: 5,          // 5 → peut monter à 10
withdrawalDelay: 24h,       // 24h → peut descendre à 12h

// MODERATE RISK - Plus strict
maxOrderValue: 100000,      // 100k → peut descendre à 50k
maxDailyOrders: 2,          // 2 → peut descendre à 1
requiresKYC: true,          // Obligatoire

// HIGH RISK - Très strict
maxOrderValue: 0,           // Bloqué
requiresKYC: true,          // Obligatoire + revue manuelle
```

---

## 🎯 Résumé : 3 Règles d'Or

### 1. **Par défaut : Faire confiance** 👍
- Nouvel utilisateur = accès immédiat
- Limites raisonnables pour commencer
- Progression automatique selon activité

### 2. **Détection silencieuse** 🔍
- Vérifications au background
- Signaux de risque détectés sans alerter
- Adaptation automatique des limites

### 3. **Intervention graduée** 📊
- 95% : Aucune friction
- 4% : Suggestion KYC avec bonus
- 1% : Blocage avec support guidé

---

## ✅ Checklist d'Activation

```
☐ Installer KYCAdaptiveService
☐ Intégrer dans registerVendeurOrLivreur()
☐ Ajouter checks avant create_order/accept_delivery
☐ Créer bannière KYC optionnelle (dashboard)
☐ Tester avec comptes test (new, moderate, high risk)
☐ Ajuster limites selon business
☐ Déployer collection risk_assessments
☐ Former équipe support
☐ Activer monitoring fraude
```

---

**Philosophie finale** : Un bon utilisateur ne devrait JAMAIS savoir qu'un système anti-fraude existe. C'est transparent, fluide, et ne se révèle QUE si nécessaire. 🎯