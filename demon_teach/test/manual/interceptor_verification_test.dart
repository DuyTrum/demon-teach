/// Manual verification test for Dio interceptors
///
/// This is a quick checkpoint to verify:
/// 1. LoggingInterceptor - logs requests/responses, masks sensitive headers
/// 2. RetryInterceptor - retries GET/HEAD with exponential backoff
/// 3. ErrorMappingInterceptor - maps DioException to domain Failures
///
/// Run this test and check console output manually.
/// Expected runtime: 5-10 minutes
///
/// Usage: flutter test test/manual/interceptor_verification_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:demon_teach/data/network/dio_client_factory.dart';
import 'package:demon_teach/core/errors/failures.dart';

void main() {
  group('Interceptor Manual Verification', () {
    late Dio dio;
    late DioAdapter dioAdapter;

    setUp(() {
      dio = DioClientFactory.createBaseClient(
        baseUrl: 'https://api.test.com',
      );
      dioAdapter = DioAdapter(dio: dio);
    });

    test('1. LoggingInterceptor - Verify logs in console', () async {
      print('\n=== TEST 1: LoggingInterceptor ===');
      print('Expected: See [HTTP] logs with method, URL, headers, body');
      print('Expected: Authorization header should be masked as ***\n');

      // Mock successful response
      dioAdapter.onGet(
        '/test',
        (server) => server.reply(200, {'message': 'success'}),
      );

      // Make request with sensitive header
      try {
        await dio.get(
          '/test',
          options: Options(headers: {'Authorization': 'Bearer secret-token'}),
        );
        print('✅ Request completed - check logs above\n');
      } catch (e) {
        print('❌ Request failed: $e\n');
      }
    });

    test('2. LoggingInterceptor - Verify body truncation', () async {
      print('\n=== TEST 2: Body Truncation ===');
      print(
          'Expected: Large body should be truncated with "... (truncated)"\n');

      // Create large response (> 1KB)
      final largeBody = {'data': 'x' * 2000};
      dioAdapter.onGet(
        '/large',
        (server) => server.reply(200, largeBody),
      );

      try {
        await dio.get('/large');
        print('✅ Large response received - check if body was truncated\n');
      } catch (e) {
        print('❌ Request failed: $e\n');
      }
    });

    test('3. RetryInterceptor - Verify 3 retries with exponential backoff',
        () async {
      print('\n=== TEST 3: Retry Logic ===');
      print('Expected: 3 retry attempts with delays ~1s, 2s, 4s');
      print('Expected: Total time ~7 seconds\n');

      int attemptCount = 0;
      dioAdapter.onGet(
        '/retry-test',
        (server) {
          attemptCount++;
          print('Attempt $attemptCount at ${DateTime.now().second}s');
          return server.throws(
            500,
            DioException(
              requestOptions: RequestOptions(path: '/retry-test'),
              type: DioExceptionType.connectionTimeout,
            ),
          );
        },
      );

      final startTime = DateTime.now();
      try {
        await dio.get('/retry-test');
      } catch (e) {
        final duration = DateTime.now().difference(startTime);
        print('\n✅ Failed after $attemptCount attempts');
        print('✅ Total duration: ${duration.inSeconds}s (expected ~7s)');
        print('✅ Check if delays were exponential: 1s → 2s → 4s\n');
      }
    });

    test('4. RetryInterceptor - Verify NO retry for 404', () async {
      print('\n=== TEST 4: No Retry for 4xx ===');
      print('Expected: Only 1 attempt, no retries\n');

      int attemptCount = 0;
      dioAdapter.onGet(
        '/not-found',
        (server) {
          attemptCount++;
          print('Attempt $attemptCount');
          return server.reply(404, {'error': 'Not found'});
        },
      );

      try {
        await dio.get('/not-found');
      } catch (e) {
        print('✅ Failed after $attemptCount attempt(s) (expected 1)');
        expect(attemptCount, equals(1), reason: '404 should NOT be retried');
        print('✅ Confirmed: 4xx errors are not retried\n');
      }
    });

    test('5. ErrorMappingInterceptor - Verify 401 → AuthFailure', () async {
      print('\n=== TEST 5: Error Mapping - 401 ===');
      print('Expected: DioException.error should be AuthFailure\n');

      dioAdapter.onGet(
        '/unauthorized',
        (server) => server.reply(401, {'error': 'Unauthorized'}),
      );

      try {
        await dio.get('/unauthorized');
      } catch (e) {
        if (e is DioException) {
          print('Error type: ${e.error.runtimeType}');
          expect(e.error, isA<AuthFailure>(),
              reason: '401 should map to AuthFailure');
          print('✅ Confirmed: 401 → AuthFailure\n');
        }
      }
    });

    test('6. ErrorMappingInterceptor - Verify 500 → ServerFailure', () async {
      print('\n=== TEST 6: Error Mapping - 500 ===');
      print('Expected: DioException.error should be ServerFailure\n');

      dioAdapter.onGet(
        '/server-error',
        (server) => server.reply(500, {'error': 'Internal server error'}),
      );

      try {
        await dio.get('/server-error');
      } catch (e) {
        if (e is DioException) {
          print('Error type: ${e.error.runtimeType}');
          expect(e.error, isA<ServerFailure>(),
              reason: '500 should map to ServerFailure');
          print('✅ Confirmed: 500 → ServerFailure\n');
        }
      }
    });

    test('7. ErrorMappingInterceptor - Verify timeout → NetworkFailure',
        () async {
      print('\n=== TEST 7: Error Mapping - Timeout ===');
      print('Expected: DioException.error should be NetworkFailure\n');

      dioAdapter.onGet(
        '/timeout',
        (server) => server.throws(
          408,
          DioException(
            requestOptions: RequestOptions(path: '/timeout'),
            type: DioExceptionType.connectionTimeout,
          ),
        ),
      );

      try {
        await dio.get('/timeout');
      } catch (e) {
        if (e is DioException) {
          print('Error type: ${e.error.runtimeType}');
          expect(e.error, isA<NetworkFailure>(),
              reason: 'Timeout should map to NetworkFailure');
          print('✅ Confirmed: Timeout → NetworkFailure\n');
        }
      }
    });

    test('8. DioClientFactory - Verify separate download client', () async {
      print('\n=== TEST 8: Download Client ===');
      print('Expected: Download client has 120s receive timeout\n');

      final downloadDio = DioClientFactory.createDownloadClient(
        baseUrl: 'https://api.test.com',
      );

      print('Base client receive timeout: ${dio.options.receiveTimeout}');
      print(
          'Download client receive timeout: ${downloadDio.options.receiveTimeout}');

      expect(dio.options.receiveTimeout, equals(const Duration(seconds: 30)),
          reason: 'Base client should have 30s timeout');
      expect(downloadDio.options.receiveTimeout,
          equals(const Duration(seconds: 120)),
          reason: 'Download client should have 120s timeout');

      print('✅ Confirmed: Download client has extended timeout\n');
    });
  });

  group('Manual Verification Summary', () {
    test('Print summary and next steps', () {
      print('\n' + '=' * 60);
      print('CHECKPOINT SUMMARY');
      print('=' * 60);
      print('\n✅ If all tests passed, you should have seen:');
      print('  1. [HTTP] logs with method, URL, masked headers');
      print('  2. Large bodies truncated with "... (truncated)"');
      print('  3. 3 retry attempts with ~7s total duration');
      print('  4. No retry for 404 (only 1 attempt)');
      print('  5. 401 → AuthFailure');
      print('  6. 500 → ServerFailure');
      print('  7. Timeout → NetworkFailure');
      print('  8. Download client has 120s timeout');
      print('\n🚀 NEXT STEPS:');
      print('  → Task 4: Implement DownloadRemoteDataSourceImpl');
      print('  → Task 5: Implement SyncRemoteDataSourceImpl');
      print('  → Task 7: Wire into DatabaseProvider');
      print('\n⚠️  IMPORTANT NOTES FOR TASK 4:');
      print('  - Use ResponseType.bytes for file downloads');
      print('  - Check statusCode and content-length');
      print('  - Handle cancel + progress callbacks');
      print('  - Retry on large downloads may waste bandwidth (OK for MVP)');
      print('\n' + '=' * 60 + '\n');
    });
  });
}
