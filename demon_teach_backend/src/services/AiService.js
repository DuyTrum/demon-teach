const axios = require('axios');
const { Exercise, Vocabulary } = require('../models');
const { EdgeTTS } = require('node-edge-tts');
const path = require('path');
const fs = require('fs');

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

  async generateExercises(vocabulary, count = 2, goalType = '') {
    if (!this.apiKey) return [];

    let goalPrompt = '';
    if (goalType) {
      goalPrompt = `The user's learning goal is: ${goalType}. Make the exercise question scenario and sentence context directly relevant to this goal (e.g. use professional/office contexts for 'work', tourist/vacation contexts for 'travel', everyday friendship chats for 'conversation', formal/scholarly concepts for 'exam'). `;
    }

    const prompt = `
      Create exactly ${count} different exercises for the ${vocabulary.language} word "${vocabulary.word}".
      Word meaning: ${JSON.stringify(vocabulary.meanings[0])}
      
      ${goalPrompt}
      CRITICAL RULES:
      - You MUST create exactly 1 exercise of type "multipleChoice" and 1 exercise of type "fillInBlank".
      - For "multipleChoice": provide "options" (array of 4 strings) and "correctAnswer" (must match one option exactly).
      - For "fillInBlank": provide "questionText" as a sentence with a blank (use "______" for the blank), "correctAnswer" as the missing word/phrase, and NO "options" field.
      - All questionTexts and explanations should be in Vietnamese.
      - All correctAnswers and options should be in the target language (${vocabulary.language}).
      
      Return ONLY a JSON array of objects:
      [
        {
          "type": "multipleChoice",
          "content": {
            "questionText": "...",
            "options": ["...", "...", "...", "..."],
            "correctAnswer": "...",
            "explanation": "..."
          }
        },
        {
          "type": "fillInBlank",
          "content": {
            "questionText": "Điền từ thích hợp: '... ______ ...'",
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

      // Ensure the vocabulary exists in the SQLite database first to satisfy the foreign key constraint
      try {
        await Vocabulary.findOrCreate({
          where: { word: vocabulary.word, language: vocabulary.language },
          defaults: {
            id: vocabulary.id,
            word: vocabulary.word,
            language: vocabulary.language,
            level: vocabulary.level || 'basic',
            phonetic: vocabulary.phonetic || '',
            details: vocabulary.details || {},
            meanings: vocabulary.meanings || [],
            source: vocabulary.source || 'ai_discovery'
          }
        });
      } catch (dbErr) {
        console.error('Error ensuring vocabulary in SQLite local DB:', dbErr.message);
        // If findOrCreate failed due to UUID validation of vocabulary.id (e.g. vocab_xxx is not a valid UUID),
        // we generate a valid UUID for it and try inserting again.
        if (dbErr.message.toLowerCase().includes('uuid') || dbErr.message.toLowerCase().includes('validation')) {
          try {
            const crypto = require('crypto');
            const validUuid = crypto.randomUUID();
            vocabulary.id = validUuid; // update in memory so the exercise will use the valid UUID
            
            await Vocabulary.findOrCreate({
              where: { word: vocabulary.word, language: vocabulary.language },
              defaults: {
                id: validUuid,
                word: vocabulary.word,
                language: vocabulary.language,
                level: vocabulary.level || 'basic',
                phonetic: vocabulary.phonetic || '',
                details: vocabulary.details || {},
                meanings: vocabulary.meanings || [],
                source: vocabulary.source || 'ai_discovery'
              }
            });
          } catch (retryErr) {
            console.error('Retry failed ensuring vocabulary in SQLite local DB:', retryErr.message);
          }
        }
      }

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
   * Generate TTS audio from feedback text using Microsoft Edge TTS
   * Uses vi-VN-HoaiMyNeural (female Vietnamese voice) for the demon teacher persona
   */
  async generateFeedbackAudio(feedbackText) {
    try {
      // Strip emoji from text for cleaner TTS output
      const cleanText = feedbackText.replace(/[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F1E0}-\u{1F1FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]/gu, '').trim();
      if (!cleanText) return null;

      const tts = new EdgeTTS({
        voice: 'vi-VN-HoaiMyNeural',
        lang: 'vi-VN',
        outputFormat: 'audio-24khz-48kbitrate-mono-mp3',
        rate: '-5%',
        pitch: '-8Hz',
        volume: 'default',
        timeout: 15000
      });

      const tempDir = path.join(__dirname, '..', 'temp');
      if (!fs.existsSync(tempDir)) {
        fs.mkdirSync(tempDir, { recursive: true });
      }
      const tempFile = path.join(tempDir, `feedback_${Date.now()}.mp3`);

      await tts.ttsPromise(cleanText, tempFile);

      const audioBuffer = fs.readFileSync(tempFile);
      const base64Audio = audioBuffer.toString('base64');

      // Clean up temp file
      try { fs.unlinkSync(tempFile); } catch (_) {}

      console.log(`🔊 Generated TTS feedback audio (${audioBuffer.length} bytes)`);
      return base64Audio;
    } catch (error) {
      console.error('⚠️ TTS audio generation failed:', error.message);
      return null;
    }
  }

  /**
   * Calculates word-level similarity ratio using Levenshtein distance
   */
  _calculateWordSimilarity(expected, actual) {
    const cleanStr = (s) => s.toLowerCase()
      .replace(/[.,\/#!$%\^&\*;:{}=\-_`~()?]/g, "")
      .replace(/\s+/g, " ")
      .trim();
    
    const s1 = cleanStr(expected);
    const s2 = cleanStr(actual);
    if (!s1 || !s2) return 0;
    
    const w1 = s1.split(" ");
    const w2 = s2.split(" ");
    
    // DP array for Levenshtein distance
    const dp = Array(w1.length + 1).fill(null).map(() => Array(w2.length + 1).fill(0));
    for (let i = 0; i <= w1.length; i++) dp[i][0] = i;
    for (let j = 0; j <= w2.length; j++) dp[0][j] = j;
    
    for (let i = 1; i <= w1.length; i++) {
      for (let j = 1; j <= w2.length; j++) {
        if (w1[i - 1] === w2[j - 1]) {
          dp[i][j] = dp[i - 1][j - 1];
        } else {
          dp[i][j] = Math.min(
            dp[i - 1][j] + 1,    // deletion
            dp[i][j - 1] + 1,    // insertion
            dp[i - 1][j - 1] + 1  // substitution
          );
        }
      }
    }
    
    const distance = dp[w1.length][w2.length];
    const maxLength = Math.max(w1.length, w2.length);
    return 1 - (distance / maxLength);
  }

  async evaluateSpeech(audioBase64, expectedPhrase, language) {
    if (!this.apiKey) {
      throw new Error('API key is not configured');
    }

    try {
      // 1. Transcribe the audio using Groq Whisper API
      let buffer;
      if (audioBase64.startsWith('http://') || audioBase64.startsWith('https://')) {
        console.log(`🌐 Fetching audio file from URL: ${audioBase64}...`);
        const downloadResponse = await axios.get(audioBase64, { responseType: 'arraybuffer' });
        buffer = Buffer.from(downloadResponse.data);
      } else {
        buffer = Buffer.from(audioBase64, 'base64');
      }
      // Detect container format and MIME type from the magic bytes of the buffer
      let ext = 'm4a';
      let mimeType = 'audio/m4a';
      if (buffer.length >= 4) {
        const header = buffer.readUInt32BE(0);
        if (header === 0x1A45DFA3) {
          ext = 'webm';
          mimeType = 'audio/webm';
          console.log('📝 Detected WebM audio format from buffer headers.');
        } else if (header === 0x52494646) { // RIFF
          ext = 'wav';
          mimeType = 'audio/wav';
          console.log('📝 Detected WAV audio format from buffer headers.');
        } else if (header === 0x4F676753) { // OggS
          ext = 'ogg';
          mimeType = 'audio/ogg';
          console.log('📝 Detected OGG audio format from buffer headers.');
        } else if (buffer.toString('ascii', 4, 8) === 'ftyp') {
          ext = 'm4a';
          mimeType = 'audio/m4a';
          console.log('📝 Detected M4A/MP4 audio format from buffer headers.');
        } else {
          console.log(`📝 Audio header bytes: ${buffer.slice(0, 4).toString('hex').toUpperCase()}. Defaulting to m4a.`);
        }
      }

      // Instruct Whisper to transcribe literally (phonetic-matching) and NOT auto-correct or fix grammar/spelling.
      const whisperPrompt = `Transcribe the audio literally. Do not correct any grammatical mistakes, wrong words, accents, or mispronunciations. If the speaker stutters, mispronounces a word, or says a phonetically broken word, write down EXACTLY what it sounds like. Do not output clean polished sentences.`;
      
      const blob = new Blob([buffer], { type: mimeType });
      const formData = new FormData();
      formData.append('file', blob, `speech.${ext}`);
      formData.append('model', 'whisper-large-v3');
      formData.append('response_format', 'json');
      formData.append('prompt', whisperPrompt);

      console.log(`🎤 Sending speech recording to Groq Whisper for transcription (Expected: "${expectedPhrase}")...`);
      const transResponse = await axios.post('https://api.groq.com/openai/v1/audio/transcriptions', formData, {
        headers: {
          'Authorization': `Bearer ${this.apiKey}`
        }
      });

      const transcription = transResponse.data.text;
      console.log(`📝 Transcribed text: "${transcription}"`);

      // Calculate exact mathematical similarity
      const mathSimilarity = this._calculateWordSimilarity(expectedPhrase, transcription);
      const mathSimilarityPercent = Math.round(mathSimilarity * 100);
      console.log(`📊 Deterministic Word Match Similarity: ${mathSimilarityPercent}%`);

      // 2. Compare the transcription with the expected phrase using Llama-3
      const gradingPrompt = `
BẮT BUỘC: Ngươi là "Demon Teach" (Giáo Viên Ác Quỷ), một giáo viên quỷ dữ đáng sợ, mỉa mai, cay độc nhưng hài hước đen từ âm phủ, dạy ngôn ngữ cho bọn phàm trần.

So sánh phát âm thực tế của học sinh với câu mục tiêu.

=== THÔNG TIN TOÁN HỌC KHÁCH QUAN ===
- Câu mục tiêu: "${expectedPhrase}"
- Học sinh nói thực tế: "${transcription}"
- Độ tương đồng từ vựng toán học chính xác: ${mathSimilarityPercent}%
- Ngôn ngữ: "${language}"

=== QUY TẮC BẮT BUỘC (KHÔNG ĐƯỢC VI PHẠM) ===
1. PHẢI viết feedback 100% bằng tiếng Việt sạch. TUYỆT ĐỐI KHÔNG dùng ký tự Nga, Trung, Nhật hay bất kỳ ngôn ngữ lạ nào.
2. PHẢI dùng giọng quỷ dữ ma mị trong MỌI câu chữ. KHÔNG ĐƯỢC viết kiểu học thuật nhạt nhẽo.
3. PHẢI xưng "ta" (ngôi thứ nhất) và gọi học sinh là "ngươi" hoặc "kẻ phàm trần".
4. PHẢI dùng ít nhất 2-3 từ ngữ ma quái trong feedback: "linh hồn", "địa ngục", "âm phủ", "quỷ dữ", "móng vuốt", "nấm mồ", "hỏa ngục", "bóng tối", "trừng phạt".
5. Bắt đầu feedback bằng emoji 😈.
6. PHẢI CHẤM ĐIỂM DỰA TRÊN độ tương đồng toán học khách quan (${mathSimilarityPercent}%). 

=== TIÊU CHÍ CHẤM ĐIỂM CHI TIẾT (accuracyScore) ===
- Độ tương đồng ${mathSimilarityPercent}% là thang điểm nền tảng cho "accuracyScore":
  - Nếu ${mathSimilarityPercent}% là 100%, hãy cho điểm khoảng 0.95 đến 1.0 (Khớp hoàn hảo).
  - Nếu ${mathSimilarityPercent}% từ 80% đến 99%, hãy cho điểm khoảng 0.8 đến 0.94 (Lỗi rất nhỏ hoặc thiếu âm đuôi nhẹ).
  - Nếu ${mathSimilarityPercent}% từ 50% đến 79%, hãy cho điểm khoảng 0.5 đến 0.79 (Sai từ rõ ràng hoặc nuốt từ).
  - Nếu ${mathSimilarityPercent}% dưới 50%, hãy trừng trị thật nặng và cho điểm DƯỚI 0.5!
  - TUYỆT ĐỐI KHÔNG cho điểm khống (ví dụ: thực tế nói sai rất nhiều nhưng vẫn cho 0.9 hoặc 1.0) hoặc quá nương tay! Quỷ dữ phải công minh và khắc nghiệt!

=== PHONG CÁCH BẮT BUỘC ===
- Điểm cao (0.9-1.0): Khen ngợi miễn cưỡng kiểu quỷ. VD: "😈 Hừm! Kẻ phàm trần này khiến ta phải nhíu mày ngạc nhiên! Phát âm tạm chấp nhận được, ta sẽ tạm tha linh hồn ngươi lần này!"
- Điểm trung bình (0.5-0.89): Mỉa mai cay độc. VD: "😈 Tiếng rên rỉ từ nấm mồ nghe còn hay hơn giọng ngươi! Nuốt mất âm cuối rồi kìa, đọc lại ngay trước khi ta kéo ngươi xuống địa ngục!"
- Điểm thấp (<0.5): Giận dữ và hài hước đen. VD: "😈 Phát âm kiểu gì mà quỷ dữ nghe thấy cũng phải khóc thét! Ngươi đang nói tiếng hành tinh nào vậy hả kẻ phàm trần?!"

- feedback: Lời nhận xét ma mị, cay độc, mỉa mai bằng tiếng Việt. PHẢI giải thích cụ thể phần nào phát âm sai dựa trên so sánh giữa thực tế và mục tiêu.
- suggestions: Mảng 2-3 gợi ý cụ thể, viết kiểu mệnh lệnh quỷ dữ bằng tiếng Việt.

Trả về CHỈ JSON (không thêm text):
{
  "accuracyScore": 0.75,
  "feedback": "😈 ...",
  "suggestions": ["...", "..."]
}
      `;

      const gradingRaw = await this._callAi(gradingPrompt);
      const gradingResult = JSON.parse(gradingRaw);

      // Generate TTS audio from the feedback text
      console.log('🔊 Generating TTS audio for feedback...');
      const feedbackAudio = await this.generateFeedbackAudio(gradingResult.feedback);

      return {
        transcription,
        accuracyScore: gradingResult.accuracyScore,
        feedback: gradingResult.feedback,
        suggestions: gradingResult.suggestions || [],
        feedbackAudio: feedbackAudio
      };
    } catch (error) {
      console.error('Error evaluating speech:', error.message);
      if (error.response) {
        console.error('Groq API Error Response:', error.response.data);
      }
      throw error;
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
