import 'package:demon_teach/domain/entities/learning_goal.dart';
import 'package:demon_teach/domain/repositories/goal_repository.dart';
import 'package:demon_teach/domain/usecases/goal/get_goal_preferences.dart';
import 'package:demon_teach/domain/usecases/goal/save_goal_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Repository provider
final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  throw UnimplementedError('GoalRepository must be overridden');
});

// Use case providers
final saveGoalPreferencesProvider = Provider<SaveGoalPreferences>((ref) {
  return SaveGoalPreferences(ref.watch(goalRepositoryProvider));
});

final getGoalPreferencesProvider = Provider<GetGoalPreferences>((ref) {
  return GetGoalPreferences(ref.watch(goalRepositoryProvider));
});

// Goal state
class GoalState {
  final LearningGoal? goal;
  final bool isLoading;
  final String? error;

  const GoalState({
    this.goal,
    this.isLoading = false,
    this.error,
  });

  GoalState copyWith({
    LearningGoal? goal,
    bool? isLoading,
    String? error,
  }) {
    return GoalState(
      goal: goal ?? this.goal,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Goal notifier
class GoalNotifier extends StateNotifier<GoalState> {
  final SaveGoalPreferences _saveGoalPreferences;
  final GetGoalPreferences _getGoalPreferences;

  GoalNotifier(this._saveGoalPreferences, this._getGoalPreferences)
      : super(const GoalState()) {
    loadGoalPreferences();
  }

  Future<void> loadGoalPreferences() async {
    state = state.copyWith(isLoading: true);

    final result = await _getGoalPreferences();

    result.when(
      success: (goal) {
        state = GoalState(goal: goal, isLoading: false);
      },
      failure: (failure) {
        state = GoalState(
          isLoading: false,
          error: failure.message,
        );
      },
    );
  }

  Future<bool> saveGoalPreferences(LearningGoal goal) async {
    state = state.copyWith(isLoading: true);

    final result = await _saveGoalPreferences(goal);

    return result.when(
      success: (_) {
        state = GoalState(goal: goal, isLoading: false);
        return true;
      },
      failure: (failure) {
        state = GoalState(
          goal: state.goal,
          isLoading: false,
          error: failure.message,
        );
        return false;
      },
    );
  }
}

// Goal provider
final goalProvider = StateNotifierProvider<GoalNotifier, GoalState>((ref) {
  return GoalNotifier(
    ref.watch(saveGoalPreferencesProvider),
    ref.watch(getGoalPreferencesProvider),
  );
});
