import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/learning_path.dart';
import 'package:demon_teach/domain/repositories/learning_path_repository.dart';

/// Use case for retrieving a learning path
class GetLearningPath {
  final LearningPathRepository _repository;

  GetLearningPath(this._repository);

  Future<Result<LearningPath?>> call({
    required String userId,
    required String targetLanguage,
  }) async {
    return await _repository.getLearningPath(
      userId: userId,
      targetLanguage: targetLanguage,
    );
  }
}
