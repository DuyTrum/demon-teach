const { Vocabulary, Exercise } = require('../models');
const VocabularyService = require('../services/VocabularyService');
const AiService = require('../services/AiService');

const expandWord = async (req, res, next) => {
  try {
    const { word, language } = req.body;

    if (!word || !language) {
      return res.status(400).json({ success: false, message: 'Word and language are required' });
    }

    let vocab;
    if (language === 'en') {
      vocab = await VocabularyService.fetchEnglishWord(word);
    } else {
      // For ZH/KO, we could implement specialized scrapers or AI-first approach
      return res.status(400).json({ success: false, message: 'Only English is currently supported for auto-fetch' });
    }

    // Generate an exercise automatically if API key exists
    const exercise = await AiService.generateExercise(vocab);

    res.status(201).json({
      success: true,
      data: {
        vocabulary: vocab,
        exercise: exercise
      }
    });
  } catch (error) {
    next(error);
  }
};

const getVocabList = async (req, res, next) => {
  try {
    const { language, level } = req.query;
    const where = {};
    if (language) where.language = language;
    if (level) where.level = level;

    const list = await Vocabulary.findAll({
      where,
      include: [{ model: Exercise, as: 'exercises' }]
    });

    res.json({ success: true, data: list });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  expandWord,
  getVocabList
};
