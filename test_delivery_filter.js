// Script pour tester le filtrage des livraisons

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'social-media-business-pro'
});

const db = admin.firestore();

async function testDeliveryFilter() {
  try {
    console.log('🔍 Test du filtrage des livraisons...\n');

    // Récupérer toutes les livraisons
    const deliveriesSnapshot = await db.collection('deliveries').get();
    const allDeliveries = [];

    deliveriesSnapshot.forEach(doc => {
      const data = doc.data();
      allDeliveries.push({
        id: doc.id,
        status: data.status,
        orderId: data.orderId
      });
    });

    console.log(`📦 ${allDeliveries.length} livraisons chargées\n`);

    // Simuler le filtre pour chaque statut
    const statusFilters = ['assigned', 'in_progress', 'delivered', 'cancelled'];

    for (const filterStatus of statusFilters) {
      console.log(`\n🔍 FILTRE: "${filterStatus}"`);

      let filtered;

      if (filterStatus === 'in_progress') {
        // Logique spéciale pour in_progress
        filtered = allDeliveries.filter(delivery =>
          delivery.status.toLowerCase() === 'picked_up' ||
          delivery.status.toLowerCase() === 'in_transit'
        );
        console.log(`   → Cherche: picked_up OU in_transit`);
      } else {
        filtered = allDeliveries.filter(delivery =>
          delivery.status.toLowerCase() === filterStatus.toLowerCase()
        );
        console.log(`   → Cherche: ${filterStatus}`);
      }

      console.log(`   → Résultats: ${filtered.length} livraison(s)`);

      if (filtered.length > 0) {
        filtered.forEach(del => {
          console.log(`      - ${del.id.substring(0, 8)}... | Statut réel: ${del.status}`);
        });
      } else {
        console.log(`      (vide)`);
      }
    }

    console.log('\n\n📊 DÉTAIL DES STATUTS RÉELS:');
    allDeliveries.forEach(del => {
      console.log(`   ${del.id.substring(0, 8)}... → status="${del.status}" (type: ${typeof del.status})`);
    });

  } catch (error) {
    console.error('❌ Erreur:', error);
  } finally {
    process.exit(0);
  }
}

testDeliveryFilter();
