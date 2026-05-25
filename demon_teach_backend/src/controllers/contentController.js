const { db } = require('../config/firebase');

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

    if (!db) throw new Error('Firestore is not initialized');

    let query = db.collection('lessons')
      .where('targetLanguage', '==', language)
      .where('isPublished', '==', true);

    if (lastSync) {
      query = query.where('updatedAt', '>', new Date(lastSync).toISOString());
    }

    const snapshot = await query.get();

    const updatedLessons = [];
    snapshot.forEach(doc => {
      const data = doc.data();
      updatedLessons.push({
        id: doc.id,
        version: data.version,
        updatedAt: data.updatedAt
      });
    });

    // Sort descending by updatedAt
    updatedLessons.sort((a, b) => new Date(b.updatedAt) - new Date(a.updatedAt));

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
    const { language, since, difficulty, topic, limit = 50 } = req.query;

    if (!language) {
      return res.status(400).json({
        success: false,
        message: 'Language parameter is required'
      });
    }

    if (!db) throw new Error('Firestore is not initialized');

    let query = db.collection('lessons')
      .where('targetLanguage', '==', language)
      .where('isPublished', '==', true);

    if (since) {
      query = query.where('updatedAt', '>', new Date(since).toISOString());
    }

    if (difficulty) {
      query = query.where('difficulty', '==', difficulty);
    }

    const snapshot = await query.get();

    let lessons = [];
    snapshot.forEach(doc => {
      const data = doc.data();
      if (topic && data.topic && !data.topic.toLowerCase().includes(topic.toLowerCase())) {
        return;
      }
      lessons.push({ id: doc.id, ...data });
    });

    lessons.sort((a, b) => new Date(b.updatedAt) - new Date(a.updatedAt));
    lessons = lessons.slice(0, parseInt(limit));

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

    if (!db) throw new Error('Firestore is not initialized');

    const doc = await db.collection('lessons').doc(lessonId).get();

    if (!doc.exists || !doc.data().isPublished) {
      return res.status(404).json({
        success: false,
        message: 'Lesson not found or not published'
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

    if (!db) throw new Error('Firestore is not initialized');

    const snapshot = await db.collection('lessons')
      .where('targetLanguage', '==', language)
      .where('difficulty', '==', difficulty)
      .where('isPublished', '==', true)
      .get();

    let lessons = [];
    snapshot.forEach(doc => {
      const data = doc.data();
      lessons.push({
        id: doc.id,
        title: data.title,
        difficulty: data.difficulty,
        topic: data.topic,
        category: data.category,
        targetLanguage: data.targetLanguage,
        durationEstimate: data.durationEstimate,
        version: data.version,
        createdAt: data.createdAt
      });
    });

    lessons.sort((a, b) => new Date(a.createdAt) - new Date(b.createdAt));
    lessons = lessons.slice(0, parseInt(limit));

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

    if (!db) throw new Error('Firestore is not initialized');

    let query = db.collection('lessons')
      .where('targetLanguage', '==', language)
      .where('isPublished', '==', true);

    if (difficulty) {
      query = query.where('difficulty', '==', difficulty);
    }

    const snapshot = await query.get();

    let lessons = [];
    snapshot.forEach(doc => {
      const data = doc.data();
      lessons.push({
        id: doc.id,
        title: data.title,
        difficulty: data.difficulty,
        topic: data.topic,
        category: data.category,
        targetLanguage: data.targetLanguage,
        durationEstimate: data.durationEstimate,
        version: data.version,
        content: data.content
      });
    });

    // Shuffle and pick
    for (let i = lessons.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [lessons[i], lessons[j]] = [lessons[j], lessons[i]];
    }

    lessons = lessons.slice(0, parseInt(count));

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
