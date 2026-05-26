import 'package:demon_teach/core/errors/failures.dart';
import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/achievement.dart';
import 'package:demon_teach/domain/repositories/achievement_repository.dart';
import 'package:demon_teach/domain/services/achievement_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Implementation of AchievementRepository using SharedPreferences
class AchievementRepositoryImpl implements AchievementRepository {
  final SharedPreferences _prefs;
  final AchievementEngine _engine;
  static const String _achievementsKeyPrefix = 'achievements_';

  AchievementRepositoryImpl(this._prefs, this._engine);

  String _getAchievementsKey(String userId, String targetLanguage) {
    return '$_achievementsKeyPrefix${userId}_$targetLanguage';
  }

  @override
  Future<Result<List<Achievement>>> getAchievements(
    String userId,
    String targetLanguage,
  ) async {
    try {
      final key = _getAchievementsKey(userId, targetLanguage);
      final achievementsJson = _prefs.getString(key);

      if (achievementsJson == null) {
        // Initialize with predefined achievements
        final achievements = _engine.getAchievementDefinitions(
          userId: userId,
          targetLanguage: targetLanguage,
        );
        await saveAchievements(achievements);
        return Result.success(achievements);
      }

      final achievementsList = json.decode(achievementsJson) as List;
      final achievements = achievementsList
          .map((json) => Achievement.fromJson(json as Map<String, dynamic>))
          .toList();

      if (achievements.isEmpty) {
        final newAchievements = _engine.getAchievementDefinitions(
          userId: userId,
          targetLanguage: targetLanguage,
        );
        await saveAchievements(newAchievements);
        return Result.success(newAchievements);
      }

      return Result.success(achievements);
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to get achievements: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<void>> saveAchievements(List<Achievement> achievements) async {
    try {
      if (achievements.isEmpty) {
        return Result.success(null);
      }

      final userId = achievements.first.userId;
      final targetLanguage = achievements.first.targetLanguage;
      final key = _getAchievementsKey(userId, targetLanguage);

      final achievementsJson =
          json.encode(achievements.map((a) => a.toJson()).toList());
      await _prefs.setString(key, achievementsJson);

      return Result.success(null);
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to save achievements: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<Achievement>> unlockAchievement(
    String achievementId,
    DateTime unlockedAt,
  ) async {
    try {
      // Extract userId and targetLanguage from achievementId
      // Format: {criteria}_{userId}_{targetLanguage}
      final parts = achievementId.split('_');
      if (parts.length < 3) {
        return Result.failure(
          CacheFailure(message: 'Invalid achievement ID format'),
        );
      }

      final userId = parts[parts.length - 2];
      final targetLanguage = parts[parts.length - 1];

      final achievementsResult = await getAchievements(userId, targetLanguage);

      return await achievementsResult.when(
        success: (achievements) async {
          final achievementIndex =
              achievements.indexWhere((a) => a.id == achievementId);

          if (achievementIndex == -1) {
            return Result.failure(
              CacheFailure(message: 'Achievement not found'),
            );
          }

          final achievement = achievements[achievementIndex];

          if (achievement.isUnlocked) {
            return Result.success(achievement);
          }

          final unlockedAchievement = achievement.copyWith(
            isUnlocked: true,
            unlockedAt: unlockedAt,
            progress: 1.0,
          );

          achievements[achievementIndex] = unlockedAchievement;

          final saveResult = await saveAchievements(achievements);

          return saveResult.when(
            success: (_) => Result.success(unlockedAchievement),
            failure: (failure) => Result.failure(failure),
          );
        },
        failure: (failure) => Future.value(Result.failure(failure)),
      );
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to unlock achievement: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<List<Achievement>>> getUnlockedAchievements(
    String userId,
    String targetLanguage,
  ) async {
    final achievementsResult = await getAchievements(userId, targetLanguage);

    return achievementsResult.when(
      success: (achievements) {
        final unlocked = achievements.where((a) => a.isUnlocked).toList();
        return Result.success(unlocked);
      },
      failure: (failure) => Result.failure(failure),
    );
  }

  @override
  Future<Result<List<Achievement>>> getLockedAchievements(
    String userId,
    String targetLanguage,
  ) async {
    final achievementsResult = await getAchievements(userId, targetLanguage);

    return achievementsResult.when(
      success: (achievements) {
        final locked = achievements.where((a) => !a.isUnlocked).toList();
        return Result.success(locked);
      },
      failure: (failure) => Result.failure(failure),
    );
  }

  @override
  Future<Result<bool>> achievementExists(String achievementId) async {
    try {
      // Extract userId and targetLanguage from achievementId
      final parts = achievementId.split('_');
      if (parts.length < 3) {
        return Result.success(false);
      }

      final userId = parts[parts.length - 2];
      final targetLanguage = parts[parts.length - 1];

      final achievementsResult = await getAchievements(userId, targetLanguage);

      return achievementsResult.when(
        success: (achievements) {
          final exists = achievements.any((a) => a.id == achievementId);
          return Result.success(exists);
        },
        failure: (_) => Result.success(false),
      );
    } catch (e) {
      return Result.success(false);
    }
  }
}
