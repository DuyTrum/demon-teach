import 'dart:convert';
import 'package:demon_teach/core/errors/failures.dart';
import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/performance_data.dart';
import 'package:demon_teach/domain/repositories/performance_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Implementation of PerformanceRepository using SharedPreferences
class PerformanceRepositoryImpl implements PerformanceRepository {
  final SharedPreferences _prefs;
  static const String _performanceKeyPrefix = 'performance_';
  static const String _performanceListKey = 'performance_list_';

  PerformanceRepositoryImpl(this._prefs);

  String _getPerformanceListKey(String userId, String targetLanguage) {
    return '$_performanceListKey${userId}_$targetLanguage';
  }

  String _getPerformanceKey(String id) {
    return '$_performanceKeyPrefix$id';
  }

  @override
  Future<Result<void>> recordPerformance(PerformanceData data) async {
    try {
      // Save individual performance data
      final key = _getPerformanceKey(data.id);
      final json = jsonEncode(data.toJson());
      await _prefs.setString(key, json);

      // Add to user's performance list
      final listKey = _getPerformanceListKey(data.userId, data.targetLanguage);
      final existingIds = _prefs.getStringList(listKey) ?? [];
      if (!existingIds.contains(data.id)) {
        existingIds.add(data.id);
        await _prefs.setStringList(listKey, existingIds);
      }

      return Result.success(null);
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to record performance: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<List<PerformanceData>>> getRecentPerformance(
    String userId,
    String targetLanguage,
    int days,
  ) async {
    try {
      final allPerformanceResult =
          await getAllPerformance(userId, targetLanguage);

      return allPerformanceResult.when(
        success: (allData) {
          final cutoffDate = DateTime.now().subtract(Duration(days: days));
          final recentData = allData
              .where((data) => data.completedAt.isAfter(cutoffDate))
              .toList();

          // Sort by completion date (newest first)
          recentData.sort((a, b) => b.completedAt.compareTo(a.completedAt));

          return Result.success(recentData);
        },
        failure: (failure) => Result.failure(failure),
      );
    } catch (e) {
      return Result.failure(
        CacheFailure(
            message: 'Failed to get recent performance: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<List<PerformanceData>>> getAllPerformance(
    String userId,
    String targetLanguage,
  ) async {
    try {
      final listKey = _getPerformanceListKey(userId, targetLanguage);
      final ids = _prefs.getStringList(listKey) ?? [];

      final performanceList = <PerformanceData>[];
      for (final id in ids) {
        final result = await getPerformanceById(id);
        result.when(
          success: (data) => performanceList.add(data),
          failure: (_) {}, // Skip failed items
        );
      }

      return Result.success(performanceList);
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to get all performance: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<PerformanceData>> getPerformanceById(String id) async {
    try {
      final key = _getPerformanceKey(id);
      final json = _prefs.getString(key);

      if (json == null) {
        return Result.failure(
          CacheFailure(message: 'Performance data not found: $id'),
        );
      }

      final data = PerformanceData.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );

      return Result.success(data);
    } catch (e) {
      return Result.failure(
        CacheFailure(
            message: 'Failed to get performance by ID: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<void>> deletePerformance(String id) async {
    try {
      final key = _getPerformanceKey(id);
      await _prefs.remove(key);

      // Note: We don't remove from the list to avoid complexity
      // The list will just have a dangling reference that gets skipped

      return Result.success(null);
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to delete performance: ${e.toString()}'),
      );
    }
  }
}
