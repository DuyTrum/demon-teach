import 'package:flutter_test/flutter_test.dart';
import 'package:demon_teach/domain/entities/listening_exercise.dart';
import 'package:demon_teach/data/datasources/local/mock_listening_data.dart';

void main() {
  group('Listening Exercise Tests', () {
    test('Mock listening exercise should have correct structure for English',
        () {
      // Arrange
      const lessonId = 'en_basic_vocab_001';
      const targetLanguage = 'en';

      // Act
      final exercise = MockListeningData.getListeningExerciseForLanguage(
        lessonId,
        targetLanguage,
      );

      // Assert
      expect(exercise.id, 'listening_en_$lessonId');
      expect(exercise.lessonId, lessonId);
      expect(exercise.audioUrl, isNotEmpty);
      expect(exercise.durationSeconds, greaterThan(0));
      expect(exercise.durationSeconds, lessThanOrEqualTo(60));
      expect(exercise.questions.length, greaterThanOrEqualTo(3));
      expect(exercise.questions.length, lessThanOrEqualTo(5));
    });

    test('Mock listening exercise should have correct structure for Chinese',
        () {
      // Arrange
      const lessonId = 'zh_basic_vocab_001';
      const targetLanguage = 'zh';

      // Act
      final exercise = MockListeningData.getListeningExerciseForLanguage(
        lessonId,
        targetLanguage,
      );

      // Assert
      expect(exercise.id, 'listening_zh_$lessonId');
      expect(exercise.lessonId, lessonId);
      expect(exercise.audioUrl, isNotEmpty);
      expect(exercise.durationSeconds, greaterThan(0));
      expect(exercise.durationSeconds, lessThanOrEqualTo(60));
      expect(exercise.questions.length, greaterThanOrEqualTo(3));
      expect(exercise.questions.length, lessThanOrEqualTo(5));
    });

    test('Mock listening exercise should have correct structure for Korean',
        () {
      // Arrange
      const lessonId = 'ko_basic_vocab_001';
      const targetLanguage = 'ko';

      // Act
      final exercise = MockListeningData.getListeningExerciseForLanguage(
        lessonId,
        targetLanguage,
      );

      // Assert
      expect(exercise.id, 'listening_ko_$lessonId');
      expect(exercise.lessonId, lessonId);
      expect(exercise.audioUrl, isNotEmpty);
      expect(exercise.durationSeconds, greaterThan(0));
      expect(exercise.durationSeconds, lessThanOrEqualTo(60));
      expect(exercise.questions.length, greaterThanOrEqualTo(3));
      expect(exercise.questions.length, lessThanOrEqualTo(5));
    });

    test('Comprehension questions should have all required fields', () {
      // Arrange
      const lessonId = 'en_basic_vocab_001';
      const targetLanguage = 'en';

      // Act
      final exercise = MockListeningData.getListeningExerciseForLanguage(
        lessonId,
        targetLanguage,
      );

      // Assert
      for (final question in exercise.questions) {
        expect(question.id, isNotEmpty);
        expect(question.questionText, isNotEmpty);
        expect(question.options.length, greaterThanOrEqualTo(2));
        expect(question.correctAnswer, isNotEmpty);
        expect(question.options, contains(question.correctAnswer));
        expect(question.explanation, isNotEmpty);
      }
    });

    test('ListeningResult should calculate percentage correctly', () {
      // Arrange
      const exerciseId = 'listening_en_test';
      final answers = [
        const ComprehensionAnswer(
          questionId: 'q1',
          userAnswer: 'correct',
          isCorrect: true,
        ),
        const ComprehensionAnswer(
          questionId: 'q2',
          userAnswer: 'wrong',
          isCorrect: false,
        ),
        const ComprehensionAnswer(
          questionId: 'q3',
          userAnswer: 'correct',
          isCorrect: true,
        ),
        const ComprehensionAnswer(
          questionId: 'q4',
          userAnswer: 'correct',
          isCorrect: true,
        ),
      ];

      // Act
      final result = ListeningResult(
        exerciseId: exerciseId,
        answers: answers,
        correctCount: 3,
        totalQuestions: 4,
        percentage: 75.0,
        completedAt: DateTime.now(),
      );

      // Assert
      expect(result.correctCount, 3);
      expect(result.incorrectCount, 1);
      expect(result.percentage, 75.0);
      expect(result.totalQuestions, 4);
    });

    test('ListeningExercise should serialize and deserialize correctly', () {
      // Arrange
      const lessonId = 'en_basic_vocab_001';
      const targetLanguage = 'en';
      final originalExercise =
          MockListeningData.getListeningExerciseForLanguage(
        lessonId,
        targetLanguage,
      );

      // Act
      final json = originalExercise.toJson();
      final deserializedExercise = ListeningExercise.fromJson(json);

      // Assert
      expect(deserializedExercise.id, originalExercise.id);
      expect(deserializedExercise.lessonId, originalExercise.lessonId);
      expect(deserializedExercise.audioUrl, originalExercise.audioUrl);
      expect(deserializedExercise.durationSeconds,
          originalExercise.durationSeconds);
      expect(deserializedExercise.questions.length,
          originalExercise.questions.length);
    });

    test('ComprehensionAnswer should serialize and deserialize correctly', () {
      // Arrange
      const answer = ComprehensionAnswer(
        questionId: 'q1',
        userAnswer: 'test answer',
        isCorrect: true,
      );

      // Act
      final json = answer.toJson();
      final deserializedAnswer = ComprehensionAnswer.fromJson(json);

      // Assert
      expect(deserializedAnswer.questionId, answer.questionId);
      expect(deserializedAnswer.userAnswer, answer.userAnswer);
      expect(deserializedAnswer.isCorrect, answer.isCorrect);
    });

    test('ListeningResult should serialize and deserialize correctly', () {
      // Arrange
      final result = ListeningResult(
        exerciseId: 'listening_en_test',
        answers: const [
          ComprehensionAnswer(
            questionId: 'q1',
            userAnswer: 'answer1',
            isCorrect: true,
          ),
        ],
        correctCount: 1,
        totalQuestions: 1,
        percentage: 100.0,
        completedAt: DateTime.now(),
      );

      // Act
      final json = result.toJson();
      final deserializedResult = ListeningResult.fromJson(json);

      // Assert
      expect(deserializedResult.exerciseId, result.exerciseId);
      expect(deserializedResult.correctCount, result.correctCount);
      expect(deserializedResult.totalQuestions, result.totalQuestions);
      expect(deserializedResult.percentage, result.percentage);
      expect(deserializedResult.answers.length, result.answers.length);
    });
  });
}
