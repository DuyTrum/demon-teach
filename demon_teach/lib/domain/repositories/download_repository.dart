import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/download_status.dart';
import 'package:demon_teach/domain/entities/offline_content.dart';
import 'package:demon_teach/domain/entities/lesson.dart';

/// Download Repository Interface
///
/// Defines contract for download operations.
abstract class DownloadRepository {
  /// Download a lesson with all content
  Future<Result<DownloadStatus>> downloadLesson(String lessonId);

  /// Download multiple lessons
  Future<Result<List<DownloadStatus>>> downloadLessons(List<String> lessonIds);

  /// Get download status for a lesson
  Future<Result<DownloadStatus?>> getDownloadStatus(String lessonId);

  /// Get all active downloads
  Future<Result<List<DownloadStatus>>> getActiveDownloads();

  /// Cancel a download
  Future<Result<void>> cancelDownload(String lessonId);

  /// Pause a download
  Future<Result<void>> pauseDownload(String lessonId);

  /// Resume a download
  Future<Result<void>> resumeDownload(String lessonId);

  /// Check if lesson is downloaded
  Future<Result<bool>> isLessonDownloaded(String lessonId);

  /// Get offline content
  Future<Result<OfflineContent?>> getOfflineContent(String contentId);

  /// Get all offline content
  Future<Result<List<OfflineContent>>> getAllOfflineContent();

  /// Delete offline content
  Future<Result<void>> deleteOfflineContent(String contentId);

  /// Get offline availability
  Future<Result<OfflineAvailability>> getOfflineAvailability(
    String userId,
    String targetLanguage,
  );

  /// Get used storage space in bytes
  Future<Result<int>> getUsedStorageSpace();

  /// Cleanup expired content
  Future<Result<void>> cleanupExpiredContent();

  /// Stream of download status updates
  Stream<DownloadStatus> get downloadStatusStream;
}
