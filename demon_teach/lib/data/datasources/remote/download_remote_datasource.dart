import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:demon_teach/core/errors/failures.dart';
import 'package:demon_teach/core/utils/result.dart';

/// Download Remote Data Source Interface
///
/// Defines contract for remote download operations.
/// Uses HTTP client (dio) for API communication.
abstract class DownloadRemoteDataSource {
  /// Download lesson content from API
  Future<Result<Map<String, dynamic>>> downloadLessonContent(
    String lessonId, {
    Function(double progress)? onProgress,
  });

  /// Download file (audio or image)
  Future<Result<String>> downloadFile(
    String url,
    String lessonId, {
    Function(double progress)? onProgress,
  });

  /// Get lesson metadata
  Future<Result<Map<String, dynamic>>> getLessonMetadata(String lessonId);

  /// Check if lesson is available for download
  Future<Result<bool>> isLessonAvailable(String lessonId);
}

/// Download Remote Data Source Implementation
///
/// Implements remote download operations using Dio HTTP client.
///
/// Features:
/// - Downloads lesson content from API
/// - Downloads files (audio, images) with progress tracking
/// - Uses separate Dio instance for large file downloads (120s timeout)
/// - Handles errors and maps to domain Failures
class DownloadRemoteDataSourceImpl implements DownloadRemoteDataSource {
  final Dio _dio; // Base client for API requests
  final Dio _downloadDio; // Extended timeout for file downloads

  DownloadRemoteDataSourceImpl({
    required Dio dio,
    required Dio downloadDio,
  })  : _dio = dio,
        _downloadDio = downloadDio;

  @override
  Future<Result<Map<String, dynamic>>> downloadLessonContent(
    String lessonId, {
    Function(double progress)? onProgress,
  }) async {
    try {
      final response = await _dio.get(
        '/api/lessons/$lessonId',
        onReceiveProgress: (received, total) {
          if (onProgress != null && total > 0) {
            onProgress(received / total);
          }
        },
      );

      // Verify response
      if (response.statusCode != 200) {
        return Result.failure(NetworkFailure(
          message: 'Failed to download lesson: HTTP ${response.statusCode}',
          code: response.statusCode,
        ));
      }

      // Parse JSON response
      final data = response.data as Map<String, dynamic>;
      return Result.success(data);
    } on DioException catch (e) {
      // Extract mapped Failure from error
      final failure = e.error as Failure? ??
          NetworkFailure(
            message: 'Failed to download lesson content: ${e.message}',
          );
      return Result.failure(failure);
    } catch (e) {
      return Result.failure(
        NetworkFailure(message: 'Unexpected error downloading lesson: $e'),
      );
    }
  }

  @override
  Future<Result<String>> downloadFile(
    String url,
    String lessonId, {
    Function(double progress)? onProgress,
  }) async {
    try {
      // Create local file path
      final fileName = url.split('/').last;
      final directory = await getApplicationDocumentsDirectory();
      final localPath = '${directory.path}/lessons/$lessonId/$fileName';

      // Ensure directory exists
      final file = File(localPath);
      await file.parent.create(recursive: true);

      // Download file using download client (120s timeout)
      await _downloadDio.download(
        url,
        localPath,
        onReceiveProgress: (received, total) {
          if (onProgress != null && total > 0) {
            onProgress(received / total);
          }
        },
        options: Options(
          responseType: ResponseType.bytes, // Important for binary files
        ),
      );

      // Verify file was downloaded
      if (!await file.exists()) {
        return Result.failure(const NetworkFailure(
          message: 'File download completed but file not found',
        ));
      }

      // Verify file is not empty
      final fileSize = await file.length();
      if (fileSize == 0) {
        return Result.failure(const NetworkFailure(
          message: 'Downloaded file is empty',
        ));
      }

      return Result.success(localPath);
    } on DioException catch (e) {
      // Extract mapped Failure from error
      final failure = e.error as Failure? ??
          NetworkFailure(
            message: 'Failed to download file: ${e.message}',
          );
      return Result.failure(failure);
    } catch (e) {
      return Result.failure(
        NetworkFailure(message: 'Unexpected error downloading file: $e'),
      );
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getLessonMetadata(
    String lessonId,
  ) async {
    try {
      final response = await _dio.get('/api/lessons/$lessonId/metadata');

      // Verify response
      if (response.statusCode != 200) {
        return Result.failure(NetworkFailure(
          message: 'Failed to get metadata: HTTP ${response.statusCode}',
          code: response.statusCode,
        ));
      }

      // Parse JSON response
      final data = response.data as Map<String, dynamic>;
      return Result.success(data);
    } on DioException catch (e) {
      // Extract mapped Failure from error
      final failure = e.error as Failure? ??
          NetworkFailure(
            message: 'Failed to get lesson metadata: ${e.message}',
          );
      return Result.failure(failure);
    } catch (e) {
      return Result.failure(
        NetworkFailure(message: 'Unexpected error getting metadata: $e'),
      );
    }
  }

  @override
  Future<Result<bool>> isLessonAvailable(String lessonId) async {
    try {
      // Use HEAD request to check availability without downloading content
      final response = await _dio.head('/api/lessons/$lessonId');

      // Lesson is available if status is 200
      return Result.success(response.statusCode == 200);
    } on DioException {
      // If HEAD request fails, lesson is not available
      // Don't treat this as an error - just return false
      return Result.success(false);
    } catch (_) {
      // Unexpected error - return false
      return Result.success(false);
    }
  }
}
