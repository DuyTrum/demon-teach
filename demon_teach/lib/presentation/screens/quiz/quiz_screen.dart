import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:demon_teach/core/theme/app_theme.dart';
import 'package:demon_teach/domain/entities/quiz.dart';
import 'package:demon_teach/presentation/providers/quiz_provider.dart';
import 'package:demon_teach/presentation/widgets/common/loading_indicator.dart';
import 'package:demon_teach/presentation/widgets/common/error_message.dart';
import 'package:demon_teach/presentation/screens/quiz/quiz_result_screen.dart';
import 'package:demon_teach/presentation/widgets/common/demon_background_particles.dart';

/// Quiz screen with immediate feedback and Demon Theme
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
      backgroundColor: AppTheme.demonBgGradientBot,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Trắc nghiệm',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          if (state.quiz != null)
            Padding(
              padding: const EdgeInsets.only(right: AppTheme.spacingMd),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.demonGlowPurple.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.demonGlowPurple.withOpacity(0.3)),
                  ),
                  child: Text(
                    '${state.currentQuestionNumber}/${state.totalQuestions}',
                    style: const TextStyle(
                      color: AppTheme.demonGlowPurple,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
        ],
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

          // Demon Particles
          const Positioned.fill(
            child: DemonBackgroundParticles(),
          ),

          // Content
          SafeArea(
            child: _buildBody(context, state),
          ),
        ],
      ),
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
        child: Text(
          'Không có câu hỏi trắc nghiệm cho bài học này.',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
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
    final progress = state.totalQuestions > 0 ? (state.currentQuestionNumber / state.totalQuestions) : 0.0;
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        children: [
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.transparent,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.demonGlowPurple,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            'Câu hỏi ${state.currentQuestionNumber} / ${state.totalQuestions}',
            style: const TextStyle(
              color: AppTheme.demonTextMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion(BuildContext context, QuizState state) {
    final question = state.currentQuestion;
    if (question == null) return const SizedBox.shrink();

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
        border: Border.all(color: AppTheme.demonGlowPurple.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.demonGlowPurple.withOpacity(0.05),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMd,
                    vertical: AppTheme.spacingSm,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.demonGlowPurple.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.demonGlowPurple.withOpacity(0.3)),
                  ),
                  child: Text(
                    _getLocalizedQuestionType(question.type),
                    style: const TextStyle(
                      color: AppTheme.demonGlowPurple,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                Text(
                  question.questionText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getLocalizedQuestionType(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return "Chọn đáp án đúng";
      case QuestionType.fillInBlank:
        return "Điền vào chỗ trống";
      case QuestionType.matching:
        return "Nối đáp án phù hợp";
    }
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
        Color textColor = Colors.white;
        BoxShadow? glowShadow;

        if (showCorrectness) {
          if (isCorrect) {
            backgroundColor = Colors.green.withOpacity(0.15);
            borderColor = Colors.green;
            textColor = Colors.greenAccent;
            glowShadow = BoxShadow(color: Colors.green.withOpacity(0.2), blurRadius: 10);
          } else if (isSelected && !isCorrect) {
            backgroundColor = Colors.redAccent.withOpacity(0.15);
            borderColor = Colors.redAccent;
            textColor = Colors.red;
            glowShadow = BoxShadow(color: Colors.redAccent.withOpacity(0.2), blurRadius: 10);
          }
        } else if (isSelected) {
          backgroundColor = AppTheme.demonGlowPurple.withOpacity(0.15);
          borderColor = AppTheme.demonGlowPurple;
          textColor = AppTheme.demonGlowPurple;
          glowShadow = BoxShadow(color: AppTheme.demonGlowPurple.withOpacity(0.3), blurRadius: 12);
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor ?? AppTheme.demonCardDark.withOpacity(0.5),
              border: Border.all(
                color: borderColor ?? Colors.white.withOpacity(0.1),
                width: isSelected || showCorrectness ? 2 : 1.5,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: glowShadow != null ? [glowShadow] : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: state.showFeedback
                    ? null
                    : () => _handleAnswerSelection(option),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          option,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: isSelected || showCorrectness ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ),
                      if (showCorrectness && isCorrect)
                        const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 24),
                      if (showCorrectness && isSelected && !isCorrect)
                        const Icon(Icons.cancel_rounded, color: Colors.redAccent, size: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFillInBlankInput(
      BuildContext context, QuizState state, bool isAnswered) {
    final isCorrect = state.isAnsweredCorrectly(state.currentQuestion!.id) ?? false;
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.demonCardDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: state.showFeedback
              ? (isCorrect ? Colors.green : Colors.redAccent)
              : Colors.white.withOpacity(0.1),
          width: 1.5,
        ),
      ),
      child: TextField(
        enabled: !state.showFeedback,
        onChanged: (value) {
          setState(() {
            _selectedAnswer = value;
          });
        },
        style: const TextStyle(color: Colors.white, fontSize: 16),
        cursorColor: AppTheme.demonGlowPurple,
        decoration: InputDecoration(
          hintText: 'Nhập câu trả lời của bạn...',
          hintStyle: const TextStyle(color: AppTheme.demonTextMuted),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          suffixIcon: state.showFeedback
              ? Icon(
                  isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: isCorrect ? Colors.greenAccent : Colors.redAccent,
                  size: 24,
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildFeedback(BuildContext context, QuizState state) {
    final question = state.currentQuestion;
    if (question == null) return const SizedBox.shrink();

    final isCorrect = state.isAnsweredCorrectly(question.id) ?? false;
    final color = isCorrect ? Colors.greenAccent : Colors.redAccent;

    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      color: color,
                      size: 28,
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                    Text(
                      isCorrect ? 'Chính xác! 😈' : 'Chưa đúng rồi 😢',
                      style: TextStyle(
                        color: color,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingMd),
                Text(
                  question.explanation,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, QuizState state) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: AppTheme.demonBgGradientBot.withOpacity(0.8),
        border: Border(
          top: BorderSide(color: AppTheme.demonGlowPurple.withOpacity(0.15)),
        ),
      ),
      child: SafeArea(
        child: state.showFeedback
            ? _buildNextButton(context, state)
            : _buildSubmitAnswerButton(context, state),
      ),
    );
  }

  Widget _buildSubmitAnswerButton(BuildContext context, QuizState state) {
    final canSubmit = _selectedAnswer != null && _selectedAnswer!.trim().isNotEmpty;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: canSubmit
            ? const LinearGradient(
                colors: [AppTheme.demonGlowPurple, AppTheme.primaryColor],
              )
            : null,
        color: canSubmit ? null : AppTheme.demonNodeLocked.withOpacity(0.4),
        border: Border.all(
          color: canSubmit ? AppTheme.demonGlowPurple.withOpacity(0.5) : Colors.white.withOpacity(0.05),
        ),
      ),
      child: ElevatedButton(
        onPressed: canSubmit ? _handleSubmitAnswer : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          'Nộp đáp án',
          style: TextStyle(
            color: canSubmit ? Colors.white : AppTheme.demonTextMuted,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildNextButton(BuildContext context, QuizState state) {
    final isLast = state.isLastQuestion && state.allQuestionsAnswered;
    final text = isLast ? 'Hoàn thành bài thi 😈' : 'Câu hỏi tiếp theo';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [AppTheme.demonGlowPurple, AppTheme.primaryColor],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.demonGlowPurple.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLast
            ? (state.isSubmitting ? null : _handleSubmitQuiz)
            : _handleNext,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: state.isSubmitting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
