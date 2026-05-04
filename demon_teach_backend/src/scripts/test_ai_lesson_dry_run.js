const axios = require('axios');
require('dotenv').config();

// Mock objects for dry run
const AiService = require('../services/AiService');

const dryRunMagic = async () => {
  try {
    console.log('✨ --- DEMON TEACH AI MAGIC (DRY RUN) --- ✨');
    console.log('💡 Note: This test does NOT use the database.\n');

    const topic = 'Chinese Street Food';
    const language = 'zh';

    console.log(`🪄 Asking AI to design a lesson about "${topic}"...`);
    console.log('⏳ This may take 5-10 seconds...\n');

    // 1. Get words
    const wordsPrompt = `Give me a list of 3 essential Chinese words for the topic "${topic}". Return ONLY a JSON array of strings.`;
    const wordsResponse = await axios.post('https://api.groq.com/openai/v1/chat/completions', {
      model: 'llama-3.3-70b-versatile',
      messages: [{ role: 'user', content: wordsPrompt }],
      response_format: { type: 'json_object' }
    }, {
      headers: {
        'Authorization': `Bearer ${process.env.GROQ_API_KEY}`,
        'Content-Type': 'application/json'
      }
    });
    
    const wordsData = JSON.parse(wordsResponse.data.choices[0].message.content);
    // Handle if AI wraps the array in an object like { "words": [...] }
    const words = Array.isArray(wordsData) ? wordsData : (wordsData.words || wordsData.result || Object.values(wordsData)[0]);
    
    if (!Array.isArray(words)) {
      throw new Error('AI failed to return a valid list of words.');
    }

    console.log(`✅ AI found ${words.length} words: ${words.join(', ')}\n`);

    // 2. Generate details for the first word as a sample
    console.log(`📝 Generating detailed Flashcard for: "${words[0]}"...`);
    const details = await AiService.fetchWordDetails(words[0], language);
    
    console.log('\n--- FLASHCARD DATA ---');
    console.log(`Word: ${words[0]}`);
    console.log(`Pinyin: ${details.phonetic}`);
    console.log(`Hán Việt: ${details.details.hanyu_viet}`);
    console.log(`Definition: ${details.meanings[0].definition}`);
    console.log(`Example: ${details.meanings[0].example}`);
    console.log(`Translation: ${details.meanings[0].example_translation}`);

    // 3. Generate a Quiz question
    console.log(`\n🧩 Generating a Quiz question for: "${words[0]}"...`);
    const exercisePrompt = `Create a multipleChoice exercise for "${words[0]}" (${details.meanings[0].definition}). Return ONLY JSON: {"questionText": "...", "options": [], "correctAnswer": "...", "explanation": "..."}`;
    const exResponse = await axios.post('https://api.groq.com/openai/v1/chat/completions', {
      model: 'llama-3.3-70b-versatile',
      messages: [{ role: 'user', content: exercisePrompt }],
      response_format: { type: 'json_object' }
    }, {
      headers: {
        'Authorization': `Bearer ${process.env.GROQ_API_KEY}`,
        'Content-Type': 'application/json'
      }
    });
    
    const exercise = JSON.parse(exResponse.data.choices[0].message.content);
    console.log('\n--- QUIZ QUESTION ---');
    console.log(`Q: ${exercise.questionText}`);
    console.log(`Options: ${exercise.options.join(' | ')}`);
    console.log(`Correct: ${exercise.correctAnswer}`);
    console.log(`Why: ${exercise.explanation}`);

    console.log('\n✨ Magic Dry Run complete! This is the quality of content your app will have.');
    process.exit(0);
  } catch (error) {
    console.error('❌ Dry run failed:', error.message);
    if (error.response) console.error(error.response.data);
    process.exit(1);
  }
};

dryRunMagic();
