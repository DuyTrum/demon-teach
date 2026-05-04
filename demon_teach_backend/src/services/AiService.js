const axios = require('axios');
const { Exercise } = require('../models');

class AiService {
  constructor() {
    this.apiKey = process.env.GROQ_API_KEY || '';
    this.apiUrl = 'https://api.groq.com/openai/v1/chat/completions';
    this.model = 'llama-3.3-70b-versatile';
  }

  /**
   * Generates comprehensive word details for any language
   */
  async fetchWordDetails(word, language) {
    if (!this.apiKey) return null;

    const langName = language === 'zh' ? 'Chinese' : language === 'ko' ? 'Korean' : 'English';
    
    const prompt = `
      As a professional language teacher, provide detailed information for the ${langName} word: "${word}".
      
      Return ONLY a JSON object in this format:
      {
        "phonetic": "...", // Pinyin for ZH, Romanization for KO, IPA for EN
        "details": {
          "traditional": "...", // For ZH only
          "hanja": "...", // For KO only
          "radical": "...", // For ZH only
          "hanyu_viet": "..." // Sino-Vietnamese reading (Hán Việt/Hán Hàn)
        },
        "meanings": [
          {
            "partOfSpeech": "...",
            "definition": "...", // In Vietnamese
            "example": "...", // In target language
            "example_translation": "..." // In Vietnamese
          }
        ]
      }
    `;

    try {
      const response = await this._callAi(prompt);
      return JSON.parse(response);
    } catch (error) {
      console.error('Error fetching word details via AI:', error.message);
      return null;
    }
  }

  /**
   * Generates multiple exercises for a specific vocabulary word
   */
  async generateExercises(vocabulary, count = 2) {
    if (!this.apiKey) return [];

    const prompt = `
      Create ${count} different exercises for the ${vocabulary.language} word "${vocabulary.word}".
      Word meaning: ${JSON.stringify(vocabulary.meanings[0])}
      
      Return ONLY a JSON array of objects:
      [
        {
          "type": "multipleChoice", // or "fillInBlank"
          "content": {
            "questionText": "...",
            "options": ["...", "...", "...", "..."], // If multipleChoice
            "correctAnswer": "...",
            "explanation": "..."
          }
        }
      ]
    `;

    try {
      const response = await this._callAi(prompt);
      const data = JSON.parse(response);
      const exercisesData = Array.isArray(data) ? data : (data.exercises || data.result || Object.values(data)[0]);
      
      if (!Array.isArray(exercisesData)) return [];

      const createdExercises = await Promise.all(exercisesData.map(async (ex) => {
        return await Exercise.create({
          type: ex.type,
          targetLanguage: vocabulary.language,
          content: ex.content,
          vocabularyId: vocabulary.id,
          source: 'ai_generated'
        });
      }));

      return createdExercises;
    } catch (error) {
      console.error('Error generating exercises via AI:', error.message);
      return [];
    }
  }

  /**
   * Internal helper to call Groq
   */
  async _callAi(prompt) {
    const response = await axios.post(this.apiUrl, {
      model: this.model,
      messages: [{ role: 'user', content: prompt }],
      response_format: { type: 'json_object' }
    }, {
      headers: {
        'Authorization': `Bearer ${this.apiKey}`,
        'Content-Type': 'application/json'
      }
    });

    return response.data.choices[0].message.content;
  }
}

module.exports = new AiService();
