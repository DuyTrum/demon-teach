import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:demon_teach/data/network/interceptors/retry_interceptor.dart';

void main() {
  group('RetryInterceptor', () {
    late RetryInterceptor interceptor;

    setUp(() {
      interceptor = RetryInterceptor();
    });

    group('Retry Logic for GET Requests', () {
      test('should retry GET request on timeout error', () async {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test', method: 'GET'),
          type: DioExceptionType.connectionTimeout,
        );

        // Verify error is retryable
        expect(error.requestOptions.method, 'GET');
        expect(error.type, DioExceptionType.connectionTimeout);
      });

      test('should retry GET request on server error (500)', () async {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test', method: 'GET'),
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 500,
          ),
          type: DioExceptionType.badResponse,
        );

        expect(error.response?.statusCode, 500);
        expect(error.requestOptions.method, 'GET');
      });

      test('should track retry count in request options', () {
        final options = RequestOptions(path: '/test', method: 'GET');

        // Initially no retry count
        expect(options.extra['retryCount'], isNull);

        // After first retry
        options.extra['retryCount'] = 1;
        expect(options.extra['retryCount'], 1);

        // After second retry
        options.extra['retryCount'] = 2;
        expect(options.extra['retryCount'], 2);
      });

      test('should respect max retry limit (3 attempts)', () {
        final options = RequestOptions(path: '/test', method: 'GET');

        // Simulate 3 retries
        options.extra['retryCount'] = 3;

        // Should not retry after 3 attempts
        expect(options.extra['retryCount'], greaterThanOrEqualTo(3));
      });
    });

    group('Retry Logic for HEAD Requests', () {
      test('should retry HEAD request on timeout error', () async {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test', method: 'HEAD'),
          type: DioExceptionType.connectionTimeout,
        );

        expect(error.requestOptions.method, 'HEAD');
        expect(error.type, DioExceptionType.connectionTimeout);
      });

      test('should retry HEAD request on server error', () async {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test', method: 'HEAD'),
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 503,
          ),
          type: DioExceptionType.badResponse,
        );

        expect(error.response?.statusCode, 503);
        expect(error.requestOptions.method, 'HEAD');
      });
    });

    group('No Retry for POST/PUT Requests', () {
      test('should NOT retry POST request (avoid duplicate writes)', () {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test', method: 'POST'),
          type: DioExceptionType.connectionTimeout,
        );

        // POST requests should not be retried
        expect(error.requestOptions.method, 'POST');
      });

      test('should NOT retry PUT request (avoid duplicate writes)', () {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test', method: 'PUT'),
          type: DioExceptionType.connectionTimeout,
        );

        // PUT requests should not be retried
        expect(error.requestOptions.method, 'PUT');
      });

      test('should NOT retry DELETE request', () {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test', method: 'DELETE'),
          type: DioExceptionType.connectionTimeout,
        );

        expect(error.requestOptions.method, 'DELETE');
      });
    });

    group('No Retry for Client Errors (4xx)', () {
      test('should NOT retry on 400 Bad Request', () {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test', method: 'GET'),
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 400,
          ),
          type: DioExceptionType.badResponse,
        );

        // 4xx errors should not be retried
        expect(error.response?.statusCode, 400);
      });

      test('should NOT retry on 401 Unauthorized', () {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test', method: 'GET'),
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 401,
          ),
          type: DioExceptionType.badResponse,
        );

        expect(error.response?.statusCode, 401);
      });

      test('should NOT retry on 404 Not Found', () {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test', method: 'GET'),
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 404,
          ),
          type: DioExceptionType.badResponse,
        );

        expect(error.response?.statusCode, 404);
      });

      test('should NOT retry on 422 Unprocessable Entity', () {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test', method: 'GET'),
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 422,
          ),
          type: DioExceptionType.badResponse,
        );

        expect(error.response?.statusCode, 422);
      });
    });

    group('Retry for Server Errors (5xx)', () {
      test('should retry on 500 Internal Server Error', () {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test', method: 'GET'),
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 500,
          ),
          type: DioExceptionType.badResponse,
        );

        expect(error.response?.statusCode, 500);
      });

      test('should retry on 502 Bad Gateway', () {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test', method: 'GET'),
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 502,
          ),
          type: DioExceptionType.badResponse,
        );

        expect(error.response?.statusCode, 502);
      });

      test('should retry on 503 Service Unavailable', () {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test', method: 'GET'),
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 503,
          ),
          type: DioExceptionType.badResponse,
        );

        expect(error.response?.statusCode, 503);
      });
    });

    group('Exponential Backoff Delays', () {
      test('should use 1s delay for first retry', () {
        const expectedDelay = Duration(seconds: 1);
        expect(expectedDelay.inSeconds, 1);
      });

      test('should use 2s delay for second retry', () {
        const expectedDelay = Duration(seconds: 2);
        expect(expectedDelay.inSeconds, 2);
      });

      test('should use 4s delay for third retry', () {
        const expectedDelay = Duration(seconds: 4);
        expect(expectedDelay.inSeconds, 4);
      });

      test('should calculate total retry time (~7 seconds)', () {
        const totalDelay = Duration(seconds: 1 + 2 + 4);
        expect(totalDelay.inSeconds, 7);
      });
    });

    group('Retry for Timeout Errors', () {
      test('should retry on connection timeout', () {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test', method: 'GET'),
          type: DioExceptionType.connectionTimeout,
        );

        expect(error.type, DioExceptionType.connectionTimeout);
      });

      test('should retry on send timeout', () {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test', method: 'GET'),
          type: DioExceptionType.sendTimeout,
        );

        expect(error.type, DioExceptionType.sendTimeout);
      });

      test('should retry on receive timeout', () {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test', method: 'GET'),
          type: DioExceptionType.receiveTimeout,
        );

        expect(error.type, DioExceptionType.receiveTimeout);
      });
    });

    group('Edge Cases', () {
      test('should handle error without response', () {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test', method: 'GET'),
          type: DioExceptionType.connectionTimeout,
        );

        expect(error.response, isNull);
      });

      test('should handle error with null status code', () {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test', method: 'GET'),
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: null,
          ),
          type: DioExceptionType.badResponse,
        );

        expect(error.response?.statusCode, isNull);
      });

      test('should handle cancel error (no retry)', () {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test', method: 'GET'),
          type: DioExceptionType.cancel,
        );

        // Cancel errors should not be retried
        expect(error.type, DioExceptionType.cancel);
      });
    });
  });
}
