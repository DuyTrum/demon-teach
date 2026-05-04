const { Lesson, LessonVersion } = require('../models');
const ContentValidator = require('../validators/contentValidator');
const { Op } = require('sequelize');

/**
 * CMS Controller
 * Handles content management operations for admin users
 */

// Get all lessons (with pagination and filters)
exports.getAllLessons = async (req, res, next) => {
  try {
    const {
      page = 1,
      limit = 20,
      targetLanguage,
      difficulty,
      topic,
      isPublished
    } = req.query;

    const offset = (page - 1) * limit;
    const where = {};

    // Apply filters
    if (targetLanguage) where.targetLanguage = targetLanguage;
    if (difficulty) where.difficulty = difficulty;
    if (topic) where.topic = { [Op.iLike]: `%${topic}%` };
    if (isPublished !== undefined) where.isPublished = isPublished === 'true';

    const { count, rows: lessons } = await Lesson.findAndCountAll({
      where,
      limit: parseInt(limit),
      offset: parseInt(offset),
      order: [['createdAt', 'DESC']],
      attributes: {
        exclude: ['content'] // Exclude content for list view
      }
    });

    res.json({
      success: true,
      data: {
        lessons,
        pagination: {
          total: count,
          page: parseInt(page),
          limit: parseInt(limit),
          totalPages: Math.ceil(count / limit)
        }
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

    const lesson = await Lesson.findByPk(lessonId);

    if (!lesson) {
      return res.status(404).json({
        success: false,
        message: 'Lesson not found'
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

// Create new lesson
exports.createLesson = async (req, res, next) => {
  try {
    const { title, difficulty, topic, targetLanguage, durationEstimate, content } = req.body;

    // Validate metadata
    const metadataValidation = ContentValidator.validateMetadata({
      title,
      difficulty,
      topic,
      targetLanguage,
      durationEstimate
    });

    if (!metadataValidation.isValid) {
      return res.status(400).json({
        success: false,
        message: 'Metadata validation failed',
        errors: metadataValidation.errors
      });
    }

    // Validate content
    const contentValidation = ContentValidator.validate(content);

    if (!contentValidation.isValid) {
      return res.status(400).json({
        success: false,
        message: 'Content validation failed',
        errors: contentValidation.errors
      });
    }

    // Create lesson
    const lesson = await Lesson.create({
      title,
      difficulty,
      topic,
      targetLanguage,
      durationEstimate,
      content,
      version: 1,
      isPublished: false,
      createdBy: req.user.id,
      updatedBy: req.user.id
    });

    // Create initial version
    await LessonVersion.create({
      lessonId: lesson.id,
      version: 1,
      title,
      difficulty,
      topic,
      targetLanguage,
      durationEstimate,
      content,
      changeDescription: 'Initial version',
      createdBy: req.user.id
    });

    res.status(201).json({
      success: true,
      message: 'Lesson created successfully',
      data: lesson
    });
  } catch (error) {
    next(error);
  }
};

// Update lesson
exports.updateLesson = async (req, res, next) => {
  try {
    const { lessonId } = req.params;
    const { title, difficulty, topic, targetLanguage, durationEstimate, content, changeDescription } = req.body;

    const lesson = await Lesson.findByPk(lessonId);

    if (!lesson) {
      return res.status(404).json({
        success: false,
        message: 'Lesson not found'
      });
    }

    // Validate metadata if provided
    if (title || difficulty || topic || targetLanguage || durationEstimate) {
      const metadataValidation = ContentValidator.validateMetadata({
        title: title || lesson.title,
        difficulty: difficulty || lesson.difficulty,
        topic: topic || lesson.topic,
        targetLanguage: targetLanguage || lesson.targetLanguage,
        durationEstimate: durationEstimate || lesson.durationEstimate
      });

      if (!metadataValidation.isValid) {
        return res.status(400).json({
          success: false,
          message: 'Metadata validation failed',
          errors: metadataValidation.errors
        });
      }
    }

    // Validate content if provided
    if (content) {
      const contentValidation = ContentValidator.validate(content);

      if (!contentValidation.isValid) {
        return res.status(400).json({
          success: false,
          message: 'Content validation failed',
          errors: contentValidation.errors
        });
      }
    }

    // Increment version
    const newVersion = lesson.version + 1;

    // Update lesson
    await lesson.update({
      ...(title && { title }),
      ...(difficulty && { difficulty }),
      ...(topic && { topic }),
      ...(targetLanguage && { targetLanguage }),
      ...(durationEstimate && { durationEstimate }),
      ...(content && { content }),
      version: newVersion,
      updatedBy: req.user.id,
      isPublished: false // Unpublish when updated
    });

    // Create new version
    await LessonVersion.create({
      lessonId: lesson.id,
      version: newVersion,
      title: lesson.title,
      difficulty: lesson.difficulty,
      topic: lesson.topic,
      targetLanguage: lesson.targetLanguage,
      durationEstimate: lesson.durationEstimate,
      content: lesson.content,
      changeDescription: changeDescription || 'Updated lesson',
      createdBy: req.user.id
    });

    res.json({
      success: true,
      message: 'Lesson updated successfully',
      data: lesson
    });
  } catch (error) {
    next(error);
  }
};

// Delete lesson
exports.deleteLesson = async (req, res, next) => {
  try {
    const { lessonId } = req.params;

    const lesson = await Lesson.findByPk(lessonId);

    if (!lesson) {
      return res.status(404).json({
        success: false,
        message: 'Lesson not found'
      });
    }

    // Delete lesson (cascade will delete versions)
    await lesson.destroy();

    res.json({
      success: true,
      message: 'Lesson deleted successfully'
    });
  } catch (error) {
    next(error);
  }
};

// Get lesson versions
exports.getLessonVersions = async (req, res, next) => {
  try {
    const { lessonId } = req.params;

    const lesson = await Lesson.findByPk(lessonId);

    if (!lesson) {
      return res.status(404).json({
        success: false,
        message: 'Lesson not found'
      });
    }

    const versions = await LessonVersion.findAll({
      where: { lessonId },
      order: [['version', 'DESC']],
      attributes: {
        exclude: ['content'] // Exclude content for list view
      }
    });

    res.json({
      success: true,
      data: versions
    });
  } catch (error) {
    next(error);
  }
};

// Publish lesson
exports.publishLesson = async (req, res, next) => {
  try {
    const { lessonId } = req.params;

    const lesson = await Lesson.findByPk(lessonId);

    if (!lesson) {
      return res.status(404).json({
        success: false,
        message: 'Lesson not found'
      });
    }

    if (lesson.isPublished) {
      return res.status(400).json({
        success: false,
        message: 'Lesson is already published'
      });
    }

    // Validate content before publishing
    const contentValidation = ContentValidator.validate(lesson.content);

    if (!contentValidation.isValid) {
      return res.status(400).json({
        success: false,
        message: 'Cannot publish lesson with invalid content',
        errors: contentValidation.errors
      });
    }

    // Publish lesson
    await lesson.update({
      isPublished: true,
      publishedAt: new Date()
    });

    res.json({
      success: true,
      message: 'Lesson published successfully',
      data: lesson
    });
  } catch (error) {
    next(error);
  }
};

// Validate lesson content
exports.validateLesson = async (req, res, next) => {
  try {
    const { content } = req.body;

    if (!content) {
      return res.status(400).json({
        success: false,
        message: 'Content is required for validation'
      });
    }

    const validation = ContentValidator.validate(content);

    res.json({
      success: true,
      data: {
        isValid: validation.isValid,
        errors: validation.errors
      }
    });
  } catch (error) {
    next(error);
  }
};

module.exports = exports;
