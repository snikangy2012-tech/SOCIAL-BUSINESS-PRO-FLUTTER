/**
 * Script pour réinitialiser les compteurs de commandes des vendeurs
 * Usage: node reset_vendor_counters.js [vendeurId]
 *
 * - Sans argument: Réinitialise TOUS les compteurs vendeurs à 0
 * - Avec vendeurId: Réinitialise seulement le compteur de ce vendeur
 */

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

// Initialiser Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
}

const db = admin.firestore();

/**
 * Réinitialise le compteur d'un vendeur spécifique
 */
async function resetVendorCounter(vendeurId, value = 0) {
  try {
    const counterRef = db
      .collection('counters')
      .doc('orders_by_vendor')
      .collection('vendors')
      .doc(vendeurId);

    await counterRef.set({
      value: value,
      vendeurId: vendeurId,
      resetAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`✅ Compteur du vendeur ${vendeurId} réinitialisé à ${value}`);
    return true;
  } catch (error) {
    console.error(`❌ Erreur réinitialisation compteur vendeur ${vendeurId}:`, error);
    return false;
  }
}

/**
 * Réinitialise tous les compteurs de tous les vendeurs
 */
async function resetAllVendorCounters(value = 0) {
  try {
    console.log('🔄 Recherche de tous les compteurs vendeurs...');

    const vendorCountersSnapshot = await db
      .collection('counters')
      .doc('orders_by_vendor')
      .collection('vendors')
      .get();

    if (vendorCountersSnapshot.empty) {
      console.log('⚠️ Aucun compteur vendeur trouvé');
      return true;
    }

    console.log(`📊 ${vendorCountersSnapshot.size} compteurs trouvés`);

    const batch = db.batch();

    vendorCountersSnapshot.docs.forEach(doc => {
      batch.update(doc.ref, {
        value: value,
        resetAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    await batch.commit();

    console.log(`✅ Tous les compteurs vendeurs réinitialisés à ${value} (${vendorCountersSnapshot.size} vendeurs)`);
    return true;
  } catch (error) {
    console.error('❌ Erreur réinitialisation compteurs:', error);
    return false;
  }
}

/**
 * Affiche les compteurs actuels de tous les vendeurs
 */
async function showVendorCounters() {
  try {
    console.log('\n📊 Compteurs actuels des vendeurs:\n');

    const vendorCountersSnapshot = await db
      .collection('counters')
      .doc('orders_by_vendor')
      .collection('vendors')
      .get();

    if (vendorCountersSnapshot.empty) {
      console.log('⚠️ Aucun compteur vendeur trouvé\n');
      return;
    }

    vendorCountersSnapshot.docs.forEach(doc => {
      const data = doc.data();
      console.log(`  - Vendeur ${doc.id}: ${data.value || 0} commandes`);
    });

    console.log('');
  } catch (error) {
    console.error('❌ Erreur affichage compteurs:', error);
  }
}

// Main
async function main() {
  const args = process.argv.slice(2);

  if (args.length === 0) {
    // Aucun argument: afficher les compteurs actuels et demander confirmation
    await showVendorCounters();

    console.log('⚠️  ATTENTION: Vous êtes sur le point de réinitialiser TOUS les compteurs vendeurs à 0');
    console.log('Pour réinitialiser un vendeur spécifique: node reset_vendor_counters.js [vendeurId]');
    console.log('Pour continuer avec la réinitialisation globale: node reset_vendor_counters.js --all');
    console.log('\n');

  } else if (args[0] === '--all' || args[0] === '-a') {
    // Réinitialiser tous les compteurs
    await showVendorCounters();
    console.log('🔄 Réinitialisation de TOUS les compteurs...\n');
    await resetAllVendorCounters(0);
    await showVendorCounters();

  } else if (args[0] === '--show' || args[0] === '-s') {
    // Afficher seulement
    await showVendorCounters();

  } else {
    // Réinitialiser un vendeur spécifique
    const vendeurId = args[0];
    const value = args[1] ? parseInt(args[1]) : 0;

    console.log(`🔄 Réinitialisation du compteur du vendeur ${vendeurId} à ${value}...\n`);
    await resetVendorCounter(vendeurId, value);

    console.log('\n📊 Vérification:');
    const counterRef = await db
      .collection('counters')
      .doc('orders_by_vendor')
      .collection('vendors')
      .doc(vendeurId)
      .get();

    if (counterRef.exists) {
      const data = counterRef.data();
      console.log(`  Compteur actuel: ${data.value || 0}\n`);
    }
  }

  process.exit(0);
}

main().catch(error => {
  console.error('❌ Erreur:', error);
  process.exit(1);
});
