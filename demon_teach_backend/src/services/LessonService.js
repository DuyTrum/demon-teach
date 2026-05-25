const { db } = require('../config/firebase');
const AiService = require('./AiService');
const TtsService = require('./TtsService');

class LessonService {
  /**
   * Generates a complete AI lesson based on a topic and language
   */
  async generateAiLesson(topic, language, difficulty = 'beginner', category = 'vocabulary', adminId, customId, assessmentScore, goalType, dailyStudyMinutes) {
    try {
      const lessonId = customId || `lesson_${Date.now()}`;

      if (db) {
        const existingSnap = await db.collection('lessons').doc(lessonId).get();
        if (existingSnap.exists) {
          console.log(`ℹ️ Lesson ${lessonId} already exists in Firestore. Returning existing lesson.`);
          const existingLesson = existingSnap.data();
          return existingLesson;
        }
      }

      console.log(`🎬 Generating ${difficulty} ${category} lesson for ${language} on topic: ${topic} (Score: ${assessmentScore}%, Goal: ${goalType}, Mins: ${dailyStudyMinutes})`);

      let customizationPrompt = '';
      if (assessmentScore !== undefined && assessmentScore !== null) {
        customizationPrompt += `The student's assessment test score is ${assessmentScore}%. `;
        if (assessmentScore < 50) {
          customizationPrompt += `Since the student scored low (${assessmentScore}%), make the content extremely simple and easy, focusing on absolute fundamentals. `;
        } else if (assessmentScore > 80) {
          customizationPrompt += `Since the student scored high (${assessmentScore}%), make the content more challenging to push their limits. `;
        } else {
          customizationPrompt += `Since the student scored moderately (${assessmentScore}%), maintain a standard, balanced level of difficulty. `;
        }
      }

      if (goalType) {
        customizationPrompt += `The user's learning goal is: ${goalType}. `;
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
      
      // Category specific instruction
      if (category === 'grammar') {
        customizationPrompt += `CRITICAL: This is a GRAMMAR lesson. Focus on grammatical structures, verb conjugations, particles, and syntax related to the topic. `;
      } else if (category === 'listening' || category === 'speaking') {
        customizationPrompt += `CRITICAL: This is a ${category.toUpperCase()} lesson. Focus entirely on conversational phrases, common dialogue, and auditory comprehension patterns. `;
      } else if (category === 'reading' || category === 'writing') {
        customizationPrompt += `CRITICAL: This is a ${category.toUpperCase()} lesson. Focus on written text patterns, paragraphs, and formal/informal written vocabulary. `;
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

      // 1. Get relevant words/phrases for this topic using AI
      const prompt = `Give me a list of ${wordCount} essential ${language} words/phrases/grammar-points for the topic "${topic}" at ${difficulty} level. ${customizationPrompt}
      CRITICAL INSTRUCTIONS:
      - The items MUST be directly relevant to the specific topic "${topic}".
      - Do NOT output generic, repetitive introductory words (like "hello", "hi") unless the topic is specifically about greetings.
      - Ensure the items are unique and specific to this lesson's topic.
      Return ONLY a JSON array of strings: ["item1", "item2", ...]`;
      const wordsRaw = await AiService._callAi(prompt);
      const wordsData = JSON.parse(wordsRaw);
      
      const words = Array.isArray(wordsData) ? wordsData : (wordsData.words || wordsData.result || Object.values(wordsData)[0]);

      if (!Array.isArray(words)) {
        throw new Error('AI failed to return a valid word list');
      }

      const flashcards = [];
      const allExercises = [];

      // 2. Process each word
      for (const wordText of words) {
        let vocab = null;

        if (db) {
          try {
            const vocabSnap = await db.collection('vocabularies')
              .where('word', '==', wordText)
              .where('language', '==', language)
              .limit(1)
              .get();
            if (!vocabSnap.empty) {
              vocab = vocabSnap.docs[0].data();
              vocab.id = vocabSnap.docs[0].id;
            }
          } catch (dbErr) {
            console.error('Error fetching vocabulary from Firestore:', dbErr.message);
          }
        }
        
        if (!vocab) {
          const details = await AiService.fetchWordDetails(wordText, language);
          if (details) {
            const newVocabId = `vocab_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
            vocab = {
              id: newVocabId,
              word: wordText,
              language,
              phonetic: details.phonetic,
              details: details.details,
              meanings: details.meanings,
              source: 'ai_discovery',
              level: difficulty,
              createdAt: new Date().toISOString()
            };
            if (db) {
              try {
                await db.collection('vocabularies').doc(newVocabId).set(vocab);
              } catch (dbErr) {
                console.error('Error saving new vocabulary to Firestore:', dbErr.message);
              }
            }
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
          try {
            const exercises = await AiService.generateExercises(vocab, 1, goalType);
            allExercises.push(...exercises.map(e => ({
              id: e.id,
              type: e.type,
              content: e.content
            })));
          } catch (exErr) {
            console.error('Error generating exercises:', exErr.message);
          }
        }
      }

      // 2.5 Generate speaking practice sentences for this topic using AI
      let speakingItems = [];
      try {
        const speakingPrompt = `Create 2 conversational speaking/reading sentences/phrases in ${language} for the topic "${topic}" at ${difficulty} level.
        For each phrase, provide its pronunciation (Pinyin for Chinese, Romanization for Korean, IPA/Pronunciation for English) and its Vietnamese translation.
        Return ONLY a JSON array of objects:
        [
          {
            "phrase": "...",
            "pronunciation": "...",
            "translation": "..."
          }
        ]`;
        console.log(`🎤 Generating speaking exercises for topic "${topic}"...`);
        const speakingRaw = await AiService._callAi(speakingPrompt);
        const speakingData = JSON.parse(speakingRaw);
        speakingItems = Array.isArray(speakingData) ? speakingData : (speakingData.phrases || speakingData.result || Object.values(speakingData)[0]);
        if (!Array.isArray(speakingItems)) {
          speakingItems = [];
        }
      } catch (speakError) {
        console.error('Failed to generate speaking exercises:', speakError.message);
      }

      // 2.7 Generate listening dialogue and questions for this topic using AI
      let listeningData = null;
      try {
        const listeningPrompt = `Create a short listening dialogue or passage in ${language} for the topic "${topic}" at ${difficulty} level.
        It must contain:
        1. "dialogueText": A short conversation or statement (in the target language) that the student will listen to.
        2. "translation": A Vietnamese translation of the dialogue/statement.
        3. "questions": A JSON array of 3 multiple-choice comprehension questions about this dialogue/statement.
        For each question, provide:
        - "questionText": The question text.
        - "options": An array of 4 options.
        - "correctAnswer": The correct option exactly as written in options.
        - "explanation": Explanation of the correct answer in Vietnamese.

        Return ONLY a JSON object:
        {
          "dialogueText": "...",
          "translation": "...",
          "questions": [
            {
              "questionText": "...",
              "options": ["...", "...", "...", "..."],
              "correctAnswer": "...",
              "explanation": "..."
            }
          ]
        }`;
        console.log(`🎧 Generating listening exercises for topic "${topic}"...`);
        const listeningRaw = await AiService._callAi(listeningPrompt);
        const parsedListening = JSON.parse(listeningRaw);
        if (parsedListening && parsedListening.dialogueText && Array.isArray(parsedListening.questions)) {
          listeningData = parsedListening;
        }
      } catch (listeningError) {
        console.error('Failed to generate listening scenario:', listeningError.message);
      }

      // 3. Assemble the Lesson
      const lessonContent = {
        flashcards: flashcards,
        quiz: {
          id: `quiz_${Date.now()}`,
          title: `${topic} Quiz`,
          questions: allExercises
        },
        listening: listeningData ? {
          id: `listening_${lessonId}`,
          lessonId: lessonId,
          audioUrl: (() => {
            try { return TtsService.getAudioUrl(listeningData.dialogueText, language); }
            catch (e) { return null; }
          })(),
          durationSeconds: Math.max(15, Math.round(listeningData.dialogueText.length * 0.4 + 5)),
          questions: listeningData.questions.map((q, idx) => ({
            id: `lq_${idx}_${Date.now()}`,
            questionText: q.questionText,
            options: q.options,
            correctAnswer: q.correctAnswer,
            explanation: q.explanation
          }))
        } : null,
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
          },
          {
            type: 'speaking',
            items: speakingItems.map(item => ({
              phrase: item.phrase,
              translation: item.translation,
              pronunciation: item.pronunciation || '',
              audioUrl: (() => {
                try { return TtsService.getAudioUrl(item.phrase, language); }
                catch (e) { return null; }
              })()
            }))
          }
        ]
      };

      const lessonData = {
        id: lessonId,
        title: `Topic: ${topic} (${language.toUpperCase()})`,
        difficulty,
        category,
        topic,
        targetLanguage: language,
        durationEstimate: dailyStudyMinutes ? parseInt(dailyStudyMinutes) : 10,
        content: lessonContent,
        isPublished: true,
        publishedAt: new Date().toISOString(),
        createdBy: adminId || null,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      };

      if (db) {
        console.log(`💾 Saving generated lesson "${lessonId}" directly to Firestore 'lessons' collection...`);
        await db.collection('lessons').doc(lessonId).set(lessonData);
      }

      return lessonData;
    } catch (error) {
      console.error('❌ Error in generateAiLesson:', error.message);
      throw error;
    }
  }
}

module.exports = new LessonService();
