import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/core/errors/failures.dart';
import 'package:demon_teach/domain/entities/download_status.dart';
import 'package:demon_teach/domain/entities/offline_content.dart';

/// Download Local Data Source Interface
///
/// Defines contract for local storage of download data.
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

/// In-memory implementation of DownloadLocalDataSource
///
/// Replaces the Drift/SQLite implementation. Data is stored in memory only.
class DownloadLocalDataSourceImpl implements DownloadLocalDataSource {
  final Map<String, DownloadStatus> _downloadStatuses = {};
  final Map<String, OfflineContent> _offlineContents = {};

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
      return Result.success(_downloadStatuses.values.toList());
    } catch (e) {
      return Result.failure(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteDownloadStatus(String contentId) async {
    try {
      _downloadStatuses.remove(contentId);
      return Result.success(null);
    } catch (e) {
      return Result.failure(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> saveOfflineContent(OfflineContent content) async {
    try {
      _offlineContents[content.contentId] = content;
      return Result.success(null);
    } catch (e) {
      return Result.failure(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<OfflineContent?>> getOfflineContent(String contentId) async {
    try {
      return Result.success(_offlineContents[contentId]);
    } catch (e) {
      return Result.failure(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<OfflineContent>>> getAllOfflineContent() async {
    try {
      return Result.success(_offlineContents.values.toList());
    } catch (e) {
      return Result.failure(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteOfflineContent(String contentId) async {
    try {
      _offlineContents.remove(contentId);
      return Result.success(null);
    } catch (e) {
      return Result.failure(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<OfflineContent>>> getOfflineContentByType(String type) async {
    try {
      final filtered = _offlineContents.values
          .where((c) => c.contentType == type)
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
      // No-op for in-memory implementation
      return Result.success(null);
    } catch (e) {
      return Result.failure(CacheFailure(message: e.toString()));
    }
  }
}
