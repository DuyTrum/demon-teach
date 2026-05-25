import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:demon_teach/core/theme/app_theme.dart';
import 'package:demon_teach/domain/entities/progress.dart';
import 'package:demon_teach/domain/entities/achievement.dart';
import 'package:demon_teach/presentation/providers/progress_provider.dart';
import 'package:demon_teach/presentation/providers/achievement_provider.dart';
import 'package:demon_teach/presentation/widgets/common/loading_indicator.dart';
import 'package:demon_teach/presentation/widgets/common/error_message.dart';

/// Progress dashboard screen showing XP, streak, and achievements
class ProgressDashboardScreen extends ConsumerStatefulWidget {
  final String userId;
  final String targetLanguage;

  const ProgressDashboardScreen({
    super.key,
    required this.userId,
    required this.targetLanguage,
  });

  @override
  ConsumerState<ProgressDashboardScreen> createState() =>
      _ProgressDashboardScreenState();
}

class _ProgressDashboardScreenState
    extends ConsumerState<ProgressDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Load progress
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(progressProvider.notifier).loadProgress(
            userId: widget.userId,
            targetLanguage: widget.targetLanguage,
          );
      ref.read(achievementProvider.notifier).loadAchievements(
            userId: widget.userId,
            targetLanguage: widget.targetLanguage,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(progressProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Progress'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(progressProvider.notifier).refresh(
                    userId: widget.userId,
                    targetLanguage: widget.targetLanguage,
                  );
            },
          ),
        ],
      ),
      body: _buildBody(context, state),
    );
  }

  Widget _buildBody(BuildContext context, ProgressState state) {
    if (state.isLoading) {
      return const Center(child: LoadingIndicator());
    }

    if (state.error != null) {
      return Center(
        child: ErrorMessage(
          message: state.error!,
          onRetry: () {
            ref.read(progressProvider.notifier).loadProgress(
                  userId: widget.userId,
                  targetLanguage: widget.targetLanguage,
                );
          },
        ),
      );
    }

    if (state.progress == null) {
      return const Center(
        child: Text('No progress data available.'),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          ref.read(progressProvider.notifier).refresh(
                userId: widget.userId,
                targetLanguage: widget.targetLanguage,
              ),
          ref.read(achievementProvider.notifier).refresh(
                userId: widget.userId,
                targetLanguage: widget.targetLanguage,
              ),
        ]);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildLevelCard(context, state.progress!),
            const SizedBox(height: AppTheme.spacingLg),
            _buildStreakCard(context, state.progress!),
            const SizedBox(height: AppTheme.spacingLg),
            _buildStatsGrid(context, state.progress!),
            const SizedBox(height: AppTheme.spacingLg),
            _buildMilestonesCard(context, state.progress!),
            const SizedBox(height: AppTheme.spacingLg),
            _buildAchievementsCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelCard(BuildContext context, Progress progress) {
    return Card(
      elevation: AppTheme.elevationMd,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Level ${progress.level}',
                      style:
                          Theme.of(context).textTheme.displayMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: AppTheme.spacingXs),
                    Text(
                      '${progress.totalXP} XP',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingLg),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.star,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress to Level ${progress.level + 1}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                    Text(
                      '${progress.xpToNextLevel} XP to go',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingSm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusRound),
                  child: LinearProgressIndicator(
                    value: progress.progressToNextLevel,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCard(BuildContext context, Progress progress) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_fire_department,
                size: 40,
                color: AppTheme.accentColor,
              ),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Streak',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                  ),
                  const SizedBox(height: AppTheme.spacingXs),
                  Text(
                    '${progress.currentStreak} days',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: AppTheme.accentColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (progress.longestStreak > progress.currentStreak) ...[
                    const SizedBox(height: AppTheme.spacingXs),
                    Text(
                      'Best: ${progress.longestStreak} days',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondaryColor,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            if (progress.currentStreak > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMd,
                  vertical: AppTheme.spacingSm,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusRound),
                ),
                child: Text(
                  '🔥 On Fire!',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.successColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, Progress progress) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            'Lessons\nCompleted',
            '${progress.lessonsCompleted}',
            Icons.school,
            AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: AppTheme.spacingMd),
        Expanded(
          child: _buildStatCard(
            context,
            'Longest\nStreak',
            '${progress.longestStreak}',
            Icons.emoji_events,
            AppTheme.warningColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: color,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              value,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMilestonesCard(BuildContext context, Progress progress) {
    final milestones = [
      {'days': 7, 'label': '1 Week', 'icon': Icons.calendar_today},
      {'days': 30, 'label': '1 Month', 'icon': Icons.calendar_month},
      {'days': 100, 'label': '100 Days', 'icon': Icons.military_tech},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Streak Milestones',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            ...milestones.map((milestone) {
              final days = milestone['days'] as int;
              final label = milestone['label'] as String;
              final icon = milestone['icon'] as IconData;
              final achieved = progress.longestStreak >= days;

              return Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      color: achieved
                          ? AppTheme.accentColor
                          : AppTheme.textDisabledColor,
                    ),
                    const SizedBox(width: AppTheme.spacingMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: achieved
                                          ? AppTheme.textPrimaryColor
                                          : AppTheme.textSecondaryColor,
                                      fontWeight: achieved
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                          ),
                          Text(
                            '$days day streak',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textSecondaryColor,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    if (achieved)
                      const Icon(
                        Icons.check_circle,
                        color: AppTheme.successColor,
                      )
                    else
                      Icon(
                        Icons.lock,
                        color: AppTheme.textDisabledColor,
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsCard(BuildContext context) {
    final achievementState = ref.watch(achievementProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Achievements',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  '${achievementState.unlockedCount}/${achievementState.totalAchievements}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),
            if (achievementState.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (achievementState.achievements.isEmpty)
              const Text('No achievements available.')
            else
              ...achievementState.achievements.map((achievement) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: achievement.isUnlocked
                        ? AppTheme.accentColor.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.2),
                    child: Icon(
                      achievement.isUnlocked ? Icons.emoji_events : Icons.lock,
                      color: achievement.isUnlocked
                          ? AppTheme.accentColor
                          : Colors.grey,
                    ),
                  ),
                  title: Text(
                    achievement.title,
                    style: TextStyle(
                      fontWeight: achievement.isUnlocked
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: achievement.isUnlocked
                          ? AppTheme.textPrimaryColor
                          : AppTheme.textSecondaryColor,
                    ),
                  ),
                  subtitle: Text(achievement.description),
                  trailing: achievement.isUnlocked
                      ? const Icon(Icons.check_circle,
                          color: AppTheme.successColor)
                      : null,
                );
              }),
          ],
        ),
      ),
    );
  }
}
