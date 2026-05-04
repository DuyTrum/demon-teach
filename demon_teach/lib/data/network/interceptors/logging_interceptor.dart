import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Interceptor that logs HTTP requests and responses for debugging
///
/// Features:
/// - Logs request method, URL, headers, and body
/// - Logs response status, headers, and body
/// - Logs errors with details
/// - Filters sensitive headers (Authorization, API-Key)
/// - Truncates large bodies (> 1KB)
/// - Only logs in debug mode
class LoggingInterceptor extends Interceptor {
  static const int _maxBodyLength = 1024; // 1KB
  static const List<String> _sensitiveHeaders = ['Authorization', 'API-Key'];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      print('[HTTP] → ${options.method} ${options.uri}');
      print('[HTTP] Headers: ${_filterSensitiveHeaders(options.headers)}');
      if (options.data != null) {
        print('[HTTP] Body: ${_truncateBody(options.data)}');
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      print('[HTTP] ← ${response.statusCode} ${response.requestOptions.uri}');
      print('[HTTP] Body: ${_truncateBody(response.data)}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      print('[HTTP] ✗ ${err.requestOptions.method} ${err.requestOptions.uri}');
      print('[HTTP] Error: ${err.type} - ${err.message}');
    }
    handler.next(err);
  }

  /// Filter sensitive headers by replacing their values with ***
  Map<String, dynamic> _filterSensitiveHeaders(Map<String, dynamic> headers) {
    return headers.map((key, value) {
      if (_sensitiveHeaders.contains(key)) {
        return MapEntry(key, '***');
      }
      return MapEntry(key, value);
    });
  }

  /// Truncate body if larger than max length
  String _truncateBody(dynamic body) {
    final str = body.toString();
    if (str.length > _maxBodyLength) {
      return '${str.substring(0, _maxBodyLength)}... (truncated)';
    }
    return str;
  }
}
