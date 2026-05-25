import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demon_teach/core/errors/failures.dart';
import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/quiz.dart';
import 'package:demon_teach/domain/repositories/quiz_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Implementation of QuizRepository using Firestore
class QuizRepositoryImpl implements QuizRepository {
  final SharedPreferences _prefs;
  static const String _quizResultsKey = 'quiz_results';

  QuizRepositoryImpl(this._prefs);

  @override
  Future<Result<Quiz>> getQuizForLesson(String lessonId) async {
    try {
      final docSnap = await FirebaseFirestore.instance.collection('lessons').doc(lessonId).get();
      if (!docSnap.exists || docSnap.data() == null) {
        return Result.failure(
          ServerFailure(message: 'Lesson $lessonId not found in Firestore.'),
        );
      }

      final data = docSnap.data()!;
      final content = data['content'] as Map<String, dynamic>?;
      if (content == null || content['quiz'] == null) {
        return Result.failure(
          const ServerFailure(message: 'Quiz content is not generated for this lesson.'),
        );
      }

      final quizMap = Map<String, dynamic>.from(content['quiz'] as Map);
      if (quizMap['lessonId'] == null) {
        quizMap['lessonId'] = lessonId;
      }
      if (quizMap['id'] == null) {
        quizMap['id'] = 'quiz_$lessonId';
      }

      return Result.success(Quiz.fromJson(quizMap));
    } catch (e) {
      return Result.failure(
        ServerFailure(message: 'Failed to get quiz: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<QuizResult>> submitQuizAnswers(
    String quizId,
    List<QuizAnswer> answers,
  ) async {
    try {
      // Reconstruct lessonId from quizId
      final lessonId = quizId.replaceFirst('quiz_', '');
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
          final percentage = maxScore > 0 ? (totalScore / maxScore) * 100 : 0.0;
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
      final lessonId = quizId.replaceFirst('quiz_', '');
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
      print('Failed to save quiz result: $e');
    }
  }
}
