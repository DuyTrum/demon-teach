import 'package:demon_teach/domain/entities/achievement.dart';
import 'package:demon_teach/domain/entities/progress.dart';

/// Service for managing achievements and checking unlock criteria
class AchievementEngine {
  /// Get all predefined achievement definitions
  List<Achievement> getAchievementDefinitions({
    required String userId,
    required String targetLanguage,
  }) {
    return [
      // Streak achievements
      Achievement(
        id: 'streak_7_${userId}_$targetLanguage',
        userId: userId,
        targetLanguage: targetLanguage,
        criteria: AchievementCriteria.streak7Days,
        type: AchievementType.streak,
        title: '1 Week Streak',
        description: 'Complete lessons for 7 consecutive days',
        bonusXP: 50,
        isUnlocked: false,
        progress: 0.0,
      ),
      Achievement(
        id: 'streak_30_${userId}_$targetLanguage',
        userId: userId,
        targetLanguage: targetLanguage,
        criteria: AchievementCriteria.streak30Days,
        type: AchievementType.streak,
        title: '1 Month Streak',
        description: 'Complete lessons for 30 consecutive days',
        bonusXP: 200,
        isUnlocked: false,
        progress: 0.0,
      ),
      Achievement(
        id: 'streak_100_${userId}_$targetLanguage',
        userId: userId,
        targetLanguage: targetLanguage,
        criteria: AchievementCriteria.streak100Days,
        type: AchievementType.streak,
        title: '100 Day Streak',
        description: 'Complete lessons for 100 consecutive days',
        bonusXP: 1000,
        isUnlocked: false,
        progress: 0.0,
      ),

      // XP achievements
      Achievement(
        id: 'xp_500_${userId}_$targetLanguage',
        userId: userId,
        targetLanguage: targetLanguage,
        criteria: AchievementCriteria.xp500,
        type: AchievementType.xp,
        title: 'Rising Star',
        description: 'Earn 500 total XP',
        bonusXP: 50,
        isUnlocked: false,
        progress: 0.0,
      ),
      Achievement(
        id: 'xp_1000_${userId}_$targetLanguage',
        userId: userId,
        targetLanguage: targetLanguage,
        criteria: AchievementCriteria.xp1000,
        type: AchievementType.xp,
        title: 'Dedicated Learner',
        description: 'Earn 1,000 total XP',
        bonusXP: 100,
        isUnlocked: false,
        progress: 0.0,
      ),
      Achievement(
        id: 'xp_5000_${userId}_$targetLanguage',
        userId: userId,
        targetLanguage: targetLanguage,
        criteria: AchievementCriteria.xp5000,
        type: AchievementType.xp,
        title: 'Expert Student',
        description: 'Earn 5,000 total XP',
        bonusXP: 500,
        isUnlocked: false,
        progress: 0.0,
      ),
      Achievement(
        id: 'xp_10000_${userId}_$targetLanguage',
        userId: userId,
        targetLanguage: targetLanguage,
        criteria: AchievementCriteria.xp10000,
        type: AchievementType.xp,
        title: 'Master Scholar',
        description: 'Earn 10,000 total XP',
        bonusXP: 1000,
        isUnlocked: false,
        progress: 0.0,
      ),

      // Lesson count achievements
      Achievement(
        id: 'lessons_10_${userId}_$targetLanguage',
        userId: userId,
        targetLanguage: targetLanguage,
        criteria: AchievementCriteria.lessons10,
        type: AchievementType.lessonCount,
        title: 'Getting Started',
        description: 'Complete 10 lessons',
        bonusXP: 50,
        isUnlocked: false,
        progress: 0.0,
      ),
      Achievement(
        id: 'lessons_50_${userId}_$targetLanguage',
        userId: userId,
        targetLanguage: targetLanguage,
        criteria: AchievementCriteria.lessons50,
        type: AchievementType.lessonCount,
        title: 'Committed Student',
        description: 'Complete 50 lessons',
        bonusXP: 200,
        isUnlocked: false,
        progress: 0.0,
      ),
      Achievement(
        id: 'lessons_100_${userId}_$targetLanguage',
        userId: userId,
        targetLanguage: targetLanguage,
        criteria: AchievementCriteria.lessons100,
        type: AchievementType.lessonCount,
        title: 'Century Club',
        description: 'Complete 100 lessons',
        bonusXP: 500,
        isUnlocked: false,
        progress: 0.0,
      ),
      Achievement(
        id: 'lessons_500_${userId}_$targetLanguage',
        userId: userId,
        targetLanguage: targetLanguage,
        criteria: AchievementCriteria.lessons500,
        type: AchievementType.lessonCount,
        title: 'Legendary Learner',
        description: 'Complete 500 lessons',
        bonusXP: 2000,
        isUnlocked: false,
        progress: 0.0,
      ),

      // Special achievements
      Achievement(
        id: 'first_lesson_${userId}_$targetLanguage',
        userId: userId,
        targetLanguage: targetLanguage,
        criteria: AchievementCriteria.firstLesson,
        type: AchievementType.special,
        title: 'First Steps',
        description: 'Complete your first lesson',
        bonusXP: 25,
        isUnlocked: false,
        progress: 0.0,
      ),
      Achievement(
        id: 'perfect_quiz_${userId}_$targetLanguage',
        userId: userId,
        targetLanguage: targetLanguage,
        criteria: AchievementCriteria.perfectQuiz,
        type: AchievementType.special,
        title: 'Perfect Score',
        description: 'Get 100% on a quiz',
        bonusXP: 50,
        isUnlocked: false,
        progress: 0.0,
      ),
      Achievement(
        id: 'review_master_${userId}_$targetLanguage',
        userId: userId,
        targetLanguage: targetLanguage,
        criteria: AchievementCriteria.reviewMaster,
        type: AchievementType.special,
        title: 'Review Master',
        description: 'Complete 100 review sessions',
        bonusXP: 500,
        isUnlocked: false,
        progress: 0.0,
      ),
    ];
  }

  /// Check if achievement should be unlocked based on progress
  bool shouldUnlockAchievement(Achievement achievement, Progress progress) {
    if (achievement.isUnlocked) {
      return false;
    }

    switch (achievement.criteria) {
      // Streak achievements
      case AchievementCriteria.streak7Days:
        return progress.currentStreak >= 7;
      case AchievementCriteria.streak30Days:
        return progress.currentStreak >= 30;
      case AchievementCriteria.streak100Days:
        return progress.currentStreak >= 100;

      // XP achievements
      case AchievementCriteria.xp500:
        return progress.totalXP >= 500;
      case AchievementCriteria.xp1000:
        return progress.totalXP >= 1000;
      case AchievementCriteria.xp5000:
        return progress.totalXP >= 5000;
      case AchievementCriteria.xp10000:
        return progress.totalXP >= 10000;

      // Lesson count achievements
      case AchievementCriteria.lessons10:
        return progress.lessonsCompleted >= 10;
      case AchievementCriteria.lessons50:
        return progress.lessonsCompleted >= 50;
      case AchievementCriteria.lessons100:
        return progress.lessonsCompleted >= 100;
      case AchievementCriteria.lessons500:
        return progress.lessonsCompleted >= 500;

      // Special achievements
      case AchievementCriteria.firstLesson:
        return progress.lessonsCompleted >= 1;

      // These require additional context beyond Progress entity
      case AchievementCriteria.perfectQuiz:
      case AchievementCriteria.reviewMaster:
        return false;
    }
  }

  /// Calculate progress toward achievement
  double calculateProgress(Achievement achievement, Progress progress) {
    if (achievement.isUnlocked) {
      return 1.0;
    }

    final targetValue = achievement.getTargetValue();
    int currentValue;

    switch (achievement.criteria) {
      // Streak achievements
      case AchievementCriteria.streak7Days:
      case AchievementCriteria.streak30Days:
      case AchievementCriteria.streak100Days:
        currentValue = progress.currentStreak;
        break;

      // XP achievements
      case AchievementCriteria.xp500:
      case AchievementCriteria.xp1000:
      case AchievementCriteria.xp5000:
      case AchievementCriteria.xp10000:
        currentValue = progress.totalXP;
        break;

      // Lesson count achievements
      case AchievementCriteria.lessons10:
      case AchievementCriteria.lessons50:
      case AchievementCriteria.lessons100:
      case AchievementCriteria.lessons500:
      case AchievementCriteria.firstLesson:
        currentValue = progress.lessonsCompleted;
        break;

      // Special achievements (require additional context)
      case AchievementCriteria.perfectQuiz:
      case AchievementCriteria.reviewMaster:
        return 0.0;
    }

    return (currentValue / targetValue).clamp(0.0, 1.0);
  }

  /// Update achievement with current progress
  Achievement updateAchievementProgress(
    Achievement achievement,
    Progress progress,
  ) {
    final newProgress = calculateProgress(achievement, progress);
    final shouldUnlock = shouldUnlockAchievement(achievement, progress);

    if (shouldUnlock) {
      return achievement.copyWith(
        isUnlocked: true,
        unlockedAt: DateTime.now(),
        progress: 1.0,
      );
    }

    return achievement.copyWith(progress: newProgress);
  }

  /// Get newly unlocked achievements
  List<Achievement> checkForNewUnlocks(
    List<Achievement> achievements,
    Progress progress,
  ) {
    final newlyUnlocked = <Achievement>[];

    for (final achievement in achievements) {
      if (!achievement.isUnlocked &&
          shouldUnlockAchievement(achievement, progress)) {
        newlyUnlocked.add(
          achievement.copyWith(
            isUnlocked: true,
            unlockedAt: DateTime.now(),
            progress: 1.0,
          ),
        );
      }
    }

    return newlyUnlocked;
  }

  /// Calculate total bonus XP from newly unlocked achievements
  int calculateBonusXP(List<Achievement> newlyUnlocked) {
    return newlyUnlocked.fold(
        0, (sum, achievement) => sum + achievement.bonusXP);
  }
}
