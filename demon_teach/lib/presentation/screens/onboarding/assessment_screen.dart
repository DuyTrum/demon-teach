import 'dart:ui';
import 'package:demon_teach/core/theme/app_theme.dart';
import 'package:demon_teach/presentation/providers/assessment_provider.dart';
import 'package:demon_teach/presentation/providers/language_provider.dart';
import 'package:demon_teach/presentation/screens/onboarding/assessment_result_screen.dart';
import 'package:demon_teach/presentation/widgets/common/custom_button.dart';
import 'package:demon_teach/presentation/widgets/common/error_message.dart';
import 'package:demon_teach/presentation/widgets/common/loading_indicator.dart';
import 'package:demon_teach/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:demon_teach/presentation/widgets/common/demon_background_particles.dart';

class AssessmentScreen extends ConsumerStatefulWidget {
  const AssessmentScreen({super.key});

  @override
  ConsumerState<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends ConsumerState<AssessmentScreen> {
  @override
  void initState() {
    super.initState();
    // Load assessment after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final languageState = ref.read(languageProvider);
      if (languageState.preference != null) {
        ref
            .read(assessmentProvider.notifier)
            .loadAssessment(
              languageState.preference!.targetLanguage,
              languageState.preference!.nativeLanguage,
            );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final assessmentState = ref.watch(assessmentProvider);
    final languageState = ref.watch(languageProvider);

    if (assessmentState.isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.demonBgGradientBot,
        body: Center(child: LoadingIndicator()),
      );
    }

    if (assessmentState.error != null) {
      return Scaffold(
        backgroundColor: AppTheme.demonBgGradientBot,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text('Đánh giá trình độ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        body: Center(
          child: ErrorMessage(
            message: assessmentState.error!,
            onRetry: () {
              if (languageState.preference != null) {
                ref
                    .read(assessmentProvider.notifier)
                    .loadAssessment(
                      languageState.preference!.targetLanguage,
                      languageState.preference!.nativeLanguage,
                    );
              }
            },
          ),
        ),
      );
    }

    if (assessmentState.result != null) {
      // Navigate to result screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const AssessmentResultScreen(),
          ),
        );
      });
      return const Scaffold(
        backgroundColor: AppTheme.demonBgGradientBot,
        body: Center(child: LoadingIndicator()),
      );
    }

    final currentQuestion = assessmentState.currentQuestion;
    if (currentQuestion == null) {
      return const Scaffold(
        backgroundColor: AppTheme.demonBgGradientBot,
        body: Center(child: Text('Không có câu hỏi khả dụng', style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppTheme.demonBgGradientBot,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Đánh giá trình độ',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Gradient
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
          // Embers
          const Positioned.fill(
            child: DemonBackgroundParticles(),
          ),

          SafeArea(
            child: Column(
              children: [
                // Progress bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: assessmentState.progress,
                        backgroundColor: Colors.transparent,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.demonGlowPurple,
                        ),
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Question number
                        Text(
                          'Câu hỏi ${assessmentState.currentQuestionIndex + 1} / ${assessmentState.assessment!.questions.length}',
                          style: const TextStyle(
                            color: AppTheme.demonTextMuted,
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Question text
                        Container(
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
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Text(
                                  currentQuestion.questionText,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Options
                        ...currentQuestion.options.map((option) {
                          final userAnswer = assessmentState.userAnswers[currentQuestion.id];
                          final isAnswered = userAnswer != null;
                          final isSelected = userAnswer == option;
                          final isCorrect = option == currentQuestion.correctAnswer;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _OptionCard(
                              option: option,
                              isSelected: isSelected,
                              isCorrect: isCorrect,
                              isAnswered: isAnswered,
                              onTap: isAnswered
                                  ? () {}
                                  : () {
                                      ref
                                          .read(assessmentProvider.notifier)
                                          .answerQuestion(currentQuestion.id, option);
                                    },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                               // Action button - Full width
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: assessmentState.userAnswers[currentQuestion.id] != null
                          ? const LinearGradient(colors: [AppTheme.demonGlowPurple, AppTheme.primaryColor])
                          : null,
                      color: assessmentState.userAnswers[currentQuestion.id] != null
                          ? null
                          : AppTheme.demonNodeLocked.withOpacity(0.4),
                      border: Border.all(
                        color: assessmentState.userAnswers[currentQuestion.id] != null
                            ? AppTheme.demonGlowPurple.withOpacity(0.5)
                            : Colors.white.withOpacity(0.05),
                      ),
                      boxShadow: assessmentState.userAnswers[currentQuestion.id] != null
                          ? [
                              BoxShadow(
                                color: AppTheme.demonGlowPurple.withOpacity(0.2),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ]
                          : null,
                    ),
                    child: ElevatedButton(
                      onPressed: assessmentState.userAnswers[currentQuestion.id] != null
                          ? () async {
                              if (assessmentState.isLastQuestion) {
                                final user = ref.read(authProvider).user;
                                final actualUserId = user?.id ?? 'default_user';
                                // Submit assessment
                                await ref
                                    .read(assessmentProvider.notifier)
                                    .submitAssessment(
                                      actualUserId,
                                      languageState.preference!.targetLanguage,
                                    );
                              } else {
                                // Next question
                                ref
                                    .read(assessmentProvider.notifier)
                                    .nextQuestion();
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        assessmentState.isLastQuestion ? 'Nộp bài 😈' : 'Tiếp theo',
                        style: TextStyle(
                          color: assessmentState.userAnswers[currentQuestion.id] != null
                              ? Colors.white
                              : AppTheme.demonTextMuted,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final String option;
  final bool isSelected;
  final bool isCorrect;
  final bool isAnswered;
  final VoidCallback onTap;

  const _OptionCard({
    required this.option,
    required this.isSelected,
    required this.isCorrect,
    required this.isAnswered,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color? backgroundColor;
    Color? borderColor;
    Color textColor = AppTheme.demonTextLight;
    BoxShadow? glowShadow;
    Widget? trailingIcon;

    if (isAnswered) {
      if (isCorrect) {
        backgroundColor = Colors.green.withOpacity(0.15);
        borderColor = Colors.green;
        textColor = Colors.greenAccent;
        glowShadow = BoxShadow(color: Colors.green.withOpacity(0.2), blurRadius: 10);
        trailingIcon = const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 24);
      } else if (isSelected && !isCorrect) {
        backgroundColor = Colors.redAccent.withOpacity(0.15);
        borderColor = Colors.redAccent;
        textColor = Colors.redAccent;
        glowShadow = BoxShadow(color: Colors.redAccent.withOpacity(0.2), blurRadius: 10);
        trailingIcon = const Icon(Icons.cancel_rounded, color: Colors.redAccent, size: 24);
      }
    } else if (isSelected) {
      backgroundColor = AppTheme.demonGlowPurple.withOpacity(0.15);
      borderColor = AppTheme.demonGlowPurple;
      textColor = Colors.white;
      glowShadow = BoxShadow(color: AppTheme.demonGlowPurple.withOpacity(0.2), blurRadius: 10);
    }

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.demonCardDark.withOpacity(0.5),
        border: Border.all(
          color: borderColor ?? Colors.white.withOpacity(0.1),
          width: isSelected || (isAnswered && (isCorrect || isSelected)) ? 2 : 1.5,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: glowShadow != null ? [glowShadow] : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    // Radio button glow look
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isAnswered
                              ? (isCorrect
                                  ? Colors.green
                                  : (isSelected ? Colors.redAccent : AppTheme.demonTextMuted))
                              : (isSelected ? AppTheme.demonGlowPurple : AppTheme.demonTextMuted),
                          width: 2,
                        ),
                        color: isAnswered
                            ? (isCorrect
                                ? Colors.green
                                : (isSelected ? Colors.redAccent : Colors.transparent))
                            : (isSelected ? AppTheme.demonGlowPurple : Colors.transparent),
                      ),
                      child: isSelected || (isAnswered && isCorrect)
                          ? Icon(
                              isAnswered && !isCorrect ? Icons.close : Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),

                    // Option text
                    Expanded(
                      child: Text(
                        option,
                        style: TextStyle(
                          color: isSelected || (isAnswered && isCorrect) ? Colors.white : textColor,
                          fontSize: 16,
                          fontWeight: isSelected || (isAnswered && isCorrect) ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (trailingIcon != null) ...[
                      const SizedBox(width: 8),
                      trailingIcon,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
