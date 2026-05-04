const express = require('express');
const router = express.Router();
const cmsController = require('../controllers/cmsController');
const { authenticate, requireAdmin } = require('../middleware/auth');

/**
 * CMS Routes (Admin only)
 * Base path: /api/cms
 */

// All CMS routes require authentication and admin role
router.use(authenticate);
router.use(requireAdmin);

// GET /api/cms/lessons - Get all lessons (with pagination and filters)
router.get('/lessons', cmsController.getAllLessons);

// POST /api/cms/lessons - Create new lesson
router.post('/lessons', cmsController.createLesson);

// GET /api/cms/lessons/:lessonId - Get single lesson
router.get('/lessons/:lessonId', cmsController.getLessonById);

// PUT /api/cms/lessons/:lessonId - Update lesson
router.put('/lessons/:lessonId', cmsController.updateLesson);

// DELETE /api/cms/lessons/:lessonId - Delete lesson
router.delete('/lessons/:lessonId', cmsController.deleteLesson);

// GET /api/cms/lessons/:lessonId/versions - Get lesson versions
router.get('/lessons/:lessonId/versions', cmsController.getLessonVersions);

// POST /api/cms/lessons/:lessonId/publish - Publish lesson
router.post('/lessons/:lessonId/publish', cmsController.publishLesson);

// POST /api/cms/lessons/validate - Validate lesson content
router.post('/lessons/validate', cmsController.validateLesson);

module.exports = router;
