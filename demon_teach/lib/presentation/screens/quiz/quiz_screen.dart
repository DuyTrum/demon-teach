import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:demon_teach/core/theme/app_theme.dart';
import 'package:demon_teach/domain/entities/quiz.dart';
import 'package:demon_teach/presentation/providers/quiz_provider.dart';
import 'package:demon_teach/presentation/widgets/common/loading_indicator.dart';
import 'package:demon_teach/presentation/widgets/common/error_message.dart';
import 'package:demon_teach/presentation/screens/quiz/quiz_result_screen.dart';

/// Quiz screen with immediate feedback
class QuizScreen extends ConsumerStatefulWidget {
  final String lessonId;
  final VoidCallback? onComplete;

  const QuizScreen({
    super.key,
    required this.lessonId,
    this.onComplete,
  });

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  String? _selectedAnswer;

  @override
  void initState() {
    super.initState();
    // Load quiz
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(quizProvider.notifier).loadQuiz(widget.lessonId);
    });
  }

  void _handleAnswerSelection(String answer) {
    setState(() {
      _selectedAnswer = answer;
    });
  }

  void _handleSubmitAnswer() {
    if (_selectedAnswer == null) return;

    ref.read(quizProvider.notifier).answerQuestion(_selectedAnswer!);
  }

  void _handleNext() {
    ref.read(quizProvider.notifier).nextQuestion();
    setState(() {
      _selectedAnswer = null;
    });
  }

  void _handleSubmitQuiz() async {
    await ref.read(quizProvider.notifier).submitQuiz();

    // Navigate to results screen
    if (mounted) {
      final result = ref.read(quizProvider).result;
      if (result != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => QuizResultScreen(
              result: result,
              quiz: ref.read(quizProvider).quiz!,
              onRetry: () {
                ref.read(quizProvider.notifier).reset();
                Navigator.of(context).pop();
              },
              onComplete: widget.onComplete,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quizProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz'),
        actions: [
          if (state.quiz != null)
            Padding(
              padding: const EdgeInsets.only(right: AppTheme.spacingMd),
              child: Center(
                child: Text(
                  '${state.currentQuestionNumber}/${state.totalQuestions}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(context, state),
    );
  }

  Widget _buildBody(BuildContext context, QuizState state) {
    if (state.isLoading) {
      return const Center(child: LoadingIndicator());
    }

    if (state.error != null) {
      return Center(
        child: ErrorMessage(
          message: state.error!,
          onRetry: () {
            ref.read(quizProvider.notifier).loadQuiz(widget.lessonId);
          },
        ),
      );
    }

    if (state.quiz == null) {
      return const Center(
        child: Text('No quiz available for this lesson.'),
      );
    }

    return Column(
      children: [
        // Progress indicator
        _buildProgressIndicator(state),

        // Question content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildQuestion(context, state),
                const SizedBox(height: AppTheme.spacingXl),
                _buildAnswerOptions(context, state),
                if (state.showFeedback) ...[
                  const SizedBox(height: AppTheme.spacingXl),
                  _buildFeedback(context, state),
                ],
              ],
            ),
          ),
        ),

        // Action buttons
        _buildActionButtons(context, state),
      ],
    );
  }

  Widget _buildProgressIndicator(QuizState state) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: state.currentQuestionNumber / state.totalQuestions,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            'Question ${state.currentQuestionNumber} of ${state.totalQuestions}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion(BuildContext context, QuizState state) {
    final question = state.currentQuestion;
    if (question == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMd,
                vertical: AppTheme.spacingSm,
              ),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Text(
                question.type.displayName,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              question.questionText,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerOptions(BuildContext context, QuizState state) {
    final question = state.currentQuestion;
    if (question == null) return const SizedBox.shrink();

    final currentAnswer = state.getUserAnswer(question.id);
    final isAnswered = currentAnswer != null;

    if (question.type == QuestionType.fillInBlank) {
      return _buildFillInBlankInput(context, state, isAnswered);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: question.options.map((option) {
        final isSelected = _selectedAnswer == option;
        final isCorrect = option == question.correctAnswer;
        final showCorrectness = state.showFeedback && isAnswered;

        Color? backgroundColor;
        Color? borderColor;
        if (showCorrectness) {
          if (isCorrect) {
            backgroundColor = AppTheme.successColor.withOpacity(0.1);
            borderColor = AppTheme.successColor;
          } else if (isSelected && !isCorrect) {
            backgroundColor = AppTheme.errorColor.withOpacity(0.1);
            borderColor = AppTheme.errorColor;
          }
        } else if (isSelected) {
          backgroundColor = AppTheme.primaryColor.withOpacity(0.1);
          borderColor = AppTheme.primaryColor;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
          child: InkWell(
            onTap: state.showFeedback
                ? null
                : () => _handleAnswerSelection(option),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: Container(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              decoration: BoxDecoration(
                color: backgroundColor ?? Colors.white,
                border: Border.all(
                  color: borderColor ?? Colors.grey[300]!,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      option,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  if (showCorrectness && isCorrect)
                    const Icon(Icons.check_circle,
                        color: AppTheme.successColor),
                  if (showCorrectness && isSelected && !isCorrect)
                    const Icon(Icons.cancel, color: AppTheme.errorColor),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFillInBlankInput(
      BuildContext context, QuizState state, bool isAnswered) {
    return TextField(
      enabled: !state.showFeedback,
      onChanged: (value) {
        setState(() {
          _selectedAnswer = value;
        });
      },
      decoration: InputDecoration(
        hintText: 'Type your answer here...',
        suffixIcon: state.showFeedback
            ? Icon(
                state.isAnsweredCorrectly(state.currentQuestion!.id) ?? false
                    ? Icons.check_circle
                    : Icons.cancel,
                color: state.isAnsweredCorrectly(state.currentQuestion!.id) ??
                        false
                    ? AppTheme.successColor
                    : AppTheme.errorColor,
              )
            : null,
      ),
    );
  }

  Widget _buildFeedback(BuildContext context, QuizState state) {
    final question = state.currentQuestion;
    if (question == null) return const SizedBox.shrink();

    final isCorrect = state.isAnsweredCorrectly(question.id) ?? false;

    return Card(
      color: isCorrect
          ? AppTheme.successColor.withOpacity(0.1)
          : AppTheme.errorColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isCorrect ? Icons.check_circle : Icons.cancel,
                  color:
                      isCorrect ? AppTheme.successColor : AppTheme.errorColor,
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Text(
                  isCorrect ? 'Correct!' : 'Incorrect',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: isCorrect
                            ? AppTheme.successColor
                            : AppTheme.errorColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              question.explanation,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, QuizState state) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: state.showFeedback
            ? _buildNextButton(context, state)
            : _buildSubmitAnswerButton(context, state),
      ),
    );
  }

  Widget _buildSubmitAnswerButton(BuildContext context, QuizState state) {
    return ElevatedButton(
      onPressed: _selectedAnswer != null ? _handleSubmitAnswer : null,
      child: const Text('Submit Answer'),
    );
  }

  Widget _buildNextButton(BuildContext context, QuizState state) {
    if (state.isLastQuestion && state.allQuestionsAnswered) {
      return ElevatedButton(
        onPressed: state.isSubmitting ? null : _handleSubmitQuiz,
        child: state.isSubmitting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text('Submit Quiz'),
      );
    }

    return ElevatedButton(
      onPressed: state.hasNext ? _handleNext : null,
      child: const Text('Next Question'),
    );
  }
}
