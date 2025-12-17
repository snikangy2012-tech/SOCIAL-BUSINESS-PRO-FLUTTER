// Script pour réinitialiser toutes les réservations de stock
// Utiliser uniquement en cas d'urgence ou pour maintenance

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'social-media-business-pro'
});

const db = admin.firestore();

async function resetAllReservations() {
  try {
    console.log('🔄 Réinitialisation des réservations de stock...\n');

    // Récupérer tous les produits
    const productsSnapshot = await db.collection('products').get();

    console.log(`📦 ${productsSnapshot.size} produits trouvés\n`);

    let updatedCount = 0;
    let totalReleased = 0;

    const batch = db.batch();
    let batchCount = 0;

    for (const doc of productsSnapshot.docs) {
      const data = doc.data();
      const reservedStock = data.reservedStock || 0;

      if (reservedStock > 0) {
        console.log(`📤 ${data.name}: Libération de ${reservedStock} unité(s)`);

        batch.update(doc.ref, {
          reservedStock: 0,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        updatedCount++;
        totalReleased += reservedStock;
        batchCount++;

        // Firestore batch limit = 500 operations
        if (batchCount >= 500) {
          await batch.commit();
          console.log(`✅ Batch de ${batchCount} mises à jour effectué`);
          batchCount = 0;
        }
      }
    }

    // Commit final batch
    if (batchCount > 0) {
      await batch.commit();
      console.log(`✅ Batch final de ${batchCount} mises à jour effectué`);
    }

    console.log(`\n📊 RÉSUMÉ:`);
    console.log(`   Produits mis à jour: ${updatedCount}`);
    console.log(`   Total d'unités libérées: ${totalReleased}`);

    if (updatedCount === 0) {
      console.log('\n✅ Aucune réservation à réinitialiser');
    } else {
      console.log(`\n✅ ${totalReleased} unité(s) réservée(s) ont été libérées avec succès!`);
    }

  } catch (error) {
    console.error('❌ Erreur:', error);
  } finally {
    process.exit(0);
  }
}

// Confirmation avant exécution
console.log('⚠️  ATTENTION: Ce script va réinitialiser TOUTES les réservations de stock.');
console.log('⚠️  Cela peut affecter les commandes en cours de traitement.\n');
console.log('Exécution dans 3 secondes... (Ctrl+C pour annuler)\n');

setTimeout(resetAllReservations, 3000);
