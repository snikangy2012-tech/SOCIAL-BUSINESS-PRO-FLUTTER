# INDEX DES SCRIPTS - SOCIAL BUSINESS Pro

> **39 scripts** organisés en **12 catégories** pour la maintenance et l'administration du projet.

---

## Structure des dossiers

```
scripts/
├── INDEX.md              # Ce fichier
├── package.json          # Dépendances Node.js
├── README.md             # Documentation générale
├── README_CLEANUP.md     # Guide de nettoyage
├── .gitignore
│
├── admin/                # Gestion administrateurs et utilisateurs (6)
├── livraisons/           # Gestion des livraisons (5)
├── stock/                # Gestion du stock (4)
├── produits/             # Gestion des produits (2)
├── categories/           # Gestion des catégories (3)
├── commandes/            # Gestion des commandes (2)
├── ui/                   # Corrections UI et boutons retour (9)
├── migration/            # Migration de données (2)
├── cleanup/              # Nettoyage et maintenance (2)
├── system/               # Utilitaires système (3)
├── tests/                # Scripts de test (1)
└── database/             # Utilitaires base de données (1)
```

---

## Navigation rapide

| Catégorie | Description | Fichiers |
|-----------|-------------|----------|
| [admin/](#admin) | Gestion admin, super admin, utilisateurs | 6 |
| [livraisons/](#livraisons) | Diagnostic et nettoyage livraisons | 5 |
| [stock/](#stock) | Réservations et réinitialisations stock | 4 |
| [produits/](#produits) | Vérification images et produits | 2 |
| [categories/](#categories) | Nettoyage et diagnostic catégories | 3 |
| [commandes/](#commandes) | Réinitialisation commandes | 2 |
| [ui/](#ui) | Corrections boutons retour et AppBars | 9 |
| [migration/](#migration) | Migration données Firestore | 2 |
| [cleanup/](#cleanup) | Nettoyage fichiers et processus | 2 |
| [system/](#system) | Optimisation et audit système | 3 |
| [tests/](#tests) | Scripts de test | 1 |
| [database/](#database) | Vérification collections Firestore | 1 |

---

## Détail par catégorie

### admin/
> Gestion des administrateurs, super admins et comptes utilisateurs

| Fichier | Description |
|---------|-------------|
| [admin_backend_server.js](admin/admin_backend_server.js) | Serveur backend pour fonctions admin |
| [create_admin_auth_accounts.js](admin/create_admin_auth_accounts.js) | Création comptes admin dans Firebase Auth |
| [fix_admin_profile.js](admin/fix_admin_profile.js) | Correction profils admin corrompus |
| [fix_admin_users.js](admin/fix_admin_users.js) | Correction utilisateurs admin |
| [reset_vendor_counters.js](admin/reset_vendor_counters.js) | Réinitialisation compteurs vendeurs |
| [setup_super_admin.js](admin/setup_super_admin.js) | Configuration du super administrateur |

**Exécution:**
```bash
node scripts/admin/setup_super_admin.js
```

---

### livraisons/
> Diagnostic, vérification et nettoyage des livraisons

| Fichier | Description |
|---------|-------------|
| [check_delivery_statuses.js](livraisons/check_delivery_statuses.js) | Vérification statuts des livraisons |
| [check_livreur_deliveries.js](livraisons/check_livreur_deliveries.js) | Vérification livraisons par livreur |
| [clean_duplicate_deliveries.js](livraisons/clean_duplicate_deliveries.js) | Suppression livraisons en double |
| [diagnose_deliveries.js](livraisons/diagnose_deliveries.js) | Diagnostic complet des livraisons |
| [migrate_delivery_addresses.js](livraisons/migrate_delivery_addresses.js) | Migration des adresses de livraison |

**Exécution:**
```bash
node scripts/livraisons/diagnose_deliveries.js
```

---

### stock/
> Gestion des réservations de stock et réinitialisations

| Fichier | Description |
|---------|-------------|
| [clean_expired_reservations.js](stock/clean_expired_reservations.js) | Nettoyage réservations expirées |
| [reset_reserved_stock.js](stock/reset_reserved_stock.js) | Réinitialisation stock réservé |
| [reset_stock_reservations.js](stock/reset_stock_reservations.js) | Réinitialisation réservations de stock |
| [test_stock_reservation.js](stock/test_stock_reservation.js) | Test système de réservation |

**Exécution:**
```bash
node scripts/stock/clean_expired_reservations.js
```

---

### produits/
> Vérification des produits et leurs images

| Fichier | Description |
|---------|-------------|
| [check_products_images.js](produits/check_products_images.js) | Vérification URLs images produits |
| [check_specific_product.js](produits/check_specific_product.js) | Vérification d'un produit spécifique |

**Exécution:**
```bash
node scripts/produits/check_products_images.js
```

---

### categories/
> Gestion et nettoyage des catégories

| Fichier | Description |
|---------|-------------|
| [clean_categories.js](categories/clean_categories.js) | Nettoyage catégories invalides |
| [cleanup_obsolete_categories.js](categories/cleanup_obsolete_categories.js) | Suppression catégories obsolètes |
| [diagnose_categories.js](categories/diagnose_categories.js) | Diagnostic système catégories |

**Exécution:**
```bash
node scripts/categories/diagnose_categories.js
```

---

### commandes/
> Réinitialisation et nettoyage des commandes

| Fichier | Description |
|---------|-------------|
| [reset_orders_and_deliveries.js](commandes/reset_orders_and_deliveries.js) | Réinitialisation commandes et livraisons |
| [reset_orders_deliveries.js](commandes/reset_orders_deliveries.js) | Réinitialisation (version alternative) |

**Exécution:**
```bash
node scripts/commandes/reset_orders_and_deliveries.js
```

---

### ui/
> Corrections d'interface utilisateur et boutons retour

| Fichier | Description |
|---------|-------------|
| [apply_system_ui_fix.js](ui/apply_system_ui_fix.js) | Application corrections UI système |
| [add_back_buttons.ps1](ui/add_back_buttons.ps1) | Ajout boutons retour manquants |
| [analyze_back_button_coverage.ps1](ui/analyze_back_button_coverage.ps1) | Analyse couverture boutons retour |
| [fix_all_back_buttons.ps1](ui/fix_all_back_buttons.ps1) | Correction tous boutons retour |
| [fix_back_buttons.ps1](ui/fix_back_buttons.ps1) | Correction boutons retour |
| [fix_back_buttons_by_role.ps1](ui/fix_back_buttons_by_role.ps1) | Correction par rôle utilisateur |
| [fix_back_buttons_role.ps1](ui/fix_back_buttons_role.ps1) | Correction rôle spécifique |
| [update_appbars.ps1](ui/update_appbars.ps1) | Mise à jour AppBars |
| [update_back_buttons.ps1](ui/update_back_buttons.ps1) | Mise à jour boutons retour |

**Exécution (PowerShell):**
```powershell
.\scripts\ui\analyze_back_button_coverage.ps1
```

---

### migration/
> Migration de données Firestore

| Fichier | Description |
|---------|-------------|
| [migrate_firestore_cli.bat](migration/migrate_firestore_cli.bat) | Script batch migration Firestore |
| [migrate_user_dates.js](migration/migrate_user_dates.js) | Migration format dates utilisateurs |

**Exécution:**
```bash
node scripts/migration/migrate_user_dates.js
```

---

### cleanup/
> Nettoyage de fichiers et processus

| Fichier | Description |
|---------|-------------|
| [clean_local_paths.js](cleanup/clean_local_paths.js) | Nettoyage chemins locaux dans le code |
| [cleanup_processes.ps1](cleanup/cleanup_processes.ps1) | Arrêt processus Flutter/Dart |

**Exécution:**
```powershell
.\scripts\cleanup\cleanup_processes.ps1
```

---

### system/
> Utilitaires système Windows

| Fichier | Description |
|---------|-------------|
| [arreter_processus_maintenant.ps1](system/arreter_processus_maintenant.ps1) | Arrêt immédiat des processus |
| [audit_zones_systeme.ps1](system/audit_zones_systeme.ps1) | Audit zones système Windows |
| [optimiser_demarrage.ps1](system/optimiser_demarrage.ps1) | Optimisation démarrage Flutter |

**Exécution:**
```powershell
.\scripts\system\optimiser_demarrage.ps1
```

---

### tests/
> Scripts de test

| Fichier | Description |
|---------|-------------|
| [test_delivery_filter.js](tests/test_delivery_filter.js) | Test filtres livraison |

**Exécution:**
```bash
node scripts/tests/test_delivery_filter.js
```

---

### database/
> Utilitaires base de données Firestore

| Fichier | Description |
|---------|-------------|
| [check_collections.js](database/check_collections.js) | Vérification collections Firestore |

**Exécution:**
```bash
node scripts/database/check_collections.js
```

---

## Prérequis

### Pour les scripts JavaScript (.js)
```bash
cd scripts
npm install
```

### Pour les scripts PowerShell (.ps1)
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

## Bonnes pratiques

1. **Toujours tester en développement** avant d'exécuter en production
2. **Faire une sauvegarde Firestore** avant les scripts de reset/migration
3. **Vérifier les logs** après exécution
4. **Utiliser les scripts de diagnostic** avant les scripts de correction

---

## Scripts critiques (à utiliser avec précaution)

| Script | Risque | Description |
|--------|--------|-------------|
| `commandes/reset_orders_*` | ÉLEVÉ | Supprime toutes les commandes |
| `stock/reset_*` | MOYEN | Réinitialise le stock |
| `admin/setup_super_admin.js` | MOYEN | Modifie les droits admin |

---

*Dernière mise à jour: Janvier 2026*
