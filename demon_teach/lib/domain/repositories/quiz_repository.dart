import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/quiz.dart';

/// Repository interface for quiz operations
abstract class QuizRepository {
  /// Get quiz for a specific lesson
  Future<Result<Quiz>> getQuizForLesson(String lessonId);

  /// Submit quiz answers and get result
  Future<Result<QuizResult>> submitQuizAnswers(
    String quizId,
    List<QuizAnswer> answers,
  );

  /// Get quiz by ID
  Future<Result<Quiz>> getQuizById(String quizId);

  /// Get quiz results for a user
  Future<Result<List<QuizResult>>> getQuizResults(String userId);
}
