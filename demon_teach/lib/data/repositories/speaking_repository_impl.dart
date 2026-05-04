import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/core/errors/failures.dart';
import 'package:demon_teach/domain/entities/speaking_exercise.dart';
import 'package:demon_teach/domain/repositories/speaking_repository.dart';

/// Implementation of SpeakingRepository using SharedPreferences
class SpeakingRepositoryImpl implements SpeakingRepository {
  final SharedPreferences _prefs;

  static const String _keyPrefix = 'speaking_exercise_';
  static const String _mockDataKey = 'speaking_mock_data';

  SpeakingRepositoryImpl(this._prefs) {
    _initializeMockData();
  }

  /// Initialize mock data for testing
  void _initializeMockData() {
    final mockDataExists = _prefs.containsKey(_mockDataKey);
    if (!mockDataExists) {
      // Create mock speaking exercises for testing
      final mockExercises = [
        SpeakingExercise(
          id: 'speaking_en_001',
          lessonId: 'en_basic_vocab_001',
          phrase: 'Hello, how are you?',
          modelAudioUrl: 'https://example.com/audio/hello_how_are_you.mp3',
        ),
        SpeakingExercise(
          id: 'speaking_en_002',
          lessonId: 'en_basic_vocab_001',
          phrase: 'Nice to meet you',
          modelAudioUrl: 'https://example.com/audio/nice_to_meet_you.mp3',
        ),
        SpeakingExercise(
          id: 'speaking_en_003',
          lessonId: 'en_basic_vocab_001',
          phrase: 'Thank you very much',
          modelAudioUrl: 'https://example.com/audio/thank_you.mp3',
        ),
      ];

      // Save mock exercises
      for (final exercise in mockExercises) {
        _prefs.setString(
          '$_keyPrefix${exercise.id}',
          jsonEncode(exercise.toJson()),
        );
      }

      _prefs.setBool(_mockDataKey, true);
    }
  }

  @override
  Future<Result<SpeakingExercise>> getSpeakingExercise(String lessonId) async {
    try {
      // Find first speaking exercise for this lesson
      final keys = _prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith(_keyPrefix)) {
          final jsonString = _prefs.getString(key);
          if (jsonString != null) {
            final json = jsonDecode(jsonString) as Map<String, dynamic>;
            final exercise = SpeakingExercise.fromJson(json);
            if (exercise.lessonId == lessonId) {
              return Result.success(exercise);
            }
          }
        }
      }

      return Result.failure(
        CacheFailure(
            message: 'No speaking exercise found for lesson: $lessonId'),
      );
    } catch (e) {
      return Result.failure(
        CacheFailure(
            message: 'Failed to get speaking exercise: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<SpeakingExercise>> saveRecording(
    String exerciseId,
    String recordingPath,
  ) async {
    try {
      final key = '$_keyPrefix$exerciseId';
      final jsonString = _prefs.getString(key);

      if (jsonString == null) {
        return Result.failure(
          CacheFailure(message: 'Speaking exercise not found: $exerciseId'),
        );
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final exercise = SpeakingExercise.fromJson(json);

      // Update with recording path and timestamp
      final updatedExercise = exercise.copyWith(
        userRecordingPath: recordingPath,
        recordedAt: DateTime.now(),
      );

      // Save updated exercise
      await _prefs.setString(
        key,
        jsonEncode(updatedExercise.toJson()),
      );

      return Result.success(updatedExercise);
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to save recording: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<SpeakingExercise>> saveFeedback(
    String exerciseId,
    PronunciationFeedback feedback,
  ) async {
    try {
      final key = '$_keyPrefix$exerciseId';
      final jsonString = _prefs.getString(key);

      if (jsonString == null) {
        return Result.failure(
          CacheFailure(message: 'Speaking exercise not found: $exerciseId'),
        );
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final exercise = SpeakingExercise.fromJson(json);

      // Update with feedback
      final updatedExercise = exercise.copyWith(
        feedback: feedback,
      );

      // Save updated exercise
      await _prefs.setString(
        key,
        jsonEncode(updatedExercise.toJson()),
      );

      return Result.success(updatedExercise);
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to save feedback: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<void>> deleteRecording(String exerciseId) async {
    try {
      final key = '$_keyPrefix$exerciseId';
      final jsonString = _prefs.getString(key);

      if (jsonString == null) {
        return Result.failure(
          CacheFailure(message: 'Speaking exercise not found: $exerciseId'),
        );
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final exercise = SpeakingExercise.fromJson(json);

      // Clear recording and feedback
      final updatedExercise = exercise.copyWith(
        userRecordingPath: null,
        feedback: null,
        recordedAt: null,
      );

      // Save updated exercise
      await _prefs.setString(
        key,
        jsonEncode(updatedExercise.toJson()),
      );

      return Result.success(null);
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to delete recording: ${e.toString()}'),
      );
    }
  }
}
