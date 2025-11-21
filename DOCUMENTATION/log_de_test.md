11-14 14:49:25.108 32680 32680 I flutter : ❌ Erreur chargement produits: setState() called after dis
pose(): _CategoriesScreenState#20f39(lifecycle state: defunct, not mounted)
11-14 14:49:25.108 32680 32680 I flutter : This error happens if you call setState() on a State objec
t for a widget that no longer appears in the widget tree (e.g., whose parent widget no longer include
s the widget in its build). This error can occur when code calls setState() from a timer or an animat
ion callback.
11-14 14:49:25.108 32680 32680 I flutter : The preferred solution is to cancel the timer or stop list
ening to the animation in the dispose() callback. Another solution is to check the "mounted" property
 of this object before calling setState() to ensure the object is still in the tree.
11-14 14:49:25.108 32680 32680 I flutter : This error might indicate a memory leak if setState() is b
eing called because another object is retaining a reference to this State object after it has been re
moved from the tree. To avoid memory leaks, consider breaking the reference to this object during dis
pose().
11-14 14:49:25.111 32680 32680 E flutter : [ERROR:flutter/runtime/dart_vm_initializer.cc(40)] Unhandl
ed Exception: setState() called after dispose(): _CategoriesScreenState#20f39(lifecycle state: defunc
t, not mounted)
11-14 14:49:25.111 32680 32680 E flutter : This error happens if you call setState() on a State objec
t for a widget that no longer appears in the widget tree (e.g., whose parent widget no longer include
s the widget in its build). This error can occur when code calls setState() from a timer or an animat
ion callback.
11-14 14:49:25.111 32680 32680 E flutter : The preferred solution is to cancel the timer or stop list
ening to the animation in the dispose() callback. Another solution is to check the "mounted" property
 of this object before calling setState() to ensure the object is still in the tree.
11-14 14:49:25.111 32680 32680 E flutter : This error might indicate a memory leak if setState() is b
eing called because another object is retaining a reference to this State object after it has been re
moved from the tree. To avoid memory leaks, consider breaking the reference to this object during dis
pose().
11-14 14:49:25.111 32680 32680 E flutter : #0      State.setState.<anonymous closure> (package:flutte
r/src/widgets/framework.dart:1163:9)
11-14 14:49:25.111 32680 32680 E flutter : #1      State.setState (package:flutter/src/widgets/framew
ork.dart:1198:6)
11-14 14:49:25.111 32680 32680 E flutter : #2      _CategoriesScreenState._loadProducts (package:soci
al_business_pro/screens/acheteur/categories_screen.dart:77:7)
11-14 14:49:25.111 32680 32680 E flutter : <asynchronous suspension>
11-14 14:49:25.111 32680 32680 E flutter :
11-14 14:49:25.113 32680 32680 I flutter : ✅ 2 produits chargés
11-14 14:49:25.114 32680 32680 I flutter : � Répartition: {mode: 2}
11-14 14:49:25.114 32680 32680 I flutter : � Sous-catégories: {mode:Chaussures: 1, mode:Costumes Hom
me: 1}
11-14 14:49:25.118 32680 32680 E flutter : [ERROR:flutter/runtime/dart_vm_initializer.cc(40)] Unhandl
ed Exception: setState() called after dispose(): _FavoriteScreenState#5cdd9(lifecycle state: defunct,
 not mounted, ticker inactive)
11-14 14:49:25.118 32680 32680 E flutter : This error happens if you call setState() on a State objec
t for a widget that no longer appears in the widget tree (e.g., whose parent widget no longer include
s the widget in its build). This error can occur when code calls setState() from a timer or an animat
ion callback.
11-14 14:49:25.118 32680 32680 E flutter : The preferred solution is to cancel the timer or stop list
ening to the animation in the dispose() callback. Another solution is to check the "mounted" property
 of this object before calling setState() to ensure the object is still in the tree.
11-14 14:49:25.118 32680 32680 E flutter : This error might indicate a memory leak if setState() is b
eing called because another object is retaining a reference to this State object after it has been re
moved from the tree. To avoid memory leaks, consider breaking the reference to this object during dis
pose().
11-14 14:49:25.118 32680 32680 E flutter : #0      State.setState.<anonymous closure> (package:flutte
r/src/widgets/framework.dart:1163:9)
11-14 14:49:25.118 32680 32680 E flutter : #1      State.setState (package:flutter/src/widgets/framew
ork.dart:1198:6)
11-14 14:49:25.118 32680 32680 E flutter : #2      _FavoriteScreenState._loadFavorites (package:socia
l_business_pro/screens/acheteur/favorite_screen.dart:76:5)
11-14 14:49:25.118 32680 32680 E flutter : <asynchronous suspension>
11-14 14:49:25.118 32680 32680 E flutter :
11-14 14:49:25.392 32680 32680 I flutter : � Event logged: screen_view
11-14 14:49:25.393 32680 32680 I flutter : � Event logged: screen_view
11-14 14:49:25.394 32680 32680 I flutter : � Event logged: screen_view
11-14 14:49:25.394 32680 32680 I flutter : � Event logged: screen_view
11-14 14:49:25.396 32680 32680 I flutter : � Event logged: screen_view
11-14 14:49:46.541 32680 32680 I flutter : � Tentative de connexion: livreurtest3@test.ci
11-14 14:49:46.541 32680 32680 I flutter : � Tentative connexion: livreurtest3@test.ci
11-14 14:49:48.010 32680 32680 I flutter : ✅ Firestore connecté
11-14 14:49:48.014 32680 32680 I flutter : ✅ Firestore connecté
11-14 14:49:48.339 32680 32680 I flutter : ✅ Utilisateur chargé: Livreur Test
11-14 14:49:48.343 32680 32680 I flutter : ✅ Utilisateur chargé: Livreur Test
11-14 14:49:48.344 32680 32680 I flutter : ✅ Connexion réussie: Livreur Test
11-14 14:49:48.344 32680 32680 I flutter : ❌ Erreur: Exception: Email non vérifié. Vérifiez votre bo
îte email.
11-14 14:49:48.347 32680 32680 I flutter : � CartProvider: setUserId appelé avec userId: vxSgsJKhoOb
IykDul8u6LAYZLit1
11-14 14:49:48.348 32680 32680 I flutter : � CartProvider: Chargement du panier pour userId: vxSgsJK
hoObIykDul8u6LAYZLit1
11-14 14:49:48.348 32680 32680 I flutter : � CartProvider: Chargement du panier pour userId: vxSgsJK
hoObIykDul8u6LAYZLit1
11-14 14:49:48.350 32680 32680 I flutter : � FavoriteProvider: setUserId appelé avec userId: vxSgsJK
hoObIykDul8u6LAYZLit1
11-14 14:49:48.350 32680 32680 I flutter : � FavoriteProvider: Chargement des favoris pour userId: v
xSgsJKhoObIykDul8u6LAYZLit1
11-14 14:49:48.350 32680 32680 I flutter : ⭐ FavoriteProvider: Chargement des favoris pour userId: v
xSgsJKhoObIykDul8u6LAYZLit1
11-14 14:49:49.018 32680 32680 I flutter : � === DeliveryDashboard initState ===
11-14 14:49:49.018 32680 32680 I flutter : � Chargement dashboard livreur
11-14 14:49:49.019 32680 32680 I flutter : ✅ User validé: Livreur Test (livreur)
11-14 14:49:49.019 32680 32680 I flutter : � Chargement statistiques livreur...
11-14 14:49:49.019 32680 32680 I flutter : � === Calcul statistiques livreur: vxSgsJKhoObIykDul8u6LA
YZLit1 ===
11-14 14:49:49.393 32680 32680 I flutter : ℹ️ CartProvider: Aucun panier existant, création d'un nouv
eau
11-14 14:49:49.394 32680 32680 I flutter : ℹ️ FavoriteProvider: Aucun favori existant, création d'une
 nouvelle liste
11-14 14:49:49.399 32680 32680 E flutter : [ERROR:flutter/runtime/dart_vm_initializer.cc(40)] Unhandl
ed Exception: setState() called after dispose(): _FavoriteScreenState#34b99(lifecycle state: defunct,
 not mounted, ticker inactive)
11-14 14:49:49.399 32680 32680 E flutter : This error happens if you call setState() on a State objec
t for a widget that no longer appears in the widget tree (e.g., whose parent widget no longer include
s the widget in its build). This error can occur when code calls setState() from a timer or an animat
ion callback.
11-14 14:49:49.399 32680 32680 E flutter : The preferred solution is to cancel the timer or stop list
ening to the animation in the dispose() callback. Another solution is to check the "mounted" property
 of this object before calling setState() to ensure the object is still in the tree.
11-14 14:49:49.399 32680 32680 E flutter : This error might indicate a memory leak if setState() is b
eing called because another object is retaining a reference to this State object after it has been re
moved from the tree. To avoid memory leaks, consider breaking the reference to this object during dis
pose().
11-14 14:49:49.399 32680 32680 E flutter : #0      State.setState.<anonymous closure> (package:flutte
r/src/widgets/framework.dart:1163:9)
11-14 14:49:49.399 32680 32680 E flutter : #1      State.setState (package:flutter/src/widgets/framew
ork.dart:1198:6)
11-14 14:49:49.399 32680 32680 E flutter : #2      _FavoriteScreenState._loadFavorites (package:socia
l_business_pro/screens/acheteur/favorite_screen.dart:76:5)
11-14 14:49:49.399 32680 32680 E flutter : <asynchronous suspension>
11-14 14:49:49.399 32680 32680 E flutter :
11-14 14:49:49.402 32680 32680 I flutter : ❌ Erreur chargement produits: setState() called after dis
pose(): _CategoriesScreenState#9cbb3(lifecycle state: defunct, not mounted)
11-14 14:49:49.402 32680 32680 I flutter : This error happens if you call setState() on a State objec
t for a widget that no longer appears in the widget tree (e.g., whose parent widget no longer include
s the widget in its build). This error can occur when code calls setState() from a timer or an animat
ion callback.
11-14 14:49:49.402 32680 32680 I flutter : The preferred solution is to cancel the timer or stop list
ening to the animation in the dispose() callback. Another solution is to check the "mounted" property
 of this object before calling setState() to ensure the object is still in the tree.
11-14 14:49:49.402 32680 32680 I flutter : This error might indicate a memory leak if setState() is b
eing called because another object is retaining a reference to this State object after it has been re
moved from the tree. To avoid memory leaks, consider breaking the reference to this object during dis
pose().
11-14 14:49:49.404 32680 32680 E flutter : [ERROR:flutter/runtime/dart_vm_initializer.cc(40)] Unhandl
ed Exception: setState() called after dispose(): _CategoriesScreenState#9cbb3(lifecycle state: defunc
t, not mounted)
11-14 14:49:49.404 32680 32680 E flutter : This error happens if you call setState() on a State objec
t for a widget that no longer appears in the widget tree (e.g., whose parent widget no longer include
s the widget in its build). This error can occur when code calls setState() from a timer or an animat
ion callback.
11-14 14:49:49.404 32680 32680 E flutter : The preferred solution is to cancel the timer or stop list
ening to the animation in the dispose() callback. Another solution is to check the "mounted" property
 of this object before calling setState() to ensure the object is still in the tree.
11-14 14:49:49.404 32680 32680 E flutter : This error might indicate a memory leak if setState() is b
eing called because another object is retaining a reference to this State object after it has been re
moved from the tree. To avoid memory leaks, consider breaking the reference to this object during dis
pose().
11-14 14:49:49.404 32680 32680 E flutter : #0      State.setState.<anonymous closure> (package:flutte
r/src/widgets/framework.dart:1163:9)
11-14 14:49:49.404 32680 32680 E flutter : #1      State.setState (package:flutter/src/widgets/framew
ork.dart:1198:6)
11-14 14:49:49.404 32680 32680 E flutter : #2      _CategoriesScreenState._loadProducts (package:soci
al_business_pro/screens/acheteur/categories_screen.dart:77:7)
11-14 14:49:49.404 32680 32680 E flutter : <asynchronous suspension>
11-14 14:49:49.404 32680 32680 E flutter :
11-14 14:49:49.527 32680 32680 I flutter : � Total livraisons: 0
11-14 14:49:49.528 32680 32680 I flutter : � Pending: 0
11-14 14:49:49.528 32680 32680 I flutter : � Picked Up: 0
11-14 14:49:49.528 32680 32680 I flutter : � In Progress: 0
11-14 14:49:49.528 32680 32680 I flutter : � Delivered: 0
11-14 14:49:49.528 32680 32680 I flutter : � Cancelled: 0
11-14 14:49:49.528 32680 32680 I flutter : � Total Earnings: 0
11-14 14:49:49.528 32680 32680 I flutter : � Chargement livraisons récentes...
11-14 14:49:49.528 32680 32680 I flutter : � Chargement livraisons récentes livreur: vxSgsJKhoObIykD
ul8u6LAYZLit1
11-14 14:49:49.821 32680 32680 I flutter : � Récupération des avis pour le livreur: vxSgsJKhoObIykDu
l8u6LAYZLit1
11-14 14:49:49.824 32680 32680 I flutter : � Event logged: screen_view
11-14 14:49:49.825 32680 32680 I flutter : � Event logged: screen_view
11-14 14:49:49.825 32680 32680 I flutter : � Event logged: screen_view
11-14 14:49:49.877 32680 32680 I flutter : ✅ 0 livraisons récentes chargées
11-14 14:49:49.879 32680 32680 I flutter : ⭐ Chargement note moyenne...
11-14 14:49:49.881 32680 32680 I flutter : � Récupération des avis pour le livreur: vxSgsJKhoObIykDu
l8u6LAYZLit1
11-14 14:49:50.172 32680 32680 I flutter : ❌ Erreur lors de la récupération des avis: [cloud_firesto
re/failed-precondition] The query requires an index. You can create it here: https://console.firebase
.google.com/v1/r/project/social-media-business-pro/firestore/indexes?create_composite=Cllwcm9qZWN0cy9
zb2NpYWwtbWVkaWEtYnVzaW5lc3MtcHJvL2RhdGFiYXNlcy8oZGVmYXVsdCkvY29sbGVjdGlvbkdyb3Vwcy9yZXZpZXdzL2luZGV4
ZXMvXxABGgwKCHRhcmdldElkEAEaDgoKdGFyZ2V0VHlwZRABGg0KCWNyZWF0ZWRBdBACGgwKCF9fbmFtZV9fEAI
11-14 14:49:50.173 32680 32680 I flutter : ❌ Erreur lors du calcul de la note moyenne: [cloud_firest
ore/failed-precondition] The query requires an index. You can create it here: https://console.firebas
e.google.com/v1/r/project/social-media-business-pro/firestore/indexes?create_composite=Cllwcm9qZWN0cy
9zb2NpYWwtbWVkaWEtYnVzaW5lc3MtcHJvL2RhdGFiYXNlcy8oZGVmYXVsdCkvY29sbGVjdGlvbkdyb3Vwcy9yZXZpZXdzL2luZGV
4ZXMvXxABGgwKCHRhcmdldElkEAEaDgoKdGFyZ2V0VHlwZRABGg0KCWNyZWF0ZWRBdBACGgwKCF9fbmFtZV9fEAI
11-14 14:49:50.173 32680 32680 I flutter : ⭐ Note moyenne livreur chargée: 0.0
11-14 14:49:50.174 32680 32680 I flutter : ❌ Erreur lors de la récupération des avis: [cloud_firesto
re/failed-precondition] The query requires an index. You can create it here: https://console.firebase
.google.com/v1/r/project/social-media-business-pro/firestore/indexes?create_composite=Cllwcm9qZWN0cy9
zb2NpYWwtbWVkaWEtYnVzaW5lc3MtcHJvL2RhdGFiYXNlcy8oZGVmYXVsdCkvY29sbGVjdGlvbkdyb3Vwcy9yZXZpZXdzL2luZGV4
ZXMvXxABGgwKCHRhcmdldElkEAEaDgoKdGFyZ2V0VHlwZRABGg0KCWNyZWF0ZWRBdBACGgwKCF9fbmFtZV9fEAI
11-14 14:49:50.175 32680 32680 I flutter : ❌ Erreur lors du calcul de la note moyenne: [cloud_firest
ore/failed-precondition] The query requires an index. You can create it here: https://console.firebas
e.google.com/v1/r/project/social-media-business-pro/firestore/indexes?create_composite=Cllwcm9qZWN0cy
9zb2NpYWwtbWVkaWEtYnVzaW5lc3MtcHJvL2RhdGFiYXNlcy8oZGVmYXVsdCkvY29sbGVjdGlvbkdyb3Vwcy9yZXZpZXdzL2luZGV
4ZXMvXxABGgwKCHRhcmdldElkEAEaDgoKdGFyZ2V0VHlwZRABGg0KCWNyZWF0ZWRBdBACGgwKCF9fbmFtZV9fEAI
11-14 14:49:50.175 32680 32680 I flutter : ✅ Dashboard livreur chargé avec succès
11-14 14:49:50.176 32680 32680 I flutter : � Stats: 0 livraisons, 0 FCFA, Note: 0.0
11-14 14:50:09.034 32680 32680 I flutter : � Auto-refresh deliveries
11-14 14:50:29.033 32680 32680 I flutter : � Auto-refresh deliveries
11-14 14:50:40.709 32680 32680 I flutter : � Récupération position actuelle...
11-14 14:50:40.873 32680 32680 I flutter : � Vérification permissions localisation...
11-14 14:50:40.880 32680 32680 I flutter : � Permission actuelle: LocationPermission.whileInUse
11-14 14:50:40.880 32680 32680 I flutter : ✅ Permission accordée: LocationPermission.whileInUse
11-14 14:50:40.943 32680 32680 I flutter : ✅ Position obtenue: 5.3677778, -3.9047904
11-14 14:50:40.978 32680 32680 I flutter : � Stream commandes triées par distance démarré
11-14 14:50:40.978 32680 32680 I flutter : � Stream commandes disponibles démarré
11-14 14:50:41.034 32680 32680 I flutter : � 0 commandes disponibles dans le stream
11-14 14:50:41.283 32680 32680 I flutter : ✅ Position livreur mise à jour: 5.3677778, -3.9047904
11-14 14:50:49.034 32680 32680 I flutter : � Auto-refresh deliveries
11-14 14:51:09.033 32680 32680 I flutter : � Auto-refresh deliveries
11-14 14:51:29.034 32680 32680 I flutter : � Auto-refresh deliveries
11-14 14:51:49.034 32680 32680 I flutter : � Auto-refresh deliveries
11-14 14:52:09.039 32680 32680 I flutter : � Auto-refresh deliveries
11-14 14:52:14.868 32680 32680 I flutter : ✅ Firestore connecté
11-14 14:52:29.039 32680 32680 I flutter : � Auto-refresh deliveries
11-14 14:52:36.072 32680 32680 I flutter : ✅ Firestore connecté
11-14 14:52:40.590 32680 32680 I flutter : ✅ Firestore connecté
11-14 14:52:49.034 32680 32680 I flutter : � Auto-refresh deliveries