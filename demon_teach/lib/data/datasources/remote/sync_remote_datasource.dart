import 'package:dio/dio.dart';
import 'package:demon_teach/core/errors/failures.dart';
import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/progress.dart';
import 'package:demon_teach/domain/entities/performance_data.dart';
import 'package:demon_teach/domain/entities/review_item.dart';

/// Sync Remote Data Source Interface
///
/// Defines contract for remote sync operations.
/// Uses HTTP client (dio) for API communication.
abstract class SyncRemoteDataSource {
  /// Get remote progress
  Future<Result<Progress?>> getRemoteProgress(
    String userId,
    String targetLanguage,
  );

  /// Update remote progress
  Future<Result<void>> updateRemoteProgress(Progress progress);

  /// Update remote performance
  Future<Result<void>> updateRemotePerformance(PerformanceData performance);

  /// Get remote review items
  Future<Result<List<ReviewItem>>> getRemoteReviews(String userId);

  /// Update remote review
  Future<Result<void>> updateRemoteReview(ReviewItem review);

  /// Get content updates since timestamp
  Future<Result<List<Map<String, dynamic>>>> getContentUpdates(
    DateTime? since,
  );

  /// Check network connectivity
  Future<Result<bool>> checkConnectivity();
}

/// Sync Remote Data Source Implementation
///
/// Implements remote sync operations using Dio HTTP client.
///
/// Features:
/// - Syncs progress, performance, and review items with backend
/// - Handles 404 as "no remote data" (returns null)
/// - Maps entities to/from JSON for API communication
/// - Checks network connectivity before sync operations
class SyncRemoteDataSourceImpl implements SyncRemoteDataSource {
  final Dio _dio;

  SyncRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  @override
  Future<Result<Progress?>> getRemoteProgress(
    String userId,
    String targetLanguage,
  ) async {
    try {
      final response = await _dio.get(
        '/api/users/$userId/progress/$targetLanguage',
      );

      // Verify response
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final progress = _progressFromJson(data);
        return Result.success(progress);
      }

      return Result.success(null);
    } on DioException catch (e) {
      // 404 means no remote progress exists yet - this is OK
      if (e.response?.statusCode == 404) {
        return Result.success(null);
      }

      // Extract mapped Failure from error
      final failure = e.error as Failure? ??
          NetworkFailure(
            message: 'Failed to get remote progress: ${e.message}',
          );
      return Result.failure(failure);
    } catch (e) {
      return Result.failure(
        NetworkFailure(message: 'Unexpected error getting progress: $e'),
      );
    }
  }

  @override
  Future<Result<void>> updateRemoteProgress(Progress progress) async {
    try {
      await _dio.put(
        '/api/users/${progress.userId}/progress',
        data: _progressToJson(progress),
      );

      return Result.success(null);
    } on DioException catch (e) {
      final failure = e.error as Failure? ??
          NetworkFailure(
            message: 'Failed to update remote progress: ${e.message}',
          );
      return Result.failure(failure);
    } catch (e) {
      return Result.failure(
        NetworkFailure(message: 'Unexpected error updating progress: $e'),
      );
    }
  }

  @override
  Future<Result<void>> updateRemotePerformance(
    PerformanceData performance,
  ) async {
    try {
      await _dio.post(
        '/api/users/${performance.userId}/performance',
        data: _performanceToJson(performance),
      );

      return Result.success(null);
    } on DioException catch (e) {
      final failure = e.error as Failure? ??
          NetworkFailure(
            message: 'Failed to update remote performance: ${e.message}',
          );
      return Result.failure(failure);
    } catch (e) {
      return Result.failure(
        NetworkFailure(message: 'Unexpected error updating performance: $e'),
      );
    }
  }

  @override
  Future<Result<List<ReviewItem>>> getRemoteReviews(String userId) async {
    try {
      final response = await _dio.get('/api/users/$userId/reviews');

      if (response.statusCode == 200) {
        final data = response.data as List;
        final reviews = data
            .map((json) => _reviewItemFromJson(json as Map<String, dynamic>))
            .toList();
        return Result.success(reviews);
      }

      return Result.success([]);
    } on DioException catch (e) {
      final failure = e.error as Failure? ??
          NetworkFailure(
            message: 'Failed to get remote reviews: ${e.message}',
          );
      return Result.failure(failure);
    } catch (e) {
      return Result.failure(
        NetworkFailure(message: 'Unexpected error getting reviews: $e'),
      );
    }
  }

  @override
  Future<Result<void>> updateRemoteReview(ReviewItem review) async {
    try {
      await _dio.put(
        '/api/users/${review.userId}/reviews/${review.id}',
        data: _reviewItemToJson(review),
      );

      return Result.success(null);
    } on DioException catch (e) {
      final failure = e.error as Failure? ??
          NetworkFailure(
            message: 'Failed to update remote review: ${e.message}',
          );
      return Result.failure(failure);
    } catch (e) {
      return Result.failure(
        NetworkFailure(message: 'Unexpected error updating review: $e'),
      );
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getContentUpdates(
    DateTime? since,
  ) async {
    try {
      final queryParams = since != null
          ? {'since': since.toIso8601String()}
          : <String, dynamic>{};

      final response = await _dio.get(
        '/api/content/updates',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data as List;
        final updates =
            data.map((item) => item as Map<String, dynamic>).toList();
        return Result.success(updates);
      }

      return Result.success([]);
    } on DioException catch (e) {
      final failure = e.error as Failure? ??
          NetworkFailure(
            message: 'Failed to get content updates: ${e.message}',
          );
      return Result.failure(failure);
    } catch (e) {
      return Result.failure(
        NetworkFailure(message: 'Unexpected error getting updates: $e'),
      );
    }
  }

  @override
  Future<Result<bool>> checkConnectivity() async {
    try {
      final response = await _dio.head(
        '/',
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );

      return Result.success(response.statusCode == 200);
    } on DioException {
      return Result.success(false);
    } catch (_) {
      return Result.success(false);
    }
  }

  // Helper methods for JSON serialization

  Progress _progressFromJson(Map<String, dynamic> json) {
    return Progress(
      userId: json['userId'] as String,
      targetLanguage: json['targetLanguage'] as String,
      totalXP: json['totalXP'] as int,
      currentStreak: json['currentStreak'] as int,
      longestStreak: json['longestStreak'] as int,
      lessonsCompleted: json['lessonsCompleted'] as int,
      lastLessonDate: json['lastLessonDate'] != null
          ? DateTime.parse(json['lastLessonDate'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> _progressToJson(Progress progress) {
    return {
      'userId': progress.userId,
      'targetLanguage': progress.targetLanguage,
      'totalXP': progress.totalXP,
      'currentStreak': progress.currentStreak,
      'longestStreak': progress.longestStreak,
      'lessonsCompleted': progress.lessonsCompleted,
      'lastLessonDate': progress.lastLessonDate?.toIso8601String(),
      'createdAt': progress.createdAt.toIso8601String(),
      'updatedAt': progress.updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> _performanceToJson(PerformanceData performance) {
    return performance.toJson();
  }

  ReviewItem _reviewItemFromJson(Map<String, dynamic> json) {
    return ReviewItem.fromJson(json);
  }

  Map<String, dynamic> _reviewItemToJson(ReviewItem review) {
    return review.toJson();
  }
}
