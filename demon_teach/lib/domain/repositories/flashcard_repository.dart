import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/flashcard.dart';

/// Repository interface for flashcard operations
abstract class FlashcardRepository {
  /// Get all flashcards for a specific lesson
  Future<Result<List<Flashcard>>> getFlashcardsForLesson(String lessonId);

  /// Mark flashcard difficulty rating
  Future<Result<void>> markFlashcardDifficulty(
    String flashcardId,
    DifficultyRating rating,
  );

  /// Get flashcard by ID
  Future<Result<Flashcard>> getFlashcardById(String flashcardId);

  /// Get all flashcards marked as hard (for review)
  Future<Result<List<Flashcard>>> getHardFlashcards(String userId);
}
