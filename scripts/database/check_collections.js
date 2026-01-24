/**
 * Script pour vérifier les deux collections de catégories
 */

const admin = require('firebase-admin');
const serviceAccount = require('../serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function checkCollection(collectionName) {
  console.log(`\n📁 Collection "${collectionName}":`);
  const snapshot = await db.collection(collectionName).get();

  if (snapshot.empty) {
    console.log(`   ❌ VIDE (${snapshot.size} documents)`);
    return null;
  }

  console.log(`   ✅ ${snapshot.size} documents trouvés:`);
  snapshot.forEach(doc => {
    const data = doc.data();
    console.log(`      - ${doc.id}: ${data.name || 'Sans nom'}`);
  });

  return snapshot;
}

async function main() {
  console.log('🔍 Vérification des collections de catégories\n');
  console.log('='.repeat(60));

  await checkCollection('categories');
  await checkCollection('product_categories');

  console.log('\n' + '='.repeat(60));
  process.exit(0);
}

main().catch(err => {
  console.error('❌ Erreur:', err);
  process.exit(1);
});
