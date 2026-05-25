import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:demon_teach/data/datasources/remote/lesson_remote_datasource.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:demon_teach/data/repositories/auth_repository_impl.dart';
import 'package:demon_teach/presentation/providers/auth_provider.dart';
import 'package:demon_teach/presentation/screens/auth/login_screen.dart';
import 'package:demon_teach/core/theme/app_theme.dart';
import 'package:demon_teach/core/di/injection_container.dart';
import 'package:demon_teach/core/constants/app_constants.dart';
import 'package:demon_teach/presentation/screens/main_screen.dart';
import 'package:demon_teach/presentation/screens/onboarding/language_selection_screen.dart';
import 'package:demon_teach/presentation/providers/language_provider.dart';
import 'package:demon_teach/presentation/providers/assessment_provider.dart';
import 'package:demon_teach/presentation/providers/goal_provider.dart';
import 'package:demon_teach/presentation/providers/learning_path_provider.dart';
import 'package:demon_teach/presentation/providers/lesson_provider.dart';
import 'package:demon_teach/presentation/providers/flashcard_provider.dart';
import 'package:demon_teach/presentation/providers/quiz_provider.dart';
import 'package:demon_teach/presentation/providers/progress_provider.dart';
import 'package:demon_teach/data/repositories/assessment_repository_impl.dart';
import 'package:demon_teach/data/repositories/goal_repository_impl.dart';
import 'package:demon_teach/data/repositories/learning_path_repository_impl.dart';
import 'package:demon_teach/data/repositories/lesson_repository_impl.dart';
import 'package:demon_teach/data/repositories/flashcard_repository_impl.dart';
import 'package:demon_teach/data/repositories/quiz_repository_impl.dart';
import 'package:demon_teach/data/repositories/progress_repository_impl.dart';
import 'package:demon_teach/data/repositories/review_repository_impl.dart';
import 'package:demon_teach/data/repositories/performance_repository_impl.dart';
import 'package:demon_teach/domain/services/progress_tracker.dart';
import 'package:demon_teach/domain/services/performance_analyzer.dart';
import 'package:demon_teach/domain/usecases/progress/update_progress.dart';
import 'package:demon_teach/presentation/providers/review_provider.dart';
import 'package:demon_teach/presentation/providers/performance_provider.dart';
import 'package:demon_teach/presentation/providers/achievement_provider.dart';
import 'package:demon_teach/data/repositories/achievement_repository_impl.dart';
import 'package:demon_teach/domain/services/achievement_engine.dart';
import 'package:demon_teach/domain/usecases/achievement/check_and_unlock_achievements.dart';
import 'package:demon_teach/presentation/providers/speaking_provider.dart';
import 'package:demon_teach/data/repositories/speaking_repository_impl.dart';
import 'package:demon_teach/presentation/providers/listening_provider.dart';
import 'package:demon_teach/data/repositories/listening_repository_impl.dart';
import 'package:demon_teach/data/datasources/local/sync_local_datasource.dart';
import 'package:demon_teach/data/datasources/remote/sync_remote_datasource.dart';
import 'package:demon_teach/data/repositories/sync_repository_impl.dart';
import 'package:demon_teach/domain/services/sync_manager.dart';
import 'package:demon_teach/presentation/providers/sync_provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Pass all uncaught "fatal" errors from the framework to Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Initialize SharedPreferences and Secure Storage
  final sharedPreferences = await SharedPreferences.getInstance();
  const secureStorage = FlutterSecureStorage();

  // Initialize Dio
  final dio = Dio(BaseOptions(
    baseUrl: AppConstants.apiBaseUrl,
    connectTimeout: AppConstants.apiTimeout,
    receiveTimeout: AppConstants.apiTimeout,
  ));

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          final token = await secureStorage.read(key: 'auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        } catch (e) {
          // Ignore secure storage errors
        }
        return handler.next(options);
      },
    ),
  );

  // Create data source instances
  final lessonRemoteDataSource = LessonRemoteDataSourceImpl(dio: dio);
  final syncLocalDataSource = SyncLocalDataSourceImpl();
  final syncRemoteDataSource = SyncRemoteDataSourceImpl(dio: dio);

  // Create repository instances
  final authRepository = AuthRepositoryImpl(dio, secureStorage, sharedPreferences);
  final learningPathRepository = LearningPathRepositoryImpl(sharedPreferences);
  final lessonRepository =
      LessonRepositoryImpl(sharedPreferences, learningPathRepository, lessonRemoteDataSource);
  final flashcardRepository = FlashcardRepositoryImpl(sharedPreferences);
  final quizRepository = QuizRepositoryImpl(sharedPreferences);
  final progressTracker = ProgressTracker();
  final progressRepository =
      ProgressRepositoryImpl(sharedPreferences, progressTracker);
  final reviewRepository = ReviewRepositoryImpl(sharedPreferences);
  final performanceAnalyzer = PerformanceAnalyzer();
  final performanceRepository = PerformanceRepositoryImpl(sharedPreferences);
  final achievementEngine = AchievementEngine();
  final achievementRepository =
      AchievementRepositoryImpl(sharedPreferences, achievementEngine);
  final speakingRepository = SpeakingRepositoryImpl(sharedPreferences);
  final listeningRepository = ListeningRepositoryImpl(sharedPreferences);
  final syncRepository = SyncRepositoryImpl(
    localDataSource: syncLocalDataSource,
    remoteDataSource: syncRemoteDataSource,
  );
  final syncManager = SyncManager(syncRepository);

  runApp(
    ProviderScope(
      overrides: [
        // Override SharedPreferences provider with initialized instance
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        // Override AuthRepository provider
        authRepositoryProvider.overrideWithValue(authRepository),
        // Override AssessmentRepository provider
        assessmentRepositoryProvider.overrideWithValue(
          AssessmentRepositoryImpl(sharedPreferences),
        ),
        // Override GoalRepository provider
        goalRepositoryProvider.overrideWithValue(
          GoalRepositoryImpl(sharedPreferences),
        ),
        // Override LearningPathRepository provider
        learningPathRepositoryProvider
            .overrideWithValue(learningPathRepository),
        // Override LessonRepository provider
        lessonRepositoryProvider.overrideWithValue(lessonRepository),
        // Override FlashcardRepository provider
        flashcardRepositoryProvider.overrideWithValue(flashcardRepository),
        // Override QuizRepository provider
        quizRepositoryProvider.overrideWithValue(quizRepository),
        // Override ProgressRepository provider
        progressRepositoryProvider.overrideWithValue(progressRepository),
        // Override UpdateProgress use case provider
        updateProgressProvider.overrideWithValue(
          UpdateProgress(progressRepository, progressTracker),
        ),
        // Override ReviewRepository provider
        reviewRepositoryProvider.overrideWithValue(reviewRepository),
        // Override PerformanceRepository provider
        performanceRepositoryProvider.overrideWithValue(performanceRepository),
        // Override PerformanceAnalyzer provider
        performanceAnalyzerProvider.overrideWithValue(performanceAnalyzer),
        // Override AchievementRepository provider
        achievementRepositoryProvider.overrideWithValue(achievementRepository),
        // Override AchievementEngine provider
        achievementEngineProvider.overrideWithValue(achievementEngine),
        // Override CheckAndUnlockAchievements provider
        checkAndUnlockAchievementsProvider.overrideWithValue(
          CheckAndUnlockAchievements(
            achievementRepository,
            progressRepository,
            achievementEngine,
          ),
        ),
        // Override SpeakingRepository provider
        speakingRepositoryProvider.overrideWithValue(speakingRepository),
        // Override ListeningRepository provider
        listeningRepositoryProvider.overrideWithValue(listeningRepository),
        // Override SyncRepository provider
        syncRepositoryProvider.overrideWithValue(syncRepository),
        // Override SyncManager provider
        syncManagerProvider.overrideWithValue(syncManager),
      ],
      child: const DemonTeachApp(),
    ),
  );
}

class DemonTeachApp extends StatelessWidget {
  const DemonTeachApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AppInitializer(),
    );
  }
}

/// App initializer that determines initial route
class AppInitializer extends ConsumerWidget {
  const AppInitializer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final languageState = ref.watch(languageProvider);

    // Show splash while loading
    if (authState.isLoading || languageState.isLoading) {
      return const SplashScreen();
    }

    // If not authenticated, show login
    if (!authState.isAuthenticated) {
      return const LoginScreen();
    }

    // If no language preference, show language selection
    if (languageState.preference == null) {
      return const LanguageSelectionScreen();
    }

    // Return main layout
    return const MainScreen();
  }
}

/// Temporary splash screen
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.school,
              size: 100,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              AppConstants.appName,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: AppTheme.primaryColor,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              'AI-Powered Language Learning',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingXl),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
