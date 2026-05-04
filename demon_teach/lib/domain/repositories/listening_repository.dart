import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/listening_exercise.dart';

/// Repository interface for listening exercise operations
abstract class ListeningRepository {
  /// Get listening exercise for a specific lesson
  Future<Result<ListeningExercise>> getListeningExerciseForLesson(
    String lessonId,
  );

  /// Submit listening exercise answers and get result
  Future<Result<ListeningResult>> submitListeningAnswers(
    String exerciseId,
    List<ComprehensionAnswer> answers,
  );

  /// Get listening exercise by ID
  Future<Result<ListeningExercise>> getListeningExerciseById(
    String exerciseId,
  );

  /// Get listening results for a user
  Future<Result<List<ListeningResult>>> getListeningResults(String userId);

  /// Mark audio as played
  Future<Result<void>> markAudioPlayed(String exerciseId);
}
