import 'package:flutter/material.dart';
import 'package:demon_teach/core/theme/app_theme.dart';
import 'package:demon_teach/domain/entities/listening_exercise.dart';

/// Listening exercise result screen
class ListeningResultScreen extends StatelessWidget {
  final ListeningResult result;
  final ListeningExercise exercise;
  final VoidCallback? onRetry;
  final VoidCallback? onComplete;

  const ListeningResultScreen({
    super.key,
    required this.result,
    required this.exercise,
    this.onRetry,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listening Results'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildScoreCard(context),
            const SizedBox(height: AppTheme.spacingXl),
            _buildStatistics(context),
            const SizedBox(height: AppTheme.spacingXl),
            _buildAnswerReview(context),
            const SizedBox(height: AppTheme.spacingXl),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard(BuildContext context) {
    final percentage = result.percentage;
    Color scoreColor;
    IconData scoreIcon;
    String scoreMessage;

    if (percentage >= 90) {
      scoreColor = AppTheme.successColor;
      scoreIcon = Icons.sentiment_very_satisfied;
      scoreMessage = 'Excellent!';
    } else if (percentage >= 75) {
      scoreColor = Colors.lightGreen;
      scoreIcon = Icons.sentiment_satisfied;
      scoreMessage = 'Great job!';
    } else if (percentage >= 60) {
      scoreColor = AppTheme.warningColor;
      scoreIcon = Icons.sentiment_neutral;
      scoreMessage = 'Good effort!';
    } else {
      scoreColor = AppTheme.errorColor;
      scoreIcon = Icons.sentiment_dissatisfied;
      scoreMessage = 'Keep practicing!';
    }

    return Card(
      elevation: AppTheme.elevationMd,
      color: scoreColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          children: [
            Icon(
              scoreIcon,
              size: 80,
              color: scoreColor,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              scoreMessage,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              '${percentage.toInt()}%',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              'Comprehension Score',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistics(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            _buildStatRow(
              context,
              icon: Icons.check_circle,
              iconColor: AppTheme.successColor,
              label: 'Correct Answers',
              value: '${result.correctCount}',
            ),
            const SizedBox(height: AppTheme.spacingSm),
            _buildStatRow(
              context,
              icon: Icons.cancel,
              iconColor: AppTheme.errorColor,
              label: 'Incorrect Answers',
              value: '${result.incorrectCount}',
            ),
            const SizedBox(height: AppTheme.spacingSm),
            _buildStatRow(
              context,
              icon: Icons.quiz,
              iconColor: AppTheme.primaryColor,
              label: 'Total Questions',
              value: '${result.totalQuestions}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 24),
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
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildAnswerReview(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Answer Review',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            ...exercise.questions.asMap().entries.map((entry) {
              final index = entry.key;
              final question = entry.value;
              final answer = result.answers.firstWhere(
                (a) => a.questionId == question.id,
              );

              return Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
                child: _buildAnswerReviewItem(
                  context,
                  questionNumber: index + 1,
                  question: question,
                  answer: answer,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerReviewItem(
    BuildContext context, {
    required int questionNumber,
    required ComprehensionQuestion question,
    required ComprehensionAnswer answer,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: answer.isCorrect
            ? AppTheme.successColor.withOpacity(0.05)
            : AppTheme.errorColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: answer.isCorrect
              ? AppTheme.successColor.withOpacity(0.3)
              : AppTheme.errorColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingSm),
                decoration: BoxDecoration(
                  color: answer.isCorrect
                      ? AppTheme.successColor
                      : AppTheme.errorColor,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$questionNumber',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Text(
                  question.questionText,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              Icon(
                answer.isCorrect ? Icons.check_circle : Icons.cancel,
                color: answer.isCorrect
                    ? AppTheme.successColor
                    : AppTheme.errorColor,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          if (!answer.isCorrect) ...[
            Text(
              'Your answer: ${answer.userAnswer}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.errorColor,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingXs),
          ],
          Text(
            'Correct answer: ${question.correctAnswer}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.successColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            question.explanation,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondaryColor,
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
            ),
            child: const Text(
              'Continue',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        else
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
            ),
            child: const Text(
              'Done',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        if (onRetry != null) ...[
          const SizedBox(height: AppTheme.spacingMd),
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry!();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
            ),
            child: const Text(
              'Try Again',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
