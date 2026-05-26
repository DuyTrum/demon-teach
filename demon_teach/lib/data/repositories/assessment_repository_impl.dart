import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demon_teach/core/errors/failures.dart';
import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/data/datasources/local/static_assessment_data.dart';
import 'package:demon_teach/domain/entities/assessment.dart';
import 'package:demon_teach/domain/repositories/assessment_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Implementation of AssessmentRepository using Firestore and SharedPreferences
class AssessmentRepositoryImpl implements AssessmentRepository {
  final SharedPreferences _prefs;

  AssessmentRepositoryImpl(this._prefs);

  @override
  Future<Result<Assessment>> getAssessment(String targetLanguage, String nativeLanguage) async {
    try {
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

      final resultJson = {
        'proficiencyLevel': result.proficiencyLevel.name,
        'score': result.score,
        'totalQuestions': result.totalQuestions,
        'correctAnswers': result.correctAnswers,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('preferences')
          .doc('assessment_$targetLanguage')
          .set(resultJson);

      await _prefs.setString(key, jsonEncode(resultJson));
      return Result.success(null);
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<AssessmentResult?>> getAssessmentResult(
    String userId,
    String targetLanguage,
  ) async {
    try {
      final key = 'assessment_result_${userId}_$targetLanguage';
      
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('preferences')
            .doc('assessment_$targetLanguage')
            .get();
            
        if (doc.exists && doc.data() != null) {
          final resultJson = doc.data()!;
          await _prefs.setString(key, jsonEncode(resultJson));
          
          final proficiencyLevel = ProficiencyLevel.values.firstWhere(
            (level) => level.name == resultJson['proficiencyLevel'],
          );

          final result = AssessmentResult(
            proficiencyLevel: proficiencyLevel,
            score: (resultJson['score'] as num).toDouble(),
            totalQuestions: resultJson['totalQuestions'] as int,
            correctAnswers: resultJson['correctAnswers'] as int,
            answers: const [],
          );
          return Result.success(result);
        }
      } catch (e) {
         print('Firestore assessment fetch failed, falling back to local cache: $e');
      }

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
        score: (resultJson['score'] as num).toDouble(),
        totalQuestions: resultJson['totalQuestions'] as int,
        correctAnswers: resultJson['correctAnswers'] as int,
        answers: const [],
      );

      return Result.success(result);
    } catch (e) {
      return Result.failure(CacheFailure(message: e.toString()));
    }
  }
}
