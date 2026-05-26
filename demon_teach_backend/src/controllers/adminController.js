const { db, auth } = require('../config/firebase');
const { exec } = require('child_process');
const path = require('path');

/**
 * Admin Controller
 * Handles administrative features (Stats, Users, Leaderboard, Notifications, Systems, Backups)
 */

// 1. Get System Stats
exports.getStats = async (req, res, next) => {
  try {
    if (!db) throw new Error('Firestore is not initialized');

    // Fetch users count
    const usersSnap = await db.collection('users').get();
    const totalUsers = usersSnap.size;

    // Fetch lessons completed
    const progressQuery = await db.collection('user_progress')
      .where('status', '==', 'completed')
      .get();
    const completedLessons = progressQuery.size;

    // Fetch average streak & total XP
    const streakQuery = await db.collection('progress').get();
    let totalStreak = 0;
    let totalXP = 0;
    let streakCount = 0;

    streakQuery.forEach(doc => {
      const data = doc.data();
      if (data.currentStreak !== undefined) {
        totalStreak += data.currentStreak;
        streakCount++;
      }
      if (data.totalXP !== undefined) {
        totalXP += data.totalXP;
      }
    });

    const averageStreak = streakCount > 0 ? Math.round(totalStreak / streakCount) : 0;

    // Fetch average quiz accuracy
    // Since some user_progress records store quiz scores/accuracy, let's aggregate them
    let totalAccuracy = 0;
    let accuracyCount = 0;
    progressQuery.forEach(doc => {
      const data = doc.data();
      if (data.score !== undefined && data.score > 0) {
        // Assume score represents accuracy or performance metric
        totalAccuracy += data.score;
        accuracyCount++;
      }
    });
    const averageAccuracy = accuracyCount > 0 ? Math.round(totalAccuracy / accuracyCount) : 85; // Fallback default to 85%

    res.json({
      success: true,
      data: {
        totalUsers,
        completedLessons,
        averageStreak,
        averageAccuracy,
        totalXP
      }
    });
  } catch (error) {
    next(error);
  }
};

// 2. User Management
exports.listUsers = async (req, res, next) => {
  try {
    if (!auth || !db) throw new Error('Firebase is not initialized');

    const { page = 1, limit = 50, search = '' } = req.query;

    // Fetch Auth users (up to 1000)
    const listUsersResult = await auth.listUsers(1000);
    const authUsers = listUsersResult.users;

    // Fetch Firestore users profile
    const usersSnap = await db.collection('users').get();
    const firestoreUsers = {};
    usersSnap.forEach(doc => {
      firestoreUsers[doc.id] = doc.data();
    });

    // Merge lists
    let mergedUsers = authUsers.map(authUser => {
      const dbUser = firestoreUsers[authUser.uid] || {};
      return {
        id: authUser.uid,
        email: authUser.email || '',
        displayName: authUser.displayName || dbUser.displayName || 'Học giả ẩn danh',
        role: dbUser.role || 'user',
        nativeLanguage: dbUser.nativeLanguage || 'vi',
        targetLanguages: dbUser.targetLanguages || [],
        createdAt: authUser.metadata.creationTime,
        lastSignInAt: authUser.metadata.lastSignInTime,
        disabled: authUser.disabled
      };
    });

    // Filter search locally
    if (search) {
      const query = search.toLowerCase();
      mergedUsers = mergedUsers.filter(u => 
        u.email.toLowerCase().includes(query) || 
        u.displayName.toLowerCase().includes(query) ||
        u.id.includes(query)
      );
    }

    const total = mergedUsers.length;
    const startIndex = (page - 1) * limit;
    const paginatedUsers = mergedUsers.slice(startIndex, startIndex + parseInt(limit));

    res.json({
      success: true,
      data: {
        users: paginatedUsers,
        pagination: {
          total,
          page: parseInt(page),
          limit: parseInt(limit),
          totalPages: Math.ceil(total / limit)
        }
      }
    });
  } catch (error) {
    next(error);
  }
};

exports.updateUserRole = async (req, res, next) => {
  try {
    const { userId } = req.params;
    const { role } = req.body; // 'admin' or 'user'
    if (!db) throw new Error('Firestore is not initialized');

    const userDocRef = db.collection('users').doc(userId);
    const userDoc = await userDocRef.get();

    if (!userDoc.exists) {
      // If profile doesn't exist yet, initialize it
      await userDocRef.set({
        id: userId,
        role: role,
        updatedAt: new Date().toISOString()
      }, { merge: true });
    } else {
      await userDocRef.update({
        role: role,
        updatedAt: new Date().toISOString()
      });
    }

    // Also update custom claims in Firebase Auth if available
    if (auth) {
      await auth.setCustomUserClaims(userId, { role });
    }

    res.json({
      success: true,
      message: `User role updated to ${role} successfully`
    });
  } catch (error) {
    next(error);
  }
};

exports.deleteUser = async (req, res, next) => {
  try {
    const { userId } = req.params;
    if (!db || !auth) throw new Error('Firebase is not initialized');

    // 1. Delete from Firebase Authentication
    await auth.deleteUser(userId);

    // 2. Delete Firestore records
    await db.collection('users').doc(userId).delete();
    
    // Delete progress documents
    const progressSnap = await db.collection('progress').where('userId', '==', userId).get();
    const batch = db.batch();
    progressSnap.docs.forEach(doc => {
      batch.delete(doc.ref);
    });
    
    // Delete user_progress documents
    const userProgressSnap = await db.collection('user_progress').where('userId', '==', userId).get();
    userProgressSnap.docs.forEach(doc => {
      batch.delete(doc.ref);
    });

    // Delete learning paths
    const pathsSnap = await db.collection('learning_paths').where('userId', '==', userId).get();
    pathsSnap.docs.forEach(doc => {
      batch.delete(doc.ref);
    });

    await batch.commit();

    res.json({
      success: true,
      message: 'User and all related learning progress deleted successfully'
    });
  } catch (error) {
    next(error);
  }
};

// 3. Leaderboard Management
exports.getLeaderboard = async (req, res, next) => {
  try {
    const { language } = req.params;
    if (!db) throw new Error('Firestore is not initialized');

    const progressQuery = await db.collection('progress')
      .where('targetLanguage', '==', language)
      .get();

    const usersSnap = await db.collection('users').get();
    const userMap = {};
    usersSnap.forEach(doc => {
      userMap[doc.id] = doc.data();
    });

    const entries = [];
    progressQuery.forEach(doc => {
      const data = doc.data();
      const user = userMap[data.userId] || {};
      entries.push({
        id: doc.id,
        userId: data.userId,
        displayName: user.displayName || user.email?.split('@')[0] || 'Chiến binh ẩn danh',
        email: user.email || '',
        totalXP: data.totalXP || 0,
        currentStreak: data.currentStreak || 0,
        souls: data.souls || 0,
        updatedAt: data.updatedAt || ''
      });
    });

    // Sort by XP
    entries.sort((a, b) => b.totalXP - a.totalXP);
    
    // Add Rank
    const rankedEntries = entries.map((entry, index) => ({
      rank: index + 1,
      ...entry
    }));

    res.json({
      success: true,
      data: rankedEntries
    });
  } catch (error) {
    next(error);
  }
};

exports.updateLeaderboardProgress = async (req, res, next) => {
  try {
    const { progressId } = req.params;
    const { totalXP, currentStreak, souls } = req.body;
    if (!db) throw new Error('Firestore is not initialized');

    await db.collection('progress').doc(progressId).update({
      ...(totalXP !== undefined && { totalXP: parseInt(totalXP) }),
      ...(currentStreak !== undefined && { currentStreak: parseInt(currentStreak) }),
      ...(souls !== undefined && { souls: parseInt(souls) }),
      updatedAt: new Date().toISOString()
    });

    res.json({
      success: true,
      message: 'Leaderboard progress metrics updated successfully'
    });
  } catch (error) {
    next(error);
  }
};

exports.resetLeaderboardProgress = async (req, res, next) => {
  try {
    const { progressId } = req.params;
    if (!db) throw new Error('Firestore is not initialized');

    await db.collection('progress').doc(progressId).update({
      totalXP: 0,
      currentStreak: 0,
      souls: 0,
      updatedAt: new Date().toISOString()
    });

    res.json({
      success: true,
      message: 'Leaderboard progress metrics reset to 0'
    });
  } catch (error) {
    next(error);
  }
};

// 4. Send Broadcast Notifications
exports.sendNotification = async (req, res, next) => {
  try {
    const { title, body } = req.body;
    if (!db) throw new Error('Firestore is not initialized');

    if (!title || !body) {
      return res.status(400).json({
        success: false,
        message: 'Title and body are required'
      });
    }

    const notificationDoc = {
      id: `notif_${Date.now()}`,
      title,
      body,
      createdAt: new Date().toISOString()
    };

    await db.collection('notifications').doc(notificationDoc.id).set(notificationDoc);

    res.json({
      success: true,
      message: 'Broadcast notification sent successfully',
      data: notificationDoc
    });
  } catch (error) {
    next(error);
  }
};

// 5. System Data (Wipe & Seeds)
exports.runWipeFirestore = (req, res, next) => {
  const scriptPath = path.join(__dirname, '../scripts/wipe_firestore.js');
  console.log(`Running script: node ${scriptPath}`);
  
  exec(`node "${scriptPath}"`, (error, stdout, stderr) => {
    if (error) {
      console.error(`Wipe Firestore Error: ${error.message}`);
      return res.status(500).json({
        success: false,
        message: 'Wipe Firestore process failed',
        error: stderr || error.message
      });
    }
    
    res.json({
      success: true,
      message: 'Firestore cleanup executed successfully',
      output: stdout
    });
  });
};

exports.runWipeAuthUsers = (req, res, next) => {
  const scriptPath = path.join(__dirname, '../scripts/wipe_auth_users.js');
  console.log(`Running script: node ${scriptPath}`);
  
  exec(`node "${scriptPath}"`, (error, stdout, stderr) => {
    if (error) {
      console.error(`Wipe Auth Users Error: ${error.message}`);
      return res.status(500).json({
        success: false,
        message: 'Wipe Firebase Auth Users failed',
        error: stderr || error.message
      });
    }
    
    res.json({
      success: true,
      message: 'Auth users cleanup executed successfully',
      output: stdout
    });
  });
};

exports.runSeedLessons = (req, res, next) => {
  const scriptPath = path.join(__dirname, '../scripts/seed_predefined_lessons_v2.js');
  console.log(`Running script: node ${scriptPath}`);
  
  exec(`node "${scriptPath}"`, (error, stdout, stderr) => {
    if (error) {
      console.error(`Seed Lessons Error: ${error.message}`);
      return res.status(500).json({
        success: false,
        message: 'Seed lessons process failed',
        error: stderr || error.message
      });
    }
    
    res.json({
      success: true,
      message: 'Predefined lessons seeded successfully',
      output: stdout
    });
  });
};

// 6. Data Backup (Export & Import)
exports.exportBackup = async (req, res, next) => {
  try {
    if (!db) throw new Error('Firestore is not initialized');

    const collections = ['users', 'lessons', 'progress', 'learning_paths', 'user_progress', 'notifications'];
    const backupData = {};

    for (const col of collections) {
      const snap = await db.collection(col).get();
      const items = [];
      snap.forEach(doc => {
        items.push({ id: doc.id, ...doc.data() });
      });
      backupData[col] = items;
    }

    res.json({
      success: true,
      data: backupData
    });
  } catch (error) {
    next(error);
  }
};

exports.importBackup = async (req, res, next) => {
  try {
    if (!db) throw new Error('Firestore is not initialized');
    const { backup } = req.body;

    if (!backup || typeof backup !== 'object') {
      return res.status(400).json({
        success: false,
        message: 'Valid backup JSON object is required'
      });
    }

    const collections = Object.keys(backup);
    let docCount = 0;

    for (const col of collections) {
      const items = backup[col];
      if (Array.isArray(items)) {
        for (const item of items) {
          const { id, ...data } = item;
          if (id) {
            await db.collection(col).doc(id).set(data);
            docCount++;
          }
        }
      }
    }

    res.json({
      success: true,
      message: `Database restored successfully. Imported ${docCount} documents across ${collections.length} collections.`
    });
  } catch (error) {
    next(error);
  }
};
