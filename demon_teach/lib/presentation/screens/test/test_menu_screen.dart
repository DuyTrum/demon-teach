import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:demon_teach/core/theme/app_theme.dart';
import 'package:demon_teach/presentation/screens/flashcard/flashcard_screen.dart';
import 'package:demon_teach/presentation/screens/quiz/quiz_screen.dart';
import 'package:demon_teach/presentation/screens/progress/progress_dashboard_screen.dart';
import 'package:demon_teach/presentation/screens/review/review_session_screen.dart';
import 'package:demon_teach/presentation/screens/review/review_queue_screen.dart';
import 'package:demon_teach/presentation/screens/achievement/achievement_gallery_screen.dart';
import 'package:demon_teach/presentation/screens/speaking/speaking_practice_screen.dart';
import 'package:demon_teach/presentation/screens/listening/listening_exercise_screen.dart';

/// Test menu screen for testing new modules
class TestMenuScreen extends StatelessWidget {
  const TestMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Menu'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        children: [
          _buildHeader(context),
          const SizedBox(height: AppTheme.spacingXl),
          _buildTestCard(
            context,
            title: 'Flashcard Module',
            description:
                'Test flashcard flip animation, difficulty rating, and navigation',
            icon: Icons.style,
            color: AppTheme.primaryColor,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const FlashcardScreen(
                    lessonId: 'en_basic_vocab_001',
                    onComplete: null,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppTheme.spacingMd),
          _buildTestCard(
            context,
            title: 'Quiz Module',
            description:
                'Test quiz questions, immediate feedback, and results screen',
            icon: Icons.quiz,
            color: AppTheme.secondaryColor,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const QuizScreen(
                    lessonId: 'en_basic_vocab_001',
                    onComplete: null,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppTheme.spacingMd),
          _buildTestCard(
            context,
            title: 'Progress Dashboard',
            description: 'Test XP, streak tracking, and milestone achievements',
            icon: Icons.analytics,
            color: AppTheme.accentColor,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ProgressDashboardScreen(
                    userId: 'user_001',
                    targetLanguage: 'en',
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppTheme.spacingMd),
          _buildTestCard(
            context,
            title: 'Review Session',
            description:
                'Test spaced repetition review session with SM-2 algorithm',
            icon: Icons.replay,
            color: AppTheme.successColor,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ReviewSessionScreen(
                    userId: 'user_001',
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppTheme.spacingMd),
          _buildTestCard(
            context,
            title: 'Review Queue',
            description: 'View upcoming review items and due reviews',
            icon: Icons.queue,
            color: Colors.purple,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ReviewQueueScreen(
                    userId: 'user_001',
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppTheme.spacingMd),
          _buildTestCard(
            context,
            title: 'Achievement Gallery',
            description:
                'View all achievements, progress, and unlock animations',
            icon: Icons.emoji_events,
            color: Colors.amber,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AchievementGalleryScreen(
                    userId: 'user_001',
                    targetLanguage: 'en',
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppTheme.spacingMd),
          _buildTestCard(
            context,
            title: 'Speaking Practice',
            description:
                'Test audio recording, pronunciation feedback, and playback',
            icon: Icons.mic,
            color: Colors.deepOrange,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SpeakingPracticeScreen(
                    lessonId: 'en_basic_vocab_001',
                    onComplete: null,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppTheme.spacingMd),
          _buildTestCard(
            context,
            title: 'Listening Exercise',
            description:
                'Test audio playback, comprehension questions, and results',
            icon: Icons.headphones,
            color: Colors.teal,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ListeningExerciseScreen(
                    lessonId: 'en_basic_vocab_001',
                    onComplete: null,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppTheme.spacingXl),
          // Crashlytics Test Section (Debug Only)
          if (kDebugMode) ...[
            _buildCrashlyticsTestSection(context),
            const SizedBox(height: AppTheme.spacingXl),
          ],
          _buildTestInfo(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Card(
      color: AppTheme.primaryColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          children: [
            const Icon(
              Icons.science,
              size: 60,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              'Phase 2 & 3 Module Testing',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              'Test Flashcard, Quiz, Progress, and Spaced Repetition modules',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: AppTheme.elevationMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: color,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: AppTheme.spacingXs),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondaryColor,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.textSecondaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTestInfo(BuildContext context) {
    return Card(
      color: AppTheme.warningColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppTheme.warningColor,
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Text(
                  'Test Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.warningColor,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingSm),
            _buildInfoItem(context, 'All modules use mock data for testing'),
            _buildInfoItem(context, 'Flashcards: 5 cards for English lesson'),
            _buildInfoItem(
                context, 'Quiz: 4 questions with immediate feedback'),
            _buildInfoItem(context, 'Progress: Simulated XP and streak data'),
            _buildInfoItem(context, 'Review: SM-2 spaced repetition algorithm'),
            _buildInfoItem(
                context, 'Achievements: Track milestones and earn XP'),
            _buildInfoItem(
                context, 'Speaking: Record and get pronunciation feedback'),
            _buildInfoItem(context,
                'Listening: Audio playback with comprehension questions'),
            _buildInfoItem(context, 'Audio playback shows placeholder toast'),
          ],
        ),
      ),
    );
  }

  Widget _buildCrashlyticsTestSection(BuildContext context) {
    return Card(
      color: Colors.red.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.bug_report,
                  color: Colors.red,
                  size: 30,
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Text(
                  'Firebase Crashlytics Test',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              'Test crash reporting to Firebase Console. These buttons will crash the app intentionally.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Test non-fatal error
                      FirebaseCrashlytics.instance.recordError(
                        Exception('Test non-fatal error from Demon Teach'),
                        StackTrace.current,
                        reason: 'Testing Crashlytics non-fatal error',
                        fatal: false,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Non-fatal error logged! Check Firebase Console in 5 minutes.'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    },
                    icon: const Icon(Icons.warning),
                    label: const Text('Log Error'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Show confirmation dialog before crashing
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Confirm Crash Test'),
                          content: const Text(
                              'This will crash the app. The crash report will appear in Firebase Console in 5-10 minutes. Continue?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                // Force crash
                                throw Exception(
                                    'Test fatal crash from Demon Teach');
                              },
                              child: const Text('Crash App'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.close),
                    label: const Text('Force Crash'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingSm),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, size: 16, color: Colors.blue),
                  const SizedBox(width: AppTheme.spacingXs),
                  Expanded(
                    child: Text(
                      'View crashes at: console.firebase.google.com/project/demon-teach/crashlytics',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.blue,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: AppTheme.spacingXs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
