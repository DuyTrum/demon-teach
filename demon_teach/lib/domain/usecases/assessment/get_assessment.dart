import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/assessment.dart';
import 'package:demon_teach/domain/repositories/assessment_repository.dart';

/// Use case for getting assessment questions
class GetAssessment {
  final AssessmentRepository _repository;

  GetAssessment(this._repository);

  Future<Result<Assessment>> call(String targetLanguage, String nativeLanguage) async {
    return await _repository.getAssessment(targetLanguage, nativeLanguage);
  }
}
