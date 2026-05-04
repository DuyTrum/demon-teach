import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/learning_goal.dart';
import 'package:demon_teach/domain/repositories/goal_repository.dart';

/// Use case for saving learning goal preferences
class SaveGoalPreferences {
  final GoalRepository _repository;

  SaveGoalPreferences(this._repository);

  Future<Result<void>> call(LearningGoal goal) async {
    return await _repository.saveGoalPreferences(goal);
  }
}
