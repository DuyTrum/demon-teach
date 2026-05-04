import 'package:flutter_test/flutter_test.dart';
import 'package:demon_teach/domain/entities/review_item.dart';
import 'package:demon_teach/domain/services/spaced_repetition_engine.dart';
import 'dart:math';

/// **Validates: Requirements 11.2, 11.5, 11.6**
///
/// Property-based tests for spaced repetition system
/// Feature: demon-teach-language-learning-app
void main() {
  group('Spaced Repetition Properties', () {
    late SpacedRepetitionEngine engine;
    late Random random;

    setUp(() {
      engine = SpacedRepetitionEngine();
      random = Random(42); // Fixed seed for reproducibility
    });

    /// Property 15: Spaced repetition interval calculation
    ///
    /// **Validates: Requirements 10.3, 10.4, 10.5**
    ///
    /// For any review item with current interval I and ease factor E, when reviewed:
    /// (1) if correct, the next interval SHALL be I * E (with minimum intervals of 1 day, then 6 days for first two reviews)
    /// (2) if incorrect, the interval SHALL reset to 1 day
    test('Property 15: Spaced repetition interval calculation', () {
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        // Generate random review item
        final repetitionCount = random.nextInt(20); // 0-19
        final easeFactor = 1.3 + random.nextDouble() * 2.0; // 1.3-3.3
        final intervalDays =
            repetitionCount == 0 ? 1 : random.nextInt(365) + 1; // 1-365
        final quality = random.nextInt(6); // 0-5
        final isCorrect = quality > 0;

        final reviewItem = ReviewItem(
          id: 'test_$i',
          userId: 'user1',
          contentId: 'content_$i',
          type: ReviewItemType.flashcard,
          nextReviewDate: DateTime.now(),
          repetitionCount: repetitionCount,
          easeFactor: easeFactor,
          intervalDays: intervalDays,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final result = ReviewResult(
          isCorrect: isCorrect,
          quality: quality,
        );

        final nextInterval = engine.calculateNextInterval(reviewItem, result);

        if (isCorrect) {
          // Property: Correct answer should follow SM-2 progression
          if (repetitionCount == 0) {
            // First review: interval should be 1 day
            expect(
              nextInterval.inDays,
              equals(1),
              reason:
                  'First review (repetition 0) should have 1 day interval, got ${nextInterval.inDays}',
            );
          } else if (repetitionCount == 1) {
            // Second review: interval should be 6 days
            expect(
              nextInterval.inDays,
              equals(6),
              reason:
                  'Second review (repetition 1) should have 6 days interval, got ${nextInterval.inDays}',
            );
          } else {
            // Subsequent reviews: interval should be I * EF (rounded)
            // Note: EF is updated during calculation, so we need to calculate the new EF
            final newEaseFactor = easeFactor +
                (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
            final clampedEF = max(1.3, newEaseFactor);
            final expectedInterval = (intervalDays * clampedEF).round();
            expect(
              nextInterval.inDays,
              equals(expectedInterval),
              reason:
                  'Review $repetitionCount should have interval ${intervalDays} * ${clampedEF.toStringAsFixed(2)} = $expectedInterval days, got ${nextInterval.inDays}',
            );
          }
        } else {
          // Property: Incorrect answer should reset to 1 day
          expect(
            nextInterval.inDays,
            equals(1),
            reason:
                'Incorrect answer should reset interval to 1 day, got ${nextInterval.inDays}',
          );
        }
      }
    });

    /// Property 15 (Extended): Ease factor updates correctly
    ///
    /// Validates that ease factor is updated according to SM-2 formula
    /// and never goes below minimum of 1.3
    test('Property 15 (Extended): Ease factor updates correctly', () {
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        final repetitionCount = random.nextInt(10);
        final initialEaseFactor = 1.3 + random.nextDouble() * 2.0;
        final intervalDays = max(1, random.nextInt(100));
        final quality = random.nextInt(6); // 0-5

        final reviewItem = ReviewItem(
          id: 'test_$i',
          userId: 'user1',
          contentId: 'content_$i',
          type: ReviewItemType.flashcard,
          nextReviewDate: DateTime.now(),
          repetitionCount: repetitionCount,
          easeFactor: initialEaseFactor,
          intervalDays: intervalDays,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final result = ReviewResult(
          isCorrect: quality > 0,
          quality: quality,
        );

        final updatedItem =
            engine.calculateUpdatedReviewItem(reviewItem, result);

        if (result.isCorrect) {
          // Calculate expected ease factor
          // EF' = EF + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
          final expectedEF = initialEaseFactor +
              (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
          final clampedEF = max(1.3, expectedEF);

          expect(
            updatedItem.easeFactor,
            closeTo(clampedEF, 0.001),
            reason:
                'Ease factor should be updated to $clampedEF, got ${updatedItem.easeFactor}',
          );

          // Property: Ease factor should never be below 1.3
          expect(
            updatedItem.easeFactor,
            greaterThanOrEqualTo(1.3),
            reason: 'Ease factor should never be below 1.3',
          );
        } else {
          // Property: Ease factor should remain unchanged on incorrect answer
          expect(
            updatedItem.easeFactor,
            equals(initialEaseFactor),
            reason: 'Ease factor should remain unchanged on incorrect answer',
          );
        }
      }
    });

    /// Property 16: Review item due date logic
    ///
    /// **Validates: Requirements 11.2, 11.5, 11.6**
    ///
    /// For any review item with next review date D and current date C,
    /// the item SHALL be included in the due reviews list if and only if D <= C
    test('Property 16: Review item due date logic', () {
      const iterations = 100;
      final now = DateTime.now();

      for (int i = 0; i < iterations; i++) {
        // Generate random offset from current time (-30 to +30 days)
        final offsetDays = random.nextInt(61) - 30;
        final nextReviewDate = now.add(Duration(days: offsetDays));

        final reviewItem = ReviewItem(
          id: 'test_$i',
          userId: 'user1',
          contentId: 'content_$i',
          type: ReviewItemType.flashcard,
          nextReviewDate: nextReviewDate,
          repetitionCount: random.nextInt(10),
          easeFactor: 2.5,
          intervalDays: random.nextInt(30) + 1,
          createdAt: now,
          updatedAt: now,
        );

        final isDue = reviewItem.isDue;
        final shouldBeDue = nextReviewDate.isBefore(now) ||
            nextReviewDate.isAtSameMomentAs(now);

        // Property: Item is due if and only if next review date <= current date
        expect(
          isDue,
          equals(shouldBeDue),
          reason:
              'Review item with next review date $nextReviewDate (offset: $offsetDays days) '
              'should ${shouldBeDue ? "be" : "not be"} due at $now, but isDue=$isDue',
        );

        // Additional validation: Past dates should always be due
        if (nextReviewDate.isBefore(now)) {
          expect(
            isDue,
            isTrue,
            reason: 'Review item with past date should be due',
          );
        }

        // Additional validation: Future dates should never be due
        if (nextReviewDate.isAfter(now)) {
          expect(
            isDue,
            isFalse,
            reason: 'Review item with future date should not be due',
          );
        }
      }
    });

    /// Property 16 (Extended): Due date calculation after review
    ///
    /// Validates that after a review, the next review date is correctly
    /// calculated based on the interval
    test('Property 16 (Extended): Due date calculation after review', () {
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        final repetitionCount = random.nextInt(10);
        final easeFactor = 1.3 + random.nextDouble() * 2.0;
        final intervalDays = max(1, random.nextInt(100));
        final quality = random.nextInt(6);

        final now = DateTime.now();
        final reviewItem = ReviewItem(
          id: 'test_$i',
          userId: 'user1',
          contentId: 'content_$i',
          type: ReviewItemType.flashcard,
          nextReviewDate: now,
          repetitionCount: repetitionCount,
          easeFactor: easeFactor,
          intervalDays: intervalDays,
          createdAt: now,
          updatedAt: now,
        );

        final result = ReviewResult(
          isCorrect: quality > 0,
          quality: quality,
        );

        final updatedItem =
            engine.calculateUpdatedReviewItem(reviewItem, result);
        final nextInterval = engine.calculateNextInterval(reviewItem, result);

        // Property: Next review date should be current time + interval
        final expectedNextReview = now.add(nextInterval);

        // Allow small time difference due to execution time
        final timeDifference =
            updatedItem.nextReviewDate.difference(expectedNextReview).abs();

        expect(
          timeDifference.inSeconds,
          lessThan(5),
          reason:
              'Next review date should be approximately $expectedNextReview, '
              'got ${updatedItem.nextReviewDate} (difference: ${timeDifference.inSeconds}s)',
        );

        // Property: Updated item should not be due immediately after review
        // (unless interval is 0, which shouldn't happen)
        if (nextInterval.inDays > 0) {
          expect(
            updatedItem.isDue,
            isFalse,
            reason: 'Item should not be due immediately after review',
          );
        }
      }
    });

    /// Property: Repetition count progression
    ///
    /// Validates that repetition count increases on correct answers
    /// and resets to 0 on incorrect answers
    test('Property: Repetition count progression', () {
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        final initialRepetitionCount = random.nextInt(20);
        final quality = random.nextInt(6);
        final isCorrect = quality > 0;

        final reviewItem = ReviewItem(
          id: 'test_$i',
          userId: 'user1',
          contentId: 'content_$i',
          type: ReviewItemType.flashcard,
          nextReviewDate: DateTime.now(),
          repetitionCount: initialRepetitionCount,
          easeFactor: 2.5,
          intervalDays: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final result = ReviewResult(
          isCorrect: isCorrect,
          quality: quality,
        );

        final updatedItem =
            engine.calculateUpdatedReviewItem(reviewItem, result);

        if (isCorrect) {
          // Property: Correct answer should increment repetition count
          expect(
            updatedItem.repetitionCount,
            equals(initialRepetitionCount + 1),
            reason:
                'Correct answer should increment repetition count from $initialRepetitionCount to ${initialRepetitionCount + 1}',
          );
        } else {
          // Property: Incorrect answer should reset repetition count to 0
          expect(
            updatedItem.repetitionCount,
            equals(0),
            reason: 'Incorrect answer should reset repetition count to 0',
          );
        }
      }
    });
  });
}
