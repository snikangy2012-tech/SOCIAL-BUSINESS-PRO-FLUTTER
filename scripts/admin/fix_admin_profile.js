// Script de migration pour corriger le profil admin
// Exécuter avec: node fix_admin_profile.js

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function fixAdminProfile() {
  try {
    console.log('🔍 Recherche du compte admin...');

    // Rechercher l'utilisateur admin
    const usersRef = db.collection('users');
    const snapshot = await usersRef.where('email', '==', 'admin@socialbusiness.ci').get();

    if (snapshot.empty) {
      console.log('❌ Aucun compte admin trouvé avec l\'email admin@socialbusiness.ci');
      return;
    }

    const adminDoc = snapshot.docs[0];
    const adminData = adminDoc.data();

    console.log('✅ Compte admin trouvé:', adminDoc.id);
    console.log('📋 Données actuelles:', JSON.stringify(adminData, null, 2));

    // Préparer les mises à jour
    const updates = {
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    };

    // Si le profil a un vendeurProfile avec businessCategory, le migrer
    if (adminData.profile && adminData.profile.vendeurProfile) {
      const vendeurProfile = adminData.profile.vendeurProfile;

      if (vendeurProfile.businessCategory && !vendeurProfile.businessCategories) {
        console.log('🔄 Migration de businessCategory vers businessCategories...');

        updates['profile.vendeurProfile.businessCategories'] = [vendeurProfile.businessCategory];

        // Optionnel: supprimer l'ancien champ
        // updates['profile.vendeurProfile.businessCategory'] = admin.firestore.FieldValue.delete();
      }
    }

    // Si c'est un admin, s'assurer que le userType est correct
    if (adminData.email === 'admin@socialbusiness.ci') {
      updates.userType = 'admin';
      updates.isSuperAdmin = true;

      // Admin n'a pas besoin de profil vendeur
      if (adminData.profile && adminData.profile.vendeurProfile) {
        console.log('⚠️ Admin a un profil vendeur, nettoyage recommandé');
        // Vous pouvez décommenter pour supprimer le profil vendeur
        // updates['profile.vendeurProfile'] = admin.firestore.FieldValue.delete();
      }
    }

    console.log('💾 Mise à jour du profil...');
    await adminDoc.ref.update(updates);

    console.log('✅ Profil admin mis à jour avec succès!');

    // Afficher les nouvelles données
    const updatedDoc = await adminDoc.ref.get();
    console.log('📋 Nouvelles données:', JSON.stringify(updatedDoc.data(), null, 2));

  } catch (error) {
    console.error('❌ Erreur:', error);
  } finally {
    process.exit(0);
  }
}

fixAdminProfile();
