import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:demon_teach/data/network/interceptors/error_mapping_interceptor.dart';
import 'package:demon_teach/core/errors/failures.dart';
import 'dart:io';

void main() {
  group('ErrorMappingInterceptor', () {
    late ErrorMappingInterceptor interceptor;

    setUp(() {
      interceptor = ErrorMappingInterceptor();
    });

    group('Timeout Error Mapping', () {
      test('should map connectionTimeout to NetworkFailure', () {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.connectionTimeout,
        );

        interceptor.onError(error, ErrorInterceptorHandler());

        expect(error.error, isA<NetworkFailure>());
        final failure = error.error as NetworkFailure;
        expect(failure.message, contains('timeout'));
      });

      test('should map sendTimeout to NetworkFailure', () {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.sendTimeout,
        );

        interceptor.onError(error, ErrorInterceptorHandler());

        expect(error.error, isA<NetworkFailure>());
      });

      test('should map receiveTimeout to NetworkFailure', () {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.receiveTimeout,
        );

        interceptor.onError(error, ErrorInterceptorHandler());

        expect(error.error, isA<NetworkFailure>());
      });
    });

    group('Auth Error Mapping (401/403)', () {
      test('should map 401 Unauthorized to AuthFailure', () {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 401,
          ),
          type: DioExceptionType.badResponse,
        );

        interceptor.onError(error, ErrorInterceptorHandler());

        expect(error.error, isA<AuthFailure>());
        final failure = error.error as AuthFailure;
        expect(failure.message, contains('401'));
      });

      test('should map 403 Forbidden to AuthFailure', () {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 403,
          ),
          type: DioExceptionType.badResponse,
        );

        interceptor.onError(error, ErrorInterceptorHandler());

        expect(error.error, isA<AuthFailure>());
      });
    });

    group('Client Error Mapping (400-499)', () {
      test('should map 400 Bad Request to NetworkFailure', () {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 400,
          ),
          type: DioExceptionType.badResponse,
        );

        interceptor.onError(error, ErrorInterceptorHandler());

        expect(error.error, isA<NetworkFailure>());
      });

      test('should map 404 Not Found to NetworkFailure', () {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 404,
          ),
          type: DioExceptionType.badResponse,
        );

        interceptor.onError(error, ErrorInterceptorHandler());

        expect(error.error, isA<NetworkFailure>());
      });
    });

    group('Server Error Mapping (500-599)', () {
      test('should map 500 Internal Server Error to ServerFailure', () {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 500,
          ),
          type: DioExceptionType.badResponse,
        );

        interceptor.onError(error, ErrorInterceptorHandler());

        expect(error.error, isA<ServerFailure>());
      });

      test('should map 502 Bad Gateway to ServerFailure', () {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 502,
          ),
          type: DioExceptionType.badResponse,
        );

        interceptor.onError(error, ErrorInterceptorHandler());

        expect(error.error, isA<ServerFailure>());
      });

      test('should map 503 Service Unavailable to ServerFailure', () {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 503,
          ),
          type: DioExceptionType.badResponse,
        );

        interceptor.onError(error, ErrorInterceptorHandler());

        expect(error.error, isA<ServerFailure>());
      });
    });

    group('Network Connection Error Mapping', () {
      test('should map SocketException to NetworkFailure', () {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test'),
          error: const SocketException('No network connection'),
          type: DioExceptionType.connectionError,
        );

        interceptor.onError(error, ErrorInterceptorHandler());

        expect(error.error, isA<NetworkFailure>());
        final failure = error.error as NetworkFailure;
        expect(failure.message, contains('No network connection available'));
      });

      test('should map cancel to NetworkFailure', () {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.cancel,
        );

        interceptor.onError(error, ErrorInterceptorHandler());

        expect(error.error, isA<NetworkFailure>());
      });
    });

    group('Failure Attachment', () {
      test('should attach Failure to err.error field', () {
        final error = DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 500,
          ),
          type: DioExceptionType.badResponse,
        );

        // Before mapping
        expect(error.error, isNot(isA<Failure>()));

        interceptor.onError(error, ErrorInterceptorHandler());

        // After mapping
        expect(error.error, isA<Failure>());
        expect(error.error, isA<ServerFailure>());
      });
    });
  });
}
