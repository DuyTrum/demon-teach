import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:demon_teach/core/theme/app_theme.dart';
import 'package:demon_teach/domain/entities/review_item.dart';
import 'package:demon_teach/presentation/providers/review_provider.dart';
import 'package:demon_teach/presentation/screens/review/review_session_screen.dart';
import 'package:intl/intl.dart';

/// Review queue screen showing upcoming review items
class ReviewQueueScreen extends ConsumerStatefulWidget {
  final String userId;

  const ReviewQueueScreen({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<ReviewQueueScreen> createState() => _ReviewQueueScreenState();
}

class _ReviewQueueScreenState extends ConsumerState<ReviewQueueScreen> {
  @override
  void initState() {
    super.initState();
    // Load all reviews and due count
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reviewProvider.notifier).loadAllReviews(widget.userId);
      ref.read(reviewProvider.notifier).loadDueReviewCount(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final reviewState = ref.watch(reviewProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Queue'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(reviewProvider.notifier).loadAllReviews(widget.userId);
              ref
                  .read(reviewProvider.notifier)
                  .loadDueReviewCount(widget.userId);
            },
          ),
        ],
      ),
      body: reviewState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : reviewState.error != null
              ? _buildErrorState(reviewState.error!)
              : _buildReviewQueue(reviewState),
      floatingActionButton: reviewState.dueCount > 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        ReviewSessionScreen(userId: widget.userId),
                  ),
                );
              },
              icon: const Icon(Icons.play_arrow),
              label: Text('Start Review (${reviewState.dueCount})'),
            )
          : null,
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: AppTheme.errorColor,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            'Error: $error',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingLg),
          ElevatedButton(
            onPressed: () {
              ref.read(reviewProvider.notifier).clearError();
              ref.read(reviewProvider.notifier).loadAllReviews(widget.userId);
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewQueue(ReviewState reviewState) {
    if (reviewState.allReviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.inbox_outlined,
              size: 100,
              color: Colors.grey,
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              'No reviews yet',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              'Mark flashcards or quiz questions as difficult\nto add them to your review queue',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Group reviews by status (due, upcoming)
    final dueReviews =
        reviewState.allReviews.where((item) => item.isDue).toList();
    final upcomingReviews =
        reviewState.allReviews.where((item) => !item.isDue).toList();

    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      children: [
        // Summary card
        _buildSummaryCard(dueReviews.length, upcomingReviews.length),
        const SizedBox(height: AppTheme.spacingLg),

        // Due reviews section
        if (dueReviews.isNotEmpty) ...[
          _buildSectionHeader('Due Now', dueReviews.length),
          const SizedBox(height: AppTheme.spacingMd),
          ...dueReviews.map((item) => _buildReviewItemCard(item, isDue: true)),
          const SizedBox(height: AppTheme.spacingLg),
        ],

        // Upcoming reviews section
        if (upcomingReviews.isNotEmpty) ...[
          _buildSectionHeader('Upcoming', upcomingReviews.length),
          const SizedBox(height: AppTheme.spacingMd),
          ...upcomingReviews
              .map((item) => _buildReviewItemCard(item, isDue: false)),
        ],
      ],
    );
  }

  Widget _buildSummaryCard(int dueCount, int upcomingCount) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Due Now',
                    dueCount.toString(),
                    AppTheme.errorColor,
                    Icons.alarm,
                  ),
                ),
                Container(
                  width: 1,
                  height: 50,
                  color: Colors.grey[300],
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Upcoming',
                    upcomingCount.toString(),
                    AppTheme.primaryColor,
                    Icons.schedule,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: AppTheme.spacingSm),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(width: AppTheme.spacingSm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingSm,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewItemCard(ReviewItem item, {required bool isDue}) {
    final dateFormat = DateFormat('MMM d, y');
    final timeFormat = DateFormat('h:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      child: ListTile(
        leading: _buildReviewTypeIcon(item.type),
        title: Text(
          item.type.displayName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Repetitions: ${item.repetitionCount}'),
            Text('Ease: ${item.easeFactor.toStringAsFixed(2)}'),
            Text(
              isDue
                  ? 'Due: Now'
                  : 'Due: ${dateFormat.format(item.nextReviewDate)} at ${timeFormat.format(item.nextReviewDate)}',
              style: TextStyle(
                color:
                    isDue ? AppTheme.errorColor : AppTheme.textSecondaryColor,
                fontWeight: isDue ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
        trailing: isDue
            ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingSm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'DUE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : _buildIntervalBadge(item.intervalDays),
      ),
    );
  }

  Widget _buildReviewTypeIcon(ReviewItemType type) {
    IconData icon;
    Color color;

    switch (type) {
      case ReviewItemType.flashcard:
        icon = Icons.style;
        color = AppTheme.primaryColor;
        break;
      case ReviewItemType.quiz:
        icon = Icons.quiz;
        color = AppTheme.accentColor;
        break;
      case ReviewItemType.listening:
        icon = Icons.headphones;
        color = AppTheme.successColor;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingSm),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color),
    );
  }

  Widget _buildIntervalBadge(int days) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$days days',
        style: const TextStyle(
          color: AppTheme.primaryColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
