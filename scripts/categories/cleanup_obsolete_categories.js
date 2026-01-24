/**
 * Script de nettoyage des produits avec catégories obsolètes
 *
 * Ce script identifie et met à jour les produits ayant des catégories
 * qui n'existent plus dans la collection 'categories'.
 *
 * Usage:
 *   node scripts/cleanup_obsolete_categories.js [--dry-run] [--auto-fix]
 *
 * Options:
 *   --dry-run    Affiche les produits à corriger sans les modifier
 *   --auto-fix   Réassigne automatiquement à une catégorie par défaut
 */

const admin = require('firebase-admin');
const serviceAccount = require('../serviceAccountKey.json');

// Initialiser Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Analyser les arguments de ligne de commande
const args = process.argv.slice(2);
const isDryRun = args.includes('--dry-run');
const autoFix = args.includes('--auto-fix');

console.log('🚀 Démarrage du script de nettoyage des catégories obsolètes...');
console.log(`Mode: ${isDryRun ? 'DRY RUN (simulation)' : 'PRODUCTION'}`);
console.log(`Auto-fix: ${autoFix ? 'OUI' : 'NON'}\n`);

async function getValidCategories() {
  console.log('📋 Récupération des catégories valides...');

  // Utiliser product_categories (collection correcte)
  let categoriesSnapshot = await db.collection('product_categories')
    .where('isActive', '==', true)
    .get();

  // Si aucune catégorie trouvée avec isActive, récupérer toutes les catégories
  if (categoriesSnapshot.empty) {
    console.log('⚠️  Aucune catégorie avec isActive=true, récupération de toutes les catégories...');
    categoriesSnapshot = await db.collection('product_categories').get();
  }

  const validCategories = new Map();
  categoriesSnapshot.forEach(doc => {
    const data = doc.data();
    validCategories.set(doc.id, data);
    console.log(`   📁 ${doc.id}: ${data.name || 'Sans nom'} (isActive: ${data.isActive !== undefined ? data.isActive : 'non défini'})`);
  });

  console.log(`\n✅ ${validCategories.size} catégories trouvées\n`);

  return validCategories;
}

async function findProductsWithObsoleteCategories(validCategories) {
  console.log('🔍 Recherche des produits avec catégories obsolètes...\n');

  const productsSnapshot = await db.collection('products').get();
  const obsoleteProducts = [];
  const validProducts = [];

  for (const doc of productsSnapshot.docs) {
    const product = doc.data();
    const productId = doc.id;

    // Vérifier si la catégorie existe
    if (!product.category) {
      obsoleteProducts.push({
        id: productId,
        name: product.name,
        vendeurId: product.vendeurId,
        issue: 'NO_CATEGORY',
        categoryValue: null
      });
      continue;
    }

    // Vérifier si la catégorie est un ID valide
    if (!validCategories.has(product.category)) {
      // Vérifier si c'est peut-être un nom au lieu d'un ID
      const isName = Array.from(validCategories.values()).some(
        cat => cat.name === product.category
      );

      obsoleteProducts.push({
        id: productId,
        name: product.name,
        vendeurId: product.vendeurId,
        issue: isName ? 'CATEGORY_IS_NAME' : 'INVALID_CATEGORY',
        categoryValue: product.category
      });
    } else {
      validProducts.push(productId);
    }
  }

  console.log(`📊 Résumé de l'analyse:`);
  console.log(`   - Produits valides: ${validProducts.length}`);
  console.log(`   - Produits avec problèmes: ${obsoleteProducts.length}\n`);

  return { obsoleteProducts, validProducts };
}

async function fixObsoleteProducts(obsoleteProducts, validCategories) {
  console.log('🔧 Correction des produits avec catégories obsolètes...\n');

  // Vérifier qu'il y a des catégories disponibles
  if (validCategories.size === 0) {
    console.error('❌ Erreur: Aucune catégorie disponible dans Firestore!');
    console.error('   Veuillez créer des catégories dans la collection "categories" avant d\'exécuter ce script.');
    return;
  }

  // Trouver une catégorie par défaut (première catégorie active)
  const defaultCategory = Array.from(validCategories.entries())[0];

  if (!defaultCategory) {
    console.error('❌ Erreur: Impossible de récupérer une catégorie par défaut!');
    return;
  }

  const [defaultCatId, defaultCatData] = defaultCategory;
  console.log(`📌 Catégorie par défaut: ${defaultCatId} (${defaultCatData.name})\n`);

  const batch = db.batch();
  let updateCount = 0;

  for (const product of obsoleteProducts) {
    console.log(`   Produit: ${product.name} (${product.id})`);
    console.log(`   Problème: ${product.issue}`);
    console.log(`   Valeur actuelle: ${product.categoryValue || 'null'}`);

    if (autoFix) {
      // Correction automatique
      const productRef = db.collection('products').doc(product.id);

      if (product.issue === 'CATEGORY_IS_NAME') {
        // Trouver l'ID correspondant au nom
        const matchingCat = Array.from(validCategories.entries()).find(
          ([id, data]) => data.name === product.categoryValue
        );

        if (matchingCat) {
          const [correctId, catData] = matchingCat;
          batch.update(productRef, { category: correctId });
          console.log(`   ✅ Correction: "${product.categoryValue}" → ${correctId}`);
          updateCount++;
        }
      } else {
        // Assigner à la catégorie par défaut
        batch.update(productRef, { category: defaultCatId });
        console.log(`   ✅ Correction: → ${defaultCatId} (${defaultCatData.name})`);
        updateCount++;
      }
    } else {
      console.log(`   ⚠️  Action requise: Correction manuelle nécessaire`);
    }

    console.log('');
  }

  if (!isDryRun && autoFix && updateCount > 0) {
    await batch.commit();
    console.log(`✅ ${updateCount} produits mis à jour avec succès!\n`);
  } else if (isDryRun) {
    console.log(`ℹ️  Mode DRY RUN: ${updateCount} produits seraient mis à jour\n`);
  } else if (!autoFix) {
    console.log(`ℹ️  Mode manuel: Utilisez --auto-fix pour corriger automatiquement\n`);
  }
}

async function generateReport(obsoleteProducts) {
  console.log('\n📄 RAPPORT DÉTAILLÉ\n');
  console.log('='.repeat(60));

  if (obsoleteProducts.length === 0) {
    console.log('✅ Aucun produit avec catégorie obsolète trouvé!');
    return;
  }

  // Grouper par type de problème
  const byIssue = obsoleteProducts.reduce((acc, p) => {
    if (!acc[p.issue]) acc[p.issue] = [];
    acc[p.issue].push(p);
    return acc;
  }, {});

  Object.entries(byIssue).forEach(([issue, products]) => {
    console.log(`\n${issue} (${products.length} produits):`);
    products.forEach(p => {
      console.log(`  - ${p.name} (${p.id})`);
      console.log(`    Catégorie: ${p.categoryValue || 'null'}`);
      console.log(`    Vendeur: ${p.vendeurId}`);
    });
  });

  console.log('\n' + '='.repeat(60));
}

// Fonction principale
async function main() {
  try {
    // 1. Récupérer les catégories valides
    const validCategories = await getValidCategories();

    // 2. Trouver les produits avec problèmes
    const { obsoleteProducts, validProducts } = await findProductsWithObsoleteCategories(validCategories);

    // 3. Générer le rapport
    await generateReport(obsoleteProducts);

    // 4. Corriger si demandé
    if (obsoleteProducts.length > 0 && (autoFix || !isDryRun)) {
      await fixObsoleteProducts(obsoleteProducts, validCategories);
    }

    console.log('\n✅ Script terminé avec succès!');
    process.exit(0);
  } catch (error) {
    console.error('\n❌ Erreur lors de l\'exécution du script:', error);
    process.exit(1);
  }
}

// Exécuter le script
main();
