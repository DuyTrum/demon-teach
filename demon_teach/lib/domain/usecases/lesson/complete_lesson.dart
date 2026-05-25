import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/repositories/lesson_repository.dart';
import 'package:demon_teach/domain/repositories/learning_path_repository.dart';
import 'package:demon_teach/domain/repositories/review_repository.dart';
import 'package:demon_teach/domain/entities/flashcard.dart';
import 'package:demon_teach/domain/entities/review_item.dart';

/// Use case for completing a lesson
class CompleteLesson {
  final LessonRepository _lessonRepository;
  final LearningPathRepository _learningPathRepository;
  final ReviewRepository _reviewRepository;

  CompleteLesson(
    this._lessonRepository,
    this._learningPathRepository,
    this._reviewRepository,
  );

  Future<Result<void>> call({
    required String userId,
    required String lessonId,
    required int score,
    required String targetLanguage,
    List<Flashcard>? flashcards,
  }) async {
    // Mark lesson as completed
    final completeResult = await _lessonRepository.completeLesson(
      userId: userId,
      lessonId: lessonId,
      score: score,
    );

    return completeResult.when(
      success: (_) async {
        // If flashcards are provided, schedule them for review
        if (flashcards != null && flashcards.isNotEmpty) {
          for (final card in flashcards) {
            // Check if review item already exists
            final existingResult = await _reviewRepository.getReviewItemByContentId(
              userId,
              card.id,
            );
            
            await existingResult.when(
              success: (existingItem) async {
                if (existingItem == null) {
                  // Only add if it doesn't exist yet
                  final newItem = ReviewItem.initial(
                    userId: userId,
                    contentId: card.id,
                    type: ReviewItemType.flashcard,
                  );
                  await _reviewRepository.addReviewItem(newItem);
                }
              },
              failure: (_) async {
                // Ignore failure and try to add anyway as fallback
                final newItem = ReviewItem.initial(
                  userId: userId,
                  contentId: card.id,
                  type: ReviewItemType.flashcard,
                );
                await _reviewRepository.addReviewItem(newItem);
              },
            );
          }
        }

        // Get learning path
        final pathResult = await _learningPathRepository.getLearningPath(
          userId: userId,
          targetLanguage: targetLanguage,
        );

        return pathResult.when(
          success: (path) async {
            if (path == null) {
              return Result.success(null);
            }

            // Only advance the learning path if the completed lesson is the current one
            if (path.currentLessonId == lessonId) {
              final newIndex = path.currentLessonIndex + 1;
              return await _learningPathRepository.updateProgress(
                pathId: 'user_${userId}_$targetLanguage', // Enforce correct docId
                currentLessonIndex: newIndex,
              );
            }

            // If it's a previous lesson being replayed, don't advance the path
            return Result.success(null);
          },
          failure: (failure) => Result.failure(failure),
        );
      },
      failure: (failure) => Result.failure(failure),
    );
  }
}
