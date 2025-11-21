# ✅ Modifications Dashboard Vendeur & Livreur - En Cours

**Date:** 13 Novembre 2025
**Status:** ✅ Partie 1 Terminée | 🔄 Partie 2 En Attente

---

## 🎯 Demandes Initiales

### Vendeur Dashboard
1. ✅ Actualiser les données du dashboard pour avoir les vraies données (pas mock)
2. ✅ Corriger le compteur des commandes en attente (affichait 2 au lieu de 0)
3. ✅ Actualisation automatique des données toutes les 15 min (au lieu de 30 sec)
4. ✅ Actualiser la page de détails après action (Confirmer/Préparer)
5. ⏳ Implémenter la page de création de boutique vendeur
6. ⏳ Implémenter la page d'historique des paiements

### Livreur Dashboard
1. ⏳ Actualiser les données réelles du dashboard
2. ⏳ Système de proposition de commandes par distance
3. ⏳ Proposer les commandes les plus proches en priorité

---

## ✅ PARTIE 1 TERMINÉE - Vendeur Dashboard

### 1. Service VendorStatsService Créé ✅

**Fichier:** `lib/services/vendor_stats_service.dart` (242 lignes)

**Fonctionnalités:**
- ✅ Calcul des statistiques réelles depuis Firestore
- ✅ Comptage par statut (pending, confirmed, preparing, ready, in_delivery, delivered, cancelled)
- ✅ Calcul du revenu total et mensuel
- ✅ Comptage des produits (total, actifs)
- ✅ Récupération des commandes récentes avec noms clients

**Classes créées:**
```dart
class VendorStats {
  final int totalOrders;
  final int pendingOrders;
  final int confirmedOrders;
  final int preparingOrders;
  final int readyOrders;
  final int inDeliveryOrders;
  final int deliveredOrders;
  final int cancelledOrders;
  final num totalRevenue;
  final num monthlyRevenue;
  final int totalProducts;
  final int activeProducts;
  final int viewsThisMonth;

  int get activeOrders => ...; // ✅ Commandes actives
  int get completedOrders => deliveredOrders; // ✅ Commandes complétées
}

class RecentOrderData {
  final String id;
  final String orderNumber;
  final String customerName;
  final num amount;
  final String status;
  final DateTime date;
}
```

**Méthodes:**
```dart
// Récupère toutes les statistiques d'un vendeur
Future<VendorStats> getVendorStats(String vendeurId)

// Récupère les N dernières commandes avec infos client
Future<List<RecentOrderData>> getRecentOrders(String vendeurId, {int limit = 5})
```

### 2. Vendeur Dashboard Mis à Jour ✅

**Fichier:** `lib/screens/vendeur/vendeur_dashboard.dart`

**Modifications:**
1. ✅ Import du `VendorStatsService`
2. ✅ Changement de l'intervalle de rafraîchissement: **30 secondes → 15 minutes**
   ```dart
   // AVANT
   final _refreshInterval = const Duration(seconds: 30);

   // APRÈS
   final _refreshInterval = const Duration(minutes: 15); // ✅ 15 minutes
   ```

3. ✅ Remplacement des données mock par des vraies données:
   ```dart
   // AVANT: Données en dur
   _stats = DashboardStats(
     totalSales: 45,
     monthlyRevenue: 2850000,
     totalOrders: 45,
     pendingOrders: 5, // ❌ Incorrect !
     ...
   );

   // APRÈS: Données réelles depuis Firestore
   final vendorStats = await VendorStatsService.getVendorStats(user.id);
   final recentOrders = await VendorStatsService.getRecentOrders(user.id);

   _stats = DashboardStats(
     totalSales: vendorStats.deliveredOrders,
     monthlyRevenue: vendorStats.monthlyRevenue,
     totalOrders: vendorStats.totalOrders,
     pendingOrders: vendorStats.pendingOrders, // ✅ Valeur réelle !
     ...
   );
   ```

4. ✅ Suppression de l'ancienne classe `RecentOrder` (utilise maintenant `RecentOrderData`)

**Résultat:**
- ✅ Le compteur "En attente" affiche maintenant la vraie valeur (0 si aucune commande)
- ✅ Toutes les statistiques sont calculées depuis Firestore
- ✅ Actualisation automatique toutes les 15 minutes (réduit la charge serveur)
- ✅ Commandes récentes avec vrais noms de clients

### 3. Order Detail Screen Corrigé ✅

**Fichier:** `lib/screens/vendeur/order_detail_screen.dart`

**Problème:** Après avoir cliqué sur "Confirmer" ou "Préparer", l'UI ne se mettait pas à jour.

**Solution appliquée:**
```dart
// AVANT
Future<void> _updateStatus(String newStatus) async {
  await OrderService.updateOrderStatus(widget.orderId, newStatus);

  // ❌ Mise à jour locale uniquement
  setState(() {
    _order = _order!.copyWith(
      status: newStatus,
      updatedAt: DateTime.now(),
    );
  });
}

// APRÈS
Future<void> _updateStatus(String newStatus) async {
  await OrderService.updateOrderStatus(widget.orderId, newStatus);

  // ✅ Recharge complète depuis Firestore
  await _loadOrder();

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('✅ Statut mis à jour avec succès'),
      ...
    ),
  );
}
```

**Résultat:**
- ✅ L'UI se met à jour immédiatement après l'action
- ✅ Les boutons disponibles changent en fonction du nouveau statut
- ✅ Message de confirmation affiché
- ✅ Gestion d'erreur améliorée avec try/catch/finally

---

## ⏳ PARTIE 2 - TÂCHES RESTANTES

### A. Page Création de Boutique Vendeur

**Objectif:** Permettre au vendeur de créer/modifier son profil de boutique

**Informations à collecter (selon VendeurProfile):**
- Nom commercial (`businessName`)
- Type d'entreprise (`businessType`: individual/company)
- Description (`businessDescription`)
- Catégorie d'activité (`businessCategory`)
- Adresse commerciale (`businessAddress`)
- Zones de livraison (`deliveryZones`: List<String>)
- Prix de livraison (`deliveryPrice`)
- Seuil livraison gratuite (`freeDeliveryThreshold`)
- Accepte paiement à la livraison (`acceptsCashOnDelivery`)
- Accepte paiement en ligne (`acceptsOnlinePayment`)

**Fichier à créer:** `lib/screens/vendeur/shop_setup_screen.dart`

**Route à ajouter:** `/vendeur/shop-setup`

**Design suggéré:**
1. Formulaire multi-étapes (wizard)
   - Étape 1: Informations de base (nom, type, catégorie)
   - Étape 2: Description et adresse
   - Étape 3: Options de livraison
   - Étape 4: Modes de paiement
   - Étape 5: Récapitulatif et validation

2. Validation:
   - Nom commercial: requis, 3-50 caractères
   - Type: requis (radio buttons)
   - Catégorie: requis (dropdown)
   - Zones de livraison: minimum 1 zone
   - Prix livraison: >= 0

3. Sauvegarde:
   - Mettre à jour `users/{vendeurId}` → `profile.businessName`, etc.
   - Option: Créer collection `shops/{shopId}` pour données étendues

### B. Page Historique des Paiements Vendeur

**Objectif:** Afficher l'historique des paiements reçus par le vendeur

**Informations à afficher:**
- Date du paiement
- Numéro de commande
- Montant
- Méthode de paiement (Mobile Money, Cash, etc.)
- Statut (en attente, validé, remboursé)
- Frais de transaction
- Montant net reçu

**Fichier à créer:** `lib/screens/vendeur/payment_history_screen.dart`

**Route à ajouter:** `/vendeur/payment-history`

**Source des données:**
- Collection `payments` avec `where('vendeurId', isEqualTo: vendeurId)`
- Filtrage par période (semaine, mois, année)
- Tri par date décroissante

**Design suggéré:**
1. Filtres en haut:
   - Période (Aujourd'hui, 7 jours, 30 jours, Tout)
   - Méthode de paiement (Tout, Mobile Money, Cash)
   - Statut (Tout, Validé, En attente)

2. Liste des paiements:
   ```
   [Icon Méthode]  CMD-001 - 45 000 FCFA
                   Orange Money
                   12 Nov 2025, 14:30
                   Statut: ✅ Validé
   ```

3. Card de résumé en haut:
   - Total paiements validés
   - En attente
   - Frais de transaction
   - Net à recevoir

**Modèle à utiliser:** `lib/models/payment_model.dart`

### C. Livreur Dashboard - Données Réelles

**Objectif:** Remplacer les données mock par des vraies données

**Fichier à modifier:** `lib/screens/livreur/livreur_dashboard.dart`

**Service à créer:** `lib/services/livreur_stats_service.dart`

**Statistiques à calculer:**
- Total livraisons
- Livraisons en cours
- Livraisons complétées
- Revenus du jour
- Revenus du mois
- Note moyenne
- Temps moyen de livraison

**Méthode:**
```dart
class LivreurStatsService {
  static Future<LivreurStats> getLivreurStats(String livreurId) async {
    // Charger toutes les livraisons du livreur
    final deliveries = await _firestore
        .collection('deliveries')
        .where('livreurId', isEqualTo: livreurId)
        .get();

    // Calculer les stats...
  }
}
```

### D. Système de Proposition de Commandes par Distance

**Objectif:** Proposer automatiquement les commandes aux livreurs les plus proches

**Complexité:** ⚠️ **ÉLEVÉE** - Nécessite géolocalisation en temps réel

**Approches possibles:**

#### Option 1: Calcul côté client (Simple mais limité)
```dart
// Dans livreur_main_screen.dart
class AvailableOrdersTab extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Position>(
      future: Geolocator.getCurrentPosition(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();

        final livreurPosition = snapshot.data!;

        return StreamBuilder<List<OrderModel>>(
          stream: OrderService.getAvailableOrders(),
          builder: (context, snapshot) {
            final orders = snapshot.data ?? [];

            // Calculer distance pour chaque commande
            final ordersWithDistance = orders.map((order) {
              final distance = Geolocator.distanceBetween(
                livreurPosition.latitude,
                livreurPosition.longitude,
                order.pickupLatitude,
                order.pickupLongitude,
              );
              return (order, distance);
            }).toList();

            // Trier par distance
            ordersWithDistance.sort((a, b) => a.$2.compareTo(b.$2));

            return ListView.builder(...);
          },
        );
      },
    );
  }
}
```

#### Option 2: Cloud Functions (Optimal mais complexe)
- Créer Cloud Function `assignOrderToNearestLivreur`
- Déclenché quand une commande passe à "ready"
- Trouve les 3 livreurs les plus proches disponibles
- Envoie notification push à chacun
- Premier à accepter obtient la commande

**Prérequis:**
1. ✅ Modèle `OrderModel` avec coordonnées GPS
2. ✅ Modèle `DeliveryModel` avec `livreurId`
3. ✅ Collection `users` avec position des livreurs
4. ⏳ System de mise à jour position livreur en temps réel
5. ⏳ Cloud Functions Firebase

**Fichiers à créer:**
- `lib/services/geolocation_service.dart`
- `lib/services/order_assignment_service.dart`
- `lib/screens/livreur/available_orders_screen.dart`

---

## 📊 Résumé des Modifications

### Fichiers Créés (1)
- ✅ `lib/services/vendor_stats_service.dart` (242 lignes)

### Fichiers Modifiés (2)
- ✅ `lib/screens/vendeur/vendeur_dashboard.dart`
  - Ligne 12: Import VendorStatsService
  - Ligne 24: Intervalle 30s → 15min
  - Ligne 28: RecentOrder → RecentOrderData
  - Lignes 94-133: Chargement données réelles
  - Ligne 639: Suppression classe RecentOrder

- ✅ `lib/screens/vendeur/order_detail_screen.dart`
  - Lignes 94-133: Recharge complète après action

### Fichiers à Créer (4)
- ⏳ `lib/screens/vendeur/shop_setup_screen.dart`
- ⏳ `lib/screens/vendeur/payment_history_screen.dart`
- ⏳ `lib/services/livreur_stats_service.dart`
- ⏳ `lib/services/geolocation_service.dart`

### Fichiers à Modifier (2)
- ⏳ `lib/screens/livreur/livreur_dashboard.dart`
- ⏳ `lib/routes/app_router.dart` (ajouter nouvelles routes)

---

## 🧪 Tests à Effectuer

### Tests Vendeur Dashboard ✅
1. ✅ Vérifier que le compteur "En attente" affiche 0 s'il n'y a pas de commandes
2. ✅ Créer une commande de test → Compteur doit s'incrémenter
3. ✅ Confirmer une commande → Compteur "En attente" diminue, "Confirmées" augmente
4. ✅ Attendre 15 minutes → Dashboard doit se rafraîchir automatiquement
5. ✅ Pull-to-refresh → Données doivent se recharger

### Tests Order Detail ✅
1. ✅ Ouvrir détails d'une commande "pending"
2. ✅ Cliquer "Confirmer" → Bouton doit passer de "Confirmer" à "Préparer"
3. ✅ Cliquer "Préparer" → Bouton doit passer de "Préparer" à "Prêt"
4. ✅ Message de confirmation doit s'afficher à chaque action

### Tests à Faire (Page Boutique)
- ⏳ Remplir formulaire boutique → Sauvegarder → Vérifier Firestore
- ⏳ Modifier boutique existante → Vérifier que les données se pré-remplissent
- ⏳ Valider les champs requis

### Tests à Faire (Historique Paiements)
- ⏳ Afficher liste des paiements
- ⏳ Filtrer par période
- ⏳ Vérifier total des revenus

---

## 🎯 Prochaines Étapes

### Immédiat
1. ⏳ Créer `shop_setup_screen.dart` (formulaire création boutique)
2. ⏳ Créer `payment_history_screen.dart` (historique paiements)
3. ⏳ Ajouter routes dans `app_router.dart`
4. ⏳ Ajouter boutons d'accès dans le menu vendeur

### Court Terme
1. ⏳ Créer `livreur_stats_service.dart`
2. ⏳ Mettre à jour `livreur_dashboard.dart` avec vraies données
3. ⏳ Créer `geolocation_service.dart`

### Moyen Terme
1. ⏳ Implémenter système de proposition de commandes par distance
2. ⏳ Créer Cloud Function pour assignment automatique
3. ⏳ Tester avec plusieurs livreurs réels

---

## 📝 Notes Importantes

### Intervalle de Rafraîchissement
- **Avant:** 30 secondes (trop fréquent, charge serveur élevée)
- **Après:** 15 minutes (optimal pour dashboard)
- **Justification:** Les statistiques dashboard changent lentement, pas besoin de rafraîchir toutes les 30 secondes

### Actualisation Manuelle
- Pull-to-refresh toujours disponible pour actualisation immédiate
- Rafraîchissement automatique à la navigation (didChangeDependencies)

### Performance
- VendorStatsService fait 2-3 requêtes Firestore par chargement
- Mise en cache possible pour améliorer performance (TODO futur)
- Considérer pagination pour historique paiements (si > 100 paiements)

---

**Progression:** 3/7 tâches terminées (43%)
**Temps estimé restant:** 4-6 heures de développement

**Dernière mise à jour:** 13 Novembre 2025, 16:30
