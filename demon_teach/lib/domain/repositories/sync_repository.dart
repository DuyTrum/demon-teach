import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/sync_status.dart';
import 'package:demon_teach/domain/entities/progress.dart';
import 'package:demon_teach/domain/entities/performance_data.dart';
import 'package:demon_teach/domain/entities/review_item.dart';

/// Sync Repository Interface
///
/// Defines contract for synchronization operations.
abstract class SyncRepository {
  /// Get sync status
  Future<Result<SyncStatus>> getSyncStatus(String userId);

  /// Get last sync timestamp
  Future<Result<DateTime?>> getLastSyncTimestamp(String userId);

  /// Update last sync timestamp
  Future<Result<void>> updateLastSyncTimestamp(
      String userId, DateTime timestamp);

  /// Get pending changes count
  Future<Result<int>> getPendingChangesCount(String userId);

  /// Mark data as dirty (needs sync)
  Future<Result<void>> markAsDirty(String itemId, String itemType);

  /// Mark data as clean (synced)
  Future<Result<void>> markAsClean(String itemId, String itemType);

  /// Get local progress
  Future<Result<List<Progress>>> getLocalProgress(String userId);

  /// Get remote progress
  Future<Result<Progress?>> getRemoteProgress(
      String userId, String targetLanguage);

  /// Update local progress
  Future<Result<void>> updateLocalProgress(Progress progress);

  /// Update remote progress
  Future<Result<void>> updateRemoteProgress(Progress progress);

  /// Get local performance data
  Future<Result<List<PerformanceData>>> getLocalPerformance(String userId);

  /// Update local performance
  Future<Result<void>> updateLocalPerformance(PerformanceData performance);

  /// Update remote performance
  Future<Result<void>> updateRemotePerformance(PerformanceData performance);

  /// Get local review items
  Future<Result<List<ReviewItem>>> getLocalReviews(String userId);

  /// Get remote review items
  Future<Result<List<ReviewItem>>> getRemoteReviews(String userId);

  /// Update local review
  Future<Result<void>> updateLocalReview(ReviewItem review);

  /// Update remote review
  Future<Result<void>> updateRemoteReview(ReviewItem review);

  /// Get content updates
  Future<Result<List<Map<String, dynamic>>>> getContentUpdates(DateTime? lastSync);

  /// Save content metadata
  Future<Result<void>> saveContentMetadata(Map<String, dynamic> metadata);

  /// Check if online
  Future<Result<bool>> isOnline();
}
