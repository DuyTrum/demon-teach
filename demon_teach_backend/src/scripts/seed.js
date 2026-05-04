const { User, Lesson, syncDatabase } = require('../models');
const { testConnection } = require('../config/database');
require('dotenv').config();

const sampleLessonContent = {
  sections: [
    {
      type: "vocabulary",
      items: [
        {
          word: "Hello",
          pronunciation: "/həˈloʊ/",
          translation: "Xin chào",
          example: "Hello, how are you? (Xin chào, bạn khỏe không?)"
        },
        {
          word: "Goodbye",
          pronunciation: "/ˌɡʊdˈbaɪ/",
          translation: "Tạm biệt",
          example: "Goodbye, see you tomorrow! (Tạm biệt, hẹn gặp lại vào ngày mai!)"
        }
      ]
    },
    {
      type: "explanation",
      title: "Cách chào hỏi thông dụng",
      content: "Trong tiếng Anh, 'Hello' là cách chào hỏi phổ biến nhất và có thể dùng trong hầu hết các tình huống thân mật hay trang trọng."
    },
    {
      type: "practice",
      exercises: [
        {
          question: "Làm thế nào để nói 'Xin chào' bằng tiếng Anh?",
          options: ["Hello", "Goodbye", "Thanks", "Sorry"],
          correctAnswer: "Hello"
        },
        {
          question: "Từ nào sau đây được dùng khi tạm biệt?",
          options: ["Hello", "Goodbye", "Please", "Welcome"],
          correctAnswer: "Goodbye"
        }
      ]
    }
  ]
};

const seedDatabase = async () => {
  try {
    console.log('🌱 Starting database seeding...');

    // Test connection
    await testConnection();

    // Sync database (create tables)
    await syncDatabase(true);

    // Create admin user
    console.log('👤 Creating admin user...');
    const admin = await User.findOrCreate({
      where: { email: 'admin@demonteach.com' },
      defaults: {
        email: 'admin@demonteach.com',
        password: 'admin123',
        role: 'admin'
      }
    });

    if (admin[1]) {
      console.log('✅ Admin user created: admin@demonteach.com / admin123');
    } else {
      console.log('ℹ️  Admin user already exists');
    }

    // Create regular user
    console.log('👤 Creating regular user...');
    const user = await User.findOrCreate({
      where: { email: 'user@demonteach.com' },
      defaults: {
        email: 'user@demonteach.com',
        password: 'user123',
        role: 'user'
      }
    });

    if (user[1]) {
      console.log('✅ Regular user created: user@demonteach.com / user123');
    } else {
      console.log('ℹ️  Regular user already exists');
    }

    // Create sample lessons
    console.log('📚 Creating sample lessons...');

    const lessons = [
      {
        id: "en_basic_vocab_001",
        title: "Greetings and Introductions",
        difficulty: "basic",
        topic: "conversation",
        targetLanguage: "en",
        nativeLanguage: "vi",
        durationEstimate: 10,
        content: sampleLessonContent,
        isPublished: true,
        publishedAt: new Date(),
        createdBy: admin[0].id
      },
      {
        id: "en_basic_vocab_002",
        title: "Numbers 1-10",
        difficulty: "basic",
        topic: "numbers",
        targetLanguage: "en",
        nativeLanguage: "vi",
        durationEstimate: 8,
        content: {
          flashcards: [
            {
              id: "fc1",
              lessonId: "en_basic_vocab_002",
              frontText: "One",
              backText: "Một",
              exampleUsage: "I have one apple",
              audioUrl: "https://cdn.example.com/audio/one.mp3"
            }
          ],
          quiz: {
            id: "quiz2",
            lessonId: "en_basic_vocab_002",
            title: "Numbers Quiz",
            questions: [
              {
                id: "q1",
                type: "multipleChoice",
                questionText: "What is 'One' in Vietnamese?",
                options: ["Một", "Hai", "Ba", "Bốn"],
                correctAnswer: "Một",
                explanation: "Một means One in Vietnamese"
              }
            ]
          }
        },
        isPublished: true,
        publishedAt: new Date(),
        createdBy: admin[0].id
      },
      {
        id: "en_basic_vocab_003",
        title: "Family Members",
        difficulty: "basic",
        topic: "family",
        targetLanguage: "en",
        nativeLanguage: "vi",
        durationEstimate: 12,
        content: sampleLessonContent, // Reuse for demo
        isPublished: true,
        publishedAt: new Date(),
        createdBy: admin[0].id
      }
    ];

    for (const lessonData of lessons) {
      const [lesson, created] = await Lesson.findOrCreate({
        where: { id: lessonData.id },
        defaults: lessonData
      });

      if (created) {
        console.log(`✅ Created lesson: ${lessonData.title} (${lessonData.id})`);
      } else {
        // Update existing lesson to ensure ID matches
        await lesson.update(lessonData);
        console.log(`ℹ️  Updated lesson: ${lessonData.title} (${lessonData.id})`);
      }
    }

    console.log('\n✨ Database seeding completed successfully!');
    console.log('\n📋 Summary:');
    console.log('   - Admin: admin@demonteach.com / admin123');
    console.log('   - User: user@demonteach.com / user123');
    console.log('   - Lessons: 3 sample lessons created');
    console.log('\n🚀 You can now start the server with: npm run dev');

    process.exit(0);
  } catch (error) {
    console.error('❌ Error seeding database:', error);
    process.exit(1);
  }
};

seedDatabase();
