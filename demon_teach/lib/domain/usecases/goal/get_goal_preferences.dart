import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/learning_goal.dart';
import 'package:demon_teach/domain/repositories/goal_repository.dart';

/// Use case for getting learning goal preferences
class GetGoalPreferences {
  final GoalRepository _repository;

  GetGoalPreferences(this._repository);

  Future<Result<LearningGoal?>> call() async {
    return await _repository.getGoalPreferences();
  }
}
