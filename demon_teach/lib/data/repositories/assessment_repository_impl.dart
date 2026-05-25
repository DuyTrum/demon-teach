import 'package:demon_teach/core/errors/failures.dart';
import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/data/datasources/local/static_assessment_data.dart';
import 'package:demon_teach/domain/entities/assessment.dart';
import 'package:demon_teach/domain/repositories/assessment_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Implementation of AssessmentRepository using SharedPreferences and StaticAssessmentData
class AssessmentRepositoryImpl implements AssessmentRepository {
  final SharedPreferences _prefs;

  AssessmentRepositoryImpl(this._prefs);

  @override
  Future<Result<Assessment>> getAssessment(String targetLanguage, String nativeLanguage) async {
    try {
      // Get static assessment data based on language
      final assessment =
          StaticAssessmentData.getAssessmentByLanguage(targetLanguage, nativeLanguage: nativeLanguage);
      return Result.success(assessment);
    } catch (e) {
      return Result.failure(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> saveAssessmentResult(
    String userId,
    String targetLanguage,
    AssessmentResult result,
  ) async {
    try {
      final key = 'assessment_result_${userId}_$targetLanguage';

      // Convert result to JSON
      final resultJson = {
        'proficiencyLevel': result.proficiencyLevel.name,
        'score': result.score,
        'totalQuestions': result.totalQuestions,
        'correctAnswers': result.correctAnswers,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await _prefs.setString(key, jsonEncode(resultJson));
      return Result.success(null);
    } catch (e) {
      return Result.failure(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<AssessmentResult?>> getAssessmentResult(
    String userId,
    String targetLanguage,
  ) async {
    try {
      final key = 'assessment_result_${userId}_$targetLanguage';
      final resultString = _prefs.getString(key);

      if (resultString == null) {
        return Result.success(null);
      }

      final resultJson = jsonDecode(resultString) as Map<String, dynamic>;

      final proficiencyLevel = ProficiencyLevel.values.firstWhere(
        (level) => level.name == resultJson['proficiencyLevel'],
      );

      final result = AssessmentResult(
        proficiencyLevel: proficiencyLevel,
        score: resultJson['score'] as double,
        totalQuestions: resultJson['totalQuestions'] as int,
        correctAnswers: resultJson['correctAnswers'] as int,
        answers: const [], // Empty for now
      );

      return Result.success(result);
    } catch (e) {
      return Result.failure(CacheFailure(message: e.toString()));
    }
  }
}
