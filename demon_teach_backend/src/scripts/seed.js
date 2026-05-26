const { db, auth } = require('../config/firebase');
require('dotenv').config();

const seedDatabase = async () => {
  try {
    console.log('🌱 Starting Firebase seeding...');

    if (!db || !auth) {
      console.error('❌ Firebase is not initialized. Check your service account file.');
      process.exit(1);
    }

    // Create admin user in Firebase Auth
    console.log('👤 Creating admin user in Firebase Auth...');
    let adminUid;
    try {
      const adminRecord = await auth.createUser({
        email: 'admin@demonteach.com',
        password: 'admin123',
        emailVerified: true
      });
      adminUid = adminRecord.uid;
      console.log('✅ Admin user created in Firebase Auth.');
    } catch (e) {
      if (e.code === 'auth/email-already-exists') {
        const existingAdmin = await auth.getUserByEmail('admin@demonteach.com');
        adminUid = existingAdmin.uid;
        console.log('ℹ️  Admin user already exists in Firebase Auth.');
      } else {
        throw e;
      }
    }

    // Set admin custom claims
    await auth.setCustomUserClaims(adminUid, { role: 'admin' });
    console.log('✅ Admin custom claims set.');

    // Create admin profile in Firestore
    await db.collection('users').doc(adminUid).set({
      email: 'admin@demonteach.com',
      role: 'admin',
      nativeLanguage: 'vi',
      targetLanguages: [],
      isActive: true,
      createdAt: new Date().toISOString(),
      lastActiveAt: new Date().toISOString()
    }, { merge: true });
    console.log('✅ Admin profile saved in Firestore.');

    console.log('\n✨ Firebase seeding completed successfully!');
    console.log('\n📋 Summary:');
    console.log('   - Admin: admin@demonteach.com / admin123');
    console.log('\n🚀 You can now start the server with: npm start');

    process.exit(0);
  } catch (error) {
    console.error('❌ Error seeding database:', error);
    process.exit(1);
  }
};

seedDatabase();
