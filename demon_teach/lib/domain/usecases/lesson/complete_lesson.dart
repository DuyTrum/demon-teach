import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/repositories/lesson_repository.dart';
import 'package:demon_teach/domain/repositories/learning_path_repository.dart';

/// Use case for completing a lesson
class CompleteLesson {
  final LessonRepository _lessonRepository;
  final LearningPathRepository _learningPathRepository;

  CompleteLesson(this._lessonRepository, this._learningPathRepository);

  Future<Result<void>> call({
    required String userId,
    required String lessonId,
    required int score,
    required String targetLanguage,
  }) async {
    // Mark lesson as completed
    final completeResult = await _lessonRepository.completeLesson(
      userId: userId,
      lessonId: lessonId,
      score: score,
    );

    return completeResult.when(
      success: (_) async {
        // Get learning path
        final pathResult = await _learningPathRepository.getLearningPath(
          userId: userId,
          targetLanguage: targetLanguage,
        );

        return pathResult.when(
          success: (path) async {
            if (path == null) {
              return Result.success(null);
            }

            // Update learning path progress (move to next lesson)
            final newIndex = path.currentLessonIndex + 1;
            return await _learningPathRepository.updateProgress(
              pathId: path.id,
              currentLessonIndex: newIndex,
            );
          },
          failure: (failure) => Result.failure(failure),
        );
      },
      failure: (failure) => Result.failure(failure),
    );
  }
}
