import 'package:dio/dio.dart';
import 'package:demon_teach/data/network/interceptors/logging_interceptor.dart';
import 'package:demon_teach/data/network/interceptors/retry_interceptor.dart';
import 'package:demon_teach/data/network/interceptors/error_mapping_interceptor.dart';

/// Factory for creating configured Dio HTTP clients
class DioClientFactory {
  /// Create base Dio client for API requests
  ///
  /// Configured with:
  /// - 10s connection timeout
  /// - 30s receive timeout
  /// - JSON headers (Content-Type, Accept)
  /// - Logging, Retry, and Error Mapping interceptors
  static Dio createBaseClient({
    required String baseUrl,
    Duration connectTimeout = const Duration(seconds: 10),
    Duration receiveTimeout = const Duration(seconds: 30),
  }) {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add interceptors in order: Logging → Retry → Error Mapping
    dio.interceptors.addAll([
      LoggingInterceptor(),
      RetryInterceptor(),
      ErrorMappingInterceptor(),
    ]);

    return dio;
  }

  /// Create Dio client for file downloads with extended timeout
  ///
  /// Configured with:
  /// - 10s connection timeout
  /// - 120s receive timeout (for large files)
  /// - No Content-Type/Accept headers (downloads don't need JSON headers)
  /// - Same interceptors as base client
  static Dio createDownloadClient({
    required String baseUrl,
    Duration connectTimeout = const Duration(seconds: 10),
    Duration receiveTimeout = const Duration(seconds: 120),
  }) {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      // No headers - downloads don't need Content-Type/Accept
    ));

    // Add interceptors in order: Logging → Retry → Error Mapping
    dio.interceptors.addAll([
      LoggingInterceptor(),
      RetryInterceptor(),
      ErrorMappingInterceptor(),
    ]);

    return dio;
  }
}
