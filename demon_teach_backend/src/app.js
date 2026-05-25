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
  origin: function (origin, callback) {
    callback(null, true);
  },
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
const axios = require('axios');
const { EdgeTTS } = require('node-edge-tts');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

app.get('/api/tts', async (req, res, next) => {
  try {
    const { text, language } = req.query;
    if (!text || !language) {
      return res.status(400).json({ success: false, message: 'Text and language parameters are required' });
    }

    const voiceMap = {
      'en': { voice: 'en-US-EmmaMultilingualNeural', lang: 'en-US' },
      'zh': { voice: 'zh-CN-XiaoxiaoNeural', lang: 'zh-CN' },
      'ko': { voice: 'ko-KR-SunHiNeural', lang: 'ko-KR' },
      'vi': { voice: 'vi-VN-HoaiMyNeural', lang: 'vi-VN' }
    };

    const voiceConfig = voiceMap[language] || voiceMap['en'];

    const tts = new EdgeTTS({
      voice: voiceConfig.voice,
      lang: voiceConfig.lang,
      outputFormat: 'audio-24khz-96kbitrate-mono-mp3'
    });

    const tempDir = path.join(__dirname, 'temp');
    if (!fs.existsSync(tempDir)) {
      fs.mkdirSync(tempDir, { recursive: true });
    }

    const tempFileName = `tts_${crypto.randomBytes(16).toString('hex')}.mp3`;
    const tempFilePath = path.join(tempDir, tempFileName);

    await tts.ttsPromise(text, tempFilePath);

    res.set('Content-Type', 'audio/mpeg');
    res.sendFile(tempFilePath, (err) => {
      // Clean up the temp file after sending
      try {
        if (fs.existsSync(tempFilePath)) {
          fs.unlinkSync(tempFilePath);
        }
      } catch (cleanupError) {
        console.error('Error deleting temp TTS file:', cleanupError.message);
      }
      if (err && !res.headersSent) {
        console.error('Error sending TTS file:', err.message);
        res.status(500).end();
      }
    });
  } catch (error) {
    console.error('Error in Edge TTS proxy:', error.message);
    if (!res.headersSent) {
      res.status(500).json({ success: false, message: 'Error playing audio through Edge TTS proxy' });
    }
  }
});

const { generateSfx } = require('./utils/wavGenerator');

app.get('/api/sfx/:type', (req, res) => {
  const type = req.params.type;
  try {
    const buffer = generateSfx(type);
    res.set('Content-Type', 'audio/wav');
    res.send(buffer);
  } catch (error) {
    console.error('Error generating SFX:', error.message);
    res.status(500).json({ success: false, message: 'SFX generation failed' });
  }
});

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
