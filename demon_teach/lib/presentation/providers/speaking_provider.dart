import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:just_audio/just_audio.dart';
import 'package:demon_teach/core/di/injection_container.dart';
import 'package:demon_teach/domain/entities/speaking_exercise.dart';
import 'package:demon_teach/domain/repositories/speaking_repository.dart';
import 'package:demon_teach/domain/services/speaking_controller.dart';
import 'package:demon_teach/data/repositories/speaking_repository_impl.dart';

/// Provider for SpeakingRepository
final speakingRepositoryProvider = Provider<SpeakingRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SpeakingRepositoryImpl(prefs);
});

/// Provider for SpeakingController
final speakingControllerProvider = Provider<SpeakingController>((ref) {
  final dio = ref.watch(dioProvider);
  return SpeakingController(dio);
});

/// Provider for AudioPlayer (model audio)
final modelAudioPlayerProvider = Provider<AudioPlayer>((ref) {
  return AudioPlayer();
});

/// Provider for AudioPlayer (user recording)
final userAudioPlayerProvider = Provider<AudioPlayer>((ref) {
  return AudioPlayer();
});

/// State for speaking practice
class SpeakingState {
  final SpeakingExercise? exercise;
  final bool isLoading;
  final String? error;
  final bool isRecording;
  final bool isPlayingModel;
  final bool isPlayingUser;
  final bool isAnalyzing;
  final bool hasPermission;

  const SpeakingState({
    this.exercise,
    this.isLoading = false,
    this.error,
    this.isRecording = false,
    this.isPlayingModel = false,
    this.isPlayingUser = false,
    this.isAnalyzing = false,
    this.hasPermission = false,
  });

  SpeakingState copyWith({
    SpeakingExercise? exercise,
    bool? isLoading,
    String? error,
    bool? isRecording,
    bool? isPlayingModel,
    bool? isPlayingUser,
    bool? isAnalyzing,
    bool? hasPermission,
  }) {
    return SpeakingState(
      exercise: exercise ?? this.exercise,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isRecording: isRecording ?? this.isRecording,
      isPlayingModel: isPlayingModel ?? this.isPlayingModel,
      isPlayingUser: isPlayingUser ?? this.isPlayingUser,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      hasPermission: hasPermission ?? this.hasPermission,
    );
  }
}

/// Notifier for speaking practice
class SpeakingNotifier extends StateNotifier<SpeakingState> {
  final SpeakingRepository _repository;
  final SpeakingController _controller;
  final AudioPlayer _modelPlayer;
  final AudioPlayer _userPlayer;

  SpeakingNotifier(
    this._repository,
    this._controller,
    this._modelPlayer,
    this._userPlayer,
  ) : super(const SpeakingState()) {
    _initializePermission();
    _setupAudioListeners();
  }

  /// Initialize microphone permission
  Future<void> _initializePermission() async {
    final hasPermission = await _controller.hasPermission();
    state = state.copyWith(hasPermission: hasPermission);
  }

  /// Setup audio player listeners
  void _setupAudioListeners() {
    _modelPlayer.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed) {
        state = state.copyWith(isPlayingModel: false);
      }
    });

    _userPlayer.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed) {
        state = state.copyWith(isPlayingUser: false);
      }
    });
  }

  /// Load speaking exercise for a lesson
  Future<void> loadExercise(String lessonId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getSpeakingExercise(lessonId);

    if (result.isSuccess) {
      state = state.copyWith(
        exercise: result.value,
        isLoading: false,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.failure.message,
      );
    }
  }

  /// Request microphone permission
  Future<void> requestPermission() async {
    final result = await _controller.requestPermission();

    if (result.isSuccess) {
      state = state.copyWith(hasPermission: true, error: null);
    } else {
      state = state.copyWith(
        hasPermission: false,
        error: result.failure.message,
      );
    }
  }

  /// Play model audio
  Future<void> playModelAudio() async {
    if (state.exercise == null) return;

    try {
      // Stop user audio if playing
      if (state.isPlayingUser) {
        await _userPlayer.stop();
      }

      state = state.copyWith(isPlayingModel: true, error: null);

      // In a real app, this would load from URL
      // For now, we'll simulate playback
      await Future.delayed(const Duration(seconds: 2));

      state = state.copyWith(isPlayingModel: false);
    } catch (e) {
      state = state.copyWith(
        isPlayingModel: false,
        error: 'Failed to play model audio: ${e.toString()}',
      );
    }
  }

  /// Stop model audio
  Future<void> stopModelAudio() async {
    try {
      await _modelPlayer.stop();
      state = state.copyWith(isPlayingModel: false);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to stop audio: ${e.toString()}',
      );
    }
  }

  /// Start recording
  Future<void> startRecording() async {
    if (!state.hasPermission) {
      await requestPermission();
      if (!state.hasPermission) return;
    }

    // Stop any playing audio
    if (state.isPlayingModel) {
      await stopModelAudio();
    }
    if (state.isPlayingUser) {
      await stopUserAudio();
    }

    state = state.copyWith(isRecording: true, error: null);

    final result = await _controller.startRecording();

    if (!result.isSuccess) {
      state = state.copyWith(
        isRecording: false,
        error: result.failure.message,
      );
    }
  }

  /// Stop recording and analyze
  Future<void> stopRecording() async {
    if (!state.isRecording) return;

    state = state.copyWith(isRecording: false, isAnalyzing: true);

    final stopResult = await _controller.stopRecording();

    if (!stopResult.isSuccess) {
      state = state.copyWith(
        isAnalyzing: false,
        error: stopResult.failure.message,
      );
      return;
    }

    final recordingPath = stopResult.value;

    // Save recording to repository
    final saveResult = await _repository.saveRecording(
      state.exercise!.id,
      recordingPath,
    );

    if (!saveResult.isSuccess) {
      state = state.copyWith(
        isAnalyzing: false,
        error: saveResult.failure.message,
      );
      return;
    }

    // Analyze pronunciation
    final langCode = state.exercise!.lessonId.split('_').first;
    final analyzeResult = await _controller.analyzePronunciation(
      recordingPath,
      state.exercise!.phrase,
      language: langCode,
    );

    if (!analyzeResult.isSuccess) {
      state = state.copyWith(
        isAnalyzing: false,
        error: analyzeResult.failure.message,
      );
      return;
    }

    // Save feedback
    final feedbackResult = await _repository.saveFeedback(
      state.exercise!.id,
      analyzeResult.value,
    );

    if (feedbackResult.isSuccess) {
      state = state.copyWith(
        exercise: feedbackResult.value,
        isAnalyzing: false,
      );
    } else {
      state = state.copyWith(
        isAnalyzing: false,
        error: feedbackResult.failure.message,
      );
    }
  }

  /// Cancel recording
  Future<void> cancelRecording() async {
    await _controller.cancelRecording();
    state = state.copyWith(isRecording: false);
  }

  /// Play user recording
  Future<void> playUserRecording() async {
    final path = state.exercise?.userRecordingPath;
    if (path == null) return;

    try {
      // Stop model audio if playing
      if (state.isPlayingModel) {
        await _modelPlayer.stop();
      }

      state = state.copyWith(isPlayingUser: true, error: null);

      if (kIsWeb || path.startsWith('blob:') || path.startsWith('http')) {
        await _userPlayer.setUrl(path);
      } else {
        await _userPlayer.setFilePath(path);
      }
      await _userPlayer.play();
    } catch (e) {
      state = state.copyWith(
        isPlayingUser: false,
        error: 'Failed to play recording: ${e.toString()}',
      );
    }
  }

  /// Stop user recording playback
  Future<void> stopUserAudio() async {
    try {
      await _userPlayer.stop();
      state = state.copyWith(isPlayingUser: false);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to stop audio: ${e.toString()}',
      );
    }
  }

  /// Delete user recording
  Future<void> deleteRecording() async {
    if (state.exercise?.userRecordingPath == null) return;

    // Stop playback if playing
    if (state.isPlayingUser) {
      await stopUserAudio();
    }

    // Delete file
    await _controller.deleteRecordingFile(state.exercise!.userRecordingPath!);

    // Delete from repository
    final result = await _repository.deleteRecording(state.exercise!.id);

    if (result.isSuccess) {
      // Reload exercise to get updated state
      await loadExercise(state.exercise!.lessonId);
    } else {
      state = state.copyWith(error: result.failure.message);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _modelPlayer.dispose();
    _userPlayer.dispose();
    super.dispose();
  }
}

/// Provider for speaking practice state
final speakingProvider =
    StateNotifierProvider<SpeakingNotifier, SpeakingState>((ref) {
  final repository = ref.watch(speakingRepositoryProvider);
  final controller = ref.watch(speakingControllerProvider);
  final modelPlayer = ref.watch(modelAudioPlayerProvider);
  final userPlayer = ref.watch(userAudioPlayerProvider);

  return SpeakingNotifier(repository, controller, modelPlayer, userPlayer);
});
