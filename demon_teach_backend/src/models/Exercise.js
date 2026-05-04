const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const Exercise = sequelize.define('Exercise', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true
  },
  type: {
    type: DataTypes.ENUM('multipleChoice', 'fillInBlank', 'matching', 'speaking', 'listening'),
    allowNull: false
  },
  difficulty: {
    type: DataTypes.ENUM('basic', 'intermediate', 'advanced'),
    allowNull: false,
    defaultValue: 'basic'
  },
  content: {
    type: DataTypes.JSONB,
    allowNull: false,
    comment: 'Question text, options, correct answer, explanation'
  },
  targetLanguage: {
    type: DataTypes.ENUM('en', 'zh', 'ko'),
    allowNull: false
  },
  vocabularyId: {
    type: DataTypes.UUID,
    allowNull: true,
    comment: 'Link to a specific vocabulary word if applicable'
  },
  source: {
    type: DataTypes.STRING,
    defaultValue: 'ai_generated'
  }
}, {
  tableName: 'exercises',
  timestamps: true,
  indexes: [
    { fields: ['targetLanguage', 'type'] },
    { fields: ['vocabularyId'] }
  ]
});

module.exports = Exercise;
