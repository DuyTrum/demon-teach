import 'package:demon_teach/domain/entities/entity.dart';

/// Question type for quiz
enum QuestionType {
  multipleChoice,
  fillInBlank,
  matching;

  String get displayName {
    switch (this) {
      case QuestionType.multipleChoice:
        return 'Multiple Choice';
      case QuestionType.fillInBlank:
        return 'Fill in the Blank';
      case QuestionType.matching:
        return 'Matching';
    }
  }
}

/// Quiz question entity
class QuizQuestion extends Entity {
  final String id;
  final QuestionType type;
  final String questionText;
  final List<String> options; // For multiple choice
  final String correctAnswer;
  final String explanation;
  final int points; // Points awarded for correct answer

  const QuizQuestion({
    required this.id,
    required this.type,
    required this.questionText,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    this.points = 10,
  });

  @override
  List<Object?> get props => [
        id,
        type,
        questionText,
        options,
        correctAnswer,
        explanation,
        points,
      ];

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'questionText': questionText,
      'options': options,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      'points': points,
    };
  }

  /// Create from JSON
  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    final content = json['content'] is Map<String, dynamic>
        ? json['content'] as Map<String, dynamic>
        : json;

    final typeStr = (json['type'] ?? '').toString().replaceAll('-', '').toLowerCase();
    QuestionType resolvedType = QuestionType.multipleChoice;
    for (final val in QuestionType.values) {
      if (val.name.toLowerCase() == typeStr ||
          val.name.replaceAll('-', '').toLowerCase() == typeStr) {
        resolvedType = val;
        break;
      }
    }

    final rawOptions = content['options'] ?? content['choices'] ?? [];
    final List<String> resolvedOptions = rawOptions is List
        ? rawOptions.map((o) => o.toString()).toList()
        : [];

    return QuizQuestion(
      id: (json['id'] ?? '').toString(),
      type: resolvedType,
      questionText: (content['questionText'] ?? content['question'] ?? '').toString(),
      options: resolvedOptions,
      correctAnswer: (content['correctAnswer'] ?? content['answer'] ?? '').toString(),
      explanation: (content['explanation'] ?? '').toString(),
      points: json['points'] as int? ?? 10,
    );
  }
}

/// Quiz entity
class Quiz extends Entity {
  final String id;
  final String lessonId;
  final String title;
  final List<QuizQuestion> questions;
  final int passingScore; // Minimum score to pass (percentage)

  const Quiz({
    required this.id,
    required this.lessonId,
    required this.title,
    required this.questions,
    this.passingScore = 60,
  });

  /// Get total possible points
  int get totalPoints => questions.fold(0, (sum, q) => sum + q.points);

  /// Get number of questions
  int get questionCount => questions.length;

  @override
  List<Object?> get props => [
        id,
        lessonId,
        title,
        questions,
        passingScore,
      ];

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lessonId': lessonId,
      'title': title,
      'questions': questions.map((q) => q.toJson()).toList(),
      'passingScore': passingScore,
    };
  }

  /// Create from JSON
  factory Quiz.fromJson(Map<String, dynamic> json) {
    final rawQuestions = json['questions'] ?? [];
    final List<QuizQuestion> resolvedQuestions = rawQuestions is List
        ? rawQuestions.map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>)).toList()
        : [];

    return Quiz(
      id: (json['id'] ?? '').toString(),
      lessonId: (json['lessonId'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      questions: resolvedQuestions,
      passingScore: json['passingScore'] as int? ?? 60,
    );
  }
}

/// User's answer to a quiz question
class QuizAnswer extends Entity {
  final String questionId;
  final String userAnswer;
  final bool isCorrect;
  final int pointsEarned;

  const QuizAnswer({
    required this.questionId,
    required this.userAnswer,
    required this.isCorrect,
    required this.pointsEarned,
  });

  @override
  List<Object?> get props => [
        questionId,
        userAnswer,
        isCorrect,
        pointsEarned,
      ];

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'userAnswer': userAnswer,
      'isCorrect': isCorrect,
      'pointsEarned': pointsEarned,
    };
  }

  /// Create from JSON
  factory QuizAnswer.fromJson(Map<String, dynamic> json) {
    return QuizAnswer(
      questionId: json['questionId'] as String,
      userAnswer: json['userAnswer'] as String,
      isCorrect: json['isCorrect'] as bool,
      pointsEarned: json['pointsEarned'] as int,
    );
  }
}

/// Quiz result entity
class QuizResult extends Entity {
  final String quizId;
  final List<QuizAnswer> answers;
  final int totalScore;
  final int maxScore;
  final double percentage;
  final bool passed;
  final DateTime completedAt;

  const QuizResult({
    required this.quizId,
    required this.answers,
    required this.totalScore,
    required this.maxScore,
    required this.percentage,
    required this.passed,
    required this.completedAt,
  });

  /// Get number of correct answers
  int get correctCount => answers.where((a) => a.isCorrect).length;

  /// Get number of incorrect answers
  int get incorrectCount => answers.where((a) => !a.isCorrect).length;

  @override
  List<Object?> get props => [
        quizId,
        answers,
        totalScore,
        maxScore,
        percentage,
        passed,
        completedAt,
      ];

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'quizId': quizId,
      'answers': answers.map((a) => a.toJson()).toList(),
      'totalScore': totalScore,
      'maxScore': maxScore,
      'percentage': percentage,
      'passed': passed,
      'completedAt': completedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(
      quizId: json['quizId'] as String,
      answers: (json['answers'] as List)
          .map((a) => QuizAnswer.fromJson(a as Map<String, dynamic>))
          .toList(),
      totalScore: json['totalScore'] as int,
      maxScore: json['maxScore'] as int,
      percentage: json['percentage'] as double,
      passed: json['passed'] as bool,
      completedAt: DateTime.parse(json['completedAt'] as String),
    );
  }
}
