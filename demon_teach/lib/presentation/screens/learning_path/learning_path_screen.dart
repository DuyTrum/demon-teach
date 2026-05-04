import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:demon_teach/core/theme/app_theme.dart';
import 'package:demon_teach/presentation/providers/learning_path_provider.dart';
import 'package:demon_teach/presentation/providers/auth_provider.dart';
import 'package:demon_teach/presentation/providers/language_provider.dart';
import 'package:demon_teach/presentation/widgets/common/custom_button.dart';
import 'package:demon_teach/presentation/widgets/common/loading_indicator.dart';
import 'package:demon_teach/presentation/widgets/common/error_message.dart';
import 'package:demon_teach/presentation/screens/lesson/daily_lesson_screen.dart';

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
      _loadPath();
    });
  }

  void _loadPath() {
    final user = ref.read(authProvider).user;
    final langPref = ref.read(languageProvider).preference;
    
    if (user != null && langPref != null) {
      ref.read(learningPathProvider.notifier).loadLearningPath(
        userId: user.id,
        targetLanguage: langPref.targetLanguage,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pathState = ref.watch(learningPathProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lộ trình học tập'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: pathState.isLoading || pathState.isGenerating
          ? const Center(child: LoadingIndicator())
          : pathState.error != null
              ? Center(
                  child: ErrorMessage(
                    message: pathState.error!,
                    onRetry: _loadPath,
                  ),
                )
              : pathState.path == null
                  ? _buildNoPathFound()
                  : _buildPathContent(context, ref, pathState),
    );
  }

  Widget _buildNoPathFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sentiment_dissatisfied, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Không tìm thấy lộ trình học tập.'),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Navigate to onboarding or generator
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Vui lòng hoàn thành đánh giá trình độ.')),
              );
            },
            child: const Text('Bắt đầu đánh giá'),
          ),
        ],
      ),
    );
  }

  Widget _buildPathContent(
    BuildContext context,
    WidgetRef ref,
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
            _buildActionButtons(context, ref, path),
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

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, path) {
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
          onPressed: () {
            // TODO: Navigate to path modification screen
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Path modification coming soon!'),
              ),
            );
          },
          isOutlined: true,
          icon: Icons.edit,
        ),
      ],
    );
  }
}
