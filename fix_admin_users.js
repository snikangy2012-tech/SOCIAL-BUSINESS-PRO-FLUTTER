/**
 * Script pour corriger les utilisateurs admin créés
 * - Marque leur email comme vérifié
 * - Active leur compte
 * - Vérifie leur userType
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

async function fixAdminUsers() {
  try {
    console.log('🔍 Recherche des utilisateurs admin...\n');

    // Récupérer tous les utilisateurs admin depuis Firestore
    const adminsSnapshot = await db.collection('users')
      .where('userType', '==', 'admin')
      .get();

    if (adminsSnapshot.empty) {
      console.log('❌ Aucun utilisateur admin trouvé dans Firestore');
      return;
    }

    console.log(`✅ ${adminsSnapshot.docs.length} admin(s) trouvé(s)\n`);

    for (const doc of adminsSnapshot.docs) {
      const adminData = doc.data();
      const adminId = doc.id;
      const adminEmail = adminData.email;

      console.log(`━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`);
      console.log(`👤 Admin: ${adminData.displayName || 'Sans nom'}`);
      console.log(`📧 Email: ${adminEmail}`);
      console.log(`🆔 UID: ${adminId}`);

      try {
        // Récupérer l'utilisateur Firebase Auth
        const userRecord = await auth.getUser(adminId);

        console.log(`\n📋 État actuel:`);
        console.log(`   Email vérifié: ${userRecord.emailVerified}`);
        console.log(`   Compte activé: ${!userRecord.disabled}`);

        // Corrections à appliquer
        const updates = {};
        let needsAuthUpdate = false;

        // 1. Vérifier l'email si pas vérifié
        if (!userRecord.emailVerified) {
          needsAuthUpdate = true;
          console.log(`   ⚠️  Email non vérifié → Sera marqué comme vérifié`);
        }

        // 2. Activer le compte si désactivé
        if (userRecord.disabled) {
          needsAuthUpdate = true;
          console.log(`   ⚠️  Compte désactivé → Sera activé`);
        }

        // Mettre à jour Firebase Auth si nécessaire
        if (needsAuthUpdate) {
          await auth.updateUser(adminId, {
            emailVerified: true,
            disabled: false,
          });
          console.log(`\n✅ Firebase Auth mis à jour`);
        }

        // 3. Vérifier et corriger Firestore
        const firestoreUpdates = {};
        let needsFirestoreUpdate = false;

        if (adminData.isVerified !== true) {
          firestoreUpdates.isVerified = true;
          needsFirestoreUpdate = true;
          console.log(`   ⚠️  isVerified: ${adminData.isVerified} → true`);
        }

        if (adminData.isActive !== true) {
          firestoreUpdates.isActive = true;
          needsFirestoreUpdate = true;
          console.log(`   ⚠️  isActive: ${adminData.isActive} → true`);
        }

        if (adminData.userType !== 'admin') {
          firestoreUpdates.userType = 'admin';
          needsFirestoreUpdate = true;
          console.log(`   ⚠️  userType: ${adminData.userType} → admin`);
        }

        // Ajouter needsPasswordChange si première connexion
        if (adminData.needsPasswordChange === undefined) {
          firestoreUpdates.needsPasswordChange = true;
          needsFirestoreUpdate = true;
          console.log(`   ℹ️  Ajout flag needsPasswordChange: true`);
        }

        if (needsFirestoreUpdate) {
          firestoreUpdates.updatedAt = admin.firestore.FieldValue.serverTimestamp();
          await db.collection('users').doc(adminId).update(firestoreUpdates);
          console.log(`✅ Firestore mis à jour`);
        }

        if (!needsAuthUpdate && !needsFirestoreUpdate) {
          console.log(`\n✅ Aucune correction nécessaire`);
        }

      } catch (error) {
        console.error(`❌ Erreur pour ${adminEmail}:`, error.message);
      }

      console.log(''); // Ligne vide
    }

    console.log(`━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`);
    console.log(`\n✅ Traitement terminé pour ${adminsSnapshot.docs.length} admin(s)`);
    console.log(`\n💡 Les admins peuvent maintenant se connecter avec leur email et mot de passe`);
    console.log(`💡 Au premier login, ils seront invités à changer leur mot de passe`);

  } catch (error) {
    console.error('❌ Erreur:', error);
    process.exit(1);
  }
}

// Exécuter
fixAdminUsers()
  .then(() => process.exit(0))
  .catch(error => {
    console.error('❌ Erreur fatale:', error);
    process.exit(1);
  });
