import 'package:demon_teach/domain/entities/review_item.dart';
import 'package:demon_teach/domain/entities/flashcard.dart';

/// Spaced Repetition Engine implementing SM-2 algorithm
///
/// The SM-2 algorithm calculates optimal review intervals based on:
/// - Repetition count
/// - Ease factor (difficulty)
/// - Quality of recall (0-5 scale)
class SpacedRepetitionEngine {
  // Initial values for SM-2 algorithm
  static const double initialEaseFactor = 2.5;
  static const int initialInterval = 1;
  static const double minimumEaseFactor = 1.3;

  /// Calculate next review interval based on SM-2 algorithm
  ///
  /// Returns the duration until the next review
  Duration calculateNextInterval(ReviewItem item, ReviewResult result) {
    int newRepetitionCount = item.repetitionCount;
    double newEaseFactor = item.easeFactor;
    int newIntervalDays = item.intervalDays;

    if (result.isCorrect) {
      newRepetitionCount++;

      // Update ease factor based on quality (0-5 scale)
      // Formula: EF' = EF + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
      newEaseFactor = item.easeFactor +
          (0.1 - (5 - result.quality) * (0.08 + (5 - result.quality) * 0.02));

      // Minimum ease factor is 1.3
      if (newEaseFactor < minimumEaseFactor) {
        newEaseFactor = minimumEaseFactor;
      }

      // Calculate new interval based on repetition count
      if (newRepetitionCount == 1) {
        newIntervalDays = 1;
      } else if (newRepetitionCount == 2) {
        newIntervalDays = 6;
      } else {
        // I(n) = I(n-1) * EF
        newIntervalDays = (item.intervalDays * newEaseFactor).round();
      }
    } else {
      // Reset on failure
      newRepetitionCount = 0;
      newIntervalDays = 1;
      // Ease factor stays the same
    }

    return Duration(days: newIntervalDays);
  }

  /// Map difficulty rating to quality score (0-5)
  ///
  /// Quality mapping:
  /// - 5: Perfect recall (easy)
  /// - 4: Correct with hesitation
  /// - 3: Correct with difficulty (medium)
  /// - 2: Incorrect but remembered
  /// - 1: Incorrect, barely remembered (hard)
  /// - 0: Complete blackout
  int mapDifficultyToQuality(DifficultyRating rating, bool isCorrect) {
    if (!isCorrect) return 0;

    switch (rating) {
      case DifficultyRating.easy:
        return 5;
      case DifficultyRating.medium:
        return 3;
      case DifficultyRating.hard:
        return 1;
    }
  }

  /// Calculate updated review item after review
  ReviewItem calculateUpdatedReviewItem(
    ReviewItem item,
    ReviewResult result,
  ) {
    final nextInterval = calculateNextInterval(item, result);
    final nextReviewDate = DateTime.now().add(nextInterval);

    // Calculate new ease factor
    double newEaseFactor = item.easeFactor;
    if (result.isCorrect) {
      newEaseFactor = item.easeFactor +
          (0.1 - (5 - result.quality) * (0.08 + (5 - result.quality) * 0.02));
      if (newEaseFactor < minimumEaseFactor) {
        newEaseFactor = minimumEaseFactor;
      }
    }

    return item.copyWith(
      nextReviewDate: nextReviewDate,
      repetitionCount: result.isCorrect ? item.repetitionCount + 1 : 0,
      easeFactor: newEaseFactor,
      intervalDays: nextInterval.inDays,
      updatedAt: DateTime.now(),
    );
  }

  /// Get quality score from user feedback
  ///
  /// For quiz/flashcard results:
  /// - Correct + Easy = 5
  /// - Correct + Medium = 3
  /// - Correct + Hard = 1
  /// - Incorrect = 0
  int getQualityFromFeedback({
    required bool isCorrect,
    DifficultyRating? difficultyRating,
  }) {
    if (!isCorrect) return 0;

    if (difficultyRating == null) {
      // Default to medium quality if no rating provided
      return 3;
    }

    return mapDifficultyToQuality(difficultyRating, isCorrect);
  }
}
