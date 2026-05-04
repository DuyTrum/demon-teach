import 'package:flutter_test/flutter_test.dart';
import 'package:demon_teach/domain/entities/performance_data.dart';
import 'package:demon_teach/domain/services/performance_analyzer.dart';
import 'dart:math';

/// **Validates: Requirements 12.1, 12.3, 12.4**
///
/// Property-based tests for adaptive difficulty system
/// Feature: demon-teach-language-learning-app
void main() {
  group('Adaptive Difficulty Properties', () {
    late PerformanceAnalyzer analyzer;
    late Random random;

    setUp(() {
      analyzer = PerformanceAnalyzer();
      random = Random(42); // Fixed seed for reproducibility
    });

    /// Property 17: Performance data collection
    ///
    /// **Validates: Requirements 12.1**
    ///
    /// For any completed lesson, performance data SHALL be recorded containing
    /// at minimum: accuracy, completion time, and difficulty level
    test('Property 17: Performance data collection', () {
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        // Generate random performance data
        final accuracy = random.nextDouble(); // 0.0 to 1.0
        final completionTime = random.nextInt(1800) + 60; // 60-1860 seconds
        final difficulties = ['basic', 'intermediate', 'advanced'];
        final difficulty = difficulties[random.nextInt(difficulties.length)];

        final performanceData = PerformanceData(
          id: 'perf_$i',
          userId: 'user1',
          lessonId: 'lesson_$i',
          targetLanguage: 'english',
          completedAt: DateTime.now(),
          accuracy: accuracy,
          completionTimeSeconds: completionTime,
          difficulty: difficulty,
        );

        // Property: Performance data must contain required fields
        expect(
          performanceData.accuracy,
          isNotNull,
          reason: 'Performance data must contain accuracy',
        );
        expect(
          performanceData.completionTimeSeconds,
          isNotNull,
          reason: 'Performance data must contain completion time',
        );
        expect(
          performanceData.difficulty,
          isNotNull,
          reason: 'Performance data must contain difficulty level',
        );

        // Property: Accuracy must be in valid range [0.0, 1.0]
        expect(
          performanceData.accuracy,
          inInclusiveRange(0.0, 1.0),
          reason: 'Accuracy must be between 0.0 and 1.0',
        );

        // Property: Completion time must be positive
        expect(
          performanceData.completionTimeSeconds,
          greaterThan(0),
          reason: 'Completion time must be positive',
        );

        // Property: Difficulty must be one of valid values
        expect(
          ['basic', 'intermediate', 'advanced'],
          contains(performanceData.difficulty),
          reason: 'Difficulty must be basic, intermediate, or advanced',
        );
      }
    });

    /// Property 18: Adaptive difficulty adjustment
    ///
    /// **Validates: Requirements 12.3, 12.4**
    ///
    /// For any 7-day performance window with at least 3 lessons and consistent
    /// performance (low variance), the difficulty adjustment SHALL be:
    /// - increase if average accuracy >= 85%
    /// - decrease if average accuracy <= 60%
    /// - maintain otherwise
    test('Property 18: Adaptive difficulty adjustment', () {
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        // Generate random number of lessons (3-20)
        final lessonCount = random.nextInt(18) + 3;

        // Generate random base accuracy with low variance for consistency
        final baseAccuracy = random.nextDouble();
        final variance = random.nextDouble() * 0.1; // Low variance (0-0.1)

        final performanceList = <PerformanceData>[];
        for (int j = 0; j < lessonCount; j++) {
          // Add small random variation around base accuracy
          final accuracyVariation = (random.nextDouble() - 0.5) * variance;
          final accuracy = (baseAccuracy + accuracyVariation).clamp(0.0, 1.0);

          performanceList.add(
            PerformanceData(
              id: 'perf_${i}_$j',
              userId: 'user1',
              lessonId: 'lesson_${i}_$j',
              targetLanguage: 'english',
              completedAt: DateTime.now().subtract(Duration(days: j)),
              accuracy: accuracy,
              completionTimeSeconds: random.nextInt(900) + 300,
              difficulty: 'intermediate',
            ),
          );
        }

        final adjustment = analyzer.analyze(performanceList);

        // Calculate actual average accuracy
        final avgAccuracy = performanceList.fold<double>(
              0.0,
              (sum, item) => sum + item.accuracy,
            ) /
            performanceList.length;

        // Calculate consistency score
        final accuracies = performanceList.map((d) => d.accuracy).toList();
        final mean = avgAccuracy;
        final varianceCalc = accuracies
                .map((acc) => pow(acc - mean, 2))
                .reduce((a, b) => a + b) /
            accuracies.length;
        final stdDev = sqrt(varianceCalc);
        final consistencyScore = max(0.0, 1.0 - (stdDev / 0.5));

        // Property: With at least 3 lessons and consistent performance
        if (lessonCount >= PerformanceAnalyzer.minimumLessons &&
            consistencyScore >= PerformanceAnalyzer.consistencyThreshold) {
          if (avgAccuracy >= PerformanceAnalyzer.increaseThreshold) {
            // Property: High accuracy should recommend increase
            expect(
              adjustment,
              equals(DifficultyAdjustment.increase),
              reason:
                  'Average accuracy ${(avgAccuracy * 100).toStringAsFixed(1)}% '
                  '(>= 85%) with consistency ${(consistencyScore * 100).toStringAsFixed(1)}% '
                  'should recommend difficulty increase',
            );
          } else if (avgAccuracy <= PerformanceAnalyzer.decreaseThreshold) {
            // Property: Low accuracy should recommend decrease
            expect(
              adjustment,
              equals(DifficultyAdjustment.decrease),
              reason:
                  'Average accuracy ${(avgAccuracy * 100).toStringAsFixed(1)}% '
                  '(<= 60%) with consistency ${(consistencyScore * 100).toStringAsFixed(1)}% '
                  'should recommend difficulty decrease',
            );
          } else {
            // Property: Medium accuracy should maintain
            expect(
              adjustment,
              equals(DifficultyAdjustment.maintain),
              reason:
                  'Average accuracy ${(avgAccuracy * 100).toStringAsFixed(1)}% '
                  '(60-85%) with consistency ${(consistencyScore * 100).toStringAsFixed(1)}% '
                  'should recommend maintain difficulty',
            );
          }
        } else {
          // Property: Insufficient data or inconsistent performance should maintain
          expect(
            adjustment,
            equals(DifficultyAdjustment.maintain),
            reason:
                'Insufficient lessons ($lessonCount < ${PerformanceAnalyzer.minimumLessons}) '
                'or inconsistent performance (consistency ${(consistencyScore * 100).toStringAsFixed(1)}% '
                '< ${PerformanceAnalyzer.consistencyThreshold * 100}%) should maintain difficulty',
          );
        }
      }
    });

    /// Property 18 (Extended): Consistency threshold enforcement
    ///
    /// Validates that high variance in performance prevents difficulty adjustment
    test('Property 18 (Extended): Consistency threshold enforcement', () {
      const iterations = 50;

      for (int i = 0; i < iterations; i++) {
        // Generate lessons with high variance
        final lessonCount = random.nextInt(8) + 5; // 5-12 lessons
        final performanceList = <PerformanceData>[];

        for (int j = 0; j < lessonCount; j++) {
          // Generate highly variable accuracy (0.0-1.0)
          final accuracy = random.nextDouble();

          performanceList.add(
            PerformanceData(
              id: 'perf_${i}_$j',
              userId: 'user1',
              lessonId: 'lesson_${i}_$j',
              targetLanguage: 'english',
              completedAt: DateTime.now().subtract(Duration(days: j)),
              accuracy: accuracy,
              completionTimeSeconds: random.nextInt(900) + 300,
              difficulty: 'intermediate',
            ),
          );
        }

        final adjustment = analyzer.analyze(performanceList);

        // Calculate consistency
        final avgAccuracy = performanceList.fold<double>(
              0.0,
              (sum, item) => sum + item.accuracy,
            ) /
            performanceList.length;
        final accuracies = performanceList.map((d) => d.accuracy).toList();
        final varianceCalc = accuracies
                .map((acc) => pow(acc - mean(accuracies), 2))
                .reduce((a, b) => a + b) /
            accuracies.length;
        final stdDev = sqrt(varianceCalc);
        final consistencyScore = max(0.0, 1.0 - (stdDev / 0.5));

        // Property: Low consistency should always result in maintain
        if (consistencyScore < PerformanceAnalyzer.consistencyThreshold) {
          expect(
            adjustment,
            equals(DifficultyAdjustment.maintain),
            reason:
                'Low consistency (${(consistencyScore * 100).toStringAsFixed(1)}% '
                '< ${PerformanceAnalyzer.consistencyThreshold * 100}%) should maintain difficulty '
                'regardless of average accuracy (${(avgAccuracy * 100).toStringAsFixed(1)}%)',
          );
        }
      }
    });

    /// Property 18 (Extended): Minimum lessons requirement
    ///
    /// Validates that insufficient lessons prevent difficulty adjustment
    test('Property 18 (Extended): Minimum lessons requirement', () {
      const iterations = 50;

      for (int i = 0; i < iterations; i++) {
        // Generate 0-2 lessons (below minimum of 3)
        final lessonCount = random.nextInt(3); // 0, 1, or 2
        final performanceList = <PerformanceData>[];

        // Generate consistent high or low accuracy
        final baseAccuracy = random.nextBool() ? 0.9 : 0.5;

        for (int j = 0; j < lessonCount; j++) {
          performanceList.add(
            PerformanceData(
              id: 'perf_${i}_$j',
              userId: 'user1',
              lessonId: 'lesson_${i}_$j',
              targetLanguage: 'english',
              completedAt: DateTime.now().subtract(Duration(days: j)),
              accuracy: baseAccuracy,
              completionTimeSeconds: random.nextInt(900) + 300,
              difficulty: 'intermediate',
            ),
          );
        }

        final adjustment = analyzer.analyze(performanceList);

        // Property: Fewer than minimum lessons should always maintain
        expect(
          adjustment,
          equals(DifficultyAdjustment.maintain),
          reason:
              'Insufficient lessons ($lessonCount < ${PerformanceAnalyzer.minimumLessons}) '
              'should maintain difficulty regardless of accuracy',
        );
      }
    });

    /// Property: Performance stats calculation
    ///
    /// Validates that performance statistics are calculated correctly
    test('Property: Performance stats calculation', () {
      const iterations = 100;

      for (int i = 0; i < iterations; i++) {
        final lessonCount = random.nextInt(20) + 1;
        final performanceList = <PerformanceData>[];

        double totalAccuracy = 0.0;
        int totalTime = 0;

        for (int j = 0; j < lessonCount; j++) {
          final accuracy = random.nextDouble();
          final time = random.nextInt(1800) + 60;

          totalAccuracy += accuracy;
          totalTime += time;

          performanceList.add(
            PerformanceData(
              id: 'perf_${i}_$j',
              userId: 'user1',
              lessonId: 'lesson_${i}_$j',
              targetLanguage: 'english',
              completedAt: DateTime.now().subtract(Duration(days: j)),
              accuracy: accuracy,
              completionTimeSeconds: time,
              difficulty: 'intermediate',
            ),
          );
        }

        final stats = analyzer.getStats(performanceList);

        // Property: Average accuracy should match calculated average
        final expectedAvgAccuracy = totalAccuracy / lessonCount;
        expect(
          stats.averageAccuracy,
          closeTo(expectedAvgAccuracy, 0.001),
          reason: 'Average accuracy should be correctly calculated',
        );

        // Property: Total lessons should match input count
        expect(
          stats.totalLessons,
          equals(lessonCount),
          reason: 'Total lessons should match input count',
        );

        // Property: Average completion time should match calculated average
        final expectedAvgTime = (totalTime / lessonCount).round();
        expect(
          stats.averageCompletionTime,
          equals(expectedAvgTime),
          reason: 'Average completion time should be correctly calculated',
        );

        // Property: Consistency score should be in valid range [0.0, 1.0]
        expect(
          stats.consistencyScore,
          inInclusiveRange(0.0, 1.0),
          reason: 'Consistency score should be between 0.0 and 1.0',
        );
      }
    });
  });
}

/// Helper function to calculate mean
double mean(List<double> values) {
  if (values.isEmpty) return 0.0;
  return values.reduce((a, b) => a + b) / values.length;
}
