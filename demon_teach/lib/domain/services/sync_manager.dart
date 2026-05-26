import 'dart:async';
import 'package:demon_teach/domain/entities/sync_status.dart';
import 'package:demon_teach/domain/entities/progress.dart';
import 'package:demon_teach/domain/entities/performance_data.dart';
import 'package:demon_teach/domain/entities/review_item.dart';
import 'package:demon_teach/domain/repositories/sync_repository.dart';

/// Sync Manager Service
///
/// Orchestrates data synchronization between local and remote storage.
/// Implements Requirement 19: Data Persistence and Synchronization
class SyncManager {
  final SyncRepository _repository;
  final StreamController<SyncStatus> _syncStatusController =
      StreamController<SyncStatus>.broadcast();

  SyncStatus _currentStatus = const SyncStatus(
    userId: '',
    state: SyncState.idle,
  );

  SyncManager(this._repository);

  /// Stream of sync status updates
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;

  /// Get current sync status
  SyncStatus get currentStatus => _currentStatus;

  /// Sync all data
  ///
  /// Requirement 19.2: Synchronize data to remote server when online
  /// Requirement 19.3: Synchronize within 30 seconds of completing lesson
  Future<SyncStatus> syncAll(String userId) async {
    if (_currentStatus.isSyncing) {
      return _currentStatus;
    }

    _updateStatus(_currentStatus.copyWith(
      userId: userId,
      state: SyncState.syncing,
    ));

    try {
      // Check online status first
      final isOnlineResult = await _repository.isOnline();
      if (isOnlineResult.isFailure || !isOnlineResult.value) {
        throw Exception('Device is offline');
      }

      // 1. Sync progress data (user -> server)
      await _syncProgress(userId);

      // 2. Sync performance data (user -> server)
      await _syncPerformance(userId);

      // 3. Sync review items (bidirectional)
      await _syncReviews(userId);

      // 4. Fetch new content (server -> user)
      await _syncContent(userId);

      // 5. Update sync timestamp
      final now = DateTime.now();
      await _repository.updateLastSyncTimestamp(userId, now);

      _updateStatus(_currentStatus.copyWith(
        state: SyncState.synced,
        lastSyncAt: now,
        nextSyncAt: now.add(const Duration(minutes: 30)),
        pendingChanges: 0,
      ));

      return _currentStatus;
    } catch (e) {
      _updateStatus(_currentStatus.copyWith(
        state: SyncState.error,
        error: e.toString(),
      ));

      // Schedule retry
      _scheduleRetry(userId);

      return _currentStatus;
    }
  }

  /// Sync progress data
  Future<void> _syncProgress(String userId) async {
    final localResult = await _repository.getLocalProgress(userId);
    if (localResult.isFailure) return;

    for (final progress in localResult.value) {
      // Get remote progress
      final remoteResult = await _repository.getRemoteProgress(
        progress.userId,
        progress.targetLanguage,
      );

      if (remoteResult.isSuccess && remoteResult.value != null) {
        // Resolve conflict
        final resolved = _resolveProgressConflict(
          local: progress,
          remote: remoteResult.value!,
        );

        // Update remote
        await _repository.updateRemoteProgress(resolved);

        // Update local
        await _repository.updateLocalProgress(resolved);
      } else {
        // No conflict, push local
        await _repository.updateRemoteProgress(progress);
        await _repository.updateLocalProgress(progress);
      }

      // Mark as clean
      final itemId = '${progress.userId}_${progress.targetLanguage}';
      await _repository.markAsClean(itemId, 'progress');
    }
  }

  /// Resolve progress conflict
  Progress _resolveProgressConflict({
    required Progress local,
    required Progress remote,
  }) {
    final isLocalNewer = local.updatedAt.isAfter(remote.updatedAt);
    return Progress(
      userId: local.userId,
      targetLanguage: local.targetLanguage,
      totalXP: _max(local.totalXP, remote.totalXP),
      currentStreak: isLocalNewer ? local.currentStreak : remote.currentStreak,
      longestStreak: _max(local.longestStreak, remote.longestStreak),
      lessonsCompleted: _max(local.lessonsCompleted, remote.lessonsCompleted),
      lastLessonDate: _mostRecent(local.lastLessonDate, remote.lastLessonDate),
      createdAt: local.createdAt.isBefore(remote.createdAt)
          ? local.createdAt
          : remote.createdAt,
      updatedAt:
          _mostRecent(local.updatedAt, remote.updatedAt) ?? DateTime.now(),
      hearts: isLocalNewer ? local.hearts : remote.hearts,
      lastHeartRegenTime: isLocalNewer ? local.lastHeartRegenTime : remote.lastHeartRegenTime,
      souls: isLocalNewer ? local.souls : remote.souls,
    );
  }

  /// Sync performance data
  Future<void> _syncPerformance(String userId) async {
    final localResult = await _repository.getLocalPerformance(userId);
    if (localResult.isFailure) return;

    for (final performance in localResult.value) {
      await _repository.updateRemotePerformance(performance);
    }
  }

  /// Sync review items (bidirectional)
  Future<void> _syncReviews(String userId) async {
    final localResult = await _repository.getLocalReviews(userId);
    if (localResult.isFailure) return;

    final remoteResult = await _repository.getRemoteReviews(userId);
    if (remoteResult.isFailure) return;

    final mergedReviews = _mergeReviewItems(localResult.value, remoteResult.value);

    for (final review in mergedReviews) {
      await _repository.updateLocalReview(review);
      await _repository.updateRemoteReview(review);
    }
  }

  /// Merge review items
  List<ReviewItem> _mergeReviewItems(
    List<ReviewItem> local,
    List<ReviewItem> remote,
  ) {
    final Map<String, ReviewItem> merged = {};

    for (final item in local) {
      merged[item.id] = item;
    }

    for (final item in remote) {
      if (merged.containsKey(item.id)) {
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

  /// Sync content updates
  Future<void> _syncContent(String userId) async {
    final lastSyncResult = await _repository.getLastSyncTimestamp(userId);
    final lastSync = lastSyncResult.isSuccess ? lastSyncResult.value : null;

    final updatesResult = await _repository.getContentUpdates(lastSync);
    if (updatesResult.isFailure) return;

    for (final update in updatesResult.value) {
      await _repository.saveContentMetadata(update);
    }
  }

  /// Schedule retry on failure
  void _scheduleRetry(String userId) {
    Future.delayed(const Duration(seconds: 30), () async {
      final isOnlineResult = await _repository.isOnline();
      if (isOnlineResult.isSuccess && isOnlineResult.value) {
        await syncAll(userId);
      } else {
        _scheduleRetry(userId);
      }
    });
  }

  void _updateStatus(SyncStatus status) {
    _currentStatus = status;
    _syncStatusController.add(status);
  }

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
