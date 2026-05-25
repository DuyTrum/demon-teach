const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { authenticate } = require('../middleware/auth');

/**
 * Authentication Routes
 * Base path: /api/auth
 */

// POST /api/auth/login - Login user
router.post('/login', authController.login);

// POST /api/auth/register - Register new user
router.post('/register', authController.register);

// POST /api/auth/refresh - Refresh access token
router.post('/refresh', authController.refresh);

// POST /api/auth/logout - Logout user
router.post('/logout', authenticate, authController.logout);

// GET /api/auth/me - Get current user
router.get('/me', authenticate, authController.me);

// PUT /api/auth/profile - Update current user profile
router.put('/profile', authenticate, authController.updateProfile);

module.exports = router;
