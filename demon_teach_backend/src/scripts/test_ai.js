const axios = require('axios');
require('dotenv').config();

const testAiConnection = async () => {
  const apiKey = process.env.GROQ_API_KEY;
  console.log('🤖 Testing AI Connection with Groq...');
  
  if (!apiKey) {
    console.error('❌ GROQ_API_KEY not found in .env');
    return;
  }

  const prompt = "Say 'Hello, Demon Teach is ready!' in English, Chinese, and Korean.";

  try {
    const response = await axios.post('https://api.groq.com/openai/v1/chat/completions', {
      model: 'llama-3.3-70b-versatile',
      messages: [{ role: 'user', content: prompt }]
    }, {
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json'
      }
    });

    console.log('✅ AI Response:', response.data.choices[0].message.content);
  } catch (error) {
    console.error('❌ AI Test failed:', error.response ? error.response.data : error.message);
  }
};

testAiConnection();
