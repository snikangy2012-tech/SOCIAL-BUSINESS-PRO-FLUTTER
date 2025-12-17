// Script Dart pour diagnostiquer les images des produits
// À exécuter avec: dart run diagnostic_images.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  print('🔍 Diagnostic des images produits...\n');

  try {
    // Initialiser Firebase
    await Firebase.initializeApp();

    final db = FirebaseFirestore.instance;

    // Récupérer les premiers produits
    final snapshot = await db.collection('products').limit(10).get();

    if (snapshot.docs.isEmpty) {
      print('❌ Aucun produit trouvé');
      return;
    }

    print('✅ ${snapshot.docs.length} produits trouvés\n');
    print('=' * 80);

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final images = data['images'] as List? ?? [];

      print('\n📦 Produit: ${data['name'] ?? 'Sans nom'}');
      print('   ID: ${doc.id}');
      print('   Catégorie: ${data['category'] ?? 'N/A'}');
      print('   Vendeur: ${data['vendeurName'] ?? data['vendeurId'] ?? 'N/A'}');
      print('   Créé le: ${data['createdAt']?.toDate() ?? 'N/A'}');

      if (images.isEmpty) {
        print('   ❌ Images: AUCUNE (champ vide)');
      } else {
        print('   📸 Images: ${images.length} image(s)');
        for (var i = 0; i < images.length; i++) {
          final url = images[i] as String;
          print('\n      Image ${i + 1}:');
          print('      URL: $url');

          // Analyser l'URL
          if (url.isEmpty) {
            print('      ❌ URL vide');
          } else if (url.contains('firebasestorage.googleapis.com')) {
            print('      ✅ Type: Firebase Storage');

            // Extraire le chemin
            final uri = Uri.parse(url);
            final pathMatch = RegExp(r'/o/([^?]+)').firstMatch(url);
            if (pathMatch != null) {
              final encodedPath = pathMatch.group(1);
              final decodedPath = Uri.decodeComponent(encodedPath ?? '');
              print('      📁 Chemin: $decodedPath');

              // Vérifier le format du chemin
              if (decodedPath.startsWith('products/')) {
                final parts = decodedPath.split('/');
                if (parts.length >= 3) {
                  print('      🆔 ID dans chemin: ${parts[1]}');
                  print('      📄 Fichier: ${parts[2]}');

                  // Vérifier si l'ID correspond
                  if (parts[1] == doc.id) {
                    print('      ✅ Chemin correct: products/{productId}/...');
                  } else if (parts[1] == data['vendeurId']) {
                    print('      ⚠️  Ancien chemin: products/{vendeurId}/...');
                    print('      💡 Suggestion: Migrer vers products/${doc.id}/${parts[2]}');
                  } else {
                    print('      ⚠️  ID inconnu: ${parts[1]}');
                  }
                }
              } else {
                print('      ⚠️  Chemin inattendu: $decodedPath');
              }
            }

            // Vérifier le token
            if (url.contains('token=')) {
              print('      ✅ Token présent');
            } else {
              print('      ⚠️  Token manquant (l\'image pourrait ne pas charger)');
            }

          } else if (url.contains('unsplash.com')) {
            print('      ⚠️  Type: Unsplash (placeholder)');
          } else if (url.startsWith('http://') || url.startsWith('https://')) {
            print('      ⚠️  Type: URL externe');
            print('      🌐 Domaine: ${Uri.parse(url).host}');
          } else {
            print('      ❌ Format invalide');
          }
        }
      }

      print('\n' + '=' * 80);
    }

    print('\n\n📊 RECOMMANDATIONS:\n');
    print('1. Si vous voyez "Ancien chemin: products/{vendeurId}/..."');
    print('   → Les images existent mais avec un mauvais chemin');
    print('   → Exécutez le script de migration');
    print('');
    print('2. Si vous voyez "Chemin correct: products/{productId}/..."');
    print('   → Les images sont bien configurées');
    print('   → Vérifiez les règles Storage');
    print('');
    print('3. Si vous voyez "Images: AUCUNE"');
    print('   → Les images doivent être uploadées via l\'app');
    print('');

  } catch (e, stackTrace) {
    print('❌ Erreur: $e');
    print('Stack trace: $stackTrace');
  }
}
