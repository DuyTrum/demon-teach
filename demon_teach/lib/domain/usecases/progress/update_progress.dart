import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/progress.dart';
import 'package:demon_teach/domain/repositories/progress_repository.dart';
import 'package:demon_teach/domain/services/progress_tracker.dart';

/// Use case to update progress after lesson completion
class UpdateProgress {
  final ProgressRepository _repository;
  final ProgressTracker _tracker;

  UpdateProgress(this._repository, this._tracker);

  Future<Result<Progress>> call({
    required String userId,
    required String targetLanguage,
    required int score,
  }) async {
    // Get current progress
    final progressResult =
        await _repository.getProgress(userId, targetLanguage);

    return await progressResult.when(
      success: (progress) async {
        // Calculate XP
        final xp = _tracker.calculateXP(score);

        // Update streak
        final updatedProgress = _tracker.updateStreak(progress, DateTime.now());

        // Add XP and increment lessons completed
        final finalProgress = updatedProgress.copyWith(
          totalXP: updatedProgress.totalXP + xp,
          lessonsCompleted: updatedProgress.lessonsCompleted + 1,
          updatedAt: DateTime.now(),
        );

        // Save updated progress
        final updateResult = await _repository.updateProgress(finalProgress);

        return updateResult.when(
          success: (_) => Result.success(finalProgress),
          failure: (failure) => Result.failure(failure),
        );
      },
      failure: (failure) => Future.value(Result.failure(failure)),
    );
  }
}
