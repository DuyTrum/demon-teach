import 'package:demon_teach/core/errors/failures.dart';
import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/listening_exercise.dart';
import 'package:demon_teach/domain/repositories/listening_repository.dart';
import 'package:demon_teach/data/datasources/local/mock_listening_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Implementation of ListeningRepository using SharedPreferences and mock data
class ListeningRepositoryImpl implements ListeningRepository {
  final SharedPreferences _prefs;
  static const String _listeningResultsKey = 'listening_results';
  static const String _audioPlayedKey = 'audio_played';

  ListeningRepositoryImpl(this._prefs);

  @override
  Future<Result<ListeningExercise>> getListeningExerciseForLesson(
    String lessonId,
  ) async {
    try {
      // Extract target language from lessonId (format: lesson_en_1, en_basic_vocab_001, etc.)
      final parts = lessonId.split('_');
      String targetLanguage = 'en';

      // Try to find language code in the lessonId
      if (parts.length > 1) {
        if (parts[0] == 'lesson' && parts.length > 1) {
          targetLanguage = parts[1];
        } else if (parts[0].length == 2) {
          targetLanguage = parts[0];
        }
      }

      // Get mock listening exercise
      final exercise = MockListeningData.getListeningExerciseForLanguage(
        lessonId,
        targetLanguage,
      );

      // Check if audio has been played before
      final playedKey = '$_audioPlayedKey:${exercise.id}';
      final hasPlayed = _prefs.getBool(playedKey) ?? false;

      return Result.success(exercise.copyWith(hasPlayedOnce: hasPlayed));
    } catch (e) {
      return Result.failure(
        CacheFailure(
          message: 'Failed to get listening exercise: ${e.toString()}',
        ),
      );
    }
  }

  @override
  Future<Result<ListeningResult>> submitListeningAnswers(
    String exerciseId,
    List<ComprehensionAnswer> answers,
  ) async {
    try {
      // Calculate score
      final correctCount = answers.where((a) => a.isCorrect).length;
      final totalQuestions = answers.length;
      final percentage = (correctCount / totalQuestions) * 100;

      final result = ListeningResult(
        exerciseId: exerciseId,
        answers: answers,
        correctCount: correctCount,
        totalQuestions: totalQuestions,
        percentage: percentage,
        completedAt: DateTime.now(),
      );

      // Save result to SharedPreferences
      await _saveListeningResult(result);

      return Result.success(result);
    } catch (e) {
      return Result.failure(
        CacheFailure(
          message: 'Failed to submit listening answers: ${e.toString()}',
        ),
      );
    }
  }

  @override
  Future<Result<ListeningExercise>> getListeningExerciseById(
    String exerciseId,
  ) async {
    try {
      // Extract lessonId from exerciseId (format: listening_en_lessonId)
      final parts = exerciseId.split('_');
      if (parts.length < 3) {
        return Result.failure(
          const ValidationFailure(
            field: 'exerciseId',
            message: 'Invalid exercise ID format',
          ),
        );
      }

      final lessonId = parts.sublist(2).join('_');
      return await getListeningExerciseForLesson(lessonId);
    } catch (e) {
      return Result.failure(
        CacheFailure(
          message: 'Failed to get listening exercise: ${e.toString()}',
        ),
      );
    }
  }

  @override
  Future<Result<List<ListeningResult>>> getListeningResults(
    String userId,
  ) async {
    try {
      final resultsJson = _prefs.getString(_listeningResultsKey);
      if (resultsJson == null) {
        return Result.success([]);
      }

      final resultsList = json.decode(resultsJson) as List;
      final results = resultsList
          .map((r) => ListeningResult.fromJson(r as Map<String, dynamic>))
          .toList();

      return Result.success(results);
    } catch (e) {
      return Result.failure(
        CacheFailure(
          message: 'Failed to get listening results: ${e.toString()}',
        ),
      );
    }
  }

  @override
  Future<Result<void>> markAudioPlayed(String exerciseId) async {
    try {
      final playedKey = '$_audioPlayedKey:$exerciseId';
      await _prefs.setBool(playedKey, true);
      return Result.success(null);
    } catch (e) {
      return Result.failure(
        CacheFailure(
          message: 'Failed to mark audio as played: ${e.toString()}',
        ),
      );
    }
  }

  /// Save listening result to SharedPreferences
  Future<void> _saveListeningResult(ListeningResult result) async {
    try {
      final resultsJson = _prefs.getString(_listeningResultsKey);
      List<dynamic> results = [];
      if (resultsJson != null) {
        results = json.decode(resultsJson) as List;
      }

      results.add(result.toJson());
      await _prefs.setString(_listeningResultsKey, json.encode(results));
    } catch (e) {
      // Log error but don't throw
      print('Failed to save listening result: $e');
    }
  }
}
