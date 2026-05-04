import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/learning_goal.dart';

/// Goal repository interface
abstract class GoalRepository {
  /// Save learning goal preferences
  Future<Result<void>> saveGoalPreferences(LearningGoal goal);

  /// Get saved learning goal preferences
  Future<Result<LearningGoal?>> getGoalPreferences();

  /// Clear goal preferences
  Future<Result<void>> clearGoalPreferences();
}
