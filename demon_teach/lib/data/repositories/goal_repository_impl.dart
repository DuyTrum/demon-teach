import 'dart:convert';
import 'package:demon_teach/core/errors/failures.dart';
import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/learning_goal.dart';
import 'package:demon_teach/domain/repositories/goal_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Implementation of GoalRepository using SharedPreferences
class GoalRepositoryImpl implements GoalRepository {
  final SharedPreferences _prefs;
  static const String _goalKey = 'learning_goal_preferences';

  GoalRepositoryImpl(this._prefs);

  @override
  Future<Result<void>> saveGoalPreferences(LearningGoal goal) async {
    try {
      // Validate study time
      if (!goal.isValidStudyTime) {
        return Result.failure(
          ValidationFailure(
            field: 'dailyStudyMinutes',
            message:
                'Daily study time must be between 5 and 30 minutes. Got: ${goal.dailyStudyMinutes}',
          ),
        );
      }

      final jsonString = jsonEncode(goal.toJson());
      await _prefs.setString(_goalKey, jsonString);
      return Result.success(null);
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to save goal preferences: $e'),
      );
    }
  }

  @override
  Future<Result<LearningGoal?>> getGoalPreferences() async {
    try {
      final jsonString = _prefs.getString(_goalKey);
      if (jsonString == null) {
        return Result.success(null);
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final goal = LearningGoal.fromJson(json);
      return Result.success(goal);
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to get goal preferences: $e'),
      );
    }
  }

  @override
  Future<Result<void>> clearGoalPreferences() async {
    try {
      await _prefs.remove(_goalKey);
      return Result.success(null);
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to clear goal preferences: $e'),
      );
    }
  }
}
