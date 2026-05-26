import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:demon_teach/core/errors/failures.dart';
import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/learning_goal.dart';
import 'package:demon_teach/domain/repositories/goal_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Implementation of GoalRepository using Firestore
class GoalRepositoryImpl implements GoalRepository {
  final SharedPreferences _prefs;

  GoalRepositoryImpl(this._prefs);

  String? get _userId => _prefs.getString('current_user_id');

  @override
  Future<Result<void>> saveGoalPreferences(LearningGoal goal) async {
    try {
      if (!goal.isValidStudyTime) {
        return Result.failure(
          ValidationFailure(
            field: 'dailyStudyMinutes',
            message:
                'Daily study time must be between 5 and 30 minutes. Got: ${goal.dailyStudyMinutes}',
          ),
        );
      }

      final userId = _userId;
      if (userId == null) {
         // Fallback to shared prefs if not logged in
         await _prefs.setString('learning_goal_preferences', jsonEncode(goal.toJson()));
         return Result.success(null);
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('preferences')
          .doc('learning_goal')
          .set(goal.toJson());
          
      // Keep a local copy for immediate syncless access
      await _prefs.setString('learning_goal_preferences', jsonEncode(goal.toJson()));
      
      return Result.success(null);
    } catch (e) {
      return Result.failure(
        ServerFailure(message: 'Failed to save goal preferences: $e'),
      );
    }
  }

  @override
  Future<Result<LearningGoal?>> getGoalPreferences() async {
    try {
      final userId = _userId;
      if (userId != null) {
        try {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('preferences')
              .doc('learning_goal')
              .get();
              
          if (doc.exists && doc.data() != null) {
            final goal = LearningGoal.fromJson(doc.data()!);
            // Update local cache
            await _prefs.setString('learning_goal_preferences', jsonEncode(goal.toJson()));
            return Result.success(goal);
          }
        } catch (e) {
           print('Firestore fetch failed, falling back to local cache: $e');
        }
      }

      // Fallback to local cache
      final jsonString = _prefs.getString('learning_goal_preferences');
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
      await _prefs.remove('learning_goal_preferences');
      final userId = _userId;
      if (userId != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('preferences')
            .doc('learning_goal')
            .delete();
      }
      return Result.success(null);
    } catch (e) {
      return Result.failure(
        ServerFailure(message: 'Failed to clear goal preferences: $e'),
      );
    }
  }
}
