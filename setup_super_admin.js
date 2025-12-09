// Script pour configurer admin@socialbusiness.ci comme super administrateur

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

// Initialiser Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function setupSuperAdmin() {
  try {
    console.log('🔍 Recherche de l\'utilisateur admin@socialbusiness.ci...');

    // Chercher l'utilisateur par email
    const usersSnapshot = await db.collection('users')
      .where('email', '==', 'admin@socialbusiness.ci')
      .limit(1)
      .get();

    if (usersSnapshot.empty) {
      console.log('❌ Utilisateur admin@socialbusiness.ci non trouvé');
      console.log('💡 Créez d\'abord un compte avec cet email dans l\'application');
      process.exit(1);
    }

    const userDoc = usersSnapshot.docs[0];
    const userId = userDoc.id;
    const userData = userDoc.data();

    console.log('✅ Utilisateur trouvé:', {
      id: userId,
      email: userData.email,
      displayName: userData.displayName,
      userType: userData.userType,
      isSuperAdmin: userData.isSuperAdmin || false
    });

    // Mettre à jour l'utilisateur
    console.log('\n📝 Mise à jour en super administrateur...');

    await db.collection('users').doc(userId).update({
      userType: 'admin',
      isSuperAdmin: true,
      isActive: true,
      isVerified: true,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    console.log('✅ Utilisateur mis à jour avec succès!');

    // Vérifier les modifications
    const updatedDoc = await db.collection('users').doc(userId).get();
    const updatedData = updatedDoc.data();

    console.log('\n✅ Configuration finale:');
    console.log({
      id: userId,
      email: updatedData.email,
      displayName: updatedData.displayName,
      userType: updatedData.userType,
      isSuperAdmin: updatedData.isSuperAdmin,
      isActive: updatedData.isActive,
      isVerified: updatedData.isVerified
    });

    console.log('\n🎉 Super administrateur configuré avec succès!');
    console.log('🔐 Vous pouvez maintenant vous connecter avec:');
    console.log('   Email: admin@socialbusiness.ci');
    console.log('   Accès: Super Admin (toutes les permissions)');

    process.exit(0);
  } catch (error) {
    console.error('❌ Erreur:', error);
    process.exit(1);
  }
}

setupSuperAdmin();
