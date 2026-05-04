const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const Vocabulary = sequelize.define('Vocabulary', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true
  },
  word: {
    type: DataTypes.STRING,
    allowNull: false,
    comment: 'The actual word or character'
  },
  language: {
    type: DataTypes.ENUM('en', 'zh', 'ko'),
    allowNull: false,
    comment: 'Language code'
  },
  level: {
    type: DataTypes.STRING,
    comment: 'Level tag (e.g., HSK1, TOPIK1, A1, B2)'
  },
  phonetic: {
    type: DataTypes.STRING,
    comment: 'Phonetic transcription (Pinyin for ZH, IPA for EN, Romanization for KO)'
  },
  details: {
    type: DataTypes.JSONB,
    defaultValue: {},
    comment: 'Language-specific details (radical, strokes, hanja, etc.)'
  },
  meanings: {
    type: DataTypes.JSONB,
    allowNull: false,
    defaultValue: [],
    comment: 'List of meanings: [{ definition, partOfSpeech, example, translation }]'
  },
  source: {
    type: DataTypes.STRING,
    defaultValue: 'manual',
    comment: 'Source of the data (hsk_json, dictionary_api, ai_generated, etc.)'
  }
}, {
  tableName: 'vocabularies',
  timestamps: true,
  indexes: [
    { fields: ['word', 'language'], unique: true },
    { fields: ['language', 'level'] },
    { fields: ['source'] }
  ]
});

module.exports = Vocabulary;
