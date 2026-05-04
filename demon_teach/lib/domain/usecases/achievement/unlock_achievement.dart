import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/achievement.dart';
import 'package:demon_teach/domain/repositories/achievement_repository.dart';

/// Use case for unlocking an achievement
class UnlockAchievement {
  final AchievementRepository _repository;

  UnlockAchievement(this._repository);

  Future<Result<Achievement>> call({
    required String achievementId,
    required DateTime unlockedAt,
  }) async {
    return await _repository.unlockAchievement(achievementId, unlockedAt);
  }
}
