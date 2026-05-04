const { Lesson } = require('../models');
const { sequelize } = require('../config/database');
const { Op } = require('sequelize');

/**
 * Content Controller
 * Handles content delivery for mobile app
 */

// Check for content updates
exports.checkUpdates = async (req, res, next) => {
  try {
    const { language, lastSync } = req.query;

    if (!language) {
      return res.status(400).json({
        success: false,
        message: 'Language parameter is required'
      });
    }

    const where = {
      targetLanguage: language,
      isPublished: true
    };

    // If lastSync provided, only get lessons updated after that time
    if (lastSync) {
      where.updatedAt = {
        [Op.gt]: new Date(lastSync)
      };
    }

    const updatedLessons = await Lesson.findAll({
      where,
      attributes: ['id', 'version', 'updatedAt'],
      order: [['updatedAt', 'DESC']]
    });

    res.json({
      success: true,
      data: {
        hasUpdates: updatedLessons.length > 0,
        updatedLessons,
        serverTime: new Date().toISOString()
      }
    });
  } catch (error) {
    next(error);
  }
};

// Get lessons (with optional filters)
exports.getLessons = async (req, res, next) => {
  try {
    const { language, nativeLanguage, since, difficulty, topic, limit = 50 } = req.query;

    if (!language) {
      return res.status(400).json({
        success: false,
        message: 'Language parameter is required'
      });
    }

    const where = {
      targetLanguage: language,
      isPublished: true
    };

    if (nativeLanguage) {
      where.nativeLanguage = nativeLanguage;
    }

    // Filter by update time
    if (since) {
      where.updatedAt = {
        [Op.gt]: new Date(since)
      };
    }

    // Filter by difficulty
    if (difficulty) {
      where.difficulty = difficulty;
    }

    // Filter by topic
    if (topic) {
      where.topic = {
        [Op.iLike]: `%${topic}%`
      };
    }

    const lessons = await Lesson.findAll({
      where,
      limit: parseInt(limit),
      order: [['updatedAt', 'DESC']]
    });

    res.json({
      success: true,
      data: {
        lessons,
        count: lessons.length
      }
    });
  } catch (error) {
    next(error);
  }
};

// Get single lesson by ID
exports.getLessonById = async (req, res, next) => {
  try {
    const { lessonId } = req.params;

    const lesson = await Lesson.findOne({
      where: {
        id: lessonId,
        isPublished: true
      }
    });

    if (!lesson) {
      return res.status(404).json({
        success: false,
        message: 'Lesson not found or not published'
      });
    }

    res.json({
      success: true,
      data: lesson
    });
  } catch (error) {
    next(error);
  }
};

// Get lessons by difficulty and language (for learning path generation)
exports.getLessonsByDifficulty = async (req, res, next) => {
  try {
    const { language, difficulty, limit = 20 } = req.query;

    if (!language || !difficulty) {
      return res.status(400).json({
        success: false,
        message: 'Language and difficulty parameters are required'
      });
    }

    const lessons = await Lesson.findAll({
      where: {
        targetLanguage: language,
        difficulty,
        isPublished: true
      },
      limit: parseInt(limit),
      order: [['createdAt', 'ASC']],
      attributes: ['id', 'title', 'difficulty', 'topic', 'targetLanguage', 'durationEstimate', 'version']
    });

    res.json({
      success: true,
      data: {
        lessons,
        count: lessons.length
      }
    });
  } catch (error) {
    next(error);
  }
};

// Get random lessons for download (offline mode)
exports.getRandomLessons = async (req, res, next) => {
  try {
    const { language, difficulty, count = 3 } = req.query;

    if (!language) {
      return res.status(400).json({
        success: false,
        message: 'Language parameter is required'
      });
    }

    const where = {
      targetLanguage: language,
      isPublished: true
    };

    if (difficulty) {
      where.difficulty = difficulty;
    }

    // Get random lessons using ORDER BY RANDOM()
    const lessons = await Lesson.findAll({
      where,
      limit: parseInt(count),
      order: sequelize.random(),
      attributes: ['id', 'title', 'difficulty', 'topic', 'targetLanguage', 'durationEstimate', 'version', 'content']
    });

    res.json({
      success: true,
      data: {
        lessons,
        count: lessons.length
      }
    });
  } catch (error) {
    next(error);
  }
};

module.exports = exports;
