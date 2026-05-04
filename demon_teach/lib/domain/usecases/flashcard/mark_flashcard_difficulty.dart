import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/flashcard.dart';
import 'package:demon_teach/domain/repositories/flashcard_repository.dart';

/// Use case to mark flashcard difficulty rating
class MarkFlashcardDifficulty {
  final FlashcardRepository _repository;

  MarkFlashcardDifficulty(this._repository);

  Future<Result<void>> call({
    required String flashcardId,
    required DifficultyRating rating,
  }) async {
    return await _repository.markFlashcardDifficulty(flashcardId, rating);
  }
}
