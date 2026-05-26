const LessonService = require('../services/LessonService');
require('dotenv').config();

const testLessonGeneration = async () => {
  try {
    console.log('✨ Starting AI Lesson Generation Magic...');

    const topic = 'Restaurant & Food';
    const language = 'zh'; // Let's try Chinese!

    console.log(`🪄 Asking AI to create a ${language.toUpperCase()} lesson about "${topic}"...`);
    
    const lesson = await LessonService.generateAiLesson(topic, language, 'basic', null);

    console.log('\n✅ LESSON GENERATED SUCCESSFULLY!');
    console.log('-----------------------------------');
    console.log(`Title: ${lesson.title}`);
    console.log(`Language: ${lesson.targetLanguage}`);
    console.log(`Flashcards count: ${lesson.content.flashcards.length}`);
    console.log(`Quiz questions count: ${lesson.content.quiz.questions.length}`);
    
    console.log('\n--- Sample Flashcard ---');
    console.log(JSON.stringify(lesson.content.flashcards[0], null, 2));

    console.log('\n--- Sample Quiz Question ---');
    console.log(JSON.stringify(lesson.content.quiz.questions[0].content, null, 2));

    console.log('\n✨ Everything is saved in Firestore. Test completed!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Generation failed:', error);
    process.exit(1);
  }
};

testLessonGeneration();
