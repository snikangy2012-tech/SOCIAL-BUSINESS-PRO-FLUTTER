// Script pour nettoyer les livraisons dupliquées
// Garde uniquement la première livraison créée pour chaque commande

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'social-media-business-pro'
});

const db = admin.firestore();

async function cleanDuplicateDeliveries() {
  try {
    console.log('🔍 Recherche des livraisons dupliquées...\n');

    // Récupérer toutes les livraisons
    const deliveriesSnapshot = await db.collection('deliveries').get();

    console.log(`📦 ${deliveriesSnapshot.size} livraisons trouvées au total\n`);

    // Grouper par orderId
    const deliveriesByOrder = {};

    deliveriesSnapshot.forEach(doc => {
      const data = doc.data();
      const orderId = data.orderId;

      if (!deliveriesByOrder[orderId]) {
        deliveriesByOrder[orderId] = [];
      }

      deliveriesByOrder[orderId].push({
        id: doc.id,
        data: data,
        createdAt: data.createdAt?.toDate() || new Date(0)
      });
    });

    // Analyser les doublons
    let totalOrders = 0;
    let ordersWithDuplicates = 0;
    let totalDuplicates = 0;
    const duplicatesToDelete = [];

    for (const [orderId, deliveries] of Object.entries(deliveriesByOrder)) {
      totalOrders++;

      if (deliveries.length > 1) {
        ordersWithDuplicates++;

        // Trier par date de création (garder la plus ancienne)
        deliveries.sort((a, b) => a.createdAt - b.createdAt);

        const toKeep = deliveries[0];
        const toDelete = deliveries.slice(1);

        totalDuplicates += toDelete.length;

        console.log(`🔴 Commande ${orderId.substring(0, 8)}... a ${deliveries.length} livraisons:`);
        console.log(`   ✅ Garder: ${toKeep.id.substring(0, 8)} (créée le ${toKeep.createdAt.toLocaleString()})`);

        toDelete.forEach(dup => {
          console.log(`   ❌ Supprimer: ${dup.id.substring(0, 8)} (créée le ${dup.createdAt.toLocaleString()})`);
          duplicatesToDelete.push(dup.id);
        });

        console.log('');
      }
    }

    // Résumé
    console.log('📊 RÉSUMÉ:');
    console.log(`   Total commandes: ${totalOrders}`);
    console.log(`   Commandes avec doublons: ${ordersWithDuplicates}`);
    console.log(`   Total doublons à supprimer: ${totalDuplicates}`);
    console.log('');

    if (duplicatesToDelete.length === 0) {
      console.log('✅ Aucun doublon trouvé ! Base de données propre.');
      return;
    }

    // Suppression des doublons
    console.log('🗑️  Suppression des doublons...\n');

    const batch = db.batch();
    let batchCount = 0;

    for (const deliveryId of duplicatesToDelete) {
      const docRef = db.collection('deliveries').doc(deliveryId);
      batch.delete(docRef);
      batchCount++;

      // Firestore batch limit = 500 operations
      if (batchCount >= 500) {
        await batch.commit();
        console.log(`✅ Batch de ${batchCount} suppressions effectué`);
        batchCount = 0;
      }
    }

    // Commit final batch
    if (batchCount > 0) {
      await batch.commit();
      console.log(`✅ Batch final de ${batchCount} suppressions effectué`);
    }

    console.log(`\n✅ ${duplicatesToDelete.length} livraisons dupliquées supprimées avec succès !`);

  } catch (error) {
    console.error('❌ Erreur:', error);
  } finally {
    process.exit(0);
  }
}

// Exécuter
cleanDuplicateDeliveries();
