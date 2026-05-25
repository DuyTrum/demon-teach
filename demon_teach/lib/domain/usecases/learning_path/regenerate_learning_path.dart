import 'package:demon_teach/core/errors/failures.dart';
import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/learning_path.dart';
import 'package:demon_teach/domain/entities/assessment.dart';
import 'package:demon_teach/domain/entities/learning_goal.dart';
import 'package:demon_teach/domain/entities/lesson.dart';
import 'package:demon_teach/domain/repositories/learning_path_repository.dart';
import 'package:demon_teach/domain/repositories/lesson_repository.dart';
import 'package:demon_teach/domain/services/learning_path_generator.dart';

/// Use case for regenerating a learning path with updated preferences
class RegenerateLearningPath {
  final LearningPathRepository _repository;
  final LessonRepository _lessonRepository;
  final LearningPathGenerator _generator;

  RegenerateLearningPath(this._repository, this._lessonRepository, this._generator);

  Future<Result<LearningPath>> call({
    required LearningPath currentPath,
    ProficiencyLevel? newProficiencyLevel,
    GoalType? newGoalType,
  }) async {
    try {
      // Fetch available lessons for the target language from backend
      final lessonsResult = await _lessonRepository.getLessonsByLanguage(currentPath.targetLanguage);
      List<Lesson> availableLessons = [];
      if (lessonsResult.isSuccess) {
        availableLessons = lessonsResult.value ?? [];
      }

      // Generate the new path
      final newPath = _generator.regeneratePath(
        currentPath: currentPath,
        newProficiencyLevel: newProficiencyLevel,
        newGoalType: newGoalType,
        availableLessons: availableLessons,
      );

      // Save to repository
      final saveResult = await _repository.saveLearningPath(newPath);

      return saveResult.when(
        success: (_) => Result.success(newPath),
        failure: (failure) => Result.failure(failure),
      );
    } catch (e) {
      return Result.failure(
        ServerFailure(
            message: 'Failed to regenerate learning path: ${e.toString()}'),
      );
    }
  }
}
