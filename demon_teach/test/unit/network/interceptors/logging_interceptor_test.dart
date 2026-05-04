import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:demon_teach/data/network/interceptors/logging_interceptor.dart';

void main() {
  group('LoggingInterceptor', () {
    late LoggingInterceptor interceptor;

    setUp(() {
      interceptor = LoggingInterceptor();
    });

    group('Request Logging', () {
      test('should process request without errors', () {
        final options = RequestOptions(
          path: '/test',
          method: 'GET',
          headers: {
            'Authorization': 'Bearer secret-token',
            'Content-Type': 'application/json',
          },
        );

        // Should not throw
        expect(
          () => interceptor.onRequest(options, RequestInterceptorHandler()),
          returnsNormally,
        );
      });

      test('should handle request with sensitive headers', () {
        final options = RequestOptions(
          path: '/test',
          method: 'GET',
          headers: {
            'API-Key': 'secret-api-key',
            'Authorization': 'Bearer token',
          },
        );

        expect(
          () => interceptor.onRequest(options, RequestInterceptorHandler()),
          returnsNormally,
        );
      });
    });

    group('Response Logging', () {
      test('should process response without errors', () {
        final response = Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 200,
          data: {'message': 'success'},
        );

        expect(
          () => interceptor.onResponse(response, ResponseInterceptorHandler()),
          returnsNormally,
        );
      });

      test('should handle large response bodies', () {
        final largeData = {'data': 'x' * 2000};
        final response = Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 200,
          data: largeData,
        );

        expect(
          () => interceptor.onResponse(response, ResponseInterceptorHandler()),
          returnsNormally,
        );
      });

      test('should handle null response data', () {
        final response = Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 204,
          data: null,
        );

        expect(
          () => interceptor.onResponse(response, ResponseInterceptorHandler()),
          returnsNormally,
        );
      });
    });

    group('Error Logging', () {
      test('should process error without throwing', () {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.connectionTimeout,
        );

        expect(
          () => interceptor.onError(error, ErrorInterceptorHandler()),
          returnsNormally,
        );
      });

      test('should handle error with response', () {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 500,
            data: {'error': 'Internal server error'},
          ),
          type: DioExceptionType.badResponse,
        );

        expect(
          () => interceptor.onError(error, ErrorInterceptorHandler()),
          returnsNormally,
        );
      });
    });
  });
}
