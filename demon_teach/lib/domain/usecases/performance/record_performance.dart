import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/performance_data.dart';
import 'package:demon_teach/domain/repositories/performance_repository.dart';

/// Use case for recording performance data
class RecordPerformance {
  final PerformanceRepository _repository;

  RecordPerformance(this._repository);

  Future<Result<void>> call(PerformanceData data) async {
    return await _repository.recordPerformance(data);
  }
}
