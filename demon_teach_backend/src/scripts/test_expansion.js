const { Vocabulary, Exercise, syncDatabase } = require('../models');
const VocabularyService = require('../services/VocabularyService');
const AiService = require('../services/AiService');
require('dotenv').config();

const testExpansion = async () => {
  try {
    console.log('🚀 Starting Automatic Expansion Test...');

    // 1. Sync DB to make sure new tables exist
    await syncDatabase(false);

    const testWord = 'persistence';
    const lang = 'en';

    console.log(`🔍 1. Fetching data for "${testWord}" from internet...`);
    const vocab = await VocabularyService.fetchEnglishWord(testWord);
    console.log('✅ Word Data Fetched:', JSON.stringify(vocab.meanings[0], null, 2));

    console.log(`🤖 2. Generating AI exercise for "${testWord}"...`);
    const exercise = await AiService.generateExercise(vocab);
    
    if (exercise) {
      console.log('✅ AI Exercise Generated:');
      console.log(JSON.stringify(exercise.content, null, 2));
    } else {
      console.log('❌ AI Exercise Generation failed (check your API key).');
    }

    console.log('\n✨ Test completed successfully!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Test failed:', error.message);
    process.exit(1);
  }
};

testExpansion();
