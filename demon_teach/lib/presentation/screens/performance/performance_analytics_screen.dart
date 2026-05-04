import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:demon_teach/core/theme/app_theme.dart';
import 'package:demon_teach/domain/entities/performance_data.dart';
import 'package:demon_teach/presentation/providers/performance_provider.dart';
import 'package:demon_teach/presentation/widgets/difficulty_adjustment_dialog.dart';

/// Screen for displaying performance analytics and difficulty adjustment
class PerformanceAnalyticsScreen extends ConsumerStatefulWidget {
  final String userId;
  final String targetLanguage;

  const PerformanceAnalyticsScreen({
    super.key,
    required this.userId,
    required this.targetLanguage,
  });

  @override
  ConsumerState<PerformanceAnalyticsScreen> createState() =>
      _PerformanceAnalyticsScreenState();
}

class _PerformanceAnalyticsScreenState
    extends ConsumerState<PerformanceAnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    // Load performance data on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(performanceProvider.notifier)
          .loadPerformance(widget.userId, widget.targetLanguage);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(performanceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref
                  .read(performanceProvider.notifier)
                  .refresh(widget.userId, widget.targetLanguage);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref
              .read(performanceProvider.notifier)
              .refresh(widget.userId, widget.targetLanguage);
        },
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : state.error != null
                ? _buildError(state.error!)
                : _buildContent(state),
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            'Error loading performance data',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(PerformanceState state) {
    if (state.recentPerformance.isEmpty) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStatsCard(state),
          const SizedBox(height: AppTheme.spacingMd),
          _buildDifficultyRecommendation(state),
          const SizedBox(height: AppTheme.spacingMd),
          _buildPerformanceTrend(state),
          const SizedBox(height: AppTheme.spacingMd),
          _buildRecentLessons(state),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.analytics_outlined,
            size: 100,
            color: AppTheme.textSecondaryColor,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            'No Performance Data Yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            'Complete some lessons to see your analytics',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(PerformanceState state) {
    final stats = state.stats;
    if (stats == null) return const SizedBox.shrink();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '7-Day Performance Summary',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.check_circle,
                    label: 'Accuracy',
                    value: '${stats.accuracyPercentage}%',
                    color: _getAccuracyColor(stats.averageAccuracy),
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.trending_up,
                    label: 'Consistency',
                    value: '${stats.consistencyPercentage}%',
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.book,
                    label: 'Lessons',
                    value: '${stats.totalLessons}',
                    color: AppTheme.accentColor,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.timer,
                    label: 'Avg Time',
                    value:
                        '${stats.averageCompletionMinutes.toStringAsFixed(1)} min',
                    color: AppTheme.secondaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: AppTheme.spacingSm),
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

  Color _getAccuracyColor(double accuracy) {
    if (accuracy >= 0.85) return Colors.green;
    if (accuracy >= 0.60) return Colors.orange;
    return Colors.red;
  }

  Widget _buildDifficultyRecommendation(PerformanceState state) {
    final adjustment = state.recommendedAdjustment;
    if (adjustment == null) return const SizedBox.shrink();

    final color = _getAdjustmentColor(adjustment);
    final icon = _getAdjustmentIcon(adjustment);

    return Card(
      elevation: 4,
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: Text(
                    'Difficulty Recommendation',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              adjustment.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (adjustment != DifficultyAdjustment.maintain) ...[
              const SizedBox(height: AppTheme.spacingMd),
              ElevatedButton.icon(
                onPressed: () => _showDifficultyAdjustmentDialog(adjustment),
                icon: const Icon(Icons.tune),
                label: Text('Apply ${adjustment.displayName}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getAdjustmentColor(DifficultyAdjustment adjustment) {
    switch (adjustment) {
      case DifficultyAdjustment.increase:
        return Colors.green;
      case DifficultyAdjustment.decrease:
        return Colors.orange;
      case DifficultyAdjustment.maintain:
        return Colors.blue;
    }
  }

  IconData _getAdjustmentIcon(DifficultyAdjustment adjustment) {
    switch (adjustment) {
      case DifficultyAdjustment.increase:
        return Icons.arrow_upward;
      case DifficultyAdjustment.decrease:
        return Icons.arrow_downward;
      case DifficultyAdjustment.maintain:
        return Icons.check_circle;
    }
  }

  void _showDifficultyAdjustmentDialog(DifficultyAdjustment adjustment) {
    showDialog(
      context: context,
      builder: (context) => DifficultyAdjustmentDialog(
        adjustment: adjustment,
        userId: widget.userId,
        targetLanguage: widget.targetLanguage,
        onConfirm: () {
          // Refresh performance data after adjustment
          ref
              .read(performanceProvider.notifier)
              .refresh(widget.userId, widget.targetLanguage);
        },
      ),
    );
  }

  Widget _buildPerformanceTrend(PerformanceState state) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Trend',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            SizedBox(
              height: 150,
              child: _buildTrendChart(state.recentPerformance),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendChart(List<PerformanceData> data) {
    if (data.isEmpty) {
      return const Center(child: Text('No data to display'));
    }

    // Simple bar chart visualization
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: data.reversed.take(7).map((performance) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '${(performance.accuracy * 100).round()}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Container(
                  height: 100 * performance.accuracy,
                  decoration: BoxDecoration(
                    color: _getAccuracyColor(performance.accuracy),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${performance.completedAt.day}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentLessons(PerformanceState state) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Lessons',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            ...state.recentPerformance.take(5).map((performance) {
              return _buildLessonItem(performance);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonItem(PerformanceData performance) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: Row(
        children: [
          Icon(
            Icons.book,
            color: _getAccuracyColor(performance.accuracy),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lesson ${performance.lessonId.substring(0, 8)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '${_formatDate(performance.completedAt)} • ${performance.difficulty}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                ),
              ],
            ),
          ),
          Text(
            '${(performance.accuracy * 100).round()}%',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _getAccuracyColor(performance.accuracy),
                ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
