import 'package:demon_teach/core/errors/failures.dart';
import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/quiz.dart';
import 'package:demon_teach/domain/repositories/quiz_repository.dart';
import 'package:demon_teach/data/datasources/local/mock_quiz_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Implementation of QuizRepository using SharedPreferences and mock data
class QuizRepositoryImpl implements QuizRepository {
  final SharedPreferences _prefs;
  static const String _quizResultsKey = 'quiz_results';

  QuizRepositoryImpl(this._prefs);

  @override
  Future<Result<Quiz>> getQuizForLesson(String lessonId) async {
    try {
      // Extract target language from lessonId (format: lesson_en_1, lesson_zh_1, etc.)
      final parts = lessonId.split('_');
      final targetLanguage = parts.length > 1 ? parts[1] : 'en';

      // Get mock quiz
      final quiz = MockQuizData.getQuizForLanguage(lessonId, targetLanguage);

      return Result.success(quiz);
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to get quiz: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<QuizResult>> submitQuizAnswers(
    String quizId,
    List<QuizAnswer> answers,
  ) async {
    try {
      // Get the quiz to calculate score
      final parts = quizId.split('_');
      final lessonId = parts.sublist(2).join('_');
      final quizResult = await getQuizForLesson(lessonId);

      return quizResult.when(
        success: (quiz) async {
          // Calculate total score
          int totalScore = 0;
          for (final answer in answers) {
            if (answer.isCorrect) {
              totalScore += answer.pointsEarned;
            }
          }

          final maxScore = quiz.totalPoints;
          final percentage = (totalScore / maxScore) * 100;
          final passed = percentage >= quiz.passingScore;

          final result = QuizResult(
            quizId: quizId,
            answers: answers,
            totalScore: totalScore,
            maxScore: maxScore,
            percentage: percentage,
            passed: passed,
            completedAt: DateTime.now(),
          );

          // Save result to SharedPreferences
          await _saveQuizResult(result);

          return Result.success(result);
        },
        failure: (failure) => Result.failure(failure),
      );
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to submit quiz answers: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<Quiz>> getQuizById(String quizId) async {
    try {
      // Extract lessonId from quizId (format: quiz_en_lessonId)
      final parts = quizId.split('_');
      if (parts.length < 3) {
        return Result.failure(
          const ValidationFailure(
            field: 'quizId',
            message: 'Invalid quiz ID format',
          ),
        );
      }

      final lessonId = parts.sublist(2).join('_');
      return await getQuizForLesson(lessonId);
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to get quiz: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<List<QuizResult>>> getQuizResults(String userId) async {
    try {
      final resultsJson = _prefs.getString(_quizResultsKey);
      if (resultsJson == null) {
        return Result.success([]);
      }

      final resultsList = json.decode(resultsJson) as List;
      final results = resultsList
          .map((r) => QuizResult.fromJson(r as Map<String, dynamic>))
          .toList();

      return Result.success(results);
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to get quiz results: ${e.toString()}'),
      );
    }
  }

  /// Save quiz result to SharedPreferences
  Future<void> _saveQuizResult(QuizResult result) async {
    try {
      final resultsJson = _prefs.getString(_quizResultsKey);
      List<dynamic> results = [];
      if (resultsJson != null) {
        results = json.decode(resultsJson) as List;
      }

      results.add(result.toJson());
      await _prefs.setString(_quizResultsKey, json.encode(results));
    } catch (e) {
      // Log error but don't throw
      print('Failed to save quiz result: $e');
    }
  }
}
