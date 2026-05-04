import 'package:demon_teach/core/theme/app_theme.dart';
import 'package:demon_teach/presentation/providers/assessment_provider.dart';
import 'package:demon_teach/presentation/providers/language_provider.dart';
import 'package:demon_teach/presentation/screens/onboarding/assessment_result_screen.dart';
import 'package:demon_teach/presentation/widgets/common/custom_button.dart';
import 'package:demon_teach/presentation/widgets/common/error_message.dart';
import 'package:demon_teach/presentation/widgets/common/loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
            .loadAssessment(languageState.preference!.targetLanguage);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final assessmentState = ref.watch(assessmentProvider);
    final languageState = ref.watch(languageProvider);

    if (assessmentState.isLoading) {
      return const Scaffold(
        body: Center(child: LoadingIndicator()),
      );
    }

    if (assessmentState.error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Assessment')),
        body: Center(
          child: ErrorMessage(
            message: assessmentState.error!,
            onRetry: () {
              if (languageState.preference != null) {
                ref
                    .read(assessmentProvider.notifier)
                    .loadAssessment(languageState.preference!.targetLanguage);
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
        body: Center(child: LoadingIndicator()),
      );
    }

    final currentQuestion = assessmentState.currentQuestion;
    if (currentQuestion == null) {
      return const Scaffold(
        body: Center(child: Text('No questions available')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Proficiency Assessment'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            LinearProgressIndicator(
              value: assessmentState.progress,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.primaryColor,
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
                      'Question ${assessmentState.currentQuestionIndex + 1} of ${assessmentState.assessment!.questions.length}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 16),

                    // Question text
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          currentQuestion.questionText,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Options
                    ...currentQuestion.options.map((option) {
                      final isSelected =
                          assessmentState.userAnswers[currentQuestion.id] ==
                              option;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _OptionCard(
                          option: option,
                          isSelected: isSelected,
                          onTap: () {
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

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  // Previous button
                  if (assessmentState.currentQuestionIndex > 0)
                    Expanded(
                      child: CustomButton(
                        text: 'Previous',
                        onPressed: () {
                          ref
                              .read(assessmentProvider.notifier)
                              .previousQuestion();
                        },
                        isOutlined: true,
                      ),
                    ),
                  if (assessmentState.currentQuestionIndex > 0)
                    const SizedBox(width: 16),

                  // Next/Submit button
                  Expanded(
                    flex: 2,
                    child: CustomButton(
                      text: assessmentState.isLastQuestion ? 'Submit' : 'Next',
                      onPressed: assessmentState
                                  .userAnswers[currentQuestion.id] !=
                              null
                          ? () async {
                              if (assessmentState.isLastQuestion) {
                                // Submit assessment
                                await ref
                                    .read(assessmentProvider.notifier)
                                    .submitAssessment(
                                      'user_1', // TODO: Get actual user ID
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
}

class _OptionCard extends StatelessWidget {
  final String option;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withOpacity(0.1)
              : Colors.white,
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Radio button
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppTheme.primaryColor : Colors.grey[400]!,
                  width: 2,
                ),
                color: isSelected ? AppTheme.primaryColor : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
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
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color:
                          isSelected ? AppTheme.primaryColor : Colors.black87,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
