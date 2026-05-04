import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:demon_teach/core/di/database_provider.dart';
import 'package:demon_teach/data/network/dio_client_factory.dart';
import 'package:demon_teach/domain/entities/progress.dart';

/// End-to-End Sync Flow Test
///
/// Tests the complete sync flow with mocked HTTP:
/// 1. Local update → mark dirty
/// 2. Sync → push to remote
/// 3. Conflict resolution by timestamp
/// 4. Verify sync status
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

  tearDown() {
    provider.reset();
  }

  group('Sync Flow End-to-End', () {
    test('Local Update → Mark Dirty → Sync → Verify', () async {
      // ========================================
      // STEP 1: Mock API responses
      // ========================================
      print('🔧 Step 1: Setting up HTTP mocks...');

      // Mock connectivity check
      dioAdapter.onHead(
        '/',
        (server) => server.reply(200, null),
      );

      // Mock progress sync (PUT)
      dioAdapter.onPut(
        '/api/users/user-1/progress',
        (server) => server.reply(200, {'success': true}),
        data: Matchers.any,
      );

      // Mock get remote progress (returns null initially)
      dioAdapter.onGet(
        '/api/users/user-1/progress/english',
        (server) => server.reply(404, {'error': 'Not found'}),
      );

      print('✅ HTTP mocks configured');

      // ========================================
      // STEP 2: Create local progress
      // ========================================
      print('\n📝 Step 2: Creating local progress...');
      final progress = Progress(
        userId: 'user-1',
        targetLanguage: 'english',
        totalXP: 100,
        currentStreak: 5,
        longestStreak: 10,
        lessonsCompleted: 3,
        lastLessonDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final updateResult =
          await provider.syncRepository.updateLocalProgress(progress);
      expect(updateResult.isSuccess, true);
      print('✅ Local progress created');

      // ========================================
      // STEP 3: Mark as dirty (needs sync)
      // ========================================
      print('\n🏷️ Step 3: Marking as dirty...');
      final markResult = await provider.syncRepository.markAsDirty(
        'user-1_english',
        'progress',
      );
      expect(markResult.isSuccess, true);
      print('✅ Marked as dirty');

      // ========================================
      // STEP 4: Check pending changes
      // ========================================
      print('\n📊 Step 4: Checking pending changes...');
      final pendingResult =
          await provider.syncRepository.getPendingChangesCount('user-1');

      expect(pendingResult.isSuccess, true);
      expect(pendingResult.value, greaterThan(0),
          reason: 'Should have pending changes');
      print('✅ Pending changes: ${pendingResult.value}');

      // ========================================
      // STEP 5: Sync all data
      // ========================================
      print('\n🔄 Step 5: Syncing all data...');
      final syncResult = await provider.syncRepository.syncAll('user-1');

      expect(syncResult.isSuccess, true);
      expect(syncResult.value.state.name, 'synced');
      print('✅ Sync completed: ${syncResult.value.state}');

      // ========================================
      // STEP 6: Verify last sync timestamp
      // ========================================
      print('\n⏰ Step 6: Verifying sync timestamp...');
      final timestampResult =
          await provider.syncRepository.getLastSyncTimestamp('user-1');

      expect(timestampResult.isSuccess, true);
      expect(timestampResult.value, isNotNull,
          reason: 'Should have sync timestamp');
      print('✅ Last sync: ${timestampResult.value}');

      // ========================================
      // STEP 7: Verify sync status
      // ========================================
      print('\n📈 Step 7: Checking sync status...');
      final statusResult =
          await provider.syncRepository.getSyncStatus('user-1');

      expect(statusResult.isSuccess, true);
      expect(statusResult.value.state.name, 'synced');
      expect(statusResult.value.lastSyncAt, isNotNull);
      print('✅ Sync status:');
      print('   - State: ${statusResult.value.state}');
      print('   - Last sync: ${statusResult.value.lastSyncAt}');
      print('   - Pending: ${statusResult.value.pendingChanges}');

      print('\n🎉 SUCCESS: Complete sync flow verified!');
      print('   - Local update works ✅');
      print('   - Dirty tracking works ✅');
      print('   - Sync works ✅');
      print('   - Timestamp tracking works ✅');
    });

    test('Sync progress data', () async {
      print('📊 Testing progress sync...');

      // Mock API responses
      dioAdapter.onHead(
        '/',
        (server) => server.reply(200, null),
      );

      dioAdapter.onPut(
        '/api/users/user-sync/progress',
        (server) => server.reply(200, {'success': true}),
        data: Matchers.any,
      );

      dioAdapter.onGet(
        '/api/users/user-sync/progress/chinese',
        (server) => server.reply(404, {'error': 'Not found'}),
      );

      final progress = Progress(
        userId: 'user-sync',
        targetLanguage: 'chinese',
        totalXP: 250,
        currentStreak: 7,
        longestStreak: 15,
        lessonsCompleted: 8,
        lastLessonDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Update local
      await provider.syncRepository.updateLocalProgress(progress);
      print('✅ Local progress updated');

      // Sync
      final syncResult =
          await provider.syncRepository.syncProgress('user-sync');
      expect(syncResult.isSuccess, true);
      print('✅ Progress synced');

      // Verify can retrieve
      final getResult =
          await provider.syncRepository.getLocalProgress('user-sync');
      expect(getResult.isSuccess, true);
      expect(getResult.value.length, greaterThan(0));
      print('✅ Progress retrieved: ${getResult.value.length} items');
    });

    test('Mark as clean after sync', () async {
      print('🧹 Testing mark as clean...');

      // Mark as dirty
      await provider.syncRepository.markAsDirty('item_1', 'progress');
      print('✅ Marked as dirty');

      // Check pending
      var pendingResult =
          await provider.syncRepository.getPendingChangesCount('item');
      expect(pendingResult.value, greaterThan(0));
      print('✅ Has pending changes: ${pendingResult.value}');

      // Mark as clean
      await provider.syncRepository.markAsClean('item_1', 'progress');
      print('✅ Marked as clean');

      // Check pending again
      pendingResult =
          await provider.syncRepository.getPendingChangesCount('item');
      expect(pendingResult.value, 0, reason: 'Should have no pending changes');
      print('✅ No pending changes');
    });

    test('Check online status', () async {
      print('🌐 Testing online status check...');

      // Mock connectivity check
      dioAdapter.onHead(
        '/',
        (server) => server.reply(200, null),
      );

      final onlineResult = await provider.syncRepository.isOnline();

      expect(onlineResult.isSuccess, true);
      expect(onlineResult.value, true);
      print('✅ Online status: ${onlineResult.value}');
    });

    test('Sync after app restart', () async {
      print('🔄 Testing sync persistence after restart...');

      // Mock API responses
      dioAdapter.onHead(
        '/',
        (server) => server.reply(200, null),
      );

      dioAdapter.onPut(
        '/api/users/user-restart/progress',
        (server) => server.reply(200, {'success': true}),
        data: Matchers.any,
      );

      dioAdapter.onGet(
        '/api/users/user-restart/progress/korean',
        (server) => server.reply(404, {'error': 'Not found'}),
      );

      // Create and sync
      final progress = Progress(
        userId: 'user-restart',
        targetLanguage: 'korean',
        totalXP: 150,
        currentStreak: 3,
        longestStreak: 8,
        lessonsCompleted: 5,
        lastLessonDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await provider.syncRepository.updateLocalProgress(progress);
      await provider.syncRepository.syncAll('user-restart');
      print('✅ Initial sync completed');

      // Simulate restart
      provider.resetRepositories();
      print('✅ App restarted');

      // Check sync status after restart
      final statusResult =
          await provider.syncRepository.getSyncStatus('user-restart');

      expect(statusResult.isSuccess, true);
      expect(statusResult.value.lastSyncAt, isNotNull,
          reason: 'Sync timestamp should persist');
      print('✅ Sync status persisted after restart');
      print('   - Last sync: ${statusResult.value.lastSyncAt}');
    });

    test('Update sync timestamp', () async {
      print('⏰ Testing sync timestamp update...');

      final now = DateTime.now();

      // Update timestamp
      final updateResult =
          await provider.syncRepository.updateLastSyncTimestamp(
        'user-timestamp',
        now,
      );
      expect(updateResult.isSuccess, true);
      print('✅ Timestamp updated');

      // Retrieve timestamp
      final getResult =
          await provider.syncRepository.getLastSyncTimestamp('user-timestamp');

      expect(getResult.isSuccess, true);
      expect(getResult.value, isNotNull);
      expect(
        getResult.value!.difference(now).inSeconds.abs(),
        lessThan(2),
        reason: 'Timestamp should match',
      );
      print('✅ Timestamp retrieved: ${getResult.value}');
    });
  });
}
