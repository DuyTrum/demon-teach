import 'package:demon_teach/core/theme/app_theme.dart';
import 'package:demon_teach/domain/entities/assessment.dart';
import 'package:demon_teach/presentation/providers/assessment_provider.dart';
import 'package:demon_teach/presentation/screens/onboarding/goal_configuration_screen.dart';
import 'package:demon_teach/presentation/widgets/common/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AssessmentResultScreen extends ConsumerWidget {
  const AssessmentResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assessmentState = ref.watch(assessmentProvider);
    final result = assessmentState.result;

    if (result == null) {
      return const Scaffold(
        body: Center(child: Text('No result available')),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              // Success icon
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: _getProficiencyColor(result.proficiencyLevel)
                        .withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.emoji_events,
                    size: 60,
                    color: _getProficiencyColor(result.proficiencyLevel),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                'Assessment Complete!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Proficiency level
              Text(
                'Your Level: ${result.proficiencyLevel.displayName}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: _getProficiencyColor(result.proficiencyLevel),
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Score card
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Score percentage
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Score',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            '${result.score.toStringAsFixed(1)}%',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Correct answers
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Correct Answers',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            '${result.correctAnswers} / ${result.totalQuestions}',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: result.percentage / 100,
                          minHeight: 12,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getProficiencyColor(result.proficiencyLevel),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Level description
              Card(
                color: _getProficiencyColor(result.proficiencyLevel)
                    .withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getLevelTitle(result.proficiencyLevel),
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color:
                                  _getProficiencyColor(result.proficiencyLevel),
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getLevelDescription(result.proficiencyLevel),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Continue button
              CustomButton(
                text: 'Continue to Learning Goals',
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => const GoalConfigurationScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getProficiencyColor(ProficiencyLevel level) {
    switch (level) {
      case ProficiencyLevel.basic:
        return Colors.orange;
      case ProficiencyLevel.intermediate:
        return Colors.blue;
      case ProficiencyLevel.advanced:
        return Colors.green;
    }
  }

  String _getLevelTitle(ProficiencyLevel level) {
    switch (level) {
      case ProficiencyLevel.basic:
        return 'Basic Level';
      case ProficiencyLevel.intermediate:
        return 'Intermediate Level';
      case ProficiencyLevel.advanced:
        return 'Advanced Level';
    }
  }

  String _getLevelDescription(ProficiencyLevel level) {
    switch (level) {
      case ProficiencyLevel.basic:
        return 'You\'re just getting started! We\'ll focus on building your foundation with essential vocabulary and basic grammar.';
      case ProficiencyLevel.intermediate:
        return 'Great progress! You have a solid foundation. We\'ll help you expand your skills with more complex conversations and grammar.';
      case ProficiencyLevel.advanced:
        return 'Excellent! You have strong language skills. We\'ll challenge you with advanced topics and help you achieve fluency.';
    }
  }
}
