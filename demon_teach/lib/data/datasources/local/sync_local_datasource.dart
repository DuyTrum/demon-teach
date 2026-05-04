import 'package:demon_teach/core/errors/failures.dart';
import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/progress.dart';
import 'package:demon_teach/domain/entities/performance_data.dart';
import 'package:demon_teach/domain/entities/review_item.dart';

/// Sync Local Data Source Interface
///
/// Defines contract for local storage of sync data.
/// Uses SQLite (Drift) for persistent storage.
abstract class SyncLocalDataSource {
  /// Get last sync timestamp
  Future<Result<DateTime?>> getLastSyncTimestamp(String userId);

  /// Update last sync timestamp
  Future<Result<void>> updateLastSyncTimestamp(
    String userId,
    DateTime timestamp,
  );

  /// Get pending changes count
  Future<Result<int>> getPendingChangesCount(String userId);

  /// Mark item as dirty (needs sync)
  Future<Result<void>> markAsDirty(String itemId, String itemType);

  /// Mark item as clean (synced)
  Future<Result<void>> markAsClean(String itemId, String itemType);

  /// Get local progress
  Future<Result<List<Progress>>> getLocalProgress(String userId);

  /// Update local progress
  Future<Result<void>> updateLocalProgress(Progress progress);

  /// Get local performance data
  Future<Result<List<PerformanceData>>> getLocalPerformance(String userId);

  /// Update local performance
  Future<Result<void>> updateLocalPerformance(PerformanceData performance);

  /// Get local review items
  Future<Result<List<ReviewItem>>> getLocalReviews(String userId);

  /// Update local review
  Future<Result<void>> updateLocalReview(ReviewItem review);

  /// Save content metadata
  Future<Result<void>> saveContentMetadata(Map<String, dynamic> metadata);

  /// Get dirty items (items that need sync)
  Future<Result<List<Map<String, dynamic>>>> getDirtyItems(String userId);
}

/// Sync Local Data Source Implementation
///
/// Implements local storage using in-memory storage (placeholder).
/// TODO: Replace with Drift/SQLite implementation
class SyncLocalDataSourceImpl implements SyncLocalDataSource {
  // In-memory storage (placeholder)
  final Map<String, DateTime> _lastSyncTimestamps = {};
  final Map<String, Progress> _progressData = {};
  final Map<String, PerformanceData> _performanceData = {};
  final Map<String, ReviewItem> _reviewItems = {};
  final Set<String> _dirtyItems = {};
  final List<Map<String, dynamic>> _contentMetadata = [];

  @override
  Future<Result<DateTime?>> getLastSyncTimestamp(String userId) async {
    try {
      return Result.success(_lastSyncTimestamps[userId]);
    } catch (e) {
      return Result.failure(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> updateLastSyncTimestamp(
    String userId,
    DateTime timestamp,
  ) async {
    try {
      _lastSyncTimestamps[userId] = timestamp;
      return Result.success(null);
    } catch (e) {
      return Result.failure(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<int>> getPendingChangesCount(String userId) async {
    try {
      // Count dirty items for this user
      final count = _dirtyItems.where((item) => item.startsWith(userId)).length;
      return Result.success(count);
    } catch (e) {
      return Result.failure(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> markAsDirty(String itemId, String itemType) async {
    try {
      _dirtyItems.add('$itemType:$itemId');
      return Result.success(null);
    } catch (e) {
      return Result.failure(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> markAsClean(String itemId, String itemType) async {
    try {
      _dirtyItems.remove('$itemType:$itemId');
      return Result.success(null);
    } catch (e) {
      return Result.failure(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<Progress>>> getLocalProgress(String userId) async {
    try {
      final userProgress = _progressData.values
          .where((progress) => progress.userId == userId)
          .toList();
      return Result.success(userProgress);
    } catch (e) {
      return Result.failure(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> updateLocalProgress(Progress progress) async {
    try {
      final key = '${progress.userId}_${progress.targetLanguage}';
      _progressData[key] = progress;
      return Result.success(null);
    } catch (e) {
      return Result.failure(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<PerformanceData>>> getLocalPerformance(
    String userId,
  ) async {
    try {
      final userPerformance = _performanceData.values
          .where((perf) => perf.userId == userId)
          .toList();
      return Result.success(userPerformance);
    } catch (e) {
      return Result.failure(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> updateLocalPerformance(
    PerformanceData performance,
  ) async {
    try {
      _performanceData[performance.id] = performance;
      return Result.success(null);
    } catch (e) {
      return Result.failure(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<ReviewItem>>> getLocalReviews(String userId) async {
    try {
      final userReviews = _reviewItems.values
          .where((review) => review.userId == userId)
          .toList();
      return Result.success(userReviews);
    } catch (e) {
      return Result.failure(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> updateLocalReview(ReviewItem review) async {
    try {
      _reviewItems[review.id] = review;
      return Result.success(null);
    } catch (e) {
      return Result.failure(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> saveContentMetadata(
    Map<String, dynamic> metadata,
  ) async {
    try {
      _contentMetadata.add(metadata);
      return Result.success(null);
    } catch (e) {
      return Result.failure(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getDirtyItems(
    String userId,
  ) async {
    try {
      final items =
          _dirtyItems.where((item) => item.startsWith(userId)).map((item) {
        final parts = item.split(':');
        return {
          'type': parts[0],
          'id': parts.length > 1 ? parts[1] : '',
        };
      }).toList();
      return Result.success(items);
    } catch (e) {
      return Result.failure(CacheFailure(message: e.toString()));
    }
  }
}

