import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/repositories/learning_path_repository.dart';

/// Use case for updating learning path progress
class UpdateLearningPath {
  final LearningPathRepository _repository;

  UpdateLearningPath(this._repository);

  Future<Result<void>> call({
    required String pathId,
    required int currentLessonIndex,
  }) async {
    return await _repository.updateProgress(
      pathId: pathId,
      currentLessonIndex: currentLessonIndex,
    );
  }
}
