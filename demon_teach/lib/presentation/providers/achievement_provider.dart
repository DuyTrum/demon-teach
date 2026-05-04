import 'package:demon_teach/domain/entities/achievement.dart';
import 'package:demon_teach/domain/repositories/achievement_repository.dart';
import 'package:demon_teach/domain/services/achievement_engine.dart';
import 'package:demon_teach/domain/usecases/achievement/get_achievements.dart';
import 'package:demon_teach/domain/usecases/achievement/check_and_unlock_achievements.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Repository provider
final achievementRepositoryProvider = Provider<AchievementRepository>((ref) {
  throw UnimplementedError('AchievementRepository must be overridden');
});

// Engine provider
final achievementEngineProvider = Provider<AchievementEngine>((ref) {
  return AchievementEngine();
});

// Use case providers
final getAchievementsProvider = Provider<GetAchievements>((ref) {
  return GetAchievements(ref.watch(achievementRepositoryProvider));
});

final checkAndUnlockAchievementsProvider =
    Provider<CheckAndUnlockAchievements>((ref) {
  // Import progress repository provider from progress_provider
  throw UnimplementedError('CheckAndUnlockAchievements must be overridden');
});

// Achievement state
class AchievementState {
  final List<Achievement> achievements;
  final List<Achievement> unlockedAchievements;
  final List<Achievement> lockedAchievements;
  final bool isLoading;
  final String? error;
  final List<Achievement>? newlyUnlocked;
  final int? bonusXP;

  const AchievementState({
    this.achievements = const [],
    this.unlockedAchievements = const [],
    this.lockedAchievements = const [],
    this.isLoading = false,
    this.error,
    this.newlyUnlocked,
    this.bonusXP,
  });

  AchievementState copyWith({
    List<Achievement>? achievements,
    List<Achievement>? unlockedAchievements,
    List<Achievement>? lockedAchievements,
    bool? isLoading,
    String? error,
    List<Achievement>? newlyUnlocked,
    int? bonusXP,
  }) {
    return AchievementState(
      achievements: achievements ?? this.achievements,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
      lockedAchievements: lockedAchievements ?? this.lockedAchievements,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      newlyUnlocked: newlyUnlocked,
      bonusXP: bonusXP,
    );
  }

  int get totalAchievements => achievements.length;
  int get unlockedCount => unlockedAchievements.length;
  double get completionPercentage =>
      totalAchievements > 0 ? unlockedCount / totalAchievements : 0.0;
}

// Achievement notifier
class AchievementNotifier extends StateNotifier<AchievementState> {
  final GetAchievements _getAchievements;
  final CheckAndUnlockAchievements _checkAndUnlock;

  AchievementNotifier(
    this._getAchievements,
    this._checkAndUnlock,
  ) : super(const AchievementState());

  /// Load achievements for user and target language
  Future<void> loadAchievements({
    required String userId,
    required String targetLanguage,
  }) async {
    state = state.copyWith(isLoading: true);

    final result = await _getAchievements(
      userId: userId,
      targetLanguage: targetLanguage,
    );

    result.when(
      success: (achievements) {
        final unlocked = achievements.where((a) => a.isUnlocked).toList();
        final locked = achievements.where((a) => !a.isUnlocked).toList();

        state = AchievementState(
          achievements: achievements,
          unlockedAchievements: unlocked,
          lockedAchievements: locked,
          isLoading: false,
        );
      },
      failure: (failure) {
        state = AchievementState(
          isLoading: false,
          error: failure.message,
        );
      },
    );
  }

  /// Check and unlock achievements based on current progress
  Future<void> checkAndUnlock({
    required String userId,
    required String targetLanguage,
  }) async {
    final result = await _checkAndUnlock(
      userId: userId,
      targetLanguage: targetLanguage,
    );

    result.when(
      success: (unlockResult) {
        if (unlockResult.hasNewUnlocks) {
          // Reload achievements to get updated state
          loadAchievements(userId: userId, targetLanguage: targetLanguage);

          // Set newly unlocked achievements for UI notification
          state = state.copyWith(
            newlyUnlocked: unlockResult.newlyUnlocked,
            bonusXP: unlockResult.bonusXP,
          );
        }
      },
      failure: (failure) {
        state = state.copyWith(error: failure.message);
      },
    );
  }

  /// Clear newly unlocked achievements (after showing notification)
  void clearNewlyUnlocked() {
    state = state.copyWith(
      newlyUnlocked: [],
      bonusXP: 0,
    );
  }

  /// Refresh achievements
  Future<void> refresh({
    required String userId,
    required String targetLanguage,
  }) async {
    await loadAchievements(userId: userId, targetLanguage: targetLanguage);
  }
}

// Achievement provider
final achievementProvider =
    StateNotifierProvider<AchievementNotifier, AchievementState>((ref) {
  return AchievementNotifier(
    ref.watch(getAchievementsProvider),
    ref.watch(checkAndUnlockAchievementsProvider),
  );
});
