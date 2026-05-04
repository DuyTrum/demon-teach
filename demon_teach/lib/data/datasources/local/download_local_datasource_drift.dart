import 'package:demon_teach/core/errors/failures.dart';
import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/download_status.dart' as entity;
import 'package:demon_teach/domain/entities/offline_content.dart' as entity;
import 'package:demon_teach/data/datasources/local/download_local_datasource.dart';
import 'package:demon_teach/data/datasources/local/database/app_database.dart';
import 'package:drift/drift.dart';
import 'dart:convert';

/// Download Local Data Source Implementation using Drift
///
/// Provides persistent storage for download data using SQLite via Drift.
class DownloadLocalDataSourceDrift implements DownloadLocalDataSource {
  final AppDatabase _database;

  DownloadLocalDataSourceDrift(this._database);

  @override
  Future<Result<void>> saveDownloadStatus(entity.DownloadStatus status) async {
    try {
      await _database.insertDownloadStatus(
        DownloadStatusesCompanion.insert(
          contentId: status.contentId,
          state: status.state.name,
          progress: Value(status.progress),
          startedAt: Value(status.startedAt),
          completedAt: Value(status.completedAt),
          error: Value(status.error),
          totalBytes: Value(status.totalBytes),
          downloadedBytes: Value(status.downloadedBytes),
        ),
      );
      return Result.success(null);
    } catch (e) {
      return Result.failure(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<entity.DownloadStatus?>> getDownloadStatus(
    String lessonId,
  ) async {
    try {
      final status = await _database.getDownloadStatus(lessonId);
      if (status == null) {
        return Result.success(null);
      }
      return Result.success(_mapToEntityDownloadStatus(status));
    } catch (e) {
      return Result.failure(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<entity.DownloadStatus>>> getActiveDownloads() async {
    try {
      final statuses = await _database.getActiveDownloads();
      final entities = <entity.DownloadStatus>[];
      for (final status in statuses) {
        entities.add(_mapToEntityDownloadStatus(status));
      }
      return Result.success(entities);
    } catch (e) {
      return Result.failure(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteDownloadStatus(String lessonId) async {
    try {
      await _database.deleteDownloadStatus(lessonId);
      return Result.success(null);
    } catch (e) {
      return Result.failure(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> saveOfflineContent(entity.OfflineContent content) async {
    try {
      await _database.insertOfflineContent(
        OfflineContentsCompanion.insert(
          contentId: content.contentId,
          contentType: content.contentType,
          localPath: content.localPath,
          sizeBytes: content.sizeBytes,
          downloadedAt: content.downloadedAt,
          expiresAt: Value(content.expiresAt),
          metadata: jsonEncode(content.metadata),
          lastAccessedAt: Value(DateTime.now()),
        ),
      );
      return Result.success(null);
    } catch (e) {
      return Result.failure(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<entity.OfflineContent?>> getOfflineContent(
    String contentId,
  ) async {
    try {
      final content = await _database.getOfflineContent(contentId);
      if (content == null) {
        return Result.success(null);
      }

      // Update last accessed time
      await _database.updateOfflineContent(
        content.copyWith(lastAccessedAt: Value(DateTime.now())),
      );

      return Result.success(_mapToEntityOfflineContent(content));
    } catch (e) {
      return Result.failure(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<entity.OfflineContent>>> getAllOfflineContent() async {
    try {
      final contents = await _database.getAllOfflineContents();
      final entities = contents.map(_mapToEntityOfflineContent).toList();
      return Result.success(entities);
    } catch (e) {
      return Result.failure(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteOfflineContent(String contentId) async {
    try {
      await _database.deleteOfflineContent(contentId);
      return Result.success(null);
    } catch (e) {
      return Result.failure(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<entity.OfflineContent>>> getOfflineContentByType(
    String type,
  ) async {
    try {
      final contents = await _database.getOfflineContentsByType(type);
      final entities = contents.map(_mapToEntityOfflineContent).toList();
      return Result.success(entities);
    } catch (e) {
      return Result.failure(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> updateOfflineContentMetadata(
    String contentId,
    Map<String, dynamic> metadata,
  ) async {
    try {
      final content = await _database.getOfflineContent(contentId);
      if (content == null) {
        return Result.failure(
          DatabaseFailure(message: 'Content not found: $contentId'),
        );
      }

      // Merge metadata
      final existingMetadata =
          jsonDecode(content.metadata) as Map<String, dynamic>;
      final mergedMetadata = {...existingMetadata, ...metadata};

      await _database.updateOfflineContent(
        content.copyWith(metadata: jsonEncode(mergedMetadata)),
      );

      return Result.success(null);
    } catch (e) {
      return Result.failure(DatabaseFailure(message: e.toString()));
    }
  }

  /// Map Drift DownloadStatus to Entity DownloadStatus
  entity.DownloadStatus _mapToEntityDownloadStatus(DownloadStatus status) {
    return entity.DownloadStatus(
      contentId: status.contentId,
      state: entity.DownloadState.values.firstWhere(
        (e) => e.name == status.state,
        orElse: () => entity.DownloadState.pending,
      ),
      progress: status.progress,
      startedAt: status.startedAt,
      completedAt: status.completedAt,
      error: status.error,
      totalBytes: status.totalBytes ?? 0,
      downloadedBytes: status.downloadedBytes ?? 0,
    );
  }

  /// Map Drift OfflineContent to Entity OfflineContent
  entity.OfflineContent _mapToEntityOfflineContent(OfflineContent content) {
    return entity.OfflineContent(
      contentId: content.contentId,
      contentType: content.contentType,
      localPath: content.localPath,
      sizeBytes: content.sizeBytes,
      downloadedAt: content.downloadedAt,
      expiresAt: content.expiresAt,
      metadata: jsonDecode(content.metadata) as Map<String, dynamic>,
    );
  }
}
