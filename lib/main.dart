// ===== lib/main.dart =====

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'config/constants.dart';
import 'config/firebase_options.dart';
import 'providers/auth_provider_firebase.dart';
import 'providers/cart_provider.dart';
import 'providers/subscription_provider.dart';
import 'routes/app_router.dart';
import 'providers/vendeur_navigation_provider.dart';

// Clé globale de navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // Initialisation Flutter
  WidgetsFlutterBinding.ensureInitialized();
  
  // Orientation portrait uniquement
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  try {
    // ===== INITIALISATION FIREBASE =====
    debugPrint('🔥 Initialisation Firebase...');
    final Stopwatch stopwatch = Stopwatch()..start();

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    stopwatch.stop();
    debugPrint('✅ Firebase initialisé en ${stopwatch.elapsedMilliseconds}ms');
    
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
        ChangeNotifierProvider(create: (_) => VendeurNavigationProvider()),

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