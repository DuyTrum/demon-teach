const axios = require('axios');
const { db } = require('../config/firebase');

class VocabularyService {
  /**
   * Fetch word details for English using Free Dictionary API
   * Saves result to Firestore instead of SQLite
   */
  async fetchEnglishWord(word) {
    try {
      const response = await axios.get(`https://api.dictionaryapi.dev/api/v2/entries/en/${word}`);
      const data = response.data[0];

      const meanings = data.meanings.map(m => ({
        partOfSpeech: m.partOfSpeech,
        definition: m.definitions[0].definition,
        example: m.definitions[0].example || '',
        synonyms: m.synonyms || []
      }));

      const vocabData = {
        word: data.word,
        language: 'en',
        phonetic: data.phonetic || '',
        meanings: meanings,
        source: 'dictionary_api',
        createdAt: new Date().toISOString()
      };

      // Save to Firestore
      if (db) {
        const docRef = await db.collection('vocabularies').add(vocabData);
        vocabData.id = docRef.id;
      }

      return vocabData;
    } catch (error) {
      console.error(`Error fetching English word "${word}":`, error.message);
      throw error;
    }
  }

  /**
   * Placeholder for Chinese/Korean fetching (could use AI or specific scrapers)
   */
  async fetchAsianWord(word, lang) {
    console.log(`Need to fetch ${lang} word: ${word}`);
  }
}

module.exports = new VocabularyService();
