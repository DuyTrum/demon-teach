import 'package:demon_teach/core/constants/app_constants.dart';
import 'package:demon_teach/domain/entities/progress.dart';

/// Service for calculating progress metrics
class ProgressTracker {
  /// Calculate XP based on lesson score
  /// Base XP: 50
  /// Score bonus: score / 2 (max 50 for perfect score)
  int calculateXP(int score) {
    const baseXP = 50;
    final scoreBonus = (score / 2).round();
    return baseXP + scoreBonus;
  }

  /// Calculate XP with accuracy bonus
  /// Base XP: 50
  /// Accuracy bonus: accuracy * 50 (max 50 for 100% accuracy)
  int calculateXPWithAccuracy(double accuracy) {
    const baseXP = 50;
    final accuracyBonus = (accuracy * 50).round();
    return baseXP + accuracyBonus;
  }

  /// Update streak based on last lesson date
  /// Returns updated progress with new streak values
  Progress updateStreak(Progress progress, DateTime completionDate) {
    final lastDate = progress.lastLessonDate;

    // If no previous lesson, start streak at 1
    if (lastDate == null) {
      return progress.copyWith(
        currentStreak: 1,
        longestStreak: 1,
        lastLessonDate: completionDate,
        updatedAt: DateTime.now(),
      );
    }

    // Check if completion is on consecutive day
    final daysSinceLastLesson = _daysBetween(lastDate, completionDate);

    int newStreak;
    if (daysSinceLastLesson == 0) {
      // Same day - don't increment streak
      newStreak = progress.currentStreak;
    } else if (daysSinceLastLesson == 1) {
      // Consecutive day - increment streak
      newStreak = progress.currentStreak + 1;
    } else {
      // Missed days - reset streak
      newStreak = 1;
    }

    // Update longest streak if current is higher
    final newLongestStreak =
        newStreak > progress.longestStreak ? newStreak : progress.longestStreak;

    return progress.copyWith(
      currentStreak: newStreak,
      longestStreak: newLongestStreak,
      lastLessonDate: completionDate,
      updatedAt: DateTime.now(),
    );
  }

  /// Check if streak should be incremented
  bool shouldIncrementStreak(DateTime? lastCompletionDate) {
    if (lastCompletionDate == null) return true;

    final now = DateTime.now();
    final daysSince = _daysBetween(lastCompletionDate, now);

    return daysSince == 1;
  }

  /// Check if streak should be reset
  bool shouldResetStreak(DateTime? lastCompletionDate) {
    if (lastCompletionDate == null) return false;

    final now = DateTime.now();
    final daysSince = _daysBetween(lastCompletionDate, now);

    return daysSince > 1;
  }

  /// Calculate days between two dates (ignoring time)
  int _daysBetween(DateTime from, DateTime to) {
    final fromDate = DateTime(from.year, from.month, from.day);
    final toDate = DateTime(to.year, to.month, to.day);
    return toDate.difference(fromDate).inDays;
  }

  /// Check if date is a streak milestone
  bool isStreakMilestone(int streak) {
    return AppConstants.streakMilestones.contains(streak);
  }

  /// Get next streak milestone
  int? getNextStreakMilestone(int currentStreak) {
    for (final milestone in AppConstants.streakMilestones) {
      if (milestone > currentStreak) {
        return milestone;
      }
    }
    return null;
  }

  /// Calculate progress percentage for learning path
  double calculateLearningPathProgress(
    int lessonsCompleted,
    int totalLessons,
  ) {
    if (totalLessons == 0) return 0.0;
    return (lessonsCompleted / totalLessons).clamp(0.0, 1.0);
  }

  /// Check and regenerate hearts based on time difference.
  /// 1 Heart regenerated every heartRegenInterval (e.g. 30 mins), capped at maxHearts (5).
  Progress checkAndRegenerateHearts(Progress progress) {
    final now = DateTime.now();

    // If hearts are full, reset regen timer to now
    if (progress.hearts >= AppConstants.maxHearts) {
      return progress.copyWith(lastHeartRegenTime: now);
    }

    // Handle anti-cheat: if the system clock was rolled back
    if (now.isBefore(progress.lastHeartRegenTime)) {
      return progress.copyWith(lastHeartRegenTime: now);
    }

    final interval = AppConstants.heartRegenInterval;
    final difference = now.difference(progress.lastHeartRegenTime);
    final heartsToRegen = difference.inSeconds ~/ interval.inSeconds;

    if (heartsToRegen > 0) {
      final newHearts = (progress.hearts + heartsToRegen).clamp(0, AppConstants.maxHearts);
      final newRegenTime = progress.lastHeartRegenTime.add(interval * heartsToRegen);
      return progress.copyWith(
        hearts: newHearts,
        lastHeartRegenTime: newHearts == AppConstants.maxHearts ? now : newRegenTime,
        updatedAt: now,
      );
    }

    return progress;
  }
}
