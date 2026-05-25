import 'package:demon_teach/core/constants/app_constants.dart';
import 'package:demon_teach/data/datasources/local/database/app_database.dart';
import 'package:demon_teach/data/datasources/local/download_local_datasource.dart';
import 'package:demon_teach/data/datasources/local/download_local_datasource_drift.dart';
import 'package:demon_teach/data/datasources/local/sync_local_datasource.dart';
import 'package:demon_teach/data/datasources/local/sync_local_datasource_drift.dart';
import 'package:demon_teach/data/datasources/remote/download_remote_datasource.dart';
import 'package:demon_teach/data/datasources/remote/sync_remote_datasource.dart';
import 'package:demon_teach/data/network/dio_client_factory.dart';
import 'package:demon_teach/data/repositories/download_repository_impl.dart';
import 'package:demon_teach/data/repositories/sync_repository_impl.dart';
import 'package:demon_teach/domain/repositories/download_repository.dart';
import 'package:demon_teach/domain/repositories/sync_repository.dart';
import 'package:demon_teach/domain/services/sync_manager.dart';
import 'package:dio/dio.dart';

/// Simple dependency injection for database and repositories
///
/// This is a lightweight DI approach. Can be replaced with Riverpod later.
class DatabaseProvider {
  static DatabaseProvider? _instance;
  static DatabaseProvider get instance {
    _instance ??= DatabaseProvider._();
    return _instance!;
  }

  DatabaseProvider._();

  // Test mode flag
  bool _testMode = false;

  /// Enable test mode (uses in-memory database)
  void enableTestMode() {
    _testMode = true;
    reset(); // Reset to create new in-memory database
  }

  // Dio clients (created once and reused)
  Dio? _baseClient;
  Dio get baseClient {
    _baseClient ??= DioClientFactory.createBaseClient(
      baseUrl: AppConstants.apiBaseUrl,
    );
    return _baseClient!;
  }

  Dio? _downloadClient;
  Dio get downloadClient {
    _downloadClient ??= DioClientFactory.createDownloadClient(
      baseUrl: AppConstants.apiBaseUrl,
    );
    return _downloadClient!;
  }

  // Singleton database instance
  AppDatabase? _database;
  AppDatabase get database {
    if (_database == null) {
      if (_testMode) {
        // Use in-memory database for tests
        _database = AppDatabase.memory();
      } else {
        // Use file-based database for production
        _database = AppDatabase();
      }
    }
    return _database!;
  }

  // Download data sources
  DownloadLocalDataSource? _downloadLocalDataSource;
  DownloadLocalDataSource get downloadLocalDataSource {
    _downloadLocalDataSource ??= DownloadLocalDataSourceDrift(database);
    return _downloadLocalDataSource!;
  }

  DownloadRemoteDataSource? _downloadRemoteDataSource;
  DownloadRemoteDataSource get downloadRemoteDataSource {
    _downloadRemoteDataSource ??= DownloadRemoteDataSourceImpl(
      dio: baseClient,
      downloadDio: downloadClient,
    );
    return _downloadRemoteDataSource!;
  }

  // Sync data sources
  SyncLocalDataSource? _syncLocalDataSource;
  SyncLocalDataSource get syncLocalDataSource {
    _syncLocalDataSource ??= SyncLocalDataSourceDrift(database);
    return _syncLocalDataSource!;
  }

  SyncRemoteDataSource? _syncRemoteDataSource;
  SyncRemoteDataSource get syncRemoteDataSource {
    _syncRemoteDataSource ??= SyncRemoteDataSourceImpl(
      dio: baseClient,
    );
    return _syncRemoteDataSource!;
  }

  // Repositories
  DownloadRepository? _downloadRepository;
  DownloadRepository get downloadRepository {
    _downloadRepository ??= DownloadRepositoryImpl(
      localDataSource: downloadLocalDataSource,
      remoteDataSource: downloadRemoteDataSource,
    );
    return _downloadRepository!;
  }

  SyncRepository? _syncRepository;
  SyncRepository get syncRepository {
    _syncRepository ??= SyncRepositoryImpl(
      localDataSource: syncLocalDataSource,
      remoteDataSource: syncRemoteDataSource,
    );
    return _syncRepository!;
  }

  SyncManager? _syncManager;
  SyncManager get syncManager {
    _syncManager ??= SyncManager(syncRepository);
    return _syncManager!;
  }

  /// Reset all instances (useful for testing)
  void reset() {
    _database?.close();
    _database = null;
    // Don't close Dio clients - just nullify to allow recreation
    // Closing would prevent reuse in lazy singleton pattern
    _baseClient = null;
    _downloadClient = null;
    _downloadLocalDataSource = null;
    _downloadRemoteDataSource = null;
    _syncLocalDataSource = null;
    _syncRemoteDataSource = null;
    _downloadRepository = null;
    _syncManager?.dispose();
    _syncManager = null;
    _syncRepository = null;
  }

  /// Reset only repositories and datasources, keeping the database
  /// (useful for simulating app restart in tests)
  void resetRepositories() {
    _downloadLocalDataSource = null;
    _downloadRemoteDataSource = null;
    _syncLocalDataSource = null;
    _syncRemoteDataSource = null;
    _downloadRepository = null;
    _syncManager?.dispose();
    _syncManager = null;
    _syncRepository = null;
  }

  /// Inject mock Dio clients for testing
  /// ONLY use this in tests - not for production code
  void injectMockDioClients({
    required Dio baseClient,
    required Dio downloadClient,
  }) {
    if (!_testMode) {
      throw StateError(
        'injectMockDioClients can only be called in test mode. '
        'Call enableTestMode() first.',
      );
    }

    // Reset existing clients and datasources
    _baseClient = baseClient;
    _downloadClient = downloadClient;
    _downloadRemoteDataSource = null;
    _syncRemoteDataSource = null;
    _downloadRepository = null;
    _syncManager?.dispose();
    _syncManager = null;
    _syncRepository = null;
  }
}
