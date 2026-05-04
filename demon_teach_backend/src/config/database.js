const { Sequelize } = require('sequelize');
require('dotenv').config();

let sequelize;

// Nếu DB_DIALECT là postgres thì bắt buộc dùng Postgres, không fallback
if (process.env.DB_DIALECT === 'postgres') {
  console.log('🚀 Using PostgreSQL (Production/Real DB Mode)');
  sequelize = new Sequelize(
    process.env.DB_NAME || 'demon_teach',
    process.env.DB_USER || 'postgres',
    process.env.DB_PASSWORD || 'postgres',
    {
      host: process.env.DB_HOST || 'localhost',
      port: process.env.DB_PORT || 5432,
      dialect: 'postgres',
      logging: process.env.NODE_ENV === 'development' ? console.log : false,
      pool: { max: 5, min: 0, acquire: 30000, idle: 10000 }
    }
  );
} else {
  // Mặc định dùng SQLite cho nhanh nếu không cấu hình Postgres
  console.log('ℹ️ Using SQLite (Local DB Mode)');
  sequelize = new Sequelize({
    dialect: 'sqlite',
    storage: './database.sqlite',
    logging: false
  });
}

const testConnection = async () => {
  try {
    await sequelize.authenticate();
    console.log(`✅ Connected to ${sequelize.options.dialect.toUpperCase()} database successfully.`);
  } catch (error) {
    console.error('❌ Database connection error:', error.message);
    console.log('👉 Please check your .env configuration or ensure PostgreSQL is running.');
    process.exit(1);
  }
};

module.exports = { sequelize, testConnection };
