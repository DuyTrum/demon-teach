import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/performance_data.dart';

/// Repository interface for performance data
abstract class PerformanceRepository {
  /// Record performance data for a completed lesson
  Future<Result<void>> recordPerformance(PerformanceData data);

  /// Get recent performance data for a user within specified days
  Future<Result<List<PerformanceData>>> getRecentPerformance(
    String userId,
    String targetLanguage,
    int days,
  );

  /// Get all performance data for a user
  Future<Result<List<PerformanceData>>> getAllPerformance(
    String userId,
    String targetLanguage,
  );

  /// Get performance data by ID
  Future<Result<PerformanceData>> getPerformanceById(String id);

  /// Delete performance data (for testing/cleanup)
  Future<Result<void>> deletePerformance(String id);
}
