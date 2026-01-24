/**
 * Script de diagnostic des catégories Firestore
 *
 * Affiche la structure complète des catégories et produits
 * pour identifier les problèmes de configuration
 */

const admin = require('firebase-admin');
const serviceAccount = require('../serviceAccountKey.json');

// Initialiser Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

console.log('🔍 DIAGNOSTIC DES CATÉGORIES FIRESTORE\n');
console.log('='.repeat(70));

async function diagnoseCategoriesCollection() {
  console.log('\n📁 COLLECTION "product_categories"\n');

  const categoriesSnapshot = await db.collection('product_categories').get();

  if (categoriesSnapshot.empty) {
    console.log('❌ PROBLÈME: La collection "product_categories" est VIDE!');
    console.log('   Solution: Créez des catégories dans Firestore avant de continuer.\n');
    return new Map();
  }

  console.log(`✅ ${categoriesSnapshot.size} documents trouvés:\n`);

  const categoriesMap = new Map();

  categoriesSnapshot.forEach(doc => {
    const data = doc.data();
    categoriesMap.set(doc.id, data);

    console.log(`📌 ID: "${doc.id}"`);
    console.log(`   Nom: ${data.name || '⚠️  NON DÉFINI'}`);
    console.log(`   isActive: ${data.isActive !== undefined ? data.isActive : '⚠️  NON DÉFINI'}`);
    console.log(`   icon: ${data.icon ? '✓' : '⚠️  NON DÉFINI'}`);
    console.log(`   displayOrder: ${data.displayOrder !== undefined ? data.displayOrder : '⚠️  NON DÉFINI'}`);

    if (data.subCategories && data.subCategories.length > 0) {
      console.log(`   Sous-catégories (${data.subCategories.length}): ${data.subCategories.join(', ')}`);
    } else {
      console.log(`   Sous-catégories: Aucune`);
    }

    console.log('');
  });

  return categoriesMap;
}

async function diagnoseProductsCollection(categoriesMap) {
  console.log('\n📦 COLLECTION "products"\n');

  const productsSnapshot = await db.collection('products').get();

  if (productsSnapshot.empty) {
    console.log('ℹ️  Aucun produit dans la base de données.\n');
    return;
  }

  console.log(`✅ ${productsSnapshot.size} produits trouvés:\n`);

  const categoryUsage = new Map();
  const problems = {
    noCategory: [],
    invalidCategory: [],
    categoryIsName: [],
    valid: []
  };

  productsSnapshot.forEach(doc => {
    const product = doc.data();
    const productId = doc.id;

    // Compter l'utilisation de chaque catégorie
    if (product.category) {
      const count = categoryUsage.get(product.category) || 0;
      categoryUsage.set(product.category, count + 1);

      // Vérifier si la catégorie est valide
      if (categoriesMap.has(product.category)) {
        problems.valid.push({ id: productId, name: product.name, category: product.category });
      } else {
        // Vérifier si c'est un nom au lieu d'un ID
        const isName = Array.from(categoriesMap.values()).some(
          cat => cat.name === product.category
        );

        if (isName) {
          problems.categoryIsName.push({
            id: productId,
            name: product.name,
            category: product.category
          });
        } else {
          problems.invalidCategory.push({
            id: productId,
            name: product.name,
            category: product.category
          });
        }
      }
    } else {
      problems.noCategory.push({ id: productId, name: product.name });
    }
  });

  // Afficher l'utilisation des catégories
  console.log('📊 UTILISATION DES CATÉGORIES:\n');
  categoryUsage.forEach((count, categoryValue) => {
    const isValid = categoriesMap.has(categoryValue);
    const status = isValid ? '✅' : '❌';
    console.log(`   ${status} "${categoryValue}": ${count} produit(s)`);
  });

  // Afficher les problèmes
  console.log('\n\n⚠️  PROBLÈMES DÉTECTÉS:\n');

  if (problems.noCategory.length > 0) {
    console.log(`❌ ${problems.noCategory.length} produit(s) SANS CATÉGORIE:`);
    problems.noCategory.slice(0, 5).forEach(p => {
      console.log(`   - ${p.name} (${p.id})`);
    });
    if (problems.noCategory.length > 5) {
      console.log(`   ... et ${problems.noCategory.length - 5} autre(s)`);
    }
    console.log('');
  }

  if (problems.categoryIsName.length > 0) {
    console.log(`⚠️  ${problems.categoryIsName.length} produit(s) avec NOM au lieu d'ID:`);
    problems.categoryIsName.slice(0, 5).forEach(p => {
      console.log(`   - ${p.name} (${p.id})`);
      console.log(`     Catégorie actuelle: "${p.category}"`);
    });
    if (problems.categoryIsName.length > 5) {
      console.log(`   ... et ${problems.categoryIsName.length - 5} autre(s)`);
    }
    console.log('');
  }

  if (problems.invalidCategory.length > 0) {
    console.log(`❌ ${problems.invalidCategory.length} produit(s) avec CATÉGORIE INVALIDE:`);
    problems.invalidCategory.slice(0, 5).forEach(p => {
      console.log(`   - ${p.name} (${p.id})`);
      console.log(`     Catégorie actuelle: "${p.category}"`);
    });
    if (problems.invalidCategory.length > 5) {
      console.log(`   ... et ${problems.invalidCategory.length - 5} autre(s)`);
    }
    console.log('');
  }

  if (problems.valid.length > 0) {
    console.log(`✅ ${problems.valid.length} produit(s) avec catégorie VALIDE\n`);
  }

  return problems;
}

async function generateRecommendations(categoriesMap, problems) {
  console.log('\n💡 RECOMMANDATIONS:\n');

  if (categoriesMap.size === 0) {
    console.log('1. ❗ URGENT: Créez des catégories dans Firestore');
    console.log('   Collection: categories');
    console.log('   Champs requis: id, name, isActive, icon, displayOrder, subCategories');
    console.log('');
    return;
  }

  const totalProblems =
    problems.noCategory.length +
    problems.categoryIsName.length +
    problems.invalidCategory.length;

  if (totalProblems === 0) {
    console.log('✅ Aucun problème détecté! Tous les produits ont des catégories valides.');
    console.log('');
    return;
  }

  console.log(`Il y a ${totalProblems} produit(s) à corriger:\n`);

  if (problems.categoryIsName.length > 0) {
    console.log('1. Pour les produits avec NOM au lieu d\'ID:');
    console.log('   → Exécutez: node scripts/cleanup_obsolete_categories.js --dry-run --auto-fix');
    console.log('   → Le script convertira automatiquement les noms en IDs');
    console.log('');
  }

  if (problems.invalidCategory.length > 0 || problems.noCategory.length > 0) {
    const firstCat = Array.from(categoriesMap.entries())[0];
    console.log('2. Pour les produits avec catégories invalides ou manquantes:');
    console.log(`   → Le script les assignera à: "${firstCat[0]}" (${firstCat[1].name})`);
    console.log('   → Ou modifiez manuellement dans Firestore');
    console.log('');
  }

  console.log('COMMANDES À EXÉCUTER:');
  console.log('  1. Diagnostic: node scripts/diagnose_categories.js');
  console.log('  2. Simulation:  node scripts/cleanup_obsolete_categories.js --dry-run --auto-fix');
  console.log('  3. Correction:  node scripts/cleanup_obsolete_categories.js --auto-fix');
  console.log('');
}

async function main() {
  try {
    const categoriesMap = await diagnoseCategoriesCollection();
    const problems = await diagnoseProductsCollection(categoriesMap);
    await generateRecommendations(categoriesMap, problems);

    console.log('='.repeat(70));
    console.log('✅ Diagnostic terminé!\n');
    process.exit(0);
  } catch (error) {
    console.error('\n❌ Erreur lors du diagnostic:', error);
    console.error('\nDétails:', error.stack);
    process.exit(1);
  }
}

main();
