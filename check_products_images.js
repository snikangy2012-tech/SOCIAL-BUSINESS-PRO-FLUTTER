// Script pour vérifier l'état des images des produits existants
const admin = require('firebase-admin');

// Initialiser Firebase Admin (utilise les credentials par défaut)
admin.initializeApp({
  projectId: 'social-media-business-pro'
});

const db = admin.firestore();

async function checkProductImages() {
  console.log('🔍 Vérification des images des produits...\n');

  try {
    const productsSnapshot = await db.collection('products').limit(20).get();

    if (productsSnapshot.empty) {
      console.log('❌ Aucun produit trouvé dans Firestore');
      return;
    }

    console.log(`✅ ${productsSnapshot.size} produits trouvés\n`);

    let withImages = 0;
    let withoutImages = 0;
    let withInvalidImages = 0;

    productsSnapshot.forEach(doc => {
      const product = doc.data();
      const images = product.images || [];

      console.log(`📦 Produit: ${product.name || 'Sans nom'}`);
      console.log(`   ID: ${doc.id}`);
      console.log(`   Catégorie: ${product.category || 'N/A'}`);
      console.log(`   Vendeur: ${product.vendeurName || product.vendeurId || 'N/A'}`);

      if (images.length === 0) {
        console.log(`   🔴 Images: AUCUNE`);
        withoutImages++;
      } else {
        console.log(`   🟢 Images: ${images.length} image(s)`);
        images.forEach((url, index) => {
          if (url && url.includes('firebasestorage.googleapis.com')) {
            console.log(`      ${index + 1}. ✅ Firebase Storage: ${url.substring(0, 80)}...`);
            withImages++;
          } else if (url && url.includes('unsplash.com')) {
            console.log(`      ${index + 1}. ⚠️  Unsplash (placeholder): ${url.substring(0, 80)}...`);
            withInvalidImages++;
          } else if (url) {
            console.log(`      ${index + 1}. ⚠️  URL inconnue: ${url.substring(0, 80)}...`);
            withInvalidImages++;
          } else {
            console.log(`      ${index + 1}. ❌ URL vide/invalide`);
            withInvalidImages++;
          }
        });
      }
      console.log('');
    });

    console.log('\n📊 RÉSUMÉ:');
    console.log(`   Total produits: ${productsSnapshot.size}`);
    console.log(`   Produits sans images: ${withoutImages}`);
    console.log(`   Images Firebase Storage valides: ${withImages}`);
    console.log(`   Images invalides/placeholder: ${withInvalidImages}`);

    if (withoutImages > 0 || withInvalidImages > 0) {
      console.log('\n💡 RECOMMANDATION:');
      console.log('   Les produits sans images ou avec placeholders afficheront');
      console.log('   automatiquement des images Unsplash grâce à ImageHelper.');
      console.log('   Pour ajouter de vraies images, les vendeurs doivent:');
      console.log('   1. Modifier leurs produits dans l\'app');
      console.log('   2. Ajouter de nouvelles images');
      console.log('   3. Sauvegarder');
    }

  } catch (error) {
    console.error('❌ Erreur:', error.message);
  }

  process.exit(0);
}

checkProductImages();
