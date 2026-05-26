const { auth } = require('../config/firebase');
require('dotenv').config();

async function wipeAllAuthUsers() {
  console.log('🧹 Starting Firebase Authentication users cleanup...');
  if (!auth) {
    console.error('❌ Firebase Auth is not connected/initialized.');
    process.exit(1);
  }

  try {
    let count = 0;
    let listUsersResult = await auth.listUsers(1000);
    let users = listUsersResult.users;
    
    while (users.length > 0) {
      const uids = users.map(user => user.uid);
      await auth.deleteUsers(uids);
      count += uids.length;
      console.log(`✅ Deleted batch of ${uids.length} users.`);
      
      if (listUsersResult.pageToken) {
        listUsersResult = await auth.listUsers(1000, listUsersResult.pageToken);
        users = listUsersResult.users;
      } else {
        break;
      }
    }
    
    console.log(`\n✨ Firebase Authentication cleanup completed: Wiped ${count} users!`);
    process.exit(0);
  } catch (error) {
    console.error('❌ Error during Firebase Auth cleanup:', error);
    process.exit(1);
  }
}

wipeAllAuthUsers();
