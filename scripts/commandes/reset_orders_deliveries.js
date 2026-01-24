// Script pour réinitialiser les collections orders et deliveries
// Garde les produits et les utilisateurs intacts
// SOCIAL BUSINESS Pro

const admin = require('firebase-admin');

// Initialiser Firebase Admin
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function resetOrdersAndDeliveries() {
  console.log('🔄 Début de la réinitialisation des commandes et livraisons...\n');

  try {
    // 1. Supprimer toutes les commandes (orders)
    console.log('📦 Suppression de toutes les commandes...');
    const ordersSnapshot = await db.collection('orders').get();
    const ordersBatch = db.batch();
    let ordersCount = 0;

    ordersSnapshot.forEach((doc) => {
      ordersBatch.delete(doc.ref);
      ordersCount++;
    });

    if (ordersCount > 0) {
      await ordersBatch.commit();
      console.log(`✅ ${ordersCount} commandes supprimées\n`);
    } else {
      console.log('ℹ️  Aucune commande à supprimer\n');
    }

    // 2. Supprimer toutes les livraisons (deliveries)
    console.log('🚚 Suppression de toutes les livraisons...');
    const deliveriesSnapshot = await db.collection('deliveries').get();
    const deliveriesBatch = db.batch();
    let deliveriesCount = 0;

    deliveriesSnapshot.forEach((doc) => {
      deliveriesBatch.delete(doc.ref);
      deliveriesCount++;
    });

    if (deliveriesCount > 0) {
      await deliveriesBatch.commit();
      console.log(`✅ ${deliveriesCount} livraisons supprimées\n`);
    } else {
      console.log('ℹ️  Aucune livraison à supprimer\n');
    }

    // 3. Réinitialiser le stock réservé des produits (optionnel)
    console.log('📊 Réinitialisation du stock réservé des produits...');
    const productsSnapshot = await db.collection('products').get();
    const productsBatch = db.batch();
    let productsCount = 0;

    productsSnapshot.forEach((doc) => {
      const data = doc.data();
      if (data.reservedStock && data.reservedStock > 0) {
        productsBatch.update(doc.ref, {
          reservedStock: 0,
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
        productsCount++;
      }
    });

    if (productsCount > 0) {
      await productsBatch.commit();
      console.log(`✅ ${productsCount} produits mis à jour (stock réservé = 0)\n`);
    } else {
      console.log('ℹ️  Aucun produit avec stock réservé\n');
    }

    // 4. Supprimer les notifications liées aux commandes et livraisons (optionnel)
    console.log('🔔 Suppression des notifications liées aux commandes...');
    const notificationsSnapshot = await db.collection('notifications')
      .where('type', 'in', ['order_update', 'delivery_update'])
      .get();

    const notificationsBatch = db.batch();
    let notificationsCount = 0;

    notificationsSnapshot.forEach((doc) => {
      notificationsBatch.delete(doc.ref);
      notificationsCount++;
    });

    if (notificationsCount > 0) {
      await notificationsBatch.commit();
      console.log(`✅ ${notificationsCount} notifications supprimées\n`);
    } else {
      console.log('ℹ️  Aucune notification à supprimer\n');
    }

    // 5. Résumé final
    console.log('═══════════════════════════════════════════════════');
    console.log('✅ Réinitialisation terminée avec succès!');
    console.log('═══════════════════════════════════════════════════');
    console.log(`📦 Commandes supprimées: ${ordersCount}`);
    console.log(`🚚 Livraisons supprimées: ${deliveriesCount}`);
    console.log(`📊 Produits mis à jour: ${productsCount}`);
    console.log(`🔔 Notifications supprimées: ${notificationsCount}`);
    console.log('═══════════════════════════════════════════════════\n');

    console.log('ℹ️  Collections préservées:');
    console.log('   ✓ users (utilisateurs)');
    console.log('   ✓ products (produits)');
    console.log('   ✓ vendeur_subscriptions');
    console.log('   ✓ livreur_subscriptions');
    console.log('   ✓ audit_logs');
    console.log('   ✓ Autres collections système\n');

  } catch (error) {
    console.error('❌ Erreur lors de la réinitialisation:', error);
    throw error;
  } finally {
    // Fermer la connexion
    await admin.app().delete();
    console.log('🔚 Connexion Firebase fermée\n');
  }
}

// Exécuter le script
resetOrdersAndDeliveries()
  .then(() => {
    console.log('✅ Script terminé avec succès');
    process.exit(0);
  })
  .catch((error) => {
    console.error('❌ Erreur fatale:', error);
    process.exit(1);
  });
