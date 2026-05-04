import 'dart:async';
import 'package:demon_teach/core/errors/failures.dart';
import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/download_status.dart';
import 'package:demon_teach/domain/entities/offline_content.dart';
import 'package:demon_teach/domain/repositories/download_repository.dart';
import 'package:demon_teach/data/datasources/local/download_local_datasource.dart';
import 'package:demon_teach/data/datasources/remote/download_remote_datasource.dart';

/// Download Repository Implementation
///
/// Implements download operations with local and remote data sources.
/// Handles caching, retry logic, and offline content management.
class DownloadRepositoryImpl implements DownloadRepository {
  final DownloadLocalDataSource _localDataSource;
  final DownloadRemoteDataSource _remoteDataSource;

  final StreamController<DownloadStatus> _downloadStatusController =
      StreamController<DownloadStatus>.broadcast();

  DownloadRepositoryImpl({
    required DownloadLocalDataSource localDataSource,
    required DownloadRemoteDataSource remoteDataSource,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource;

  @override
  Stream<DownloadStatus> get downloadStatusStream =>
      _downloadStatusController.stream;

  @override
  Future<Result<DownloadStatus>> downloadLesson(String lessonId) async {
    try {
      // Check if already downloaded
      final existingResult = await _localDataSource.getDownloadStatus(lessonId);
      if (existingResult.isSuccess) {
        final existing = existingResult.value;
        if (existing != null && existing.isCompleted) {
          return Result.success(existing);
        }
      }

      // Create initial status
      var status = DownloadStatus(
        contentId: lessonId,
        state: DownloadState.downloading,
        startedAt: DateTime.now(),
      );

      // Save initial status
      await _localDataSource.saveDownloadStatus(status);
      _downloadStatusController.add(status);

      // Download lesson content from remote
      final contentResult = await _remoteDataSource.downloadLessonContent(
        lessonId,
        onProgress: (progress) {
          status = status.copyWith(progress: progress);
          _downloadStatusController.add(status);
        },
      );

      if (contentResult.isFailure) {
        final errorMsg = contentResult.failure.message;
        status = status.copyWith(
          state: DownloadState.failed,
          error: errorMsg,
        );
        await _localDataSource.saveDownloadStatus(status);
        _downloadStatusController.add(status);
        return Result.failure(contentResult.failure);
      }

      final content = contentResult.value;

      // Download audio files
      final audioUrls = _extractAudioUrls(content);
      for (final audioUrl in audioUrls) {
        final audioResult = await _remoteDataSource.downloadFile(
          audioUrl,
          lessonId,
        );
        if (audioResult.isFailure) {
          final errorMsg = audioResult.failure.message;
          status = status.copyWith(
            state: DownloadState.failed,
            error: 'Failed to download audio: $errorMsg',
          );
          await _localDataSource.saveDownloadStatus(status);
          _downloadStatusController.add(status);
          return Result.failure(audioResult.failure);
        }
      }

      // Download image files
      final imageUrls = _extractImageUrls(content);
      for (final imageUrl in imageUrls) {
        final imageResult = await _remoteDataSource.downloadFile(
          imageUrl,
          lessonId,
        );
        if (imageResult.isFailure) {
          final errorMsg = imageResult.failure.message;
          status = status.copyWith(
            state: DownloadState.failed,
            error: 'Failed to download image: $errorMsg',
          );
          await _localDataSource.saveDownloadStatus(status);
          _downloadStatusController.add(status);
          return Result.failure(imageResult.failure);
        }
      }

      // Save offline content
      final offlineContent = OfflineContent(
        contentId: lessonId,
        contentType: 'lesson',
        localPath: '/local/storage/$lessonId',
        downloadedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
        sizeBytes: _calculateContentSize(content),
        metadata: content,
      );

      final saveResult = await _localDataSource.saveOfflineContent(
        offlineContent,
      );

      if (saveResult.isFailure) {
        final errorMsg = saveResult.failure.message;
        status = status.copyWith(
          state: DownloadState.failed,
          error: 'Failed to save content: $errorMsg',
        );
        await _localDataSource.saveDownloadStatus(status);
        _downloadStatusController.add(status);
        return Result.failure(saveResult.failure);
      }

      // Mark as completed
      status = status.copyWith(
        state: DownloadState.completed,
        progress: 1.0,
        completedAt: DateTime.now(),
      );
      await _localDataSource.saveDownloadStatus(status);
      _downloadStatusController.add(status);

      return Result.success(status);
    } catch (e) {
      final status = DownloadStatus(
        contentId: lessonId,
        state: DownloadState.failed,
        error: e.toString(),
      );
      await _localDataSource.saveDownloadStatus(status);
      _downloadStatusController.add(status);
      return Result.failure(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<DownloadStatus>>> downloadLessons(
    List<String> lessonIds,
  ) async {
    try {
      final List<DownloadStatus> results = [];

      for (final lessonId in lessonIds) {
        final result = await downloadLesson(lessonId);
        if (result.isSuccess) {
          results.add(result.value);
        } else {
          // Continue with other downloads even if one fails
          results.add(DownloadStatus(
            contentId: lessonId,
            state: DownloadState.failed,
            error: result.failure.message,
          ));
        }
      }

      return Result.success(results);
    } catch (e) {
      return Result.failure(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<DownloadStatus?>> getDownloadStatus(String lessonId) async {
    return await _localDataSource.getDownloadStatus(lessonId);
  }

  @override
  Future<Result<List<DownloadStatus>>> getActiveDownloads() async {
    return await _localDataSource.getActiveDownloads();
  }

  @override
  Future<Result<void>> cancelDownload(String lessonId) async {
    try {
      final statusResult = await _localDataSource.getDownloadStatus(lessonId);
      if (statusResult.isSuccess && statusResult.value != null) {
        final status = statusResult.value!.copyWith(
          state: DownloadState.cancelled,
        );
        await _localDataSource.saveDownloadStatus(status);
        _downloadStatusController.add(status);
      }
      return Result.success(null);
    } catch (e) {
      return Result.failure(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> pauseDownload(String lessonId) async {
    try {
      final statusResult = await _localDataSource.getDownloadStatus(lessonId);
      if (statusResult.isSuccess && statusResult.value != null) {
        final status = statusResult.value!;
        if (status.isDownloading) {
          final pausedStatus = status.copyWith(
            state: DownloadState.paused,
          );
          await _localDataSource.saveDownloadStatus(pausedStatus);
          _downloadStatusController.add(pausedStatus);
        }
      }
      return Result.success(null);
    } catch (e) {
      return Result.failure(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> resumeDownload(String lessonId) async {
    try {
      final statusResult = await _localDataSource.getDownloadStatus(lessonId);
      if (statusResult.isSuccess && statusResult.value != null) {
        final status = statusResult.value!;
        if (status.isPaused) {
          // Resume download
          return await downloadLesson(lessonId)
              .then((_) => Result.success(null));
        }
      }
      return Result.success(null);
    } catch (e) {
      return Result.failure(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<bool>> isLessonDownloaded(String lessonId) async {
    try {
      final contentResult = await _localDataSource.getOfflineContent(lessonId);
      return Result.success(
          contentResult.isSuccess && contentResult.value != null);
    } catch (e) {
      return Result.failure(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<OfflineContent?>> getOfflineContent(String contentId) async {
    return await _localDataSource.getOfflineContent(contentId);
  }

  @override
  Future<Result<List<OfflineContent>>> getAllOfflineContent() async {
    return await _localDataSource.getAllOfflineContent();
  }

  @override
  Future<Result<void>> deleteOfflineContent(String contentId) async {
    try {
      await _localDataSource.deleteOfflineContent(contentId);
      await _localDataSource.deleteDownloadStatus(contentId);
      return Result.success(null);
    } catch (e) {
      return Result.failure(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<OfflineAvailability>> getOfflineAvailability(
    String userId,
    String targetLanguage,
  ) async {
    try {
      final allContentResult = await _localDataSource.getAllOfflineContent();
      if (allContentResult.isFailure) {
        return Result.failure(allContentResult.failure);
      }

      final allContent = allContentResult.value;
      final totalSizeBytes = allContent.fold<int>(
        0,
        (sum, content) => sum + content.sizeBytes,
      );

      // Get total lessons count from remote (or cache)
      final totalLessons = 100; // Placeholder - should come from learning path

      return Result.success(OfflineAvailability(
        isAvailable: allContent.isNotEmpty,
        totalLessons: totalLessons,
        downloadedLessons: allContent.length,
        totalSizeBytes: totalSizeBytes,
        usedSizeBytes: totalSizeBytes,
      ));
    } catch (e) {
      return Result.failure(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<int>> getUsedStorageSpace() async {
    try {
      final allContentResult = await _localDataSource.getAllOfflineContent();
      if (allContentResult.isFailure) {
        return Result.failure(allContentResult.failure);
      }

      final totalSize = allContentResult.value.fold<int>(
        0,
        (sum, content) => sum + content.sizeBytes,
      );

      return Result.success(totalSize);
    } catch (e) {
      return Result.failure(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> cleanupExpiredContent() async {
    try {
      final allContentResult = await _localDataSource.getAllOfflineContent();
      if (allContentResult.isFailure) {
        return Result.failure(allContentResult.failure);
      }

      final now = DateTime.now();
      for (final content in allContentResult.value) {
        if (content.expiresAt != null && content.expiresAt!.isBefore(now)) {
          await _localDataSource.deleteOfflineContent(content.contentId);
        }
      }

      return Result.success(null);
    } catch (e) {
      return Result.failure(CacheFailure(message: e.toString()));
    }
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
    if (content['images'] != null) {
      for (final image in content['images']) {
        if (image is String) {
          urls.add(image);
        }
      }
    }

    return urls;
  }

  /// Calculate content size (approximate)
  int _calculateContentSize(Map<String, dynamic> content) {
    // Rough estimation based on JSON size
    // In production, should track actual file sizes
    final jsonString = content.toString();
    return jsonString.length * 2; // UTF-8 approximation
  }

  void dispose() {
    _downloadStatusController.close();
  }
}
