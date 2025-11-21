# 🎯 Prochaines Étapes - Dashboard Vendeur & Livreur

**Date:** 13 Novembre 2025
**Progression:** ✅ 57% (4/7 tâches)

---

## ✅ CE QUI A ÉTÉ FAIT

### 1. Dashboard Vendeur - Données Réelles ✅
- Compteur "En attente" corrigé (affiche maintenant 0 si aucune commande)
- Toutes les statistiques viennent de Firestore (plus de mock)
- Actualisation automatique toutes les **15 minutes** (au lieu de 30 secondes)
- Service `VendorStatsService` créé pour calculer les stats

### 2. Page Détails Commande - Actualisation ✅
- L'UI se met maintenant à jour après "Confirmer" ou "Préparer"
- Les boutons changent automatiquement selon le statut
- Message de confirmation affiché

### 3. Page Configuration Boutique ✅
- Formulaire multi-étapes (4 étapes)
- Chargement et modification du profil existant
- Validation complète
- Sauvegarde dans Firestore
- **Route:** `/vendeur/shop-setup`

---

## 🚀 COMMENT TESTER

### Test 1: Dashboard Vendeur
```bash
1. Lancez l'application: flutter run -d chrome
2. Connectez-vous en tant que vendeur
3. Vérifiez que les compteurs affichent les vraies valeurs
4. Pull-to-refresh pour recharger
```

### Test 2: Configuration Boutique
```bash
1. Dashboard vendeur → Cliquez sur "Configurer ma boutique" (à ajouter dans l'UI)
2. OU accédez directement: context.push('/vendeur/shop-setup')
3. Remplissez le formulaire (4 étapes)
4. Sauvegardez
5. Vérifiez dans Firestore: users/{vendeurId}/profile
```

### Ajouter le Bouton d'Accès

Dans `lib/screens/vendeur/vendeur_dashboard.dart`, ajoutez dans l'AppBar ou dans la grille de statistiques :

```dart
// Option 1: Dans l'AppBar
appBar: AppBar(
  title: const Text('Dashboard'),
  actions: [
    IconButton(
      icon: const Icon(Icons.store_outlined),
      onPressed: () => context.push('/vendeur/shop-setup'),
      tooltip: 'Configurer ma boutique',
    ),
    // ... autres actions
  ],
),

// Option 2: Comme card dans la grille
GestureDetector(
  onTap: () => context.push('/vendeur/shop-setup'),
  child: Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Column(
      children: [
        Icon(Icons.store, size: 48, color: Colors.white),
        SizedBox(height: 8),
        Text(
          'Ma Boutique',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ],
    ),
  ),
)
```

---

## ⏳ TÂCHES RESTANTES

### Priorité 1 - Court Terme (2-3h)

#### A. Page Historique des Paiements
**Fichier à créer:** `lib/screens/vendeur/payment_history_screen.dart`

**Fonctionnalités:**
- Liste des paiements reçus
- Filtres par période (Aujourd'hui, 7 jours, 30 jours, Tout)
- Filtres par méthode (Mobile Money, Cash)
- Résumé financier (Total, En attente, Frais)
- Export CSV/PDF (optionnel)

**Code de départ:**
```dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/constants.dart';
import '../../models/payment_model.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  String _selectedPeriod = '30'; // jours
  String _selectedMethod = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des Paiements'),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          _buildFilters(),
          _buildSummaryCards(),
          Expanded(child: _buildPaymentsList()),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    // Filtres période et méthode
  }

  Widget _buildSummaryCards() {
    // Cards résumé financier
  }

  Widget _buildPaymentsList() {
    // StreamBuilder pour la liste des paiements
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(FirebaseCollections.payments)
          .where('vendeurId', isEqualTo: currentUserId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        // Liste des paiements
      },
    );
  }
}
```

**Route à ajouter:**
```dart
// Dans lib/routes/app_router.dart
GoRoute(
  path: '/vendeur/payment-history',
  builder: (context, state) => const PaymentHistoryScreen(),
),
```

### Priorité 2 - Moyen Terme (2-3h)

#### B. Dashboard Livreur - Données Réelles

**Étape 1:** Créer `lib/services/livreur_stats_service.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/delivery_model.dart';
import '../config/constants.dart';

class LivreurStatsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<LivreurStats> getLivreurStats(String livreurId) async {
    try {
      // Charger toutes les livraisons du livreur
      final deliveriesSnapshot = await _firestore
          .collection(FirebaseCollections.deliveries)
          .where('livreurId', isEqualTo: livreurId)
          .get();

      final deliveries = deliveriesSnapshot.docs
          .map((doc) => DeliveryModel.fromFirestore(doc))
          .toList();

      // Calculer les stats
      int totalDeliveries = deliveries.length;
      int pendingDeliveries = 0;
      int inProgressDeliveries = 0;
      int completedDeliveries = 0;
      num totalEarnings = 0;
      num todayEarnings = 0;

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      for (var delivery in deliveries) {
        switch (delivery.status) {
          case 'pending':
            pendingDeliveries++;
            break;
          case 'in_progress':
            inProgressDeliveries++;
            break;
          case 'delivered':
            completedDeliveries++;
            totalEarnings += delivery.deliveryFee;

            if (delivery.deliveredAt?.isAfter(startOfDay) == true) {
              todayEarnings += delivery.deliveryFee;
            }
            break;
        }
      }

      return LivreurStats(
        totalDeliveries: totalDeliveries,
        pendingDeliveries: pendingDeliveries,
        inProgressDeliveries: inProgressDeliveries,
        completedDeliveries: completedDeliveries,
        totalEarnings: totalEarnings,
        todayEarnings: todayEarnings,
      );
    } catch (e) {
      debugPrint('❌ Erreur calcul stats livreur: $e');
      throw Exception('Impossible de calculer les statistiques: $e');
    }
  }
}

class LivreurStats {
  final int totalDeliveries;
  final int pendingDeliveries;
  final int inProgressDeliveries;
  final int completedDeliveries;
  final num totalEarnings;
  final num todayEarnings;

  LivreurStats({
    required this.totalDeliveries,
    required this.pendingDeliveries,
    required this.inProgressDeliveries,
    required this.completedDeliveries,
    required this.totalEarnings,
    required this.todayEarnings,
  });
}
```

**Étape 2:** Mettre à jour `lib/screens/livreur/livreur_dashboard.dart`

Remplacer les données mock par:
```dart
import '../../services/livreur_stats_service.dart';

// Dans _loadDashboardData()
final livreurStats = await LivreurStatsService.getLivreurStats(user.id);

setState(() {
  _totalDeliveries = livreurStats.totalDeliveries;
  _pendingDeliveries = livreurStats.pendingDeliveries;
  _inProgressDeliveries = livreurStats.inProgressDeliveries;
  _completedDeliveries = livreurStats.completedDeliveries;
  _totalEarnings = livreurStats.totalEarnings;
  _todayEarnings = livreurStats.todayEarnings;
});
```

### Priorité 3 - Long Terme (4-6h) - COMPLEXE

#### C. Système de Proposition de Commandes par Distance

**Prérequis:**
1. Permissions géolocalisation configurées
2. FCM (Firebase Cloud Messaging) configuré
3. Packages: `geolocator`, `permission_handler`

**Étape 1:** Créer `lib/services/geolocation_service.dart`

```dart
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class GeolocationService {
  // Vérifier et demander les permissions
  static Future<bool> checkPermissions() async {
    final status = await Permission.location.status;
    if (status.isDenied) {
      final result = await Permission.location.request();
      return result.isGranted;
    }
    return status.isGranted;
  }

  // Obtenir la position actuelle
  static Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await checkPermissions();
      if (!hasPermission) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint('❌ Erreur géolocalisation: $e');
      return null;
    }
  }

  // Calculer la distance entre deux points
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000; // en km
  }

  // Surveiller la position en temps réel
  static Stream<Position> watchPosition() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100, // Mise à jour tous les 100m
      ),
    );
  }
}
```

**Étape 2:** Créer `lib/services/order_assignment_service.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../models/order_model.dart';
import 'geolocation_service.dart';

class OrderAssignmentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtenir les commandes disponibles triées par distance
  static Future<List<OrderWithDistance>> getAvailableOrdersByDistance(
    String livreurId,
  ) async {
    try {
      // Obtenir position du livreur
      final livreurPosition = await GeolocationService.getCurrentPosition();
      if (livreurPosition == null) {
        throw Exception('Position du livreur non disponible');
      }

      // Charger commandes prêtes pour livraison
      final ordersSnapshot = await _firestore
          .collection(FirebaseCollections.orders)
          .where('status', isEqualTo: 'ready')
          .where('livreurId', isNull: true) // Pas encore assignées
          .get();

      final ordersWithDistance = <OrderWithDistance>[];

      for (var doc in ordersSnapshot.docs) {
        final order = OrderModel.fromFirestore(doc);

        // Calculer distance
        // Note: Nécessite que OrderModel ait pickupLatitude et pickupLongitude
        if (order.pickupLatitude != null && order.pickupLongitude != null) {
          final distance = GeolocationService.calculateDistance(
            livreurPosition.latitude,
            livreurPosition.longitude,
            order.pickupLatitude!,
            order.pickupLongitude!,
          );

          ordersWithDistance.add(OrderWithDistance(
            order: order,
            distance: distance,
          ));
        }
      }

      // Trier par distance
      ordersWithDistance.sort((a, b) => a.distance.compareTo(b.distance));

      return ordersWithDistance;
    } catch (e) {
      debugPrint('❌ Erreur récupération commandes: $e');
      throw Exception('Impossible de charger les commandes: $e');
    }
  }

  // Accepter une commande
  static Future<void> acceptOrder(String orderId, String livreurId) async {
    try {
      await _firestore.collection(FirebaseCollections.orders).doc(orderId).update({
        'livreurId': livreurId,
        'status': 'in_delivery',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Créer la livraison
      await _firestore.collection(FirebaseCollections.deliveries).add({
        'orderId': orderId,
        'livreurId': livreurId,
        'status': 'in_progress',
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Commande $orderId acceptée par livreur $livreurId');
    } catch (e) {
      debugPrint('❌ Erreur acceptation commande: $e');
      throw Exception('Impossible d\'accepter la commande: $e');
    }
  }
}

class OrderWithDistance {
  final OrderModel order;
  final double distance; // en km

  OrderWithDistance({
    required this.order,
    required this.distance,
  });
}
```

**Étape 3:** Créer `lib/screens/livreur/available_orders_screen.dart`

```dart
import 'package:flutter/material.dart';
import '../../services/order_assignment_service.dart';
import '../../config/constants.dart';

class AvailableOrdersScreen extends StatefulWidget {
  final String livreurId;

  const AvailableOrdersScreen({
    super.key,
    required this.livreurId,
  });

  @override
  State<AvailableOrdersScreen> createState() => _AvailableOrdersScreenState();
}

class _AvailableOrdersScreenState extends State<AvailableOrdersScreen> {
  List<OrderWithDistance>? _orders;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);

    try {
      final orders = await OrderAssignmentService.getAvailableOrdersByDistance(
        widget.livreurId,
      );

      if (mounted) {
        setState(() {
          _orders = orders;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _acceptOrder(String orderId) async {
    try {
      await OrderAssignmentService.acceptOrder(orderId, widget.livreurId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Commande acceptée !'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadOrders(); // Recharger la liste
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_orders == null || _orders!.isEmpty) {
      return const Center(
        child: Text('Aucune commande disponible pour le moment'),
      );
    }

    return ListView.builder(
      itemCount: _orders!.length,
      itemBuilder: (context, index) {
        final orderWithDistance = _orders![index];
        final order = orderWithDistance.order;
        final distance = orderWithDistance.distance;

        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: distance < 5
                  ? AppColors.success
                  : distance < 10
                      ? AppColors.warning
                      : AppColors.error,
              child: Text(
                '${distance.toStringAsFixed(1)}km',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(order.orderNumber),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Client: ${order.buyerName}'),
                Text('Montant: ${order.totalAmount} FCFA'),
                Text('Adresse: ${order.deliveryAddress}'),
              ],
            ),
            trailing: ElevatedButton(
              onPressed: () => _acceptOrder(order.id),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Accepter'),
            ),
          ),
        );
      },
    );
  }
}
```

**Note IMPORTANTE:** Pour que le système de distance fonctionne, vous devez ajouter `pickupLatitude` et `pickupLongitude` au modèle `OrderModel`.

---

## 📋 CHECKLIST COMPLÈTE

### Fait ✅
- [x] Service VendorStatsService créé
- [x] Dashboard vendeur avec vraies données
- [x] Compteur commandes en attente corrigé
- [x] Actualisation automatique 15 min
- [x] Page détails commande actualisée après action
- [x] Page configuration boutique créée
- [x] Route /vendeur/shop-setup ajoutée

### À Faire ⏳
- [ ] Ajouter bouton "Configurer ma boutique" dans l'UI
- [ ] Créer page historique paiements
- [ ] Ajouter route /vendeur/payment-history
- [ ] Créer service LivreurStatsService
- [ ] Mettre à jour dashboard livreur
- [ ] Créer service GeolocationService
- [ ] Créer service OrderAssignmentService
- [ ] Créer page commandes disponibles livreur
- [ ] Tester système complet avec plusieurs livreurs

---

## 📚 DOCUMENTATION

Tous les détails sont dans:
- `MODIFICATIONS_DASHBOARD_VENDEUR_LIVREUR.md` - Guide complet
- `SESSION_DASHBOARD_COMPLETE.md` - Résumé de session
- `PROCHAINES_ETAPES.md` - Ce document

---

**Besoin d'aide ?** Consultez les guides ou demandez !
