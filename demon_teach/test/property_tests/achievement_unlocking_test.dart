import 'package:flutter_test/flutter_test.dart';
import 'package:demon_teach/domain/entities/achievement.dart';
import 'package:demon_teach/domain/entities/progress.dart';
import 'package:demon_teach/domain/services/achievement_engine.dart';

/// **Property 21: Achievement Unlocking**
///
/// *For any* user progress that meets achievement criteria (streak milestone,
/// XP threshold, or lesson count), the corresponding achievement SHALL be unlocked.
///
/// **Validates: Requirements 17.2**

void main() {
  group('Property 21: Achievement Unlocking', () {
    late AchievementEngine engine;

    setUp(() {
      engine = AchievementEngine();
    });

    test('Property: Streak achievements unlock when streak milestone reached',
        () {
      const userId = 'test_user';
      const targetLanguage = 'en';

      // Test data: streak values and expected unlocks
      final testCases = [
        (streak: 7, expectedUnlocks: ['streak_7_${userId}_$targetLanguage']),
        (
          streak: 30,
          expectedUnlocks: [
            'streak_7_${userId}_$targetLanguage',
            'streak_30_${userId}_$targetLanguage'
          ]
        ),
        (
          streak: 100,
          expectedUnlocks: [
            'streak_7_${userId}_$targetLanguage',
            'streak_30_${userId}_$targetLanguage',
            'streak_100_${userId}_$targetLanguage'
          ]
        ),
      ];

      for (final testCase in testCases) {
        // Create progress with specific streak
        final progress = Progress(
          userId: userId,
          targetLanguage: targetLanguage,
          totalXP: 0,
          currentStreak: testCase.streak,
          longestStreak: testCase.streak,
          lessonsCompleted: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Get all achievements
        final achievements = engine.getAchievementDefinitions(
          userId: userId,
          targetLanguage: targetLanguage,
        );

        // Check for unlocks
        final newlyUnlocked = engine.checkForNewUnlocks(achievements, progress);

        // Verify correct achievements are unlocked
        final unlockedIds = newlyUnlocked.map((a) => a.id).toSet();
        final expectedIds = testCase.expectedUnlocks.toSet();

        expect(
          unlockedIds,
          equals(expectedIds),
          reason:
              'Streak ${testCase.streak} should unlock: ${testCase.expectedUnlocks}',
        );

        // Verify all unlocked achievements have correct properties
        for (final achievement in newlyUnlocked) {
          expect(achievement.isUnlocked, isTrue);
          expect(achievement.unlockedAt, isNotNull);
          expect(achievement.progress, equals(1.0));
        }
      }
    });

    test('Property: XP achievements unlock when XP threshold reached', () {
      const userId = 'test_user';
      const targetLanguage = 'en';

      // Test data: XP values and expected unlocks
      final testCases = [
        (xp: 500, expectedUnlocks: ['xp_500_${userId}_$targetLanguage']),
        (
          xp: 1000,
          expectedUnlocks: [
            'xp_500_${userId}_$targetLanguage',
            'xp_1000_${userId}_$targetLanguage'
          ]
        ),
        (
          xp: 5000,
          expectedUnlocks: [
            'xp_500_${userId}_$targetLanguage',
            'xp_1000_${userId}_$targetLanguage',
            'xp_5000_${userId}_$targetLanguage'
          ]
        ),
        (
          xp: 10000,
          expectedUnlocks: [
            'xp_500_${userId}_$targetLanguage',
            'xp_1000_${userId}_$targetLanguage',
            'xp_5000_${userId}_$targetLanguage',
            'xp_10000_${userId}_$targetLanguage'
          ]
        ),
      ];

      for (final testCase in testCases) {
        // Create progress with specific XP
        final progress = Progress(
          userId: userId,
          targetLanguage: targetLanguage,
          totalXP: testCase.xp,
          currentStreak: 0,
          longestStreak: 0,
          lessonsCompleted: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Get all achievements
        final achievements = engine.getAchievementDefinitions(
          userId: userId,
          targetLanguage: targetLanguage,
        );

        // Check for unlocks
        final newlyUnlocked = engine.checkForNewUnlocks(achievements, progress);

        // Verify correct achievements are unlocked
        final unlockedIds = newlyUnlocked.map((a) => a.id).toSet();
        final expectedIds = testCase.expectedUnlocks.toSet();

        expect(
          unlockedIds,
          equals(expectedIds),
          reason:
              'XP ${testCase.xp} should unlock: ${testCase.expectedUnlocks}',
        );

        // Verify all unlocked achievements have correct properties
        for (final achievement in newlyUnlocked) {
          expect(achievement.isUnlocked, isTrue);
          expect(achievement.unlockedAt, isNotNull);
          expect(achievement.progress, equals(1.0));
        }
      }
    });

    test('Property: Lesson count achievements unlock when count reached', () {
      const userId = 'test_user';
      const targetLanguage = 'en';

      // Test data: lesson counts and expected unlocks
      final testCases = [
        (
          lessons: 1,
          expectedUnlocks: ['first_lesson_${userId}_$targetLanguage']
        ),
        (
          lessons: 10,
          expectedUnlocks: [
            'first_lesson_${userId}_$targetLanguage',
            'lessons_10_${userId}_$targetLanguage'
          ]
        ),
        (
          lessons: 50,
          expectedUnlocks: [
            'first_lesson_${userId}_$targetLanguage',
            'lessons_10_${userId}_$targetLanguage',
            'lessons_50_${userId}_$targetLanguage'
          ]
        ),
        (
          lessons: 100,
          expectedUnlocks: [
            'first_lesson_${userId}_$targetLanguage',
            'lessons_10_${userId}_$targetLanguage',
            'lessons_50_${userId}_$targetLanguage',
            'lessons_100_${userId}_$targetLanguage'
          ]
        ),
        (
          lessons: 500,
          expectedUnlocks: [
            'first_lesson_${userId}_$targetLanguage',
            'lessons_10_${userId}_$targetLanguage',
            'lessons_50_${userId}_$targetLanguage',
            'lessons_100_${userId}_$targetLanguage',
            'lessons_500_${userId}_$targetLanguage'
          ]
        ),
      ];

      for (final testCase in testCases) {
        // Create progress with specific lesson count
        final progress = Progress(
          userId: userId,
          targetLanguage: targetLanguage,
          totalXP: 0,
          currentStreak: 0,
          longestStreak: 0,
          lessonsCompleted: testCase.lessons,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Get all achievements
        final achievements = engine.getAchievementDefinitions(
          userId: userId,
          targetLanguage: targetLanguage,
        );

        // Check for unlocks
        final newlyUnlocked = engine.checkForNewUnlocks(achievements, progress);

        // Verify correct achievements are unlocked
        final unlockedIds = newlyUnlocked.map((a) => a.id).toSet();
        final expectedIds = testCase.expectedUnlocks.toSet();

        expect(
          unlockedIds,
          equals(expectedIds),
          reason:
              'Lessons ${testCase.lessons} should unlock: ${testCase.expectedUnlocks}',
        );

        // Verify all unlocked achievements have correct properties
        for (final achievement in newlyUnlocked) {
          expect(achievement.isUnlocked, isTrue);
          expect(achievement.unlockedAt, isNotNull);
          expect(achievement.progress, equals(1.0));
        }
      }
    });

    test('Property: Already unlocked achievements are not re-unlocked', () {
      const userId = 'test_user';
      const targetLanguage = 'en';

      // Create progress that meets multiple criteria
      final progress = Progress(
        userId: userId,
        targetLanguage: targetLanguage,
        totalXP: 1000,
        currentStreak: 30,
        longestStreak: 30,
        lessonsCompleted: 50,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Get all achievements and mark some as already unlocked
      final achievements = engine.getAchievementDefinitions(
        userId: userId,
        targetLanguage: targetLanguage,
      );

      final alreadyUnlocked = achievements
          .where((a) => a.criteria == AchievementCriteria.streak7Days)
          .map((a) => a.copyWith(
                isUnlocked: true,
                unlockedAt: DateTime.now().subtract(const Duration(days: 7)),
                progress: 1.0,
              ))
          .toList();

      final updatedAchievements = achievements.map((a) {
        if (a.criteria == AchievementCriteria.streak7Days) {
          return alreadyUnlocked.first;
        }
        return a;
      }).toList();

      // Check for new unlocks
      final newlyUnlocked =
          engine.checkForNewUnlocks(updatedAchievements, progress);

      // Verify already unlocked achievement is not in newly unlocked list
      final newlyUnlockedIds = newlyUnlocked.map((a) => a.id).toSet();
      expect(
        newlyUnlockedIds.contains(alreadyUnlocked.first.id),
        isFalse,
        reason: 'Already unlocked achievements should not be re-unlocked',
      );
    });

    test('Property: Progress calculation is accurate for locked achievements',
        () {
      const userId = 'test_user';
      const targetLanguage = 'en';

      // Test cases with partial progress - streak achievements
      final streakTestCases = [
        (streak: 3, criteria: AchievementCriteria.streak7Days, expected: 3 / 7),
        (
          streak: 15,
          criteria: AchievementCriteria.streak30Days,
          expected: 15 / 30
        ),
      ];

      for (final testCase in streakTestCases) {
        final progress = Progress(
          userId: userId,
          targetLanguage: targetLanguage,
          totalXP: 0,
          currentStreak: testCase.streak,
          longestStreak: testCase.streak,
          lessonsCompleted: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final achievements = engine.getAchievementDefinitions(
          userId: userId,
          targetLanguage: targetLanguage,
        );

        final achievement =
            achievements.firstWhere((a) => a.criteria == testCase.criteria);

        final calculatedProgress =
            engine.calculateProgress(achievement, progress);

        expect(
          calculatedProgress,
          closeTo(testCase.expected, 0.01),
          reason:
              'Progress for ${testCase.criteria} should be ${testCase.expected}',
        );
      }

      // Test cases with partial progress - XP achievements
      final xpTestCases = [
        (xp: 250, criteria: AchievementCriteria.xp500, expected: 250 / 500),
        (
          xp: 7500,
          criteria: AchievementCriteria.xp10000,
          expected: 7500 / 10000
        ),
      ];

      for (final testCase in xpTestCases) {
        final progress = Progress(
          userId: userId,
          targetLanguage: targetLanguage,
          totalXP: testCase.xp,
          currentStreak: 0,
          longestStreak: 0,
          lessonsCompleted: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final achievements = engine.getAchievementDefinitions(
          userId: userId,
          targetLanguage: targetLanguage,
        );

        final achievement =
            achievements.firstWhere((a) => a.criteria == testCase.criteria);

        final calculatedProgress =
            engine.calculateProgress(achievement, progress);

        expect(
          calculatedProgress,
          closeTo(testCase.expected, 0.01),
          reason:
              'Progress for ${testCase.criteria} should be ${testCase.expected}',
        );
      }

      // Test cases with partial progress - lesson achievements
      final lessonTestCases = [
        (
          lessons: 25,
          criteria: AchievementCriteria.lessons50,
          expected: 25 / 50
        ),
        (
          lessons: 300,
          criteria: AchievementCriteria.lessons500,
          expected: 300 / 500
        ),
      ];

      for (final testCase in lessonTestCases) {
        final progress = Progress(
          userId: userId,
          targetLanguage: targetLanguage,
          totalXP: 0,
          currentStreak: 0,
          longestStreak: 0,
          lessonsCompleted: testCase.lessons,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final achievements = engine.getAchievementDefinitions(
          userId: userId,
          targetLanguage: targetLanguage,
        );

        final achievement =
            achievements.firstWhere((a) => a.criteria == testCase.criteria);

        final calculatedProgress =
            engine.calculateProgress(achievement, progress);

        expect(
          calculatedProgress,
          closeTo(testCase.expected, 0.01),
          reason:
              'Progress for ${testCase.criteria} should be ${testCase.expected}',
        );
      }
    });

    test('Property: Bonus XP calculation is correct for unlocked achievements',
        () {
      const userId = 'test_user';
      const targetLanguage = 'en';

      // Create achievements with known bonus XP
      final achievements = engine.getAchievementDefinitions(
        userId: userId,
        targetLanguage: targetLanguage,
      );

      // Simulate unlocking specific achievements
      final unlockedAchievements = [
        achievements
            .firstWhere((a) => a.criteria == AchievementCriteria.streak7Days)
            .copyWith(isUnlocked: true, unlockedAt: DateTime.now()),
        achievements
            .firstWhere((a) => a.criteria == AchievementCriteria.xp500)
            .copyWith(isUnlocked: true, unlockedAt: DateTime.now()),
        achievements
            .firstWhere((a) => a.criteria == AchievementCriteria.lessons10)
            .copyWith(isUnlocked: true, unlockedAt: DateTime.now()),
      ];

      // Calculate total bonus XP
      final totalBonusXP = engine.calculateBonusXP(unlockedAchievements);

      // Expected: 50 (streak7) + 50 (xp500) + 50 (lessons10) = 150
      final expectedBonusXP =
          unlockedAchievements.fold(0, (sum, a) => sum + a.bonusXP);

      expect(
        totalBonusXP,
        equals(expectedBonusXP),
        reason: 'Total bonus XP should equal sum of individual bonuses',
      );
    });
  });
}
