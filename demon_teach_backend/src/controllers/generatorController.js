const LessonService = require('../services/LessonService');
const AiService = require('../services/AiService');

const generateLesson = async (req, res, next) => {
  try {
    const { topic, language, difficulty, category, id, assessmentScore, goalType, dailyStudyMinutes } = req.body;
    const adminId = req.user?.id || null; // Assume admin ID from auth if available

    if (!topic || !language) {
      return res.status(400).json({ success: false, message: 'Topic and language are required' });
    }

    const lesson = await LessonService.generateAiLesson(
      topic,
      language,
      difficulty,
      category,
      adminId,
      id,
      assessmentScore,
      goalType,
      dailyStudyMinutes
    );

    res.status(201).json({
      success: true,
      message: 'Lesson generated successfully by AI',
      data: lesson
    });
  } catch (error) {
    next(error);
  }
};

const evaluateSpeech = async (req, res, next) => {
  try {
    const { audio, phrase, language } = req.body;

    if (!audio || !phrase || !language) {
      return res.status(400).json({ success: false, message: 'Audio (base64), phrase, and language are required' });
    }

    const evaluation = await AiService.evaluateSpeech(audio, phrase, language);

    res.status(200).json({
      success: true,
      message: 'Speech evaluated successfully',
      data: evaluation
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  generateLesson,
  evaluateSpeech
};
