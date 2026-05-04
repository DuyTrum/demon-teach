const googleTTS = require('google-tts-api');

class TtsService {
  /**
   * Get audio URL for a given text and language
   * @param {string} text 
   * @param {string} language ('en', 'zh', 'ko')
   */
  getAudioUrl(text, language) {
    try {
      // Map app language codes to Google TTS codes
      const langMap = {
        'en': 'en',
        'zh': 'zh-CN',
        'ko': 'ko'
      };

      const url = googleTTS.getAudioUrl(text, {
        lang: langMap[language] || 'en',
        slow: false,
        host: 'https://translate.google.com',
      });

      return url;
    } catch (error) {
      console.error('Error generating TTS URL:', error.message);
      return null;
    }
  }
}

module.exports = new TtsService();
