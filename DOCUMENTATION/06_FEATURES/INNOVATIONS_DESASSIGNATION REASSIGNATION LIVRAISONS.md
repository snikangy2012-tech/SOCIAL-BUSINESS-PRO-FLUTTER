# INNOVATIONS PLANIFIÉES - SOCIAL BUSINESS Pro

Document de référence pour les futures améliorations de la plateforme.

---

## 🚀 PRIORITÉ 1: Système de Désassignation Livreur (En cours)

### Contexte
Permettre aux livreurs de se désassigner d'une livraison avant récupération du colis, avec contrôles anti-abus liés aux tiers d'abonnement.

### Architecture par Abonnement

#### STARTER (Gratuit) - Mode Très Stricte
- ❌ **1 désassignation/jour maximum**
- ❌ **Raison obligatoire** via dropdown:
  - Imprévu urgent
  - Distance trop grande
  - Indisponibilité soudaine
  - Autre (avec commentaire)
- ❌ **Limite mensuelle**: 5 désassignations en 30 jours → Révision compte admin
- 📉 **Pénalité**: -10 points de fiabilité par désassignation
- 🚫 **Blocage**: 24h après 2 désassignations dans la même journée
- 📊 **Impact**: Priorité réduite dans algorithme d'auto-assignation

#### PRO (10k FCFA/mois) - Mode Stricte mais Raisonnable
- ✅ **2 désassignations/jour maximum**
- ⚠️ **Raison suggérée** (optionnelle mais encouragée pour statistiques)
- ⚠️ **Limite hebdomadaire**: 3 désassignations en 7 jours → Suspension 24h
- 📉 **Pénalité**: -5 points de fiabilité par désassignation
- 🔄 **Récupération**: +2 points par livraison complétée avec succès
- 📈 **Priorité**: Maintenue tant que score > 70

#### PREMIUM (30k FCFA/mois) - Mode Souple
- ✅ **3 désassignations/jour maximum**
- 📝 **Pas de raison obligatoire**
- 📊 **Pénalité minimale**: -3 points de fiabilité seulement
- 🎯 **Priorité maintenue** dans algorithme même avec désassignations
- ⏱️ **Récupération rapide**: +3 points par livraison complétée
- ✨ **BONUS PREMIUM**: 1 désassignation "gratuite" sans pénalité par semaine
- 💎 **Avantage**: Pas de suspension automatique (sauf abus flagrant)

### Structure Firestore à Ajouter

```javascript
// Collection: livreur_subscriptions/{livreurId}
{
  // Champs existants
  'tier': 'STARTER' | 'PRO' | 'PREMIUM',
  'price': 0 | 10000 | 30000,
  'status': 'active' | 'inactive',

  // NOUVEAUX CHAMPS pour désassignation
  'unassignmentLimits': {
    'dailyMax': 1,              // Selon tier: 1/2/3
    'dailyCount': 0,            // Reset à minuit
    'weeklyCount': 0,           // Reset chaque lundi
    'monthlyCount': 0,          // Reset 1er du mois
    'lastUnassignmentDate': Timestamp,
    'lastResetDate': Timestamp,
    'requiresReason': true,     // true pour STARTER, false pour PREMIUM
  },

  'reliabilityScore': {
    'current': 100,             // Score initial (max 100)
    'penaltyPerUnassignment': 10, // 10 STARTER, 5 PRO, 3 PREMIUM
    'bonusPerDelivery': 1,      // 1 STARTER, 2 PRO, 3 PREMIUM
    'weeklyFreeUnassignment': false, // PREMIUM only
    'lastFreeUnassignmentUsed': Timestamp,
    'history': [
      {
        'date': Timestamp,
        'action': 'unassignment' | 'delivery_completed',
        'scoreChange': -10,
        'scoreBefore': 100,
        'scoreAfter': 90,
        'reason': 'Imprévu urgent'
      }
    ]
  },

  'suspensionStatus': {
    'isSuspended': false,
    'suspensionUntil': null,
    'suspensionReason': '',
    'suspensionCount': 0
  },

  'statistics': {
    'totalUnassignments': 0,
    'totalDeliveries': 0,
    'completionRate': 100.0,    // % de livraisons complétées sans désassignation
    'averageResponseTime': 0     // Temps moyen avant acceptation/refus
  }
}
```

### Nouveau Service à Créer

**Fichier**: `lib/services/delivery_unassignment_service.dart`

**Méthodes principales**:
```dart
class DeliveryUnassignmentService {
  /// Vérifier si le livreur peut se désassigner
  static Future<Map<String, dynamic>> canUnassign({
    required String livreurId,
    required String deliveryId,
  });

  /// Demander une désassignation
  static Future<void> requestUnassignment({
    required String deliveryId,
    required String livreurId,
    String? reason,  // Obligatoire pour STARTER
  });

  /// Appliquer les pénalités de score
  static Future<void> applyUnassignmentPenalty({
    required String livreurId,
    required String tier,
  });

  /// Vérifier et appliquer les suspensions automatiques
  static Future<void> checkAndApplySuspension({
    required String livreurId,
  });

  /// Reset des compteurs (à exécuter via Cloud Function)
  static Future<void> resetDailyCounters();
  static Future<void> resetWeeklyCounters();
  static Future<void> resetMonthlyCounters();

  /// Auto-réassigner la livraison à un autre livreur
  static Future<void> autoReassignDelivery({
    required String deliveryId,
    required String previousLivreurId,
  });
}
```

### UI à Créer/Modifier

#### 1. **delivery_detail_screen.dart** (Livreur)
- Bouton "Se désassigner" visible uniquement si:
  - Statut = `assigned`
  - N'a pas encore `picked_up` le colis
- Badge indiquant: "Désassignations: 2/3 restantes aujourd'hui"
- Couleur adaptée au tier:
  - STARTER: Gris + warning icon
  - PRO: Bleu
  - PREMIUM: Or/doré
- Dialog de confirmation avec:
  - Raison (dropdown pour STARTER, optionnel pour PRO/PREMIUM)
  - Warning sur pénalité de score
  - Compteur restant

#### 2. **livreur_profile_screen.dart**
- Section "Score de Fiabilité":
  - Jauge visuelle (0-100)
  - Historique des 10 dernières actions (désassignations/livraisons)
  - Impact sur priorité d'assignation
- Section "Statistiques de Désassignation":
  - Aujourd'hui: X/Y
  - Cette semaine: X/Y
  - Ce mois: X/Y
  - Taux de complétion: XX%

#### 3. **sale_detail_screen.dart** (Vendeur) ✅ DÉJÀ IMPLÉMENTÉ
- ✅ Bouton "Annuler cette commande" (si pas de livreur assigné)
- À AJOUTER:
  - Notification visuelle si livreur se désassigne
  - Historique des désassignations pour cette commande
  - Statut de ré-assignation automatique

#### 4. **admin Dashboard** (À créer)
- Écran "Gestion des Livreurs":
  - Filtre par score de fiabilité (< 70, 70-85, > 85)
  - Liste des livreurs en suspension
  - Statistiques de désassignation par livreur
  - Action: Réinitialiser score, lever suspension

### Workflow Complet

```
1. Livreur clique "Se désassigner" dans delivery_detail_screen
   ↓
2. Vérification:
   - Limite quotidienne atteinte?
   - Livreur suspendu?
   - Statut livraison = assigned?
   ↓
3. Dialog de confirmation:
   - Raison (si STARTER)
   - Warning pénalité
   - Bouton "Confirmer la désassignation"
   ↓
4. Traitement backend:
   - Mettre deliveryId.livreurId = null
   - Mettre deliveryId.status = 'available'
   - Incrémenter compteurs (daily/weekly/monthly)
   - Appliquer pénalité score
   - Vérifier suspension automatique
   - Logger dans audit_logs
   ↓
5. Notification vendeur:
   - Push: "Le livreur s'est désassigné de la commande #XXX"
   - Email (optionnel)
   ↓
6. Auto-réassignation:
   - Exécuter DeliveryService.autoAssignDeliveryToOrder()
   - Notifier nouveau livreur
   - Notifier vendeur du nouveau livreur
   ↓
7. Feedback livreur:
   - SnackBar: "Désassignation effectuée. Score: -X points"
   - Mise à jour UI (compteur restant)
```

### Cloud Functions à Créer (Firebase)

```javascript
// functions/index.js

// Reset quotidien à minuit (Africa/Abidjan timezone)
exports.resetDailyUnassignmentCounters = functions.pubsub
  .schedule('0 0 * * *')
  .timeZone('Africa/Abidjan')
  .onRun(async (context) => {
    // Reset tous les dailyCount à 0
  });

// Reset hebdomadaire (lundi 00:00)
exports.resetWeeklyUnassignmentCounters = functions.pubsub
  .schedule('0 0 * * 1')
  .timeZone('Africa/Abidjan')
  .onRun(async (context) => {
    // Reset tous les weeklyCount à 0
  });

// Reset mensuel (1er du mois 00:00)
exports.resetMonthlyUnassignmentCounters = functions.pubsub
  .schedule('0 0 1 * *')
  .timeZone('Africa/Abidjan')
  .onRun(async (context) => {
    // Reset tous les monthlyCount à 0
  });
```

### Tests à Effectuer

1. **Test STARTER**:
   - Désassignation sans raison → Erreur
   - 2 désassignations même jour → Blocage 24h
   - 5 désassignations en 30j → Flag admin

2. **Test PRO**:
   - 3 désassignations en 7j → Suspension 24h
   - Vérifier récupération +2 points par livraison

3. **Test PREMIUM**:
   - Utiliser désassignation gratuite hebdomadaire
   - Vérifier pas de suspension automatique
   - 4 désassignations même jour → Devrait passer (3 max + warnings seulement)

4. **Test auto-réassignation**:
   - Vérifier nouveau livreur reçoit notification
   - Vérifier vendeur informé du changement
   - Vérifier algorithme évite le livreur qui vient de se désassigner

### Avantages Business

- 💰 **Monétisation**: Incitation forte à upgrade PRO/PREMIUM
- 📈 **Qualité**: Livreurs sérieux paient pour flexibilité
- ⚖️ **Équité**: Pas d'interdiction totale, mais contrôle des abus
- 📊 **Data**: Statistiques pour identifier livreurs problématiques
- 🎯 **Rétention**: PREMIUM = expérience premium réelle

---

## 🔧 AUTRES INNOVATIONS PLANIFIÉES

### 1. Système de Notation Multi-critères
- Note globale (1-5 étoiles)
- Critères détaillés:
  - Rapidité
  - Qualité emballage
  - Communication
  - État du colis
- Filtrage vendeurs/livreurs par note minimale

### 2. Programme de Fidélité Acheteurs
- Points par achat (1% montant)
- Bonus parrainage
- Paliers: Bronze/Argent/Or/Platine
- Avantages: livraison gratuite, réductions

### 3. Chat Temps Réel
- Vendeur ↔ Acheteur
- Livreur ↔ Acheteur (pendant livraison)
- Livreur ↔ Vendeur (ramassage)
- Firebase Cloud Messaging + Firestore

### 4. Paiement Fractionné
- Payer en 2-3 fois sans frais
- Partenariat Wave/Orange Money
- Validation crédit simple (historique achats)

### 5. Mode Sombre (Dark Mode)
- Switch dans paramètres
- Sauvegarde préférence utilisateur
- Adaptation complète UI

### 6. Notifications Push Avancées
- Par catégorie (commandes, promos, messages)
- Personnalisation fréquence
- Quiet hours (pas de notif 22h-7h)

### 7. Analytics Vendeur
- Dashboard ventes (jour/semaine/mois)
- Produits les plus vendus
- Heures de pointe
- Suggestions stock

### 8. Système de Réclamations
- Formulaire structuré
- Suivi ticket
- SLA réponse admin (24h)
- Résolution guidée

### 9. Marketplace B2B
- Section "Vendeurs Pros"
- Commandes en gros
- Facturation automatique
- Conditions de paiement (NET 30)

### 10. Géofencing Intelligent
- Alertes si livreur sort de zone prévue
- Optimisation itinéraire multi-livraisons
- Prédiction ETA dynamique

---

## 📋 ROADMAP RECOMMANDÉE

### Phase 1 (Immédiat - Q1 2025)
1. ✅ Système désassignation livreur (EN COURS)
2. Chat temps réel basique
3. Mode sombre

### Phase 2 (Q2 2025)
4. Programme fidélité acheteurs
5. Notation multi-critères
6. Analytics vendeur

### Phase 3 (Q3 2025)
7. Paiement fractionné
8. Système réclamations
9. Géofencing intelligent

### Phase 4 (Q4 2025)
10. Marketplace B2B
11. Notifications push avancées
12. API publique pour intégrations tierces

---

## 📝 NOTES IMPORTANTES

- Toujours tester en environnement staging avant production
- Documenter chaque nouvelle feature dans CLAUDE.md
- Créer tests unitaires pour services critiques
- Suivre métriques d'adoption (Firebase Analytics)
- Recueillir feedback utilisateurs (enquêtes in-app)

---

**Dernière mise à jour**: 30 Décembre 2024
**Statut**: Document vivant - à mettre à jour après chaque sprint
