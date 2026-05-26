const { db } = require('../config/firebase');
require('dotenv').config();

async function deleteCollection(collectionPath, batchSize = 100) {
  if (!db) {
    console.error('❌ Firestore not initialized.');
    return;
  }
  const collectionRef = db.collection(collectionPath);
  const query = collectionRef.orderBy('__name__').limit(batchSize);

  return new Promise((resolve, reject) => {
    deleteQueryBatch(query, resolve, reject);
  });
}

async function deleteQueryBatch(query, resolve, reject) {
  try {
    const snapshot = await query.get();

    const batchSize = snapshot.size;
    if (batchSize === 0) {
      resolve();
      return;
    }

    const batch = db.batch();
    snapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });
    await batch.commit();

    process.nextTick(() => {
      deleteQueryBatch(query, resolve, reject);
    });
  } catch (error) {
    reject(error);
  }
}

async function wipeAllFirestoreUserData() {
  console.log('🧹 Starting Cloud Firestore cleanup...');
  if (!db) {
    console.error('❌ Cloud Firestore is not connected.');
    process.exit(1);
  }

  try {
    // 1. Wipe progress
    console.log('⏳ Wiping "progress" collection...');
    await deleteCollection('progress');
    console.log('✅ Wiped "progress" collection.');

    // 2. Wipe user_progress
    console.log('⏳ Wiping "user_progress" collection...');
    await deleteCollection('user_progress');
    console.log('✅ Wiped "user_progress" collection.');

    // 3. Wipe learning_paths
    console.log('⏳ Wiping "learning_paths" collection...');
    await deleteCollection('learning_paths');
    console.log('✅ Wiped "learning_paths" collection.');

    // 4. Wipe subcollections inside users (preferences)
    console.log('⏳ Wiping user preferences subcollections...');
    const usersSnapshot = await db.collection('users').get();
    for (const userDoc of usersSnapshot.docs) {
      const userId = userDoc.id;
      console.log(`   - Wiping preferences subcollection for user: ${userId}`);
      await deleteCollection(`users/${userId}/preferences`);
    }

    // 5. Wipe users collection itself
    console.log('⏳ Wiping "users" collection...');
    await deleteCollection('users');
    console.log('✅ Wiped "users" collection.');

    // 6. Wipe lessons collection (to remove AI generated & older lessons)
    console.log('⏳ Wiping "lessons" collection...');
    await deleteCollection('lessons');
    console.log('✅ Wiped "lessons" collection.');

    console.log('\n✨ Cloud Firestore clean up completed successfully!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error during Cloud Firestore cleanup:', error);
    process.exit(1);
  }
}

wipeAllFirestoreUserData();
