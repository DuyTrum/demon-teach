import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:demon_teach/core/theme/app_theme.dart';
import 'package:demon_teach/domain/entities/review_item.dart';
import 'package:demon_teach/presentation/providers/review_provider.dart';
import 'package:demon_teach/presentation/screens/review/review_session_screen.dart';
import 'package:demon_teach/presentation/widgets/common/demon_background_particles.dart';
import 'package:intl/intl.dart';
import 'package:demon_teach/presentation/providers/lesson_provider.dart';
import 'package:demon_teach/presentation/providers/language_provider.dart';
import 'package:demon_teach/presentation/screens/lesson/daily_lesson_screen.dart';

/// Review queue screen showing upcoming review items (Demon Theme)
class ReviewQueueScreen extends ConsumerStatefulWidget {
  final String userId;

  const ReviewQueueScreen({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<ReviewQueueScreen> createState() => _ReviewQueueScreenState();
}

class _ReviewQueueScreenState extends ConsumerState<ReviewQueueScreen> {
  bool _isGeneratingAi = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reviewProvider.notifier).loadAllReviews(widget.userId);
      ref.read(reviewProvider.notifier).loadDueReviewCount(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final reviewState = ref.watch(reviewProvider);

    return Scaffold(
      backgroundColor: AppTheme.demonBgGradientBot,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Hàng chờ ôn tập',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.demonGlowPurple),
            onPressed: () {
              ref.read(reviewProvider.notifier).loadAllReviews(widget.userId);
              ref.read(reviewProvider.notifier).loadDueReviewCount(widget.userId);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Dark Gradient Background
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
          
          // Eerie Particles
          const Positioned.fill(
            child: DemonBackgroundParticles(),
          ),

          // Main Content
          SafeArea(
            child: reviewState.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.demonGlowPurple),
                  )
                : reviewState.error != null
                    ? _buildErrorState(reviewState.error!)
                    : _buildReviewQueue(reviewState),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (reviewState.dueCount > 0)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.demonGlowPurple.withOpacity(0.4),
                    blurRadius: 15,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: FloatingActionButton.extended(
                heroTag: 'start_review',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ReviewSessionScreen(userId: widget.userId),
                    ),
                  );
                },
                backgroundColor: AppTheme.demonGlowPurple,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.play_arrow),
                label: Text(
                  'Bắt đầu ôn tập (${reviewState.dueCount})',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          
          // AI Review Generator Button
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.demonGlowGreen.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                )
              ],
            ),
            child: FloatingActionButton.extended(
              heroTag: 'generate_ai_review',
              onPressed: _isGeneratingAi ? null : _generateAiReview,
              backgroundColor: AppTheme.demonNodeLocked,
              foregroundColor: AppTheme.demonGlowGreen,
              icon: _isGeneratingAi 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: AppTheme.demonGlowGreen, strokeWidth: 2))
                  : const Icon(Icons.auto_awesome),
              label: const Text(
                'Tạo Bài Ôn Tập AI',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateAiReview() async {
    setState(() {
      _isGeneratingAi = true;
    });

    try {
      final langPref = ref.read(languageProvider).preference;
      final targetLang = langPref?.targetLanguage ?? 'en';
      
      final lessonRepo = ref.read(lessonRepositoryProvider);
      
      final result = await lessonRepo.generateLesson(
        id: 'review_ai_${DateTime.now().millisecondsSinceEpoch}',
        topic: 'AI Review & Reinforcement',
        language: targetLang,
        difficulty: 'intermediate', // Auto-adjust based on progress
        goalType: 'review',
      );

      if (mounted) {
        setState(() {
          _isGeneratingAi = false;
        });

        result.when(
          success: (lesson) {
            // Set custom lesson
            ref.read(lessonProvider.notifier).setCustomLesson(lesson);
            
            // Navigate to DailyLessonScreen
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const DailyLessonScreen()),
            );
          },
          failure: (failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Không thể tạo bài ôn tập AI: ${failure.message}')),
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGeneratingAi = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.redAccent,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            'Lỗi: $error',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingLg),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.demonGlowPurple,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              ref.read(reviewProvider.notifier).clearError();
              ref.read(reviewProvider.notifier).loadAllReviews(widget.userId);
            },
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewQueue(ReviewState reviewState) {
    if (reviewState.allReviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.demonGlowPurple.withOpacity(0.2),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.demonGlowPurple.withOpacity(0.4),
                        blurRadius: 30,
                        spreadRadius: 10,
                      )
                    ],
                  ),
                ),
                const Icon(
                  Icons.auto_awesome,
                  size: 60,
                  color: Colors.white,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingXl),
            const Text(
              'Chưa có mục ôn tập nào',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              'Kiến thức ác quỷ của bạn đang rất vững chắc.\nHãy quay lại sau để củng cố thêm.',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.demonTextMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Group reviews by status (due, upcoming)
    final dueReviews = reviewState.allReviews.where((item) => item.isDue).toList();
    final upcomingReviews = reviewState.allReviews.where((item) => !item.isDue).toList();

    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      physics: const BouncingScrollPhysics(),
      children: [
        // Summary card
        _buildSummaryCard(dueReviews.length, upcomingReviews.length),
        const SizedBox(height: AppTheme.spacingLg),

        // Due reviews section
        if (dueReviews.isNotEmpty) ...[
          _buildSectionHeader('Cần ôn ngay', dueReviews.length, isDue: true),
          const SizedBox(height: AppTheme.spacingMd),
          ...dueReviews.map((item) => _buildReviewItemCard(item, isDue: true)),
          const SizedBox(height: AppTheme.spacingLg),
        ],

        // Upcoming reviews section
        if (upcomingReviews.isNotEmpty) ...[
          _buildSectionHeader('Sắp tới', upcomingReviews.length, isDue: false),
          const SizedBox(height: AppTheme.spacingMd),
          ...upcomingReviews.map((item) => _buildReviewItemCard(item, isDue: false)),
        ],
      ],
    );
  }

  Widget _buildSummaryCard(int dueCount, int upcomingCount) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.demonNodeLocked.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Cần ôn ngay',
                  dueCount.toString(),
                  Colors.redAccent,
                  Icons.local_fire_department,
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: Colors.white.withOpacity(0.1),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Sắp tới',
                  upcomingCount.toString(),
                  AppTheme.demonGlowPurple,
                  Icons.hourglass_empty,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: AppTheme.spacingSm),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
            shadows: [
              Shadow(
                color: color.withOpacity(0.5),
                blurRadius: 10,
              )
            ],
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.demonTextMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count, {required bool isDue}) {
    final color = isDue ? Colors.redAccent : AppTheme.demonGlowPurple;
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: AppTheme.spacingSm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewItemCard(ReviewItem item, {required bool isDue}) {
    final dateFormat = DateFormat('MMM d');
    final timeFormat = DateFormat('h:mm a');

    final glowColor = isDue ? Colors.redAccent : AppTheme.demonGlowPurple;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.demonNodeLocked.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDue ? glowColor.withOpacity(0.3) : Colors.white.withOpacity(0.05),
        ),
        boxShadow: isDue
            ? [
                BoxShadow(
                  color: glowColor.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      child: ListTile(
        onTap: () {
          if (isDue) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ReviewSessionScreen(userId: item.userId),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Bài tập này chưa đến hạn ôn.'),
                backgroundColor: Colors.orangeAccent,
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: _buildReviewTypeIcon(item.type, glowColor),
        title: Text(
          item.type.displayName,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Độ dễ: ${item.easeFactor.toStringAsFixed(1)} | Lần ôn: ${item.repetitionCount}',
              style: TextStyle(color: AppTheme.demonTextMuted, fontSize: 12),
            ),
            const SizedBox(height: 2),
            Text(
              isDue
                  ? 'Hạn: Ngay bây giờ'
                  : 'Hạn: ${dateFormat.format(item.nextReviewDate)} lúc ${timeFormat.format(item.nextReviewDate)}',
              style: TextStyle(
                color: isDue ? Colors.redAccent : AppTheme.demonTextMuted,
                fontWeight: isDue ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: isDue
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                ),
                child: const Text(
                  'CẦN ÔN',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : _buildIntervalBadge(item.intervalDays),
      ),
    );
  }

  Widget _buildReviewTypeIcon(ReviewItemType type, Color color) {
    IconData icon;
    switch (type) {
      case ReviewItemType.flashcard:
        icon = Icons.style;
        break;
      case ReviewItemType.quiz:
        icon = Icons.quiz;
        break;
      case ReviewItemType.listening:
        icon = Icons.headphones;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildIntervalBadge(int days) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.demonGlowPurple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.demonGlowPurple.withOpacity(0.3)),
      ),
      child: Text(
        '+$days ngày',
        style: const TextStyle(
          color: AppTheme.demonGlowPurple,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

