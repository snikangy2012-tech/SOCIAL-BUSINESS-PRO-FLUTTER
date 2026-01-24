// Script de nettoyage des catégories vendeur dans Firestore
// Usage: node clean_categories.js <userId>

const admin = require('firebase-admin');

// Catégories valides actuelles
const VALID_CATEGORIES = [
  'Mode & Style',
  'Électronique',
  'Électroménager',
  'Cuisine & Ustensiles',
  'Meubles & Déco',
  'Alimentaire',
  'Maison & Jardin',
  'Beauté & Soins',
  'Sport & Loisirs',
  'Auto & Moto',
  'Services'
];

async function cleanCategories(userId) {
  try {
    console.log(`🔍 Vérification du profil vendeur pour l'utilisateur: ${userId}\n`);

    // Récupérer le document utilisateur
    const userRef = admin.firestore().collection('users').doc(userId);
    const userDoc = await userRef.get();

    if (!userDoc.exists) {
      console.error('❌ Utilisateur non trouvé dans Firestore');
      return;
    }

    const userData = userDoc.data();
    const vendeurProfile = userData?.profile?.vendeurProfile;

    if (!vendeurProfile) {
      console.error('❌ Pas de profil vendeur trouvé pour cet utilisateur');
      return;
    }

    console.log('📋 Profil vendeur actuel:');
    console.log('   Nom de la boutique:', vendeurProfile.businessName || 'N/A');
    console.log('   Catégories actuelles:', vendeurProfile.businessCategories || []);
    console.log('');

    // Vérifier les catégories
    const currentCategories = vendeurProfile.businessCategories || [];
    const invalidCategories = currentCategories.filter(cat => !VALID_CATEGORIES.includes(cat));
    const validCurrentCategories = currentCategories.filter(cat => VALID_CATEGORIES.includes(cat));

    if (invalidCategories.length > 0) {
      console.log('⚠️  Catégories invalides détectées:', invalidCategories);
      console.log('✅ Catégories valides:', validCurrentCategories);
      console.log('');

      // Si aucune catégorie valide, utiliser 'Alimentaire' par défaut
      const cleanedCategories = validCurrentCategories.length > 0
        ? validCurrentCategories
        : ['Alimentaire'];

      console.log('🧹 Nettoyage des catégories...');
      console.log('   Nouvelles catégories:', cleanedCategories);

      // Mettre à jour Firestore
      await userRef.update({
        'profile.vendeurProfile.businessCategories': cleanedCategories,
        'updatedAt': admin.firestore.FieldValue.serverTimestamp()
      });

      console.log('✅ Catégories nettoyées avec succès!');
    } else {
      console.log('✅ Toutes les catégories sont valides - aucun nettoyage nécessaire');
    }

    console.log('\n📊 Catégories valides disponibles:');
    VALID_CATEGORIES.forEach((cat, index) => {
      console.log(`   ${index + 1}. ${cat}`);
    });

  } catch (error) {
    console.error('❌ Erreur lors du nettoyage:', error);
  }
}

// Initialiser Firebase Admin
try {
  // Utiliser les credentials de service account ou default credentials
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
    projectId: 'socialbusinesspro-2f91c' // Remplacer par votre project ID si différent
  });
  console.log('✅ Firebase Admin initialisé\n');
} catch (error) {
  console.error('❌ Erreur d\'initialisation Firebase:', error.message);
  console.log('\nℹ️  Assurez-vous d\'avoir configuré les credentials Firebase:');
  console.log('   1. Téléchargez le fichier service account JSON depuis Firebase Console');
  console.log('   2. Définissez la variable d\'environnement GOOGLE_APPLICATION_CREDENTIALS');
  console.log('   3. Ou utilisez: firebase-admin.initializeApp({ credential: admin.credential.cert(serviceAccount) })');
  process.exit(1);
}

// Récupérer l'ID utilisateur depuis les arguments
const userId = process.argv[2];

if (!userId) {
  console.error('❌ Usage: node clean_categories.js <userId>');
  console.log('\nℹ️  Pour trouver votre userId:');
  console.log('   1. Ouvrez Firebase Console → Authentication');
  console.log('   2. Trouvez votre utilisateur vendeur');
  console.log('   3. Copiez l\'UID');
  process.exit(1);
}

// Exécuter le nettoyage
cleanCategories(userId).then(() => {
  console.log('\n✅ Script terminé');
  process.exit(0);
}).catch(error => {
  console.error('❌ Erreur fatale:', error);
  process.exit(1);
});
