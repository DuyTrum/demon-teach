import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/learning_path.dart';

/// Repository interface for learning path operations
abstract class LearningPathRepository {
  /// Save a learning path
  Future<Result<void>> saveLearningPath(LearningPath path);

  /// Get learning path by user ID and target language
  Future<Result<LearningPath?>> getLearningPath({
    required String userId,
    required String targetLanguage,
  });

  /// Update learning path progress (current lesson index)
  Future<Result<void>> updateProgress({
    required String pathId,
    required int currentLessonIndex,
  });

  /// Delete a learning path
  Future<Result<void>> deleteLearningPath(String pathId);

  /// Check if a learning path exists for user and language
  Future<Result<bool>> hasLearningPath({
    required String userId,
    required String targetLanguage,
  });
}
