const { admin } = require('../config/firebase');

const authenticate = async (req, res, next) => {
  try {
    // Get token from header
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        message: 'No token provided. Authorization denied.'
      });
    }

    const token = authHeader.substring(7); // Remove 'Bearer ' prefix

    if (!admin) {
      return res.status(500).json({
        success: false,
        message: 'Firebase Admin is not initialized.'
      });
    }

    // Verify Firebase ID Token
    try {
      const decodedToken = await admin.auth().verifyIdToken(token);
      req.user = {
        id: decodedToken.uid,
        email: decodedToken.email || '',
        role: decodedToken.role || 'user'
      };
      next();
    } catch (firebaseError) {
      return res.status(401).json({
        success: false,
        message: 'Invalid or expired token. Authorization denied.'
      });
    }
  } catch (error) {
    console.error('Authentication error:', error.message);
    return res.status(401).json({
      success: false,
      message: 'Authentication failed.'
    });
  }
};

const requireAdmin = (req, res, next) => {
  if (!req.user) {
    return res.status(401).json({
      success: false,
      message: 'Authentication required.'
    });
  }

  // Check role from Firebase custom claims
  if (req.user.role !== 'admin' && req.user.email !== 'admin@demonteach.com') {
    return res.status(403).json({
      success: false,
      message: 'Admin access required. Forbidden.'
    });
  }

  next();
};

module.exports = { authenticate, requireAdmin };
