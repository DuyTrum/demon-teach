/// Application-wide constants
class AppConstants {
  // App Information
  static const String appName = 'Demon Teach';
  static const String appVersion = '1.0.0';

  // Supported Languages
  static const List<String> supportedTargetLanguages = ['en', 'zh', 'ko'];
  static const List<String> supportedNativeLanguages = ['vi', 'en', 'zh', 'ko'];

  // Language Display Names
  static const Map<String, String> languageNames = {
    'en': 'English',
    'zh': 'Chinese',
    'ko': 'Korean',
    'vi': 'Vietnamese',
  };

  // Study Time Constraints
  static const int minStudyTimeMinutes = 5;
  static const int maxStudyTimeMinutes = 30;

  // Lesson Duration
  static const int minLessonDurationMinutes = 5;
  static const int maxLessonDurationMinutes = 15;

  // Assessment
  static const int minAssessmentQuestions = 10;
  static const int maxAssessmentQuestions = 15;
  static const int assessmentTimeMinutes = 10;

  // Proficiency Levels
  static const String proficiencyBasic = 'basic';
  static const String proficiencyIntermediate = 'intermediate';
  static const String proficiencyAdvanced = 'advanced';

  // Learning Goals
  static const String goalConversation = 'conversation';
  static const String goalExamPreparation = 'exam_preparation';
  static const String goalProfessional = 'professional';

  // Progress Tracking
  static const int baseXP = 10;
  static const int accuracyBonusMax = 15;
  static const int speedBonusMax = 5;
  static const int perfectBonus = 10;

  // Spaced Repetition
  static const double initialEaseFactor = 2.5;
  static const int initialInterval = 1;
  static const double minEaseFactor = 1.3;

  // Adaptive Difficulty
  static const int analysisWindowDays = 7;
  static const double increaseThreshold = 0.85;
  static const double decreaseThreshold = 0.60;
  static const int minimumLessonsForAnalysis = 3;

  // Offline Mode
  static const int lessonsToDownload = 3;

  // Sync
  static const int syncTimeoutSeconds = 30;
  static const int maxRetryAttempts = 3;

  // Notifications
  static const List<int> streakMilestones = [7, 30, 100];

  // Audio
  static const int minAudioDurationSeconds = 10;
  static const int maxAudioDurationSeconds = 60;

  // Quiz
  static const int minQuizQuestions = 3;
  static const int maxQuizQuestions = 5;

  // Database
  static const String databaseName = 'demon_teach.db';
  static const int databaseVersion = 1;

  // API
  // Use http://10.0.2.2:3000 for Android Emulator
  // Use http://localhost:3000 for iOS Simulator or Web
  static const String apiBaseUrl = 'http://10.0.2.2:3000';
  static const Duration apiTimeout = Duration(seconds: 30);

  // Cache
  static const Duration cacheExpiration = Duration(days: 7);
}
