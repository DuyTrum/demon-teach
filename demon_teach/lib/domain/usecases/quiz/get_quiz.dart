import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/quiz.dart';
import 'package:demon_teach/domain/repositories/quiz_repository.dart';

/// Use case to get quiz for a lesson
class GetQuiz {
  final QuizRepository _repository;

  GetQuiz(this._repository);

  Future<Result<Quiz>> call(String lessonId) async {
    return await _repository.getQuizForLesson(lessonId);
  }
}
