// Script de migration pour ajouter les coordonnées GPS aux livraisons existantes
// Utilise l'API de géocodage pour convertir les adresses textuelles en coordonnées GPS

const admin = require('firebase-admin');
const https = require('https');

// Initialiser Firebase Admin
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'social-media-business-pro'
});

const db = admin.firestore();

// Fonction pour calculer la distance entre deux points (Haversine)
function calculateDistance(lat1, lon1, lat2, lon2) {
  const earthRadius = 6371; // Rayon de la Terre en km
  const PI = Math.PI;

  const dLat = (lat2 - lat1) * PI / 180;
  const dLon = (lon2 - lon1) * PI / 180;
  const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
            Math.cos(lat1 * PI / 180) * Math.cos(lat2 * PI / 180) *
            Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return earthRadius * c;
}

// Fonction pour calculer les frais de livraison
function calculateDeliveryFee(distance) {
  if (distance <= 10) return 1000;  // 1000 FCFA pour 0-10km
  if (distance <= 20) return 1500;  // 1500 FCFA pour 10-20km
  if (distance <= 30) return 2000;  // 2000 FCFA pour 20-30km
  return 2000 + ((distance - 30) * 100); // 2000 FCFA + 100 FCFA/km au-delà de 30km
}

// Fonction pour estimer la durée de livraison
function estimateDeliveryDuration(distance) {
  const avgSpeed = 25.0; // Vitesse moyenne en km/h (moto)
  const travelTime = (distance / avgSpeed) * 60; // Temps de trajet en minutes
  const pickupTime = 10; // Temps de récupération
  const deliveryTime = 5; // Temps de remise

  return Math.round(travelTime + pickupTime + deliveryTime);
}

// Fonction pour géocoder une adresse via l'API Google Maps Geocoding
// Note: Vous devrez configurer une clé API Google Maps Geocoding
async function geocodeAddress(address) {
  // IMPORTANT: Remplacez 'YOUR_API_KEY' par votre véritable clé API Google Maps
  const apiKey = 'AIzaSyB1GSASwjsnerHDP0j9Dc_Ukijny8jnvs8';

  if (apiKey === 'YOUR_API_KEY') {
    console.log('⚠️  Clé API Google Maps non configurée - utilisation de coordonnées par défaut (Yaoundé)');
    // Coordonnées par défaut pour Yaoundé, Cameroun
    return {
      latitude: 3.8480,
      longitude: 11.5021
    };
  }

  return new Promise((resolve, reject) => {
    const encodedAddress = encodeURIComponent(address);
    const url = `https://maps.googleapis.com/maps/api/geocode/json?address=${encodedAddress}&key=${apiKey}`;

    https.get(url, (res) => {
      let data = '';

      res.on('data', (chunk) => {
        data += chunk;
      });

      res.on('end', () => {
        try {
          const result = JSON.parse(data);

          if (result.status === 'OK' && result.results.length > 0) {
            const location = result.results[0].geometry.location;
            resolve({
              latitude: location.lat,
              longitude: location.lng
            });
          } else {
            console.log(`❌ Géocodage échoué pour "${address}": ${result.status}`);
            // Retourner coordonnées par défaut en cas d'échec
            resolve({
              latitude: 3.8480,
              longitude: 11.5021
            });
          }
        } catch (error) {
          console.error('❌ Erreur parsing résultat:', error);
          reject(error);
        }
      });
    }).on('error', (error) => {
      console.error('❌ Erreur requête HTTP:', error);
      reject(error);
    });
  });
}

// Fonction principale de migration
async function migrateDeliveryAddresses() {
  console.log('🚀 Début de la migration des adresses de livraison\n');

  try {
    // Récupérer toutes les livraisons
    const deliveriesSnapshot = await db.collection('deliveries').get();

    console.log(`📦 ${deliveriesSnapshot.size} livraisons trouvées\n`);

    let updated = 0;
    let skipped = 0;
    let errors = 0;

    for (const doc of deliveriesSnapshot.docs) {
      const delivery = doc.data();
      const deliveryId = doc.id;

      console.log(`\n📍 Livraison: ${deliveryId}`);

      // Vérifier si les coordonnées GPS existent déjà
      const hasPickupGPS = delivery.pickupAddress?.coordinates?.latitude != null &&
                          delivery.pickupAddress?.coordinates?.longitude != null;
      const hasDeliveryGPS = delivery.deliveryAddress?.coordinates?.latitude != null &&
                            delivery.deliveryAddress?.coordinates?.longitude != null;

      if (hasPickupGPS && hasDeliveryGPS) {
        console.log('  ✅ Coordonnées GPS déjà présentes - ignoré');
        skipped++;
        continue;
      }

      const updates = {};

      try {
        // Géocoder l'adresse de pickup si nécessaire
        if (!hasPickupGPS && delivery.pickupAddress?.street) {
          console.log(`  🔍 Géocodage pickup: "${delivery.pickupAddress.street}"`);
          const pickupCoords = await geocodeAddress(delivery.pickupAddress.street);

          updates['pickupAddress.coordinates'] = {
            latitude: pickupCoords.latitude,
            longitude: pickupCoords.longitude
          };

          console.log(`  ✅ Pickup: ${pickupCoords.latitude}, ${pickupCoords.longitude}`);

          // Attendre 1 seconde pour ne pas dépasser les limites de l'API
          await new Promise(resolve => setTimeout(resolve, 1000));
        }

        // Géocoder l'adresse de livraison si nécessaire
        if (!hasDeliveryGPS && delivery.deliveryAddress?.street) {
          console.log(`  🔍 Géocodage delivery: "${delivery.deliveryAddress.street}"`);
          const deliveryCoords = await geocodeAddress(delivery.deliveryAddress.street);

          updates['deliveryAddress.coordinates'] = {
            latitude: deliveryCoords.latitude,
            longitude: deliveryCoords.longitude
          };

          console.log(`  ✅ Delivery: ${deliveryCoords.latitude}, ${deliveryCoords.longitude}`);

          // Attendre 1 seconde pour ne pas dépasser les limites de l'API
          await new Promise(resolve => setTimeout(resolve, 1000));
        }

        // Recalculer la distance si on a mis à jour les coordonnées
        if (Object.keys(updates).length > 0) {
          // Récupérer les nouvelles coordonnées (mises à jour ou existantes)
          const finalPickupLat = updates['pickupAddress.coordinates']?.latitude ||
                                delivery.pickupAddress?.coordinates?.latitude;
          const finalPickupLng = updates['pickupAddress.coordinates']?.longitude ||
                                delivery.pickupAddress?.coordinates?.longitude;
          const finalDeliveryLat = updates['deliveryAddress.coordinates']?.latitude ||
                                  delivery.deliveryAddress?.coordinates?.latitude;
          const finalDeliveryLng = updates['deliveryAddress.coordinates']?.longitude ||
                                  delivery.deliveryAddress?.coordinates?.longitude;

          // Calculer la nouvelle distance
          if (finalPickupLat && finalPickupLng && finalDeliveryLat && finalDeliveryLng) {
            const newDistance = calculateDistance(
              finalPickupLat,
              finalPickupLng,
              finalDeliveryLat,
              finalDeliveryLng
            );

            const oldDistance = delivery.distance || 0;

            console.log(`  📏 Distance: ${oldDistance.toFixed(1)} km → ${newDistance.toFixed(1)} km`);

            // Recalculer les frais et la durée
            const newFee = calculateDeliveryFee(newDistance);
            const newDuration = estimateDeliveryDuration(newDistance);

            updates['distance'] = newDistance;
            updates['deliveryFee'] = newFee;
            updates['estimatedDuration'] = newDuration;

            console.log(`  💰 Frais: ${delivery.deliveryFee || 0} FCFA → ${newFee} FCFA`);
            console.log(`  ⏱️  Durée: ${delivery.estimatedDuration || 0} min → ${newDuration} min`);
          }
        }

        // Mettre à jour le document si des changements ont été faits
        if (Object.keys(updates).length > 0) {
          await doc.ref.update({
            ...updates,
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
          });
          console.log('  💾 Livraison mise à jour avec succès');
          updated++;
        } else {
          console.log('  ⚠️  Aucune adresse textuelle disponible pour géocodage');
          skipped++;
        }

      } catch (error) {
        console.error(`  ❌ Erreur lors du traitement: ${error.message}`);
        errors++;
      }
    }

    console.log('\n\n📊 RÉSUMÉ DE LA MIGRATION:');
    console.log('═══════════════════════════════════');
    console.log(`✅ Mises à jour réussies: ${updated}`);
    console.log(`⏭️  Ignorées (déjà GPS): ${skipped}`);
    console.log(`❌ Erreurs: ${errors}`);
    console.log(`📦 Total traité: ${deliveriesSnapshot.size}`);
    console.log('═══════════════════════════════════\n');

    if (updated > 0) {
      console.log('✨ Migration terminée avec succès !\n');
      console.log('💡 PROCHAINES ÉTAPES:');
      console.log('1. Vérifiez les coordonnées dans Firestore');
      console.log('2. Testez l\'application avec un compte livreur');
      console.log('3. Les nouveaux itinéraires devraient maintenant fonctionner\n');
    }

  } catch (error) {
    console.error('❌ Erreur fatale:', error);
  }

  process.exit(0);
}

// Lancer la migration
console.log('╔═══════════════════════════════════════════════════════╗');
console.log('║  MIGRATION DES ADRESSES DE LIVRAISON                 ║');
console.log('║  Ajout des coordonnées GPS manquantes                ║');
console.log('╚═══════════════════════════════════════════════════════╝\n');

console.log('⚠️  IMPORTANT: Configuration de la clé API Google Maps');
console.log('════════════════════════════════════════════════════════');
console.log('Pour utiliser le géocodage réel, vous devez:');
console.log('1. Obtenir une clé API Google Maps Geocoding');
console.log('2. Remplacer "YOUR_API_KEY" dans ce script');
console.log('3. Activer l\'API Geocoding dans Google Cloud Console\n');
console.log('Sans clé API, le script utilisera des coordonnées par défaut');
console.log('pour Yaoundé, Cameroun (3.8480, 11.5021)\n');

const readline = require('readline').createInterface({
  input: process.stdin,
  output: process.stdout
});

readline.question('Voulez-vous continuer ? (oui/non): ', (answer) => {
  readline.close();

  if (answer.toLowerCase() === 'oui' || answer.toLowerCase() === 'o') {
    migrateDeliveryAddresses();
  } else {
    console.log('\n❌ Migration annulée');
    process.exit(0);
  }
});
