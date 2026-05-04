import 'package:demon_teach/core/theme/app_theme.dart';
import 'package:demon_teach/domain/entities/learning_goal.dart';
import 'package:demon_teach/presentation/providers/goal_provider.dart';
import 'package:demon_teach/presentation/providers/language_provider.dart';
import 'package:demon_teach/presentation/providers/auth_provider.dart';
import 'package:demon_teach/presentation/providers/assessment_provider.dart';
import 'package:demon_teach/presentation/providers/learning_path_provider.dart';
import 'package:demon_teach/presentation/screens/learning_path/learning_path_screen.dart';
import 'package:demon_teach/presentation/widgets/common/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GoalConfigurationScreen extends ConsumerStatefulWidget {
  const GoalConfigurationScreen({super.key});

  @override
  ConsumerState<GoalConfigurationScreen> createState() =>
      _GoalConfigurationScreenState();
}

class _GoalConfigurationScreenState
    extends ConsumerState<GoalConfigurationScreen> {
  GoalType? selectedGoalType;
  int selectedStudyMinutes = 15; // Default 15 minutes

  @override
  Widget build(BuildContext context) {
    final goalState = ref.watch(goalProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning Goals'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spacingLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Text(
                      'What\'s your learning goal?',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    Text(
                      'This helps us personalize your learning path',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondaryColor,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.spacingXl),

                    // Goal type selection
                    ...GoalType.values.map((goalType) {
                      final isSelected = selectedGoalType == goalType;
                      return Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppTheme.spacingMd),
                        child: _GoalCard(
                          goalType: goalType,
                          isSelected: isSelected,
                          onTap: () {
                            setState(() {
                              selectedGoalType = goalType;
                            });
                          },
                        ),
                      );
                    }),

                    const SizedBox(height: AppTheme.spacingXl),

                    // Study time selection
                    Text(
                      'Daily study time',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    Text(
                      'How much time can you dedicate each day?',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondaryColor,
                          ),
                    ),
                    const SizedBox(height: AppTheme.spacingMd),

                    // Study time slider
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.spacingLg),
                        child: Column(
                          children: [
                            Text(
                              '$selectedStudyMinutes minutes',
                              style: Theme.of(context)
                                  .textTheme
                                  .displaySmall
                                  ?.copyWith(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: AppTheme.spacingMd),
                            Slider(
                              value: selectedStudyMinutes.toDouble(),
                              min: 5,
                              max: 30,
                              divisions: 25,
                              label: '$selectedStudyMinutes min',
                              onChanged: (value) {
                                setState(() {
                                  selectedStudyMinutes = value.round();
                                });
                              },
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '5 min',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppTheme.textSecondaryColor,
                                      ),
                                ),
                                Text(
                                  '30 min',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppTheme.textSecondaryColor,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AppTheme.spacingMd),

                    // Time recommendation
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingMd),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.lightbulb_outline,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: AppTheme.spacingMd),
                          Expanded(
                            child: Text(
                              _getTimeRecommendation(selectedStudyMinutes),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppTheme.primaryColor,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Continue button
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              child: CustomButton(
                text: 'Continue',
                onPressed: selectedGoalType != null
                    ? () => _handleContinue(context)
                    : null,
                isLoading: goalState.isLoading,
                width: double.infinity,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeRecommendation(int minutes) {
    if (minutes < 10) {
      return 'Perfect for busy schedules! Quick daily practice builds consistency.';
    } else if (minutes < 20) {
      return 'Great balance! Enough time to make real progress each day.';
    } else {
      return 'Ambitious! This will accelerate your learning significantly.';
    }
  }

  Future<void> _handleContinue(BuildContext context) async {
    if (selectedGoalType == null) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final goal = LearningGoal(
      goalType: selectedGoalType!,
      dailyStudyMinutes: selectedStudyMinutes,
    );

    // Save goal preferences
    final success =
        await ref.read(goalProvider.notifier).saveGoalPreferences(goal);

    if (!success) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Failed to save goals. Please try again.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (!context.mounted) return;

    // Get language preference and assessment result
    final languageState = ref.read(languageProvider);
    final assessmentState = ref.read(assessmentProvider);

    if (languageState.preference == null || assessmentState.result == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
              'Missing language or assessment data. Please restart onboarding.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final user = ref.read(authProvider).user;
    if (user == null) return;

    // Generate learning path
    final pathSuccess =
        await ref.read(learningPathProvider.notifier).generatePath(
              userId: user.id,
              targetLanguage: languageState.preference!.targetLanguage,
              proficiencyLevel: assessmentState.result!.proficiencyLevel,
              goalType: goal.goalType,
            );

    if (!context.mounted) return;

    if (pathSuccess) {
      // Navigate to learning path screen
      navigator.pushReplacement(
        MaterialPageRoute(
          builder: (context) => const LearningPathScreen(),
        ),
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Failed to generate learning path. Please try again.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
}

class _GoalCard extends StatelessWidget {
  final GoalType goalType;
  final bool isSelected;
  final VoidCallback onTap;

  const _GoalCard({
    required this.goalType,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withOpacity(0.1)
              : Colors.white,
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryColor
                    : AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Center(
                child: Text(
                  goalType.icon,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacingMd),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goalType.displayName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : AppTheme.textPrimaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    goalType.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                  ),
                ],
              ),
            ),

            // Checkmark
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppTheme.primaryColor,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }
}
