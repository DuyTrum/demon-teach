import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:demon_teach/domain/entities/performance_data.dart';
import 'package:demon_teach/domain/repositories/performance_repository.dart';
import 'package:demon_teach/domain/services/performance_analyzer.dart';
import 'package:demon_teach/domain/usecases/performance/record_performance.dart';
import 'package:demon_teach/domain/usecases/performance/analyze_performance.dart';

/// Provider for PerformanceRepository
final performanceRepositoryProvider = Provider<PerformanceRepository>((ref) {
  throw UnimplementedError('PerformanceRepository must be overridden');
});

/// Provider for PerformanceAnalyzer
final performanceAnalyzerProvider = Provider<PerformanceAnalyzer>((ref) {
  return PerformanceAnalyzer();
});

/// Provider for RecordPerformance use case
final recordPerformanceProvider = Provider<RecordPerformance>((ref) {
  final repository = ref.watch(performanceRepositoryProvider);
  return RecordPerformance(repository);
});

/// Provider for AnalyzePerformance use case
final analyzePerformanceProvider = Provider<AnalyzePerformance>((ref) {
  final repository = ref.watch(performanceRepositoryProvider);
  final analyzer = ref.watch(performanceAnalyzerProvider);
  return AnalyzePerformance(repository, analyzer);
});

/// State for performance data
class PerformanceState {
  final List<PerformanceData> recentPerformance;
  final PerformanceStats? stats;
  final DifficultyAdjustment? recommendedAdjustment;
  final bool isLoading;
  final String? error;

  const PerformanceState({
    this.recentPerformance = const [],
    this.stats,
    this.recommendedAdjustment,
    this.isLoading = false,
    this.error,
  });

  PerformanceState copyWith({
    List<PerformanceData>? recentPerformance,
    PerformanceStats? stats,
    DifficultyAdjustment? recommendedAdjustment,
    bool? isLoading,
    String? error,
  }) {
    return PerformanceState(
      recentPerformance: recentPerformance ?? this.recentPerformance,
      stats: stats ?? this.stats,
      recommendedAdjustment:
          recommendedAdjustment ?? this.recommendedAdjustment,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Provider for performance state
final performanceProvider =
    StateNotifierProvider<PerformanceNotifier, PerformanceState>((ref) {
  final repository = ref.watch(performanceRepositoryProvider);
  final analyzer = ref.watch(performanceAnalyzerProvider);
  return PerformanceNotifier(repository, analyzer);
});

/// Notifier for managing performance state
class PerformanceNotifier extends StateNotifier<PerformanceState> {
  final PerformanceRepository _repository;
  final PerformanceAnalyzer _analyzer;

  PerformanceNotifier(this._repository, this._analyzer)
      : super(const PerformanceState());

  /// Load recent performance data and analyze
  Future<void> loadPerformance(String userId, String targetLanguage) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getRecentPerformance(
      userId,
      targetLanguage,
      PerformanceAnalyzer.analysisWindowDays,
    );

    result.when(
      success: (data) {
        final stats = _analyzer.getStats(data);
        final adjustment = _analyzer.analyze(data);

        state = state.copyWith(
          recentPerformance: data,
          stats: stats,
          recommendedAdjustment: adjustment,
          isLoading: false,
        );
      },
      failure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
      },
    );
  }

  /// Record new performance data
  Future<void> recordPerformance(PerformanceData data) async {
    final result = await _repository.recordPerformance(data);

    result.when(
      success: (_) {
        // Reload performance data after recording
        loadPerformance(data.userId, data.targetLanguage);
      },
      failure: (failure) {
        state = state.copyWith(error: failure.message);
      },
    );
  }

  /// Refresh performance data
  Future<void> refresh(String userId, String targetLanguage) async {
    await loadPerformance(userId, targetLanguage);
  }

  /// Reset state
  void reset() {
    state = const PerformanceState();
  }
}
