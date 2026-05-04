import 'package:flutter_test/flutter_test.dart';
import 'package:demon_teach/core/di/database_provider.dart';
import 'package:demon_teach/domain/entities/download_status.dart' as entity;

/// Debug test to identify the root cause of test failures
void main() {
  // Initialize Flutter bindings for path_provider
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    DatabaseProvider.instance.enableTestMode();
    DatabaseProvider.instance.reset();
  });

  tearDown(() {
    DatabaseProvider.instance.reset();
  });

  test('Debug: Check database provider initialization', () async {
    print('🔍 Step 1: Getting DatabaseProvider instance...');
    final provider = DatabaseProvider.instance;
    print('✅ Provider created');

    print('\n🔍 Step 2: Getting database...');
    final database = provider.database;
    print('✅ Database instance: ${database.runtimeType}');

    print('\n🔍 Step 3: Getting download repository...');
    final downloadRepo = provider.downloadRepository;
    print('✅ Download repository: ${downloadRepo.runtimeType}');

    print('\n🔍 Step 4: Attempting to download lesson...');
    final result = await downloadRepo.downloadLesson('test-lesson');

    print('\n📊 Result:');
    print('  - isSuccess: ${result.isSuccess}');
    print('  - isFailure: ${result.isFailure}');

    if (result.isFailure) {
      print('  - Failure type: ${result.failure.runtimeType}');
      print('  - Failure message: ${result.failure.message}');
    } else {
      print('  - Success value: ${result.value}');
    }

    // Don't assert yet, just observe
  });

  test('Debug: Check remote datasource directly', () async {
    print('🔍 Testing remote datasource directly...');
    final provider = DatabaseProvider.instance;
    final remoteDataSource = provider.downloadRemoteDataSource;

    print('\n📥 Downloading lesson content...');
    final contentResult =
        await remoteDataSource.downloadLessonContent('test-lesson');

    print('  - isSuccess: ${contentResult.isSuccess}');
    print('  - isFailure: ${contentResult.isFailure}');

    if (contentResult.isFailure) {
      print('  - Failure: ${contentResult.failure.message}');
    } else {
      print('  - Content keys: ${contentResult.value.keys}');
    }
  });

  test('Debug: Check local datasource directly', () async {
    print('🔍 Testing local datasource directly...');
    final provider = DatabaseProvider.instance;
    provider.reset(); // Clean slate

    final localDataSource = provider.downloadLocalDataSource;

    print('\n💾 Saving download status...');
    final status = await localDataSource.saveDownloadStatus(
      entity.DownloadStatus(
        contentId: 'test-lesson',
        state: entity.DownloadState.completed,
        progress: 1.0,
        startedAt: DateTime.now(),
        completedAt: DateTime.now(),
      ),
    );

    print('  - Save isSuccess: ${status.isSuccess}');
    if (status.isFailure) {
      print('  - Save failure: ${status.failure.message}');
    }

    print('\n📖 Reading download status...');
    final getResult = await localDataSource.getDownloadStatus('test-lesson');

    print('  - Get isSuccess: ${getResult.isSuccess}');
    if (getResult.isFailure) {
      print('  - Get failure: ${getResult.failure.message}');
    } else {
      print('  - Status: ${getResult.value}');
    }
  });
}
