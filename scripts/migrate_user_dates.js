/**
 * Script de migration Firestore - Conversion des dates String vers Timestamp
 *
 * Ce script corrige le problème où les dates étaient stockées en String
 * au lieu de Timestamp, causant l'erreur: "Class 'String' has no instance method 'toDate'"
 *
 * AVANT d'exécuter:
 * 1. Téléchargez votre clé de service Firebase depuis la console Firebase
 * 2. Placez-la dans ce dossier scripts/ sous le nom: serviceAccountKey.json
 * 3. Installez les dépendances: npm install
 * 4. Exécutez: npm run migrate
 */

const admin = require('firebase-admin');
const path = require('path');

// Initialiser Firebase Admin SDK
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

console.log('\n🚀 === DÉBUT MIGRATION DES DATES UTILISATEURS ===\n');

async function migrateUserDates() {
  try {
    // Récupérer tous les utilisateurs
    console.log('📥 Récupération de tous les utilisateurs...');
    const usersSnapshot = await db.collection('users').get();
    console.log(`✅ ${usersSnapshot.size} utilisateurs trouvés\n`);

    let successCount = 0;
    let errorCount = 0;
    let skippedCount = 0;

    // Parcourir chaque utilisateur
    for (const doc of usersSnapshot.docs) {
      const userId = doc.id;
      const data = doc.data();

      console.log(`🔄 Traitement: ${data.email || userId}`);

      try {
        const updates = {};
        let needsUpdate = false;

        // Vérifier et convertir createdAt
        if (data.createdAt) {
          if (typeof data.createdAt === 'string') {
            console.log('   📅 createdAt: String → Timestamp');
            updates.createdAt = admin.firestore.Timestamp.fromDate(
              new Date(data.createdAt)
            );
            needsUpdate = true;
          } else if (data.createdAt._seconds !== undefined) {
            console.log('   ✓ createdAt: déjà Timestamp');
          }
        }

        // Vérifier et convertir updatedAt
        if (data.updatedAt) {
          if (typeof data.updatedAt === 'string') {
            console.log('   📅 updatedAt: String → Timestamp');
            updates.updatedAt = admin.firestore.Timestamp.fromDate(
              new Date(data.updatedAt)
            );
            needsUpdate = true;
          } else if (data.updatedAt._seconds !== undefined) {
            console.log('   ✓ updatedAt: déjà Timestamp');
          }
        }

        // Vérifier et convertir lastLoginAt
        if (data.lastLoginAt) {
          if (typeof data.lastLoginAt === 'string') {
            console.log('   📅 lastLoginAt: String → Timestamp');
            updates.lastLoginAt = admin.firestore.Timestamp.fromDate(
              new Date(data.lastLoginAt)
            );
            needsUpdate = true;
          } else if (data.lastLoginAt._seconds !== undefined) {
            console.log('   ✓ lastLoginAt: déjà Timestamp');
          }
        }

        // Mettre à jour si nécessaire
        if (needsUpdate) {
          await doc.ref.update(updates);
          console.log('   ✅ Utilisateur mis à jour\n');
          successCount++;
        } else {
          console.log('   ⏭️  Aucune mise à jour nécessaire\n');
          skippedCount++;
        }

      } catch (error) {
        console.log(`   ❌ Erreur: ${error.message}\n`);
        errorCount++;
      }
    }

    // Afficher le résumé
    console.log('\n🎉 === MIGRATION TERMINÉE ===');
    console.log(`✅ Mis à jour: ${successCount} utilisateurs`);
    console.log(`⏭️  Ignorés: ${skippedCount} utilisateurs (déjà OK)`);
    console.log(`❌ Erreurs: ${errorCount} utilisateurs`);
    console.log(`\nTotal: ${usersSnapshot.size} utilisateurs traités\n`);

  } catch (error) {
    console.error('❌ ERREUR FATALE:', error);
    console.error('La migration a échoué.\n');
  } finally {
    // Fermer la connexion
    await admin.app().delete();
  }
}

// Exécuter la migration
migrateUserDates();
