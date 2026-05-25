import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:demon_teach/core/theme/app_theme.dart';
import 'package:demon_teach/domain/entities/lesson.dart';
import 'package:demon_teach/presentation/providers/lesson_provider.dart';
import 'package:demon_teach/presentation/providers/language_provider.dart';
import 'package:demon_teach/presentation/providers/auth_provider.dart';
import 'package:demon_teach/presentation/widgets/common/custom_button.dart';
import 'package:demon_teach/presentation/screens/learning_path/learning_path_screen.dart';
import 'package:demon_teach/presentation/providers/learning_path_provider.dart';
import 'package:demon_teach/presentation/providers/progress_provider.dart';
import 'package:demon_teach/presentation/providers/achievement_provider.dart';

class LessonCompletionScreen extends ConsumerStatefulWidget {
  final Lesson lesson;
  final int score;
  final int timeSpent; // in seconds

  const LessonCompletionScreen({
    super.key,
    required this.lesson,
    required this.score,
    required this.timeSpent,
  });

  @override
  ConsumerState<LessonCompletionScreen> createState() =>
      _LessonCompletionScreenState();
}

class _LessonCompletionScreenState extends ConsumerState<LessonCompletionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isCompleting = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );

    _animationController.forward();
    // Delay lesson completion to avoid modifying provider during build
    Future.microtask(() => _completeLesson());
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _completeLesson() async {
    setState(() {
      _isCompleting = true;
    });

    final user = ref.read(authProvider).user;
    final languageState = ref.read(languageProvider);
    if (user == null || languageState.preference == null) return;

    final targetLanguage = languageState.preference!.targetLanguage;

    // 1. Mark lesson as complete and update current index of learning path on local DB
    await ref.read(lessonProvider.notifier).completeCurrentLesson(
          userId: user.id,
          score: widget.score,
          targetLanguage: targetLanguage,
        );

    // 2. Update overall progress details (totalXP, lessonsCompleted, levels)
    await ref.read(progressProvider.notifier).updateProgressAfterLesson(
          userId: user.id,
          targetLanguage: targetLanguage,
          score: widget.score,
        );

    // 3. Reload learning path to ensure we have the next lesson loaded properly
    await ref.read(learningPathProvider.notifier).loadLearningPath(
          userId: user.id,
          targetLanguage: targetLanguage,
        );

    // 4. Check & Unlock achievements based on the updated progress
    await ref.read(achievementProvider.notifier).checkAndUnlock(
          userId: user.id,
          targetLanguage: targetLanguage,
        );

    setState(() {
      _isCompleting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success animation
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppTheme.successColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.successColor.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: AppTheme.spacingXl),

              // Congratulations text
              Text(
                'Lesson Complete!',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppTheme.spacingSm),

              Text(
                'Great job! You\'ve completed this lesson.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppTheme.spacingXl),

              // Stats cards
              _buildStatsCard(),

              const SizedBox(height: AppTheme.spacingXl),

              // Lesson info
              _buildLessonInfo(),

              const Spacer(),

              // Action buttons
              if (!_isCompleting) ...[
                CustomButton(
                  text: 'Continue Learning',
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  width: double.infinity,
                  icon: Icons.arrow_forward,
                ),
                const SizedBox(height: AppTheme.spacingSm),
                CustomButton(
                  text: 'Review Lesson',
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  isOutlined: true,
                  width: double.infinity,
                  icon: Icons.replay,
                ),
              ] else
                const Center(
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              icon: Icons.star,
              label: 'Score',
              value: '${widget.score}',
              color: AppTheme.warningColor,
            ),
            Container(
              width: 1,
              height: 50,
              color: AppTheme.surfaceColor,
            ),
            _buildStatItem(
              icon: Icons.timer,
              label: 'Time',
              value: _formatTime(widget.timeSpent),
              color: AppTheme.primaryColor,
            ),
            Container(
              width: 1,
              height: 50,
              color: AppTheme.surfaceColor,
            ),
            _buildStatItem(
              icon: Icons.emoji_events,
              label: 'XP',
              value: '+${_calculateXP()}',
              color: AppTheme.successColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: AppTheme.spacingSm),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
        ),
      ],
    );
  }

  Widget _buildLessonInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingSm),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Text(
                widget.lesson.metadata.category.icon,
                style: const TextStyle(fontSize: 32),
              ),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.lesson.metadata.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.lesson.metadata.category.displayName} • ${widget.lesson.metadata.difficulty.displayName}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.check_circle,
              color: AppTheme.successColor,
              size: 32,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes > 0) {
      return '$minutes min ${remainingSeconds}s';
    }
    return '${remainingSeconds}s';
  }

  int _calculateXP() {
    // Simple XP calculation: base 50 + score bonus
    return 50 + (widget.score ~/ 2);
  }
}
