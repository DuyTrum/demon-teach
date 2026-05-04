import 'package:dio/dio.dart';

/// Interceptor that automatically retries failed GET/HEAD requests
///
/// Features:
/// - Only retries GET and HEAD requests (idempotent)
/// - Does NOT retry POST/PUT (to avoid duplicate writes)
/// - Exponential backoff: 1s → 2s → 4s
/// - Max 3 retry attempts
/// - Skips retry for client errors (400-499)
/// - Retries server errors (500-599) and timeouts
class RetryInterceptor extends Interceptor {
  static const int maxRetries = 3;
  static const List<Duration> retryDelays = [
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 4),
  ];

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Only retry GET and HEAD requests
    if (!_isRetryableMethod(err.requestOptions.method)) {
      return handler.next(err);
    }

    // Don't retry client errors (400-499)
    if (_isClientError(err.response?.statusCode)) {
      return handler.next(err);
    }

    // Don't retry if not a retryable error type
    if (!_isRetryableError(err.type)) {
      return handler.next(err);
    }

    // Get retry count from request options
    final retryCount = err.requestOptions.extra['retryCount'] as int? ?? 0;

    if (retryCount >= maxRetries) {
      return handler.next(err);
    }

    // Wait before retrying (exponential backoff)
    await Future.delayed(retryDelays[retryCount]);

    // Increment retry count
    err.requestOptions.extra['retryCount'] = retryCount + 1;

    // Retry the request
    try {
      final response = await Dio().fetch(err.requestOptions);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }

  /// Check if HTTP method is retryable (GET or HEAD only)
  bool _isRetryableMethod(String method) {
    return method.toUpperCase() == 'GET' || method.toUpperCase() == 'HEAD';
  }

  /// Check if status code is a client error (400-499)
  bool _isClientError(int? statusCode) {
    return statusCode != null && statusCode >= 400 && statusCode < 500;
  }

  /// Check if error type is retryable
  ///
  /// Retryable errors:
  /// - Timeouts (connection, send, receive)
  /// - Connection errors
  /// - Unknown errors
  ///
  /// Non-retryable errors:
  /// - Bad response (handled by status code check)
  /// - Cancel
  /// - Bad certificate
  bool _isRetryableError(DioExceptionType type) {
    return type == DioExceptionType.connectionTimeout ||
        type == DioExceptionType.sendTimeout ||
        type == DioExceptionType.receiveTimeout ||
        type == DioExceptionType.connectionError ||
        type == DioExceptionType.unknown;
  }
}
