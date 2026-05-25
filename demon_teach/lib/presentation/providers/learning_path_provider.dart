import 'package:demon_teach/domain/entities/learning_path.dart';
import 'package:demon_teach/domain/entities/assessment.dart';
import 'package:demon_teach/domain/entities/learning_goal.dart';
import 'package:demon_teach/domain/repositories/learning_path_repository.dart';
import 'package:demon_teach/domain/services/learning_path_generator.dart';
import 'package:demon_teach/domain/usecases/learning_path/generate_learning_path.dart';
import 'package:demon_teach/domain/usecases/learning_path/get_learning_path.dart';
import 'package:demon_teach/domain/usecases/learning_path/update_learning_path.dart';
import 'package:demon_teach/domain/usecases/learning_path/regenerate_learning_path.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Repository provider
final learningPathRepositoryProvider = Provider<LearningPathRepository>((ref) {
  throw UnimplementedError('LearningPathRepository must be overridden');
});

// Generator provider
final learningPathGeneratorProvider = Provider<LearningPathGenerator>((ref) {
  return LearningPathGenerator();
});

// Use case providers
final generateLearningPathProvider = Provider<GenerateLearningPath>((ref) {
  return GenerateLearningPath(
    ref.watch(learningPathRepositoryProvider),
    ref.watch(learningPathGeneratorProvider),
  );
});

final getLearningPathProvider = Provider<GetLearningPath>((ref) {
  return GetLearningPath(ref.watch(learningPathRepositoryProvider));
});

final updateLearningPathProvider = Provider<UpdateLearningPath>((ref) {
  return UpdateLearningPath(ref.watch(learningPathRepositoryProvider));
});

final regenerateLearningPathProvider = Provider<RegenerateLearningPath>((ref) {
  return RegenerateLearningPath(
    ref.watch(learningPathRepositoryProvider),
    ref.watch(learningPathGeneratorProvider),
  );
});

// Learning path state
class LearningPathState {
  final LearningPath? path;
  final bool isLoading;
  final String? error;
  final bool isGenerating;

  const LearningPathState({
    this.path,
    this.isLoading = false,
    this.error,
    this.isGenerating = false,
  });

  LearningPathState copyWith({
    LearningPath? path,
    bool? isLoading,
    String? error,
    bool? isGenerating,
  }) {
    return LearningPathState(
      path: path ?? this.path,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isGenerating: isGenerating ?? this.isGenerating,
    );
  }
}

// Learning path notifier
class LearningPathNotifier extends StateNotifier<LearningPathState> {
  final GenerateLearningPath _generateLearningPath;
  final GetLearningPath _getLearningPath;
  final UpdateLearningPath _updateLearningPath;
  final RegenerateLearningPath _regenerateLearningPath;

  LearningPathNotifier(
    this._generateLearningPath,
    this._getLearningPath,
    this._updateLearningPath,
    this._regenerateLearningPath,
  ) : super(const LearningPathState());

  /// Load learning path for user and language
  Future<void> loadLearningPath({
    required String userId,
    required String targetLanguage,
  }) async {
    state = state.copyWith(isLoading: true);

    final result = await _getLearningPath(
      userId: userId,
      targetLanguage: targetLanguage,
    );

    result.when(
      success: (path) {
        state = LearningPathState(path: path, isLoading: false);
      },
      failure: (failure) {
        state = LearningPathState(
          isLoading: false,
          error: failure.message,
        );
      },
    );
  }

  /// Generate a new learning path
  Future<bool> generatePath({
    required String userId,
    required String targetLanguage,
    required ProficiencyLevel proficiencyLevel,
    required GoalType goalType,
  }) async {
    state = state.copyWith(isGenerating: true);

    final result = await _generateLearningPath(
      userId: userId,
      targetLanguage: targetLanguage,
      proficiencyLevel: proficiencyLevel,
      goalType: goalType,
    );

    return result.when(
      success: (path) {
        state = LearningPathState(path: path, isGenerating: false);
        return true;
      },
      failure: (failure) {
        state = LearningPathState(
          path: state.path,
          isGenerating: false,
          error: failure.message,
        );
        return false;
      },
    );
  }

  /// Update learning path progress
  Future<bool> updateProgress({
    required String pathId,
    required int currentLessonIndex,
  }) async {
    if (state.path == null) return false;

    final result = await _updateLearningPath(
      pathId: pathId,
      currentLessonIndex: currentLessonIndex,
    );

    return result.when(
      success: (_) {
        // Update local state
        state = LearningPathState(
          path: state.path!.copyWith(
            currentLessonIndex: currentLessonIndex,
            lastModifiedAt: DateTime.now(),
          ),
        );
        return true;
      },
      failure: (failure) {
        state = state.copyWith(error: failure.message);
        return false;
      },
    );
  }

  /// Regenerate learning path with updated preferences
  Future<bool> regeneratePath({
    ProficiencyLevel? newProficiencyLevel,
    GoalType? newGoalType,
  }) async {
    if (state.path == null) return false;

    state = state.copyWith(isGenerating: true);

    final result = await _regenerateLearningPath(
      currentPath: state.path!,
      newProficiencyLevel: newProficiencyLevel,
      newGoalType: newGoalType,
    );

    return result.when(
      success: (path) {
        state = LearningPathState(path: path, isGenerating: false);
        return true;
      },
      failure: (failure) {
        state = LearningPathState(
          path: state.path,
          isGenerating: false,
          error: failure.message,
        );
        return false;
      },
    );
  }
}

// Learning path provider
final learningPathProvider =
    StateNotifierProvider<LearningPathNotifier, LearningPathState>((ref) {
  return LearningPathNotifier(
    ref.watch(generateLearningPathProvider),
    ref.watch(getLearningPathProvider),
    ref.watch(updateLearningPathProvider),
    ref.watch(regenerateLearningPathProvider),
  );
});
