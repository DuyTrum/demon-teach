import 'package:demon_teach/domain/entities/entity.dart';

/// Proficiency level enum
enum ProficiencyLevel {
  basic,
  intermediate,
  advanced;

  String get displayName {
    switch (this) {
      case ProficiencyLevel.basic:
        return 'Basic';
      case ProficiencyLevel.intermediate:
        return 'Intermediate';
      case ProficiencyLevel.advanced:
        return 'Advanced';
    }
  }
}

/// Question difficulty enum
enum QuestionDifficulty {
  easy,
  medium,
  hard;

  double get weight {
    switch (this) {
      case QuestionDifficulty.easy:
        return 1.0;
      case QuestionDifficulty.medium:
        return 2.0;
      case QuestionDifficulty.hard:
        return 3.0;
    }
  }
}

/// Assessment question entity
class AssessmentQuestion extends Entity {
  final String id;
  final String questionText;
  final List<String> options;
  final String correctAnswer;
  final QuestionDifficulty difficulty;
  final String category; // vocabulary, grammar, comprehension

  const AssessmentQuestion({
    required this.id,
    required this.questionText,
    required this.options,
    required this.correctAnswer,
    required this.difficulty,
    required this.category,
  });

  @override
  List<Object?> get props => [
        id,
        questionText,
        options,
        correctAnswer,
        difficulty,
        category,
      ];
}

/// Assessment answer entity
class AssessmentAnswer extends Entity {
  final AssessmentQuestion question;
  final String userAnswer;
  final bool isCorrect;

  const AssessmentAnswer({
    required this.question,
    required this.userAnswer,
    required this.isCorrect,
  });

  @override
  List<Object?> get props => [question, userAnswer, isCorrect];
}

/// Assessment entity
class Assessment extends Entity {
  final String id;
  final String targetLanguage;
  final List<AssessmentQuestion> questions;

  const Assessment({
    required this.id,
    required this.targetLanguage,
    required this.questions,
  });

  @override
  List<Object?> get props => [id, targetLanguage, questions];
}

/// Assessment result entity
class AssessmentResult extends Entity {
  final ProficiencyLevel proficiencyLevel;
  final double score;
  final int totalQuestions;
  final int correctAnswers;
  final List<AssessmentAnswer> answers;

  const AssessmentResult({
    required this.proficiencyLevel,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.answers,
  });

  double get percentage => (correctAnswers / totalQuestions) * 100;

  @override
  List<Object?> get props => [
        proficiencyLevel,
        score,
        totalQuestions,
        correctAnswers,
        answers,
      ];
}
