const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const Lesson = sequelize.define('Lesson', {
  id: {
    type: DataTypes.STRING,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true
  },
  title: {
    type: DataTypes.STRING,
    allowNull: false
  },
  difficulty: {
    type: DataTypes.ENUM('basic', 'intermediate', 'advanced'),
    allowNull: false,
    defaultValue: 'basic'
  },
  topic: {
    type: DataTypes.STRING,
    allowNull: false
  },
  targetLanguage: {
    type: DataTypes.ENUM('en', 'zh', 'ko'),
    allowNull: false
  },
  durationEstimate: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 10,
    comment: 'Estimated duration in minutes'
  },
  version: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 1
  },
  content: {
    type: DataTypes.JSONB,
    allowNull: false,
    comment: 'Lesson content including flashcards, quiz, listening, speaking exercises'
  },
  isPublished: {
    type: DataTypes.BOOLEAN,
    allowNull: false,
    defaultValue: false
  },
  publishedAt: {
    type: DataTypes.DATE,
    allowNull: true
  },
  createdBy: {
    type: DataTypes.UUID,
    allowNull: true,
    comment: 'Admin user ID who created this lesson'
  },
  updatedBy: {
    type: DataTypes.UUID,
    allowNull: true,
    comment: 'Admin user ID who last updated this lesson'
  }
}, {
  tableName: 'lessons',
  timestamps: true,
  indexes: [
    {
      fields: ['targetLanguage', 'difficulty']
    },
    {
      fields: ['topic']
    },
    {
      fields: ['isPublished']
    }
  ]
});

module.exports = Lesson;
