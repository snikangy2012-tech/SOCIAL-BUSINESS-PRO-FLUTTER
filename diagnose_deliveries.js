// Script de diagnostic pour analyser les distances des livraisons
const admin = require('firebase-admin');

const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'social-media-business-pro'
});

const db = admin.firestore();

async function diagnoseDeliveries() {
  console.log('🔍 Diagnostic des livraisons...\n');

  try {
    const deliveriesSnapshot = await db.collection('deliveries').get();

    console.log(`📦 ${deliveriesSnapshot.size} livraisons trouvées\n`);
    console.log('═══════════════════════════════════════════════════════════════\n');

    const distanceGroups = {};
    let missingGPS = 0;
    let hasGPS = 0;

    for (const doc of deliveriesSnapshot.docs) {
      const delivery = doc.data();
      const id = doc.id;

      // Vérifier les coordonnées
      const pickupLat = delivery.pickupAddress?.coordinates?.latitude;
      const pickupLng = delivery.pickupAddress?.coordinates?.longitude;
      const deliveryLat = delivery.deliveryAddress?.coordinates?.latitude;
      const deliveryLng = delivery.deliveryAddress?.coordinates?.longitude;

      const distance = delivery.distance || 0;

      console.log(`📍 Livraison: ${id.substring(0, 8)}...`);
      console.log(`   Distance: ${distance} km`);
      console.log(`   Pickup GPS: ${pickupLat}, ${pickupLng}`);
      console.log(`   Delivery GPS: ${deliveryLat}, ${deliveryLng}`);

      // Vérifier si GPS manquant
      if (!pickupLat || !deliveryLat || pickupLat === 0 || deliveryLat === 0) {
        console.log('   ⚠️  GPS MANQUANT ou INVALIDE (0, 0)');
        missingGPS++;
      } else {
        console.log('   ✅ GPS présent');
        hasGPS++;
      }

      // Grouper par distance
      const distKey = distance.toFixed(1);
      if (!distanceGroups[distKey]) {
        distanceGroups[distKey] = [];
      }
      distanceGroups[distKey].push({
        id: id.substring(0, 8),
        pickupLat,
        pickupLng,
        deliveryLat,
        deliveryLng,
        pickupStreet: delivery.pickupAddress?.street,
        deliveryStreet: delivery.deliveryAddress?.street
      });

      console.log('   Pickup: ' + (delivery.pickupAddress?.street || 'N/A'));
      console.log('   Delivery: ' + (delivery.deliveryAddress?.street || 'N/A'));
      console.log('');
    }

    console.log('\n═══════════════════════════════════════════════════════════════');
    console.log('📊 RÉSUMÉ PAR DISTANCE:\n');

    const sortedDistances = Object.keys(distanceGroups).sort((a, b) => parseFloat(a) - parseFloat(b));

    for (const dist of sortedDistances) {
      const count = distanceGroups[dist].length;
      console.log(`   ${dist} km: ${count} livraison(s)`);

      if (count > 1 && parseFloat(dist) > 0) {
        console.log('   ⚠️  Plusieurs livraisons avec la MÊME distance - probablement GPS manquant!');
      }
    }

    console.log('\n═══════════════════════════════════════════════════════════════');
    console.log('📈 STATISTIQUES GPS:\n');
    console.log(`   ✅ Avec GPS valide: ${hasGPS}`);
    console.log(`   ❌ GPS manquant/invalide: ${missingGPS}`);
    console.log(`   📊 Pourcentage GPS valide: ${((hasGPS / deliveriesSnapshot.size) * 100).toFixed(1)}%`);

    console.log('\n═══════════════════════════════════════════════════════════════');
    console.log('🔍 ANALYSE DU PROBLÈME:\n');

    if (missingGPS > 0) {
      console.log('❌ PROBLÈME IDENTIFIÉ:');
      console.log(`   ${missingGPS} livraisons ont des coordonnées GPS manquantes ou invalides (0, 0)`);
      console.log('');
      console.log('💡 CAUSES POSSIBLES:');
      console.log('   1. Livraisons créées avant l\'implémentation du GPS');
      console.log('   2. Commandes sans coordonnées GPS au moment de la création');
      console.log('   3. Valeurs par défaut (0.0) utilisées quand GPS manquant');
      console.log('');
      console.log('✅ SOLUTIONS:');
      console.log('   1. Utiliser le script migrate_delivery_addresses.js pour géocoder');
      console.log('   2. Interface livreur modifiée pour utiliser adresse textuelle (déjà fait)');
    } else {
      console.log('✅ Toutes les livraisons ont des coordonnées GPS valides!');
    }

    console.log('\n═══════════════════════════════════════════════════════════════\n');

    // Analyse spécifique pour 4.3 km
    if (distanceGroups['4.3'] && distanceGroups['4.3'].length > 1) {
      console.log('🔍 ANALYSE DÉTAILLÉE DES LIVRAISONS À 4.3 KM:\n');

      for (const delivery of distanceGroups['4.3']) {
        console.log(`   Livraison ${delivery.id}:`);
        console.log(`      Pickup: (${delivery.pickupLat}, ${delivery.pickupLng})`);
        console.log(`      Delivery: (${delivery.deliveryLat}, ${delivery.deliveryLng})`);
        console.log(`      Pickup addr: ${delivery.pickupStreet || 'N/A'}`);
        console.log(`      Delivery addr: ${delivery.deliveryStreet || 'N/A'}`);
        console.log('');
      }

      console.log('   💡 Si toutes ces livraisons ont les MÊMES coordonnées:');
      console.log('      → Probablement des coordonnées par défaut ou hardcodées');
      console.log('      → Vérifiez le code de création des commandes/livraisons');
      console.log('\n═══════════════════════════════════════════════════════════════\n');
    }

  } catch (error) {
    console.error('❌ Erreur:', error);
  }

  process.exit(0);
}

diagnoseDeliveries();
