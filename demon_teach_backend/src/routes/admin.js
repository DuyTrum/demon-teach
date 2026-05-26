const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const { authenticate, requireAdmin } = require('../middleware/auth');

/**
 * Administration Routes (Admin only)
 * Base path: /api/cms/admin
 */

// Secure all administrative routes
router.use(authenticate);
router.use(requireAdmin);

// Dashboard metrics
router.get('/stats', adminController.getStats);

// User Management
router.get('/users', adminController.listUsers);
router.put('/users/:userId/role', adminController.updateUserRole);
router.delete('/users/:userId', adminController.deleteUser);

// Leaderboard Management
router.get('/leaderboard/:language', adminController.getLeaderboard);
router.put('/leaderboard/:progressId', adminController.updateLeaderboardProgress);
router.delete('/leaderboard/:progressId', adminController.resetLeaderboardProgress);

// Push Notification Dispatcher
router.post('/notifications', adminController.sendNotification);

// System Utilities
router.post('/system/wipe-firestore', adminController.runWipeFirestore);
router.post('/system/wipe-auth-users', adminController.runWipeAuthUsers);
router.post('/system/seed-lessons', adminController.runSeedLessons);

// Backup Utilities
router.get('/backup/export', adminController.exportBackup);
router.post('/backup/import', adminController.importBackup);

module.exports = router;
