import 'package:demon_teach/domain/entities/entity.dart';

/// Comprehension question for listening exercises
class ComprehensionQuestion extends Entity {
  final String id;
  final String questionText;
  final List<String> options;
  final String correctAnswer;
  final String explanation;

  const ComprehensionQuestion({
    required this.id,
    required this.questionText,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
  });

  @override
  List<Object?> get props => [
        id,
        questionText,
        options,
        correctAnswer,
        explanation,
      ];

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'questionText': questionText,
      'options': options,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
    };
  }

  /// Create from JSON
  factory ComprehensionQuestion.fromJson(Map<String, dynamic> json) {
    return ComprehensionQuestion(
      id: json['id'] as String,
      questionText: json['questionText'] as String,
      options: List<String>.from(json['options'] as List),
      correctAnswer: json['correctAnswer'] as String,
      explanation: json['explanation'] as String,
    );
  }
}

/// Listening exercise entity
class ListeningExercise extends Entity {
  final String id;
  final String lessonId;
  final String audioUrl;
  final int durationSeconds;
  final List<ComprehensionQuestion> questions;
  final bool hasPlayedOnce;

  const ListeningExercise({
    required this.id,
    required this.lessonId,
    required this.audioUrl,
    required this.durationSeconds,
    required this.questions,
    this.hasPlayedOnce = false,
  });

  /// Get number of questions
  int get questionCount => questions.length;

  @override
  List<Object?> get props => [
        id,
        lessonId,
        audioUrl,
        durationSeconds,
        questions,
        hasPlayedOnce,
      ];

  /// Create a copy with updated fields
  ListeningExercise copyWith({
    String? id,
    String? lessonId,
    String? audioUrl,
    int? durationSeconds,
    List<ComprehensionQuestion>? questions,
    bool? hasPlayedOnce,
  }) {
    return ListeningExercise(
      id: id ?? this.id,
      lessonId: lessonId ?? this.lessonId,
      audioUrl: audioUrl ?? this.audioUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      questions: questions ?? this.questions,
      hasPlayedOnce: hasPlayedOnce ?? this.hasPlayedOnce,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lessonId': lessonId,
      'audioUrl': audioUrl,
      'durationSeconds': durationSeconds,
      'questions': questions.map((q) => q.toJson()).toList(),
      'hasPlayedOnce': hasPlayedOnce,
    };
  }

  /// Create from JSON
  factory ListeningExercise.fromJson(Map<String, dynamic> json) {
    return ListeningExercise(
      id: json['id'] as String,
      lessonId: json['lessonId'] as String,
      audioUrl: json['audioUrl'] as String,
      durationSeconds: json['durationSeconds'] as int,
      questions: (json['questions'] as List)
          .map((q) => ComprehensionQuestion.fromJson(q as Map<String, dynamic>))
          .toList(),
      hasPlayedOnce: json['hasPlayedOnce'] as bool? ?? false,
    );
  }
}

/// User's answer to a comprehension question
class ComprehensionAnswer extends Entity {
  final String questionId;
  final String userAnswer;
  final bool isCorrect;

  const ComprehensionAnswer({
    required this.questionId,
    required this.userAnswer,
    required this.isCorrect,
  });

  @override
  List<Object?> get props => [
        questionId,
        userAnswer,
        isCorrect,
      ];

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'userAnswer': userAnswer,
      'isCorrect': isCorrect,
    };
  }

  /// Create from JSON
  factory ComprehensionAnswer.fromJson(Map<String, dynamic> json) {
    return ComprehensionAnswer(
      questionId: json['questionId'] as String,
      userAnswer: json['userAnswer'] as String,
      isCorrect: json['isCorrect'] as bool,
    );
  }
}

/// Listening exercise result entity
class ListeningResult extends Entity {
  final String exerciseId;
  final List<ComprehensionAnswer> answers;
  final int correctCount;
  final int totalQuestions;
  final double percentage;
  final DateTime completedAt;

  const ListeningResult({
    required this.exerciseId,
    required this.answers,
    required this.correctCount,
    required this.totalQuestions,
    required this.percentage,
    required this.completedAt,
  });

  /// Get number of incorrect answers
  int get incorrectCount => totalQuestions - correctCount;

  @override
  List<Object?> get props => [
        exerciseId,
        answers,
        correctCount,
        totalQuestions,
        percentage,
        completedAt,
      ];

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      'answers': answers.map((a) => a.toJson()).toList(),
      'correctCount': correctCount,
      'totalQuestions': totalQuestions,
      'percentage': percentage,
      'completedAt': completedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory ListeningResult.fromJson(Map<String, dynamic> json) {
    return ListeningResult(
      exerciseId: json['exerciseId'] as String,
      answers: (json['answers'] as List)
          .map((a) => ComprehensionAnswer.fromJson(a as Map<String, dynamic>))
          .toList(),
      correctCount: json['correctCount'] as int,
      totalQuestions: json['totalQuestions'] as int,
      percentage: (json['percentage'] as num).toDouble(),
      completedAt: DateTime.parse(json['completedAt'] as String),
    );
  }
}
