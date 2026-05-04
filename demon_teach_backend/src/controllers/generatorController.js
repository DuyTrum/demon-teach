const LessonService = require('../services/LessonService');

const generateLesson = async (req, res, next) => {
  try {
    const { topic, language, difficulty } = req.body;
    const adminId = req.user?.id || null; // Assume admin ID from auth if available

    if (!topic || !language) {
      return res.status(400).json({ success: false, message: 'Topic and language are required' });
    }

    const lesson = await LessonService.generateAiLesson(topic, language, difficulty, adminId);

    res.status(201).json({
      success: true,
      message: 'Lesson generated successfully by AI',
      data: lesson
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  generateLesson
};
