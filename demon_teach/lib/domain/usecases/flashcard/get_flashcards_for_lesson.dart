import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/flashcard.dart';
import 'package:demon_teach/domain/repositories/flashcard_repository.dart';

/// Use case to get flashcards for a specific lesson
class GetFlashcardsForLesson {
  final FlashcardRepository _repository;

  GetFlashcardsForLesson(this._repository);

  Future<Result<List<Flashcard>>> call(String lessonId) async {
    return await _repository.getFlashcardsForLesson(lessonId);
  }
}
