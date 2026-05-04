import 'package:demon_teach/domain/entities/quiz.dart';
import 'package:demon_teach/domain/repositories/quiz_repository.dart';
import 'package:demon_teach/domain/usecases/quiz/get_quiz.dart';
import 'package:demon_teach/domain/usecases/quiz/submit_quiz_answers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Repository provider
final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  throw UnimplementedError('QuizRepository must be overridden');
});

// Use case providers
final getQuizProvider = Provider<GetQuiz>((ref) {
  return GetQuiz(ref.watch(quizRepositoryProvider));
});

final submitQuizAnswersProvider = Provider<SubmitQuizAnswers>((ref) {
  return SubmitQuizAnswers(ref.watch(quizRepositoryProvider));
});

// Quiz state
class QuizState {
  final Quiz? quiz;
  final int currentQuestionIndex;
  final Map<String, String> userAnswers; // questionId -> answer
  final Map<String, bool> answeredCorrectly; // questionId -> isCorrect
  final bool isLoading;
  final String? error;
  final QuizResult? result;
  final bool isSubmitting;
  final bool showFeedback; // Show immediate feedback after answering

  const QuizState({
    this.quiz,
    this.currentQuestionIndex = 0,
    this.userAnswers = const {},
    this.answeredCorrectly = const {},
    this.isLoading = false,
    this.error,
    this.result,
    this.isSubmitting = false,
    this.showFeedback = false,
  });

  QuizQuestion? get currentQuestion {
    if (quiz == null ||
        currentQuestionIndex >= quiz!.questions.length ||
        currentQuestionIndex < 0) {
      return null;
    }
    return quiz!.questions[currentQuestionIndex];
  }

  bool get hasNext => currentQuestionIndex < (quiz?.questions.length ?? 0) - 1;
  bool get hasPrevious => currentQuestionIndex > 0;
  int get totalQuestions => quiz?.questions.length ?? 0;
  int get currentQuestionNumber => currentQuestionIndex + 1;
  bool get isLastQuestion => currentQuestionIndex == totalQuestions - 1;
  bool get allQuestionsAnswered =>
      userAnswers.length == totalQuestions && totalQuestions > 0;

  String? getUserAnswer(String questionId) => userAnswers[questionId];
  bool? isAnsweredCorrectly(String questionId) => answeredCorrectly[questionId];

  QuizState copyWith({
    Quiz? quiz,
    int? currentQuestionIndex,
    Map<String, String>? userAnswers,
    Map<String, bool>? answeredCorrectly,
    bool? isLoading,
    String? error,
    QuizResult? result,
    bool? isSubmitting,
    bool? showFeedback,
  }) {
    return QuizState(
      quiz: quiz ?? this.quiz,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      userAnswers: userAnswers ?? this.userAnswers,
      answeredCorrectly: answeredCorrectly ?? this.answeredCorrectly,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      result: result ?? this.result,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      showFeedback: showFeedback ?? this.showFeedback,
    );
  }
}

// Quiz notifier
class QuizNotifier extends StateNotifier<QuizState> {
  final GetQuiz _getQuiz;
  final SubmitQuizAnswers _submitQuizAnswers;

  QuizNotifier(
    this._getQuiz,
    this._submitQuizAnswers,
  ) : super(const QuizState());

  /// Load quiz for a lesson
  Future<void> loadQuiz(String lessonId) async {
    state = state.copyWith(isLoading: true);

    final result = await _getQuiz(lessonId);

    result.when(
      success: (quiz) {
        state = QuizState(
          quiz: quiz,
          currentQuestionIndex: 0,
          isLoading: false,
        );
      },
      failure: (failure) {
        state = QuizState(
          isLoading: false,
          error: failure.message,
        );
      },
    );
  }

  /// Answer current question
  void answerQuestion(String answer) {
    final currentQuestion = state.currentQuestion;
    if (currentQuestion == null) return;

    final isCorrect = answer.trim().toLowerCase() ==
        currentQuestion.correctAnswer.trim().toLowerCase();

    final newAnswers = Map<String, String>.from(state.userAnswers);
    newAnswers[currentQuestion.id] = answer;

    final newCorrectness = Map<String, bool>.from(state.answeredCorrectly);
    newCorrectness[currentQuestion.id] = isCorrect;

    state = state.copyWith(
      userAnswers: newAnswers,
      answeredCorrectly: newCorrectness,
      showFeedback: true,
    );
  }

  /// Go to next question
  void nextQuestion() {
    if (state.hasNext) {
      state = state.copyWith(
        currentQuestionIndex: state.currentQuestionIndex + 1,
        showFeedback: false,
      );
    }
  }

  /// Go to previous question
  void previousQuestion() {
    if (state.hasPrevious) {
      state = state.copyWith(
        currentQuestionIndex: state.currentQuestionIndex - 1,
        showFeedback: false,
      );
    }
  }

  /// Submit quiz
  Future<void> submitQuiz() async {
    if (state.quiz == null || !state.allQuestionsAnswered) return;

    state = state.copyWith(isSubmitting: true);

    // Create quiz answers
    final answers = state.quiz!.questions.map((question) {
      final userAnswer = state.userAnswers[question.id] ?? '';
      final isCorrect = state.answeredCorrectly[question.id] ?? false;
      final pointsEarned = isCorrect ? question.points : 0;

      return QuizAnswer(
        questionId: question.id,
        userAnswer: userAnswer,
        isCorrect: isCorrect,
        pointsEarned: pointsEarned,
      );
    }).toList();

    final result = await _submitQuizAnswers(
      quizId: state.quiz!.id,
      answers: answers,
    );

    result.when(
      success: (quizResult) {
        state = state.copyWith(
          result: quizResult,
          isSubmitting: false,
        );
      },
      failure: (failure) {
        state = state.copyWith(
          isSubmitting: false,
          error: failure.message,
        );
      },
    );
  }

  /// Reset quiz
  void reset() {
    state = QuizState(
      quiz: state.quiz,
      currentQuestionIndex: 0,
    );
  }

  /// Hide feedback
  void hideFeedback() {
    state = state.copyWith(showFeedback: false);
  }
}

// Quiz provider
final quizProvider = StateNotifierProvider<QuizNotifier, QuizState>((ref) {
  return QuizNotifier(
    ref.watch(getQuizProvider),
    ref.watch(submitQuizAnswersProvider),
  );
});
