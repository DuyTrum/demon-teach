const { db } = require('../config/firebase');
const LessonService = require('../services/LessonService');
require('dotenv').config();

const SEED_TOPICS = [
  // Beginner
  { topic: 'Basic Greetings & Introductions', level: 'beginner', category: 'vocabulary' },
  { topic: 'Numbers and Time', level: 'beginner', category: 'vocabulary' },
  { topic: 'Daily Activities & Routines', level: 'beginner', category: 'vocabulary' },

  // Elementary
  { topic: 'Family & Describe People', level: 'elementary', category: 'vocabulary' },
  { topic: 'Asking for Directions', level: 'elementary', category: 'speaking' },
  { topic: 'Present Tense Grammar', level: 'elementary', category: 'grammar' },

  // Intermediate
  { topic: 'Travel & Transportation', level: 'intermediate', category: 'vocabulary' },
  { topic: 'Past Tense Grammar', level: 'intermediate', category: 'grammar' },
  { topic: 'Ordering Food at a Restaurant', level: 'intermediate', category: 'speaking' },

  // Upper Intermediate
  { topic: 'Work and Job Interviews', level: 'upperIntermediate', category: 'vocabulary' },
  { topic: 'Conditional Sentences', level: 'upperIntermediate', category: 'grammar' },
  { topic: 'Giving Presentations', level: 'upperIntermediate', category: 'speaking' },

  // Advanced
  { topic: 'Academic Vocabulary', level: 'advanced', category: 'vocabulary' },
  { topic: 'Complex Sentence Structures', level: 'advanced', category: 'grammar' },
  { topic: 'Global Debates & Current Events', level: 'advanced', category: 'speaking' },
];

const seedLessons = async () => {
  try {
    console.log('🌱 Starting Firebase Lesson Seeding...');
    if (!db) throw new Error('Firestore not initialized. Check your credentials.');

    let count = 1;
    for (const item of SEED_TOPICS) {
      console.log(`\n⏳ [${count}/${SEED_TOPICS.length}] Generating ${item.level} lesson on: "${item.topic}"...`);
      
      const customId = `en_${item.level}_${item.category}_00${Math.floor(Math.random() * 100) + 1}_${Date.now()}`;
      
      try {
        const lesson = await LessonService.generateAiLesson(
          item.topic,
          'en', // target language
          item.level,
          item.category,
          'admin_seed',
          customId,
          null, // assessmentScore
          null, // goalType
          10 // minutes
        );
        console.log(`✅ Success: ${lesson.title} (${customId}) saved to Firestore!`);
      } catch (err) {
        console.error(`❌ Failed to generate lesson "${item.topic}":`, err.message);
      }
      count++;
    }

    console.log('\n✨ Database seeding completed successfully!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Critical Error seeding database:', error);
    process.exit(1);
  }
};

seedLessons();
