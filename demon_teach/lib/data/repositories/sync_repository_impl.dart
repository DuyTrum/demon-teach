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
/// Handles bidirectional sync between local and remote data sources.
class SyncRepositoryImpl implements SyncRepository {
  final SyncLocalDataSource _localDataSource;
  final SyncRemoteDataSource _remoteDataSource;

  SyncRepositoryImpl({
    required SyncLocalDataSource localDataSource,
    required SyncRemoteDataSource remoteDataSource,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource;

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
  Future<Result<List<Map<String, dynamic>>>> getContentUpdates(DateTime? lastSync) async {
    return await _remoteDataSource.getContentUpdates(lastSync);
  }

  @override
  Future<Result<void>> saveContentMetadata(Map<String, dynamic> metadata) async {
    return await _localDataSource.saveContentMetadata(metadata);
  }

  @override
  Future<Result<bool>> isOnline() async {
    return await _remoteDataSource.checkConnectivity();
  }
}
