const { admin, db } = require('../config/firebase');
const axios = require('axios');
require('dotenv').config();

const FIREBASE_WEB_API_KEY = process.env.FIREBASE_WEB_API_KEY;

/**
 * Login user via Firebase Auth REST API
 * Returns Firebase ID Token + Refresh Token
 */
exports.login = async (req, res, next) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Email and password are required'
      });
    }

    if (!FIREBASE_WEB_API_KEY) {
      return res.status(500).json({
        success: false,
        message: 'FIREBASE_WEB_API_KEY is not configured on the server.'
      });
    }

    // Use Firebase Auth REST API to sign in with email/password
    const firebaseResponse = await axios.post(
      `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${FIREBASE_WEB_API_KEY}`,
      {
        email,
        password,
        returnSecureToken: true
      }
    );

    const { idToken, refreshToken, localId } = firebaseResponse.data;

    // Fetch user profile from Firestore
    let userProfile = null;
    if (db) {
      const userDoc = await db.collection('users').doc(localId).get();
      if (userDoc.exists) {
        userProfile = userDoc.data();
      }
    }

    // Determine role from custom claims or Firestore
    let role = 'user';
    try {
      const userRecord = await admin.auth().getUser(localId);
      if (userRecord.customClaims && userRecord.customClaims.role) {
        role = userRecord.customClaims.role;
      }
    } catch (e) {
      // Ignore if we can't fetch claims
    }

    // Fallback: check Firestore profile for role
    if (role === 'user' && userProfile && userProfile.role) {
      role = userProfile.role;
    }

    res.json({
      success: true,
      message: 'Login successful',
      data: {
        user: {
          id: localId,
          email: email,
          role: role,
          nativeLanguage: userProfile?.nativeLanguage || 'vi',
          targetLanguages: userProfile?.targetLanguages || []
        },
        accessToken: idToken,
        refreshToken: refreshToken
      }
    });
  } catch (error) {
    // Map Firebase REST API errors
    if (error.response && error.response.data && error.response.data.error) {
      const fbError = error.response.data.error;
      const errorMap = {
        'EMAIL_NOT_FOUND': 'Invalid email or password',
        'INVALID_PASSWORD': 'Invalid email or password',
        'USER_DISABLED': 'Account is disabled. Please contact support.',
        'INVALID_LOGIN_CREDENTIALS': 'Invalid email or password',
      };
      const message = errorMap[fbError.message] || fbError.message || 'Authentication failed';
      return res.status(401).json({ success: false, message });
    }
    next(error);
  }
};

/**
 * Register new user via Firebase Auth Admin SDK
 */
exports.register = async (req, res, next) => {
  try {
    const { email, password, role = 'user', nativeLanguage, targetLanguages } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Email and password are required'
      });
    }

    if (password.length < 6) {
      return res.status(400).json({
        success: false,
        message: 'Password must be at least 6 characters long'
      });
    }

    // Create user in Firebase Auth
    let userRecord;
    try {
      userRecord = await admin.auth().createUser({
        email,
        password,
        emailVerified: false
      });
    } catch (fbErr) {
      if (fbErr.code === 'auth/email-already-exists') {
        return res.status(409).json({
          success: false,
          message: 'User with this email already exists'
        });
      }
      throw fbErr;
    }

    // Set custom claims for role
    const assignedRole = role === 'admin' ? 'admin' : 'user';
    await admin.auth().setCustomUserClaims(userRecord.uid, { role: assignedRole });

    // Create user profile in Firestore
    const userProfile = {
      email,
      role: assignedRole,
      nativeLanguage: nativeLanguage || 'vi',
      targetLanguages: targetLanguages || [],
      isActive: true,
      createdAt: new Date().toISOString(),
      lastActiveAt: new Date().toISOString()
    };

    if (db) {
      await db.collection('users').doc(userRecord.uid).set(userProfile);
    }

    // Sign in to get tokens
    let accessToken = '';
    let refreshToken = '';
    if (FIREBASE_WEB_API_KEY) {
      try {
        const signInResp = await axios.post(
          `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${FIREBASE_WEB_API_KEY}`,
          { email, password, returnSecureToken: true }
        );
        accessToken = signInResp.data.idToken;
        refreshToken = signInResp.data.refreshToken;
      } catch (e) {
        // Generate a custom token as fallback
        accessToken = await admin.auth().createCustomToken(userRecord.uid);
      }
    }

    res.status(201).json({
      success: true,
      message: 'Registration successful',
      data: {
        user: {
          id: userRecord.uid,
          email: email,
          role: assignedRole,
          nativeLanguage: userProfile.nativeLanguage,
          targetLanguages: userProfile.targetLanguages
        },
        accessToken,
        refreshToken
      }
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Refresh access token via Firebase Secure Token API
 */
exports.refresh = async (req, res, next) => {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      return res.status(400).json({
        success: false,
        message: 'Refresh token is required'
      });
    }

    if (!FIREBASE_WEB_API_KEY) {
      return res.status(500).json({
        success: false,
        message: 'FIREBASE_WEB_API_KEY is not configured on the server.'
      });
    }

    const response = await axios.post(
      `https://securetoken.googleapis.com/v1/token?key=${FIREBASE_WEB_API_KEY}`,
      {
        grant_type: 'refresh_token',
        refresh_token: refreshToken
      }
    );

    res.json({
      success: true,
      message: 'Token refreshed successfully',
      data: {
        accessToken: response.data.id_token,
        refreshToken: response.data.refresh_token,
        expiresIn: response.data.expires_in
      }
    });
  } catch (error) {
    if (error.response && error.response.data) {
      return res.status(401).json({
        success: false,
        message: 'Invalid refresh token'
      });
    }
    next(error);
  }
};

/**
 * Logout user
 */
exports.logout = async (req, res, next) => {
  try {
    // Revoke refresh tokens on the server side
    if (req.user && req.user.id) {
      try {
        await admin.auth().revokeRefreshTokens(req.user.id);
      } catch (e) {
        // Ignore revocation errors
      }
    }

    res.json({
      success: true,
      message: 'Logged out successfully'
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Get current user profile
 */
exports.me = async (req, res, next) => {
  try {
    const userId = req.user.id;

    let userProfile = {
      id: userId,
      email: req.user.email || '',
      role: req.user.role || 'user'
    };

    // Fetch full profile from Firestore
    if (db) {
      const userDoc = await db.collection('users').doc(userId).get();
      if (userDoc.exists) {
        const data = userDoc.data();
        userProfile = {
          id: userId,
          email: data.email || req.user.email || '',
          role: data.role || req.user.role || 'user',
          nativeLanguage: data.nativeLanguage || 'vi',
          targetLanguages: data.targetLanguages || [],
          createdAt: data.createdAt,
          lastActiveAt: data.lastActiveAt
        };
      }
    }

    res.json({
      success: true,
      data: userProfile
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Update user profile
 */
exports.updateProfile = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { nativeLanguage, targetLanguages } = req.body;

    const updateData = {};
    if (nativeLanguage) updateData.nativeLanguage = nativeLanguage;
    if (targetLanguages) updateData.targetLanguages = targetLanguages;
    updateData.lastActiveAt = new Date().toISOString();

    if (db) {
      await db.collection('users').doc(userId).update(updateData);
    }

    // Return updated profile
    let updatedProfile = { id: userId, ...updateData };
    if (db) {
      const userDoc = await db.collection('users').doc(userId).get();
      if (userDoc.exists) {
        updatedProfile = { id: userId, ...userDoc.data() };
      }
    }

    res.json({
      success: true,
      message: 'Profile updated successfully',
      data: updatedProfile
    });
  } catch (error) {
    next(error);
  }
};
