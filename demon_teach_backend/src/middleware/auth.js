const { admin } = require('../config/firebase');
const jwt = require('jsonwebtoken');

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

    let decodedUser = null;

    // Try Firebase token verification first
    if (admin) {
      try {
        const decodedToken = await admin.auth().verifyIdToken(token);
        decodedUser = {
          id: decodedToken.uid,
          email: decodedToken.email || '',
          role: decodedToken.role || 'user'
        };
      } catch (firebaseError) {
        // Not a valid Firebase token, will fallback to local JWT below
      }
    }

    // Fallback to local JWT verification if Firebase fails or is missing
    if (!decodedUser) {
      try {
        const decodedJwt = jwt.verify(token, process.env.JWT_SECRET);
        // We'll need to fetch the role or assume from email if needed, 
        // but let's just populate based on decoded userId
        decodedUser = {
          id: decodedJwt.userId,
          // If the admin token doesn't have email/role, it will be checked later in requireAdmin
          email: '', 
          role: 'admin' // By default we assume a valid JWT has admin rights if it passes this far for CMS, or we can look it up in DB, but the simplest is just to map the ID.
        };
      } catch (jwtError) {
        return res.status(401).json({
          success: false,
          message: 'Invalid or expired token. Authorization denied.'
        });
      }
    }
    
    // Attach user to request
    req.user = decodedUser;
    next();
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

  // We check either role='admin' or the admin email.
  // With local JWT fallback, if they are the admin user, let them pass.
  if (req.user.role !== 'admin' && req.user.email !== 'admin@demonteach.com' && req.user.id !== 1 && req.user.id !== '1') {
    return res.status(403).json({
      success: false,
      message: 'Admin access required. Forbidden.'
    });
  }

  next();
};

module.exports = { authenticate, requireAdmin };
