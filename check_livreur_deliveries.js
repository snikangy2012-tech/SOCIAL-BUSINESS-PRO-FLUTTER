// Script pour vérifier les livraisons par livreur

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'social-media-business-pro'
});

const db = admin.firestore();

async function checkLivreurDeliveries() {
  try {
    console.log('🔍 Vérification des livraisons par livreur...\n');

    // Récupérer toutes les livraisons
    const deliveriesSnapshot = await db.collection('deliveries').get();

    console.log(`📦 ${deliveriesSnapshot.size} livraisons trouvées\n`);

    // Grouper par livreurId
    const deliveriesByLivreur = {};

    deliveriesSnapshot.forEach(doc => {
      const data = doc.data();
      const livreurId = data.livreurId || 'NON_ASSIGNÉ';

      if (!deliveriesByLivreur[livreurId]) {
        deliveriesByLivreur[livreurId] = [];
      }

      deliveriesByLivreur[livreurId].push({
        id: doc.id,
        status: data.status,
        orderId: data.orderId
      });
    });

    console.log('📊 RÉPARTITION PAR LIVREUR:\n');

    for (const [livreurId, deliveries] of Object.entries(deliveriesByLivreur)) {
      console.log(`👤 Livreur: ${livreurId.substring(0, 12)}...`);
      console.log(`   Total: ${deliveries.length} livraison(s)`);

      // Compter par statut
      const statusCount = {};
      deliveries.forEach(del => {
        const status = del.status;
        statusCount[status] = (statusCount[status] || 0) + 1;
      });

      console.log(`   Statuts:`);
      for (const [status, count] of Object.entries(statusCount)) {
        console.log(`      - ${status}: ${count}`);
      }

      console.log(`   Détails:`);
      deliveries.forEach(del => {
        console.log(`      • ${del.id.substring(0, 8)}... | ${del.status} | Commande: ${del.orderId?.substring(0, 8) || 'N/A'}...`);
      });

      console.log('');
    }

    // Récupérer les livreurs pour afficher leurs noms
    console.log('\n👥 INFORMATIONS LIVREURS:\n');

    for (const livreurId of Object.keys(deliveriesByLivreur)) {
      if (livreurId === 'NON_ASSIGNÉ') continue;

      try {
        const livreurDoc = await db.collection('users').doc(livreurId).get();
        if (livreurDoc.exists) {
          const data = livreurDoc.data();
          console.log(`   ${livreurId.substring(0, 12)}... → ${data.displayName || data.username || 'Inconnu'} (${data.email})`);
        }
      } catch (e) {
        console.log(`   ${livreurId.substring(0, 12)}... → Erreur lecture`);
      }
    }

  } catch (error) {
    console.error('❌ Erreur:', error);
  } finally {
    process.exit(0);
  }
}

checkLivreurDeliveries();
