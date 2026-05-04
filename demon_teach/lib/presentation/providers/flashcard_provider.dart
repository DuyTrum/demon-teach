import 'package:demon_teach/domain/entities/flashcard.dart';
import 'package:demon_teach/domain/repositories/flashcard_repository.dart';
import 'package:demon_teach/domain/usecases/flashcard/get_flashcards_for_lesson.dart';
import 'package:demon_teach/domain/usecases/flashcard/mark_flashcard_difficulty.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Repository provider
final flashcardRepositoryProvider = Provider<FlashcardRepository>((ref) {
  throw UnimplementedError('FlashcardRepository must be overridden');
});

// Use case providers
final getFlashcardsForLessonProvider = Provider<GetFlashcardsForLesson>((ref) {
  return GetFlashcardsForLesson(ref.watch(flashcardRepositoryProvider));
});

final markFlashcardDifficultyProvider =
    Provider<MarkFlashcardDifficulty>((ref) {
  return MarkFlashcardDifficulty(ref.watch(flashcardRepositoryProvider));
});

// Flashcard state
class FlashcardState {
  final List<Flashcard> flashcards;
  final int currentIndex;
  final bool isFlipped;
  final bool isLoading;
  final String? error;
  final bool isMarkingDifficulty;

  const FlashcardState({
    this.flashcards = const [],
    this.currentIndex = 0,
    this.isFlipped = false,
    this.isLoading = false,
    this.error,
    this.isMarkingDifficulty = false,
  });

  Flashcard? get currentFlashcard {
    if (flashcards.isEmpty || currentIndex >= flashcards.length) {
      return null;
    }
    return flashcards[currentIndex];
  }

  bool get hasNext => currentIndex < flashcards.length - 1;
  bool get hasPrevious => currentIndex > 0;
  int get totalCards => flashcards.length;
  int get currentCardNumber => currentIndex + 1;

  FlashcardState copyWith({
    List<Flashcard>? flashcards,
    int? currentIndex,
    bool? isFlipped,
    bool? isLoading,
    String? error,
    bool? isMarkingDifficulty,
  }) {
    return FlashcardState(
      flashcards: flashcards ?? this.flashcards,
      currentIndex: currentIndex ?? this.currentIndex,
      isFlipped: isFlipped ?? this.isFlipped,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isMarkingDifficulty: isMarkingDifficulty ?? this.isMarkingDifficulty,
    );
  }
}

// Flashcard notifier
class FlashcardNotifier extends StateNotifier<FlashcardState> {
  final GetFlashcardsForLesson _getFlashcardsForLesson;
  final MarkFlashcardDifficulty _markFlashcardDifficulty;

  FlashcardNotifier(
    this._getFlashcardsForLesson,
    this._markFlashcardDifficulty,
  ) : super(const FlashcardState());

  /// Load flashcards for a lesson
  Future<void> loadFlashcards(String lessonId) async {
    state = state.copyWith(isLoading: true);

    final result = await _getFlashcardsForLesson(lessonId);

    result.when(
      success: (flashcards) {
        state = FlashcardState(
          flashcards: flashcards,
          currentIndex: 0,
          isFlipped: false,
          isLoading: false,
        );
      },
      failure: (failure) {
        state = FlashcardState(
          isLoading: false,
          error: failure.message,
        );
      },
    );
  }

  /// Flip the current card
  void flipCard() {
    state = state.copyWith(isFlipped: !state.isFlipped);
  }

  /// Go to next card
  void nextCard() {
    if (state.hasNext) {
      state = state.copyWith(
        currentIndex: state.currentIndex + 1,
        isFlipped: false,
      );
    }
  }

  /// Go to previous card
  void previousCard() {
    if (state.hasPrevious) {
      state = state.copyWith(
        currentIndex: state.currentIndex - 1,
        isFlipped: false,
      );
    }
  }

  /// Mark current flashcard difficulty
  Future<void> markDifficulty(DifficultyRating rating) async {
    final currentFlashcard = state.currentFlashcard;
    if (currentFlashcard == null) return;

    state = state.copyWith(isMarkingDifficulty: true);

    final result = await _markFlashcardDifficulty(
      flashcardId: currentFlashcard.id,
      rating: rating,
    );

    result.when(
      success: (_) {
        // Update the flashcard in the list with the new rating
        final updatedFlashcards = List<Flashcard>.from(state.flashcards);
        updatedFlashcards[state.currentIndex] = currentFlashcard.copyWith(
          userRating: rating,
          lastReviewed: DateTime.now(),
        );

        state = state.copyWith(
          flashcards: updatedFlashcards,
          isMarkingDifficulty: false,
        );

        // Auto-advance to next card after marking difficulty
        if (state.hasNext) {
          Future.delayed(const Duration(milliseconds: 500), () {
            nextCard();
          });
        }
      },
      failure: (failure) {
        state = state.copyWith(
          isMarkingDifficulty: false,
          error: failure.message,
        );
      },
    );
  }

  /// Reset to first card
  void reset() {
    state = state.copyWith(
      currentIndex: 0,
      isFlipped: false,
    );
  }
}

// Flashcard provider
final flashcardProvider =
    StateNotifierProvider<FlashcardNotifier, FlashcardState>((ref) {
  return FlashcardNotifier(
    ref.watch(getFlashcardsForLessonProvider),
    ref.watch(markFlashcardDifficultyProvider),
  );
});
