const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const LessonVersion = sequelize.define('LessonVersion', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true
  },
  lessonId: {
    type: DataTypes.UUID,
    allowNull: false,
    references: {
      model: 'lessons',
      key: 'id'
    },
    onDelete: 'CASCADE'
  },
  version: {
    type: DataTypes.INTEGER,
    allowNull: false
  },
  title: {
    type: DataTypes.STRING,
    allowNull: false
  },
  difficulty: {
    type: DataTypes.ENUM('basic', 'intermediate', 'advanced'),
    allowNull: false
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
    allowNull: false
  },
  content: {
    type: DataTypes.JSONB,
    allowNull: false
  },
  changeDescription: {
    type: DataTypes.TEXT,
    allowNull: true,
    comment: 'Description of changes made in this version'
  },
  createdBy: {
    type: DataTypes.UUID,
    allowNull: true
  }
}, {
  tableName: 'lesson_versions',
  timestamps: true,
  updatedAt: false,
  indexes: [
    {
      fields: ['lessonId', 'version'],
      unique: true
    }
  ]
});

module.exports = LessonVersion;
