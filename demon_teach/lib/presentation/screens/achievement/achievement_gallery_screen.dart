import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:demon_teach/core/theme/app_theme.dart';
import 'package:demon_teach/domain/entities/achievement.dart';
import 'package:demon_teach/presentation/providers/achievement_provider.dart';
import 'package:demon_teach/presentation/widgets/achievement/achievement_card.dart';

/// Achievement gallery screen showing all achievements
class AchievementGalleryScreen extends ConsumerStatefulWidget {
  final String userId;
  final String targetLanguage;

  const AchievementGalleryScreen({
    super.key,
    required this.userId,
    required this.targetLanguage,
  });

  @override
  ConsumerState<AchievementGalleryScreen> createState() =>
      _AchievementGalleryScreenState();
}

class _AchievementGalleryScreenState
    extends ConsumerState<AchievementGalleryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Load achievements
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(achievementProvider.notifier).loadAchievements(
            userId: widget.userId,
            targetLanguage: widget.targetLanguage,
          );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final achievementState = ref.watch(achievementProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Unlocked'),
          ],
        ),
      ),
      body: achievementState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : achievementState.error != null
              ? _buildError(context, achievementState.error!)
              : Column(
                  children: [
                    _buildHeader(context, achievementState),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildAchievementList(
                            context,
                            achievementState.achievements,
                          ),
                          _buildAchievementList(
                            context,
                            achievementState.unlockedAchievements,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildHeader(BuildContext context, AchievementState state) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.secondaryColor.withOpacity(0.1),
          ],
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard(
                context,
                icon: Icons.emoji_events,
                label: 'Unlocked',
                value: '${state.unlockedCount}/${state.totalAchievements}',
                color: AppTheme.accentColor,
              ),
              _buildStatCard(
                context,
                icon: Icons.percent,
                label: 'Completion',
                value:
                    '${(state.completionPercentage * 100).toStringAsFixed(0)}%',
                color: AppTheme.successColor,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          LinearProgressIndicator(
            value: state.completionPercentage,
            backgroundColor: Colors.grey[300],
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
            minHeight: 8,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: AppTheme.spacingXs),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
        ),
      ],
    );
  }

  Widget _buildAchievementList(
    BuildContext context,
    List<Achievement> achievements,
  ) {
    if (achievements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              'No achievements yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              'Keep learning to unlock achievements!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
            ),
          ],
        ),
      );
    }

    // Group achievements by type
    final grouped = <AchievementType, List<Achievement>>{};
    for (final achievement in achievements) {
      grouped.putIfAbsent(achievement.type, () => []).add(achievement);
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(achievementProvider.notifier).refresh(
              userId: widget.userId,
              targetLanguage: widget.targetLanguage,
            );
      },
      child: ListView(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        children: [
          if (grouped.containsKey(AchievementType.streak))
            _buildSection(
              context,
              'Streak Achievements',
              grouped[AchievementType.streak]!,
              Icons.local_fire_department,
              Colors.orange,
            ),
          if (grouped.containsKey(AchievementType.xp))
            _buildSection(
              context,
              'XP Achievements',
              grouped[AchievementType.xp]!,
              Icons.star,
              Colors.amber,
            ),
          if (grouped.containsKey(AchievementType.lessonCount))
            _buildSection(
              context,
              'Lesson Achievements',
              grouped[AchievementType.lessonCount]!,
              Icons.book,
              Colors.blue,
            ),
          if (grouped.containsKey(AchievementType.special))
            _buildSection(
              context,
              'Special Achievements',
              grouped[AchievementType.special]!,
              Icons.emoji_events,
              Colors.purple,
            ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Achievement> achievements,
    IconData icon,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingSm,
            vertical: AppTheme.spacingMd,
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: AppTheme.spacingSm),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),
            ],
          ),
        ),
        ...achievements.map((achievement) => Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
              child: AchievementCard(achievement: achievement),
            )),
        const SizedBox(height: AppTheme.spacingMd),
      ],
    );
  }

  Widget _buildError(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 80,
            color: AppTheme.errorColor,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            'Error loading achievements',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingLg),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(achievementProvider.notifier).loadAchievements(
                    userId: widget.userId,
                    targetLanguage: widget.targetLanguage,
                  );
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
