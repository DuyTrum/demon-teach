import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/assessment.dart';

/// Assessment repository interface
abstract class AssessmentRepository {
  /// Get assessment for a specific language
  Future<Result<Assessment>> getAssessment(String targetLanguage, String nativeLanguage);

  /// Save assessment result
  Future<Result<void>> saveAssessmentResult(
    String userId,
    String targetLanguage,
    AssessmentResult result,
  );

  /// Get saved assessment result
  Future<Result<AssessmentResult?>> getAssessmentResult(
    String userId,
    String targetLanguage,
  );
}
