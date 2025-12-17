// Script pour libérer les réservations de stock des commandes échouées/expirées
// Plus intelligent que reset_stock_reservations.js : vérifie l'état des commandes

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'social-media-business-pro'
});

const db = admin.firestore();

async function cleanExpiredReservations() {
  try {
    console.log('🔍 Analyse des réservations de stock...\n');

    // 1. Récupérer toutes les commandes
    const ordersSnapshot = await db.collection('orders').get();
    console.log(`📦 ${ordersSnapshot.size} commandes trouvées\n`);

    // 2. Grouper les produits par statut de commande
    const productsByOrderStatus = {
      pending: new Map(),      // En attente (réservation légitime)
      confirmed: new Map(),    // Confirmée (réservation légitime)
      preparing: new Map(),    // En préparation (réservation légitime)
      cancelled: new Map(),    // Annulée (DOIT ÊTRE LIBÉRÉ)
      delivered: new Map(),    // Livrée (DOIT ÊTRE LIBÉRÉ - déjà déduit)
    };

    const oldPendingOrders = new Map(); // Commandes pending > 30 minutes

    const now = Date.now();
    const TIMEOUT_MS = 30 * 60 * 1000; // 30 minutes

    ordersSnapshot.forEach(doc => {
      const data = doc.data();
      const status = data.status || 'pending';
      const items = data.items || [];
      const createdAt = data.createdAt?.toDate() || new Date();
      const age = now - createdAt.getTime();

      // Vérifier si la commande pending est expirée (> 30 min)
      if (status === 'pending' && age > TIMEOUT_MS) {
        oldPendingOrders.set(doc.id, {
          age: Math.floor(age / 60000), // minutes
          items: items,
        });
      }

      // Grouper les items par statut
      items.forEach(item => {
        const productId = item.productId;
        const quantity = item.quantity;

        if (!productsByOrderStatus[status]) {
          productsByOrderStatus[status] = new Map();
        }

        const current = productsByOrderStatus[status].get(productId) || 0;
        productsByOrderStatus[status].set(productId, current + quantity);
      });
    });

    // 3. Calculer les réservations à libérer
    const toRelease = new Map();

    // Libérer les commandes annulées
    if (productsByOrderStatus.cancelled.size > 0) {
      console.log('📋 Commandes ANNULÉES détectées:');
      productsByOrderStatus.cancelled.forEach((quantity, productId) => {
        console.log(`   ${productId.substring(0, 8)}... : ${quantity} unité(s)`);
        const current = toRelease.get(productId) || 0;
        toRelease.set(productId, current + quantity);
      });
      console.log('');
    }

    // Libérer les commandes livrées (stock déjà déduit)
    if (productsByOrderStatus.delivered.size > 0) {
      console.log('📋 Commandes LIVRÉES détectées (stock déjà déduit):');
      productsByOrderStatus.delivered.forEach((quantity, productId) => {
        console.log(`   ${productId.substring(0, 8)}... : ${quantity} unité(s)`);
        const current = toRelease.get(productId) || 0;
        toRelease.set(productId, current + quantity);
      });
      console.log('');
    }

    // Libérer les commandes pending expirées (> 30 min)
    if (oldPendingOrders.size > 0) {
      console.log('⏰ Commandes PENDING EXPIRÉES (> 30 min):');
      oldPendingOrders.forEach((data, orderId) => {
        console.log(`   Commande ${orderId.substring(0, 8)}... (${data.age} min)`);
        data.items.forEach(item => {
          const productId = item.productId;
          const quantity = item.quantity;
          const current = toRelease.get(productId) || 0;
          toRelease.set(productId, current + quantity);
        });
      });
      console.log('');
    }

    // 4. Récupérer les produits et leurs réservations actuelles
    console.log('📦 Vérification des stocks actuels...\n');

    const productsSnapshot = await db.collection('products').get();
    const actualReservations = new Map();

    productsSnapshot.forEach(doc => {
      const data = doc.data();
      const reservedStock = data.reservedStock || 0;
      if (reservedStock > 0) {
        actualReservations.set(doc.id, {
          name: data.name,
          reserved: reservedStock,
          total: data.stock || 0,
        });
      }
    });

    // 5. Calculer la différence et libérer uniquement ce qui est nécessaire
    const finalToRelease = new Map();

    toRelease.forEach((quantityToRelease, productId) => {
      const actual = actualReservations.get(productId);
      if (actual) {
        // Libérer au maximum ce qui est réservé
        const releaseAmount = Math.min(quantityToRelease, actual.reserved);
        if (releaseAmount > 0) {
          finalToRelease.set(productId, {
            name: actual.name,
            quantity: releaseAmount,
            reservedBefore: actual.reserved,
            reservedAfter: actual.reserved - releaseAmount,
          });
        }
      }
    });

    // 6. Afficher le résumé
    console.log('📊 RÉSUMÉ DES LIBÉRATIONS:\n');

    if (finalToRelease.size === 0) {
      console.log('✅ Aucune réservation à libérer ! Tout est en ordre.');
      return;
    }

    let totalReleased = 0;
    finalToRelease.forEach((data, productId) => {
      console.log(`📦 ${data.name}`);
      console.log(`   Avant: ${data.reservedBefore} unité(s) réservées`);
      console.log(`   Libérer: ${data.quantity} unité(s)`);
      console.log(`   Après: ${data.reservedAfter} unité(s) réservées`);
      console.log('');
      totalReleased += data.quantity;
    });

    console.log(`Total à libérer: ${totalReleased} unité(s)\n`);

    // 7. Demander confirmation
    console.log('⚠️  Continuer avec la libération ? (Ctrl+C pour annuler)');
    console.log('Exécution dans 5 secondes...\n');

    await new Promise(resolve => setTimeout(resolve, 5000));

    // 8. Libérer les réservations
    console.log('🔄 Libération en cours...\n');

    const batch = db.batch();
    let batchCount = 0;

    for (const [productId, data] of finalToRelease.entries()) {
      const docRef = db.collection('products').doc(productId);
      batch.update(docRef, {
        reservedStock: admin.firestore.FieldValue.increment(-data.quantity),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      batchCount++;

      if (batchCount >= 500) {
        await batch.commit();
        console.log(`✅ Batch de ${batchCount} mises à jour effectué`);
        batchCount = 0;
      }
    }

    if (batchCount > 0) {
      await batch.commit();
      console.log(`✅ Batch final de ${batchCount} mises à jour effectué`);
    }

    console.log(`\n✅ ${totalReleased} unité(s) libérée(s) avec succès !`);

    // 9. Statistiques finales
    console.log('\n📊 STATISTIQUES:');
    console.log(`   Commandes annulées: ${productsByOrderStatus.cancelled.size} produit(s) uniques`);
    console.log(`   Commandes livrées: ${productsByOrderStatus.delivered.size} produit(s) uniques`);
    console.log(`   Commandes expirées: ${oldPendingOrders.size} commande(s)`);
    console.log(`   Produits mis à jour: ${finalToRelease.size}`);

  } catch (error) {
    console.error('❌ Erreur:', error);
  } finally {
    process.exit(0);
  }
}

cleanExpiredReservations();
