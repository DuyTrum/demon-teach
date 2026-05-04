const express = require('express');
const router = express.Router();
const vocabularyController = require('../controllers/vocabularyController');

router.post('/expand', vocabularyController.expandWord);
router.get('/', vocabularyController.getVocabList);

module.exports = router;
