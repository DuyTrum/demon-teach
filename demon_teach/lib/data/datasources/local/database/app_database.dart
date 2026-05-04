import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

/// Download Status Table
///
/// Tracks download progress and state for lessons
@DataClassName('DownloadStatus')
class DownloadStatuses extends Table {
  TextColumn get contentId => text()();
  TextColumn get state =>
      text()(); // pending, downloading, paused, completed, failed, cancelled
  RealColumn get progress => real().withDefault(const Constant(0.0))();
  DateTimeColumn get startedAt => dateTime().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get error => text().nullable()();
  IntColumn get totalBytes => integer().nullable()();
  IntColumn get downloadedBytes => integer().nullable()();

  @override
  Set<Column> get primaryKey => {contentId};
}

/// Offline Content Table
///
/// Stores metadata for downloaded content available offline
class OfflineContents extends Table {
  TextColumn get contentId => text()();
  TextColumn get contentType => text()(); // lesson, audio, image
  TextColumn get localPath => text()();
  IntColumn get sizeBytes => integer()();
  DateTimeColumn get downloadedAt => dateTime()();
  DateTimeColumn get expiresAt => dateTime().nullable()();
  TextColumn get metadata => text()(); // JSON string for additional data
  DateTimeColumn get lastAccessedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {contentId};
}

/// Sync Metadata Table
///
/// Tracks synchronization state and timestamps
@DataClassName('SyncMetadata')
class SyncMetadataTable extends Table {
  TextColumn get userId => text()();
  TextColumn get dataType =>
      text()(); // progress, performance, reviews, content
  DateTimeColumn get lastSyncAt => dateTime().nullable()();
  DateTimeColumn get nextSyncAt => dateTime().nullable()();
  IntColumn get pendingChanges => integer().withDefault(const Constant(0))();
  TextColumn get syncState => text()(); // idle, syncing, synced, error
  TextColumn get error => text().nullable()();

  @override
  Set<Column> get primaryKey => {userId, dataType};
}

/// Dirty Items Table
///
/// Tracks items that need to be synced to remote
class DirtyItems extends Table {
  TextColumn get itemId => text()();
  TextColumn get itemType => text()(); // progress, performance, review
  TextColumn get userId => text()();
  DateTimeColumn get markedDirtyAt => dateTime()();
  TextColumn get operation => text()(); // create, update, delete

  @override
  Set<Column> get primaryKey => {itemId, itemType};
}

/// Progress Table
///
/// Stores user progress data locally
@DataClassName('ProgressData')
class ProgressTable extends Table {
  TextColumn get userId => text()();
  TextColumn get targetLanguage => text()();
  IntColumn get totalXP => integer().withDefault(const Constant(0))();
  IntColumn get currentStreak => integer().withDefault(const Constant(0))();
  IntColumn get longestStreak => integer().withDefault(const Constant(0))();
  IntColumn get lessonsCompleted => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastLessonDate => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isDirty => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {userId, targetLanguage};
}

/// Performance Data Table
///
/// Stores performance metrics for adaptive learning
@DataClassName('PerformanceData')
class PerformanceDataTable extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get targetLanguage => text()();
  TextColumn get lessonId => text()();
  DateTimeColumn get completedAt => dateTime()();
  IntColumn get accuracy => integer()(); // 0-100
  IntColumn get timeSpentSeconds => integer()();
  TextColumn get difficulty => text()(); // easy, medium, hard
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isDirty => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Review Items Table
///
/// Stores spaced repetition review items
@DataClassName('ReviewItem')
class ReviewItems extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get targetLanguage => text()();
  TextColumn get contentId => text()();
  TextColumn get contentType => text()(); // flashcard, quiz_question
  IntColumn get repetitions => integer().withDefault(const Constant(0))();
  RealColumn get easeFactor => real().withDefault(const Constant(2.5))();
  IntColumn get intervalDays => integer().withDefault(const Constant(1))();
  DateTimeColumn get nextReviewDate => dateTime()();
  DateTimeColumn get lastReviewedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isDirty => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Content Metadata Table
///
/// Stores metadata about available content from server
@DataClassName('ContentMetadata')
class ContentMetadataTable extends Table {
  TextColumn get contentId => text()();
  TextColumn get contentType => text()();
  TextColumn get title => text()();
  TextColumn get version => text()();
  IntColumn get sizeBytes => integer()();
  DateTimeColumn get publishedAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get targetLanguage => text()();
  TextColumn get difficulty => text()();
  BoolColumn get isAvailable => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {contentId};
}

/// App Database
///
/// Main database class for the application
@DriftDatabase(tables: [
  DownloadStatuses,
  OfflineContents,
  SyncMetadataTable,
  DirtyItems,
  ProgressTable,
  PerformanceDataTable,
  ReviewItems,
  ContentMetadataTable,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Constructor for in-memory database (used in tests)
  AppDatabase.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Handle migrations here when schema version changes
      },
    );
  }

  // Download Status Queries
  Future<List<DownloadStatus>> getAllDownloadStatuses() =>
      select(downloadStatuses).get();

  Future<DownloadStatus?> getDownloadStatus(String contentId) =>
      (select(downloadStatuses)
            ..where((tbl) => tbl.contentId.equals(contentId)))
          .getSingleOrNull();

  Future<List<DownloadStatus>> getActiveDownloads() => (select(downloadStatuses)
        ..where((tbl) => tbl.state.isIn([
              'pending',
              'downloading',
              'paused',
            ])))
      .get();

  Future<int> insertDownloadStatus(DownloadStatusesCompanion status) =>
      into(downloadStatuses).insert(
        status,
        mode: InsertMode.insertOrReplace,
      );

  Future<bool> updateDownloadStatus(DownloadStatus status) =>
      update(downloadStatuses).replace(status);

  Future<int> deleteDownloadStatus(String contentId) =>
      (delete(downloadStatuses)
            ..where((tbl) => tbl.contentId.equals(contentId)))
          .go();

  // Offline Content Queries
  Future<List<OfflineContent>> getAllOfflineContents() =>
      select(offlineContents).get();

  Future<OfflineContent?> getOfflineContent(String contentId) =>
      (select(offlineContents)..where((tbl) => tbl.contentId.equals(contentId)))
          .getSingleOrNull();

  Future<List<OfflineContent>> getOfflineContentsByType(String type) =>
      (select(offlineContents)..where((tbl) => tbl.contentType.equals(type)))
          .get();

  Future<int> insertOfflineContent(OfflineContentsCompanion content) =>
      into(offlineContents).insert(
        content,
        mode: InsertMode.insertOrReplace,
      );

  Future<bool> updateOfflineContent(OfflineContent content) =>
      update(offlineContents).replace(content);

  Future<int> deleteOfflineContent(String contentId) =>
      (delete(offlineContents)..where((tbl) => tbl.contentId.equals(contentId)))
          .go();

  Future<int> deleteExpiredContent(DateTime now) => (delete(offlineContents)
        ..where((tbl) => tbl.expiresAt.isSmallerThanValue(now)))
      .go();

  // Sync Metadata Queries
  Future<SyncMetadata?> getSyncMetadata(String userId, String dataType) =>
      (select(syncMetadataTable)
            ..where((tbl) =>
                tbl.userId.equals(userId) & tbl.dataType.equals(dataType)))
          .getSingleOrNull();

  Future<int> insertSyncMetadata(SyncMetadataTableCompanion metadata) =>
      into(syncMetadataTable).insert(
        metadata,
        mode: InsertMode.insertOrReplace,
      );

  Future<bool> updateSyncMetadata(SyncMetadata metadata) =>
      update(syncMetadataTable).replace(metadata);

  // Dirty Items Queries
  Future<List<DirtyItem>> getDirtyItems(String userId) =>
      (select(dirtyItems)..where((tbl) => tbl.userId.equals(userId))).get();

  Future<int> getDirtyItemsCount(String userId) {
    final query = selectOnly(dirtyItems)
      ..addColumns([dirtyItems.itemId.count()])
      ..where(dirtyItems.userId.equals(userId));
    return query
        .map((row) => row.read(dirtyItems.itemId.count()) ?? 0)
        .getSingle();
  }

  Future<int> insertDirtyItem(DirtyItemsCompanion item) =>
      into(dirtyItems).insert(
        item,
        mode: InsertMode.insertOrReplace,
      );

  Future<int> deleteDirtyItem(
          String itemId, String itemType) =>
      (delete(dirtyItems)
            ..where((tbl) =>
                tbl.itemId.equals(itemId) & tbl.itemType.equals(itemType)))
          .go();

  // Progress Queries
  Future<List<ProgressData>> getProgressByUser(String userId) =>
      (select(progressTable)..where((tbl) => tbl.userId.equals(userId))).get();

  Future<ProgressData?> getProgress(String userId, String targetLanguage) =>
      (select(progressTable)
            ..where((tbl) =>
                tbl.userId.equals(userId) &
                tbl.targetLanguage.equals(targetLanguage)))
          .getSingleOrNull();

  Future<int> insertProgress(ProgressTableCompanion progress) =>
      into(progressTable).insert(
        progress,
        mode: InsertMode.insertOrReplace,
      );

  Future<bool> updateProgress(ProgressData progress) =>
      update(progressTable).replace(progress);

  // Performance Data Queries
  Future<List<PerformanceData>> getPerformanceByUser(String userId) =>
      (select(performanceDataTable)..where((tbl) => tbl.userId.equals(userId)))
          .get();

  Future<int> insertPerformance(PerformanceDataTableCompanion performance) =>
      into(performanceDataTable).insert(
        performance,
        mode: InsertMode.insertOrReplace,
      );

  Future<bool> updatePerformance(PerformanceData performance) =>
      update(performanceDataTable).replace(performance);

  // Review Items Queries
  Future<List<ReviewItem>> getReviewsByUser(String userId) =>
      (select(reviewItems)..where((tbl) => tbl.userId.equals(userId))).get();

  Future<List<ReviewItem>> getDueReviews(String userId, DateTime now) =>
      (select(reviewItems)
            ..where((tbl) =>
                tbl.userId.equals(userId) &
                tbl.nextReviewDate.isSmallerOrEqualValue(now)))
          .get();

  Future<int> insertReview(ReviewItemsCompanion review) =>
      into(reviewItems).insert(
        review,
        mode: InsertMode.insertOrReplace,
      );

  Future<bool> updateReview(ReviewItem review) =>
      update(reviewItems).replace(review);

  // Content Metadata Queries
  Future<List<ContentMetadata>> getAllContentMetadata() =>
      select(contentMetadataTable).get();

  Future<List<ContentMetadata>> getContentMetadataByLanguage(
    String targetLanguage,
  ) =>
      (select(contentMetadataTable)
            ..where((tbl) => tbl.targetLanguage.equals(targetLanguage)))
          .get();

  Future<int> insertContentMetadata(ContentMetadataTableCompanion metadata) =>
      into(contentMetadataTable).insert(
        metadata,
        mode: InsertMode.insertOrReplace,
      );

  Future<bool> updateContentMetadata(ContentMetadata metadata) =>
      update(contentMetadataTable).replace(metadata);
}

/// Open database connection
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'demon_teach.db'));
    return NativeDatabase(file);
  });
}
