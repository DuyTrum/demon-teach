import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:demon_teach/core/errors/failures.dart';
import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/lesson.dart';
import 'package:demon_teach/domain/repositories/lesson_repository.dart';
import 'package:demon_teach/domain/repositories/learning_path_repository.dart';
import 'package:demon_teach/data/datasources/remote/lesson_remote_datasource.dart';
import 'package:demon_teach/data/datasources/local/mock_lesson_data.dart';

/// Implementation of LessonRepository using Remote API and local fallbacks
class LessonRepositoryImpl implements LessonRepository {
  final SharedPreferences _prefs;
  final LearningPathRepository _learningPathRepository;
  final LessonRemoteDataSource _remoteDataSource;

  // Keys for SharedPreferences
  static const String _progressKeyPrefix = 'lesson_progress_';
  static const String _downloadedLessonsKey = 'downloaded_lessons';

  LessonRepositoryImpl(this._prefs, this._learningPathRepository, this._remoteDataSource);

  /// Generate storage key for user lesson progress
  String _getProgressKey({required String userId, required String lessonId}) {
    return '$_progressKeyPrefix${userId}_$lessonId';
  }

  @override
  Future<Result<Lesson?>> getLessonById(String lessonId,
      {bool includeContent = true}) async {
    try {
      // Fetch from remote only
      final result = await _remoteDataSource.getLessonById(lessonId);
      
      return result.when(
        success: (lesson) {
          if (!includeContent) {
            return Result.success(lesson.copyWith(content: null));
          }
          return Result.success(lesson);
        },
        failure: (failure) => Result.failure(failure),
      );
    } catch (e) {
      return Result.failure(
        ServerFailure(message: 'Failed to get lesson from server: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<List<Lesson>>> getLessonsByIds(
    List<String> lessonIds, {
    bool includeContent = false,
  }) async {
    try {
      final lessons = <Lesson>[];

      for (final lessonId in lessonIds) {
        final result =
            await getLessonById(lessonId, includeContent: includeContent);
        result.when(
          success: (lesson) {
            if (lesson != null) {
              lessons.add(lesson);
            }
          },
          failure: (_) {
            // Skip failed lessons
          },
        );
      }

      return Result.success(lessons);
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to get lessons: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<Lesson?>> getNextLesson({
    required String userId,
    required String targetLanguage,
  }) async {
    try {
      // Get learning path
      final pathResult = await _learningPathRepository.getLearningPath(
        userId: userId,
        targetLanguage: targetLanguage,
      );

      return pathResult.when(
        success: (path) async {
          if (path == null || path.currentLessonId == null) {
            return Result.success(null);
          }

          // Get current lesson
          final lessonResult = await getLessonById(path.currentLessonId!);
          return lessonResult.when(
            success: (lesson) async {
              if (lesson == null) {
                return Result.success(null);
              }

              // Get user progress for this lesson
              final progressResult = await getUserLessonProgress(
                userId: userId,
                lessonId: lesson.metadata.id,
              );

              return progressResult.when(
                success: (progressLesson) {
                  // Merge lesson with user progress
                  if (progressLesson != null) {
                    return Result.success(lesson.copyWith(
                      status: progressLesson.status,
                      progressPercentage: progressLesson.progressPercentage,
                      startedAt: progressLesson.startedAt,
                      completedAt: progressLesson.completedAt,
                      score: progressLesson.score,
                    ));
                  }
                  return Result.success(lesson);
                },
                failure: (failure) => Result.success(lesson),
              );
            },
            failure: (failure) => Result.failure(failure),
          );
        },
        failure: (failure) => Result.failure(failure),
      );
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to get next lesson: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<void>> saveLessonProgress({
    required String userId,
    required String lessonId,
    required LessonStatus status,
    int? progressPercentage,
    DateTime? startedAt,
    DateTime? completedAt,
    int? score,
  }) async {
    try {
      final key = _getProgressKey(userId: userId, lessonId: lessonId);

      final progressData = {
        'userId': userId,
        'lessonId': lessonId,
        'status': status.name,
        'progressPercentage': progressPercentage,
        'startedAt': startedAt?.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'score': score,
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      await _prefs.setString(key, jsonEncode(progressData));
      return Result.success(null);
    } catch (e) {
      return Result.failure(
        CacheFailure(
            message: 'Failed to save lesson progress: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<void>> completeLesson({
    required String userId,
    required String lessonId,
    required int score,
  }) async {
    return await saveLessonProgress(
      userId: userId,
      lessonId: lessonId,
      status: LessonStatus.completed,
      progressPercentage: 100,
      completedAt: DateTime.now(),
      score: score,
    );
  }

  @override
  Future<Result<Lesson?>> getUserLessonProgress({
    required String userId,
    required String lessonId,
  }) async {
    try {
      final key = _getProgressKey(userId: userId, lessonId: lessonId);
      final jsonString = _prefs.getString(key);

      if (jsonString == null) {
        return Result.success(null);
      }

      final progressData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Get lesson metadata
      final lessonResult = await getLessonById(lessonId, includeContent: false);

      return lessonResult.when(
        success: (lesson) {
          if (lesson == null) {
            return Result.success(null);
          }

          // Create lesson with progress data
          return Result.success(lesson.copyWith(
            status: LessonStatus.values.firstWhere(
              (e) => e.name == progressData['status'],
              orElse: () => LessonStatus.notStarted,
            ),
            progressPercentage: progressData['progressPercentage'] as int?,
            startedAt: progressData['startedAt'] != null
                ? DateTime.parse(progressData['startedAt'] as String)
                : null,
            completedAt: progressData['completedAt'] != null
                ? DateTime.parse(progressData['completedAt'] as String)
                : null,
            score: progressData['score'] as int?,
          ));
        },
        failure: (failure) => Result.failure(failure),
      );
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to get lesson progress: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<bool>> isLessonAvailableOffline(String lessonId) async {
    try {
      final downloadedIds = await getDownloadedLessonIds();
      return downloadedIds.when(
        success: (ids) => Result.success(ids.contains(lessonId)),
        failure: (failure) => Result.failure(failure),
      );
    } catch (e) {
      return Result.failure(
        CacheFailure(
            message: 'Failed to check offline availability: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<void>> downloadLessonForOffline(String lessonId) async {
    try {
      final downloadedResult = await getDownloadedLessonIds();

      return downloadedResult.when(
        success: (ids) async {
          if (!ids.contains(lessonId)) {
            ids.add(lessonId);
            await _prefs.setString(_downloadedLessonsKey, jsonEncode(ids));
          }
          return Result.success(null);
        },
        failure: (failure) => Result.failure(failure),
      );
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to download lesson: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<List<Lesson>>> getLessonsByLanguage(String language, {String? nativeLanguage}) async {
    try {
      return await _remoteDataSource.getLessons(language, nativeLanguage: nativeLanguage);
    } catch (e) {
      return Result.failure(
        ServerFailure(message: 'Failed to fetch lessons: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<List<String>>> getDownloadedLessonIds() async {
    try {
      final jsonString = _prefs.getString(_downloadedLessonsKey);

      if (jsonString == null) {
        return Result.success([]);
      }

      final ids = List<String>.from(jsonDecode(jsonString) as List);
      return Result.success(ids);
    } catch (e) {
      return Result.failure(
        CacheFailure(
            message: 'Failed to get downloaded lessons: ${e.toString()}'),
      );
    }
  }
}
