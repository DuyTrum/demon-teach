import 'dart:async';
import 'package:demon_teach/core/constants/app_constants.dart';
import 'package:demon_teach/domain/entities/progress.dart';
import 'package:demon_teach/domain/repositories/progress_repository.dart';
import 'package:demon_teach/domain/usecases/progress/get_progress.dart';
import 'package:demon_teach/domain/usecases/progress/update_progress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:demon_teach/core/services/audio_feedback_service.dart';

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

class ProgressNotifier extends StateNotifier<ProgressState> {
  final GetProgress _getProgress;
  final UpdateProgress _updateProgress;
  final ProgressRepository _repository;
  final AudioFeedbackService? _audioService;
  Timer? _regenTimer;

  ProgressNotifier(
    this._getProgress,
    this._updateProgress,
    this._repository, [
    this._audioService,
  ]) : super(const ProgressState()) {
    // Start periodic heart check timer every 10 seconds
    _regenTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _checkLocalHeartRegen();
    });
  }

  @override
  void dispose() {
    _regenTimer?.cancel();
    super.dispose();
  }

  void _checkLocalHeartRegen() {
    final progress = state.progress;
    if (progress == null || progress.hearts >= AppConstants.maxHearts) return;

    final now = DateTime.now();
    if (now.isBefore(progress.lastHeartRegenTime)) return;

    final interval = AppConstants.heartRegenInterval;
    final difference = now.difference(progress.lastHeartRegenTime);
    final heartsToRegen = difference.inSeconds ~/ interval.inSeconds;

    if (heartsToRegen > 0) {
      refresh(userId: progress.userId, targetLanguage: progress.targetLanguage);
    }
  }

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

  /// Consume 1 heart (called when incorrect final submission is made)
  Future<void> consumeHeart({
    required String userId,
    required String targetLanguage,
  }) async {
    final progress = state.progress;
    if (progress == null || progress.hearts <= 0) return;

    final result = await _repository.consumeHeart(userId, targetLanguage);

    result.when(
      success: (updatedProgress) {
        state = state.copyWith(progress: updatedProgress);
        _audioService?.playLoseHeartSfx();
      },
      failure: (failure) {
        state = state.copyWith(error: failure.message);
      },
    );
  }

  /// Refill 1 heart using 100 souls
  Future<bool> refillHeartWithSouls({
    required String userId,
    required String targetLanguage,
  }) async {
    state = state.copyWith(isUpdating: true);

    final result = await _repository.refillHeartWithSouls(userId, targetLanguage);

    return result.when(
      success: (updatedProgress) {
        state = ProgressState(
          progress: updatedProgress,
          isUpdating: false,
        );
        return true;
      },
      failure: (failure) {
        state = state.copyWith(
          isUpdating: false,
          error: failure.message,
        );
        return false;
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
    ref.watch(progressRepositoryProvider),
    ref.watch(audioFeedbackServiceProvider),
  );
});
