// Script pour tester la gestion des réservations de stock

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'social-media-business-pro'
});

const db = admin.firestore();

async function testStockReservation() {
  try {
    console.log('🧪 Test de la gestion des réservations de stock\n');

    // 1. Récupérer quelques produits
    const productsSnapshot = await db.collection('products').limit(5).get();

    console.log(`📦 ${productsSnapshot.size} produits chargés pour le test\n`);

    productsSnapshot.forEach(doc => {
      const data = doc.data();
      const currentStock = data.stock || 0;
      const reservedStock = data.reservedStock || 0;
      const availableStock = currentStock - reservedStock;

      console.log(`\n📦 Produit: ${data.name}`);
      console.log(`   ID: ${doc.id.substring(0, 8)}...`);
      console.log(`   Stock total: ${currentStock}`);
      console.log(`   Stock réservé: ${reservedStock}`);
      console.log(`   Stock disponible: ${availableStock}`);

      // Alertes
      if (reservedStock > currentStock) {
        console.log(`   ⚠️  ALERTE: Stock réservé > Stock total!`);
      }

      if (reservedStock > 0 && availableStock === 0) {
        console.log(`   ⚠️  ALERTE: Tout le stock est réservé!`);
      }

      if (reservedStock < 0) {
        console.log(`   ❌ ERREUR: Stock réservé négatif!`);
      }
    });

    // 2. Statistiques globales
    console.log('\n\n📊 STATISTIQUES GLOBALES:\n');

    const allProducts = await db.collection('products').get();
    let totalProducts = 0;
    let totalStock = 0;
    let totalReserved = 0;
    let productsWithReservations = 0;
    let productsWithErrors = 0;

    allProducts.forEach(doc => {
      const data = doc.data();
      const stock = data.stock || 0;
      const reserved = data.reservedStock || 0;

      totalProducts++;
      totalStock += stock;
      totalReserved += reserved;

      if (reserved > 0) {
        productsWithReservations++;
      }

      if (reserved > stock || reserved < 0) {
        productsWithErrors++;
      }
    });

    console.log(`   Total produits: ${totalProducts}`);
    console.log(`   Stock total: ${totalStock} unités`);
    console.log(`   Stock réservé total: ${totalReserved} unités`);
    console.log(`   Stock disponible: ${totalStock - totalReserved} unités`);
    console.log(`   Produits avec réservations: ${productsWithReservations}`);
    console.log(`   Produits avec erreurs: ${productsWithErrors}`);

    if (productsWithErrors > 0) {
      console.log(`\n   ❌ ${productsWithErrors} produit(s) ont des erreurs de réservation!`);
    } else {
      console.log(`\n   ✅ Aucune erreur de réservation détectée`);
    }

    // 3. Proposer un nettoyage si nécessaire
    if (totalReserved > 0) {
      console.log(`\n\n💡 INFO: ${totalReserved} unités sont actuellement réservées.`);
      console.log(`   Ces réservations seront automatiquement libérées en cas d'échec de commande.`);
      console.log(`   Pour réinitialiser manuellement toutes les réservations, exécutez: npm run reset-reservations`);
    }

  } catch (error) {
    console.error('❌ Erreur:', error);
  } finally {
    process.exit(0);
  }
}

testStockReservation();
