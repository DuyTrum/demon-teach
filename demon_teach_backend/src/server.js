const app = require('./app');

const PORT = process.env.PORT || 3000;

// Start server
const startServer = async () => {
  try {
    console.log('🚀 Starting Demon Teach Backend API...');
    console.log(`📍 Environment: ${process.env.NODE_ENV || 'development'}`);
    console.log('🔥 Using Firebase Firestore as the sole database.');

    // Start listening
    app.listen(PORT, () => {
      console.log(`✅ Server is running on port ${PORT}`);
      console.log(`🌐 API URL: http://localhost:${PORT}`);
      console.log(`📚 Health check: http://localhost:${PORT}/health`);
      console.log('\n📋 Available endpoints:');
      console.log('   - POST   /api/auth/login');
      console.log('   - POST   /api/auth/register');
      console.log('   - POST   /api/auth/refresh');
      console.log('   - GET    /api/auth/me');
      console.log('   - GET    /api/cms/lessons');
      console.log('   - POST   /api/cms/lessons');
      console.log('   - PUT    /api/cms/lessons/:id');
      console.log('   - DELETE /api/cms/lessons/:id');
      console.log('   - POST   /api/cms/lessons/:id/publish');
      console.log('   - GET    /api/content/check-updates');
      console.log('   - GET    /api/content/lessons');
      console.log('   - GET    /api/content/lessons/:id');
      console.log('\n✨ Ready to accept requests!');
    });
  } catch (error) {
    console.error('❌ Failed to start server:', error);
    process.exit(1);
  }
};

// Handle graceful shutdown
process.on('SIGTERM', async () => {
  console.log('\n🛑 SIGTERM received. Shutting down gracefully...');
  process.exit(0);
});

process.on('SIGINT', async () => {
  console.log('\n🛑 SIGINT received. Shutting down gracefully...');
  process.exit(0);
});

// Start the server
startServer();
