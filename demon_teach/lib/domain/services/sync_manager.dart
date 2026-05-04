import 'dart:async';
import 'package:demon_teach/domain/entities/sync_status.dart';
import 'package:demon_teach/domain/entities/progress.dart';
import 'package:demon_teach/domain/entities/performance_data.dart';
import 'package:demon_teach/domain/entities/review_item.dart';

/// Sync Manager Service
///
/// Orchestrates data synchronization between local and remote storage.
/// Implements Requirement 19: Data Persistence and Synchronization
class SyncManager {
  final StreamController<SyncStatus> _syncStatusController =
      StreamController<SyncStatus>.broadcast();

  SyncStatus _currentStatus = const SyncStatus(
    userId: '',
    state: SyncState.idle,
  );

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
      // 1. Sync progress data (user → server)
      await _syncProgress(userId);

      // 2. Sync performance data (user → server)
      await _syncPerformance(userId);

      // 3. Sync review items (bidirectional)
      await _syncReviews(userId);

      // 4. Fetch new content (server → user)
      await _syncContent(userId);

      // 5. Update sync timestamp
      final now = DateTime.now();
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
      await _scheduleRetry(userId);

      return _currentStatus;
    }
  }

  /// Sync progress data
  ///
  /// Property 22: Local data persistence
  Future<void> _syncProgress(String userId) async {
    // Get local progress data
    final localProgress = await _getLocalProgress(userId);

    for (final progress in localProgress) {
      if (progress.isDirty) {
        // Get remote progress
        final remoteProgress = await _getRemoteProgress(
          progress.userId,
          progress.targetLanguage,
        );

        if (remoteProgress != null) {
          // Resolve conflict
          final resolved = _resolveProgressConflict(
            local: progress,
            remote: remoteProgress,
          );

          // Update remote
          await _updateRemoteProgress(resolved);

          // Update local (mark as clean)
          await _updateLocalProgress(resolved.copyWith(isDirty: false));
        } else {
          // No conflict, push local
          await _updateRemoteProgress(progress);
          await _updateLocalProgress(progress.copyWith(isDirty: false));
        }
      }
    }
  }

  /// Resolve progress conflict
  ///
  /// Property 23: Conflict resolution by timestamp
  /// Requirement 19.7: Resolve conflicts by most recent timestamp
  Progress _resolveProgressConflict({
    required Progress local,
    required Progress remote,
  }) {
    // Use most recent data for each field
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
      achievements: _mergeAchievements(
        local.achievements,
        remote.achievements,
      ),
      updatedAt: _mostRecent(local.updatedAt, remote.updatedAt),
      isDirty: false,
    );
  }

  /// Sync performance data
  Future<void> _syncPerformance(String userId) async {
    // Get local performance data
    final localPerformance = await _getLocalPerformance(userId);

    for (final performance in localPerformance) {
      if (performance.isDirty) {
        // Push to remote
        await _updateRemotePerformance(performance);

        // Mark as clean
        await _updateLocalPerformance(
          performance.copyWith(isDirty: false),
        );
      }
    }
  }

  /// Sync review items (bidirectional)
  Future<void> _syncReviews(String userId) async {
    // Get local review items
    final localReviews = await _getLocalReviews(userId);

    // Get remote review items
    final remoteReviews = await _getRemoteReviews(userId);

    // Merge review items
    final mergedReviews = _mergeReviewItems(localReviews, remoteReviews);

    // Update local
    for (final review in mergedReviews) {
      await _updateLocalReview(review);
    }

    // Update remote
    for (final review in mergedReviews) {
      await _updateRemoteReview(review);
    }
  }

  /// Merge review items
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

  /// Sync content updates
  ///
  /// Requirement 21.8: Check for new or updated Lesson_Content when online
  /// Requirement 21.19: Update cached content when newer version available
  Future<void> _syncContent(String userId) async {
    // Get last content sync timestamp
    final lastSync = await _getLastContentSync(userId);

    // Check for content updates
    final updates = await _getContentUpdates(lastSync);

    if (updates.isNotEmpty) {
      // Download new content
      for (final content in updates) {
        await _downloadContent(content);
      }

      // Update last sync timestamp
      await _updateLastContentSync(userId, DateTime.now());
    }
  }

  /// Schedule retry on failure
  ///
  /// Requirement 19.5: Retry automatically when connection restored
  Future<void> _scheduleRetry(String userId) async {
    // Wait 30 seconds before retry
    await Future.delayed(const Duration(seconds: 30));

    // Check if online
    if (await _isOnline()) {
      // Retry sync
      await syncAll(userId);
    } else {
      // Schedule another retry
      await _scheduleRetry(userId);
    }
  }

  /// Update sync status
  void _updateStatus(SyncStatus status) {
    _currentStatus = status;
    _syncStatusController.add(status);
  }

  /// Helper methods (placeholders - to be implemented with repositories)

  Future<List<Progress>> _getLocalProgress(String userId) async {
    // Get from local repository
    return [];
  }

  Future<Progress?> _getRemoteProgress(
    String userId,
    String targetLanguage,
  ) async {
    // Get from remote repository
    return null;
  }

  Future<void> _updateRemoteProgress(Progress progress) async {
    // Update remote repository
  }

  Future<void> _updateLocalProgress(Progress progress) async {
    // Update local repository
  }

  Future<List<PerformanceData>> _getLocalPerformance(String userId) async {
    // Get from local repository
    return [];
  }

  Future<void> _updateRemotePerformance(PerformanceData performance) async {
    // Update remote repository
  }

  Future<void> _updateLocalPerformance(PerformanceData performance) async {
    // Update local repository
  }

  Future<List<ReviewItem>> _getLocalReviews(String userId) async {
    // Get from local repository
    return [];
  }

  Future<List<ReviewItem>> _getRemoteReviews(String userId) async {
    // Get from remote repository
    return [];
  }

  Future<void> _updateLocalReview(ReviewItem review) async {
    // Update local repository
  }

  Future<void> _updateRemoteReview(ReviewItem review) async {
    // Update remote repository
  }

  Future<DateTime?> _getLastContentSync(String userId) async {
    // Get from local repository
    return null;
  }

  Future<List<Map<String, dynamic>>> _getContentUpdates(
    DateTime? lastSync,
  ) async {
    // Get from remote repository
    return [];
  }

  Future<void> _downloadContent(Map<String, dynamic> content) async {
    // Download content
  }

  Future<void> _updateLastContentSync(String userId, DateTime timestamp) async {
    // Update local repository
  }

  Future<bool> _isOnline() async {
    // Check network connectivity
    return true;
  }

  /// Helper functions

  int _max(int a, int b) => a > b ? a : b;

  DateTime _mostRecent(DateTime a, DateTime b) {
    return a.isAfter(b) ? a : b;
  }

  Map<String, dynamic> _mergeAchievements(
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
  ) {
    final merged = Map<String, dynamic>.from(local);

    for (final entry in remote.entries) {
      if (!merged.containsKey(entry.key)) {
        merged[entry.key] = entry.value;
      }
    }

    return merged;
  }

  /// Dispose resources
  void dispose() {
    _syncStatusController.close();
  }
}
