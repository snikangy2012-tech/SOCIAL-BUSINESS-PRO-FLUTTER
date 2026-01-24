# 🇨🇮 TODO - EXPANSION NATIONALE : Système de livraison multi-villes

## 📋 Vue d'ensemble

**Objectif** : Transformer l'application d'une plateforme centrée sur Abidjan en une solution e-commerce **nationale** couvrant toutes les villes de Côte d'Ivoire.

**Différenciation** : La plupart des plateformes e-commerce ivoiriennes se limitent à Abidjan. SOCIAL BUSINESS Pro sera la première à offrir une couverture nationale complète.

---

## 🎯 Phase 1 : Configuration des zones de livraison par ville

### 1.1 Structure de données : Villes et Communes de Côte d'Ivoire

**Fichier à créer** : `lib/config/ci_locations.dart`

**Structure hiérarchique** :
```
Côte d'Ivoire
├── Abidjan (Chef-lieu économique)
│   ├── Abobo
│   ├── Adjamé
│   ├── Attecoubé
│   ├── Cocody
│   ├── Koumassi
│   ├── Marcory
│   ├── Plateau
│   ├── Port-Bouët
│   ├── Treichville
│   ├── Yopougon
│   ├── Bingerville
│   ├── Songon
│   └── Anyama
│
├── Yamoussoukro (Capitale politique)
│   ├── Commune de Yamoussoukro
│   └── Sous-préfectures environnantes
│
├── Bouaké (2ème ville)
│   ├── Bouaké Centre
│   ├── Dar Es Salam
│   ├── Koko
│   └── ...
│
├── San-Pédro (Port)
├── Daloa
├── Korhogo
├── Man
├── Gagnoa
├── Divo
└── ... (autres villes importantes)
```

### 1.2 Interface de sélection pour les vendeurs

**Écran** : `shop_setup_screen.dart` - Section "Zones de livraison"

**UI/UX proposée** :

```
┌─────────────────────────────────────────┐
│  📍 Zones de livraison                  │
├─────────────────────────────────────────┤
│                                         │
│  Sélectionnez les villes où vous       │
│  pouvez livrer :                        │
│                                         │
│  [x] Abidjan (10 communes sélectionnées)│
│      └─ [x] Cocody                      │
│      └─ [x] Plateau                     │
│      └─ [x] Marcory                     │
│      └─ [ ] Abobo                       │
│      └─ [ ] Adjamé                      │
│      └─ ... (liste déroulante)          │
│                                         │
│  [ ] Yamoussoukro (0/2 communes)        │
│  [ ] Bouaké (0/4 communes)              │
│  [ ] San-Pédro (0/3 communes)           │
│  [+] Ajouter d'autres villes...         │
│                                         │
└─────────────────────────────────────────┘
```

**Fonctionnalités** :
- ✅ Sélection de villes (accordion/expansion panels)
- ✅ Sélection de communes par ville (checkboxes)
- ✅ Compteur de communes sélectionnées
- ✅ Recherche de ville/commune
- ✅ "Tout sélectionner" / "Tout désélectionner" par ville

### 1.3 Calcul de frais de livraison inter-villes

**Service** : `delivery_service.dart`

**Logique de tarification** :

```dart
// Tarification actuelle (Abidjan uniquement)
if (distance <= 10) return 1000 FCFA
if (distance <= 20) return 1500 FCFA
if (distance <= 30) return 2000 FCFA
return 2000 + (distance - 30) * 100

// Nouvelle tarification (National)
1. Même commune : tarif de base (1000-2000 FCFA selon distance)
2. Même ville, autre commune : tarif de base + 500 FCFA
3. Autre ville, même région : tarif de base + forfait inter-villes (3000-5000 FCFA)
4. Autre région : tarif de base + forfait longue distance (5000-15000 FCFA)
```

**Nouveaux champs OrderModel** :
```dart
class OrderModel {
  // ... champs existants

  // Nouveaux champs pour livraison nationale
  String? deliveryCity;           // Ville de livraison
  String? deliveryCommune;        // Commune de livraison
  String? shopCity;               // Ville de la boutique
  String? shopCommune;            // Commune de la boutique
  bool isInterCity;               // Livraison inter-villes ?
  double interCityFee;            // Frais supplémentaires inter-villes
}
```

---

## 🎯 Phase 2 : Système de livreurs régionaux

### 2.1 Profil livreur étendu

**Ajouts au profil livreur** :
```dart
class LivreurProfile {
  // ... champs existants

  // Nouveaux champs
  String primaryCity;                    // Ville principale d'opération
  List<String> operatingCities;          // Villes où il opère
  List<String> operatingCommunes;        // Communes précises
  bool acceptsInterCityDeliveries;       // Accepte livraisons inter-villes ?
  Map<String, double> interCityRates;    // Tarifs par destination
}
```

### 2.2 Affectation intelligente des livreurs

**Algorithme d'affectation** :
1. Priorité 1 : Livreur dans la même commune que la boutique ET la destination
2. Priorité 2 : Livreur dans la même ville
3. Priorité 3 : Livreur acceptant les livraisons inter-villes vers la destination
4. Fallback : Notification manuelle / système d'enchères

---

## 🎯 Phase 3 : Filtrage et recherche géolocalisée

### 3.1 Recherche de produits par ville

**Écran acheteur** : Ajout d'un filtre de localisation

```
┌─────────────────────────────────────────┐
│  🔍 Rechercher un produit...            │
│  📍 Ma ville : Abidjan, Cocody ▼        │
│                                         │
│  Filtres :                              │
│  [ ] Livraison dans ma commune          │
│  [ ] Livraison dans ma ville            │
│  [x] Livraison dans toute la CI         │
└─────────────────────────────────────────┘
```

### 3.2 Affichage des vendeurs par proximité

**ProductCard** : Badge de localisation
```
┌────────────────────┐
│  [Photo produit]   │
│  📍 Cocody, Abidjan│  ← Badge de localisation
│  Nom du produit    │
│  5000 FCFA         │
└────────────────────┘
```

---

## 🎯 Phase 4 : Système d'expédition inter-villes (Future)

### 4.1 Partenariats avec transporteurs

**Transporteurs potentiels** :
- UTB (Union des Transports de Bouaké)
- Gare routière d'Adjamé
- Services de messagerie privés

### 4.2 Points relais par ville

**Concept** : Points de collecte/livraison dans chaque ville
- Boutique partenaire
- Agence de transport
- Gare routière

**OrderModel** :
```dart
enum DeliveryMode {
  homeDelivery,      // Livraison à domicile
  pickupPoint,       // Point relais
  expeditionService  // Service d'expédition inter-villes
}
```

---

## 📊 Données requises

### Villes prioritaires (Top 20)
1. **Abidjan** (13 communes) - Économique
2. **Yamoussoukro** - Capitale
3. **Bouaké** - Centre
4. **San-Pédro** - Port Ouest
5. **Daloa** - Centre-Ouest
6. **Korhogo** - Nord
7. **Man** - Ouest montagneux
8. **Gagnoa** - Centre-Ouest
9. **Divo** - Sud
10. **Abengourou** - Est
11. **Grand-Bassam** - Sud-Est
12. **Soubré** - Sud-Ouest
13. **Bondoukou** - Nord-Est
14. **Dimbokro** - Centre
15. **Agboville** - Sud
16. **Odienné** - Nord-Ouest
17. **Ferkessédougou** - Nord
18. **Adzopé** - Sud-Est
19. **Séguéla** - Nord-Ouest
20. **Dabou** - Sud

### Format de données recommandé

```json
{
  "cities": [
    {
      "id": "abidjan",
      "name": "Abidjan",
      "type": "ville",
      "region": "Lagunes",
      "latitude": 5.3599517,
      "longitude": -4.0082563,
      "communes": [
        {
          "id": "cocody",
          "name": "Cocody",
          "postalCode": "01",
          "latitude": 5.3476,
          "longitude": -3.9877
        },
        // ... autres communes
      ]
    },
    // ... autres villes
  ]
}
```

---

## 🔧 Implémentation technique

### Fichiers à créer/modifier

**Nouveaux fichiers** :
- [ ] `lib/config/ci_locations.dart` - Données villes/communes
- [ ] `lib/models/city_model.dart` - Modèle Ville
- [ ] `lib/models/commune_model.dart` - Modèle Commune
- [ ] `lib/widgets/city_selector.dart` - Widget sélection villes
- [ ] `lib/widgets/commune_selector.dart` - Widget sélection communes
- [ ] `lib/services/location_service.dart` - Service géolocalisation étendu

**Fichiers à modifier** :
- [ ] `lib/screens/vendeur/shop_setup_screen.dart` - Ajout sélection zones
- [ ] `lib/models/shop_model.dart` - Champs deliveryCities, deliveryCommunes
- [ ] `lib/models/order_model.dart` - Champs ville/commune départ/arrivée
- [ ] `lib/services/delivery_service.dart` - Calcul frais inter-villes
- [ ] `lib/screens/acheteur/checkout_screen.dart` - Sélection ville/commune livraison
- [ ] `lib/screens/livreur/livreur_profile_screen.dart` - Zones d'opération

### Base de données (Firestore)

**Collection `shops`** :
```javascript
{
  // ... champs existants
  "location": {
    "city": "Abidjan",
    "commune": "Cocody",
    "coordinates": { "lat": 5.3476, "lng": -3.9877 }
  },
  "deliveryZones": [
    {
      "city": "Abidjan",
      "communes": ["Cocody", "Plateau", "Marcory"],
      "baseFee": 1000
    },
    {
      "city": "Yamoussoukro",
      "communes": ["Centre"],
      "baseFee": 5000,
      "isInterCity": true
    }
  ]
}
```

**Collection `orders`** :
```javascript
{
  // ... champs existants
  "delivery": {
    "address": "...",
    "city": "Abidjan",
    "commune": "Plateau",
    "coordinates": {...}
  },
  "shop": {
    "city": "Abidjan",
    "commune": "Cocody"
  },
  "isInterCity": false,
  "deliveryFee": 1500,
  "interCityFee": 0
}
```

---

## 📈 Roadmap suggérée

### Sprint 1 (2 semaines) - Fondations
- [ ] Créer la base de données villes/communes CI
- [ ] Modèle City, Commune, Location
- [ ] Widget de sélection ville/commune
- [ ] Test avec top 5 villes

### Sprint 2 (2 semaines) - Configuration vendeur
- [ ] Intégration dans shop_setup_screen
- [ ] Sauvegarde zones de livraison Firestore
- [ ] UI/UX sélection zones
- [ ] Validation et tests

### Sprint 3 (2 semaines) - Checkout acheteur
- [ ] Sélection ville/commune de livraison
- [ ] Calcul frais inter-villes
- [ ] Vérification zone de livraison vendeur
- [ ] Message si hors zone

### Sprint 4 (2 semaines) - Livreurs régionaux
- [ ] Zones d'opération livreurs
- [ ] Affectation intelligente
- [ ] Filtres de livraisons par zone
- [ ] Tests end-to-end

### Sprint 5 (1 semaine) - Recherche géolocalisée
- [ ] Filtre produits par ville
- [ ] Badge localisation vendeur
- [ ] Tri par proximité
- [ ] Tests et optimisations

---

## 🎁 Avantages concurrentiels

✅ **Couverture nationale** - Seule plateforme CI avec cette portée
✅ **Inclusion économique** - Vendeurs de toutes les villes
✅ **Opportunités livreurs** - Emploi dans toutes les régions
✅ **Transparence tarifaire** - Frais de livraison clairs par zone
✅ **Expérience unifiée** - Même qualité de service partout

---

## 💡 Notes d'implémentation

### Considérations techniques
- **Performance** : Index Firestore sur city + commune pour requêtes rapides
- **Cache** : Données villes/communes en cache local (rarement modifiées)
- **Fallback** : Champ texte libre si ville/commune non listée
- **Migration** : Script pour migrer données existantes (Abidjan par défaut)

### Considérations business
- **Frais de livraison** : À calibrer avec vrais livreurs par région
- **Partenariats** : Contacter gares routières principales
- **Marketing** : Campagne "SOCIAL BUSINESS Pro, partout en Côte d'Ivoire"

---

## ✅ Checklist avant lancement national

- [ ] Base de données complète des 20 villes principales
- [ ] Tests de livraison dans 5 villes minimum
- [ ] Au moins 10 vendeurs par ville pilote
- [ ] Au moins 5 livreurs par ville pilote
- [ ] Partenariat avec 1 transporteur inter-villes
- [ ] Support client multilingue (Français + langues locales ?)
- [ ] Documentation livreurs/vendeurs par région

---

**Date de création** : 27 Novembre 2025
**Priorité** : 🔥 HAUTE - Différenciation stratégique majeure
**Statut** : 📋 TODO - Planification terminée, prêt pour développement
