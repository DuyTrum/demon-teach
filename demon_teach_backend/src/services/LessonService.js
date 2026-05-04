const { Lesson, Vocabulary, Exercise } = require('../models');
const AiService = require('./AiService');
const VocabularyService = require('./VocabularyService');
const TtsService = require('./TtsService');

class LessonService {
  /**
   * Generates a complete AI lesson based on a topic and language
   */
  async generateAiLesson(topic, language, difficulty = 'basic', adminId) {
    try {
      console.log(`🎬 Generating ${difficulty} lesson for ${language} on topic: ${topic}`);

      // 1. Get 5 relevant words for this topic using AI
      const prompt = `Give me a list of 5 essential ${language} words/phrases for the topic "${topic}" at ${difficulty} level. Return ONLY a JSON array of strings: ["word1", "word2", ...]`;
      const wordsRaw = await AiService._callAi(prompt);
      const wordsData = JSON.parse(wordsRaw);
      
      // Nhận diện mảng từ vựng (phòng trường hợp AI trả về { "words": [...] })
      const words = Array.isArray(wordsData) ? wordsData : (wordsData.words || wordsData.result || Object.values(wordsData)[0]);

      if (!Array.isArray(words)) {
        throw new Error('AI failed to return a valid word list');
      }

      const flashcards = [];
      const allExercises = [];

      // 2. Process each word
      for (const wordText of words) {
        // Find or create vocabulary
        let vocab = await Vocabulary.findOne({ where: { word: wordText, language } });
        
        if (!vocab) {
          const details = await AiService.fetchWordDetails(wordText, language);
          if (details) {
            vocab = await Vocabulary.create({
              word: wordText,
              language,
              phonetic: details.phonetic,
              details: details.details,
              meanings: details.meanings,
              source: 'ai_discovery',
              level: difficulty === 'basic' ? 'Level 1' : 'Level 2'
            });
          }
        }

        if (vocab) {
          // Add to flashcards
          flashcards.push({
            id: vocab.id,
            frontText: vocab.word,
            backText: vocab.meanings[0].definition,
            phonetic: vocab.phonetic,
            example: vocab.meanings[0].example,
            example_translation: vocab.meanings[0].example_translation,
            audioUrl: (() => {
              try { return TtsService.getAudioUrl(vocab.word, language); }
              catch (e) { return null; }
            })()
          });

          // Generate exercises for this word
          const exercises = await AiService.generateExercises(vocab, 1);
          allExercises.push(...exercises.map(e => ({
            id: e.id,
            type: e.type,
            content: e.content
          })));
        }
      }
      // 3. Assemble the Lesson
      const lessonContent = {
        flashcards: flashcards,
        quiz: {
          id: `quiz_${Date.now()}`,
          title: `${topic} Quiz`,
          questions: allExercises
        }
      };

      const lesson = await Lesson.create({
        title: `Topic: ${topic} (${language.toUpperCase()})`,
        difficulty,
        topic,
        targetLanguage: language,
        durationEstimate: 10,
        content: lessonContent,
        isPublished: true,
        publishedAt: new Date(),
        createdBy: adminId || null // Đảm bảo không bị lỗi nếu adminId là undefined
      });

      return lesson;
    } catch (error) {
      console.error('❌ Error in generateAiLesson:', error.message);
      throw error;
    }
  }
}

module.exports = new LessonService();
