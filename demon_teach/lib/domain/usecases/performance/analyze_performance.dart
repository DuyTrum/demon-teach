import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/performance_data.dart';
import 'package:demon_teach/domain/repositories/performance_repository.dart';
import 'package:demon_teach/domain/services/performance_analyzer.dart';

/// Use case for analyzing performance and recommending difficulty adjustment
class AnalyzePerformance {
  final PerformanceRepository _repository;
  final PerformanceAnalyzer _analyzer;

  AnalyzePerformance(this._repository, this._analyzer);

  Future<Result<DifficultyAdjustment>> call(
    String userId,
    String targetLanguage,
  ) async {
    final result = await _repository.getRecentPerformance(
      userId,
      targetLanguage,
      PerformanceAnalyzer.analysisWindowDays,
    );

    return result.when(
      success: (data) {
        final adjustment = _analyzer.analyze(data);
        return Result.success(adjustment);
      },
      failure: (failure) => Result.failure(failure),
    );
  }
}
