import 'package:demon_teach/domain/entities/assessment.dart';
import 'package:demon_teach/domain/repositories/assessment_repository.dart';
import 'package:demon_teach/domain/services/assessment_engine.dart';
import 'package:demon_teach/domain/usecases/assessment/get_assessment.dart';
import 'package:demon_teach/domain/usecases/assessment/submit_assessment.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Repository provider
final assessmentRepositoryProvider = Provider<AssessmentRepository>((ref) {
  throw UnimplementedError('AssessmentRepository must be overridden');
});

// Assessment engine provider
final assessmentEngineProvider = Provider<AssessmentEngine>((ref) {
  return AssessmentEngine();
});

// Use case providers
final getAssessmentProvider = Provider<GetAssessment>((ref) {
  return GetAssessment(ref.watch(assessmentRepositoryProvider));
});

final submitAssessmentProvider = Provider<SubmitAssessment>((ref) {
  return SubmitAssessment(
    ref.watch(assessmentRepositoryProvider),
    ref.watch(assessmentEngineProvider),
  );
});

// Assessment state
class AssessmentState {
  final Assessment? assessment;
  final int currentQuestionIndex;
  final Map<String, String> userAnswers;
  final bool isLoading;
  final String? error;
  final AssessmentResult? result;

  AssessmentState({
    this.assessment,
    this.currentQuestionIndex = 0,
    this.userAnswers = const {},
    this.isLoading = false,
    this.error,
    this.result,
  });

  AssessmentState copyWith({
    Assessment? assessment,
    int? currentQuestionIndex,
    Map<String, String>? userAnswers,
    bool? isLoading,
    String? error,
    AssessmentResult? result,
  }) {
    return AssessmentState(
      assessment: assessment ?? this.assessment,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      userAnswers: userAnswers ?? this.userAnswers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      result: result ?? this.result,
    );
  }

  bool get isLastQuestion =>
      assessment != null &&
      currentQuestionIndex >= assessment!.questions.length - 1;

  AssessmentQuestion? get currentQuestion =>
      assessment?.questions[currentQuestionIndex];

  double get progress => assessment != null
      ? (currentQuestionIndex + 1) / assessment!.questions.length
      : 0.0;
}

// Assessment notifier
class AssessmentNotifier extends StateNotifier<AssessmentState> {
  final GetAssessment _getAssessment;
  final SubmitAssessment _submitAssessment;

  AssessmentNotifier(this._getAssessment, this._submitAssessment)
      : super(AssessmentState());

  Future<void> loadAssessment(String targetLanguage, String nativeLanguage) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getAssessment(targetLanguage, nativeLanguage);

    result.when(
      success: (assessment) {
        state = state.copyWith(
          assessment: assessment,
          isLoading: false,
          currentQuestionIndex: 0,
          userAnswers: {},
        );
      },
      failure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
      },
    );
  }

  void answerQuestion(String questionId, String answer) {
    final newAnswers = Map<String, String>.from(state.userAnswers);
    newAnswers[questionId] = answer;
    state = state.copyWith(userAnswers: newAnswers);
  }

  void nextQuestion() {
    if (!state.isLastQuestion) {
      state = state.copyWith(
        currentQuestionIndex: state.currentQuestionIndex + 1,
      );
    }
  }

  void previousQuestion() {
    if (state.currentQuestionIndex > 0) {
      state = state.copyWith(
        currentQuestionIndex: state.currentQuestionIndex - 1,
      );
    }
  }

  Future<void> submitAssessment(String userId, String targetLanguage) async {
    if (state.assessment == null) return;

    state = state.copyWith(isLoading: true, error: null);

    // Create assessment answers
    final answers = state.assessment!.questions.map((question) {
      final userAnswer = state.userAnswers[question.id] ?? '';
      final isCorrect = userAnswer == question.correctAnswer;
      return AssessmentAnswer(
        question: question,
        userAnswer: userAnswer,
        isCorrect: isCorrect,
      );
    }).toList();

    final result = await _submitAssessment(
      userId: userId,
      targetLanguage: targetLanguage,
      answers: answers,
    );

    result.when(
      success: (assessmentResult) {
        state = state.copyWith(
          result: assessmentResult,
          isLoading: false,
        );
      },
      failure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
      },
    );
  }

  void reset() {
    state = AssessmentState();
  }
}

// Assessment provider
final assessmentProvider =
    StateNotifierProvider<AssessmentNotifier, AssessmentState>((ref) {
  return AssessmentNotifier(
    ref.watch(getAssessmentProvider),
    ref.watch(submitAssessmentProvider),
  );
});
