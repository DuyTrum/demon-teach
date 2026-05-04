import 'package:demon_teach/core/errors/failures.dart';
import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/assessment.dart';
import 'package:demon_teach/domain/repositories/assessment_repository.dart';
import 'package:demon_teach/domain/services/assessment_engine.dart';

/// Use case for submitting assessment and calculating results
class SubmitAssessment {
  final AssessmentRepository _repository;
  final AssessmentEngine _engine;

  SubmitAssessment(this._repository, this._engine);

  Future<Result<AssessmentResult>> call({
    required String userId,
    required String targetLanguage,
    required List<AssessmentAnswer> answers,
  }) async {
    try {
      // Calculate result using assessment engine
      final result = _engine.calculateResult(answers);

      // Save result to repository
      final saveResult = await _repository.saveAssessmentResult(
        userId,
        targetLanguage,
        result,
      );

      if (saveResult.isFailure) {
        return Result.failure(saveResult.failure);
      }

      return Result.success(result);
    } catch (e) {
      return Result.failure(CacheFailure(message: e.toString()));
    }
  }
}
