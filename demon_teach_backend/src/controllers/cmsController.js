const { db } = require('../config/firebase');
const ContentValidator = require('../validators/contentValidator');

/**
 * CMS Controller
 * Handles content management operations for admin users using Firebase Firestore
 */

// Helper to calculate pagination for Firestore (client-side slicing for simplicity, since Firestore doesn't easily support dynamic offset without cursors if ordering by a specific field combined with multiple filters)
// Note: For a production app with huge data, cursor-based pagination is better. For this admin panel, we'll fetch filtered docs and slice.

// Get all lessons (with pagination and filters)
exports.getAllLessons = async (req, res, next) => {
  try {
    const {
      page = 1,
      limit = 20,
      targetLanguage,
      difficulty,
      topic,
      category,
      isPublished
    } = req.query;

    if (!db) throw new Error('Firestore is not initialized');

    let query = db.collection('lessons');

    // Apply exact match filters
    if (targetLanguage) query = query.where('targetLanguage', '==', targetLanguage);
    if (difficulty) query = query.where('difficulty', '==', difficulty);
    if (category) query = query.where('category', '==', category);
    if (isPublished !== undefined) query = query.where('isPublished', '==', isPublished === 'true');

    // Firestore doesn't support generic substring search (like ILike), so we'll fetch and filter locally for 'topic'
    const snapshot = await query.get();
    
    let lessons = [];
    snapshot.forEach(doc => {
      const data = doc.data();
      // Apply topic filter locally
      if (topic && data.topic && !data.topic.toLowerCase().includes(topic.toLowerCase())) {
        return;
      }
      
      // Exclude heavy content for list view to save bandwidth
      const { content, ...metadata } = data;
      lessons.push({ id: doc.id, ...metadata });
    });

    // Sort by createdAt DESC
    lessons.sort((a, b) => {
      const dateA = new Date(a.createdAt || 0);
      const dateB = new Date(b.createdAt || 0);
      return dateB - dateA;
    });

    const total = lessons.length;
    const startIndex = (page - 1) * limit;
    const paginatedLessons = lessons.slice(startIndex, startIndex + parseInt(limit));

    res.json({
      success: true,
      data: {
        lessons: paginatedLessons,
        pagination: {
          total,
          page: parseInt(page),
          limit: parseInt(limit),
          totalPages: Math.ceil(total / limit)
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
    if (!db) throw new Error('Firestore is not initialized');

    const doc = await db.collection('lessons').doc(lessonId).get();

    if (!doc.exists) {
      return res.status(404).json({
        success: false,
        message: 'Lesson not found'
      });
    }

    res.json({
      success: true,
      data: { id: doc.id, ...doc.data() }
    });
  } catch (error) {
    next(error);
  }
};

// Create new lesson
exports.createLesson = async (req, res, next) => {
  try {
    const { title, difficulty, category, topic, targetLanguage, durationEstimate, content } = req.body;
    if (!db) throw new Error('Firestore is not initialized');

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

    const lessonId = `lesson_${Date.now()}`;
    const now = new Date().toISOString();

    const lessonData = {
      id: lessonId,
      title,
      difficulty: difficulty || 'beginner',
      category: category || 'vocabulary',
      topic,
      targetLanguage,
      durationEstimate: durationEstimate || 10,
      content,
      version: 1,
      isPublished: false,
      createdBy: req.user ? req.user.id : null,
      updatedBy: req.user ? req.user.id : null,
      createdAt: now,
      updatedAt: now
    };

    await db.collection('lessons').doc(lessonId).set(lessonData);

    // Save version history in a subcollection
    await db.collection('lessons').doc(lessonId).collection('versions').doc('v1').set({
      version: 1,
      title,
      difficulty,
      category,
      topic,
      targetLanguage,
      durationEstimate,
      content,
      changeDescription: 'Initial version',
      createdBy: req.user ? req.user.id : null,
      createdAt: now
    });

    res.status(201).json({
      success: true,
      message: 'Lesson created successfully',
      data: lessonData
    });
  } catch (error) {
    next(error);
  }
};

// Update lesson
exports.updateLesson = async (req, res, next) => {
  try {
    const { lessonId } = req.params;
    const { title, difficulty, category, topic, targetLanguage, durationEstimate, content, changeDescription } = req.body;
    if (!db) throw new Error('Firestore is not initialized');

    const docRef = db.collection('lessons').doc(lessonId);
    const doc = await docRef.get();

    if (!doc.exists) {
      return res.status(404).json({
        success: false,
        message: 'Lesson not found'
      });
    }

    const currentLesson = doc.data();

    // Validate metadata if provided
    if (title || difficulty || category || topic || targetLanguage || durationEstimate) {
      const metadataValidation = ContentValidator.validateMetadata({
        title: title || currentLesson.title,
        difficulty: difficulty || currentLesson.difficulty,
        topic: topic || currentLesson.topic,
        targetLanguage: targetLanguage || currentLesson.targetLanguage,
        durationEstimate: durationEstimate || currentLesson.durationEstimate
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

    const newVersion = (currentLesson.version || 1) + 1;
    const now = new Date().toISOString();

    const updateData = {
      ...(title && { title }),
      ...(difficulty && { difficulty }),
      ...(category && { category }),
      ...(topic && { topic }),
      ...(targetLanguage && { targetLanguage }),
      ...(durationEstimate && { durationEstimate }),
      ...(content && { content }),
      version: newVersion,
      updatedBy: req.user ? req.user.id : null,
      isPublished: false, // Unpublish when updated
      updatedAt: now
    };

    await docRef.update(updateData);

    // Save new version history
    const versionData = {
      version: newVersion,
      title: title || currentLesson.title,
      difficulty: difficulty || currentLesson.difficulty,
      category: category || currentLesson.category,
      topic: topic || currentLesson.topic,
      targetLanguage: targetLanguage || currentLesson.targetLanguage,
      durationEstimate: durationEstimate || currentLesson.durationEstimate,
      content: content || currentLesson.content,
      changeDescription: changeDescription || 'Updated lesson',
      createdBy: req.user ? req.user.id : null,
      createdAt: now
    };

    await docRef.collection('versions').doc(`v${newVersion}`).set(versionData);

    res.json({
      success: true,
      message: 'Lesson updated successfully',
      data: { id: lessonId, ...currentLesson, ...updateData }
    });
  } catch (error) {
    next(error);
  }
};

// Delete lesson
exports.deleteLesson = async (req, res, next) => {
  try {
    const { lessonId } = req.params;
    if (!db) throw new Error('Firestore is not initialized');

    const docRef = db.collection('lessons').doc(lessonId);
    const doc = await docRef.get();

    if (!doc.exists) {
      return res.status(404).json({
        success: false,
        message: 'Lesson not found'
      });
    }

    // Firestore doesn't automatically delete subcollections.
    // For this simple CMS, we delete the main document. Versions will be orphaned but won't show up.
    // A cloud function or recursive delete would be ideal in production.
    await docRef.delete();

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
    if (!db) throw new Error('Firestore is not initialized');

    const lessonDoc = await db.collection('lessons').doc(lessonId).get();
    if (!lessonDoc.exists) {
      return res.status(404).json({
        success: false,
        message: 'Lesson not found'
      });
    }

    const versionsSnapshot = await db.collection('lessons').doc(lessonId).collection('versions')
      .orderBy('version', 'desc')
      .get();
      
    const versions = [];
    versionsSnapshot.forEach(doc => {
      const { content, ...metadata } = doc.data(); // Exclude heavy content
      versions.push({ id: doc.id, lessonId, ...metadata });
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
    if (!db) throw new Error('Firestore is not initialized');

    const docRef = db.collection('lessons').doc(lessonId);
    const doc = await docRef.get();

    if (!doc.exists) {
      return res.status(404).json({
        success: false,
        message: 'Lesson not found'
      });
    }

    const lesson = doc.data();

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

    const publishedAt = new Date().toISOString();

    await docRef.update({
      isPublished: true,
      publishedAt
    });

    res.json({
      success: true,
      message: 'Lesson published successfully',
      data: { ...lesson, id: lessonId, isPublished: true, publishedAt }
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
