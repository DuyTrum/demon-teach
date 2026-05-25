const { Lesson, Vocabulary, Exercise } = require('../models');
const AiService = require('./AiService');
const VocabularyService = require('./VocabularyService');
const TtsService = require('./TtsService');

class LessonService {
  /**
   * Generates a complete AI lesson based on a topic and language
   */
  async generateAiLesson(topic, language, difficulty = 'basic', adminId, customId, assessmentScore, goalType, dailyStudyMinutes) {
    try {
      if (customId) {
        const existingLesson = await Lesson.findByPk(customId);
        if (existingLesson) {
          console.log(`ℹ️ Lesson ${customId} already exists in the database. Updating isPublished to true.`);
          existingLesson.isPublished = true;
          existingLesson.publishedAt = existingLesson.publishedAt || new Date();
          await existingLesson.save();
          return existingLesson;
        }
      }

      console.log(`🎬 Generating ${difficulty} lesson for ${language} on topic: ${topic} (Score: ${assessmentScore}%, Goal: ${goalType}, Mins: ${dailyStudyMinutes})`);

      let customizationPrompt = '';
      if (assessmentScore !== undefined && assessmentScore !== null) {
        customizationPrompt = `The student's assessment test score is ${assessmentScore}%. `;
        if (assessmentScore < 50) {
          customizationPrompt += `Since the student scored low (${assessmentScore}%), make the vocabulary and exercises extremely simple and easy, focusing on absolute fundamentals. `;
        } else if (assessmentScore > 80) {
          customizationPrompt += `Since the student scored high (${assessmentScore}%), make the vocabulary more challenging and the exercises more advanced to push their limits. `;
        } else {
          customizationPrompt += `Since the student scored moderately (${assessmentScore}%), maintain a standard, balanced level of difficulty. `;
        }
      }

      if (goalType) {
        customizationPrompt += `The user's learning goal/purpose is: ${goalType}. `;
        if (goalType === 'conversation') {
          customizationPrompt += `Focus on spoken communication, realistic dialogue phrases, and listening comprehension in daily settings. `;
        } else if (goalType === 'travel') {
          customizationPrompt += `Focus on practical travel situations, asking directions, ordering food, checking in, and key tourist phrases. `;
        } else if (goalType === 'work') {
          customizationPrompt += `Focus on formal business vocabulary, workplace discussions, professional terminology, and career situations. `;
        } else if (goalType === 'exam') {
          customizationPrompt += `Focus on advanced/rigorous grammar, precise vocabulary, and formal expressions appropriate for language proficiency tests. `;
        } else if (goalType === 'hobby') {
          customizationPrompt += `Focus on interesting cultural context, idiomatic/slang expressions, and casual, engaging daily topics. `;
        }
      }

      let wordCount = 5;
      if (dailyStudyMinutes !== undefined && dailyStudyMinutes !== null) {
        const minutes = parseInt(dailyStudyMinutes);
        if (minutes <= 10) {
          wordCount = 3;
        } else if (minutes <= 20) {
          wordCount = 5;
        } else {
          wordCount = 8;
        }
      }

      // 1. Get relevant words for this topic using AI
      const prompt = `Give me a list of ${wordCount} essential ${language} words/phrases for the topic "${topic}" at ${difficulty} level. ${customizationPrompt}
      CRITICAL INSTRUCTIONS:
      - The words/phrases MUST be directly relevant to the specific topic "${topic}".
      - Do NOT output generic, repetitive introductory words (like "hello", "hi", "my name is", "goodbye") unless the topic is specifically about greetings.
      - Ensure the words/phrases are unique and specific to this lesson's topic.
      Return ONLY a JSON array of strings: ["word1", "word2", ...]`;
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
          const exercises = await AiService.generateExercises(vocab, 1, goalType);
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
        },
        sections: [
          {
            type: 'vocabulary',
            items: flashcards.map(fc => ({
              word: fc.frontText,
              translation: fc.backText,
              pronunciation: fc.phonetic || '',
              audioUrl: fc.audioUrl
            }))
          },
          {
            type: 'practice',
            exercises: allExercises.map(ex => ({
              question: ex.content.questionText,
              options: ex.content.options || [],
              correctAnswer: ex.content.correctAnswer
            }))
          }
        ]
      };

      const lesson = await Lesson.create({
        id: customId || undefined,
        title: `Topic: ${topic} (${language.toUpperCase()})`,
        difficulty,
        topic,
        targetLanguage: language,
        durationEstimate: dailyStudyMinutes ? parseInt(dailyStudyMinutes) : 10,
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
