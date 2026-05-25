import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:demon_teach/presentation/screens/onboarding/assessment_screen.dart';
import 'package:demon_teach/presentation/providers/auth_provider.dart';
import 'package:demon_teach/presentation/providers/language_provider.dart';
import 'package:demon_teach/core/theme/app_theme.dart';
import 'package:demon_teach/presentation/providers/learning_path_provider.dart';
import 'package:demon_teach/presentation/widgets/common/custom_button.dart';
import 'package:demon_teach/presentation/widgets/common/loading_indicator.dart';
import 'package:demon_teach/presentation/widgets/common/error_message.dart';
import 'package:demon_teach/presentation/screens/lesson/daily_lesson_screen.dart';
import 'package:demon_teach/domain/entities/assessment.dart';
import 'package:demon_teach/domain/entities/learning_goal.dart';

class LearningPathScreen extends ConsumerStatefulWidget {
  const LearningPathScreen({super.key});

  @override
  ConsumerState<LearningPathScreen> createState() => _LearningPathScreenState();
}

class _LearningPathScreenState extends ConsumerState<LearningPathScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ignore: missing_return
      _loadPath();
    });
  }

  Future<void> _loadPath() async {
    final user = ref.read(authProvider).user;
    final languagePref = ref.read(languageProvider).preference;
    
    print('--- LEARNING PATH DEBUG ---');
    print('User: ${user?.id}');
    print('Language: ${languagePref?.targetLanguage}');
    
    if (user != null && languagePref != null) {
      print('Calling loadLearningPath...');
      ref.read(learningPathProvider.notifier).loadLearningPath(
        userId: user.id,
        targetLanguage: languagePref.targetLanguage,
      );
    } else {
      print('Not calling loadLearningPath because user or languagePref is null');
    }
  }

  @override
  Widget build(BuildContext context) {
    final pathState = ref.watch(learningPathProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Learning Path'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: pathState.isLoading || pathState.isGenerating
          ? const Center(child: LoadingIndicator())
          : pathState.error != null
              ? Center(
                  child: ErrorMessage(
                    message: pathState.error!,
                    onRetry: () {
                      // Retry logic can be added here
                    },
                  ),
                )
              : pathState.path == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Chưa có lộ trình học nào được tạo.',
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                          CustomButton(
                            text: 'Tạo Lộ trình học',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const AssessmentScreen()),
                              );
                            },
                          ),
                        ],
                      ),
                    )
                  : _buildPathContent(context, pathState),
    );
  }

  Widget _buildPathContent(
    BuildContext context,
    LearningPathState pathState,
  ) {
    final path = pathState.path!;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Path overview card
            _buildOverviewCard(context, path),
            const SizedBox(height: AppTheme.spacingMd),

            // Progress indicator
            _buildProgressSection(context, path),
            const SizedBox(height: AppTheme.spacingMd),

            // Lesson list
            _buildLessonList(context, path),
            const SizedBox(height: AppTheme.spacingMd),

            // Action buttons
            _buildActionButtons(context, path),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard(BuildContext context, path) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.school,
                  color: AppTheme.primaryColor,
                  size: 32,
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Learning ${path.targetLanguage.toUpperCase()}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${path.proficiencyLevel.displayName} • ${path.goalType.displayName}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondaryColor,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),
            const Divider(),
            const SizedBox(height: AppTheme.spacingSm),
            _buildInfoRow(
              context,
              icon: Icons.list_alt,
              label: 'Total Lessons',
              value: '${path.lessonIds.length}',
            ),
            const SizedBox(height: AppTheme.spacingSm),
            _buildInfoRow(
              context,
              icon: Icons.check_circle,
              label: 'Completed',
              value: '${path.currentLessonIndex}',
            ),
            const SizedBox(height: AppTheme.spacingSm),
            _buildInfoRow(
              context,
              icon: Icons.pending_actions,
              label: 'Remaining',
              value: '${path.lessonIds.length - path.currentLessonIndex}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.textSecondaryColor),
        const SizedBox(width: AppTheme.spacingSm),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
        ),
        const Spacer(),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
        ),
      ],
    );
  }

  Widget _buildProgressSection(BuildContext context, path) {
    final percentage = path.completionPercentage;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Overall Progress',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingSm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              child: LinearProgressIndicator(
                value: percentage / 100,
                minHeight: 12,
                backgroundColor: AppTheme.surfaceColor,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonList(BuildContext context, path) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lessons',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            const Divider(),
            ...path.lessonIds.asMap().entries.map((entry) {
              final index = entry.key;
              final lessonId = entry.value;
              final isCompleted = index < path.currentLessonIndex;
              final isCurrent = index == path.currentLessonIndex;

              return _buildLessonItem(
                context,
                lessonId: lessonId,
                lessonNumber: index + 1,
                isCompleted: isCompleted,
                isCurrent: isCurrent,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonItem(
    BuildContext context, {
    required String lessonId,
    required int lessonNumber,
    required bool isCompleted,
    required bool isCurrent,
  }) {
    // Parse lesson ID to get readable name
    final parts = lessonId.split('_');
    final category = parts.length > 2 ? parts[2] : 'lesson';
    final lessonName = '${category.toUpperCase()} Lesson $lessonNumber';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppTheme.spacingXs),
      padding: const EdgeInsets.all(AppTheme.spacingSm),
      decoration: BoxDecoration(
        color: isCurrent
            ? AppTheme.primaryColor.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: isCurrent
            ? Border.all(color: AppTheme.primaryColor, width: 2)
            : null,
      ),
      child: Row(
        children: [
          // Status icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppTheme.successColor
                  : isCurrent
                      ? AppTheme.primaryColor
                      : AppTheme.surfaceColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 20,
                    )
                  : Text(
                      '$lessonNumber',
                      style: TextStyle(
                        color: isCurrent
                            ? Colors.white
                            : AppTheme.textSecondaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          // Lesson name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lessonName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight:
                            isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: isCompleted
                            ? AppTheme.textSecondaryColor
                            : AppTheme.textPrimaryColor,
                      ),
                ),
                Text(
                  lessonId,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 10,
                      ),
                ),
              ],
            ),
          ),
          // Current indicator
          if (isCurrent)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingSm,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: const Text(
                'Current',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, path) {
    return Column(
      children: [
        if (!path.isCompleted)
          CustomButton(
            text: 'Start Learning',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const DailyLessonScreen(),
                ),
              );
            },
            icon: Icons.play_arrow,
          ),
        const SizedBox(height: AppTheme.spacingSm),
        CustomButton(
          text: 'Modify Learning Path',
          onPressed: () => _showModifyPathSheet(context, path),
          isOutlined: true,
          icon: Icons.edit,
        ),
      ],
    );
  }

  void _showModifyPathSheet(BuildContext context, path) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _ModifyPathBottomSheet(path: path),
    );
  }
}

class _ModifyPathBottomSheet extends ConsumerStatefulWidget {
  final dynamic path;

  const _ModifyPathBottomSheet({required this.path});

  @override
  ConsumerState<_ModifyPathBottomSheet> createState() => _ModifyPathBottomSheetState();
}

class _ModifyPathBottomSheetState extends ConsumerState<_ModifyPathBottomSheet> {
  late ProficiencyLevel _selectedLevel;
  late GoalType _selectedGoal;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedLevel = widget.path.proficiencyLevel;
    _selectedGoal = widget.path.goalType;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppTheme.spacingLg,
        right: AppTheme.spacingLg,
        top: AppTheme.spacingLg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.spacingXl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Text(
            'Điều chỉnh lộ trình học',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingXl),

          // Proficiency Level selection
          Text(
            'Trình độ của bạn',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Wrap(
            spacing: 8,
            children: ProficiencyLevel.values.map((level) {
              final isSelected = _selectedLevel == level;
              return ChoiceChip(
                label: Text(level.displayName),
                selected: isSelected,
                selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: isSelected ? AppTheme.primaryColor : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedLevel = level;
                    });
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // Goal Type selection
          Text(
            'Mục tiêu học tập',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Column(
            children: GoalType.values.map((goal) {
              final isSelected = _selectedGoal == goal;
              return Card(
                elevation: isSelected ? 2 : 0,
                color: isSelected ? AppTheme.primaryColor.withOpacity(0.05) : Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
                  ),
                ),
                child: ListTile(
                  leading: Text(goal.icon, style: const TextStyle(fontSize: 24)),
                  title: Text(
                    goal.displayName,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
                    ),
                  ),
                  subtitle: Text(goal.description, style: const TextStyle(fontSize: 12)),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: AppTheme.primaryColor)
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedGoal = goal;
                    });
                  },
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppTheme.spacingXl),

          // Confirm button
          CustomButton(
            text: 'Cập nhật lộ trình',
            isLoading: _isLoading,
            onPressed: () async {
              setState(() {
                _isLoading = true;
              });

              final success = await ref
                  .read(learningPathProvider.notifier)
                  .regeneratePath(
                    newProficiencyLevel: _selectedLevel,
                    newGoalType: _selectedGoal,
                  );

              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
                if (success) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lộ trình học đã được cập nhật thành công!'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Không thể cập nhật lộ trình. Vui lòng thử lại.'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
