import 'dart:ui';
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
import 'package:demon_teach/core/services/audio_feedback_service.dart';
import 'package:demon_teach/presentation/widgets/common/demon_background_particles.dart';

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

    // Play meme sound for completion
    ref.read(audioFeedbackServiceProvider).playLessonCompleteSfx();

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
      backgroundColor: AppTheme.demonBgGradientBot,
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.demonBgGradientTop,
                  AppTheme.demonBgGradientMid,
                  AppTheme.demonBgGradientBot,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Eerie particles
          const Positioned.fill(child: DemonBackgroundParticles()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  // Success animation
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppTheme.demonGlowGreen,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.demonGlowGreen.withOpacity(0.4),
                            blurRadius: 25,
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
                  const Text(
                    'Hoàn thành bài học! 😈',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(color: AppTheme.demonGlowPurple, blurRadius: 15),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: AppTheme.spacingSm),

                  const Text(
                    'Làm tốt lắm! Ngươi đã hoàn thành thử thách hôm nay.',
                    style: TextStyle(
                      color: AppTheme.demonTextMuted,
                      fontSize: 15,
                      fontStyle: FontStyle.italic,
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
                      text: 'Tiếp tục hành trình',
                      onPressed: () {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      width: double.infinity,
                      icon: Icons.arrow_forward,
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    CustomButton(
                      text: 'Xem lại bài học',
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      isOutlined: true,
                      width: double.infinity,
                      icon: Icons.replay,
                    ),
                  ] else
                    const Center(
                      child: CircularProgressIndicator(color: AppTheme.demonGlowPurple),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.demonNodeLocked.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.star,
                label: 'Điểm số',
                value: '${widget.score}',
                color: Colors.orangeAccent,
              ),
              Container(
                width: 1,
                height: 50,
                color: Colors.white.withOpacity(0.1),
              ),
              _buildStatItem(
                icon: Icons.timer,
                label: 'Thời gian',
                value: _formatTime(widget.timeSpent),
                color: AppTheme.demonGlowPurple,
              ),
              Container(
                width: 1,
                height: 50,
                color: Colors.white.withOpacity(0.1),
              ),
              _buildStatItem(
                icon: Icons.emoji_events,
                label: 'XP',
                value: '+${_calculateXP()}',
                color: AppTheme.demonGlowGreen,
              ),
            ],
          ),
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
        Icon(icon, color: color, size: 30),
        const SizedBox(height: AppTheme.spacingSm),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 20,
            shadows: [Shadow(color: color.withOpacity(0.3), blurRadius: 5)],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.demonTextMuted,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildLessonInfo() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.demonCardDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.demonGlowPurple.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingSm),
            decoration: BoxDecoration(
              color: AppTheme.demonGlowPurple.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.demonGlowPurple.withOpacity(0.3)),
            ),
            child: Text(
              widget.lesson.metadata.category.icon,
              style: const TextStyle(fontSize: 30),
            ),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.lesson.metadata.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.lesson.metadata.category.displayName} • ${widget.lesson.metadata.difficulty.displayName}',
                  style: const TextStyle(
                    color: AppTheme.demonTextMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.check_circle,
            color: AppTheme.demonGlowGreen,
            size: 32,
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes > 0) {
      return '$minutes p ${remainingSeconds}s';
    }
    return '${remainingSeconds}s';
  }

  int _calculateXP() {
    // Simple XP calculation: base 50 + score bonus
    return 50 + (widget.score ~/ 2);
  }
}
