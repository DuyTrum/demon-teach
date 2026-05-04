import 'dart:async';
import 'package:demon_teach/core/errors/failures.dart';
import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/sync_status.dart';
import 'package:demon_teach/domain/entities/progress.dart';
import 'package:demon_teach/domain/entities/performance_data.dart';
import 'package:demon_teach/domain/entities/review_item.dart';
import 'package:demon_teach/domain/repositories/sync_repository.dart';
import 'package:demon_teach/data/datasources/local/sync_local_datasource.dart';
import 'package:demon_teach/data/datasources/remote/sync_remote_datasource.dart';

/// Sync Repository Implementation
///
/// Implements synchronization operations with conflict resolution.
/// Handles bidirectional sync between local and remote data sources.
class SyncRepositoryImpl implements SyncRepository {
  final SyncLocalDataSource _localDataSource;
  final SyncRemoteDataSource _remoteDataSource;

  final StreamController<SyncStatus> _syncStatusController =
      StreamController<SyncStatus>.broadcast();

  SyncRepositoryImpl({
    required SyncLocalDataSource localDataSource,
    required SyncRemoteDataSource remoteDataSource,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource;

  @override
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;

  @override
  Future<Result<SyncStatus>> syncAll(String userId) async {
    try {
      var status = SyncStatus(
        userId: userId,
        state: SyncState.syncing,
      );
      _syncStatusController.add(status);

      // 1. Sync progress
      await syncProgress(userId);

      // 2. Sync performance
      await syncPerformance(userId);

      // 3. Sync reviews
      await syncReviews(userId);

      // 4. Sync content
      await syncContent(userId);

      // 5. Update sync timestamp
      final now = DateTime.now();
      await _localDataSource.updateLastSyncTimestamp(userId, now);

      status = status.copyWith(
        state: SyncState.synced,
        lastSyncAt: now,
        nextSyncAt: now.add(const Duration(minutes: 30)),
        pendingChanges: 0,
      );
      _syncStatusController.add(status);

      return Result.success(status);
    } catch (e) {
      final status = SyncStatus(
        userId: userId,
        state: SyncState.error,
        error: e.toString(),
      );
      _syncStatusController.add(status);
      return Result.failure(NetworkFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> syncProgress(String userId) async {
    try {
      // Get local progress
      final localResult = await _localDataSource.getLocalProgress(userId);
      if (localResult.isFailure) {
        return Result.failure(localResult.failure);
      }

      final localProgress = localResult.value;

      for (final progress in localProgress) {
        // Get remote progress
        final remoteResult = await _remoteDataSource.getRemoteProgress(
          progress.userId,
          progress.targetLanguage,
        );

        if (remoteResult.isSuccess && remoteResult.value != null) {
          // Resolve conflict using timestamp
          final resolved = _resolveProgressConflict(
            local: progress,
            remote: remoteResult.value!,
          );

          // Update remote
          await _remoteDataSource.updateRemoteProgress(resolved);

          // Update local
          await _localDataSource.updateLocalProgress(resolved);
        } else {
          // No conflict, push local to remote
          await _remoteDataSource.updateRemoteProgress(progress);
        }

        // Mark as clean after successful sync
        final itemId = '${progress.userId}_${progress.targetLanguage}';
        await _localDataSource.markAsClean(itemId, 'progress');
      }

      return Result.success(null);
    } catch (e) {
      return Result.failure(NetworkFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> syncPerformance(String userId) async {
    try {
      // Get local performance data
      final localResult = await _localDataSource.getLocalPerformance(userId);
      if (localResult.isFailure) {
        return Result.failure(localResult.failure);
      }

      // Push to remote
      for (final performance in localResult.value) {
        await _remoteDataSource.updateRemotePerformance(performance);
      }

      return Result.success(null);
    } catch (e) {
      return Result.failure(NetworkFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> syncReviews(String userId) async {
    try {
      // Get local reviews
      final localResult = await _localDataSource.getLocalReviews(userId);
      if (localResult.isFailure) {
        return Result.failure(localResult.failure);
      }

      // Get remote reviews
      final remoteResult = await _remoteDataSource.getRemoteReviews(userId);
      if (remoteResult.isFailure) {
        return Result.failure(remoteResult.failure);
      }

      // Merge reviews
      final merged = _mergeReviewItems(
        localResult.value,
        remoteResult.value,
      );

      // Update local
      for (final review in merged) {
        await _localDataSource.updateLocalReview(review);
      }

      // Update remote
      for (final review in merged) {
        await _remoteDataSource.updateRemoteReview(review);
      }

      return Result.success(null);
    } catch (e) {
      return Result.failure(NetworkFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> syncContent(String userId) async {
    try {
      // Get last content sync timestamp
      final lastSyncResult =
          await _localDataSource.getLastSyncTimestamp(userId);
      final lastSync = lastSyncResult.isSuccess ? lastSyncResult.value : null;

      // Check for content updates
      final updatesResult = await _remoteDataSource.getContentUpdates(lastSync);
      if (updatesResult.isFailure) {
        return Result.failure(updatesResult.failure);
      }

      // Download new content metadata (not full content)
      // Full content download is handled by DownloadManager
      for (final update in updatesResult.value) {
        await _localDataSource.saveContentMetadata(update);
      }

      return Result.success(null);
    } catch (e) {
      return Result.failure(NetworkFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<SyncStatus>> getSyncStatus(String userId) async {
    try {
      final lastSyncResult =
          await _localDataSource.getLastSyncTimestamp(userId);
      final pendingResult =
          await _localDataSource.getPendingChangesCount(userId);

      final lastSync = lastSyncResult.isSuccess ? lastSyncResult.value : null;
      final pendingCount = pendingResult.isSuccess ? pendingResult.value : 0;

      final status = SyncStatus(
        userId: userId,
        state: pendingCount > 0 ? SyncState.idle : SyncState.synced,
        lastSyncAt: lastSync,
        nextSyncAt: lastSync?.add(const Duration(minutes: 30)),
        pendingChanges: pendingCount,
      );

      return Result.success(status);
    } catch (e) {
      return Result.failure(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<DateTime?>> getLastSyncTimestamp(String userId) async {
    return await _localDataSource.getLastSyncTimestamp(userId);
  }

  @override
  Future<Result<void>> updateLastSyncTimestamp(
    String userId,
    DateTime timestamp,
  ) async {
    return await _localDataSource.updateLastSyncTimestamp(userId, timestamp);
  }

  @override
  Future<Result<int>> getPendingChangesCount(String userId) async {
    return await _localDataSource.getPendingChangesCount(userId);
  }

  @override
  Future<Result<void>> markAsDirty(String itemId, String itemType) async {
    return await _localDataSource.markAsDirty(itemId, itemType);
  }

  @override
  Future<Result<void>> markAsClean(String itemId, String itemType) async {
    return await _localDataSource.markAsClean(itemId, itemType);
  }

  @override
  Future<Result<List<Progress>>> getLocalProgress(String userId) async {
    return await _localDataSource.getLocalProgress(userId);
  }

  @override
  Future<Result<Progress?>> getRemoteProgress(
    String userId,
    String targetLanguage,
  ) async {
    return await _remoteDataSource.getRemoteProgress(userId, targetLanguage);
  }

  @override
  Future<Result<void>> updateLocalProgress(Progress progress) async {
    return await _localDataSource.updateLocalProgress(progress);
  }

  @override
  Future<Result<void>> updateRemoteProgress(Progress progress) async {
    return await _remoteDataSource.updateRemoteProgress(progress);
  }

  @override
  Future<Result<List<PerformanceData>>> getLocalPerformance(
      String userId) async {
    return await _localDataSource.getLocalPerformance(userId);
  }

  @override
  Future<Result<void>> updateLocalPerformance(
      PerformanceData performance) async {
    return await _localDataSource.updateLocalPerformance(performance);
  }

  @override
  Future<Result<void>> updateRemotePerformance(
      PerformanceData performance) async {
    return await _remoteDataSource.updateRemotePerformance(performance);
  }

  @override
  Future<Result<List<ReviewItem>>> getLocalReviews(String userId) async {
    return await _localDataSource.getLocalReviews(userId);
  }

  @override
  Future<Result<List<ReviewItem>>> getRemoteReviews(String userId) async {
    return await _remoteDataSource.getRemoteReviews(userId);
  }

  @override
  Future<Result<void>> updateLocalReview(ReviewItem review) async {
    return await _localDataSource.updateLocalReview(review);
  }

  @override
  Future<Result<void>> updateRemoteReview(ReviewItem review) async {
    return await _remoteDataSource.updateRemoteReview(review);
  }

  @override
  Future<Result<bool>> isOnline() async {
    return await _remoteDataSource.checkConnectivity();
  }

  /// Resolve progress conflict using timestamp-based strategy
  ///
  /// Property 23: Conflict resolution by timestamp
  /// Uses most recent data for each field
  Progress _resolveProgressConflict({
    required Progress local,
    required Progress remote,
  }) {
    return Progress(
      userId: local.userId,
      targetLanguage: local.targetLanguage,
      totalXP: _max(local.totalXP, remote.totalXP),
      currentStreak: local.updatedAt.isAfter(remote.updatedAt)
          ? local.currentStreak
          : remote.currentStreak,
      longestStreak: _max(local.longestStreak, remote.longestStreak),
      lessonsCompleted: _max(local.lessonsCompleted, remote.lessonsCompleted),
      lastLessonDate: _mostRecent(local.lastLessonDate, remote.lastLessonDate),
      createdAt: local.createdAt.isBefore(remote.createdAt)
          ? local.createdAt
          : remote.createdAt,
      updatedAt:
          _mostRecent(local.updatedAt, remote.updatedAt) ?? DateTime.now(),
    );
  }

  /// Merge review items using timestamp-based strategy
  List<ReviewItem> _mergeReviewItems(
    List<ReviewItem> local,
    List<ReviewItem> remote,
  ) {
    final Map<String, ReviewItem> merged = {};

    // Add local items
    for (final item in local) {
      merged[item.id] = item;
    }

    // Merge remote items
    for (final item in remote) {
      if (merged.containsKey(item.id)) {
        // Resolve conflict - use most recent
        final localItem = merged[item.id]!;
        if (item.updatedAt.isAfter(localItem.updatedAt)) {
          merged[item.id] = item;
        }
      } else {
        merged[item.id] = item;
      }
    }

    return merged.values.toList();
  }

  /// Helper functions
  int _max(int a, int b) => a > b ? a : b;

  DateTime? _mostRecent(DateTime? a, DateTime? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.isAfter(b) ? a : b;
  }

  void dispose() {
    _syncStatusController.close();
  }
}
