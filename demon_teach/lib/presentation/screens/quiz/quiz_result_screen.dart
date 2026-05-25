import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:demon_teach/core/theme/app_theme.dart';
import 'package:demon_teach/domain/entities/quiz.dart';
import 'package:demon_teach/presentation/widgets/common/demon_background_particles.dart';

/// Quiz result screen showing score and review with Demon Theme
class QuizResultScreen extends StatelessWidget {
  final QuizResult result;
  final Quiz quiz;
  final VoidCallback? onRetry;
  final VoidCallback? onComplete;

  const QuizResultScreen({
    super.key,
    required this.result,
    required this.quiz,
    this.onRetry,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.demonBgGradientBot,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Kết quả làm bài',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
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

          // Particles
          const Positioned.fill(
            child: DemonBackgroundParticles(),
          ),

          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildScoreCard(context),
                  const SizedBox(height: AppTheme.spacingXl),
                  _buildPerformanceStats(context),
                  const SizedBox(height: AppTheme.spacingXl),
                  _buildReviewSection(context),
                  const SizedBox(height: AppTheme.spacingXl),
                  _buildActionButtons(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(BuildContext context) {
    final passed = result.passed;
    final color = passed ? Colors.greenAccent : Colors.redAccent;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.demonCardDark.withOpacity(0.7),
            AppTheme.demonBgGradientTop.withOpacity(0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingXl),
            child: Column(
              children: [
                Icon(
                  passed ? Icons.emoji_events_rounded : Icons.sentiment_very_dissatisfied_rounded,
                  size: 90,
                  color: color,
                ),
                const SizedBox(height: AppTheme.spacingMd),
                Text(
                  passed ? 'Xuất Sắc! 😈' : 'Cần Cố Gắng Hơn 😢',
                  style: TextStyle(
                    color: color,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingSm),
                Text(
                  passed
                      ? 'Bạn đã vượt qua bài kiểm tra ngày hôm nay!'
                      : 'Bạn cần đạt tối thiểu ${quiz.passingScore}% để vượt qua',
                  style: const TextStyle(
                    color: AppTheme.demonTextMuted,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingLg),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.4)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${result.percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: color,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: color,
                              blurRadius: 15,
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingSm),
                      Text(
                        'Điểm: ${result.totalScore} / ${result.maxScore}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPerformanceStats(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.demonCardDark.withOpacity(0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tóm tắt hiệu suất',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                _buildStatRow(
                  context,
                  'Tổng số câu hỏi',
                  '${quiz.questionCount}',
                  Icons.help_outline_rounded,
                  color: Colors.white,
                ),
                _buildStatRow(
                  context,
                  'Trả lời đúng',
                  '${result.correctCount}',
                  Icons.check_circle_outline_rounded,
                  color: Colors.greenAccent,
                ),
                _buildStatRow(
                  context,
                  'Trả lời sai',
                  '${result.incorrectCount}',
                  Icons.highlight_off_rounded,
                  color: Colors.redAccent,
                ),
                _buildStatRow(
                  context,
                  'Tỷ lệ chính xác',
                  '${result.percentage.toStringAsFixed(1)}%',
                  Icons.insights_rounded,
                  color: AppTheme.demonGlowPurple,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.demonTextLight,
                fontSize: 15,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewSection(BuildContext context) {
    final incorrectAnswers = result.answers.where((a) => !a.isCorrect).toList();

    if (incorrectAnswers.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Column(
            children: [
              const Icon(
                Icons.stars_rounded,
                size: 60,
                color: Colors.greenAccent,
              ),
              const SizedBox(height: AppTheme.spacingMd),
              const Text(
                'Điểm Số Tuyệt Đối! 😈',
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppTheme.spacingSm),
              const Text(
                'Bạn đã trả lời chính xác tất cả các câu hỏi!',
                style: TextStyle(
                  color: AppTheme.demonTextMuted,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.demonCardDark.withOpacity(0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orangeAccent,
                ),
                const SizedBox(width: AppTheme.spacingSm),
                const Text(
                  'Xem lại các câu sai',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),
            ...incorrectAnswers.map((answer) {
              final question = quiz.questions.firstWhere(
                (q) => q.id == answer.questionId,
              );
              return _buildIncorrectAnswerItem(context, question, answer);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildIncorrectAnswerItem(
    BuildContext context,
    QuizQuestion question,
    QuizAnswer answer,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.redAccent.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.questionText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.cancel_rounded,
                color: Colors.redAccent,
                size: 18,
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  'Đáp án của bạn: ${answer.userAnswer}',
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.greenAccent,
                size: 18,
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  'Đáp án đúng: ${question.correctAnswer}',
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.spacingSm),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Text(
              question.explanation,
              style: const TextStyle(
                color: AppTheme.demonTextMuted,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (onComplete != null)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [AppTheme.demonGlowPurple, AppTheme.primaryColor],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.demonGlowPurple.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onComplete!();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Tiếp tục hành trình 😈',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        if (onRetry != null) ...[
          const SizedBox(height: AppTheme.spacingMd),
          OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.demonGlowPurple,
              side: const BorderSide(color: AppTheme.demonGlowPurple, width: 2),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Làm lại bài thi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
