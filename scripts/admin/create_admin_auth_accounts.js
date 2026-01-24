/**
 * Script pour créer les comptes Firebase Auth pour les admins qui existent dans Firestore
 */

const admin = require('firebase-admin');

// Initialiser Firebase Admin
if (!admin.apps.length) {
  const serviceAccount = require('./serviceAccountKey.json');
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
}

const auth = admin.auth();
const db = admin.firestore();

// Mot de passe temporaire par défaut (l'admin devra le changer)
const DEFAULT_TEMP_PASSWORD = 'Admin@2025';

async function createAdminAuthAccounts() {
  try {
    console.log('🔍 Recherche des admins sans compte Auth...\n');

    // Récupérer tous les utilisateurs admin depuis Firestore
    const adminsSnapshot = await db.collection('users')
      .where('userType', '==', 'admin')
      .get();

    if (adminsSnapshot.empty) {
      console.log('❌ Aucun admin trouvé dans Firestore');
      return;
    }

    console.log(`✅ ${adminsSnapshot.docs.length} admin(s) trouvé(s) dans Firestore\n`);

    let created = 0;
    let skipped = 0;
    let errors = 0;

    for (const doc of adminsSnapshot.docs) {
      const adminData = doc.data();
      const adminId = doc.id;
      const adminEmail = adminData.email;
      const adminName = adminData.displayName || 'Admin';

      console.log(`━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`);
      console.log(`👤 Admin: ${adminName}`);
      console.log(`📧 Email: ${adminEmail}`);
      console.log(`🆔 UID Firestore: ${adminId}`);

      try {
        // Vérifier si le compte Auth existe déjà
        try {
          await auth.getUser(adminId);
          console.log(`✅ Compte Auth existe déjà`);
          skipped++;
          continue;
        } catch (e) {
          // Le compte n'existe pas, on va le créer
          console.log(`⚠️  Compte Auth inexistant, création en cours...`);
        }

        // Créer le compte Firebase Auth avec l'UID de Firestore
        const userRecord = await auth.createUser({
          uid: adminId,
          email: adminEmail,
          emailVerified: true, // Vérifier l'email directement
          displayName: adminName,
          password: DEFAULT_TEMP_PASSWORD,
          disabled: false,
        });

        console.log(`✅ Compte Auth créé avec succès`);
        console.log(`   Email: ${userRecord.email}`);
        console.log(`   UID: ${userRecord.uid}`);
        console.log(`   Mot de passe temporaire: ${DEFAULT_TEMP_PASSWORD}`);

        // Mettre à jour Firestore pour indiquer que le mot de passe doit être changé
        await db.collection('users').doc(adminId).update({
          needsPasswordChange: true,
          isVerified: true,
          isActive: true,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        console.log(`✅ Firestore mis à jour (needsPasswordChange: true)`);
        created++;

      } catch (error) {
        console.error(`❌ Erreur pour ${adminEmail}:`, error.message);
        errors++;
      }

      console.log(''); // Ligne vide
    }

    console.log(`━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`);
    console.log(`\n📊 RÉSULTATS :`);
    console.log(`   ✅ Comptes créés: ${created}`);
    console.log(`   ⏭️  Ignorés (déjà existants): ${skipped}`);
    console.log(`   ❌ Erreurs: ${errors}`);

    if (created > 0) {
      console.log(`\n🔐 MOT DE PASSE TEMPORAIRE: ${DEFAULT_TEMP_PASSWORD}`);
      console.log(`💡 Les admins DOIVENT changer ce mot de passe à la première connexion`);
      console.log(`💡 Partagez ce mot de passe de manière sécurisée avec chaque admin`);
    }

  } catch (error) {
    console.error('❌ Erreur:', error);
    process.exit(1);
  }
}

// Exécuter
createAdminAuthAccounts()
  .then(() => process.exit(0))
  .catch(error => {
    console.error('❌ Erreur fatale:', error);
    process.exit(1);
  });
