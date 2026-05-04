const { sequelize } = require('../config/database');
const User = require('./User');
const Lesson = require('./Lesson');
const LessonVersion = require('./LessonVersion');
const Vocabulary = require('./Vocabulary');
const Exercise = require('./Exercise');

// Define associations
Lesson.hasMany(LessonVersion, {
  foreignKey: 'lessonId',
  as: 'versions'
});

LessonVersion.belongsTo(Lesson, {
  foreignKey: 'lessonId',
  as: 'lesson'
});

// Vocabulary and Exercise associations
Vocabulary.hasMany(Exercise, {
  foreignKey: 'vocabularyId',
  as: 'exercises'
});

Exercise.belongsTo(Vocabulary, {
  foreignKey: 'vocabularyId',
  as: 'vocabulary'
});

// Sync database (create tables if they don't exist)
const syncDatabase = async (force = false) => {
  try {
    await sequelize.sync({ force });
    console.log('✅ Database synchronized successfully.');
  } catch (error) {
    console.error('❌ Error synchronizing database:', error.message);
    throw error;
  }
};

module.exports = {
  sequelize,
  User,
  Lesson,
  LessonVersion,
  Vocabulary,
  Exercise,
  syncDatabase
};
