import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:demon_teach/core/di/database_provider.dart';
import 'package:demon_teach/data/network/dio_client_factory.dart';

/// End-to-End Download Flow Test
///
/// Tests the complete download flow with mocked HTTP:
/// 1. Download lesson
/// 2. Save to database
/// 3. Restart (simulate by resetting provider)
/// 4. Load from database
/// 5. Verify state persisted
void main() {
  // CRITICAL: Initialize Flutter bindings for path_provider (used by Drift)
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseProvider provider;
  late Dio mockDio;
  late DioAdapter dioAdapter;

  setUp(() {
    provider = DatabaseProvider.instance;
    provider.enableTestMode(); // Use in-memory database for tests

    // Create mock Dio client
    mockDio = DioClientFactory.createBaseClient(
      baseUrl: 'https://api.test.com',
    );
    dioAdapter = DioAdapter(dio: mockDio);

    // Inject mock Dio into provider
    provider.injectMockDioClients(
      baseClient: mockDio,
      downloadClient: mockDio,
    );
  });

  tearDown(() {
    provider.reset();
  });

  group('Download Flow End-to-End', () {
    test('Download → Save → Restart → Load → Verify', () async {
      // ========================================
      // STEP 1: Mock API responses
      // ========================================
      print('🔧 Step 1: Setting up HTTP mocks...');

      // Mock lesson content download
      final mockLessonContent = {
        'id': 'lesson-1',
        'title': 'Basic Greetings',
        'flashcards': [
          {'id': 'fc1', 'front': 'Hello', 'back': '你好'}
        ],
        'quiz': {'id': 'q1', 'questions': []},
      };

      dioAdapter.onGet(
        '/api/lessons/lesson-1',
        (server) => server.reply(200, mockLessonContent),
      );

      // Mock lesson availability check (HEAD request)
      dioAdapter.onHead(
        '/api/lessons/lesson-1',
        (server) => server.reply(200, null),
      );

      print('✅ HTTP mocks configured');

      // ========================================
      // STEP 2: Download a lesson
      // ========================================
      print('\n📥 Step 2: Downloading lesson-1...');
      final downloadResult =
          await provider.downloadRepository.downloadLesson('lesson-1');

      print('DEBUG: downloadResult.isSuccess = ${downloadResult.isSuccess}');
      if (downloadResult.isFailure) {
        print('DEBUG: Failure type = ${downloadResult.failure.runtimeType}');
        print('DEBUG: Failure message = ${downloadResult.failure.message}');
      }

      expect(downloadResult.isSuccess, true, reason: 'Download should succeed');
      final downloadStatus = downloadResult.value;
      expect(downloadStatus.contentId, 'lesson-1');
      expect(downloadStatus.isCompleted, true,
          reason: 'Download should be completed');
      print('✅ Download completed: ${downloadStatus.state}');

      // ========================================
      // STEP 3: Verify saved to database
      // ========================================
      print('\n📊 Step 3: Verifying saved to database...');
      final statusResult =
          await provider.downloadRepository.getDownloadStatus('lesson-1');

      expect(statusResult.isSuccess, true);
      expect(statusResult.value, isNotNull, reason: 'Status should be saved');
      expect(statusResult.value!.isCompleted, true);
      print('✅ Status saved to database');

      // ========================================
      // STEP 4: Verify offline content saved
      // ========================================
      print('\n💾 Step 4: Verifying offline content...');
      final contentResult =
          await provider.downloadRepository.getOfflineContent('lesson-1');

      expect(contentResult.isSuccess, true);
      expect(contentResult.value, isNotNull, reason: 'Content should be saved');
      expect(contentResult.value!.contentId, 'lesson-1');
      expect(contentResult.value!.contentType, 'lesson');
      print('✅ Offline content saved: ${contentResult.value!.sizeBytes} bytes');

      // ========================================
      // STEP 5: Simulate app restart
      // ========================================
      print('\n🔄 Step 5: Simulating app restart...');
      provider
          .resetRepositories(); // This simulates app restart - clears in-memory cache but keeps database
      print('✅ App restarted (repositories reset, database persisted)');

      // ========================================
      // STEP 6: Load from database after restart
      // ========================================
      print('\n📂 Step 6: Loading from database after restart...');
      final reloadedStatusResult =
          await provider.downloadRepository.getDownloadStatus('lesson-1');

      expect(reloadedStatusResult.isSuccess, true);
      expect(reloadedStatusResult.value, isNotNull,
          reason: 'Status should persist after restart');
      expect(reloadedStatusResult.value!.contentId, 'lesson-1');
      expect(reloadedStatusResult.value!.isCompleted, true,
          reason: 'State should be preserved');
      print(
          '✅ Status loaded from database: ${reloadedStatusResult.value!.state}');

      // ========================================
      // STEP 7: Verify offline content still available
      // ========================================
      print('\n🔍 Step 7: Verifying offline content after restart...');
      final reloadedContentResult =
          await provider.downloadRepository.getOfflineContent('lesson-1');

      expect(reloadedContentResult.isSuccess, true);
      expect(reloadedContentResult.value, isNotNull,
          reason: 'Content should persist after restart');
      expect(reloadedContentResult.value!.contentId, 'lesson-1');
      print('✅ Offline content still available');

      // ========================================
      // STEP 8: Verify lesson is marked as downloaded
      // ========================================
      print('\n✔️ Step 8: Checking if lesson is downloaded...');
      final isDownloadedResult =
          await provider.downloadRepository.isLessonDownloaded('lesson-1');

      expect(isDownloadedResult.isSuccess, true);
      expect(isDownloadedResult.value, true,
          reason: 'Lesson should be marked as downloaded');
      print('✅ Lesson correctly marked as downloaded');

      print('\n🎉 SUCCESS: Complete download flow verified!');
      print('   - Download works ✅');
      print('   - Database persistence works ✅');
      print('   - Survives app restart ✅');
      print('   - State correctly preserved ✅');
    });

    test('Download multiple lessons', () async {
      print('📥 Downloading multiple lessons...');

      // Mock API responses for multiple lessons
      for (var i = 1; i <= 3; i++) {
        dioAdapter.onGet(
          '/api/lessons/lesson-$i',
          (server) => server.reply(200, {
            'id': 'lesson-$i',
            'title': 'Lesson $i',
            'flashcards': [],
            'quiz': {},
          }),
        );

        dioAdapter.onHead(
          '/api/lessons/lesson-$i',
          (server) => server.reply(200, null),
        );
      }

      final result = await provider.downloadRepository.downloadLessons([
        'lesson-1',
        'lesson-2',
        'lesson-3',
      ]);

      expect(result.isSuccess, true);
      expect(result.value.length, 3);

      // Verify all completed
      for (final status in result.value) {
        expect(status.isCompleted, true,
            reason: '${status.contentId} should be completed');
        print('✅ ${status.contentId}: ${status.state}');
      }

      // Verify all saved to database
      final allContent =
          await provider.downloadRepository.getAllOfflineContent();
      expect(allContent.isSuccess, true);
      expect(allContent.value.length, greaterThanOrEqualTo(3));
      print('✅ All ${allContent.value.length} lessons saved to database');
    });

    test('Get active downloads', () async {
      print('📊 Testing active downloads tracking...');

      // Mock API response
      dioAdapter.onGet(
        '/api/lessons/lesson-active',
        (server) => server.reply(200, {
          'id': 'lesson-active',
          'title': 'Active Lesson',
          'flashcards': [],
          'quiz': {},
        }),
      );

      dioAdapter.onHead(
        '/api/lessons/lesson-active',
        (server) => server.reply(200, null),
      );

      // Start a download (it will complete immediately in mock)
      await provider.downloadRepository.downloadLesson('lesson-active');

      // Get active downloads (should be empty since mock completes immediately)
      final activeResult =
          await provider.downloadRepository.getActiveDownloads();

      expect(activeResult.isSuccess, true);
      print('✅ Active downloads: ${activeResult.value.length}');
    });

    test('Delete offline content', () async {
      print('🗑️ Testing content deletion...');

      // Mock API response
      dioAdapter.onGet(
        '/api/lessons/lesson-delete',
        (server) => server.reply(200, {
          'id': 'lesson-delete',
          'title': 'Delete Me',
          'flashcards': [],
          'quiz': {},
        }),
      );

      dioAdapter.onHead(
        '/api/lessons/lesson-delete',
        (server) => server.reply(200, null),
      );

      // Download first
      await provider.downloadRepository.downloadLesson('lesson-delete');

      // Verify exists
      var contentResult =
          await provider.downloadRepository.getOfflineContent('lesson-delete');
      expect(contentResult.value, isNotNull);
      print('✅ Content exists before deletion');

      // Delete
      final deleteResult = await provider.downloadRepository
          .deleteOfflineContent('lesson-delete');
      expect(deleteResult.isSuccess, true);
      print('✅ Content deleted');

      // Verify deleted
      contentResult =
          await provider.downloadRepository.getOfflineContent('lesson-delete');
      expect(contentResult.value, isNull, reason: 'Content should be deleted');
      print('✅ Content no longer exists');
    });

    test('Storage space tracking', () async {
      print('💾 Testing storage space tracking...');

      // Mock API responses
      for (var i = 1; i <= 2; i++) {
        dioAdapter.onGet(
          '/api/lessons/lesson-$i',
          (server) => server.reply(200, {
            'id': 'lesson-$i',
            'title': 'Lesson $i',
            'flashcards': [],
            'quiz': {},
          }),
        );

        dioAdapter.onHead(
          '/api/lessons/lesson-$i',
          (server) => server.reply(200, null),
        );
      }

      // Download some lessons
      await provider.downloadRepository
          .downloadLessons(['lesson-1', 'lesson-2']);

      // Get used space
      final spaceResult =
          await provider.downloadRepository.getUsedStorageSpace();

      expect(spaceResult.isSuccess, true);
      expect(spaceResult.value, greaterThan(0),
          reason: 'Should have used some space');
      print('✅ Used storage: ${spaceResult.value} bytes');
    });

    test('Offline availability', () async {
      print('📊 Testing offline availability...');

      // Mock API responses
      for (var i = 1; i <= 2; i++) {
        dioAdapter.onGet(
          '/api/lessons/lesson-$i',
          (server) => server.reply(200, {
            'id': 'lesson-$i',
            'title': 'Lesson $i',
            'flashcards': [],
            'quiz': {},
          }),
        );

        dioAdapter.onHead(
          '/api/lessons/lesson-$i',
          (server) => server.reply(200, null),
        );
      }

      // Download some lessons
      await provider.downloadRepository
          .downloadLessons(['lesson-1', 'lesson-2']);

      // Get availability
      final availResult =
          await provider.downloadRepository.getOfflineAvailability(
        'user-1',
        'english',
      );

      expect(availResult.isSuccess, true);
      expect(availResult.value.isAvailable, true);
      expect(availResult.value.downloadedLessons, greaterThanOrEqualTo(2));
      print('✅ Offline availability:');
      print('   - Available: ${availResult.value.isAvailable}');
      print(
          '   - Downloaded: ${availResult.value.downloadedLessons}/${availResult.value.totalLessons}');
      print('   - Storage: ${availResult.value.usedSizeBytes} bytes');
    });
  });
}
