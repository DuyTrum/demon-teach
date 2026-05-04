import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/achievement.dart';
import 'package:demon_teach/domain/repositories/achievement_repository.dart';
import 'package:demon_teach/domain/repositories/progress_repository.dart';
import 'package:demon_teach/domain/services/achievement_engine.dart';

/// Use case for checking and unlocking achievements based on progress
class CheckAndUnlockAchievements {
  final AchievementRepository _achievementRepository;
  final ProgressRepository _progressRepository;
  final AchievementEngine _engine;

  CheckAndUnlockAchievements(
    this._achievementRepository,
    this._progressRepository,
    this._engine,
  );

  /// Check progress and unlock any newly earned achievements
  /// Returns list of newly unlocked achievements and total bonus XP
  Future<Result<AchievementUnlockResult>> call({
    required String userId,
    required String targetLanguage,
  }) async {
    // Get current progress
    final progressResult =
        await _progressRepository.getProgress(userId, targetLanguage);

    return await progressResult.when(
      success: (progress) async {
        // Get all achievements
        final achievementsResult = await _achievementRepository.getAchievements(
            userId, targetLanguage);

        return await achievementsResult.when(
          success: (achievements) async {
            // Check for new unlocks
            final newlyUnlocked =
                _engine.checkForNewUnlocks(achievements, progress);

            if (newlyUnlocked.isEmpty) {
              return Result.success(
                AchievementUnlockResult(
                  newlyUnlocked: [],
                  bonusXP: 0,
                ),
              );
            }

            // Save unlocked achievements
            final updatedAchievements = achievements.map((achievement) {
              final unlocked = newlyUnlocked.firstWhere(
                (a) => a.id == achievement.id,
                orElse: () => achievement,
              );
              return unlocked;
            }).toList();

            final saveResult = await _achievementRepository
                .saveAchievements(updatedAchievements);

            return saveResult.when(
              success: (_) {
                final bonusXP = _engine.calculateBonusXP(newlyUnlocked);

                // Add bonus XP to progress
                _progressRepository.addXP(userId, targetLanguage, bonusXP);

                return Result.success(
                  AchievementUnlockResult(
                    newlyUnlocked: newlyUnlocked,
                    bonusXP: bonusXP,
                  ),
                );
              },
              failure: (failure) => Result.failure(failure),
            );
          },
          failure: (failure) => Future.value(Result.failure(failure)),
        );
      },
      failure: (failure) => Future.value(Result.failure(failure)),
    );
  }
}

/// Result of achievement unlock check
class AchievementUnlockResult {
  final List<Achievement> newlyUnlocked;
  final int bonusXP;

  AchievementUnlockResult({
    required this.newlyUnlocked,
    required this.bonusXP,
  });

  bool get hasNewUnlocks => newlyUnlocked.isNotEmpty;
}
