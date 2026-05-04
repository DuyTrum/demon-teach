import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/lesson.dart';
import 'package:demon_teach/domain/repositories/lesson_repository.dart';

/// Use case for getting a lesson by ID
class GetLessonById {
  final LessonRepository _repository;

  GetLessonById(this._repository);

  Future<Result<Lesson?>> call(String lessonId,
      {bool includeContent = true}) async {
    return await _repository.getLessonById(lessonId,
        includeContent: includeContent);
  }
}
