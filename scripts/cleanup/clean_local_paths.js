// Script pour nettoyer les chemins locaux dans Firestore
// Les chemins locaux Android ne sont pas accessibles par les autres utilisateurs

const admin = require('firebase-admin');

admin.initializeApp({
  projectId: 'social-media-business-pro'
});

const db = admin.firestore();

async function cleanLocalPaths() {
  console.log('🧹 Nettoyage des chemins locaux dans Firestore...\n');

  try {
    const snapshot = await db.collection('products').get();

    if (snapshot.empty) {
      console.log('❌ Aucun produit trouvé');
      return;
    }

    console.log(`✅ ${snapshot.size} produits trouvés\n`);

    let cleanedCount = 0;
    let alreadyCleanCount = 0;
    let errorCount = 0;

    for (const doc of snapshot.docs) {
      const data = doc.data();
      const images = data.images || [];

      // Filtrer les chemins locaux
      const validImages = images.filter(url => {
        // Garder seulement les URLs HTTP/HTTPS valides
        return url &&
               typeof url === 'string' &&
               (url.startsWith('http://') || url.startsWith('https://'));
      });

      // Si des images ont été supprimées
      if (validImages.length !== images.length) {
        const removedCount = images.length - validImages.length;

        console.log(`📦 ${data.name || 'Sans nom'} (${doc.id})`);
        console.log(`   Images avant: ${images.length}`);
        console.log(`   Images après: ${validImages.length}`);
        console.log(`   Supprimées: ${removedCount} chemin(s) local/aux`);

        try {
          // Mettre à jour avec seulement les URLs valides (ou tableau vide)
          await doc.ref.update({
            images: validImages,
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
          });

          console.log(`   ✅ Nettoyé\n`);
          cleanedCount++;

        } catch (error) {
          console.log(`   ❌ Erreur: ${error.message}\n`);
          errorCount++;
        }

      } else if (images.length === 0) {
        console.log(`📦 ${data.name || 'Sans nom'} (${doc.id})`);
        console.log(`   ⚪ Déjà vide (pas d'images)\n`);
        alreadyCleanCount++;
      } else {
        console.log(`📦 ${data.name || 'Sans nom'} (${doc.id})`);
        console.log(`   ✅ Déjà propre (${images.length} URL(s) valide(s))\n`);
        alreadyCleanCount++;
      }
    }

    console.log('\n' + '='.repeat(60));
    console.log('📊 RÉSUMÉ:');
    console.log(`   Total produits: ${snapshot.size}`);
    console.log(`   Nettoyés: ${cleanedCount}`);
    console.log(`   Déjà propres: ${alreadyCleanCount}`);
    console.log(`   Erreurs: ${errorCount}`);
    console.log('='.repeat(60));

    console.log('\n💡 PROCHAINES ÉTAPES:');
    console.log('   1. Les produits nettoyés afficheront des placeholders Unsplash');
    console.log('   2. Les vendeurs doivent modifier leurs produits pour ajouter de vraies images');
    console.log('   3. Cette fois, les images seront uploadées vers Firebase Storage ✅');

  } catch (error) {
    console.error('❌ Erreur:', error.message);
  }

  process.exit(0);
}

cleanLocalPaths();
