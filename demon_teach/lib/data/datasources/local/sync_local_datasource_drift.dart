import 'package:demon_teach/core/errors/failures.dart';
import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/progress.dart' as entity;
import 'package:demon_teach/domain/entities/performance_data.dart' as entity;
import 'package:demon_teach/domain/entities/review_item.dart' as entity;
import 'package:demon_teach/data/datasources/local/sync_local_datasource.dart';
import 'package:demon_teach/data/datasources/local/database/app_database.dart';
import 'package:drift/drift.dart';

/// Sync Local Data Source Implementation using Drift
///
/// Provides persistent storage for sync data using SQLite via Drift.
class SyncLocalDataSourceDrift implements SyncLocalDataSource {
  final AppDatabase _database;

  SyncLocalDataSourceDrift(this._database);

  @override
  Future<Result<DateTime?>> getLastSyncTimestamp(String userId) async {
    try {
      final metadata = await _database.getSyncMetadata(userId, 'all');
      return Result.success(metadata?.lastSyncAt);
    } catch (e) {
      return Result.failure(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> updateLastSyncTimestamp(
    String userId,
    DateTime timestamp,
  ) async {
    try {
      await _database.insertSyncMetadata(
        SyncMetadataTableCompanion.insert(
          userId: userId,
          dataType: 'all',
          lastSyncAt: Value(timestamp),
          nextSyncAt: Value(timestamp.add(const Duration(minutes: 30))),
          syncState: 'synced',
        ),
      );
      return Result.success(null);
    } catch (e) {
      return Result.failure(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<int>> getPendingChangesCount(String userId) async {
    try {
      final count = await _database.getDirtyItemsCount(userId);
      return Result.success(count);
    } catch (e) {
      return Result.failure(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> markAsDirty(String itemId, String itemType) async {
    try {
      // Extract userId from itemId (assuming format: userId_...)
      final userId = itemId.split('_').first;

      await _database.insertDirtyItem(
        DirtyItemsCompanion.insert(
          itemId: itemId,
          itemType: itemType,
          userId: userId,
          markedDirtyAt: DateTime.now(),
          operation: 'update',
        ),
      );
      return Result.success(null);
    } catch (e) {
      return Result.failure(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> markAsClean(String itemId, String itemType) async {
    try {
      await _database.deleteDirtyItem(itemId, itemType);
      return Result.success(null);
    } catch (e) {
      return Result.failure(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<entity.Progress>>> getLocalProgress(String userId) async {
    try {
      final progressList = await _database.getProgressByUser(userId);
      final entities = <entity.Progress>[];
      for (final progress in progressList) {
        entities.add(_mapToEntityProgress(progress));
      }
      return Result.success(entities);
    } catch (e) {
      return Result.failure(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> updateLocalProgress(entity.Progress progress) async {
    try {
      await _database.insertProgress(
        ProgressTableCompanion.insert(
          userId: progress.userId,
          targetLanguage: progress.targetLanguage,
          totalXP: Value(progress.totalXP),
          currentStreak: Value(progress.currentStreak),
          longestStreak: Value(progress.longestStreak),
          lessonsCompleted: Value(progress.lessonsCompleted),
          lastLessonDate: Value(progress.lastLessonDate),
          createdAt: progress.createdAt,
          updatedAt: progress.updatedAt,
          isDirty: const Value(false),
        ),
      );
      return Result.success(null);
    } catch (e) {
      return Result.failure(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<entity.PerformanceData>>> getLocalPerformance(
    String userId,
  ) async {
    try {
      final performanceList = await _database.getPerformanceByUser(userId);
      final entities = performanceList.map(_mapToEntityPerformance).toList();
      return Result.success(entities);
    } catch (e) {
      return Result.failure(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> updateLocalPerformance(
    entity.PerformanceData performance,
  ) async {
    try {
      // Convert accuracy from 0.0-1.0 to 0-100
      final accuracyPercent = (performance.accuracy * 100).round();

      await _database.insertPerformance(
        PerformanceDataTableCompanion.insert(
          id: performance.id,
          userId: performance.userId,
          targetLanguage: performance.targetLanguage,
          lessonId: performance.lessonId,
          completedAt: performance.completedAt,
          accuracy: accuracyPercent,
          timeSpentSeconds: performance.completionTimeSeconds,
          difficulty: performance.difficulty,
          createdAt: performance.completedAt, // Use completedAt as createdAt
          isDirty: Value(false),
        ),
      );
      return Result.success(null);
    } catch (e) {
      return Result.failure(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<entity.ReviewItem>>> getLocalReviews(String userId) async {
    try {
      final reviewList = await _database.getReviewsByUser(userId);
      final entities = reviewList.map(_mapToEntityReview).toList();
      return Result.success(entities);
    } catch (e) {
      return Result.failure(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> updateLocalReview(entity.ReviewItem review) async {
    try {
      await _database.insertReview(
        ReviewItemsCompanion.insert(
          id: review.id,
          userId: review.userId,
          targetLanguage: '', // Not in entity, use empty string
          contentId: review.contentId,
          contentType: review.type.name,
          repetitions: Value(review.repetitionCount),
          easeFactor: Value(review.easeFactor),
          intervalDays: Value(review.intervalDays),
          nextReviewDate: review.nextReviewDate,
          lastReviewedAt: Value(null), // Not in entity
          createdAt: review.createdAt,
          updatedAt: review.updatedAt,
          isDirty: Value(false),
        ),
      );
      return Result.success(null);
    } catch (e) {
      return Result.failure(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> saveContentMetadata(
    Map<String, dynamic> metadata,
  ) async {
    try {
      await _database.insertContentMetadata(
        ContentMetadataTableCompanion.insert(
          contentId: metadata['contentId'] as String,
          contentType: metadata['contentType'] as String,
          title: metadata['title'] as String,
          version: metadata['version'] as String,
          sizeBytes: metadata['sizeBytes'] as int,
          publishedAt: DateTime.parse(metadata['publishedAt'] as String),
          updatedAt: DateTime.parse(metadata['updatedAt'] as String),
          targetLanguage: metadata['targetLanguage'] as String,
          difficulty: metadata['difficulty'] as String,
          isAvailable: Value(metadata['isAvailable'] as bool? ?? true),
        ),
      );
      return Result.success(null);
    } catch (e) {
      return Result.failure(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getDirtyItems(
    String userId,
  ) async {
    try {
      final items = await _database.getDirtyItems(userId);
      final result = items.map((item) {
        return {
          'itemId': item.itemId,
          'itemType': item.itemType,
          'userId': item.userId,
          'markedDirtyAt': item.markedDirtyAt.toIso8601String(),
          'operation': item.operation,
        };
      }).toList();
      return Result.success(result);
    } catch (e) {
      return Result.failure(DatabaseFailure(message: e.toString()));
    }
  }

  /// Map Drift ProgressData to Entity Progress
  entity.Progress _mapToEntityProgress(ProgressData progress) {
    return entity.Progress(
      userId: progress.userId,
      targetLanguage: progress.targetLanguage,
      totalXP: progress.totalXP,
      currentStreak: progress.currentStreak,
      longestStreak: progress.longestStreak,
      lessonsCompleted: progress.lessonsCompleted,
      lastLessonDate: progress.lastLessonDate,
      createdAt: progress.createdAt,
      updatedAt: progress.updatedAt,
    );
  }

  /// Map Drift PerformanceData to Entity PerformanceData
  entity.PerformanceData _mapToEntityPerformance(
    PerformanceData performance,
  ) {
    // Convert accuracy from 0-100 to 0.0-1.0
    final accuracyDecimal = performance.accuracy / 100.0;

    return entity.PerformanceData(
      id: performance.id,
      userId: performance.userId,
      lessonId: performance.lessonId,
      targetLanguage: performance.targetLanguage,
      completedAt: performance.completedAt,
      accuracy: accuracyDecimal,
      completionTimeSeconds: performance.timeSpentSeconds,
      difficulty: performance.difficulty,
    );
  }

  /// Map Drift ReviewItem to Entity ReviewItem
  entity.ReviewItem _mapToEntityReview(ReviewItem review) {
    return entity.ReviewItem(
      id: review.id,
      userId: review.userId,
      contentId: review.contentId,
      type: entity.ReviewItemType.values.firstWhere(
        (e) => e.name == review.contentType,
        orElse: () => entity.ReviewItemType.flashcard,
      ),
      nextReviewDate: review.nextReviewDate,
      repetitionCount: review.repetitions,
      easeFactor: review.easeFactor,
      intervalDays: review.intervalDays,
      createdAt: review.createdAt,
      updatedAt: review.updatedAt,
    );
  }
}
