// Script pour réinitialiser TOUTES les commandes et livraisons
// ⚠️ ATTENTION : Cette action est IRRÉVERSIBLE !

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'social-media-business-pro'
});

const db = admin.firestore();

async function resetOrdersAndDeliveries() {
  try {
    console.log('⚠️  ═══════════════════════════════════════════════════════');
    console.log('⚠️  RÉINITIALISATION COMPLÈTE DES COMMANDES ET LIVRAISONS');
    console.log('⚠️  ═══════════════════════════════════════════════════════');
    console.log('');
    console.log('Cette action va :');
    console.log('  1. Supprimer TOUTES les commandes');
    console.log('  2. Supprimer TOUTES les livraisons');
    console.log('  3. Libérer TOUTES les réservations de stock');
    console.log('  4. Réinitialiser les compteurs de commandes');
    console.log('');
    console.log('⚠️  CETTE ACTION EST IRRÉVERSIBLE !');
    console.log('');
    console.log('Annulation possible avec Ctrl+C...');
    console.log('Exécution dans 10 secondes...');
    console.log('');

    await new Promise(resolve => setTimeout(resolve, 10000));

    console.log('🔄 Début de la réinitialisation...\n');

    // ═══════════════════════════════════════════════════════════════
    // ÉTAPE 1 : Récupérer les statistiques avant suppression
    // ═══════════════════════════════════════════════════════════════
    console.log('📊 STATISTIQUES AVANT SUPPRESSION:\n');

    const ordersSnapshot = await db.collection('orders').get();
    const deliveriesSnapshot = await db.collection('deliveries').get();

    console.log(`   📦 Commandes: ${ordersSnapshot.size}`);
    console.log(`   🚚 Livraisons: ${deliveriesSnapshot.size}`);

    // Grouper par statut
    const ordersByStatus = {};
    const deliveriesByStatus = {};

    ordersSnapshot.forEach(doc => {
      const status = doc.data().status || 'unknown';
      ordersByStatus[status] = (ordersByStatus[status] || 0) + 1;
    });

    deliveriesSnapshot.forEach(doc => {
      const status = doc.data().status || 'unknown';
      deliveriesByStatus[status] = (deliveriesByStatus[status] || 0) + 1;
    });

    console.log('\n   Commandes par statut:');
    Object.entries(ordersByStatus).forEach(([status, count]) => {
      console.log(`      - ${status}: ${count}`);
    });

    console.log('\n   Livraisons par statut:');
    Object.entries(deliveriesByStatus).forEach(([status, count]) => {
      console.log(`      - ${status}: ${count}`);
    });

    console.log('\n');

    // ═══════════════════════════════════════════════════════════════
    // ÉTAPE 2 : Libérer toutes les réservations de stock
    // ═══════════════════════════════════════════════════════════════
    console.log('📤 Libération des réservations de stock...\n');

    const productsSnapshot = await db.collection('products').get();
    let totalReservedReleased = 0;
    let productsWithReservations = 0;

    const stockBatch = db.batch();
    let stockBatchCount = 0;

    productsSnapshot.forEach(doc => {
      const data = doc.data();
      const reservedStock = data.reservedStock || 0;

      if (reservedStock > 0) {
        console.log(`   📦 ${data.name}: ${reservedStock} unité(s) réservées → libérées`);

        stockBatch.update(doc.ref, {
          reservedStock: 0,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        productsWithReservations++;
        totalReservedReleased += reservedStock;
        stockBatchCount++;

        if (stockBatchCount >= 500) {
          stockBatch.commit();
          stockBatchCount = 0;
        }
      }
    });

    if (stockBatchCount > 0) {
      await stockBatch.commit();
    }

    console.log(`\n   ✅ ${totalReservedReleased} unité(s) libérée(s) sur ${productsWithReservations} produit(s)\n`);

    // ═══════════════════════════════════════════════════════════════
    // ÉTAPE 3 : Supprimer toutes les livraisons
    // ═══════════════════════════════════════════════════════════════
    console.log('🗑️  Suppression des livraisons...\n');

    let deliveriesBatch = db.batch();
    let deliveriesBatchCount = 0;
    let deliveriesDeleted = 0;

    for (const doc of deliveriesSnapshot.docs) {
      deliveriesBatch.delete(doc.ref);
      deliveriesBatchCount++;
      deliveriesDeleted++;

      if (deliveriesBatchCount >= 500) {
        await deliveriesBatch.commit();
        console.log(`   ✅ Batch de ${deliveriesBatchCount} livraisons supprimées`);
        deliveriesBatch = db.batch();
        deliveriesBatchCount = 0;
      }
    }

    if (deliveriesBatchCount > 0) {
      await deliveriesBatch.commit();
      console.log(`   ✅ Batch final de ${deliveriesBatchCount} livraisons supprimées`);
    }

    console.log(`\n   ✅ Total: ${deliveriesDeleted} livraison(s) supprimée(s)\n`);

    // ═══════════════════════════════════════════════════════════════
    // ÉTAPE 4 : Supprimer toutes les commandes
    // ═══════════════════════════════════════════════════════════════
    console.log('🗑️  Suppression des commandes...\n');

    let ordersBatch = db.batch();
    let ordersBatchCount = 0;
    let ordersDeleted = 0;

    for (const doc of ordersSnapshot.docs) {
      ordersBatch.delete(doc.ref);
      ordersBatchCount++;
      ordersDeleted++;

      if (ordersBatchCount >= 500) {
        await ordersBatch.commit();
        console.log(`   ✅ Batch de ${ordersBatchCount} commandes supprimées`);
        ordersBatch = db.batch();
        ordersBatchCount = 0;
      }
    }

    if (ordersBatchCount > 0) {
      await ordersBatch.commit();
      console.log(`   ✅ Batch final de ${ordersBatchCount} commandes supprimées`);
    }

    console.log(`\n   ✅ Total: ${ordersDeleted} commande(s) supprimée(s)\n`);

    // ═══════════════════════════════════════════════════════════════
    // ÉTAPE 5 : Réinitialiser les compteurs
    // ═══════════════════════════════════════════════════════════════
    console.log('🔢 Réinitialisation des compteurs...\n');

    const countersSnapshot = await db.collection('counters').get();

    const countersBatch = db.batch();
    let countersReset = 0;

    countersSnapshot.forEach(doc => {
      const data = doc.data();
      console.log(`   🔢 Compteur ${doc.id}: ${data.value || 0} → 0`);

      countersBatch.update(doc.ref, {
        value: 0,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      countersReset++;
    });

    if (countersReset > 0) {
      await countersBatch.commit();
      console.log(`\n   ✅ ${countersReset} compteur(s) réinitialisé(s)\n`);
    } else {
      console.log('   ℹ️  Aucun compteur trouvé\n');
    }

    // ═══════════════════════════════════════════════════════════════
    // ÉTAPE 6 : Vérification finale
    // ═══════════════════════════════════════════════════════════════
    console.log('🔍 Vérification finale...\n');

    const finalOrdersCount = (await db.collection('orders').get()).size;
    const finalDeliveriesCount = (await db.collection('deliveries').get()).size;

    console.log(`   📦 Commandes restantes: ${finalOrdersCount}`);
    console.log(`   🚚 Livraisons restantes: ${finalDeliveriesCount}`);

    // ═══════════════════════════════════════════════════════════════
    // RÉSUMÉ FINAL
    // ═══════════════════════════════════════════════════════════════
    console.log('\n\n✅ ═══════════════════════════════════════════════════════');
    console.log('✅  RÉINITIALISATION TERMINÉE AVEC SUCCÈS !');
    console.log('✅ ═══════════════════════════════════════════════════════\n');

    console.log('📊 RÉSUMÉ:');
    console.log(`   ✅ ${ordersDeleted} commandes supprimées`);
    console.log(`   ✅ ${deliveriesDeleted} livraisons supprimées`);
    console.log(`   ✅ ${totalReservedReleased} unités de stock libérées`);
    console.log(`   ✅ ${countersReset} compteurs réinitialisés`);
    console.log('');
    console.log('🎯 Vous pouvez maintenant reprendre les tests avec une base propre !');
    console.log('');

  } catch (error) {
    console.error('\n❌ ERREUR LORS DE LA RÉINITIALISATION:', error);
    console.error('\nℹ️  La base de données peut être dans un état incohérent.');
    console.error('   Veuillez vérifier manuellement ou relancer le script.');
  } finally {
    process.exit(0);
  }
}

// Exécution
resetOrdersAndDeliveries();
