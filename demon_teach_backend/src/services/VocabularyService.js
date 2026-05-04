const axios = require('axios');
const { Vocabulary, Exercise } = require('../models');

class VocabularyService {
  /**
   * Fetch word details for English using Free Dictionary API
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

      const vocab = await Vocabulary.create({
        word: data.word,
        language: 'en',
        phonetic: data.phonetic || '',
        meanings: meanings,
        source: 'dictionary_api'
      });

      return vocab;
    } catch (error) {
      console.error(`Error fetching English word "${word}":`, error.message);
      throw error;
    }
  }

  /**
   * Placeholder for Chinese/Korean fetching (could use AI or specific scrapers)
   */
  async fetchAsianWord(word, lang) {
    // This is where we would call an AI service or a specialized scraper
    // For now, it's a stub that the AI service will fill
    console.log(`Need to fetch ${lang} word: ${word}`);
  }
}

module.exports = new VocabularyService();
