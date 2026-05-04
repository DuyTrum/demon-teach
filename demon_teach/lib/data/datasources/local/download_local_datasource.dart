import 'package:demon_teach/core/errors/failures.dart';
import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/download_status.dart';
import 'package:demon_teach/domain/entities/offline_content.dart';

/// Download Local Data Source Interface
///
/// Defines contract for local storage of download data.
/// Uses SQLite (Drift) for persistent storage.
abstract class DownloadLocalDataSource {
  /// Save download status
  Future<Result<void>> saveDownloadStatus(DownloadStatus status);

  /// Get download status
  Future<Result<DownloadStatus?>> getDownloadStatus(String lessonId);

  /// Get all active downloads
  Future<Result<List<DownloadStatus>>> getActiveDownloads();

  /// Delete download status
  Future<Result<void>> deleteDownloadStatus(String lessonId);

  /// Save offline content
  Future<Result<void>> saveOfflineContent(OfflineContent content);

  /// Get offline content
  Future<Result<OfflineContent?>> getOfflineContent(String contentId);

  /// Get all offline content
  Future<Result<List<OfflineContent>>> getAllOfflineContent();

  /// Delete offline content
  Future<Result<void>> deleteOfflineContent(String contentId);

  /// Get offline content by type
  Future<Result<List<OfflineContent>>> getOfflineContentByType(String type);

  /// Update offline content metadata
  Future<Result<void>> updateOfflineContentMetadata(
    String contentId,
    Map<String, dynamic> metadata,
  );
}

/// Download Local Data Source Implementation
///
/// Implements local storage using in-memory storage (placeholder).
/// TODO: Replace with Drift/SQLite implementation
class DownloadLocalDataSourceImpl implements DownloadLocalDataSource {
  // In-memory storage (placeholder)
  final Map<String, DownloadStatus> _downloadStatuses = {};
  final Map<String, OfflineContent> _offlineContent = {};

  @override
  Future<Result<void>> saveDownloadStatus(DownloadStatus status) async {
    try {
      _downloadStatuses[status.contentId] = status;
      return Result.success(null);
    } catch (e) {
      return Result.failure(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<DownloadStatus?>> getDownloadStatus(String lessonId) async {
    try {
      return Result.success(_downloadStatuses[lessonId]);
    } catch (e) {
      return Result.failure(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<DownloadStatus>>> getActiveDownloads() async {
    try {
      final active = _downloadStatuses.values
          .where((status) =>
              status.isDownloading || status.isPending || status.isPaused)
          .toList();
      return Result.success(active);
    } catch (e) {
      return Result.failure(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteDownloadStatus(String lessonId) async {
    try {
      _downloadStatuses.remove(lessonId);
      return Result.success(null);
    } catch (e) {
      return Result.failure(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> saveOfflineContent(OfflineContent content) async {
    try {
      _offlineContent[content.contentId] = content;
      return Result.success(null);
    } catch (e) {
      return Result.failure(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<OfflineContent?>> getOfflineContent(String contentId) async {
    try {
      return Result.success(_offlineContent[contentId]);
    } catch (e) {
      return Result.failure(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<OfflineContent>>> getAllOfflineContent() async {
    try {
      return Result.success(_offlineContent.values.toList());
    } catch (e) {
      return Result.failure(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteOfflineContent(String contentId) async {
    try {
      _offlineContent.remove(contentId);
      return Result.success(null);
    } catch (e) {
      return Result.failure(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<OfflineContent>>> getOfflineContentByType(
    String type,
  ) async {
    try {
      final filtered = _offlineContent.values
          .where((content) => content.contentType == type)
          .toList();
      return Result.success(filtered);
    } catch (e) {
      return Result.failure(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> updateOfflineContentMetadata(
    String contentId,
    Map<String, dynamic> metadata,
  ) async {
    try {
      final content = _offlineContent[contentId];
      if (content != null) {
        final updated = content.copyWith(
          metadata: {...content.metadata, ...metadata},
        );
        _offlineContent[contentId] = updated;
      }
      return Result.success(null);
    } catch (e) {
      return Result.failure(CacheFailure(message: e.toString()));
    }
  }
}
