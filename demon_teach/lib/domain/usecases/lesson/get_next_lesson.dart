import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/lesson.dart';
import 'package:demon_teach/domain/repositories/lesson_repository.dart';

/// Use case for getting the next lesson in learning path
class GetNextLesson {
  final LessonRepository _repository;

  GetNextLesson(this._repository);

  Future<Result<Lesson?>> call({
    required String userId,
    required String targetLanguage,
  }) async {
    return await _repository.getNextLesson(
      userId: userId,
      targetLanguage: targetLanguage,
    );
  }
}
