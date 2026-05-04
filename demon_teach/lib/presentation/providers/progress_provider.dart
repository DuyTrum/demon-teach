import 'package:demon_teach/domain/entities/progress.dart';
import 'package:demon_teach/domain/repositories/progress_repository.dart';
import 'package:demon_teach/domain/usecases/progress/get_progress.dart';
import 'package:demon_teach/domain/usecases/progress/update_progress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Repository provider
final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  throw UnimplementedError('ProgressRepository must be overridden');
});

// Use case providers
final getProgressProvider = Provider<GetProgress>((ref) {
  return GetProgress(ref.watch(progressRepositoryProvider));
});

final updateProgressProvider = Provider<UpdateProgress>((ref) {
  // Note: ProgressTracker will be injected when we override the provider
  throw UnimplementedError('UpdateProgress must be overridden');
});

// Progress state
class ProgressState {
  final Progress? progress;
  final bool isLoading;
  final String? error;
  final bool isUpdating;

  const ProgressState({
    this.progress,
    this.isLoading = false,
    this.error,
    this.isUpdating = false,
  });

  ProgressState copyWith({
    Progress? progress,
    bool? isLoading,
    String? error,
    bool? isUpdating,
  }) {
    return ProgressState(
      progress: progress ?? this.progress,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isUpdating: isUpdating ?? this.isUpdating,
    );
  }
}

// Progress notifier
class ProgressNotifier extends StateNotifier<ProgressState> {
  final GetProgress _getProgress;
  final UpdateProgress _updateProgress;

  ProgressNotifier(
    this._getProgress,
    this._updateProgress,
  ) : super(const ProgressState());

  /// Load progress for user and target language
  Future<void> loadProgress({
    required String userId,
    required String targetLanguage,
  }) async {
    state = state.copyWith(isLoading: true);

    final result = await _getProgress(
      userId: userId,
      targetLanguage: targetLanguage,
    );

    result.when(
      success: (progress) {
        state = ProgressState(
          progress: progress,
          isLoading: false,
        );
      },
      failure: (failure) {
        state = ProgressState(
          isLoading: false,
          error: failure.message,
        );
      },
    );
  }

  /// Update progress after lesson completion
  Future<void> updateProgressAfterLesson({
    required String userId,
    required String targetLanguage,
    required int score,
  }) async {
    state = state.copyWith(isUpdating: true);

    final result = await _updateProgress(
      userId: userId,
      targetLanguage: targetLanguage,
      score: score,
    );

    result.when(
      success: (progress) {
        state = ProgressState(
          progress: progress,
          isUpdating: false,
        );
      },
      failure: (failure) {
        state = state.copyWith(
          isUpdating: false,
          error: failure.message,
        );
      },
    );
  }

  /// Refresh progress
  Future<void> refresh({
    required String userId,
    required String targetLanguage,
  }) async {
    await loadProgress(userId: userId, targetLanguage: targetLanguage);
  }
}

// Progress provider
final progressProvider =
    StateNotifierProvider<ProgressNotifier, ProgressState>((ref) {
  return ProgressNotifier(
    ref.watch(getProgressProvider),
    ref.watch(updateProgressProvider),
  );
});
