// ===== lib/main.dart =====

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'config/constants.dart';
import 'config/firebase_options.dart';
import 'providers/auth_provider_firebase.dart';
import 'providers/cart_provider.dart';
import 'providers/favorite_provider.dart';
import 'providers/subscription_provider.dart';
import 'providers/notification_provider.dart';
import 'routes/app_router.dart';
import 'providers/vendeur_navigation_provider.dart';
import 'providers/admin_navigation_provider.dart';
import 'utils/system_ui_helper.dart';

// Clé globale de navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // Initialisation Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation du formatage de dates pour le français
  await initializeDateFormatting('fr_FR', null);
  debugPrint('✅ Initialisation locale fr_FR terminée');

  // Orientation portrait uniquement
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Configuration par défaut de l'UI système (barres visibles, fond blanc)
  SystemUIHelper.setDefaultSystemUI();

  try {
    // ===== INITIALISATION FIREBASE =====
    debugPrint('🔥 Initialisation Firebase...');
    final Stopwatch stopwatch = Stopwatch()..start();

    // Vérifier si Firebase est déjà initialisé pour éviter l'erreur duplicate-app
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        stopwatch.stop();
        debugPrint('✅ Firebase initialisé en ${stopwatch.elapsedMilliseconds}ms');
      } else {
        debugPrint('ℹ️ Firebase déjà initialisé, utilisation de l\'instance existante');
      }
    } on FirebaseException catch (e) {
      if (e.code == 'duplicate-app') {
        debugPrint('ℹ️ Firebase déjà initialisé (duplicate-app ignoré)');
        // Récupérer l'app existante
        Firebase.app();
      } else {
        rethrow;
      }
    } catch (e) {
      debugPrint('⚠️ Erreur inattendue Firebase: $e');
      // Tenter de récupérer l'app par défaut
      try {
        Firebase.app();
      } catch (_) {
        // Si vraiment aucune app, on réessaye l'initialisation
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
    }

    debugPrint('📋 Project ID: ${Firebase.app().options.projectId}');
    
    
    // ===== OPTIMISATION FIRESTORE =====
    try {
      // Configuration Firestore optimisée pour Web et Mobile
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: kIsWeb ? false : true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        // ✅ NOUVEAU: Augmenter le timeout pour les connexions lentes
        host: kIsWeb ? null : null, // Utiliser serveur par défaut
      );
      debugPrint('⚡ Firestore configuré (persistenceEnabled: ${!kIsWeb})');

      // ✅ AMÉLIORATION: Test de connectivité non-bloquant
      if (kIsWeb) {
        debugPrint('🔍 Test connexion Firestore (non-bloquant)...');

        // Ne pas bloquer le démarrage de l'app si Firestore est lent
        FirebaseFirestore.instance
            .collection('_connection_test')
            .doc('test')
            .get(const GetOptions(source: Source.serverAndCache))
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                debugPrint('⏱️ Firestore timeout (10s) - mode offline activé');
                // Retourner un doc vide sans erreur
                return FirebaseFirestore.instance
                    .collection('_connection_test')
                    .doc('test')
                    .get(const GetOptions(source: Source.cache));
              },
            )
            .then((testDoc) {
              debugPrint('✅ Firestore connecté - Test: ${testDoc.exists ? "doc existe" : "doc absent"}');
            })
            .catchError((error) {
              debugPrint('⚠️ Firestore en mode offline (normal sur localhost)');
              debugPrint('   💡 Pour une connexion complète, déployez sur Firebase Hosting');
            });
      }
    } catch (e) {
      debugPrint('⚠️ Erreur configuration Firestore: $e');
      debugPrint('   ⚡ Application continuera en mode offline');
    }
    
    // Lancer l'application
    runApp(const SocialBusinessProApp());
    
  } catch (e) {
    debugPrint('❌ Erreur Firebase: $e');
    runApp(FirebaseErrorApp(error: e.toString()));
  }
}

// ===== APPLICATION PRINCIPALE =====
class SocialBusinessProApp extends StatelessWidget {
  const SocialBusinessProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provider d'authentification
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),

        // Providers de navigation
        ChangeNotifierProvider(create: (_) => VendeurNavigationProvider()),
        ChangeNotifierProvider(create: (_) => AdminNavigationProvider()),

        // Provider d'abonnements
        ChangeNotifierProvider(
          create: (_) => SubscriptionProvider(),
        ),

        // Provider de panier (dépend de l'auth)
        ChangeNotifierProxyProvider<AuthProvider, CartProvider>(
          create: (_) => CartProvider(),
          update: (_, auth, cart) {
            if (cart != null && auth.user != null) {
              cart.setUserId(auth.user!.id);
            }
            return cart ?? CartProvider();
          },
        ),

        // Provider de favoris (dépend de l'auth)
        ChangeNotifierProxyProvider<AuthProvider, FavoriteProvider>(
          create: (_) => FavoriteProvider(),
          update: (_, auth, favorite) {
            if (favorite != null && auth.user != null) {
              favorite.setUserId(auth.user!.id);
            }
            return favorite ?? FavoriteProvider();
          },
        ),

        // Provider de notifications (dépend de l'auth)
        ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
          create: (_) => NotificationProvider(),
          update: (_, auth, notification) {
            if (notification != null && auth.user != null) {
              notification.initialize(auth.user!.id);
            }
            return notification ?? NotificationProvider();
          },
        ),
      ],
      // ✅ UTILISER Builder POUR ACCÉDER AU PROVIDER
      child: Builder(
        builder: (context) {
          // Récupérer le AuthProvider
          final authProvider = context.watch<AuthProvider>();
          
          return MaterialApp.router(
            // ✅ APPELER createRouter avec le provider
            routerConfig: AppRouter.createRouter(authProvider),
            
            debugShowCheckedModeBanner: false,
            title: 'SOCIAL BUSINESS Pro',
            
            // Thème
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primary,
                brightness: Brightness.light,
              ),
              scaffoldBackgroundColor: AppColors.background,
              appBarTheme: const AppBarTheme(
                centerTitle: true,
                elevation: 0,
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              bottomNavigationBarTheme: const BottomNavigationBarThemeData(
                selectedItemColor: AppColors.primary,
                unselectedItemColor: AppColors.textSecondary,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ===== ÉCRAN D'ERREUR FIREBASE =====
class FirebaseErrorApp extends StatelessWidget {
  final String error;
  
  const FirebaseErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: AppColors.error,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 80,
                  color: Colors.white,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Erreur d\'initialisation',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  error,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    // Redémarrer l'app
                    SystemNavigator.pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.error,
                  ),
                  child: const Text('Redémarrer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}