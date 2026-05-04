import 'dart:io';
import 'package:dio/dio.dart';
import 'package:demon_teach/core/errors/failures.dart';

/// Interceptor that maps DioException to domain Failure types
///
/// Mapping rules:
/// - 401/403 → AuthFailure
/// - 400-499 (excluding 401/403) → NetworkFailure (client error)
/// - 500-599 → ServerFailure
/// - Timeouts → NetworkFailure
/// - SocketException → NetworkFailure (no connection)
/// - Other connection errors → NetworkFailure
/// - Cancel → NetworkFailure
/// - Unknown → NetworkFailure
///
/// The mapped Failure is attached to err.error for datasource extraction
class ErrorMappingInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final failure = _mapDioExceptionToFailure(err);

    // Create new DioException with failure attached
    final newErr = DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: failure, // Attach failure here
      message: err.message,
    );

    handler.next(newErr);
  }

  /// Map DioException to appropriate Failure type
  Failure _mapDioExceptionToFailure(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkFailure(
          message: 'Request timeout: connection took longer than expected',
          code: err.response?.statusCode,
        );

      case DioExceptionType.badResponse:
        return _mapStatusCodeToFailure(err.response!);

      case DioExceptionType.cancel:
        return const NetworkFailure(
          message: 'Request cancelled',
          code: null,
        );

      case DioExceptionType.connectionError:
        if (err.error is SocketException) {
          return const NetworkFailure(
            message: 'No network connection available',
            code: null,
          );
        }
        return NetworkFailure(
          message: 'Connection failed: ${err.message}',
          code: null,
        );

      case DioExceptionType.badCertificate:
        return const NetworkFailure(
          message: 'SSL certificate verification failed',
          code: null,
        );

      case DioExceptionType.unknown:
      default:
        return NetworkFailure(
          message: 'Network error: ${err.message}',
          code: null,
        );
    }
  }

  /// Map HTTP status code to appropriate Failure type
  Failure _mapStatusCodeToFailure(Response response) {
    final statusCode = response.statusCode!;
    final statusMessage = response.statusMessage ?? '';

    // Authentication/Authorization failures
    if (statusCode == 401 || statusCode == 403) {
      return AuthFailure(
        message: 'Authentication failed: $statusCode - $statusMessage',
        code: statusCode,
      );
    }

    // Client errors (400-499)
    if (statusCode >= 400 && statusCode < 500) {
      return NetworkFailure(
        message: 'Client error: $statusCode - $statusMessage',
        code: statusCode,
      );
    }

    // Server errors (500-599)
    if (statusCode >= 500) {
      return ServerFailure(
        message: 'Server error: $statusCode - $statusMessage',
        code: statusCode,
      );
    }

    // Other HTTP errors
    return NetworkFailure(
      message: 'HTTP error: $statusCode - $statusMessage',
      code: statusCode,
    );
  }
}
