import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demon_teach/core/errors/failures.dart';
import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/listening_exercise.dart';
import 'package:demon_teach/domain/repositories/listening_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Implementation of ListeningRepository using Firestore
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
      final docSnap = await FirebaseFirestore.instance.collection('lessons').doc(lessonId).get();
      if (!docSnap.exists || docSnap.data() == null) {
        return Result.failure(
          ServerFailure(message: 'Lesson $lessonId not found in Firestore.'),
        );
      }

      final data = docSnap.data()!;
      final content = data['content'] as Map<String, dynamic>?;
      if (content == null || content['listening'] == null) {
        return Result.failure(
          const ServerFailure(message: 'Listening exercise is not generated for this lesson.'),
        );
      }

      final listeningMap = Map<String, dynamic>.from(content['listening'] as Map);
      if (listeningMap['lessonId'] == null) {
        listeningMap['lessonId'] = lessonId;
      }
      if (listeningMap['id'] == null) {
        listeningMap['id'] = 'listening_$lessonId';
      }

      // Check if audio has been played before
      final playedKey = '$_audioPlayedKey:${listeningMap['id']}';
      final hasPlayed = _prefs.getBool(playedKey) ?? false;
      listeningMap['hasPlayedOnce'] = hasPlayed;

      return Result.success(ListeningExercise.fromJson(listeningMap));
    } catch (e) {
      return Result.failure(
        ServerFailure(message: 'Failed to get listening exercise: ${e.toString()}'),
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
      final percentage = totalQuestions > 0 ? (correctCount / totalQuestions) * 100 : 0.0;

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
      final lessonId = exerciseId.replaceFirst('listening_', '');
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
      print('Failed to save listening result: $e');
    }
  }
}
