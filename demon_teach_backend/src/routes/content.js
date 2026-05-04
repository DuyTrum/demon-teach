const express = require('express');
const router = express.Router();
const contentController = require('../controllers/contentController');
const { authenticate } = require('../middleware/auth');

/**
 * Content Routes (Mobile App)
 * Base path: /api/content
 */

// All content routes require authentication
router.use(authenticate);

// GET /api/content/check-updates - Check for content updates
router.get('/check-updates', contentController.checkUpdates);

// GET /api/content/lessons - Get lessons with filters
router.get('/lessons', contentController.getLessons);

// GET /api/content/lessons/:lessonId - Get single lesson
router.get('/lessons/:lessonId', contentController.getLessonById);

// GET /api/content/lessons-by-difficulty - Get lessons by difficulty
router.get('/lessons-by-difficulty', contentController.getLessonsByDifficulty);

// GET /api/content/random-lessons - Get random lessons for offline download
router.get('/random-lessons', contentController.getRandomLessons);

module.exports = router;
