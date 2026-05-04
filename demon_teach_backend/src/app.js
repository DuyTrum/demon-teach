const express = require('express');
const cors = require('cors');
require('dotenv').config();

const { errorHandler, notFound } = require('./middleware/errorHandler');

// Import routes
const authRoutes = require('./routes/auth');
const cmsRoutes = require('./routes/cms');
const contentRoutes = require('./routes/content');
const vocabularyRoutes = require('./routes/vocabulary');
const generatorRoutes = require('./routes/generator');

const app = express();

// Middleware
app.use(cors({
  origin: ['http://localhost:3000', 'http://localhost:3001', 'http://localhost:8080'],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'PATCH'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Request logging in development
if (process.env.NODE_ENV === 'development') {
  app.use((req, res, next) => {
    console.log(`${req.method} ${req.path}`);
    next();
  });
}

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    success: true,
    message: 'Demon Teach Backend API is running',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development'
  });
});

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/cms', cmsRoutes);
app.use('/api/content', contentRoutes);
app.use('/api/vocabulary', vocabularyRoutes);
app.use('/api/generator', generatorRoutes);

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'Welcome to Demon Teach Backend API',
    version: '1.0.0',
    endpoints: {
      health: '/health',
      auth: '/api/auth',
      cms: '/api/cms',
      content: '/api/content'
    }
  });
});

// Error handling
app.use(notFound);
app.use(errorHandler);

module.exports = app;
