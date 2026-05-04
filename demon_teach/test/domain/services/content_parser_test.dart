import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:demon_teach/domain/entities/flashcard.dart';
import 'package:demon_teach/domain/entities/listening_exercise.dart';
import 'package:demon_teach/domain/entities/quiz.dart';
import 'package:demon_teach/domain/entities/speaking_exercise.dart';
import 'package:demon_teach/domain/services/content_parser.dart';

void main() {
  group('ContentParser', () {
    late ContentParser parser;

    setUp(() {
      parser = ContentParser();
    });

    group('parse', () {
      test('should successfully parse valid minimal content', () {
        final json = jsonEncode({
          'flashcards': [
            {
              'id': 'f1',
              'lessonId': 'l1',
              'frontText': 'Hello',
              'backText': 'Xin chào',
              'exampleUsage': 'Hello, how are you?',
            }
          ],
          'quiz': {
            'id': 'q1',
            'lessonId': 'l1',
            'title': 'Test Quiz',
            'questions': [
              {
                'id': 'q1',
                'type': 'multipleChoice',
                'questionText': 'What is hello?',
                'options': ['Xin chào', 'Goodbye'],
                'correctAnswer': 'Xin chào',
                'explanation': 'Hello means Xin chào',
              }
            ],
          },
        });

        final result = parser.parse(json);

        expect(result.isSuccess, isTrue);
        expect(result.value.flashcards.length, equals(1));
        expect(result.value.flashcards[0].frontText, equals('Hello'));
        expect(result.value.quiz.questions.length, equals(1));
      });

      test('should successfully parse content with all optional fields', () {
        final json = jsonEncode({
          'flashcards': [
            {
              'id': 'f1',
              'lessonId': 'l1',
              'frontText': 'Hello',
              'backText': 'Xin chào',
              'exampleUsage': 'Hello, how are you?',
              'audioUrl': 'https://example.com/audio.mp3',
            }
          ],
          'listeningExercise': {
            'id': 'le1',
            'lessonId': 'l1',
            'audioUrl': 'https://example.com/listening.mp3',
            'durationSeconds': 30,
            'questions': [
              {
                'id': 'cq1',
                'questionText': 'What did you hear?',
                'options': ['Hello', 'Goodbye'],
                'correctAnswer': 'Hello',
                'explanation': 'The audio said hello',
              }
            ],
          },
          'quiz': {
            'id': 'q1',
            'lessonId': 'l1',
            'title': 'Test Quiz',
            'questions': [
              {
                'id': 'q1',
                'type': 'multipleChoice',
                'questionText': 'What is hello?',
                'options': ['Xin chào', 'Goodbye'],
                'correctAnswer': 'Xin chào',
                'explanation': 'Hello means Xin chào',
              }
            ],
          },
          'speakingExercise': {
            'id': 'se1',
            'lessonId': 'l1',
            'phrase': 'Hello, nice to meet you',
            'modelAudioUrl': 'https://example.com/model.mp3',
          },
        });

        final result = parser.parse(json);

        expect(result.isSuccess, isTrue);
        expect(result.value.listeningExercise, isNotNull);
        expect(result.value.speakingExercise, isNotNull);
      });

      test('should fail when flashcards field is missing', () {
        final json = jsonEncode({
          'quiz': {
            'id': 'q1',
            'lessonId': 'l1',
            'title': 'Test Quiz',
            'questions': [
              {
                'id': 'q1',
                'type': 'multipleChoice',
                'questionText': 'What is hello?',
                'options': ['Xin chào', 'Goodbye'],
                'correctAnswer': 'Xin chào',
                'explanation': 'Hello means Xin chào',
              }
            ],
          },
        });

        final result = parser.parse(json);

        expect(result.isFailure, isTrue);
        expect(result.failure.message, contains('flashcards'));
      });

      test('should fail when quiz field is missing', () {
        final json = jsonEncode({
          'flashcards': [
            {
              'id': 'f1',
              'lessonId': 'l1',
              'frontText': 'Hello',
              'backText': 'Xin chào',
              'exampleUsage': 'Hello, how are you?',
            }
          ],
        });

        final result = parser.parse(json);

        expect(result.isFailure, isTrue);
        expect(result.failure.message, contains('quiz'));
      });

      test('should fail when flashcards array is empty', () {
        final json = jsonEncode({
          'flashcards': [],
          'quiz': {
            'id': 'q1',
            'lessonId': 'l1',
            'title': 'Test Quiz',
            'questions': [
              {
                'id': 'q1',
                'type': 'multipleChoice',
                'questionText': 'What is hello?',
                'options': ['Xin chào', 'Goodbye'],
                'correctAnswer': 'Xin chào',
                'explanation': 'Hello means Xin chào',
              }
            ],
          },
        });

        final result = parser.parse(json);

        expect(result.isFailure, isTrue);
        expect(result.failure.message,
            contains('flashcards array cannot be empty'));
      });

      test('should fail when flashcard is missing required fields', () {
        final json = jsonEncode({
          'flashcards': [
            {
              'id': 'f1',
              'lessonId': 'l1',
              // Missing frontText, backText, exampleUsage
            }
          ],
          'quiz': {
            'id': 'q1',
            'lessonId': 'l1',
            'title': 'Test Quiz',
            'questions': [
              {
                'id': 'q1',
                'type': 'multipleChoice',
                'questionText': 'What is hello?',
                'options': ['Xin chào', 'Goodbye'],
                'correctAnswer': 'Xin chào',
                'explanation': 'Hello means Xin chào',
              }
            ],
          },
        });

        final result = parser.parse(json);

        expect(result.isFailure, isTrue);
        expect(result.failure.message, contains('frontText'));
        expect(result.failure.message, contains('backText'));
        expect(result.failure.message, contains('exampleUsage'));
      });

      test('should fail when audioUrl is not a valid URL', () {
        final json = jsonEncode({
          'flashcards': [
            {
              'id': 'f1',
              'lessonId': 'l1',
              'frontText': 'Hello',
              'backText': 'Xin chào',
              'exampleUsage': 'Hello, how are you?',
              'audioUrl': 'not-a-valid-url',
            }
          ],
          'quiz': {
            'id': 'q1',
            'lessonId': 'l1',
            'title': 'Test Quiz',
            'questions': [
              {
                'id': 'q1',
                'type': 'multipleChoice',
                'questionText': 'What is hello?',
                'options': ['Xin chào', 'Goodbye'],
                'correctAnswer': 'Xin chào',
                'explanation': 'Hello means Xin chào',
              }
            ],
          },
        });

        final result = parser.parse(json);

        expect(result.isFailure, isTrue);
        expect(result.failure.message, contains('audioUrl is not a valid URL'));
      });

      test('should fail when quiz questions array is empty', () {
        final json = jsonEncode({
          'flashcards': [
            {
              'id': 'f1',
              'lessonId': 'l1',
              'frontText': 'Hello',
              'backText': 'Xin chào',
              'exampleUsage': 'Hello, how are you?',
            }
          ],
          'quiz': {
            'id': 'q1',
            'lessonId': 'l1',
            'title': 'Test Quiz',
            'questions': [],
          },
        });

        final result = parser.parse(json);

        expect(result.isFailure, isTrue);
        expect(result.failure.message,
            contains('questions array cannot be empty'));
      });

      test('should fail when JSON is malformed', () {
        const json = '{invalid json}';

        final result = parser.parse(json);

        expect(result.isFailure, isTrue);
        expect(result.failure.message, contains('Invalid JSON format'));
      });

      test('should fail when root is not an object', () {
        const json = '["array", "not", "object"]';

        final result = parser.parse(json);

        expect(result.isFailure, isTrue);
        expect(
            result.failure.message, contains('Content must be a JSON object'));
      });

      test('should fail when quiz question type is invalid', () {
        final json = jsonEncode({
          'flashcards': [
            {
              'id': 'f1',
              'lessonId': 'l1',
              'frontText': 'Hello',
              'backText': 'Xin chào',
              'exampleUsage': 'Hello, how are you?',
            }
          ],
          'quiz': {
            'id': 'q1',
            'lessonId': 'l1',
            'title': 'Test Quiz',
            'questions': [
              {
                'id': 'q1',
                'type': 'invalidType',
                'questionText': 'What is hello?',
                'options': ['Xin chào', 'Goodbye'],
                'correctAnswer': 'Xin chào',
                'explanation': 'Hello means Xin chào',
              }
            ],
          },
        });

        final result = parser.parse(json);

        expect(result.isFailure, isTrue);
        expect(result.failure.message, contains('type must be one of'));
      });
    });

    group('prettyPrint', () {
      test('should successfully serialize valid content', () {
        final content = LessonContent(
          flashcards: [
            const Flashcard(
              id: 'f1',
              lessonId: 'l1',
              frontText: 'Hello',
              backText: 'Xin chào',
              exampleUsage: 'Hello, how are you?',
            ),
          ],
          quiz: Quiz(
            id: 'q1',
            lessonId: 'l1',
            title: 'Test Quiz',
            questions: [
              const QuizQuestion(
                id: 'q1',
                type: QuestionType.multipleChoice,
                questionText: 'What is hello?',
                options: ['Xin chào', 'Goodbye'],
                correctAnswer: 'Xin chào',
                explanation: 'Hello means Xin chào',
              ),
            ],
          ),
        );

        final result = parser.prettyPrint(content);

        expect(result.isSuccess, isTrue);
        expect(result.value, contains('flashcards'));
        expect(result.value, contains('quiz'));
        expect(result.value, contains('Hello'));
      });

      test('should format JSON with proper indentation', () {
        final content = LessonContent(
          flashcards: [
            const Flashcard(
              id: 'f1',
              lessonId: 'l1',
              frontText: 'Hello',
              backText: 'Xin chào',
              exampleUsage: 'Hello, how are you?',
            ),
          ],
          quiz: Quiz(
            id: 'q1',
            lessonId: 'l1',
            title: 'Test Quiz',
            questions: [
              const QuizQuestion(
                id: 'q1',
                type: QuestionType.multipleChoice,
                questionText: 'What is hello?',
                options: ['Xin chào', 'Goodbye'],
                correctAnswer: 'Xin chào',
                explanation: 'Hello means Xin chào',
              ),
            ],
          ),
        );

        final result = parser.prettyPrint(content);

        expect(result.isSuccess, isTrue);
        // Check for indentation (2 spaces)
        expect(result.value, contains('  "flashcards"'));
        expect(result.value, contains('  "quiz"'));
      });

      test('should include optional fields when present', () {
        final content = LessonContent(
          flashcards: [
            const Flashcard(
              id: 'f1',
              lessonId: 'l1',
              frontText: 'Hello',
              backText: 'Xin chào',
              exampleUsage: 'Hello, how are you?',
              audioUrl: 'https://example.com/audio.mp3',
            ),
          ],
          listeningExercise: const ListeningExercise(
            id: 'le1',
            lessonId: 'l1',
            audioUrl: 'https://example.com/listening.mp3',
            durationSeconds: 30,
            questions: [
              ComprehensionQuestion(
                id: 'cq1',
                questionText: 'What did you hear?',
                options: ['Hello', 'Goodbye'],
                correctAnswer: 'Hello',
                explanation: 'The audio said hello',
              ),
            ],
          ),
          quiz: Quiz(
            id: 'q1',
            lessonId: 'l1',
            title: 'Test Quiz',
            questions: [
              const QuizQuestion(
                id: 'q1',
                type: QuestionType.multipleChoice,
                questionText: 'What is hello?',
                options: ['Xin chào', 'Goodbye'],
                correctAnswer: 'Xin chào',
                explanation: 'Hello means Xin chào',
              ),
            ],
          ),
          speakingExercise: const SpeakingExercise(
            id: 'se1',
            lessonId: 'l1',
            phrase: 'Hello, nice to meet you',
            modelAudioUrl: 'https://example.com/model.mp3',
          ),
        );

        final result = parser.prettyPrint(content);

        expect(result.isSuccess, isTrue);
        expect(result.value, contains('listeningExercise'));
        expect(result.value, contains('speakingExercise'));
        expect(result.value, contains('audioUrl'));
      });

      test('should omit optional fields when not present', () {
        final content = LessonContent(
          flashcards: [
            const Flashcard(
              id: 'f1',
              lessonId: 'l1',
              frontText: 'Hello',
              backText: 'Xin chào',
              exampleUsage: 'Hello, how are you?',
            ),
          ],
          quiz: Quiz(
            id: 'q1',
            lessonId: 'l1',
            title: 'Test Quiz',
            questions: [
              const QuizQuestion(
                id: 'q1',
                type: QuestionType.multipleChoice,
                questionText: 'What is hello?',
                options: ['Xin chào', 'Goodbye'],
                correctAnswer: 'Xin chào',
                explanation: 'Hello means Xin chào',
              ),
            ],
          ),
        );

        final result = parser.prettyPrint(content);

        expect(result.isSuccess, isTrue);
        expect(result.value, isNot(contains('listeningExercise')));
        expect(result.value, isNot(contains('speakingExercise')));
      });
    });

    group('round-trip', () {
      test('should preserve content through parse and prettyPrint cycle', () {
        final originalContent = LessonContent(
          flashcards: [
            const Flashcard(
              id: 'f1',
              lessonId: 'l1',
              frontText: 'Hello',
              backText: 'Xin chào',
              exampleUsage: 'Hello, how are you?',
              audioUrl: 'https://example.com/audio.mp3',
            ),
          ],
          quiz: Quiz(
            id: 'q1',
            lessonId: 'l1',
            title: 'Test Quiz',
            questions: [
              const QuizQuestion(
                id: 'q1',
                type: QuestionType.multipleChoice,
                questionText: 'What is hello?',
                options: ['Xin chào', 'Goodbye'],
                correctAnswer: 'Xin chào',
                explanation: 'Hello means Xin chào',
              ),
            ],
          ),
        );

        // Serialize
        final serialized = parser.prettyPrint(originalContent);
        expect(serialized.isSuccess, isTrue);

        // Parse
        final parsed = parser.parse(serialized.value);
        expect(parsed.isSuccess, isTrue);

        // Compare
        expect(parsed.value, equals(originalContent));
      });
    });

    group('UTF-8 support', () {
      test('should preserve Chinese characters', () {
        final content = LessonContent(
          flashcards: [
            const Flashcard(
              id: 'f1',
              lessonId: 'l1',
              frontText: '你好',
              backText: 'Hello',
              exampleUsage: '你好，你好吗？',
            ),
          ],
          quiz: Quiz(
            id: 'q1',
            lessonId: 'l1',
            title: '中文测试',
            questions: [
              const QuizQuestion(
                id: 'q1',
                type: QuestionType.multipleChoice,
                questionText: '你好是什么意思？',
                options: ['Hello', 'Goodbye'],
                correctAnswer: 'Hello',
                explanation: '你好的意思是Hello',
              ),
            ],
          ),
        );

        final serialized = parser.prettyPrint(content);
        expect(serialized.isSuccess, isTrue);

        final parsed = parser.parse(serialized.value);
        expect(parsed.isSuccess, isTrue);
        expect(parsed.value.flashcards[0].frontText, equals('你好'));
        expect(parsed.value.quiz.title, equals('中文测试'));
      });

      test('should preserve Korean characters', () {
        final content = LessonContent(
          flashcards: [
            const Flashcard(
              id: 'f1',
              lessonId: 'l1',
              frontText: '안녕하세요',
              backText: 'Hello',
              exampleUsage: '안녕하세요, 어떻게 지내세요?',
            ),
          ],
          quiz: Quiz(
            id: 'q1',
            lessonId: 'l1',
            title: '한국어 테스트',
            questions: [
              const QuizQuestion(
                id: 'q1',
                type: QuestionType.multipleChoice,
                questionText: '안녕하세요는 무슨 뜻인가요?',
                options: ['Hello', 'Goodbye'],
                correctAnswer: 'Hello',
                explanation: '안녕하세요는 Hello를 의미합니다',
              ),
            ],
          ),
        );

        final serialized = parser.prettyPrint(content);
        expect(serialized.isSuccess, isTrue);

        final parsed = parser.parse(serialized.value);
        expect(parsed.isSuccess, isTrue);
        expect(parsed.value.flashcards[0].frontText, equals('안녕하세요'));
        expect(parsed.value.quiz.title, equals('한국어 테스트'));
      });

      test('should preserve emojis and special characters', () {
        final content = LessonContent(
          flashcards: [
            const Flashcard(
              id: 'f1',
              lessonId: 'l1',
              frontText: 'Hello! 😊',
              backText: 'Greeting with emoji',
              exampleUsage: 'Say: Hello! 😊 How are you? 🎉',
            ),
          ],
          quiz: Quiz(
            id: 'q1',
            lessonId: 'l1',
            title: 'Test with symbols: @#\$%',
            questions: [
              const QuizQuestion(
                id: 'q1',
                type: QuestionType.multipleChoice,
                questionText: 'What\'s the emoji? 😊',
                options: ['Happy', 'Sad'],
                correctAnswer: 'Happy',
                explanation: '😊 means happy!',
              ),
            ],
          ),
        );

        final serialized = parser.prettyPrint(content);
        expect(serialized.isSuccess, isTrue);

        final parsed = parser.parse(serialized.value);
        expect(parsed.isSuccess, isTrue);
        expect(parsed.value.flashcards[0].frontText, equals('Hello! 😊'));
        expect(parsed.value.quiz.questions[0].explanation,
            equals('😊 means happy!'));
      });
    });
  });
}
