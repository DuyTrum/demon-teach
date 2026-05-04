import 'package:demon_teach/domain/entities/lesson.dart';
import 'package:demon_teach/domain/repositories/lesson_repository.dart';
import 'package:demon_teach/domain/usecases/lesson/get_next_lesson.dart';
import 'package:demon_teach/domain/usecases/lesson/get_lesson_by_id.dart';
import 'package:demon_teach/domain/usecases/lesson/complete_lesson.dart';
import 'package:demon_teach/presentation/providers/learning_path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Repository provider
final lessonRepositoryProvider = Provider<LessonRepository>((ref) {
  throw UnimplementedError('LessonRepository must be overridden');
});

// Use case providers
final getNextLessonProvider = Provider<GetNextLesson>((ref) {
  return GetNextLesson(ref.watch(lessonRepositoryProvider));
});

final getLessonByIdProvider = Provider<GetLessonById>((ref) {
  return GetLessonById(ref.watch(lessonRepositoryProvider));
});

final completeLessonProvider = Provider<CompleteLesson>((ref) {
  return CompleteLesson(
    ref.watch(lessonRepositoryProvider),
    ref.watch(learningPathRepositoryProvider),
  );
});

// Lesson state
class LessonState {
  final Lesson? currentLesson;
  final bool isLoading;
  final String? error;
  final bool isCompleting;

  const LessonState({
    this.currentLesson,
    this.isLoading = false,
    this.error,
    this.isCompleting = false,
  });

  LessonState copyWith({
    Lesson? currentLesson,
    bool? isLoading,
    String? error,
    bool? isCompleting,
  }) {
    return LessonState(
      currentLesson: currentLesson ?? this.currentLesson,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isCompleting: isCompleting ?? this.isCompleting,
    );
  }
}

// Lesson notifier
class LessonNotifier extends StateNotifier<LessonState> {
  final GetNextLesson _getNextLesson;
  final GetLessonById _getLessonById;
  final CompleteLesson _completeLesson;

  LessonNotifier(
    this._getNextLesson,
    this._getLessonById,
    this._completeLesson,
  ) : super(const LessonState());

  /// Load next lesson for user
  Future<void> loadNextLesson({
    required String userId,
    required String targetLanguage,
  }) async {
    state = state.copyWith(isLoading: true);

    final result = await _getNextLesson(
      userId: userId,
      targetLanguage: targetLanguage,
    );

    result.when(
      success: (lesson) {
        state = LessonState(currentLesson: lesson, isLoading: false);
      },
      failure: (failure) {
        state = LessonState(
          isLoading: false,
          error: failure.message,
        );
      },
    );
  }

  /// Load specific lesson by ID
  Future<void> loadLessonById(String lessonId) async {
    state = state.copyWith(isLoading: true);

    final result = await _getLessonById(lessonId);

    result.when(
      success: (lesson) {
        state = LessonState(currentLesson: lesson, isLoading: false);
      },
      failure: (failure) {
        state = LessonState(
          isLoading: false,
          error: failure.message,
        );
      },
    );
  }

  /// Complete current lesson
  Future<bool> completeCurrentLesson({
    required String userId,
    required int score,
    required String targetLanguage,
  }) async {
    if (state.currentLesson == null) return false;

    state = state.copyWith(isCompleting: true);

    final result = await _completeLesson(
      userId: userId,
      lessonId: state.currentLesson!.metadata.id,
      score: score,
      targetLanguage: targetLanguage,
    );

    return result.when(
      success: (_) {
        // Update local state
        state = LessonState(
          currentLesson: state.currentLesson!.copyWith(
            status: LessonStatus.completed,
            completedAt: DateTime.now(),
            score: score,
          ),
          isCompleting: false,
        );
        return true;
      },
      failure: (failure) {
        state = state.copyWith(
          isCompleting: false,
          error: failure.message,
        );
        return false;
      },
    );
  }
}

// Lesson provider
final lessonProvider =
    StateNotifierProvider<LessonNotifier, LessonState>((ref) {
  return LessonNotifier(
    ref.watch(getNextLessonProvider),
    ref.watch(getLessonByIdProvider),
    ref.watch(completeLessonProvider),
  );
});
