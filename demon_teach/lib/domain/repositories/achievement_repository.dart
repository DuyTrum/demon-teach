import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/achievement.dart';

/// Repository interface for achievement data
abstract class AchievementRepository {
  /// Get all achievements for a user and target language
  Future<Result<List<Achievement>>> getAchievements(
    String userId,
    String targetLanguage,
  );

  /// Save achievements
  Future<Result<void>> saveAchievements(List<Achievement> achievements);

  /// Unlock an achievement
  Future<Result<Achievement>> unlockAchievement(
    String achievementId,
    DateTime unlockedAt,
  );

  /// Get unlocked achievements
  Future<Result<List<Achievement>>> getUnlockedAchievements(
    String userId,
    String targetLanguage,
  );

  /// Get locked achievements
  Future<Result<List<Achievement>>> getLockedAchievements(
    String userId,
    String targetLanguage,
  );

  /// Check if achievement exists
  Future<Result<bool>> achievementExists(String achievementId);
}
