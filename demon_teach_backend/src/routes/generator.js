const express = require('express');
const router = express.Router();
const generatorController = require('../controllers/generatorController');
// const { authenticate, isAdmin } = require('../middleware/auth');

router.post('/lesson', generatorController.generateLesson);
router.post('/evaluate-speech', generatorController.evaluateSpeech);

module.exports = router;
