# Système de Vérification KYC - SOCIAL MEDIA BUSINESS Pro

## Document de Spécification Détaillée

**Version:** 1.0
**Date:** 2025-11-20
**Objectif:** Définir le système de vérification d'identité conforme à la loi ivoirienne tout en maintenant une expérience utilisateur fluide

---

## 📋 Table des Matières

1. [Vue d'Ensemble](#vue-densemble)
2. [Architecture en 3 Niveaux](#architecture-en-3-niveaux)
3. [Règles par Type d'Utilisateur](#règles-par-type-dutilisateur)
4. [Flux de Vérification](#flux-de-vérification)
5. [Documents Requis](#documents-requis)
6. [Validation Admin](#validation-admin)
7. [Système de Limitations](#système-de-limitations)
8. [Protection Juridique](#protection-juridique)
9. [Implémentation Technique](#implémentation-technique)

---

## 🎯 Vue d'Ensemble

### Principe Fondamental

**Activation immédiate + Vérification progressive = Expérience fluide + Sécurité juridique**

- ✅ **Acheteurs** : Peuvent acheter immédiatement, vérification en arrière-plan
- ⚠️ **Vendeurs** : Validation obligatoire avant première vente
- ⚠️ **Livreurs** : Validation obligatoire avant première livraison

### Objectifs

1. **Expérience Utilisateur** : Pas de friction à l'inscription
2. **Conformité Légale** : Respect loi ivoirienne sur cybercriminalité (n°2013-546)
3. **Protection Plateforme** : Traçabilité complète, limitation responsabilité
4. **Anti-Fraude** : Détection précoce comportements suspects

---

## 🏗️ Architecture en 3 Niveaux

### Niveau 1 : COMPTE NON VÉRIFIÉ

**Status:** `VerificationStatus.notVerified`
**Durée:** De l'inscription jusqu'à validation KYC
**Badge:** 🟡 "Compte non vérifié"

#### Capacités par type :

**ACHETEUR** (Niveau 1) :
```
✅ Navigation complète de l'app
✅ Consultation produits, catégories, vendeurs
✅ Ajout au panier
✅ Achats AUTORISÉS (illimités) ⭐
✅ Suivi commandes
✅ Avis/notes après achat
⚠️ Message discret : "Complétez votre profil pour bénéficier de tous les avantages"
```

**VENDEUR** (Niveau 1) :
```
✅ Navigation de l'app
✅ Consultation dashboard (vide)
✅ Voir tutoriels/aide
❌ AUCUNE vente autorisée
❌ Ajout produits BLOQUÉ
❌ Gestion commandes BLOQUÉ

🔴 Écran de blocage avec message clair :
"Pour votre sécurité et celle de vos clients, vous devez
compléter la vérification de votre identité avant de commencer
à vendre sur SOCIAL MEDIA BUSINESS Pro."

[Bouton : Compléter ma vérification →]
```

**LIVREUR** (Niveau 1) :
```
✅ Navigation de l'app
✅ Consultation dashboard (vide)
✅ Voir zone de livraison potentielle
❌ AUCUNE livraison autorisée
❌ Commandes disponibles MASQUÉES
❌ Gestion livraisons BLOQUÉ

🔴 Écran de blocage avec message clair :
"Pour garantir la sécurité des colis et de vos clients, vous
devez valider votre profil et vos documents avant de commencer
vos livraisons."

[Bouton : Compléter mes documents →]
```

---

### Niveau 2 : COMPTE EN VALIDATION

**Status:** `VerificationStatus.pending`
**Durée:** Pendant la validation admin (max 48h)
**Badge:** 🟠 "Vérification en cours"

#### Capacités :

**ACHETEUR** (Niveau 2) :
```
✅ Toutes capacités Niveau 1 maintenues
✅ Aucune limitation supplémentaire
ℹ️ Badge discret "Vérification en cours" sur profil
```

**VENDEUR** (Niveau 2) :
```
✅ Navigation complète
✅ Peut préparer catalogue (ajouter produits en brouillon)
⚠️ Produits en attente de publication
❌ Ventes toujours BLOQUÉES

💬 Message :
"Vos documents sont en cours de vérification (24-48h).
Vous pouvez préparer votre catalogue en attendant."

[Statut : ⏳ En attente de validation admin]
```

**LIVREUR** (Niveau 2) :
```
✅ Navigation complète
✅ Peut consulter statistiques zone
✅ Peut voir commandes disponibles (lecture seule)
❌ Livraisons toujours BLOQUÉES

💬 Message :
"Vos documents sont en cours de vérification (24-48h).
Préparez-vous, vous pourrez bientôt commencer vos livraisons !"

[Statut : ⏳ En attente de validation admin]
```

---

### Niveau 3 : COMPTE VÉRIFIÉ

**Status:** `VerificationStatus.verified`
**Durée:** Permanent (sauf suspension)
**Badge:** ✅ "Compte vérifié"

#### Capacités :

**ACHETEUR** (Niveau 3) :
```
✅ Toutes fonctionnalités
✅ Badge "Vérifié" sur profil
✅ Confiance accrue des vendeurs
✅ Priorité SAV en cas de litige
✅ Accès programmes fidélité (si disponible)
```

**VENDEUR** (Niveau 3) :
```
✅ Toutes fonctionnalités débloquées
✅ Publication produits IMMÉDIATE
✅ Gestion complète commandes
✅ Paiements (avec rétention 7 jours les 30 premiers jours)
✅ Badge "Vendeur vérifié" visible par acheteurs
✅ Confiance accrue = meilleur classement recherche
```

**LIVREUR** (Niveau 3) :
```
✅ Toutes fonctionnalités débloquées
✅ Acceptation commandes IMMÉDIATE
✅ Gestion livraisons complète
✅ Paiements (avec rétention 7 jours les 30 premiers jours)
✅ Badge "Livreur vérifié" visible par acheteurs
✅ Priorité dans attribution automatique commandes
```

---

## 👥 Règles par Type d'Utilisateur

### 🛒 ACHETEUR

#### Politique de Vérification

**Type:** Vérification **EN ARRIÈRE-PLAN** (non bloquante)

**Principe:**
- L'acheteur peut acheter immédiatement sans attendre validation
- La vérification KYC se fait progressivement et discrètement
- Aucune limitation d'achat imposée

#### Timeline Acheteur

```
Jour 0 : Inscription
    ↓
✅ Peut acheter IMMÉDIATEMENT (montant illimité)
    ↓
Notification discrète : "Complétez votre profil pour profiter de tous les avantages"
    ↓
(Optionnel) Upload CNI + Selfie
    ↓
Validation automatique ou admin sous 24h
    ↓
Badge "Vérifié" + Avantages supplémentaires
```

#### Documents Acheteur (Optionnels mais encouragés)

1. **CNI recto/verso** (optionnel)
   - Format : JPG, PNG, PDF
   - Taille max : 5 MB
   - Lisibilité requise

2. **Selfie avec CNI** (si CNI fournie)
   - Format : JPG, PNG
   - Taille max : 3 MB
   - Visage et CNI visibles

#### Avantages Vérification Acheteur

**Avant vérification :**
- Achats illimités ✅
- Paiements standard ✅
- SAV normal ✅

**Après vérification :**
- Achats illimités ✅
- Badge "Vérifié" ⭐
- Priorité SAV en cas de litige 🎯
- Accès programmes fidélité 🎁
- Confiance accrue vendeurs 🤝

---

### 🏪 VENDEUR

#### Politique de Vérification

**Type:** Vérification **OBLIGATOIRE BLOQUANTE**

**Principe:**
- Le vendeur NE PEUT PAS vendre avant validation
- Upload documents obligatoire dès inscription
- Validation admin dans les 24-48h
- Blocage total des ventes avant validation

#### Timeline Vendeur

```
Jour 0 : Inscription
    ↓
❌ Ventes BLOQUÉES
    ↓
Redirection forcée vers "Vérification identité"
    ↓
Upload CNI + Selfie + Justificatif domicile
    ↓
Status : "En attente de validation" (max 48h)
    ↓
Validation admin (vérification manuelle)
    ↓
✅ Status "Vérifié" → Ventes DÉBLOQUÉES
```

#### Documents Vendeur (OBLIGATOIRES)

1. **CNI recto/verso** ⚠️ OBLIGATOIRE
   - Format : JPG, PNG, PDF
   - Taille max : 5 MB
   - Lisibilité complète requise
   - Validité : En cours

2. **Selfie avec CNI** ⚠️ OBLIGATOIRE
   - Format : JPG, PNG
   - Taille max : 3 MB
   - Visage ET CNI bien visibles
   - Photo nette, bien éclairée

3. **Justificatif de domicile**  (Recommandé)
   - Types acceptés :
     - Facture électricité (CIE) < 3 mois
     - Facture eau (SODECI) < 3 mois
     - Contrat de bail signé
     - Certificat de résidence < 3 mois
   - Format : JPG, PNG, PDF
   - Taille max : 5 MB
   - Nom et adresse lisibles

4. **Photo espace stockage** (Recommandé)
   - Format : JPG, PNG
   - Taille max : 3 MB
   - Montre espace rangement produits
   - Prouve sérieux activité

#### Checklist Validation Vendeur

Admin vérifie :
- [ ] CNI valide et lisible
- [ ] Photo correspond à personne sur CNI
- [ ] Justificatif domicile récent (< 3 mois)
- [ ] Cohérence informations (nom, adresse)
- [ ] Aucun signalement antérieur sur email/téléphone
- [ ] Profil complété (description, catégorie)

**Validation:** ✅ Approuver  /  ❌ Rejeter (avec raison)

---

### 🚚 LIVREUR

#### Politique de Vérification

**Type:** Vérification **OBLIGATOIRE BLOQUANTE + Documents additionnels**

**Principe:**
- Le livreur NE PEUT PAS livrer avant validation
- Upload documents obligatoire dès inscription
- Validation admin stricte dans les 24-48h
- Vérification documents véhicule + assurance
- Blocage total des livraisons avant validation

#### Timeline Livreur

```
Jour 0 : Inscription
    ↓
❌ Livraisons BLOQUÉES
    ↓
Redirection forcée vers "Gestion des documents"
    ↓
Upload TOUS documents requis (5 documents)
    ↓
Status : "En attente de validation" (max 48h)
    ↓
Validation admin stricte (vérification manuelle approfondie)
    ↓
✅ Status "Vérifié" → Livraisons DÉBLOQUÉES
```

#### Documents Livreur (OBLIGATOIRES)

**Déjà implémentés dans `documents_management_screen.dart` :**

1. **Carte d'identité (CNI)** ⚠️ OBLIGATOIRE
   - Clé Firestore : `identityCard`
   - Format : JPG, PNG, PDF
   - Taille max : 5 MB
   - Recto + Verso si possible

2. **Permis de conduire** ⚠️ OBLIGATOIRE
   - Clé Firestore : `drivingLicense`
   - Format : JPG, PNG, PDF
   - Taille max : 5 MB
   - Catégorie A (moto) ou B (voiture)
   - Validité en cours

3. **Carte grise du véhicule** ⚠️ OBLIGATOIRE
   - Clé Firestore : `vehicleRegistration`
   - Format : JPG, PNG, PDF
   - Taille max : 5 MB
   - Nom propriétaire doit correspondre
   - Ou attestation si véhicule loué/prêté

4. **Assurance véhicule** ⚠️ OBLIGATOIRE
   - Clé Firestore : `insurance`
   - Format : JPG, PNG, PDF
   - Taille max : 5 MB
   - Validité : En cours (vérifier date)
   - Type : Responsabilité civile minimum

5. **Photo du véhicule** ⚠️ OBLIGATOIRE
   - Clé Firestore : `vehiclePhoto`
   - Format : JPG, PNG
   - Taille max : 3 MB
   - Véhicule complet, plaque visible
   - Photo récente

**❌ SUPPRIMÉ (trop contraignant) :**
- ~~Casier judiciaire~~ → Pas obligatoire

#### Checklist Validation Livreur

Admin vérifie :
- [ ] CNI valide et lisible
- [ ] Permis conduire valide (catégorie appropriée)
- [ ] Carte grise correspond au véhicule
- [ ] Assurance EN COURS (date validité)
- [ ] Photo véhicule correspond à carte grise
- [ ] Aucun signalement antérieur
- [ ] Profil complété (zone livraison, disponibilité)

**Validation:** ✅ Approuver  /  ❌ Rejeter (avec raison détaillée)

---

## 🔄 Flux de Vérification

### Flux Acheteur (Non Bloquant)

```
┌─────────────────────────────────────────────────────────────┐
│ INSCRIPTION ACHETEUR                                        │
└─────────────────────────────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │ Compte créé : Status = notVerified  │
        │ isActive = true                     │
        └─────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │ ✅ REDIRECTION VERS ACHETEUR HOME   │
        │ Peut acheter immédiatement          │
        └─────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │ Notification in-app (discrète) :    │
        │ "Complétez votre profil"            │
        │                                      │
        │ [Plus tard]  [Compléter maintenant] │
        └─────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │ Si "Compléter maintenant" :         │
        │ → Page KYC acheteur (optionnel)    │
        │                                      │
        │ Si "Plus tard" :                    │
        │ → Continue achats normalement       │
        └─────────────────────────────────────┘
```

---

### Flux Vendeur (Bloquant)

```
┌─────────────────────────────────────────────────────────────┐
│ INSCRIPTION VENDEUR                                         │
└─────────────────────────────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │ Compte créé : Status = notVerified  │
        │ isActive = true                     │
        └─────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │ 🔴 REDIRECTION FORCÉE vers          │
        │ Page "Vérification Obligatoire"     │
        │                                      │
        │ Impossible d'accéder au dashboard   │
        │ sans compléter KYC                  │
        └─────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │ ÉCRAN KYC VENDEUR                   │
        │                                      │
        │ "Pour votre sécurité et celle de    │
        │ vos clients, complétez votre        │
        │ vérification d'identité"            │
        │                                      │
        │ 1. ⬆️ CNI recto/verso               │
        │ 2. ⬆️ Selfie avec CNI               │
        │ 3. ⬆️ Justificatif domicile  (optionnel mais obligatoire pour avoir le statut "vérifié" mais n'empèche pas le vendeur dans ses acticités sur l'application)      │
        │                                      │
        │ [Valider mes documents]             │
        └─────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │ Upload terminé                      │
        │ Status = pending                    │
        │                                      │
        │ Notification admin créée            │
        └─────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │ 🟠 ÉCRAN ATTENTE VALIDATION         │
        │                                      │
        │ "Vos documents sont en cours de     │
        │ vérification. Vous recevrez une     │
        │ notification sous 24-48h."          │
        │                                      │
        │ Pendant ce temps :                  │
        │ ✅ Peut préparer son catalogue      │
        │ ✅ Peut ajouter produits (brouillon)│
        │ ❌ Ne peut pas PUBLIER              │
        │ ❌ Ne peut pas VENDRE               │
        └─────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │ ADMIN VALIDE / REJETTE              │
        │                                      │
        │ Si APPROUVÉ :                       │
        │ → Status = verified                 │
        │ → Notification "Compte validé ✅"   │
        │ → Ventes DÉBLOQUÉES                 │
        │                                      │
        │ Si REJETÉ :                         │
        │ → Status = rejected                 │
        │ → Notification avec raison          │
        │ → Possibilité re-soumission         │
        └─────────────────────────────────────┘
```

---

### Flux Livreur (Bloquant + Documents)

```
┌─────────────────────────────────────────────────────────────┐
│ INSCRIPTION LIVREUR                                         │
└─────────────────────────────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │ Compte créé : Status = notVerified  │
        │ isActive = true                     │
        └─────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │ 🔴 REDIRECTION FORCÉE vers          │
        │ "Gestion des documents"             │
        │                                      │
        │ (Screen déjà implémenté)            │
        └─────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │ ÉCRAN DOCUMENTS LIVREUR             │
        │ (documents_management_screen.dart)  │
        │                                      │
        │ "Pour garantir la sécurité des      │
        │ livraisons, uploadez vos documents" │
        │                                      │
        │ 1. ⬆️ CNI (identityCard)            │
        │ 2. ⬆️ Permis (drivingLicense)       │
        │ 3. ⬆️ Carte grise (vehicleReg...)   │
        │ 4. ⬆️ Assurance (insurance)         │
        │ 5. ⬆️ Photo véhicule (vehiclePhoto) │
        │                                      │
        │ [Soumettre mes documents]           │
        └─────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │ Upload terminé (5/5 documents)      │
        │ Status = pending                    │
        │                                      │
        │ Notification admin HIGH PRIORITY    │
        └─────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │ 🟠 ÉCRAN ATTENTE VALIDATION         │
        │                                      │
        │ "Vos documents sont en cours de     │
        │ vérification approfondie."          │
        │ "Délai : 24-48h"                    │
        │                                      │
        │ Pendant ce temps :                  │
        │ ✅ Peut consulter map livraisons    │
        │ ✅ Peut voir commandes (lecture)    │
        │ ❌ Ne peut pas ACCEPTER commandes   │
        │ ❌ Ne peut pas LIVRER               │
        └─────────────────────────────────────┘
                          ↓
        ┌─────────────────────────────────────┐
        │ ADMIN VALIDE / REJETTE              │
        │ (Vérification stricte)              │
        │                                      │
        │ Si APPROUVÉ :                       │
        │ → Status = verified                 │
        │ → Notification "Validé ✅"          │
        │ → Livraisons DÉBLOQUÉES             │
        │                                      │
        │ Si REJETÉ :                         │
        │ → Status = rejected                 │
        │ → Notification avec raison précise  │
        │ → Indiquer quel document problème   │
        │ → Possibilité re-soumission         │
        └─────────────────────────────────────┘
```

---

## 📂 Documents Requis - Récapitulatif

### Matrice Documents par Type Utilisateur

| Document | Acheteur | Vendeur | Livreur |
|----------|----------|---------|---------|
| **CNI recto/verso** | 🟡 Optionnel | 🔴 OBLIGATOIRE | 🔴 OBLIGATOIRE |
| **Selfie avec CNI** | 🟡 Si CNI fournie | 🔴 OBLIGATOIRE | 🔴 OBLIGATOIRE |
| **Justificatif domicile** | ⚪ Non requis | Recommandé | 🟢 Recommandé |
| **Permis de conduire** | ⚪ Non requis | ⚪ Non requis | 🔴 OBLIGATOIRE |
| **Carte grise** | ⚪ Non requis | ⚪ Non requis | 🔴 OBLIGATOIRE |
| **Assurance véhicule** | ⚪ Non requis | ⚪ Non requis | 🔴 OBLIGATOIRE |
| **Photo véhicule** | ⚪ Non requis | ⚪ Non requis | 🔴 OBLIGATOIRE |
| **Casier judiciaire** | ⚪ Non requis | ⚪ Non requis | ⚪ Non requis |

**Légende:**
- 🔴 OBLIGATOIRE : Bloque l'activation
- 🟡 Optionnel : Encouragé mais pas bloquant
- 🟢 Recommandé : Améliore confiance mais pas bloquant
- ⚪ Non requis : Pas nécessaire

---

## 👮 Validation Admin

### Dashboard Admin - File de Validation

**Écran:** Admin → Gestion Utilisateurs → Validations en attente

#### Vue Liste

```
┌────────────────────────────────────────────────────────────────┐
│ VALIDATIONS EN ATTENTE (12)                    [Filtrer ▼]     │
├────────────────────────────────────────────────────────────────┤
│                                                                 │
│ 🟠 Mamadou KONÉ - Vendeur                                      │
│ └─ Inscrit il y a 3h                                           │
│ └─ Documents : CNI ✅, Selfie ✅, Domicile ✅                  │
│    [Voir détails]  [✅ Valider]  [❌ Rejeter]                  │
│                                                                 │
│ 🟠 Fatou DIALLO - Livreur                                      │
│ └─ Inscrit il y a 1j                                           │
│ └─ Documents : 5/5 uploadés                                    │
│    [Voir détails]  [✅ Valider]  [❌ Rejeter]                  │
│                                                                 │
│ 🟠 Jean KOUASSI - Vendeur                                      │
│ └─ Inscrit il y a 2j                                           │
│ └─ Documents : CNI ✅, Selfie ⚠️ Flou, Domicile ✅            │
│    [Voir détails]  [✅ Valider]  [❌ Rejeter]                  │
│                                                                 │
└────────────────────────────────────────────────────────────────┘
```

#### Vue Détail Vendeur

```
┌────────────────────────────────────────────────────────────────┐
│ VALIDATION VENDEUR - Mamadou KONÉ                              │
├────────────────────────────────────────────────────────────────┤
│ Informations profil :                                          │
│ • Email : mamadou.kone@gmail.com                               │
│ • Téléphone : +225 07 12 34 56 78                              │
│ • Adresse : Cocody, Abidjan                                    │
│ • Catégorie : Électronique                                     │
│ • Inscrit le : 20/11/2025 à 14h30                              │
│                                                                 │
│ Documents uploadés :                                           │
│                                                                 │
│ 1. CNI recto/verso ✅                                          │
│    [Voir image] [Agrandir] [Télécharger]                       │
│    └─ Nom : KONÉ Mamadou                                       │
│    └─ N° : CI225123456789                                      │
│    └─ Né le : 15/03/1990                                       │
│    └─ Validité : 2028                                          │
│                                                                 │
│ 2. Selfie avec CNI ✅                                          │
│    [Voir image] [Agrandir] [Télécharger]                       │
│    └─ Visage clair ✅                                          │
│    └─ CNI lisible ✅                                           │
│    └─ Correspondance visuelle : ✅ OUI                         │
│                                                                 │
│ 3. Justificatif domicile ✅                                    │
│    [Voir document] [Agrandir] [Télécharger]                    │
│    └─ Type : Facture CIE                                       │
│    └─ Date : Octobre 2025 (< 3 mois ✅)                        │
│    └─ Nom : KONÉ Mamadou ✅                                    │
│    └─ Adresse : Cocody, Abidjan ✅                             │
│                                                                 │
│ Checklist de validation :                                      │
│ ☑ CNI valide et lisible                                        │
│ ☑ Photo correspond à CNI                                       │
│ ☑ Justificatif récent (< 3 mois)                               │
│ ☑ Cohérence nom/adresse                                        │
│ ☐ Vérification signalements antérieurs                         │
│                                                                 │
│ Décision :                                                      │
│ [✅ APPROUVER]  [❌ REJETER]  [⏸️ Demander complément]         │
│                                                                 │
│ Si rejet, indiquer raison :                                    │
│ [ Sélectionner raison ▼ ]                                      │
│ • CNI invalide/expirée                                         │
│ • Photo floue/illisible                                        │
│ • Selfie ne correspond pas                                     │
│ • Justificatif trop ancien                                     │
│ • Incohérence informations                                     │
│ • Autre (préciser)                                             │
│                                                                 │
│ [______________________________________________]                │
│                                                                 │
└────────────────────────────────────────────────────────────────┘
```

#### Vue Détail Livreur

```
┌────────────────────────────────────────────────────────────────┐
│ VALIDATION LIVREUR - Fatou DIALLO                              │
├────────────────────────────────────────────────────────────────┤
│ Informations profil :                                          │
│ • Email : fatou.diallo@yahoo.fr                                │
│ • Téléphone : +225 05 98 76 54 32                              │
│ • Zone livraison : Cocody - Marcory                            │
│ • Inscrit le : 19/11/2025 à 10h15                              │
│                                                                 │
│ Documents uploadés :                                           │
│                                                                 │
│ 1. CNI ✅                                                      │
│    [Voir image]                                                │
│    └─ Nom : DIALLO Fatou                                       │
│    └─ N° : CI225987654321                                      │
│    └─ Validité : 2027 ✅                                       │
│                                                                 │
│ 2. Permis de conduire ✅                                       │
│    [Voir image]                                                │
│    └─ N° : PC123456                                            │
│    └─ Catégorie : A (Moto) ✅                                  │
│    └─ Validité : 2026 ✅                                       │
│                                                                 │
│ 3. Carte grise ✅                                              │
│    [Voir image]                                                │
│    └─ Immatriculation : AB-1234-CI                             │
│    └─ Propriétaire : DIALLO Fatou ✅                           │
│    └─ Type : Moto                                              │
│                                                                 │
│ 4. Assurance ⚠️ VÉRIFIER DATE                                 │
│    [Voir image]                                                │
│    └─ Compagnie : NSIA                                         │
│    └─ N° Police : 123456789                                    │
│    └─ Validité : 01/12/2024 à 01/12/2025                       │
│    └─ Type : RC (Responsabilité Civile) ✅                     │
│    └─ ⚠️ Expire dans 11 jours !                                │
│                                                                 │
│ 5. Photo véhicule ✅                                           │
│    [Voir image]                                                │
│    └─ Plaque visible : AB-1234-CI ✅                           │
│    └─ État véhicule : Bon                                      │
│                                                                 │
│ Checklist de validation :                                      │
│ ☑ CNI valide                                                   │
│ ☑ Permis catégorie appropriée                                  │
│ ☑ Carte grise correspond                                       │
│ ⚠️ Assurance EXPIRE BIENTÔT                                    │
│ ☑ Photo véhicule correspond                                    │
│                                                                 │
│ Décision :                                                      │
│ [✅ APPROUVER avec avertissement]  [❌ REJETER]                │
│ [⏸️ Demander renouvellement assurance]                         │
│                                                                 │
│ Note pour le livreur (visible après décision) :                │
│ [______________________________________________]                │
│ Exemple : "Votre assurance expire le 01/12. Veuillez           │
│ uploader la nouvelle assurance sous 10 jours."                 │
│                                                                 │
└────────────────────────────────────────────────────────────────┘
```

### Actions Admin

**Approuver:**
1. Click bouton "✅ APPROUVER"
2. `verificationStatus` → `verified`
3. Notification envoyée à l'utilisateur
4. Email de confirmation
5. Déblocage fonctionnalités

**Rejeter:**
1. Sélectionner raison prédéfinie
2. (Optionnel) Ajouter commentaire
3. Click bouton "❌ REJETER"
4. `verificationStatus` → `rejected`
5. Notification avec raison envoyée
6. Utilisateur peut re-soumettre documents

**Demander complément:**
1. Click bouton "⏸️ Demander complément"
2. Liste documents à compléter/corriger
3. `verificationStatus` reste `pending`
4. Notification spécifique envoyée
5. Utilisateur re-upload documents manquants

---

## 🚫 Système de Limitations

### Blocages Techniques

**Pour VENDEURS non vérifiés (`status = notVerified ou pending`) :**

```dart
// Dans product_service.dart - Méthode addProduct()

Future<String?> addProduct(ProductModel product) async {
  // Vérifier status vendeur
  final user = await getUserById(product.vendeurId);

  if (user.verificationStatus != VerificationStatus.verified) {
    throw Exception(
      'Votre compte doit être vérifié avant d\'ajouter des produits. '
      'Complétez votre vérification d\'identité.'
    );
  }

  // Continue si vérifié...
}

// Dans order_service.dart - Méthode createOrder()

Future<String?> createOrder(OrderModel order) async {
  // Vérifier status vendeur
  final vendeur = await getUserById(order.vendeurId);

  if (vendeur.verificationStatus != VerificationStatus.verified) {
    throw Exception(
      'Ce vendeur n\'est pas encore vérifié. '
      'Vous ne pouvez pas passer commande pour le moment.'
    );
  }

  // Continue si vérifié...
}
```

**Pour LIVREURS non vérifiés (`status = notVerified ou pending`) :**

```dart
// Dans delivery_service.dart - Méthode acceptDelivery()

Future<bool> acceptDelivery(String deliveryId, String livreurId) async {
  // Vérifier status livreur
  final livreur = await getUserById(livreurId);

  if (livreur.verificationStatus != VerificationStatus.verified) {
    throw Exception(
      'Votre compte doit être vérifié avant d\'accepter des livraisons. '
      'Complétez vos documents dans "Gestion des documents".'
    );
  }

  // Continue si vérifié...
}

// Dans available_orders_screen.dart

Widget build(BuildContext context) {
  final user = context.watch<AuthProvider>().user;

  if (user?.verificationStatus != VerificationStatus.verified) {
    return _buildVerificationRequiredScreen();
  }

  // Affiche commandes disponibles si vérifié
  return _buildOrdersList();
}
```

**Pour ACHETEURS (aucun blocage) :**

```dart
// Dans cart_screen.dart - Méthode checkout()

Future<void> checkout() async {
  final user = context.read<AuthProvider>().user;

  // ✅ AUCUNE vérification status
  // Acheteur peut acheter même si non vérifié

  // (Optionnel) Encourager vérification après achat
  if (user?.verificationStatus == VerificationStatus.notVerified) {
    // Afficher message discret après commande passée:
    // "Pensez à vérifier votre compte pour profiter de tous les avantages"
  }

  // Continue checkout normalement...
}
```

### Écrans de Blocage

**Écran Blocage Vendeur :**

```dart
class VerificationRequiredScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Vérification requise')),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified_user, size: 100, color: Colors.orange),
              SizedBox(height: 24),
              Text(
                'Vérification d\'identité requise',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                'Pour garantir la sécurité de tous, vous devez compléter '
                'votre vérification d\'identité avant de pouvoir vendre '
                'sur SOCIAL MEDIA BUSINESS Pro.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => context.push('/kyc-verification'),
                icon: Icon(Icons.upload_file),
                label: Text('Compléter ma vérification'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

**Écran Blocage Livreur :**

```dart
class DocumentsRequiredScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Documents requis')),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.description, size: 100, color: Colors.orange),
              SizedBox(height: 24),
              Text(
                'Documents de livraison requis',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                'Pour la sécurité des colis et de vos clients, vous devez '
                'uploader vos documents (CNI, permis, assurance, etc.) avant '
                'de commencer vos livraisons.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => context.push('/livreur/documents'),
                icon: Icon(Icons.upload),
                label: Text('Gérer mes documents'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## 📜 Protection Juridique

### Mentions Légales Obligatoires

**Affichées lors de l'inscription :**

```
CONDITIONS GÉNÉRALES D'UTILISATION
SOCIAL MEDIA BUSINESS Pro

Article 5 : Vérification d'identité (KYC)

5.1 Obligation légale
Conformément à la loi n°2013-546 du 19 juin 2013 relative à la lutte
contre la cybercriminalité et la loi n°2020-628 du 14 octobre 2020
relative au commerce électronique en Côte d'Ivoire, SOCIAL MEDIA BUSINESS Pro
est tenu de vérifier l'identité de ses utilisateurs, notamment les
vendeurs et livreurs.

5.2 Documents requis
• Acheteurs : Vérification optionnelle mais encouragée
• Vendeurs : CNI + Selfie + Justificatif domicile OBLIGATOIRES
• Livreurs : CNI + Permis + Carte grise + Assurance + Photo véhicule
  OBLIGATOIRES

5.3 Conservation des données
Les données d'identité sont conservées 5 ans après fermeture du compte,
conformément aux obligations légales de traçabilité.

5.4 Sanctions en cas de fraude
Toute usurpation d'identité, fourniture de faux documents ou utilisation
frauduleuse de la plateforme entraîne :
• Suspension immédiate du compte
• Signalement aux autorités compétentes (PLCC, ARTCI)
• Poursuites judiciaires possibles

Article 6 : Limitation de responsabilité

6.1 Rôle de la plateforme
SOCIAL MEDIA BUSINESS Pro agit comme intermédiaire de mise en relation entre
vendeurs, livreurs et acheteurs. Nous ne sommes pas partie aux
transactions.

6.2 Vérifications effectuées
Malgré nos vérifications KYC, SOCIAL MEDIA BUSINESS Pro ne garantit pas
l'honnêteté absolue des utilisateurs. Chaque utilisateur agit sous sa
propre responsabilité.

6.3 Responsabilité des vendeurs/livreurs
Les vendeurs sont responsables de la qualité, de la conformité et de la
légalité des produits vendus. Les livreurs sont responsables de la bonne
exécution des livraisons.

SOCIAL MEDIA BUSINESS Pro ne peut être tenu responsable des vices cachés,
retards, dommages ou litiges entre utilisateurs.

6.4 Système de notation
Le système d'avis et de notation permet aux utilisateurs d'évaluer la
qualité des services. Il constitue un mécanisme d'autorégulation et
d'information.

En acceptant ces CGU, vous reconnaissez avoir lu et compris ces
dispositions.

☐ J'accepte les Conditions Générales d'Utilisation
```

### Clause de Décharge Spécifique

```
DÉCHARGE DE RESPONSABILITÉ

En utilisant SOCIAL MEDIA BUSINESS Pro, vous reconnaissez et acceptez que :

1. Vous êtes seul responsable de vos transactions
2. SOCIAL MEDIA BUSINESS Pro effectue des vérifications raisonnables mais ne
   peut garantir l'honnêteté absolue de tous les utilisateurs
3. En cas de litige, vous vous engagez à chercher une résolution amiable
   en premier lieu
4. SOCIAL MEDIA BUSINESS Pro peut jouer un rôle de médiation mais n'est pas
   juridiquement responsable des litiges
5. Vous ne tiendrez pas SOCIAL MEDIA BUSINESS Pro responsable des pertes,
   dommages ou préjudices résultant de transactions avec d'autres
   utilisateurs

Cette clause est conforme au droit ivoirien et aux usages des plateformes
de commerce électronique.
```

---

## 💻 Implémentation Technique

### Modifications Requises

#### 1. Enum VerificationStatus (Déjà présent)

```dart
// lib/config/constants.dart (lignes 158-165)

enum VerificationStatus {
  verified,      // ✅ Vérifié (vendeur/livreur peut opérer)
  pending,       // 🟠 En attente validation admin
  rejected,      // ❌ Rejeté (peut re-soumettre)
  notVerified;   // 🟡 Non vérifié (bloqué si vendeur/livreur)

  String get value => toString().split('.').last;
}
```

#### 2. UserModel (Déjà mis à jour)

```dart
// lib/models/user_model.dart

class UserModel {
  final String id;
  final String email;
  final String displayName;
  final UserType userType;
  final VerificationStatus verificationStatus;  // ✅ Déjà présent
  final Map<String, dynamic> profile;
  // ...
}
```

#### 3. Service de Vérification KYC

**Nouveau fichier:** `lib/services/kyc_verification_service.dart`

```dart
class KYCVerificationService {
  static Future<bool> canPerformAction(String userId, String action) async {
    final user = await getUserById(userId);

    switch (action) {
      case 'sell':
        // Vendeur doit être vérifié
        return user.userType == UserType.vendeur &&
               user.verificationStatus == VerificationStatus.verified;

      case 'deliver':
        // Livreur doit être vérifié
        return user.userType == UserType.livreur &&
               user.verificationStatus == VerificationStatus.verified;

      case 'buy':
        // Acheteur peut toujours acheter
        return user.userType == UserType.acheteur;

      default:
        return false;
    }
  }

  static Future<void> submitVerification(
    String userId,
    Map<String, String> documents,
  ) async {
    await FirebaseService.updateDocument(
      collection: FirebaseCollections.users,
      docId: userId,
      data: {
        'verificationStatus': VerificationStatus.pending.value,
        'documents': documents,
        'submittedAt': DateTime.now(),
      },
    );

    // Notifier admin
    await NotificationService().notifyAdminNewVerification(userId);
  }
}
```

#### 4. Écrans KYC à créer

**Fichiers à créer:**
- `lib/screens/kyc/kyc_upload_screen.dart` (Upload documents vendeur)
- `lib/screens/kyc/kyc_pending_screen.dart` (Attente validation)
- `lib/screens/kyc/verification_required_screen.dart` (Blocage vendeur)
- `lib/screens/admin/kyc_validation_screen.dart` (Dashboard admin validation)

#### 5. Routes à ajouter

```dart
// lib/routes/app_router.dart

GoRoute(
  path: '/kyc-verification',
  builder: (context, state) => const KYCUploadScreen(),
),
GoRoute(
  path: '/kyc-pending',
  builder: (context, state) => const KYCPendingScreen(),
),
GoRoute(
  path: '/admin/kyc-validation',
  builder: (context, state) => const KYCValidationScreen(),
),
```

---

## 📊 Résumé des Décisions

### Décisions Finales

| Aspect | Décision | Justification |
|--------|----------|---------------|
| **Acheteurs - Vérification** | Optionnelle, en arrière-plan | Fluidité expérience, pas de risque pour plateforme |
| **Acheteurs - Limitations** | AUCUNE | Peuvent acheter sans limite dès inscription |
| **Vendeurs - Vérification** | OBLIGATOIRE bloquante | Protection acheteurs, conformité légale |
| **Vendeurs - Documents** | CNI + Selfie + Justificatif domicile | Standard KYC Côte d'Ivoire |
| **Livreurs - Vérification** | OBLIGATOIRE bloquante | Sécurité colis, conformité légale |
| **Livreurs - Documents** | 5 documents (CNI, Permis, Carte grise, Assurance, Photo) | Déjà implémentés dans app |
| **Casier judiciaire** | NON requis | Trop contraignant, risque abandon |
| **Délai validation** | 24-48h max | Standard marché, acceptable utilisateurs |
| **Validation** | Manuelle par admin (Phase 1) | Précision maximale, coût 0 |
| **Protection légale** | CGU + Mentions + Décharge | Limitation responsabilité plateforme |

### Impacts

**Positifs:**
- ✅ Conformité légale assurée
- ✅ Confiance acheteurs renforcée
- ✅ Traçabilité complète
- ✅ Protection juridique plateforme
- ✅ Expérience acheteur préservée (0 friction)
- ✅ Système évolutif (API automatique Phase 2)

**À surveiller:**
- ⚠️ Charge admin validation (Phase 1)
- ⚠️ Temps attente vendeurs/livreurs (24-48h)
- ⚠️ Taux abandon inscription vendeurs/livreurs

**Mitigations:**
- Admin dédiés validation KYC
- Notifications proactives progression
- Possibilité préparer catalogue pendant attente
- Communication claire délais dès inscription

---

## 🚀 Prochaines Étapes

### Phase 1 (Maintenant - MVP)

1. Créer écrans KYC upload
2. Créer dashboard admin validation
3. Implémenter blocages techniques (vendeurs/livreurs)
4. Ajouter CGU/Mentions légales
5. Tester flux complet
6. Former admins procédure validation

### Phase 2 (3-6 mois - Scale)

1. Intégrer API Smile Identity (OCR automatique)
2. Validation automatique 70% cas
3. Dashboard analytics KYC
4. Optimisation processus admin
5. Système scoring utilisateurs
6. Assurance plateforme partenariat

---

**Document maintenu par:** Équipe SOCIAL MEDIA BUSINESS Pro
**Dernière révision:** 2025-11-20
**Version:** 1.0