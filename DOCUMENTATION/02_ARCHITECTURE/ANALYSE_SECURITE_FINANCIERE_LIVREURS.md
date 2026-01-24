# 🔒 ANALYSE SÉCURITÉ FINANCIÈRE - GESTION DES LIVREURS
## Social Business Pro - Décembre 2025

---

## 📋 CONTEXTE & PROBLÉMATIQUE

### 🎯 Objectif de la règle actuelle (≥ 50k FCFA → Vendeur livre)

**Raisonnement** :
```
Si commande ≥ 50 000 FCFA
→ Somme trop importante pour confier à un livreur
→ Risque de fuite/vol élevé
→ SOLUTION : Le vendeur livre lui-même (plus fiable)
```

### ⚠️ Risques identifiés avec les livreurs

**Scénario problématique** :
```
Livreur accepte commande de 150 000 FCFA
    ↓
Client paie en CASH à la livraison
    ↓
Livreur a 150k FCFA en poche
    ↓
RISQUES :
❌ Livreur disparaît avec l'argent
❌ Livreur prétend avoir été volé
❌ Livreur reporte le paiement indéfiniment
❌ Livreur dépense l'argent avant de reverser
```

### 💰 Enjeux financiers

**Pour la plateforme** :
- Perte sèche si livreur disparaît
- Réputation endommagée
- Vendeur et acheteur mécontents
- Coûts juridiques de recouvrement

**Pour le vendeur** :
- Ne reçoit pas son paiement
- Perte du produit + revenu
- Doit gérer le SAV client

**Pour l'acheteur** :
- A payé mais pas reçu
- Ou reçu mais vendeur réclame paiement
- Confiance brisée

---

## 🌍 COMMENT LES AUTRES PLATEFORMES GÈRENT CE RISQUE ?

### 1. **Jumia Côte d'Ivoire**

**Approche** : Paiement en ligne obligatoire pour montants élevés

```
┌─────────────────────────────────────────────────────┐
│ Montant < 50k FCFA                                  │
│ → Cash à la livraison autorisé                      │
├─────────────────────────────────────────────────────┤
│ Montant ≥ 50k FCFA                                  │
│ → OBLIGATOIRE : Paiement en ligne (CB, Mobile Money)│
│ → Livreur ne manipule PAS l'argent                  │
└─────────────────────────────────────────────────────┘
```

**Avantages** :
- ✅ Zéro risque de fuite du livreur
- ✅ Paiement sécurisé et tracé
- ✅ Livreur se concentre sur la livraison

**Inconvénients** :
- ❌ Limite les clients sans compte bancaire/mobile money
- ❌ Frais de transaction (2-3%)

---

### 2. **Glovo / Uber Eats**

**Approche** : Caution + assurance + limite journalière

```
┌─────────────────────────────────────────────────────┐
│ SYSTÈME DE CAUTION                                  │
├─────────────────────────────────────────────────────┤
│ Livreur dépose caution : 50 000 FCFA               │
│ → Bloquée pendant toute la durée du contrat        │
│ → Remboursée après 30 jours sans incident          │
├─────────────────────────────────────────────────────┤
│ LIMITE JOURNALIÈRE                                  │
├─────────────────────────────────────────────────────┤
│ Max 200k FCFA de cash/jour par livreur             │
│ → Au-delà, doit reverser à un point de collecte    │
├─────────────────────────────────────────────────────┤
│ ASSURANCE OBLIGATOIRE                               │
├─────────────────────────────────────────────────────┤
│ Livreur assuré pour pertes/vols                    │
│ → Plateforme couverte jusqu'à 500k FCFA           │
└─────────────────────────────────────────────────────┘
```

**Avantages** :
- ✅ Livreur a "skin in the game" (caution)
- ✅ Limite les montants à risque
- ✅ Assurance couvre les cas exceptionnels

---

### 3. **Yango Delivery (Russie/CI)**

**Approche** : Compte livreur avec solde + clearing automatique

```
┌─────────────────────────────────────────────────────┐
│ WALLET LIVREUR                                      │
├─────────────────────────────────────────────────────┤
│ Chaque paiement cash → Enregistré dans wallet      │
│ Solde livreur mis à jour en temps réel             │
├─────────────────────────────────────────────────────┤
│ CLEARING AUTOMATIQUE                                │
├─────────────────────────────────────────────────────┤
│ Si solde > 100k FCFA                               │
│ → BLOCAGE : Doit reverser avant nouvelle livraison │
│                                                      │
│ Si solde > 50k FCFA pendant 24h                    │
│ → ALERTE : SMS/notification rappel                 │
├─────────────────────────────────────────────────────┤
│ PÉNALITÉS                                           │
├─────────────────────────────────────────────────────┤
│ Retard de reversement > 48h                        │
│ → Suspension du compte                             │
│ → Pénalité 5% du montant                          │
└─────────────────────────────────────────────────────┘
```

**Avantages** :
- ✅ Tracking en temps réel des montants
- ✅ Pression automatique pour reverser
- ✅ Détection précoce des anomalies

---

### 4. **WhatsApp Business (Informel ivoirien)**

**Approche** : Confiance + système de parrainage

```
┌─────────────────────────────────────────────────────┐
│ PARRAINAGE OBLIGATOIRE                              │
├─────────────────────────────────────────────────────┤
│ Nouveau livreur doit être parrainé                 │
│ → Parrain (ancien livreur) est garant              │
│ → Si problème, parrain paie                        │
├─────────────────────────────────────────────────────┤
│ PROGRESSION                                         │
├─────────────────────────────────────────────────────┤
│ Niveau 1 (0-20 livraisons) : Max 30k FCFA/commande│
│ Niveau 2 (21-50) : Max 60k FCFA/commande          │
│ Niveau 3 (51+) : Max 150k FCFA/commande           │
└─────────────────────────────────────────────────────┘
```

**Avantages** :
- ✅ Très adapté à la culture ivoirienne
- ✅ Responsabilisation par les pairs
- ✅ Confiance progressive

---

## 🎯 PROPOSITIONS POUR SOCIAL BUSINESS PRO

---

## 💡 PROPOSITION #1 : Système de paliers de confiance progressifs

### 🎯 Concept

Le montant maximal qu'un livreur peut gérer dépend de son **niveau de confiance** (historique, performances, caution).

### 📊 Grille de paliers

```
┌──────────────────────────────────────────────────────────────────┐
│ NIVEAU 1 : DÉBUTANT (0-10 livraisons)                           │
├──────────────────────────────────────────────────────────────────┤
│ Caution requise : 0 FCFA                                         │
│ Montant max/commande : 30 000 FCFA                              │
│ Total max non reversé : 50 000 FCFA                             │
│ Délai de reversement : 24h                                       │
│                                                                   │
│ Si commande > 30k FCFA → Auto-assignée au vendeur               │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│ NIVEAU 2 : CONFIRMÉ (11-50 livraisons + note ≥ 4.0/5)          │
├──────────────────────────────────────────────────────────────────┤
│ Caution requise : 20 000 FCFA                                   │
│ Montant max/commande : 75 000 FCFA                              │
│ Total max non reversé : 150 000 FCFA                            │
│ Délai de reversement : 48h                                       │
│                                                                   │
│ Si commande > 75k FCFA → Auto-assignée au vendeur               │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│ NIVEAU 3 : EXPERT (51-150 livraisons + note ≥ 4.3/5)           │
├──────────────────────────────────────────────────────────────────┤
│ Caution requise : 50 000 FCFA                                   │
│ Montant max/commande : 150 000 FCFA                             │
│ Total max non reversé : 300 000 FCFA                            │
│ Délai de reversement : 72h                                       │
│                                                                   │
│ Si commande > 150k FCFA → Auto-assignée au vendeur              │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│ NIVEAU 4 : VIP (151+ livraisons + note ≥ 4.5/5 + caution 100k) │
├──────────────────────────────────────────────────────────────────┤
│ Caution requise : 100 000 FCFA                                  │
│ Montant max/commande : 300 000 FCFA                             │
│ Total max non reversé : 500 000 FCFA                            │
│ Délai de reversement : 7 jours                                   │
│                                                                   │
│ Avantages :                                                       │
│ ✅ Badge "Livreur VIP Certifié"                                 │
│ ✅ Priorité sur les grosses commandes                           │
│ ✅ Bonus mensuel de performance                                 │
└──────────────────────────────────────────────────────────────────┘
```

### 🛠️ Implémentation

**1. Modèle livreur**

```dart
// lib/models/livreur_trust_level.dart
enum LivreurTrustLevel {
  debutant,   // 0-10 livraisons
  confirme,   // 11-50 livraisons + note ≥ 4.0
  expert,     // 51-150 livraisons + note ≥ 4.3
  vip,        // 151+ livraisons + note ≥ 4.5 + caution 100k
}

class LivreurTrustConfig {
  final LivreurTrustLevel level;
  final double cautionRequired;      // Caution à déposer
  final double maxOrderAmount;       // Montant max par commande
  final double maxUnpaidBalance;     // Total max non reversé
  final int reversementDelayHours;   // Délai de reversement

  static LivreurTrustConfig getConfig(
    int completedDeliveries,
    double averageRating,
    double cautionDeposited,
  ) {
    // Niveau VIP
    if (completedDeliveries >= 151 &&
        averageRating >= 4.5 &&
        cautionDeposited >= 100000) {
      return LivreurTrustConfig(
        level: LivreurTrustLevel.vip,
        cautionRequired: 100000,
        maxOrderAmount: 300000,
        maxUnpaidBalance: 500000,
        reversementDelayHours: 168, // 7 jours
      );
    }

    // Niveau Expert
    if (completedDeliveries >= 51 && averageRating >= 4.3) {
      return LivreurTrustConfig(
        level: LivreurTrustLevel.expert,
        cautionRequired: 50000,
        maxOrderAmount: 150000,
        maxUnpaidBalance: 300000,
        reversementDelayHours: 72,
      );
    }

    // Niveau Confirmé
    if (completedDeliveries >= 11 && averageRating >= 4.0) {
      return LivreurTrustConfig(
        level: LivreurTrustLevel.confirme,
        cautionRequired: 20000,
        maxOrderAmount: 75000,
        maxUnpaidBalance: 150000,
        reversementDelayHours: 48,
      );
    }

    // Niveau Débutant (par défaut)
    return LivreurTrustConfig(
      level: LivreurTrustLevel.debutant,
      cautionRequired: 0,
      maxOrderAmount: 30000,
      maxUnpaidBalance: 50000,
      reversementDelayHours: 24,
    );
  }
}
```

**2. Vérification avant assignation**

```dart
// Dans delivery_service.dart - Fonction d'assignation
Future<bool> canLivreurAcceptOrder(
  String livreurId,
  double orderAmount,
) async {
  // Récupérer le profil livreur
  final livreur = await _getUserProfile(livreurId);

  // Calculer le niveau de confiance
  final trustConfig = LivreurTrustConfig.getConfig(
    livreur.completedDeliveries,
    livreur.averageRating,
    livreur.cautionDeposited,
  );

  // Vérifier si le montant est dans la limite
  if (orderAmount > trustConfig.maxOrderAmount) {
    debugPrint('❌ Commande ${orderAmount} FCFA > limite ${trustConfig.maxOrderAmount} FCFA');
    return false;
  }

  // Vérifier le solde non reversé actuel
  final currentUnpaidBalance = await _getUnpaidBalance(livreurId);

  if (currentUnpaidBalance + orderAmount > trustConfig.maxUnpaidBalance) {
    debugPrint('❌ Solde non reversé ${currentUnpaidBalance + orderAmount} FCFA > limite ${trustConfig.maxUnpaidBalance} FCFA');
    return false;
  }

  debugPrint('✅ Livreur peut accepter (niveau: ${trustConfig.level.name})');
  return true;
}
```

**3. Filtrage des commandes disponibles**

```dart
// Dans available_orders_screen.dart (livreur)
Stream<List<OrderModel>> getAvailableOrdersForLivreur(String livreurId) async* {
  final livreur = await _getUserProfile(livreurId);
  final trustConfig = LivreurTrustConfig.getConfig(
    livreur.completedDeliveries,
    livreur.averageRating,
    livreur.cautionDeposited,
  );

  yield* FirebaseFirestore.instance
      .collection('orders')
      .where('status', isEqualTo: 'ready')
      .where('totalAmount', isLessThanOrEqualTo: trustConfig.maxOrderAmount)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs
            .map((doc) => OrderModel.fromFirestore(doc))
            .toList();
      });
}
```

**4. Badge et affichage niveau**

```dart
// Widget de niveau de confiance
class LivreurTrustBadge extends StatelessWidget {
  final LivreurTrustLevel level;

  @override
  Widget build(BuildContext context) {
    final config = _getBadgeConfig(level);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: config.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.borderColor, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, color: Colors.white, size: 16),
          SizedBox(width: 4),
          Text(
            config.label,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  _BadgeConfig _getBadgeConfig(LivreurTrustLevel level) {
    switch (level) {
      case LivreurTrustLevel.vip:
        return _BadgeConfig(
          label: '🌟 VIP',
          icon: Icons.star,
          color: Colors.purple,
          borderColor: Colors.amber,
        );
      case LivreurTrustLevel.expert:
        return _BadgeConfig(
          label: '⚡ Expert',
          icon: Icons.verified,
          color: Colors.blue,
          borderColor: Colors.lightBlue,
        );
      case LivreurTrustLevel.confirme:
        return _BadgeConfig(
          label: '✓ Confirmé',
          icon: Icons.check_circle,
          color: Colors.green,
          borderColor: Colors.lightGreen,
        );
      case LivreurTrustLevel.debutant:
        return _BadgeConfig(
          label: 'Débutant',
          icon: Icons.person,
          color: Colors.grey,
          borderColor: Colors.grey.shade400,
        );
    }
  }
}
```

### ✅ Avantages

- ✅ **Sécurité progressive** : Limite les risques pour nouveaux livreurs
- ✅ **Motivation** : Gamification avec niveaux à débloquer
- ✅ **Confiance gagnée** : Livreurs expérimentés récompensés
- ✅ **Flexibilité** : Chaque livreur selon son niveau

---

## 💡 PROPOSITION #2 : Wallet livreur avec alertes automatiques

### 🎯 Concept

Chaque livreur a un **wallet virtuel** qui suit en temps réel l'argent collecté et les reversements dus.

### 💳 Fonctionnement

```
┌──────────────────────────────────────────────────────────────────┐
│ WALLET LIVREUR                                                   │
├──────────────────────────────────────────────────────────────────┤
│ Solde actuel : 85 000 FCFA                                      │
│ Limite (niveau Confirmé) : 150 000 FCFA                         │
│ Marge restante : 65 000 FCFA                                    │
│                                                                   │
│ ⏰ Plus ancien paiement non reversé : il y a 18h                │
│ ⚠️ Délai max : 48h                                              │
│ ⏳ Temps restant : 30h                                          │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│ HISTORIQUE (7 derniers jours)                                   │
├──────────────────────────────────────────────────────────────────┤
│ 12 déc 14:30  | Livraison #1234 | +25 000 FCFA | Solde: 25k   │
│ 12 déc 16:15  | Livraison #1235 | +35 000 FCFA | Solde: 60k   │
│ 12 déc 17:00  | Livraison #1236 | +25 000 FCFA | Solde: 85k   │
│ 12 déc 18:00  | ⏰ RAPPEL : Reverser avant demain 14h30        │
└──────────────────────────────────────────────────────────────────┘
```

### 🚨 Système d'alertes

**Alerte Niveau 1 : 50% de la limite atteinte**
```
Notification :
"💰 Vous avez collecté 75k FCFA (50% de votre limite).
Pensez à reverser bientôt pour continuer vos livraisons."
```

**Alerte Niveau 2 : 80% de la limite atteinte**
```
SMS + Notification :
"⚠️ ATTENTION : Vous avez 120k FCFA non reversés (80% de limite).
Reversez avant d'atteindre 150k pour éviter un blocage."
```

**Alerte Niveau 3 : 100% de la limite atteinte**
```
SMS + Notification + Blocage app :
"🚫 COMPTE BLOQUÉ
Vous avez atteint votre limite de 150k FCFA.
Reversez maintenant pour débloquer votre compte."

→ Livreur NE PEUT PLUS accepter de nouvelles livraisons
→ Écran de reversement forcé
```

**Alerte Niveau 4 : Délai dépassé**
```
48h après la première collecte sans reversement :
"⏰ DÉLAI DÉPASSÉ
Vous devez reverser 85k FCFA immédiatement.
Pénalité : 5% (4 250 FCFA) si non reversé sous 6h.

Points de collecte disponibles :
📍 Cocody Angré - Orange Money
📍 Yopougon Siporex - MTN Money
📍 Plateau CCI - Agence SBP
"
```

### 🛠️ Implémentation

**1. Modèle Wallet**

```dart
// lib/models/livreur_wallet.dart
class LivreurWallet {
  final String livreurId;
  final double currentBalance;      // Solde actuel non reversé
  final double maxBalance;          // Limite selon niveau
  final DateTime? oldestUnpaidDate; // Date du plus ancien paiement non reversé
  final List<WalletTransaction> transactions;

  double get availableMargin => max(0, maxBalance - currentBalance);

  double get balancePercentage => (currentBalance / maxBalance) * 100;

  Duration? get timeSinceOldestUnpaid {
    if (oldestUnpaidDate == null) return null;
    return DateTime.now().difference(oldestUnpaidDate!);
  }

  bool get isBlocked => currentBalance >= maxBalance;

  bool get isNearLimit => balancePercentage >= 80;

  bool get hasOverduePayments {
    if (timeSinceOldestUnpaid == null) return false;
    // Vérifier selon le niveau (24h, 48h, 72h, etc.)
    return timeSinceOldestUnpaid!.inHours >= reversementDelayHours;
  }
}

class WalletTransaction {
  final String id;
  final String type; // 'collection' ou 'reversement'
  final double amount;
  final String orderId;
  final DateTime timestamp;
  final bool isReversed;
}
```

**2. Service de gestion**

```dart
// lib/services/livreur_wallet_service.dart
class LivreurWalletService {

  /// Ajouter un paiement collecté
  static Future<void> addCollection({
    required String livreurId,
    required String orderId,
    required double amount,
  }) async {
    final walletRef = FirebaseFirestore.instance
        .collection('livreur_wallets')
        .doc(livreurId);

    await walletRef.set({
      'currentBalance': FieldValue.increment(amount),
      'transactions': FieldValue.arrayUnion([
        {
          'id': Uuid().v4(),
          'type': 'collection',
          'amount': amount,
          'orderId': orderId,
          'timestamp': FieldValue.serverTimestamp(),
          'isReversed': false,
        }
      ]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Vérifier les alertes
    await _checkAndSendAlerts(livreurId);
  }

  /// Enregistrer un reversement
  static Future<void> addReversement({
    required String livreurId,
    required double amount,
    required String method, // 'orange_money', 'mtn_momo', 'cash_deposit'
    String? proofPhoto,
  }) async {
    final walletRef = FirebaseFirestore.instance
        .collection('livreur_wallets')
        .doc(livreurId);

    await walletRef.update({
      'currentBalance': FieldValue.increment(-amount),
      'transactions': FieldValue.arrayUnion([
        {
          'id': Uuid().v4(),
          'type': 'reversement',
          'amount': amount,
          'method': method,
          'proofPhoto': proofPhoto,
          'timestamp': FieldValue.serverTimestamp(),
        }
      ]),
      'lastReversementAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    debugPrint('✅ Reversement enregistré: $amount FCFA');
  }

  /// Vérifier et envoyer alertes
  static Future<void> _checkAndSendAlerts(String livreurId) async {
    final wallet = await getWallet(livreurId);
    final trustConfig = await _getTrustConfig(livreurId);

    // Alerte 50%
    if (wallet.balancePercentage >= 50 && wallet.balancePercentage < 80) {
      await _sendAlert(livreurId, AlertLevel.info, wallet);
    }

    // Alerte 80%
    if (wallet.balancePercentage >= 80 && wallet.balancePercentage < 100) {
      await _sendAlert(livreurId, AlertLevel.warning, wallet);
    }

    // Blocage 100%
    if (wallet.isBlocked) {
      await _sendAlert(livreurId, AlertLevel.critical, wallet);
      await _blockLivreurAccount(livreurId);
    }

    // Délai dépassé
    if (wallet.hasOverduePayments) {
      await _sendAlert(livreurId, AlertLevel.overdue, wallet);
    }
  }

  static Future<void> _sendAlert(
    String livreurId,
    AlertLevel level,
    LivreurWallet wallet,
  ) async {
    String title, body;

    switch (level) {
      case AlertLevel.info:
        title = '💰 Pensez à reverser bientôt';
        body = 'Vous avez collecté ${wallet.currentBalance.toStringAsFixed(0)} FCFA '
               '(${wallet.balancePercentage.toStringAsFixed(0)}% de votre limite).';
        break;

      case AlertLevel.warning:
        title = '⚠️ ATTENTION : Proche de la limite';
        body = 'Vous avez ${wallet.currentBalance.toStringAsFixed(0)} FCFA non reversés. '
               'Reversez avant d\'atteindre ${wallet.maxBalance.toStringAsFixed(0)} FCFA.';
        break;

      case AlertLevel.critical:
        title = '🚫 COMPTE BLOQUÉ';
        body = 'Limite atteinte (${wallet.maxBalance.toStringAsFixed(0)} FCFA). '
               'Reversez maintenant pour débloquer votre compte.';
        break;

      case AlertLevel.overdue:
        title = '⏰ DÉLAI DÉPASSÉ';
        body = 'Vous devez reverser ${wallet.currentBalance.toStringAsFixed(0)} FCFA immédiatement. '
               'Pénalité de 5% si non reversé sous 6h.';
        break;
    }

    // Notification push
    await NotificationService.send(
      userId: livreurId,
      title: title,
      body: body,
      data: {'type': 'wallet_alert', 'level': level.name},
    );

    // SMS si critique
    if (level == AlertLevel.critical || level == AlertLevel.overdue) {
      await SMSService.send(
        userId: livreurId,
        message: '$title\n$body',
      );
    }
  }
}
```

**3. Écran Wallet**

```dart
// lib/screens/livreur/wallet_screen.dart
class LivreurWalletScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<LivreurWallet>(
      stream: LivreurWalletService.watchWallet(currentUserId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();

        final wallet = snapshot.data!;

        return Scaffold(
          appBar: AppBar(title: Text('Mon Porte-monnaie')),
          body: Column(
            children: [
              // Carte de solde
              _buildBalanceCard(wallet),

              // Alertes
              if (wallet.isNearLimit || wallet.hasOverduePayments)
                _buildAlertBanner(wallet),

              // Bouton reverser
              if (wallet.currentBalance > 0)
                _buildReversementButton(wallet),

              // Historique
              Expanded(
                child: _buildTransactionHistory(wallet.transactions),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBalanceCard(LivreurWallet wallet) {
    return Card(
      margin: EdgeInsets.all(16),
      color: wallet.isBlocked ? Colors.red.shade100 : Colors.blue.shade50,
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Text('Solde actuel', style: TextStyle(fontSize: 14)),
            SizedBox(height: 8),
            Text(
              '${wallet.currentBalance.toStringAsFixed(0)} FCFA',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: wallet.isBlocked ? Colors.red : Colors.blue,
              ),
            ),
            SizedBox(height: 16),

            // Barre de progression
            LinearProgressIndicator(
              value: wallet.balancePercentage / 100,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation(
                wallet.isBlocked ? Colors.red :
                wallet.isNearLimit ? Colors.orange : Colors.green
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Limite : ${wallet.maxBalance.toStringAsFixed(0)} FCFA',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReversementButton(LivreurWallet wallet) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showReversementDialog(wallet),
        icon: Icon(Icons.upload),
        label: Text('REVERSER MAINTENANT'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          padding: EdgeInsets.all(16),
          textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
```

### ✅ Avantages

- ✅ **Visibilité totale** : Livreur voit exactement où il en est
- ✅ **Alertes préventives** : Évite les blocages surprise
- ✅ **Traçabilité** : Historique complet des transactions
- ✅ **Automatisation** : Système self-service

---

## 💡 PROPOSITION #3 : Paiement en ligne obligatoire pour montants élevés

### 🎯 Concept

Au-delà d'un certain montant, le **paiement en ligne est obligatoire** (pas de cash à la livraison).

### 📊 Règles de paiement

```
┌──────────────────────────────────────────────────────────────────┐
│ MONTANT < 30 000 FCFA                                           │
├──────────────────────────────────────────────────────────────────┤
│ Options disponibles :                                            │
│ ✓ Cash à la livraison (COD)                                     │
│ ✓ Mobile Money (Orange, MTN, Moov, Wave)                        │
│ ✓ Carte bancaire                                                │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│ MONTANT 30 001 - 100 000 FCFA                                  │
├──────────────────────────────────────────────────────────────────┤
│ Options disponibles :                                            │
│ ⚠️ Cash à la livraison (frais +500 FCFA + livreur niveau 2+)   │
│ ✓ Mobile Money (recommandé)                                     │
│ ✓ Carte bancaire                                                │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│ MONTANT > 100 000 FCFA                                          │
├──────────────────────────────────────────────────────────────────┤
│ Options disponibles :                                            │
│ ❌ Cash à la livraison (NON DISPONIBLE)                         │
│ ✓ Mobile Money (OBLIGATOIRE)                                    │
│ ✓ Carte bancaire                                                │
│                                                                   │
│ Si vendeur livre lui-même :                                     │
│ ✓ Cash accepté (vendeur = propriétaire)                        │
└──────────────────────────────────────────────────────────────────┘
```

### 🛠️ Implémentation

```dart
// Dans cart_screen.dart / checkout
List<PaymentMethod> _getAvailablePaymentMethods(double totalAmount) {
  if (totalAmount <= 30000) {
    // Tous les moyens acceptés
    return [
      PaymentMethod.cashOnDelivery,
      PaymentMethod.orangeMoney,
      PaymentMethod.mtnMomo,
      PaymentMethod.moovMoney,
      PaymentMethod.wave,
    ];
  }

  if (totalAmount <= 100000) {
    // Cash avec frais supplémentaires
    return [
      PaymentMethod.cashOnDelivery, // Avec avertissement
      PaymentMethod.orangeMoney,
      PaymentMethod.mtnMomo,
      PaymentMethod.moovMoney,
      PaymentMethod.wave,
    ];
  }

  // > 100k : Paiement en ligne obligatoire
  return [
    PaymentMethod.orangeMoney,
    PaymentMethod.mtnMomo,
    PaymentMethod.moovMoney,
    PaymentMethod.wave,
  ];
}
```

### ✅ Avantages

- ✅ **Zéro risque** pour montants élevés
- ✅ **Traçabilité** : Tous les paiements enregistrés
- ✅ **Encourage** le paiement digital (bon pour l'économie)

### ⚠️ Inconvénient

- ❌ Exclut les clients sans mobile money (mais rare en CI)

---

## 💡 PROPOSITION #4 : Système de caution progressive

### 🎯 Concept

Le livreur dépose une **caution remboursable** pour débloquer des montants plus élevés.

### 💰 Grille de caution

```
AUCUNE CAUTION
→ Max 30k FCFA/commande

CAUTION 20k FCFA
→ Max 75k FCFA/commande
→ Remboursée après 3 mois sans incident

CAUTION 50k FCFA
→ Max 150k FCFA/commande
→ Remboursée après 6 mois sans incident

CAUTION 100k FCFA
→ Max 300k FCFA/commande
→ Statut VIP
→ Remboursée après 1 an
```

### 🛠️ Gestion de la caution

```dart
// Dépôt de caution
Future<void> depositCaution(String livreurId, double amount) async {
  await FirebaseFirestore.instance
      .collection('users')
      .doc(livreurId)
      .update({
    'cautionDeposited': amount,
    'cautionDepositedAt': FieldValue.serverTimestamp(),
    'cautionStatus': 'active',
  });

  // Créer une transaction
  await FirebaseFirestore.instance
      .collection('caution_deposits')
      .add({
    'livreurId': livreurId,
    'amount': amount,
    'depositedAt': FieldValue.serverTimestamp(),
    'status': 'active',
    'refundableAfter': _calculateRefundDate(amount),
  });
}
```

### ✅ Avantages

- ✅ **Engagement** du livreur (skin in the game)
- ✅ **Flexibilité** : Chacun choisit son niveau
- ✅ **Remboursable** : Pas une perte pour le livreur

---

## 📊 TABLEAU COMPARATIF DES SOLUTIONS

| Solution | Sécurité | Complexité | Adoption livreurs | UX Client | Coût dev |
|----------|----------|------------|-------------------|-----------|----------|
| **#1 Paliers progressifs** | ⭐⭐⭐⭐⭐ | Moyenne | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | Moyen |
| **#2 Wallet + alertes** | ⭐⭐⭐⭐⭐ | Élevée | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Élevé |
| **#3 Paiement en ligne obligatoire** | ⭐⭐⭐⭐⭐ | Faible | ⭐⭐ | ⭐⭐⭐ | Faible |
| **#4 Système de caution** | ⭐⭐⭐⭐ | Moyenne | ⭐⭐⭐ | ⭐⭐⭐⭐ | Moyen |

---

## 🎯 RECOMMANDATION FINALE : APPROCHE HYBRIDE

### 🏆 Combinaison optimale

```
SOLUTION #1 (Paliers progressifs)
+
SOLUTION #2 (Wallet + alertes)
+
SOLUTION #3 partielle (Paiement en ligne au-delà de 200k FCFA)
```

### 📐 Configuration recommandée

```
┌──────────────────────────────────────────────────────────────────┐
│ NIVEAU DÉBUTANT (0-10 livraisons)                               │
├──────────────────────────────────────────────────────────────────┤
│ Max/commande : 30k FCFA                                          │
│ Max total non reversé : 50k FCFA                                │
│ Délai reversement : 24h                                          │
│ Caution : 0 FCFA                                                 │
│                                                                   │
│ Commandes > 30k → Vendeur livre                                 │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│ NIVEAU CONFIRMÉ (11-50 livraisons + note 4.0+)                  │
├──────────────────────────────────────────────────────────────────┤
│ Max/commande : 100k FCFA                                         │
│ Max total non reversé : 200k FCFA                               │
│ Délai reversement : 48h                                          │
│ Caution recommandée : 20k FCFA (optionnel)                      │
│                                                                   │
│ Commandes > 100k → Vendeur livre                                │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│ NIVEAU EXPERT (51+ livraisons + note 4.3+ + caution 50k)       │
├──────────────────────────────────────────────────────────────────┤
│ Max/commande : 200k FCFA                                         │
│ Max total non reversé : 400k FCFA                               │
│ Délai reversement : 72h                                          │
│ Caution : 50k FCFA                                              │
│                                                                   │
│ Commandes > 200k → Paiement en ligne OBLIGATOIRE                │
└──────────────────────────────────────────────────────────────────┘
```

### ✅ Avantages de cette approche

1. **Sécurité maximale** : Risque limité pour chaque niveau
2. **Motivation** : Livreurs progressent et débloquent privilèges
3. **Flexibilité** : Vendeur peut toujours livrer lui-même si montant élevé
4. **Transparence** : Wallet en temps réel, alertes claires
5. **Adaptée au contexte ivoirien** : Progression douce, pas de barrière à l'entrée

---

**Document créé le** : 12 Décembre 2025
**Auteur** : Analyse sécurité financière livreurs
**Status** : ✅ PRÊT POUR IMPLÉMENTATION
