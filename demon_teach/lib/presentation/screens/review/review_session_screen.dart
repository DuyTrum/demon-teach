import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:demon_teach/core/theme/app_theme.dart';
import 'package:demon_teach/domain/entities/review_item.dart';
import 'package:demon_teach/domain/entities/flashcard.dart';
import 'package:demon_teach/presentation/providers/review_provider.dart';
import 'package:demon_teach/presentation/providers/flashcard_provider.dart';
import 'package:demon_teach/presentation/widgets/flashcard_widget.dart';

/// Review session screen for spaced repetition
class ReviewSessionScreen extends ConsumerStatefulWidget {
  final String userId;

  const ReviewSessionScreen({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<ReviewSessionScreen> createState() =>
      _ReviewSessionScreenState();
}

class _ReviewSessionScreenState extends ConsumerState<ReviewSessionScreen> {
  bool _isFlipped = false;
  DifficultyRating? _selectedDifficulty;

  @override
  void initState() {
    super.initState();
    // Load due reviews
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reviewProvider.notifier).loadDueReviews(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final reviewState = ref.watch(reviewProvider);

    if (reviewState.isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Review Session'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (reviewState.error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Review Session'),
        ),
        body: Center(
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
                'Error: ${reviewState.error}',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingLg),
              ElevatedButton(
                onPressed: () {
                  ref.read(reviewProvider.notifier).clearError();
                  ref
                      .read(reviewProvider.notifier)
                      .loadDueReviews(widget.userId);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (reviewState.dueReviews.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Review Session'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 100,
                color: AppTheme.successColor,
              ),
              const SizedBox(height: AppTheme.spacingLg),
              Text(
                'No reviews due!',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                'Great job! Come back later for more reviews.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingXl),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      );
    }

    if (reviewState.isComplete) {
      return _buildCompletionScreen(context);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Review ${reviewState.currentReviewNumber}/${reviewState.totalReviews}',
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Center(
              child: Text(
                '${reviewState.remainingReviews} left',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                    ),
              ),
            ),
          ),
        ],
      ),
      body: _buildReviewContent(context, reviewState),
    );
  }

  Widget _buildReviewContent(BuildContext context, ReviewState reviewState) {
    final currentReview = reviewState.currentReview;
    if (currentReview == null) return const SizedBox.shrink();

    return Column(
      children: [
        // Progress indicator
        LinearProgressIndicator(
          value: reviewState.currentReviewNumber / reviewState.totalReviews,
          backgroundColor: Colors.grey[200],
          valueColor:
              const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: Column(
              children: [
                // Review type badge
                _buildReviewTypeBadge(currentReview.type),
                const SizedBox(height: AppTheme.spacingLg),
                // Review content
                Expanded(
                  child: _buildReviewItemContent(currentReview),
                ),
                const SizedBox(height: AppTheme.spacingLg),
                // Difficulty rating buttons (shown after flip)
                if (_isFlipped) _buildDifficultyButtons(),
                const SizedBox(height: AppTheme.spacingMd),
                // Submit button
                if (_isFlipped && _selectedDifficulty != null)
                  _buildSubmitButton(reviewState),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewTypeBadge(ReviewItemType type) {
    IconData icon;
    String label;
    Color color;

    switch (type) {
      case ReviewItemType.flashcard:
        icon = Icons.style;
        label = 'Flashcard';
        color = AppTheme.primaryColor;
        break;
      case ReviewItemType.quiz:
        icon = Icons.quiz;
        label = 'Quiz';
        color = AppTheme.accentColor;
        break;
      case ReviewItemType.listening:
        icon = Icons.headphones;
        label = 'Listening';
        color = AppTheme.successColor;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: AppTheme.spacingSm),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItemContent(ReviewItem reviewItem) {
    // For now, we'll focus on flashcard reviews
    // Quiz and listening reviews can be added later
    if (reviewItem.type == ReviewItemType.flashcard) {
      return _buildFlashcardReview(reviewItem);
    }

    return Center(
      child: Text(
        'Review type ${reviewItem.type.displayName} not yet implemented',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }

  Widget _buildFlashcardReview(ReviewItem reviewItem) {
    // Load the flashcard content
    return FutureBuilder(
      future: ref
          .read(flashcardRepositoryProvider)
          .getFlashcardById(reviewItem.contentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading flashcard: ${snapshot.error}'),
          );
        }

        return snapshot.data!.when(
          success: (flashcard) => GestureDetector(
            onTap: () {
              setState(() {
                _isFlipped = !_isFlipped;
              });
            },
            child: FlashcardWidget(
              flashcard: flashcard,
              isFlipped: _isFlipped,
            ),
          ),
          failure: (failure) => Center(
            child: Text('Error: ${failure.message}'),
          ),
        );
      },
    );
  }

  Widget _buildDifficultyButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'How well did you remember?',
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.spacingMd),
        Row(
          children: [
            Expanded(
              child: _buildDifficultyButton(
                DifficultyRating.hard,
                '😰 Hard',
                AppTheme.errorColor,
              ),
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: _buildDifficultyButton(
                DifficultyRating.medium,
                '🤔 Medium',
                AppTheme.warningColor,
              ),
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: _buildDifficultyButton(
                DifficultyRating.easy,
                '😊 Easy',
                AppTheme.successColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDifficultyButton(
    DifficultyRating rating,
    String label,
    Color color,
  ) {
    final isSelected = _selectedDifficulty == rating;

    return OutlinedButton(
      onPressed: () {
        setState(() {
          _selectedDifficulty = rating;
        });
      },
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? color.withOpacity(0.1) : null,
        side: BorderSide(
          color: isSelected ? color : Colors.grey,
          width: isSelected ? 2 : 1,
        ),
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? color : AppTheme.textPrimaryColor,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildSubmitButton(ReviewState reviewState) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: reviewState.isSubmitting
            ? null
            : () {
                _submitReview();
              },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
        ),
        child: reviewState.isSubmitting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text('Submit & Continue'),
      ),
    );
  }

  void _submitReview() {
    if (_selectedDifficulty == null) return;

    // Map difficulty to quality score
    final quality = ref
        .read(spacedRepetitionEngineProvider)
        .mapDifficultyToQuality(_selectedDifficulty!, true);

    final result = ReviewResult(
      isCorrect: true,
      quality: quality,
    );

    ref.read(reviewProvider.notifier).submitReviewResult(result: result);

    // Reset state for next card
    setState(() {
      _isFlipped = false;
      _selectedDifficulty = null;
    });
  }

  Widget _buildCompletionScreen(BuildContext context) {
    final reviewState = ref.watch(reviewProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Complete'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingXl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.celebration,
                size: 100,
                color: AppTheme.successColor,
              ),
              const SizedBox(height: AppTheme.spacingXl),
              Text(
                'Great Job!',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              Text(
                'You completed ${reviewState.totalReviews} reviews',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                'Keep up the great work!',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
              ),
              const SizedBox(height: AppTheme.spacingXl * 2),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: AppTheme.spacingMd),
                  ),
                  child: const Text('Back to Home'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
