// Script pour vérifier les statuts des livraisons

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'social-media-business-pro'
});

const db = admin.firestore();

async function checkDeliveryStatuses() {
  try {
    console.log('🔍 Vérification des statuts des livraisons...\n');

    const deliveriesSnapshot = await db.collection('deliveries').get();

    console.log(`📦 ${deliveriesSnapshot.size} livraisons trouvées\n`);

    // Compter par statut
    const statusCount = {};

    deliveriesSnapshot.forEach(doc => {
      const data = doc.data();
      const status = data.status || 'undefined';

      if (!statusCount[status]) {
        statusCount[status] = 0;
      }
      statusCount[status]++;

      console.log(`ID: ${doc.id.substring(0, 8)}... | Statut: ${status} | Commande: ${data.orderId?.substring(0, 8) || 'N/A'}...`);
    });

    console.log('\n📊 RÉPARTITION PAR STATUT:');
    for (const [status, count] of Object.entries(statusCount)) {
      console.log(`   ${status}: ${count} livraison(s)`);
    }

  } catch (error) {
    console.error('❌ Erreur:', error);
  } finally {
    process.exit(0);
  }
}

checkDeliveryStatuses();
