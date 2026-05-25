const { User, Lesson, LessonVersion, Vocabulary, Exercise, syncDatabase } = require('../models');
const { testConnection } = require('../config/database');
require('dotenv').config();

const seedDatabase = async () => {
  try {
    console.log('🌱 Starting database seeding & cleanup...');

    // Test connection
    await testConnection();

    // Sync database (create tables if not exists)
    await syncDatabase(false);

    // Wipe all previous lesson-related data to ensure clean, AI-only generation
    console.log('🧹 Wiping all old lesson, lesson version, vocabulary, and exercise records...');
    await LessonVersion.destroy({ where: {} });
    await Lesson.destroy({ where: {} });
    await Vocabulary.destroy({ where: {} });
    await Exercise.destroy({ where: {} });

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

    console.log('\n✨ Database cleanup and seeding completed successfully!');
    console.log('\n📋 Summary:');
    console.log('   - Admin: admin@demonteach.com / admin123');
    console.log('   - User: user@demonteach.com / user123');
    console.log('   - Lessons: Database wiped clean for AI generation');
    console.log('\n🚀 You can now start the server with: npm run dev');

    process.exit(0);
  } catch (error) {
    console.error('❌ Error seeding database:', error);
    process.exit(1);
  }
};

seedDatabase();
