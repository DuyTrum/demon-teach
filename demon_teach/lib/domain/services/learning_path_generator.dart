import 'package:demon_teach/domain/entities/learning_path.dart';
import 'package:demon_teach/domain/entities/assessment.dart';
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
  }) {
    // Get lesson IDs based on proficiency and goal
    final lessonIds = _selectLessons(
      targetLanguage: targetLanguage,
      proficiencyLevel: proficiencyLevel,
      goalType: goalType,
    );

    return LearningPath(
      id: _uuid.v4(),
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
    ProficiencyLevel? newProficiencyLevel,
    GoalType? newGoalType,
  }) {
    final proficiencyLevel =
        newProficiencyLevel ?? currentPath.proficiencyLevel;
    final goalType = newGoalType ?? currentPath.goalType;

    // Get new lesson IDs
    final newLessonIds = _selectLessons(
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
    required String targetLanguage,
    required ProficiencyLevel proficiencyLevel,
    required GoalType goalType,
  }) {
    // Get base lessons for proficiency level
    final baseLessons = _getLessonsForProficiency(
      targetLanguage: targetLanguage,
      proficiencyLevel: proficiencyLevel,
    );

    // Prioritize lessons based on goal type
    final prioritizedLessons = _prioritizeLessonsByGoal(
      lessons: baseLessons,
      goalType: goalType,
    );

    return prioritizedLessons;
  }

  /// Get lessons for a specific proficiency level
  List<String> _getLessonsForProficiency({
    required String targetLanguage,
    required ProficiencyLevel proficiencyLevel,
  }) {
    // Lesson ID format: {language}_{level}_{category}_{number}
    // Example: en_basic_vocab_001, en_intermediate_grammar_005

    final prefix = '${targetLanguage.toLowerCase()}_${proficiencyLevel.name}';

    switch (proficiencyLevel) {
      case ProficiencyLevel.basic:
        return [
          '${prefix}_vocab_001', // Basic greetings
          '${prefix}_vocab_002', // Numbers and time
          '${prefix}_vocab_003', // Family and relationships
          '${prefix}_grammar_001', // Present tense
          '${prefix}_grammar_002', // Basic sentence structure
          '${prefix}_listening_001', // Simple conversations
          '${prefix}_speaking_001', // Self-introduction
          '${prefix}_vocab_004', // Food and drinks
          '${prefix}_vocab_005', // Daily activities
          '${prefix}_grammar_003', // Questions and answers
        ];

      case ProficiencyLevel.intermediate:
        return [
          '${prefix}_vocab_001', // Work and professions
          '${prefix}_vocab_002', // Travel and transportation
          '${prefix}_grammar_001', // Past tense
          '${prefix}_grammar_002', // Future tense
          '${prefix}_listening_001', // News and media
          '${prefix}_speaking_001', // Expressing opinions
          '${prefix}_vocab_003', // Health and wellness
          '${prefix}_grammar_003', // Conditional sentences
          '${prefix}_listening_002', // Interviews
          '${prefix}_speaking_002', // Presentations
        ];

      case ProficiencyLevel.advanced:
        return [
          '${prefix}_vocab_001', // Academic vocabulary
          '${prefix}_vocab_002', // Business terminology
          '${prefix}_grammar_001', // Complex sentence structures
          '${prefix}_grammar_002', // Idiomatic expressions
          '${prefix}_listening_001', // Lectures and speeches
          '${prefix}_speaking_001', // Debates and discussions
          '${prefix}_vocab_003', // Cultural references
          '${prefix}_grammar_003', // Advanced writing
          '${prefix}_listening_002', // Podcasts and documentaries
          '${prefix}_speaking_002', // Professional communication
        ];
    }
  }

  /// Prioritize lessons based on goal type
  /// Reorders lessons to emphasize relevant content for the goal
  List<String> _prioritizeLessonsByGoal({
    required List<String> lessons,
    required GoalType goalType,
  }) {
    // Create a copy to avoid modifying original list
    final prioritized = List<String>.from(lessons);

    // Define priority keywords for each goal type
    final priorityKeywords = _getPriorityKeywords(goalType);

    // Sort lessons: priority lessons first, then others
    prioritized.sort((a, b) {
      final aHasPriority =
          priorityKeywords.any((keyword) => a.contains(keyword));
      final bHasPriority =
          priorityKeywords.any((keyword) => b.contains(keyword));

      if (aHasPriority && !bHasPriority) return -1;
      if (!aHasPriority && bHasPriority) return 1;
      return 0; // Keep original order for same priority
    });

    return prioritized;
  }

  /// Get priority keywords for a goal type
  List<String> _getPriorityKeywords(GoalType goalType) {
    switch (goalType) {
      case GoalType.conversation:
        return ['speaking', 'listening', 'vocab'];
      case GoalType.exam:
        return ['grammar', 'vocab', 'listening'];
      case GoalType.work:
        return ['vocab', 'speaking', 'grammar'];
      case GoalType.travel:
        return ['vocab', 'speaking', 'listening'];
      case GoalType.hobby:
        return ['vocab', 'listening', 'speaking'];
    }
  }
}
