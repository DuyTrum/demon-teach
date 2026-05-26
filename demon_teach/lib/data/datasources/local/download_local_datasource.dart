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
