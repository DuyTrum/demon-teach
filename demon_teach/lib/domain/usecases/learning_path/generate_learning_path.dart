import 'package:demon_teach/core/errors/failures.dart';
import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/learning_path.dart';
import 'package:demon_teach/domain/entities/assessment.dart';
import 'package:demon_teach/domain/entities/learning_goal.dart';
import 'package:demon_teach/domain/entities/lesson.dart';
import 'package:demon_teach/domain/repositories/learning_path_repository.dart';
import 'package:demon_teach/domain/repositories/lesson_repository.dart';
import 'package:demon_teach/domain/services/learning_path_generator.dart';

/// Use case for generating a new learning path
class GenerateLearningPath {
  final LearningPathRepository _repository;
  final LessonRepository _lessonRepository;
  final LearningPathGenerator _generator;

  GenerateLearningPath(this._repository, this._lessonRepository, this._generator);

  Future<Result<LearningPath>> call({
    required String userId,
    required String targetLanguage,
    required ProficiencyLevel proficiencyLevel,
    required GoalType goalType,
  }) async {
    try {
      // Fetch available lessons for the target language from backend
      final lessonsResult = await _lessonRepository.getLessonsByLanguage(targetLanguage);
      List<Lesson> availableLessons = [];
      if (lessonsResult.isSuccess) {
        availableLessons = lessonsResult.value ?? [];
      }

      // Generate the learning path
      final path = _generator.generatePath(
        userId: userId,
        targetLanguage: targetLanguage,
        proficiencyLevel: proficiencyLevel,
        goalType: goalType,
        availableLessons: availableLessons,
      );

      // Save to repository
      final saveResult = await _repository.saveLearningPath(path);

      return saveResult.when(
        success: (_) => Result.success(path),
        failure: (failure) => Result.failure(failure),
      );
    } catch (e) {
      return Result.failure(
        ServerFailure(
            message: 'Failed to generate learning path: ${e.toString()}'),
      );
    }
  }
}
