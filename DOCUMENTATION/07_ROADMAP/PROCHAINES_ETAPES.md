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

### Priorité 3 - Moyen Terme (6-8h) - INNOVATION

#### C. Système de Devis (Panier Sauvegardé)

**Objectif:** Permettre aux acheteurs de transformer leur panier en devis pour préserver leur intention d'achat, la partager, la modifier et la transformer en commande ultérieurement.

**Contexte Métier SOCIAL BUSINESS Pro:**
- Les acheteurs en Côte d'Ivoire ont souvent besoin de temps pour réunir les fonds
- Le devis permet de "réserver" mentalement une sélection sans impacter le stock
- Utile pour les achats groupés (familles, associations, entreprises)
- Facilite le partage et la comparaison avant achat

---

##### 📦 Architecture Flutter + Firebase

```
lib/
├── models/
│   └── devis_model.dart              # Modèle de données du devis
├── services/
│   └── devis_service.dart            # CRUD et logique métier devis
├── providers/
│   └── devis_provider.dart           # Gestion d'état (optionnel)
├── screens/
│   └── acheteur/
│       ├── devis_list_screen.dart    # Liste des devis de l'utilisateur
│       ├── devis_detail_screen.dart  # Détail et modification d'un devis
│       └── devis_share_screen.dart   # Partage et export PDF
└── widgets/
    └── devis_card.dart               # Widget réutilisable pour afficher un devis
```

---

##### 🗄️ Modèle de Données Firestore

**Collection: `devis`**

```dart
// lib/models/devis_model.dart

enum DevisStatus {
  brouillon,    // En cours de création
  enregistre,   // Sauvegardé par l'utilisateur
  partage,      // Lien de partage généré
  expire,       // Date d'expiration dépassée
  reconverti,   // Transformé en panier/commande
}

class DevisModel {
  final String id;
  final String reference;           // REF-DEVIS-20250123-001
  final String userId;              // ID de l'acheteur
  final String userName;            // Nom de l'acheteur
  final String? userPhone;          // Téléphone pour contact

  // Articles du devis
  final List<DevisItem> items;

  // Montants
  final double subtotal;            // Sous-total articles
  final double estimatedDeliveryFee;// Frais de livraison estimés
  final double totalEstimate;       // Total estimatif

  // Métadonnées
  final DevisStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? expiresAt;        // Date d'expiration (configurable)
  final String? shareToken;         // Token pour partage sécurisé
  final String? notes;              // Notes de l'utilisateur

  // Traçabilité
  final String? convertedToOrderId; // ID commande si reconverti
  final DateTime? convertedAt;

  // Adresse de livraison préférée (optionnel)
  final Map<String, dynamic>? preferredAddress;
}

class DevisItem {
  final String productId;
  final String productName;
  final String? productImage;
  final String vendeurId;
  final String vendeurName;
  final double priceAtCreation;     // Prix au moment du devis
  final double? currentPrice;       // Prix actuel (pour comparaison)
  final int quantity;
  final String? variant;            // Taille, couleur, etc.
}
```

**Structure Firestore:**
```
devis/
├── {devisId}/
│   ├── id: string
│   ├── reference: string
│   ├── userId: string
│   ├── userName: string
│   ├── userPhone: string?
│   ├── items: array<DevisItem>
│   ├── subtotal: number
│   ├── estimatedDeliveryFee: number
│   ├── totalEstimate: number
│   ├── status: string (brouillon|enregistre|partage|expire|reconverti)
│   ├── createdAt: timestamp
│   ├── updatedAt: timestamp
│   ├── expiresAt: timestamp?
│   ├── shareToken: string?
│   ├── notes: string?
│   ├── convertedToOrderId: string?
│   ├── convertedAt: timestamp?
│   └── preferredAddress: map?
```

---

##### ⚙️ Services Firebase

**`lib/services/devis_service.dart`**

```dart
class DevisService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ========== CRÉATION ==========

  /// Transformer le panier en devis
  static Future<DevisModel> createDevisFromCart({
    required String userId,
    required List<CartItem> cartItems,
    String? notes,
    int expirationDays = 30, // Par défaut 30 jours
  }) async {
    // 1. Générer référence unique
    final reference = await _generateReference();

    // 2. Calculer les totaux
    final subtotal = cartItems.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
    final estimatedDeliveryFee = await _estimateDeliveryFee(cartItems);

    // 3. Créer le document
    final devisData = {
      'reference': reference,
      'userId': userId,
      'userName': await _getUserName(userId),
      'items': cartItems.map((item) => {
        'productId': item.productId,
        'productName': item.productName,
        'productImage': item.productImage,
        'vendeurId': item.vendeurId,
        'vendeurName': item.vendeurName,
        'priceAtCreation': item.price,
        'quantity': item.quantity,
      }).toList(),
      'subtotal': subtotal,
      'estimatedDeliveryFee': estimatedDeliveryFee,
      'totalEstimate': subtotal + estimatedDeliveryFee,
      'status': 'enregistre',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(
        DateTime.now().add(Duration(days: expirationDays))
      ),
      'notes': notes,
    };

    final docRef = await _firestore.collection('devis').add(devisData);

    // 4. Logger l'action
    await AuditService.logAction(
      userId: userId,
      action: 'devis_created',
      actionLabel: 'Devis créé',
      category: AuditCategory.userAction,
      targetType: 'devis',
      targetId: docRef.id,
      metadata: {'reference': reference, 'total': subtotal},
    );

    return DevisModel.fromMap({...devisData, 'id': docRef.id});
  }

  // ========== LECTURE ==========

  /// Obtenir les devis d'un utilisateur
  static Stream<List<DevisModel>> getUserDevis(String userId) {
    return _firestore
        .collection('devis')
        .where('userId', isEqualTo: userId)
        .where('status', whereNotIn: ['expire', 'reconverti'])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DevisModel.fromFirestore(doc))
            .toList());
  }

  /// Obtenir un devis par son token de partage (accès public)
  static Future<DevisModel?> getDevisByShareToken(String token) async {
    final snapshot = await _firestore
        .collection('devis')
        .where('shareToken', isEqualTo: token)
        .where('status', isEqualTo: 'partage')
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return DevisModel.fromFirestore(snapshot.docs.first);
  }

  // ========== MODIFICATION ==========

  /// Modifier un devis (articles, quantités)
  static Future<void> updateDevis({
    required String devisId,
    List<DevisItem>? items,
    String? notes,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (items != null) {
      updates['items'] = items.map((i) => i.toMap()).toList();
      // Recalculer les totaux
      final subtotal = items.fold(0.0, (sum, item) => sum + (item.priceAtCreation * item.quantity));
      updates['subtotal'] = subtotal;
      updates['totalEstimate'] = subtotal + /* delivery fee */;
    }

    if (notes != null) updates['notes'] = notes;

    await _firestore.collection('devis').doc(devisId).update(updates);
  }

  /// Supprimer un devis
  static Future<void> deleteDevis(String devisId) async {
    await _firestore.collection('devis').doc(devisId).delete();
  }

  // ========== PARTAGE ==========

  /// Générer un lien de partage sécurisé
  static Future<String> generateShareLink(String devisId) async {
    final token = _generateSecureToken();

    await _firestore.collection('devis').doc(devisId).update({
      'shareToken': token,
      'status': 'partage',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Format: https://socialbusinesspro.ci/devis?token=xxxxx
    return 'https://socialbusinesspro.ci/devis?token=$token';
  }

  // ========== CONVERSION ==========

  /// Reconvertir un devis en panier
  static Future<void> convertDevisToCart({
    required String devisId,
    required String userId,
    required CartProvider cartProvider,
  }) async {
    // 1. Charger le devis
    final devisDoc = await _firestore.collection('devis').doc(devisId).get();
    final devis = DevisModel.fromFirestore(devisDoc);

    // 2. Vérifier disponibilité des produits et prix actuels
    final validItems = <CartItem>[];
    final priceChanges = <String, Map<String, double>>{};

    for (final item in devis.items) {
      final productDoc = await _firestore
          .collection('products')
          .doc(item.productId)
          .get();

      if (!productDoc.exists) continue;

      final product = ProductModel.fromFirestore(productDoc);

      // Vérifier le stock
      if (product.availableStock < item.quantity) {
        // Stock insuffisant - ajuster ou ignorer
        continue;
      }

      // Détecter changement de prix
      if (product.price != item.priceAtCreation) {
        priceChanges[item.productId] = {
          'ancien': item.priceAtCreation,
          'nouveau': product.price,
        };
      }

      validItems.add(CartItem(
        productId: item.productId,
        productName: product.name,
        price: product.price, // Prix ACTUEL
        quantity: item.quantity,
        // ... autres champs
      ));
    }

    // 3. Ajouter au panier
    for (final item in validItems) {
      await cartProvider.addItem(item);
    }

    // 4. Marquer le devis comme reconverti
    await _firestore.collection('devis').doc(devisId).update({
      'status': 'reconverti',
      'convertedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 5. Retourner info sur changements de prix si nécessaire
    if (priceChanges.isNotEmpty) {
      // Notifier l'utilisateur des changements de prix
    }
  }

  // ========== UTILITAIRES ==========

  static Future<String> _generateReference() async {
    final date = DateTime.now();
    final dateStr = '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';

    // Compteur journalier
    final counterDoc = await _firestore
        .collection('counters')
        .doc('devis_$dateStr')
        .get();

    final count = (counterDoc.data()?['count'] ?? 0) + 1;

    await _firestore
        .collection('counters')
        .doc('devis_$dateStr')
        .set({'count': count});

    return 'DEV-$dateStr-${count.toString().padLeft(3, '0')}';
  }

  static String _generateSecureToken() {
    // Génère un token sécurisé de 32 caractères
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(values).substring(0, 32);
  }
}
```

---

##### 🎨 Flow UX Flutter

**1. Depuis le Panier (cart_screen.dart):**
```
[Panier avec articles]
       │
       ├── [Bouton "Commander"] → Checkout normal
       │
       └── [Bouton "Enregistrer en devis"]
              │
              ├── Dialog confirmation
              │     "Voulez-vous transformer ce panier en devis ?
              │      Le devis sera valable 30 jours.
              │      ⚠️ Devis non engageant - prix susceptibles de changer"
              │
              └── → Création devis
                    → Notification succès
                    → Option: Vider le panier ou le conserver
```

**2. Écran Liste des Devis (devis_list_screen.dart):**
```
[AppBar: Mes Devis]
       │
       ├── [Card Devis 1]
       │     ├── Référence: DEV-20250123-001
       │     ├── 3 articles - 45 000 FCFA
       │     ├── Créé le 23/01/2025
       │     ├── Expire dans 25 jours
       │     └── [Actions: Voir | Partager | Supprimer]
       │
       ├── [Card Devis 2]
       │     └── ...
       │
       └── [FAB: Nouveau devis depuis panier]
```

**3. Écran Détail Devis (devis_detail_screen.dart):**
```
[AppBar: Devis DEV-20250123-001]
       │
       ├── [Section: Statut]
       │     └── Badge: Enregistré | Partagé | etc.
       │
       ├── [Section: Articles]
       │     ├── [Article 1] - Quantité: 2 - 10 000 FCFA
       │     │     └── [Boutons: +/- quantité | Supprimer]
       │     ├── [Article 2] - Quantité: 1 - 25 000 FCFA
       │     │     └── ⚠️ Prix modifié: était 22 000 FCFA
       │     └── [Article 3] ...
       │
       ├── [Section: Totaux]
       │     ├── Sous-total: 45 000 FCFA
       │     ├── Livraison (estimée): 2 000 FCFA
       │     └── TOTAL ESTIMATIF: 47 000 FCFA
       │
       ├── [Section: Notes]
       │     └── [TextField éditable]
       │
       └── [Actions en bas]
             ├── [Bouton: Reconvertir en panier] (primaire)
             ├── [Bouton: Partager] (secondaire)
             └── [Bouton: Exporter PDF] (tertiaire)
```

**4. Partage et Export:**
```
[Dialog Partage]
       │
       ├── [Lien de partage]
       │     └── https://socialbusinesspro.ci/devis?token=xxx
       │         [Bouton: Copier]
       │
       ├── [Partager via]
       │     ├── WhatsApp
       │     ├── SMS
       │     └── Email
       │
       └── [Exporter PDF]
             └── Génère un PDF avec:
                   - Logo SOCIAL BUSINESS Pro
                   - Référence du devis
                   - Liste détaillée des articles
                   - Mention "Devis non engageant"
                   - Date de validité
```

---

##### 📱 Routes à Ajouter

```dart
// Dans lib/routes/app_router.dart

// Liste des devis
GoRoute(
  path: '/acheteur/devis',
  builder: (context, state) => const DevisListScreen(),
),

// Détail d'un devis
GoRoute(
  path: '/acheteur/devis/:devisId',
  builder: (context, state) => DevisDetailScreen(
    devisId: state.pathParameters['devisId']!,
  ),
),

// Devis partagé (accès public avec token)
GoRoute(
  path: '/devis-partage',
  builder: (context, state) => SharedDevisScreen(
    token: state.uri.queryParameters['token'] ?? '',
  ),
),
```

---

##### 🔔 Notifications (Optionnel)

- **Expiration proche:** "Votre devis DEV-xxx expire dans 3 jours"
- **Prix modifié:** "Un article de votre devis a changé de prix"
- **Produit indisponible:** "Un article de votre devis n'est plus disponible"

---

##### ⚡ Règles Firestore

```javascript
// Dans firestore.rules

// ===== DEVIS COLLECTION =====
match /devis/{devisId} {
  // Lecture: propriétaire ou via token de partage
  allow read: if isAuthenticated() &&
                 (resource.data.userId == request.auth.uid ||
                  resource.data.shareToken != null);

  // Création: utilisateur authentifié pour lui-même
  allow create: if isAuthenticated() &&
                   request.resource.data.userId == request.auth.uid;

  // Modification: propriétaire uniquement
  allow update: if isAuthenticated() &&
                   resource.data.userId == request.auth.uid;

  // Suppression: propriétaire ou admin
  allow delete: if isAuthenticated() &&
                   (resource.data.userId == request.auth.uid || isAdmin());
}
```

---

##### ✅ Checklist Implémentation Devis

- [ ] Créer `lib/models/devis_model.dart`
- [ ] Créer `lib/services/devis_service.dart`
- [ ] Ajouter règles Firestore pour collection `devis`
- [ ] Créer `lib/screens/acheteur/devis_list_screen.dart`
- [ ] Créer `lib/screens/acheteur/devis_detail_screen.dart`
- [ ] Créer `lib/widgets/devis_card.dart`
- [ ] Ajouter bouton "Transformer en devis" dans `cart_screen.dart`
- [ ] Ajouter entrée "Mes Devis" dans le menu/drawer acheteur
- [ ] Implémenter génération PDF (package `pdf`, `printing`)
- [ ] Implémenter partage (package `share_plus`)
- [ ] Ajouter notifications d'expiration
- [ ] Tester flow complet: panier → devis → modification → reconversion
- [ ] Gérer les cas edge: prix modifiés, stock insuffisant, produit supprimé

---

### Priorité 4 - Long Terme (4-6h) - COMPLEXE

#### D. Système de Proposition de Commandes par Distance

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

#### Priorité 1-2: Dashboard & Paiements
- [ ] Ajouter bouton "Configurer ma boutique" dans l'UI
- [ ] Créer page historique paiements
- [ ] Ajouter route /vendeur/payment-history
- [ ] Créer service LivreurStatsService
- [ ] Mettre à jour dashboard livreur

#### Priorité 3: Système de Devis (NOUVEAU)
- [ ] Créer `lib/models/devis_model.dart`
- [ ] Créer `lib/services/devis_service.dart`
- [ ] Ajouter règles Firestore pour collection `devis`
- [ ] Créer `lib/screens/acheteur/devis_list_screen.dart`
- [ ] Créer `lib/screens/acheteur/devis_detail_screen.dart`
- [ ] Créer `lib/widgets/devis_card.dart`
- [ ] Ajouter bouton "Transformer en devis" dans `cart_screen.dart`
- [ ] Ajouter entrée "Mes Devis" dans le drawer acheteur
- [ ] Implémenter génération PDF (package `pdf`, `printing`)
- [ ] Implémenter partage (package `share_plus`)
- [ ] Ajouter notifications d'expiration
- [ ] Tester flow complet: panier → devis → reconversion

#### Priorité 4: Proposition par Distance
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
