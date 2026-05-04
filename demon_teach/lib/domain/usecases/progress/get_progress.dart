import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/progress.dart';
import 'package:demon_teach/domain/repositories/progress_repository.dart';

/// Use case to get user progress
class GetProgress {
  final ProgressRepository _repository;

  GetProgress(this._repository);

  Future<Result<Progress>> call({
    required String userId,
    required String targetLanguage,
  }) async {
    return await _repository.getProgress(userId, targetLanguage);
  }
}
