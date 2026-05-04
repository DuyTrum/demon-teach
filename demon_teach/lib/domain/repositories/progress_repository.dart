import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/progress.dart';

/// Repository interface for progress tracking operations
abstract class ProgressRepository {
  /// Get progress for a user and target language
  Future<Result<Progress>> getProgress(String userId, String targetLanguage);

  /// Update progress
  Future<Result<void>> updateProgress(Progress progress);

  /// Add XP to user's progress
  Future<Result<Progress>> addXP(
    String userId,
    String targetLanguage,
    int xp,
  );

  /// Update streak after lesson completion
  Future<Result<Progress>> updateStreak(
    String userId,
    String targetLanguage,
    DateTime completionDate,
  );

  /// Increment lessons completed count
  Future<Result<Progress>> incrementLessonsCompleted(
    String userId,
    String targetLanguage,
  );
}
