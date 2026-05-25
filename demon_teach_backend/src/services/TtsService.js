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

      return `/api/tts?text=${encodeURIComponent(text)}&language=${encodeURIComponent(language)}`;
    } catch (error) {
      console.error('Error generating TTS URL:', error.message);
      return null;
    }
  }
}

module.exports = new TtsService();
