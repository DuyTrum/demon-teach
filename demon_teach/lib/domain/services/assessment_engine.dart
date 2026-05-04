import 'package:demon_teach/domain/entities/assessment.dart';

/// Assessment engine for calculating proficiency level
///
/// Algorithm:
/// - Each question has a weight based on difficulty (easy: 1.0, medium: 2.0, hard: 3.0)
/// - Calculate weighted score: sum of (weight * isCorrect)
/// - Calculate percentage: (totalScore / maxScore) * 100
/// - Classify proficiency:
///   - >= 75%: Advanced
///   - >= 45%: Intermediate
///   - < 45%: Basic
class AssessmentEngine {
  /// Calculate proficiency level from assessment answers
  ProficiencyLevel calculateProficiency(List<AssessmentAnswer> answers) {
    if (answers.isEmpty) {
      throw ArgumentError('Assessment answers cannot be empty');
    }

    double totalScore = 0.0;
    double maxScore = 0.0;

    for (final answer in answers) {
      final weight = answer.question.difficulty.weight;
      maxScore += weight;
      if (answer.isCorrect) {
        totalScore += weight;
      }
    }

    final percentage = (totalScore / maxScore) * 100;

    if (percentage >= 75.0) {
      return ProficiencyLevel.advanced;
    } else if (percentage >= 45.0) {
      return ProficiencyLevel.intermediate;
    } else {
      return ProficiencyLevel.basic;
    }
  }

  /// Calculate assessment result
  AssessmentResult calculateResult(List<AssessmentAnswer> answers) {
    if (answers.isEmpty) {
      throw ArgumentError('Assessment answers cannot be empty');
    }

    final proficiencyLevel = calculateProficiency(answers);
    final totalQuestions = answers.length;
    final correctAnswers = answers.where((a) => a.isCorrect).length;

    double totalScore = 0.0;
    double maxScore = 0.0;

    for (final answer in answers) {
      final weight = answer.question.difficulty.weight;
      maxScore += weight;
      if (answer.isCorrect) {
        totalScore += weight;
      }
    }

    final score = (totalScore / maxScore) * 100;

    return AssessmentResult(
      proficiencyLevel: proficiencyLevel,
      score: score,
      totalQuestions: totalQuestions,
      correctAnswers: correctAnswers,
      answers: answers,
    );
  }
}
