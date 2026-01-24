/**
 * Script pour réinitialiser le stock réservé (reservedStock) de tous les produits
 *
 * Ce script corrige le problème de "stock insuffisant" causé par
 * des réservations de stock qui n'ont pas été libérées (commandes abandonnées, etc.)
 *
 * UTILISATION:
 * node reset_reserved_stock.js
 */

const admin = require('firebase-admin');

// Initialiser Firebase Admin avec le fichier de configuration
// Assurez-vous d'avoir téléchargé le fichier de clé privée depuis Firebase Console
// Settings > Service accounts > Generate new private key

// Option 1: Utiliser le fichier de service account (recommandé pour production)
// const serviceAccount = require('./serviceAccountKey.json');
// admin.initializeApp({
//   credential: admin.credential.cert(serviceAccount)
// });

// Option 2: Utiliser les credentials par défaut (si déjà authentifié avec Firebase CLI)
admin.initializeApp({
  projectId: 'social-media-business-pro'
});

const db = admin.firestore();

async function resetReservedStock() {
  console.log('🔄 Démarrage de la réinitialisation du stock réservé...\n');

  try {
    // Récupérer tous les produits
    const productsSnapshot = await db.collection('products').get();

    if (productsSnapshot.empty) {
      console.log('⚠️ Aucun produit trouvé dans la base de données');
      return;
    }

    console.log(`📦 ${productsSnapshot.size} produit(s) trouvé(s)\n`);

    let updatedCount = 0;
    let errorCount = 0;

    // Parcourir chaque produit
    for (const doc of productsSnapshot.docs) {
      const productId = doc.id;
      const data = doc.data();
      const productName = data.name || 'Sans nom';
      const currentStock = data.stock || 0;
      const currentReserved = data.reservedStock || 0;

      console.log(`\n📋 Produit: ${productName} (ID: ${productId})`);
      console.log(`   Stock actuel: ${currentStock}`);
      console.log(`   Stock réservé: ${currentReserved}`);
      console.log(`   Stock disponible: ${currentStock - currentReserved}`);

      // Si reservedStock > 0, le réinitialiser
      if (currentReserved > 0) {
        try {
          await db.collection('products').doc(productId).update({
            reservedStock: 0,
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
          });

          console.log(`   ✅ Stock réservé réinitialisé: ${currentReserved} → 0`);
          console.log(`   📈 Nouveau stock disponible: ${currentStock}`);
          updatedCount++;
        } catch (err) {
          console.log(`   ❌ Erreur: ${err.message}`);
          errorCount++;
        }
      } else {
        console.log(`   ℹ️ Aucune réservation à réinitialiser`);
      }
    }

    console.log('\n' + '='.repeat(50));
    console.log('📊 RÉSUMÉ:');
    console.log(`   Total produits: ${productsSnapshot.size}`);
    console.log(`   Produits mis à jour: ${updatedCount}`);
    console.log(`   Erreurs: ${errorCount}`);
    console.log('='.repeat(50));

    if (updatedCount > 0) {
      console.log('\n✅ Réinitialisation terminée avec succès!');
      console.log('   Les clients pourront maintenant acheter ces produits.');
    } else {
      console.log('\nℹ️ Aucune réinitialisation nécessaire.');
    }

  } catch (error) {
    console.error('❌ Erreur fatale:', error.message);
    console.error(error);
  }

  // Fermer la connexion
  process.exit(0);
}

// Exécuter le script
resetReservedStock();
