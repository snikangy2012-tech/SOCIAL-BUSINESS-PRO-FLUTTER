// Vérifier un produit spécifique dans Firestore
const admin = require('firebase-admin');

admin.initializeApp({
  projectId: 'social-media-business-pro'
});

const db = admin.firestore();

async function checkProduct() {
  const productId = 'OH6iUT6i0R1rMbG7TVo5';

  console.log(`🔍 Vérification du produit: ${productId}\n`);

  try {
    const doc = await db.collection('products').doc(productId).get();

    if (!doc.exists) {
      console.log('❌ Produit non trouvé');
      return;
    }

    const data = doc.data();
    console.log('✅ Produit trouvé\n');
    console.log('Détails:');
    console.log('  Nom:', data.name || 'N/A');
    console.log('  Catégorie:', data.category || 'N/A');
    console.log('  Vendeur ID:', data.vendeurId || 'N/A');
    console.log('  Vendeur Nom:', data.vendeurName || 'N/A');
    console.log('  Créé le:', data.createdAt?.toDate() || 'N/A');
    console.log('\n📸 Images:');

    const images = data.images || [];

    if (images.length === 0) {
      console.log('  ❌ Aucune image dans Firestore');
      console.log('\n💡 PROBLÈME IDENTIFIÉ:');
      console.log('  Les images sont sur votre téléphone mais pas uploadées vers Firebase Storage.');
      console.log('  Chemin local: /data/user/0/.../cache/scaled_1000008226.jpg');
      console.log('  Ce chemin est inaccessible pour les autres utilisateurs.\n');
      console.log('✅ SOLUTION:');
      console.log('  1. Modifiez ce produit dans l\'app vendeur');
      console.log('  2. Ajoutez les images à nouveau');
      console.log('  3. Sauvegardez → Les images seront uploadées vers Firebase Storage');
    } else {
      console.log(`  ✅ ${images.length} image(s) trouvée(s):\n`);
      images.forEach((url, index) => {
        console.log(`  ${index + 1}. ${url.substring(0, 100)}...`);
        if (url.includes('firebasestorage.googleapis.com')) {
          console.log('     Type: ✅ Firebase Storage');
        } else if (url.includes('unsplash.com')) {
          console.log('     Type: ⚠️  Placeholder Unsplash');
        } else if (url.includes('/data/user/') || url.includes('/cache/')) {
          console.log('     Type: ❌ CHEMIN LOCAL (non accessible!)');
        } else {
          console.log('     Type: ❓ Inconnu');
        }
      });
    }

  } catch (error) {
    console.error('❌ Erreur:', error.message);
  }

  process.exit(0);
}

checkProduct();
