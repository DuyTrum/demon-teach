const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

const pathsToTry = [
  path.join(__dirname, 'firebase-service-account.json'),
  path.join(__dirname, '../../firebase-service-account.json'),
  path.join(__dirname, '../../config/firebase-service-account.json'),
];

let initialized = false;

for (const saPath of pathsToTry) {
  if (fs.existsSync(saPath)) {
    console.log(`🔥 Initializing Firebase Admin with service account file from: ${saPath}`);
    try {
      const serviceAccount = require(saPath);
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        storageBucket: 'demon-teach.firebasestorage.app'
      });
      initialized = true;
      break;
    } catch (e) {
      console.error(`❌ Failed to initialize Firebase Admin with file ${saPath}:`, e.message);
    }
  }
}

if (!initialized) {
  console.log('⚠️ Firebase service account file not found in search paths.');
  console.log('ℹ️ Attempting to initialize with default credentials or project ID...');
  try {
    admin.initializeApp({
      projectId: 'demon-teach',
      storageBucket: 'demon-teach.firebasestorage.app'
    });
    initialized = true;
  } catch (e) {
    console.error('❌ Failed to initialize Firebase Admin with default credentials:', e.message);
  }
}

const db = initialized ? admin.firestore() : null;
const auth = initialized ? admin.auth() : null;
const storage = initialized ? admin.storage() : null;

module.exports = { admin, db, auth, storage };
