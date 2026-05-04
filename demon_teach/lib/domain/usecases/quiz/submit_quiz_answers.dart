import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/quiz.dart';
import 'package:demon_teach/domain/repositories/quiz_repository.dart';

/// Use case to submit quiz answers
class SubmitQuizAnswers {
  final QuizRepository _repository;

  SubmitQuizAnswers(this._repository);

  Future<Result<QuizResult>> call({
    required String quizId,
    required List<QuizAnswer> answers,
  }) async {
    return await _repository.submitQuizAnswers(quizId, answers);
  }
}
