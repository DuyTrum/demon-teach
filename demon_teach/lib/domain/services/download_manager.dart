import 'dart:async';
import 'package:demon_teach/domain/entities/download_status.dart';
import 'package:demon_teach/domain/entities/offline_content.dart';

/// Download Manager Service
///
/// Manages downloading of lessons and content for offline use.
/// Implements Requirement 15: Offline Mode Support
class DownloadManager {
  final StreamController<DownloadStatus> _downloadStatusController =
      StreamController<DownloadStatus>.broadcast();

  final Map<String, DownloadStatus> _activeDownloads = {};
  final int maxConcurrentDownloads = 3;
  final int maxStorageMB = 500; // 500MB max storage

  /// Stream of download status updates
  Stream<DownloadStatus> get downloadStatusStream =>
      _downloadStatusController.stream;

  /// Download next N lessons for offline use
  ///
  /// Requirement 15.1: Download next 3 Daily_Lesson modules when online
  Future<List<DownloadStatus>> downloadNextLessons({
    required String userId,
    required String targetLanguage,
    int count = 3,
  }) async {
    final List<DownloadStatus> results = [];

    // Get next lessons from learning path
    final nextLessons = await _getNextLessons(userId, targetLanguage, count);

    for (final lessonId in nextLessons) {
      // Check if already downloaded
      if (await _isLessonDownloaded(lessonId)) {
        results.add(DownloadStatus(
          contentId: lessonId,
          state: DownloadState.completed,
          progress: 1.0,
        ));
        continue;
      }

      // Check storage space
      if (!await _hasStorageSpace()) {
        results.add(DownloadStatus(
          contentId: lessonId,
          state: DownloadState.failed,
          error: 'Insufficient storage space',
        ));
        continue;
      }

      // Start download
      final status = await _downloadLesson(lessonId);
      results.add(status);
    }

    return results;
  }

  /// Download a single lesson with all content
  ///
  /// Requirement 15.2: Download all Lesson_Content including audio and images
  Future<DownloadStatus> _downloadLesson(String lessonId) async {
    // Create initial status
    var status = DownloadStatus(
      contentId: lessonId,
      state: DownloadState.pending,
      startedAt: DateTime.now(),
    );

    _activeDownloads[lessonId] = status;
    _downloadStatusController.add(status);

    try {
      // Update to downloading
      status = status.copyWith(state: DownloadState.downloading);
      _activeDownloads[lessonId] = status;
      _downloadStatusController.add(status);

      // Download lesson content
      final lessonContent = await _fetchLessonContent(lessonId);

      // Download audio files
      final audioFiles = _extractAudioUrls(lessonContent);
      for (final audioUrl in audioFiles) {
        await _downloadFile(audioUrl, lessonId);
      }

      // Download image files
      final imageFiles = _extractImageUrls(lessonContent);
      for (final imageUrl in imageFiles) {
        await _downloadFile(imageUrl, lessonId);
      }

      // Save lesson content locally
      await _saveLessonLocally(lessonId, lessonContent);

      // Mark as completed
      status = status.copyWith(
        state: DownloadState.completed,
        progress: 1.0,
        completedAt: DateTime.now(),
      );
      _activeDownloads.remove(lessonId);
      _downloadStatusController.add(status);

      return status;
    } catch (e) {
      // Mark as failed
      status = status.copyWith(
        state: DownloadState.failed,
        error: e.toString(),
      );
      _activeDownloads.remove(lessonId);
      _downloadStatusController.add(status);

      return status;
    }
  }

  /// Download a file (audio or image)
  Future<String> _downloadFile(String url, String lessonId) async {
    // Simulate download with progress
    // In real implementation, use dio or http package with progress callback
    await Future.delayed(const Duration(milliseconds: 500));

    // Return local file path
    return '/local/storage/$lessonId/${url.split('/').last}';
  }

  /// Check if lesson is already downloaded
  Future<bool> _isLessonDownloaded(String lessonId) async {
    // Check local database for downloaded lesson
    // Implementation depends on local data source
    return false; // Placeholder
  }

  /// Check if there's enough storage space
  Future<bool> _hasStorageSpace() async {
    final usedSpace = await _getUsedStorageSpace();
    final maxSpace = maxStorageMB * 1024 * 1024; // Convert to bytes
    return usedSpace < maxSpace;
  }

  /// Get used storage space in bytes
  Future<int> _getUsedStorageSpace() async {
    // Calculate total size of downloaded content
    // Implementation depends on local data source
    return 0; // Placeholder
  }

  /// Get next lessons from learning path
  Future<List<String>> _getNextLessons(
    String userId,
    String targetLanguage,
    int count,
  ) async {
    // Get from learning path repository
    // Implementation depends on repository
    return []; // Placeholder
  }

  /// Fetch lesson content from API
  Future<Map<String, dynamic>> _fetchLessonContent(String lessonId) async {
    // Fetch from remote API
    // Implementation depends on remote data source
    return {}; // Placeholder
  }

  /// Extract audio URLs from lesson content
  List<String> _extractAudioUrls(Map<String, dynamic> content) {
    final List<String> urls = [];

    // Extract from flashcards
    if (content['flashcards'] != null) {
      for (final flashcard in content['flashcards']) {
        if (flashcard['audioUrl'] != null) {
          urls.add(flashcard['audioUrl']);
        }
      }
    }

    // Extract from listening exercise
    if (content['listeningExercise']?['audioUrl'] != null) {
      urls.add(content['listeningExercise']['audioUrl']);
    }

    // Extract from speaking exercise
    if (content['speakingExercise']?['modelAudioUrl'] != null) {
      urls.add(content['speakingExercise']['modelAudioUrl']);
    }

    return urls;
  }

  /// Extract image URLs from lesson content
  List<String> _extractImageUrls(Map<String, dynamic> content) {
    final List<String> urls = [];

    // Extract image URLs if present in content
    // Implementation depends on content structure

    return urls;
  }

  /// Save lesson content locally
  Future<void> _saveLessonLocally(
    String lessonId,
    Map<String, dynamic> content,
  ) async {
    // Save to local database
    // Implementation depends on local data source
  }

  /// Get download status for a lesson
  DownloadStatus? getDownloadStatus(String lessonId) {
    return _activeDownloads[lessonId];
  }

  /// Get all active downloads
  List<DownloadStatus> getActiveDownloads() {
    return _activeDownloads.values.toList();
  }

  /// Cancel a download
  Future<void> cancelDownload(String lessonId) async {
    final status = _activeDownloads[lessonId];
    if (status != null) {
      final cancelledStatus = status.copyWith(
        state: DownloadState.cancelled,
      );
      _activeDownloads.remove(lessonId);
      _downloadStatusController.add(cancelledStatus);
    }
  }

  /// Pause a download
  Future<void> pauseDownload(String lessonId) async {
    final status = _activeDownloads[lessonId];
    if (status != null && status.isDownloading) {
      final pausedStatus = status.copyWith(
        state: DownloadState.paused,
      );
      _activeDownloads[lessonId] = pausedStatus;
      _downloadStatusController.add(pausedStatus);
    }
  }

  /// Resume a paused download
  Future<void> resumeDownload(String lessonId) async {
    final status = _activeDownloads[lessonId];
    if (status != null && status.isPaused) {
      final resumedStatus = status.copyWith(
        state: DownloadState.downloading,
      );
      _activeDownloads[lessonId] = resumedStatus;
      _downloadStatusController.add(resumedStatus);

      // Continue download
      await _downloadLesson(lessonId);
    }
  }

  /// Clean up expired content
  Future<void> cleanupExpiredContent() async {
    // Remove expired offline content
    // Implementation depends on local data source
  }

  /// Get offline availability info
  Future<OfflineAvailability> getOfflineAvailability(
    String userId,
    String targetLanguage,
  ) async {
    // Get offline availability statistics
    // Implementation depends on local data source
    return const OfflineAvailability(
      isAvailable: false,
      totalLessons: 0,
      downloadedLessons: 0,
      totalSizeBytes: 0,
      usedSizeBytes: 0,
    );
  }

  /// Dispose resources
  void dispose() {
    _downloadStatusController.close();
  }
}
