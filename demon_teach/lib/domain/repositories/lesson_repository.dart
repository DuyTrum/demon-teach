import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/lesson.dart';

/// Repository interface for lesson operations
abstract class LessonRepository {
  /// Get lesson by ID (with or without content)
  Future<Result<Lesson?>> getLessonById(String lessonId,
      {bool includeContent = true});

  /// Get lessons by IDs (batch operation)
  Future<Result<List<Lesson>>> getLessonsByIds(List<String> lessonIds,
      {bool includeContent = false});

  /// Get lessons by language from remote
  Future<Result<List<Lesson>>> getLessonsByLanguage(String language);

  /// Get next lesson in learning path
  Future<Result<Lesson?>> getNextLesson({
    required String userId,
    required String targetLanguage,
  });

  /// Save lesson progress
  Future<Result<void>> saveLessonProgress({
    required String userId,
    required String lessonId,
    required LessonStatus status,
    int? progressPercentage,
    DateTime? startedAt,
    DateTime? completedAt,
    int? score,
  });

  /// Mark lesson as completed
  Future<Result<void>> completeLesson({
    required String userId,
    required String lessonId,
    required int score,
  });

  /// Get user's lesson progress
  Future<Result<Lesson?>> getUserLessonProgress({
    required String userId,
    required String lessonId,
  });

  /// Check if lesson is available offline
  Future<Result<bool>> isLessonAvailableOffline(String lessonId);

  /// Download lesson for offline use
  Future<Result<void>> downloadLessonForOffline(String lessonId);

  /// Get all downloaded lessons
  Future<Result<List<String>>> getDownloadedLessonIds();
}
