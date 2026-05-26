import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:demon_teach/domain/entities/listening_exercise.dart';
import 'package:demon_teach/domain/repositories/listening_repository.dart';
import 'package:demon_teach/data/repositories/listening_repository_impl.dart';
import 'package:demon_teach/core/di/injection_container.dart';
import 'package:just_audio/just_audio.dart';

/// Provider for ListeningRepository
final listeningRepositoryProvider = Provider<ListeningRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ListeningRepositoryImpl(prefs);
});

/// State for listening exercise
class ListeningState {
  final ListeningExercise? exercise;
  final bool isLoading;
  final String? error;
  final bool isPlaying;
  final bool isPaused;
  final Duration currentPosition;
  final Duration totalDuration;
  final int currentQuestionIndex;
  final Map<String, String> userAnswers;
  final Map<String, bool> answeredCorrectly;
  final bool showFeedback;
  final ListeningResult? result;
  final bool isSubmitting;

  const ListeningState({
    this.exercise,
    this.isLoading = false,
    this.error,
    this.isPlaying = false,
    this.isPaused = false,
    this.currentPosition = Duration.zero,
    this.totalDuration = Duration.zero,
    this.currentQuestionIndex = 0,
    this.userAnswers = const {},
    this.answeredCorrectly = const {},
    this.showFeedback = false,
    this.result,
    this.isSubmitting = false,
  });

  ListeningState copyWith({
    ListeningExercise? exercise,
    bool? isLoading,
    String? error,
    bool? isPlaying,
    bool? isPaused,
    Duration? currentPosition,
    Duration? totalDuration,
    int? currentQuestionIndex,
    Map<String, String>? userAnswers,
    Map<String, bool>? answeredCorrectly,
    bool? showFeedback,
    ListeningResult? result,
    bool? isSubmitting,
  }) {
    return ListeningState(
      exercise: exercise ?? this.exercise,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isPlaying: isPlaying ?? this.isPlaying,
      isPaused: isPaused ?? this.isPaused,
      currentPosition: currentPosition ?? this.currentPosition,
      totalDuration: totalDuration ?? this.totalDuration,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      userAnswers: userAnswers ?? this.userAnswers,
      answeredCorrectly: answeredCorrectly ?? this.answeredCorrectly,
      showFeedback: showFeedback ?? this.showFeedback,
      result: result ?? this.result,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  ComprehensionQuestion? get currentQuestion {
    if (exercise == null ||
        currentQuestionIndex >= exercise!.questions.length) {
      return null;
    }
    return exercise!.questions[currentQuestionIndex];
  }

  int get totalQuestions => exercise?.questions.length ?? 0;
  int get currentQuestionNumber => currentQuestionIndex + 1;
  bool get hasNext => currentQuestionIndex < totalQuestions - 1;
  bool get isLastQuestion => currentQuestionIndex == totalQuestions - 1;
  bool get allQuestionsAnswered => userAnswers.length == totalQuestions;
  bool get canShowQuestions => exercise?.hasPlayedOnce ?? false;

  String? getUserAnswer(String questionId) => userAnswers[questionId];
  bool? isAnsweredCorrectly(String questionId) => answeredCorrectly[questionId];
}

/// Notifier for listening exercise state
class ListeningNotifier extends StateNotifier<ListeningState> {
  final ListeningRepository _repository;
  final AudioPlayer _audioPlayer;
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;

  ListeningNotifier(this._repository)
      : _audioPlayer = AudioPlayer(),
        super(const ListeningState()) {
    _setupAudioListeners();
  }

  void _setupAudioListeners() {
    // Listen to player state changes
    _playerStateSubscription = _audioPlayer.playerStateStream.listen((playerState) {
      if (!mounted) return;
      if (playerState.processingState == ProcessingState.completed) {
        state = state.copyWith(
          isPlaying: false,
          isPaused: false,
        );
        // Mark audio as played
        if (state.exercise != null) {
          _markAudioPlayed();
        }
      }
    });

    // Listen to position changes
    _positionSubscription = _audioPlayer.positionStream.listen((position) {
      if (!mounted) return;
      state = state.copyWith(currentPosition: position);
    });

    // Listen to duration changes
    _durationSubscription = _audioPlayer.durationStream.listen((duration) {
      if (!mounted) return;
      if (duration != null) {
        state = state.copyWith(totalDuration: duration);
      }
    });
  }

  Future<void> loadExercise(String lessonId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getListeningExerciseForLesson(lessonId);

    result.when(
      success: (exercise) {
        state = state.copyWith(
          exercise: exercise,
          isLoading: false,
        );
        // Preload audio
        _preloadAudio(exercise.audioUrl);
      },
      failure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
      },
    );
  }

  Future<void> _preloadAudio(String url) async {
    try {
      // For mock data, we'll simulate audio loading
      // In production, this would load the actual audio file
      await Future.delayed(const Duration(milliseconds: 500));

      // Set a mock duration based on the exercise duration
      if (state.exercise != null) {
        state = state.copyWith(
          totalDuration: Duration(seconds: state.exercise!.durationSeconds),
        );
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to load audio: ${e.toString()}',
      );
    }
  }

  Future<void> playAudio() async {
    try {
      if (state.isPaused) {
        // Resume playback
        await _audioPlayer.play();
        state = state.copyWith(isPlaying: true, isPaused: false);
      } else {
        // Start playback (simulated for mock data)
        state = state.copyWith(isPlaying: true, isPaused: false);

        // Simulate audio playback
        _simulateAudioPlayback();
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to play audio: ${e.toString()}',
        isPlaying: false,
      );
    }
  }

  Future<void> pauseAudio() async {
    try {
      await _audioPlayer.pause();
      state = state.copyWith(isPlaying: false, isPaused: true);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to pause audio: ${e.toString()}',
      );
    }
  }

  Future<void> stopAudio() async {
    try {
      await _audioPlayer.stop();
      state = state.copyWith(
        isPlaying: false,
        isPaused: false,
        currentPosition: Duration.zero,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to stop audio: ${e.toString()}',
      );
    }
  }

  Future<void> replayAudio() async {
    try {
      await _audioPlayer.seek(Duration.zero);
      await playAudio();
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to replay audio: ${e.toString()}',
      );
    }
  }

  void _simulateAudioPlayback() async {
    // Simulate audio playback for mock data
    final duration = state.totalDuration;
    final steps = 100;
    final stepDuration = duration.inMilliseconds ~/ steps;

    for (int i = 0; i <= steps; i++) {
      if (!state.isPlaying) break;

      await Future.delayed(Duration(milliseconds: stepDuration));

      if (mounted) {
        state = state.copyWith(
          currentPosition: Duration(
            milliseconds: (duration.inMilliseconds * i / steps).round(),
          ),
        );
      }
    }

    if (mounted && state.isPlaying) {
      state = state.copyWith(
        isPlaying: false,
        isPaused: false,
        currentPosition: duration,
      );
      _markAudioPlayed();
    }
  }

  Future<void> _markAudioPlayed() async {
    if (state.exercise != null && !state.exercise!.hasPlayedOnce) {
      await _repository.markAudioPlayed(state.exercise!.id);
      state = state.copyWith(
        exercise: state.exercise!.copyWith(hasPlayedOnce: true),
      );
    }
  }

  void answerQuestion(String answer) {
    final question = state.currentQuestion;
    if (question == null) return;

    final isCorrect = answer == question.correctAnswer;

    state = state.copyWith(
      userAnswers: {...state.userAnswers, question.id: answer},
      answeredCorrectly: {...state.answeredCorrectly, question.id: isCorrect},
      showFeedback: true,
    );
  }

  void nextQuestion() {
    if (state.hasNext) {
      state = state.copyWith(
        currentQuestionIndex: state.currentQuestionIndex + 1,
        showFeedback: false,
      );
    }
  }

  void previousQuestion() {
    if (state.currentQuestionIndex > 0) {
      state = state.copyWith(
        currentQuestionIndex: state.currentQuestionIndex - 1,
        showFeedback: state.userAnswers.containsKey(
          state.exercise!.questions[state.currentQuestionIndex - 1].id,
        ),
      );
    }
  }

  Future<void> submitExercise() async {
    if (!state.allQuestionsAnswered) return;

    state = state.copyWith(isSubmitting: true);

    // Create answers list
    final answers = state.exercise!.questions.map((question) {
      final userAnswer = state.userAnswers[question.id]!;
      final isCorrect = state.answeredCorrectly[question.id]!;

      return ComprehensionAnswer(
        questionId: question.id,
        userAnswer: userAnswer,
        isCorrect: isCorrect,
      );
    }).toList();

    final result = await _repository.submitListeningAnswers(
      state.exercise!.id,
      answers,
    );

    result.when(
      success: (listeningResult) {
        state = state.copyWith(
          result: listeningResult,
          isSubmitting: false,
        );
      },
      failure: (failure) {
        state = state.copyWith(
          error: failure.message,
          isSubmitting: false,
        );
      },
    );
  }

  void reset() {
    state = const ListeningState();
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}

/// Provider for listening exercise state
final listeningProvider =
    StateNotifierProvider<ListeningNotifier, ListeningState>((ref) {
  final repository = ref.watch(listeningRepositoryProvider);
  return ListeningNotifier(repository);
});
