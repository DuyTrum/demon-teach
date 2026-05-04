import 'package:flutter/material.dart';
import 'package:demon_teach/core/theme/app_theme.dart';
import 'package:demon_teach/domain/entities/quiz.dart';

/// Quiz result screen showing score and review
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
      appBar: AppBar(
        title: const Text('Quiz Results'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
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
    );
  }

  Widget _buildScoreCard(BuildContext context) {
    final passed = result.passed;
    final color = passed ? AppTheme.successColor : AppTheme.errorColor;

    return Card(
      elevation: AppTheme.elevationMd,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          children: [
            Icon(
              passed ? Icons.celebration : Icons.sentiment_dissatisfied,
              size: 80,
              color: color,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              passed ? 'Congratulations!' : 'Keep Practicing!',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              passed
                  ? 'You passed the quiz!'
                  : 'You need ${quiz.passingScore}% to pass',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              child: Column(
                children: [
                  Text(
                    '${result.percentage.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  Text(
                    '${result.totalScore} / ${result.maxScore} points',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.textSecondaryColor,
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

  Widget _buildPerformanceStats(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Summary',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            _buildStatRow(
              context,
              'Total Questions',
              '${quiz.questionCount}',
              Icons.quiz,
            ),
            _buildStatRow(
              context,
              'Correct Answers',
              '${result.correctCount}',
              Icons.check_circle,
              color: AppTheme.successColor,
            ),
            _buildStatRow(
              context,
              'Incorrect Answers',
              '${result.incorrectCount}',
              Icons.cancel,
              color: AppTheme.errorColor,
            ),
            _buildStatRow(
              context,
              'Accuracy',
              '${result.percentage.toStringAsFixed(1)}%',
              Icons.analytics,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
      child: Row(
        children: [
          Icon(
            icon,
            color: color ?? AppTheme.primaryColor,
            size: 24,
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color ?? AppTheme.textPrimaryColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewSection(BuildContext context) {
    final incorrectAnswers = result.answers.where((a) => !a.isCorrect).toList();

    if (incorrectAnswers.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Column(
            children: [
              const Icon(
                Icons.star,
                size: 60,
                color: AppTheme.accentColor,
              ),
              const SizedBox(height: AppTheme.spacingMd),
              Text(
                'Perfect Score!',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                'You answered all questions correctly!',
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppTheme.warningColor,
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Text(
                  'Review Incorrect Answers',
                  style: Theme.of(context).textTheme.titleLarge,
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
        color: AppTheme.errorColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: AppTheme.errorColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.questionText,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.cancel,
                color: AppTheme.errorColor,
                size: 20,
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  'Your answer: ${answer.userAnswer}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.errorColor,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.check_circle,
                color: AppTheme.successColor,
                size: 20,
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  'Correct answer: ${question.correctAnswer}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.successColor,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingSm),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Text(
              question.explanation,
              style: Theme.of(context).textTheme.bodySmall,
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
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onComplete!();
            },
            child: const Text('Continue'),
          ),
        if (onRetry != null) ...[
          const SizedBox(height: AppTheme.spacingMd),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('Retry Quiz'),
          ),
        ],
      ],
    );
  }
}
