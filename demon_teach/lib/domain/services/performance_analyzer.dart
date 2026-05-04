import 'dart:math';
import 'package:demon_teach/domain/entities/performance_data.dart';

/// Service for analyzing performance data and recommending difficulty adjustments
class PerformanceAnalyzer {
  static const int analysisWindowDays = 7;
  static const double increaseThreshold = 0.85;
  static const double decreaseThreshold = 0.60;
  static const int minimumLessons = 3;
  static const double consistencyThreshold = 0.7;

  /// Analyze performance data and recommend difficulty adjustment
  DifficultyAdjustment analyze(List<PerformanceData> data) {
    // Need at least minimum lessons to make a decision
    if (data.length < minimumLessons) {
      return DifficultyAdjustment.maintain;
    }

    final avgAccuracy = _calculateAverageAccuracy(data);
    final consistencyScore = _calculateConsistency(data);

    // Only adjust if performance is consistent (low variance)
    if (consistencyScore < consistencyThreshold) {
      return DifficultyAdjustment.maintain;
    }

    // Determine adjustment based on accuracy thresholds
    if (avgAccuracy >= increaseThreshold) {
      return DifficultyAdjustment.increase;
    } else if (avgAccuracy <= decreaseThreshold) {
      return DifficultyAdjustment.decrease;
    } else {
      return DifficultyAdjustment.maintain;
    }
  }

  /// Calculate average accuracy from performance data
  double _calculateAverageAccuracy(List<PerformanceData> data) {
    if (data.isEmpty) return 0.0;
    final sum = data.fold<double>(0.0, (sum, item) => sum + item.accuracy);
    return sum / data.length;
  }

  /// Calculate consistency score (1.0 = perfectly consistent, 0.0 = highly variable)
  /// Uses standard deviation to measure variance
  double _calculateConsistency(List<PerformanceData> data) {
    if (data.length < 2) return 1.0;

    final accuracies = data.map((d) => d.accuracy).toList();
    final mean = _calculateAverageAccuracy(data);

    // Calculate standard deviation
    final variance =
        accuracies.map((acc) => pow(acc - mean, 2)).reduce((a, b) => a + b) /
            accuracies.length;
    final stdDev = sqrt(variance);

    // Consistency score: 1.0 - normalized standard deviation
    // Lower std dev = higher consistency
    // Normalize by 0.5 (max reasonable std dev for 0-1 range)
    return max(0.0, 1.0 - (stdDev / 0.5));
  }

  /// Get performance statistics for display
  PerformanceStats getStats(List<PerformanceData> data) {
    if (data.isEmpty) {
      return PerformanceStats(
        averageAccuracy: 0.0,
        consistencyScore: 0.0,
        totalLessons: 0,
        averageCompletionTime: 0,
      );
    }

    final avgAccuracy = _calculateAverageAccuracy(data);
    final consistencyScore = _calculateConsistency(data);
    final avgTime =
        data.fold<int>(0, (sum, item) => sum + item.completionTimeSeconds) /
            data.length;

    return PerformanceStats(
      averageAccuracy: avgAccuracy,
      consistencyScore: consistencyScore,
      totalLessons: data.length,
      averageCompletionTime: avgTime.round(),
    );
  }
}

/// Performance statistics for display
class PerformanceStats {
  final double averageAccuracy;
  final double consistencyScore;
  final int totalLessons;
  final int averageCompletionTime;

  const PerformanceStats({
    required this.averageAccuracy,
    required this.consistencyScore,
    required this.totalLessons,
    required this.averageCompletionTime,
  });

  /// Get accuracy percentage (0-100)
  int get accuracyPercentage => (averageAccuracy * 100).round();

  /// Get consistency percentage (0-100)
  int get consistencyPercentage => (consistencyScore * 100).round();

  /// Get average completion time in minutes
  double get averageCompletionMinutes => averageCompletionTime / 60.0;
}
