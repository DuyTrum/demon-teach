import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/core/errors/failures.dart';
import 'package:demon_teach/domain/entities/speaking_exercise.dart';
import 'package:demon_teach/domain/repositories/speaking_repository.dart';

/// Implementation of SpeakingRepository using Firestore and local cache for recordings
class SpeakingRepositoryImpl implements SpeakingRepository {
  final SharedPreferences _prefs;

  static const String _keyPrefix = 'speaking_exercise_';

  SpeakingRepositoryImpl(this._prefs);

  @override
  Future<Result<SpeakingExercise>> getSpeakingExercise(String lessonId) async {
    try {
      final cleanLessonId = lessonId.replaceAll('speaking_exercise_', '').replaceAll('speaking_', '');
      final localKey = '$_keyPrefix$cleanLessonId';

      // Check if we have a locally cached progress version containing recordings or feedback
      final jsonString = _prefs.getString(localKey);
      if (jsonString != null) {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        return Result.success(SpeakingExercise.fromJson(json));
      }

      // Fetch from Firestore
      final docSnap = await FirebaseFirestore.instance.collection('lessons').doc(cleanLessonId).get();
      if (!docSnap.exists || docSnap.data() == null) {
        return Result.failure(
          ServerFailure(message: 'Lesson $cleanLessonId not found in Firestore.'),
        );
      }

      final data = docSnap.data()!;
      final content = data['content'] as Map<String, dynamic>?;
      if (content == null || content['sections'] == null) {
        return Result.failure(
          const ServerFailure(message: 'Lesson content sections are missing.'),
        );
      }

      final List<dynamic> sections = content['sections'] as List;
      final speakingSection = sections.firstWhere(
        (s) => s['type'] == 'speaking',
        orElse: () => null,
      );

      if (speakingSection == null || speakingSection['items'] == null || (speakingSection['items'] as List).isEmpty) {
        return Result.failure(
          const ServerFailure(message: 'Speaking exercises are not generated for this lesson.'),
        );
      }

      final firstItem = speakingSection['items'][0] as Map<String, dynamic>;
      final phrase = firstItem['phrase'] as String;
      final audioUrl = firstItem['audioUrl'] as String? ?? '';

      final exercise = SpeakingExercise(
        id: 'speaking_$cleanLessonId',
        lessonId: cleanLessonId,
        phrase: phrase,
        modelAudioUrl: audioUrl,
      );

      // Save initial state locally
      await _prefs.setString(localKey, jsonEncode(exercise.toJson()));

      return Result.success(exercise);
    } catch (e) {
      return Result.failure(
        ServerFailure(message: 'Failed to get speaking exercise: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<SpeakingExercise>> saveRecording(
    String exerciseId,
    String recordingPath,
  ) async {
    try {
      final cleanLessonId = exerciseId.replaceAll('speaking_exercise_', '').replaceAll('speaking_', '');
      final localKey = '$_keyPrefix$cleanLessonId';
      final jsonString = _prefs.getString(localKey);

      SpeakingExercise exercise;
      if (jsonString == null) {
        final loadResult = await getSpeakingExercise(cleanLessonId);
        exercise = await loadResult.when(
          success: (ex) => ex,
          failure: (f) => throw Exception(f.message),
        );
      } else {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        exercise = SpeakingExercise.fromJson(json);
      }

      // Update with recording path and timestamp
      final updatedExercise = exercise.copyWith(
        userRecordingPath: recordingPath,
        recordedAt: DateTime.now(),
      );

      // Save updated exercise
      await _prefs.setString(
        localKey,
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
      final cleanLessonId = exerciseId.replaceAll('speaking_exercise_', '').replaceAll('speaking_', '');
      final localKey = '$_keyPrefix$cleanLessonId';
      final jsonString = _prefs.getString(localKey);

      SpeakingExercise exercise;
      if (jsonString == null) {
        final loadResult = await getSpeakingExercise(cleanLessonId);
        exercise = await loadResult.when(
          success: (ex) => ex,
          failure: (f) => throw Exception(f.message),
        );
      } else {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        exercise = SpeakingExercise.fromJson(json);
      }

      // Update with feedback
      final updatedExercise = exercise.copyWith(
        feedback: feedback,
      );

      // Save updated exercise
      await _prefs.setString(
        localKey,
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
      final cleanLessonId = exerciseId.replaceAll('speaking_exercise_', '').replaceAll('speaking_', '');
      final localKey = '$_keyPrefix$cleanLessonId';
      final jsonString = _prefs.getString(localKey);

      if (jsonString == null) {
        return Result.success(null);
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
        localKey,
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
