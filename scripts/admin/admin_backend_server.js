/**
 * Backend simple pour la création d'administrateurs
 * Utilise Firebase Admin SDK pour créer les comptes Auth + Firestore
 *
 * DÉMARRAGE: node admin_backend_server.js
 */

const admin = require('firebase-admin');
const express = require('express');
const crypto = require('crypto');

// Initialiser Firebase Admin
if (!admin.apps.length) {
  const serviceAccount = require('./serviceAccountKey.json');
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
}

const auth = admin.auth();
const db = admin.firestore();
const app = express();
app.use(express.json());

// Fonction pour générer un mot de passe sécurisé
function generateSecurePassword() {
  // Générer un mot de passe de 12 caractères avec majuscules, minuscules, chiffres et symboles
  const length = 12;
  const charset = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@#$%&*!';
  let password = '';

  // Assurer au moins un de chaque type
  password += 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'[Math.floor(Math.random() * 26)]; // Majuscule
  password += 'abcdefghijklmnopqrstuvwxyz'[Math.floor(Math.random() * 26)]; // Minuscule
  password += '0123456789'[Math.floor(Math.random() * 10)]; // Chiffre
  password += '@#$%&*!'[Math.floor(Math.random() * 7)]; // Symbole

  // Remplir le reste aléatoirement
  for (let i = password.length; i < length; i++) {
    password += charset[Math.floor(Math.random() * charset.length)];
  }

  // Mélanger les caractères
  return password.split('').sort(() => Math.random() - 0.5).join('');
}

// Middleware de vérification du token Firebase
async function verifyFirebaseToken(req, res, next) {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Token manquant' });
  }

  const token = authHeader.split('Bearer ')[1];

  try {
    const decodedToken = await auth.verifyIdToken(token);

    // Vérifier que l'utilisateur est bien un super admin
    const userDoc = await db.collection('users').doc(decodedToken.uid).get();
    const userData = userDoc.data();

    if (!userData || userData.userType !== 'admin' || userData.isSuperAdmin !== true) {
      return res.status(403).json({ error: 'Accès refusé: Super Admin requis' });
    }

    req.user = {
      uid: decodedToken.uid,
      email: decodedToken.email
    };

    next();
  } catch (error) {
    console.error('❌ Erreur vérification token:', error);
    return res.status(401).json({ error: 'Token invalide' });
  }
}

// Route de santé
app.get('/health', (req, res) => {
  res.json({ status: 'ok', message: 'Admin Backend Server is running' });
});

// Route pour créer un administrateur
app.post('/api/admin/create', verifyFirebaseToken, async (req, res) => {
  const { email, displayName, adminRole } = req.body;

  // Validation
  if (!email || !displayName || !adminRole) {
    return res.status(400).json({
      error: 'Champs manquants',
      required: ['email', 'displayName', 'adminRole']
    });
  }

  // Générer un mot de passe temporaire sécurisé
  const temporaryPassword = generateSecurePassword();

  try {
    console.log(`\n🔧 Création admin: ${displayName} (${email})`);

    // 1. Créer le compte Firebase Auth
    const userRecord = await auth.createUser({
      email: email,
      emailVerified: true, // Vérifier l'email directement
      displayName: displayName,
      password: temporaryPassword,
      disabled: false,
    });

    console.log(`✅ Compte Auth créé: ${userRecord.uid}`);

    // 2. Créer le document Firestore avec le même UID
    await db.collection('users').doc(userRecord.uid).set({
      email: email,
      displayName: displayName,
      userType: 'admin',
      adminRole: adminRole,
      isSuperAdmin: false,
      customPrivileges: [],
      isActive: true,
      isVerified: true,
      needsPasswordChange: true, // Doit changer le mot de passe à la première connexion
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      createdBy: req.user.uid,
      profile: {}
    });

    console.log(`✅ Document Firestore créé`);

    // 3. Retourner les informations (le mot de passe temporaire ne sera affiché qu'une fois)
    res.status(201).json({
      success: true,
      admin: {
        uid: userRecord.uid,
        email: userRecord.email,
        displayName: userRecord.displayName,
        temporaryPassword: temporaryPassword, // ⚠️ À afficher une seule fois à l'utilisateur
      },
      message: 'Administrateur créé avec succès'
    });

    console.log(`✅ Admin créé avec succès\n`);

  } catch (error) {
    console.error('❌ Erreur création admin:', error);

    // Gérer les erreurs spécifiques
    if (error.code === 'auth/email-already-exists') {
      return res.status(400).json({
        error: 'Cet email est déjà utilisé',
        code: 'EMAIL_EXISTS'
      });
    }

    res.status(500).json({
      error: 'Erreur lors de la création',
      message: error.message
    });
  }
});

// Route pour réinitialiser le mot de passe d'un admin
app.post('/api/admin/reset-password', verifyFirebaseToken, async (req, res) => {
  const { adminUid } = req.body;

  if (!adminUid) {
    return res.status(400).json({ error: 'adminUid requis' });
  }

  try {
    // Vérifier que c'est bien un admin
    const userDoc = await db.collection('users').doc(adminUid).get();
    if (!userDoc.exists || userDoc.data().userType !== 'admin') {
      return res.status(404).json({ error: 'Administrateur non trouvé' });
    }

    // Générer un nouveau mot de passe
    const newPassword = generateSecurePassword();

    // Mettre à jour le mot de passe
    await auth.updateUser(adminUid, {
      password: newPassword
    });

    // Marquer comme devant changer le mot de passe
    await db.collection('users').doc(adminUid).update({
      needsPasswordChange: true,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    res.json({
      success: true,
      temporaryPassword: newPassword,
      message: 'Mot de passe réinitialisé'
    });

  } catch (error) {
    console.error('❌ Erreur réinitialisation:', error);
    res.status(500).json({ error: error.message });
  }
});

// Démarrer le serveur
const PORT = process.env.PORT || 3001;
app.listen(PORT, () => {
  console.log(`\n🚀 Admin Backend Server démarré`);
  console.log(`📡 Port: ${PORT}`);
  console.log(`✅ Routes disponibles:`);
  console.log(`   GET  /health - Vérifier le statut`);
  console.log(`   POST /api/admin/create - Créer un admin`);
  console.log(`   POST /api/admin/reset-password - Réinitialiser mot de passe\n`);
});
