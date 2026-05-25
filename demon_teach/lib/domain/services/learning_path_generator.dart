import 'package:demon_teach/domain/entities/learning_path.dart';
import 'package:demon_teach/domain/entities/assessment.dart';
import 'package:demon_teach/domain/entities/lesson.dart';
import 'package:demon_teach/domain/entities/learning_goal.dart';
import 'package:uuid/uuid.dart';

/// Service for generating personalized learning paths
class LearningPathGenerator {
  final _uuid = const Uuid();

  /// Generate a learning path based on proficiency level and goal type
  ///
  /// Algorithm:
  /// 1. Select lesson pool based on proficiency level
  /// 2. Prioritize lessons based on goal type
  /// 3. Order lessons from foundational to advanced
  /// 4. Return ordered list of lesson IDs
  LearningPath generatePath({
    required String userId,
    required String targetLanguage,
    required ProficiencyLevel proficiencyLevel,
    required GoalType goalType,
    required List<Lesson> availableLessons,
  }) {
    // Get lesson IDs based on proficiency and goal
    final lessonIds = _selectLessons(
      availableLessons: availableLessons,
      targetLanguage: targetLanguage,
      proficiencyLevel: proficiencyLevel,
      goalType: goalType,
    );

    return LearningPath(
      id: 'user_${userId}_$targetLanguage',
      userId: userId,
      targetLanguage: targetLanguage,
      proficiencyLevel: proficiencyLevel,
      goalType: goalType,
      lessonIds: lessonIds,
      currentLessonIndex: 0,
      createdAt: DateTime.now(),
    );
  }

  /// Regenerate learning path with updated preferences
  /// Preserves history by keeping completed lessons
  LearningPath regeneratePath({
    required LearningPath currentPath,
    required List<Lesson> availableLessons,
    ProficiencyLevel? newProficiencyLevel,
    GoalType? newGoalType,
  }) {
    final proficiencyLevel =
        newProficiencyLevel ?? currentPath.proficiencyLevel;
    final goalType = newGoalType ?? currentPath.goalType;

    // Get new lesson IDs
    final newLessonIds = _selectLessons(
      availableLessons: availableLessons,
      targetLanguage: currentPath.targetLanguage,
      proficiencyLevel: proficiencyLevel,
      goalType: goalType,
    );

    // Keep completed lessons (up to current index)
    final completedLessonIds =
        currentPath.lessonIds.take(currentPath.currentLessonIndex).toList();

    // Combine completed lessons with new lessons (avoid duplicates)
    final combinedLessonIds = [
      ...completedLessonIds,
      ...newLessonIds.where((id) => !completedLessonIds.contains(id)),
    ];

    return currentPath.copyWith(
      proficiencyLevel: proficiencyLevel,
      goalType: goalType,
      lessonIds: combinedLessonIds,
      lastModifiedAt: DateTime.now(),
    );
  }

  /// Select lessons based on proficiency level and goal type
  List<String> _selectLessons({
    required List<Lesson> availableLessons,
    required String targetLanguage,
    required ProficiencyLevel proficiencyLevel,
    required GoalType goalType,
  }) {
    // Filter base lessons for proficiency level
    final baseLessons = availableLessons.where((lesson) {
      // Map lesson difficulty to proficiency level
      final diffStr = lesson.metadata.difficulty.name;
      final lessonProficiency = _mapDifficultyToProficiency(diffStr);
      return lessonProficiency == proficiencyLevel || diffStr.isEmpty;
    }).toList();

    // If no lessons matched the level, fallback to all available
    final listToPrioritize = baseLessons.isNotEmpty ? baseLessons : availableLessons;

    // Prioritize lessons based on goal type
    final prioritizedLessons = _prioritizeLessonsByGoal(
      lessons: listToPrioritize,
      goalType: goalType,
    );

    return prioritizedLessons.map((l) => l.metadata.id).toList();
  }

  ProficiencyLevel _mapDifficultyToProficiency(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
      case 'elementary':
        return ProficiencyLevel.basic;
      case 'intermediate':
      case 'upperintermediate':
        return ProficiencyLevel.intermediate;
      case 'advanced':
      case 'master':
        return ProficiencyLevel.advanced;
      default:
        return ProficiencyLevel.basic;
    }
  }

  /// Prioritize lessons based on goal type
  /// Reorders lessons to emphasize relevant content for the goal
  List<Lesson> _prioritizeLessonsByGoal({
    required List<Lesson> lessons,
    required GoalType goalType,
  }) {
    // Create a copy to avoid modifying original list
    final prioritized = List<Lesson>.from(lessons);

    // Define priority keywords/categories for each goal type
    final priorityKeywords = _getPriorityKeywords(goalType);

    // Sort lessons: priority lessons first, then others
    prioritized.sort((a, b) {
      final aCat = a.metadata.category.name.toLowerCase();
      final bCat = b.metadata.category.name.toLowerCase();
      final aTitle = a.metadata.title.toLowerCase();
      final bTitle = b.metadata.title.toLowerCase();

      final aHasPriority = priorityKeywords.contains(aCat) || 
          priorityKeywords.any((keyword) => aTitle.contains(keyword));
      final bHasPriority = priorityKeywords.contains(bCat) || 
          priorityKeywords.any((keyword) => bTitle.contains(keyword));

      if (aHasPriority && !bHasPriority) return -1;
      if (!aHasPriority && bHasPriority) return 1;
      return 0; // Keep original order for same priority
    });

    // If not enough lessons to form a full path (e.g. 10), we can pad or duplicate if we really wanted to, 
    // but typically we just return what is available. 
    // The path screen will map them out. We'll return max 15 lessons.
    if (prioritized.length > 15) {
      return prioritized.sublist(0, 15);
    }
    return prioritized;
  }

  /// Get priority keywords for a goal type
  List<String> _getPriorityKeywords(GoalType goalType) {
    switch (goalType) {
      case GoalType.conversation:
        return ['speaking', 'listening', 'vocabulary', 'vocab'];
      case GoalType.exam:
        return ['grammar', 'vocabulary', 'vocab', 'listening'];
      case GoalType.work:
        return ['vocabulary', 'vocab', 'speaking', 'grammar', 'business', 'work'];
      case GoalType.travel:
        return ['vocabulary', 'vocab', 'speaking', 'listening', 'travel'];
      case GoalType.hobby:
        return ['vocabulary', 'vocab', 'listening', 'speaking'];
    }
  }
}
