const { db } = require('../config/firebase');
require('dotenv').config();

const PREDEFINED_LESSONS = [
  // BEGINNER
  {
    id: "en_beginner_vocabulary_001",
    title: "Topic: Greetings & Introductions (EN)",
    difficulty: "beginner",
    category: "vocabulary",
    topic: "Greetings & Introductions",
    targetLanguage: "en",
    durationEstimate: 10,
    content: {
      flashcards: [
        { id: "beg_v1", frontText: "Hello", backText: "Xin chào", phonetic: "/həˈloʊ/", example: "Hello, nice to meet you.", example_translation: "Xin chào, rất vui được gặp bạn.", audioUrl: "/api/tts?text=Hello&language=en" },
        { id: "beg_v2", frontText: "How are you?", backText: "Bạn khỏe không?", phonetic: "/haʊ ɑːr juː/", example: "How are you today?", example_translation: "Hôm nay bạn khỏe không?", audioUrl: "/api/tts?text=How%20are%20you&language=en" },
        { id: "beg_v3", frontText: "Thank you", backText: "Cảm ơn", phonetic: "/θæŋk juː/", example: "Thank you for your help.", example_translation: "Cảm ơn sự giúp đỡ của bạn.", audioUrl: "/api/tts?text=Thank%20you&language=en" }
      ],
      quiz: {
        id: "beg_q1",
        title: "Greetings & Introductions Quiz",
        questions: [
          { id: "beg_ex1", type: "multiple-choice", content: { questionText: "Translate: 'Xin chào'", options: ["Hello", "Goodbye", "Thank you", "Please"], correctAnswer: "Hello", explanation: "Hello nghĩa là Xin chào." } },
          { id: "beg_ex2", type: "multiple-choice", content: { questionText: "Translate: 'Cảm ơn'", options: ["Hello", "Goodbye", "Thank you", "Sorry"], correctAnswer: "Thank you", explanation: "Thank you nghĩa là Cảm ơn." } }
        ]
      },
      listening: {
        id: "beg_list1",
        lessonId: "en_beginner_vocabulary_001",
        audioUrl: "/api/tts?text=Hello%20my%20friend%20how%20are%20you&language=en",
        durationSeconds: 15,
        questions: [
          { id: "beg_lq1", questionText: "What does the speaker say?", options: ["Hello my friend how are you", "Goodbye my friend", "Thank you", "Good morning"], correctAnswer: "Hello my friend how are you", explanation: "Người nói phát âm: Hello my friend how are you." }
        ]
      },
      sections: [
        {
          type: "vocabulary",
          items: [
            { word: "Hello", translation: "Xin chào", pronunciation: "/həˈloʊ/", audioUrl: "/api/tts?text=Hello&language=en" },
            { word: "How are you?", translation: "Bạn khỏe không?", pronunciation: "/haʊ ɑːr juː/", audioUrl: "/api/tts?text=How%20are%20you&language=en" },
            { word: "Thank you", translation: "Cảm ơn", pronunciation: "/θæŋk juː/", audioUrl: "/api/tts?text=Thank%20you&language=en" }
          ]
        },
        {
          type: "practice",
          exercises: [
            { question: "Translate: 'Xin chào'", options: ["Hello", "Goodbye", "Thank you", "Please"], correctAnswer: "Hello" },
            { question: "Translate: 'Cảm ơn'", options: ["Hello", "Goodbye", "Thank you", "Sorry"], correctAnswer: "Thank you" }
          ]
        },
        {
          type: "speaking",
          items: [
            { phrase: "Nice to meet you", translation: "Rất vui được gặp bạn", pronunciation: "/naɪs tuː miːt juː/", audioUrl: "/api/tts?text=Nice%20to%20meet%20you&language=en" }
          ]
        }
      ]
    },
    isPublished: true,
    publishedAt: new Date().toISOString(),
    createdBy: "admin_seed",
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  },
  
  // ELEMENTARY
  {
    id: "en_elementary_vocabulary_001",
    title: "Topic: Family Members (EN)",
    difficulty: "elementary",
    category: "vocabulary",
    topic: "Family Members",
    targetLanguage: "en",
    durationEstimate: 10,
    content: {
      flashcards: [
        { id: "elem_v1", frontText: "Father", backText: "Bố/Cha", phonetic: "/ˈfɑːðər/", example: "My father is a teacher.", example_translation: "Bố tôi là giáo viên.", audioUrl: "/api/tts?text=Father&language=en" },
        { id: "elem_v2", frontText: "Mother", backText: "Mẹ", phonetic: "/ˈmʌðər/", example: "My mother cooks delicious food.", example_translation: "Mẹ tôi nấu ăn rất ngon.", audioUrl: "/api/tts?text=Mother&language=en" },
        { id: "elem_v3", frontText: "Brother", backText: "Anh/Em trai", phonetic: "/ˈbrʌðər/", example: "I have one brother.", example_translation: "Tôi có một người em trai.", audioUrl: "/api/tts?text=Brother&language=en" }
      ],
      quiz: {
        id: "elem_q1",
        title: "Family Members Quiz",
        questions: [
          { id: "elem_ex1", type: "multiple-choice", content: { questionText: "Translate: 'Mẹ'", options: ["Father", "Mother", "Sister", "Brother"], correctAnswer: "Mother", explanation: "Mother có nghĩa là mẹ." } }
        ]
      },
      listening: {
        id: "elem_list1",
        lessonId: "en_elementary_vocabulary_001",
        audioUrl: "/api/tts?text=I%20love%20my%20father%20and%20mother&language=en",
        durationSeconds: 15,
        questions: [
          { id: "elem_lq1", questionText: "Who does the speaker love?", options: ["Father and Mother", "Brother and Sister", "Uncle", "Friends"], correctAnswer: "Father and Mother", explanation: "Người nói phát âm: I love my father and mother." }
        ]
      },
      sections: [
        {
          type: "vocabulary",
          items: [
            { word: "Father", translation: "Bố/Cha", pronunciation: "/ˈfɑːðər/", audioUrl: "/api/tts?text=Father&language=en" },
            { word: "Mother", translation: "Mẹ", pronunciation: "/ˈmʌðər/", audioUrl: "/api/tts?text=Mother&language=en" },
            { word: "Brother", translation: "Anh/Em trai", pronunciation: "/ˈbrʌðər/", audioUrl: "/api/tts?text=Brother&language=en" }
          ]
        },
        {
          type: "practice",
          exercises: [
            { question: "Translate: 'Mẹ'", options: ["Father", "Mother", "Sister", "Brother"], correctAnswer: "Mother" }
          ]
        },
        {
          type: "speaking",
          items: [
            { phrase: "My family is small", translation: "Gia đình tôi nhỏ thôi", pronunciation: "/maɪ ˈfæməli ɪz smɔːl/", audioUrl: "/api/tts?text=My%20family%20is%20small&language=en" }
          ]
        }
      ]
    },
    isPublished: true,
    publishedAt: new Date().toISOString(),
    createdBy: "admin_seed",
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  },

  // INTERMEDIATE
  {
    id: "en_intermediate_vocabulary_001",
    title: "Topic: Travel Arrangements (EN)",
    difficulty: "intermediate",
    category: "vocabulary",
    topic: "Travel Arrangements",
    targetLanguage: "en",
    durationEstimate: 10,
    content: {
      flashcards: [
        { id: "int_v1", frontText: "Reservation", backText: "Sự đặt trước", phonetic: "/ˌrezərˈveɪʃn/", example: "I made a hotel reservation.", example_translation: "Tôi đã đặt trước phòng khách sạn.", audioUrl: "/api/tts?text=Reservation&language=en" },
        { id: "int_v2", frontText: "Departure", backText: "Giờ khởi hành", phonetic: "/dɪˈpɑːrtʃər/", example: "Our departure is at 9 AM.", example_translation: "Giờ khởi hành của chúng tôi là lúc 9 giờ sáng.", audioUrl: "/api/tts?text=Departure&language=en" },
        { id: "int_v3", frontText: "Destination", backText: "Điểm đến", phonetic: "/ˌdestɪˈneɪʃn/", example: "Paris is our final destination.", example_translation: "Paris là điểm đến cuối cùng của chúng tôi.", audioUrl: "/api/tts?text=Destination&language=en" }
      ],
      quiz: {
        id: "int_q1",
        title: "Travel Quiz",
        questions: [
          { id: "int_ex1", type: "multiple-choice", content: { questionText: "Translate: 'Điểm đến'", options: ["Reservation", "Departure", "Destination", "Flight"], correctAnswer: "Destination", explanation: "Destination nghĩa là Điểm đến." } }
        ]
      },
      listening: {
        id: "int_list1",
        lessonId: "en_intermediate_vocabulary_001",
        audioUrl: "/api/tts?text=Please%20confirm%20your%20flight%20departure%20time&language=en",
        durationSeconds: 15,
        questions: [
          { id: "int_lq1", questionText: "What should you confirm?", options: ["Flight departure time", "Hotel reservation", "Destination address", "Ticket price"], correctAnswer: "Flight departure time", explanation: "Đoạn ghi âm nói: Please confirm your flight departure time." }
        ]
      },
      sections: [
        {
          type: "vocabulary",
          items: [
            { word: "Reservation", translation: "Sự đặt trước", pronunciation: "/ˌrezərˈveɪʃn/", audioUrl: "/api/tts?text=Reservation&language=en" },
            { word: "Departure", translation: "Giờ khởi hành", pronunciation: "/dɪˈpɑːrtʃər/", audioUrl: "/api/tts?text=Departure&language=en" },
            { word: "Destination", translation: "Điểm đến", pronunciation: "/ˌdestɪˈneɪʃn/", audioUrl: "/api/tts?text=Destination&language=en" }
          ]
        },
        {
          type: "practice",
          exercises: [
            { question: "Translate: 'Điểm đến'", options: ["Reservation", "Departure", "Destination", "Flight"], correctAnswer: "Destination" }
          ]
        },
        {
          type: "speaking",
          items: [
            { phrase: "Where is the departure gate?", translation: "Cổng khởi hành ở đâu?", pronunciation: "/wer ɪz ðə dɪˈpɑːrtʃər ɡeɪt/", audioUrl: "/api/tts?text=Where%20is%20the%20departure%20gate&language=en" }
          ]
        }
      ]
    },
    isPublished: true,
    publishedAt: new Date().toISOString(),
    createdBy: "admin_seed",
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  },

  // UPPER INTERMEDIATE
  {
    id: "en_upperIntermediate_vocabulary_001",
    title: "Topic: Career Development (EN)",
    difficulty: "upperIntermediate",
    category: "vocabulary",
    topic: "Career Development",
    targetLanguage: "en",
    durationEstimate: 10,
    content: {
      flashcards: [
        { id: "up_v1", frontText: "Promotion", backText: "Sự thăng tiến/Lên chức", phonetic: "/prəˈmoʊʃn/", example: "She received a well-deserved promotion.", example_translation: "Cô ấy đã được thăng chức rất xứng đáng.", audioUrl: "/api/tts?text=Promotion&language=en" },
        { id: "up_v2", frontText: "Resume", backText: "Sơ yếu lý lịch (CV)", phonetic: "/ˈrezʊmeɪ/", example: "Send your resume to our HR manager.", example_translation: "Gửi sơ yếu lý lịch của bạn cho quản lý nhân sự.", audioUrl: "/api/tts?text=Resume&language=en" },
        { id: "up_v3", frontText: "Negotiation", backText: "Sự đàm phán/Thương lượng", phonetic: "/nɪˌɡoʊʃiˈeɪʃn/", example: "Salary negotiation is important.", example_translation: "Đàm phán lương là việc quan trọng.", audioUrl: "/api/tts?text=Negotiation&language=en" }
      ],
      quiz: {
        id: "up_q1",
        title: "Career Quiz",
        questions: [
          { id: "up_ex1", type: "multiple-choice", content: { questionText: "Translate: 'Đàm phán'", options: ["Promotion", "Resume", "Negotiation", "Interview"], correctAnswer: "Negotiation", explanation: "Negotiation có nghĩa là đàm phán." } }
        ]
      },
      listening: {
        id: "up_list1",
        lessonId: "en_upperIntermediate_vocabulary_001",
        audioUrl: "/api/tts?text=Salary%20negotiation%20requires%20careful%20preparation&language=en",
        durationSeconds: 15,
        questions: [
          { id: "up_lq1", questionText: "What requires preparation?", options: ["Salary negotiation", "Sending a resume", "Applying for job", "Holiday plan"], correctAnswer: "Salary negotiation", explanation: "Đoạn ghi âm nói: Salary negotiation requires careful preparation." }
        ]
      },
      sections: [
        {
          type: "vocabulary",
          items: [
            { word: "Promotion", translation: "Sự thăng tiến/Lên chức", pronunciation: "/prəˈmoʊʃn/", audioUrl: "/api/tts?text=Promotion&language=en" },
            { word: "Resume", translation: "Sơ yếu lý lịch (CV)", pronunciation: "/ˈrezʊmeɪ/", audioUrl: "/api/tts?text=Resume&language=en" },
            { word: "Negotiation", translation: "Sự đàm phán/Thương lượng", pronunciation: "/nɪˌɡoʊʃiˈeɪʃn/", audioUrl: "/api/tts?text=Negotiation&language=en" }
          ]
        },
        {
          type: "practice",
          exercises: [
            { question: "Translate: 'Đàm phán'", options: ["Promotion", "Resume", "Negotiation", "Interview"], correctAnswer: "Negotiation" }
          ]
        },
        {
          type: "speaking",
          items: [
            { phrase: "I would like to negotiate my contract", translation: "Tôi muốn đàm phán lại hợp đồng của mình", pronunciation: "/aɪ wʊd laɪk tuː nɪˈɡoʊʃieɪt maɪ ˈkɑːntrækt/", audioUrl: "/api/tts?text=I%20would%20like%20to%20negotiate%20my%20contract&language=en" }
          ]
        }
      ]
    },
    isPublished: true,
    publishedAt: new Date().toISOString(),
    createdBy: "admin_seed",
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  },

  // ADVANCED
  {
    id: "en_advanced_vocabulary_001",
    title: "Topic: Academic Discourse (EN)",
    difficulty: "advanced",
    category: "vocabulary",
    topic: "Academic Discourse",
    targetLanguage: "en",
    durationEstimate: 10,
    content: {
      flashcards: [
        { id: "adv_v1", frontText: "Hypothesis", backText: "Giả thuyết", phonetic: "/haɪˈpɑːθəsɪs/", example: "The researcher formulated a hypothesis.", example_translation: "Nhà nghiên cứu đã thiết lập một giả thuyết.", audioUrl: "/api/tts?text=Hypothesis&language=en" },
        { id: "adv_v2", frontText: "Methodology", backText: "Phương pháp luận", phonetic: "/ˌmeθəˈdɑːlədʒi/", example: "We revised the research methodology.", example_translation: "Chúng tôi đã chỉnh sửa phương pháp luận nghiên cứu.", audioUrl: "/api/tts?text=Methodology&language=en" },
        { id: "adv_v3", frontText: "Empirical Evidence", backText: "Bằng chứng thực nghiệm", phonetic: "/ɪmˈpɪrɪkl ˈevɪdəns/", example: "This theory is supported by empirical evidence.", example_translation: "Lý thuyết này được hỗ trợ bởi bằng chứng thực nghiệm.", audioUrl: "/api/tts?text=Empirical%20Evidence&language=en" }
      ],
      quiz: {
        id: "adv_q1",
        title: "Academic Discourse Quiz",
        questions: [
          { id: "adv_ex1", type: "multiple-choice", content: { questionText: "Translate: 'Giả thuyết'", options: ["Hypothesis", "Methodology", "Evidence", "Analysis"], correctAnswer: "Hypothesis", explanation: "Hypothesis nghĩa là giả thuyết." } }
        ]
      },
      listening: {
        id: "adv_list1",
        lessonId: "en_advanced_vocabulary_001",
        audioUrl: "/api/tts?text=Empirical%20evidence%20is%20required%20to%20validate%20your%20hypothesis&language=en",
        durationSeconds: 15,
        questions: [
          { id: "adv_lq1", questionText: "What is required to validate the hypothesis?", options: ["Empirical evidence", "A new book", "More time", "Money"], correctAnswer: "Empirical evidence", explanation: "Đoạn băng ghi âm: Empirical evidence is required to validate your hypothesis." }
        ]
      },
      sections: [
        {
          type: "vocabulary",
          items: [
            { word: "Hypothesis", translation: "Giả thuyết", pronunciation: "/haɪˈpɑːθəsɪs/", audioUrl: "/api/tts?text=Hypothesis&language=en" },
            { word: "Methodology", translation: "Phương pháp luận", pronunciation: "/ˌmeθəˈdɑːlədʒi/", audioUrl: "/api/tts?text=Methodology&language=en" },
            { word: "Empirical Evidence", translation: "Bằng chứng thực nghiệm", pronunciation: "/ɪmˈpɪrɪkl ˈevɪdəns/", audioUrl: "/api/tts?text=Empirical%20Evidence&language=en" }
          ]
        },
        {
          type: "practice",
          exercises: [
            { question: "Translate: 'Giả thuyết'", options: ["Hypothesis", "Methodology", "Evidence", "Analysis"], correctAnswer: "Hypothesis" }
          ]
        },
        {
          type: "speaking",
          items: [
            { phrase: "The research methodology is rigorous", translation: "Phương pháp luận nghiên cứu rất chặt chẽ", pronunciation: "/ðə rɪˈsɜːrtʃ ˌmeθəˈdɑːlədʒi ɪz ˈrɪɡərəs/", audioUrl: "/api/tts?text=The%20research%20methodology%20is%20rigorous&language=en" }
          ]
        }
      ]
    },
    isPublished: true,
    publishedAt: new Date().toISOString(),
    createdBy: "admin_seed",
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  }
];

async function seedPredefined() {
  console.log('🌱 Seeding predefined lessons directly to Firestore...');
  if (!db) {
    console.error('❌ Firestore not initialized.');
    process.exit(1);
  }

  try {
    for (const lesson of PREDEFINED_LESSONS) {
      console.log(`⏳ Seeding predefined lesson: ${lesson.id} ("${lesson.topic}")`);
      await db.collection('lessons').doc(lesson.id).set(lesson);
    }
    console.log('✅ Success! All 5 levels of predefined lessons seeded successfully!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Failed to seed predefined lessons:', error.message);
    process.exit(1);
  }
}

seedPredefined();
