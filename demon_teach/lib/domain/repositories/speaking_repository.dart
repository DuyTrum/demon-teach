import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/speaking_exercise.dart';

/// Repository interface for speaking exercises
abstract class SpeakingRepository {
  /// Get speaking exercise for a lesson
  Future<Result<SpeakingExercise>> getSpeakingExercise(String lessonId);

  /// Save user recording
  Future<Result<SpeakingExercise>> saveRecording(
    String exerciseId,
    String recordingPath,
  );

  /// Save pronunciation feedback
  Future<Result<SpeakingExercise>> saveFeedback(
    String exerciseId,
    PronunciationFeedback feedback,
  );

  /// Delete user recording
  Future<Result<void>> deleteRecording(String exerciseId);
}
