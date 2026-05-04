import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:demon_teach/domain/entities/flashcard.dart';
import 'package:demon_teach/domain/entities/listening_exercise.dart';
import 'package:demon_teach/domain/entities/quiz.dart';
import 'package:demon_teach/domain/entities/speaking_exercise.dart';
import 'package:demon_teach/domain/services/content_parser.dart';

/// **Property 24: Content Parser Validation**
///
/// *For any* content file, the parser SHALL correctly identify whether it is
/// valid or invalid according to the schema, and for invalid files, SHALL
/// return descriptive error messages.
///
/// **Validates: Requirements 20.2, 20.3**

/// **Property 25: Content Serialization Preservation**
///
/// *For any* lesson content object, serializing it to JSON SHALL preserve all
/// fields including metadata, text, and media references.
///
/// **Validates: Requirements 20.5**

/// **Property 26: Content Parser Round-Trip**
///
/// *For any* valid lesson content object, the sequence parse(prettyPrint(content))
/// SHALL produce a lesson content object equivalent to the original.
///
/// **Validates: Requirements 20.6**

/// **Property 27: UTF-8 Encoding Support**
///
/// *For any* lesson content containing UTF-8 characters (including Chinese,
/// Korean, and special characters), the parser SHALL correctly parse and
/// preserve these characters.
///
/// **Validates: Requirements 20.7**

void main() {
  group('Property 24: Content Parser Validation', () {
    late ContentParser parser;

    setUp(() {
      parser = ContentParser();
    });

    test('Property: Parser correctly identifies valid content', () {
      // Generate 100+ valid content samples
      final generator = LessonContentGenerator();

      for (int i = 0; i < 100; i++) {
        final content = generator.generateValid();
        final json = jsonEncode(content.toJson());

        final result = parser.parse(json);

        expect(
          result.isSuccess,
          isTrue,
          reason: 'Valid content should parse successfully (iteration $i)',
        );
      }
    });

    test(
        'Property: Parser correctly identifies invalid content with descriptive errors',
        () {
      // Test cases for various invalid content scenarios
      final invalidCases = [
        // Missing required field: flashcards
        (
          json:
              '{"quiz": {"id": "q1", "lessonId": "l1", "title": "Test", "questions": []}}',
          expectedError: 'flashcards'
        ),
        // Missing required field: quiz
        (json: '{"flashcards": []}', expectedError: 'quiz'),
        // Empty flashcards array
        (
          json:
              '{"flashcards": [], "quiz": {"id": "q1", "lessonId": "l1", "title": "Test", "questions": [{"id": "q1", "type": "multipleChoice", "questionText": "Q?", "options": ["A"], "correctAnswer": "A", "explanation": "E"}]}}',
          expectedError: 'flashcards array cannot be empty'
        ),
        // Invalid flashcard: missing frontText
        (
          json:
              '{"flashcards": [{"id": "f1", "lessonId": "l1", "backText": "back", "exampleUsage": "ex"}], "quiz": {"id": "q1", "lessonId": "l1", "title": "Test", "questions": [{"id": "q1", "type": "multipleChoice", "questionText": "Q?", "options": ["A"], "correctAnswer": "A", "explanation": "E"}]}}',
          expectedError: 'frontText'
        ),
        // Invalid URL format
        (
          json:
              '{"flashcards": [{"id": "f1", "lessonId": "l1", "frontText": "front", "backText": "back", "exampleUsage": "ex", "audioUrl": "not-a-url"}], "quiz": {"id": "q1", "lessonId": "l1", "title": "Test", "questions": [{"id": "q1", "type": "multipleChoice", "questionText": "Q?", "options": ["A"], "correctAnswer": "A", "explanation": "E"}]}}',
          expectedError: 'audioUrl is not a valid URL'
        ),
        // Invalid JSON format
        (json: '{invalid json}', expectedError: 'Invalid JSON format'),
        // Empty quiz questions
        (
          json:
              '{"flashcards": [{"id": "f1", "lessonId": "l1", "frontText": "front", "backText": "back", "exampleUsage": "ex"}], "quiz": {"id": "q1", "lessonId": "l1", "title": "Test", "questions": []}}',
          expectedError: 'questions array cannot be empty'
        ),
      ];

      for (final testCase in invalidCases) {
        final result = parser.parse(testCase.json);

        expect(
          result.isFailure,
          isTrue,
          reason:
              'Invalid content should fail parsing: ${testCase.expectedError}',
        );

        expect(
          result.failure.message.toLowerCase(),
          contains(testCase.expectedError.toLowerCase()),
          reason: 'Error message should contain: ${testCase.expectedError}',
        );
      }
    });

    test('Property: Parser provides specific field names in error messages',
        () {
      final testCases = [
        (
          json:
              '{"flashcards": [{"id": "f1", "lessonId": "l1"}], "quiz": {"id": "q1", "lessonId": "l1", "title": "Test", "questions": [{"id": "q1", "type": "multipleChoice", "questionText": "Q?", "options": ["A"], "correctAnswer": "A", "explanation": "E"}]}}',
          expectedFields: ['frontText', 'backText', 'exampleUsage']
        ),
        (
          json:
              '{"flashcards": [{"id": "f1", "lessonId": "l1", "frontText": "front", "backText": "back", "exampleUsage": "ex"}], "quiz": {"id": "q1", "lessonId": "l1"}}',
          expectedFields: ['title', 'questions']
        ),
      ];

      for (final testCase in testCases) {
        final result = parser.parse(testCase.json);

        expect(result.isFailure, isTrue);

        for (final field in testCase.expectedFields) {
          expect(
            result.failure.message.toLowerCase(),
            contains(field.toLowerCase()),
            reason: 'Error message should mention missing field: $field',
          );
        }
      }
    });
  });

  group('Property 25: Content Serialization Preservation', () {
    late ContentParser parser;

    setUp(() {
      parser = ContentParser();
    });

    test('Property: Serialization preserves all flashcard fields', () {
      final generator = LessonContentGenerator();

      for (int i = 0; i < 100; i++) {
        final content = generator.generateValid();

        final result = parser.prettyPrint(content);
        expect(result.isSuccess, isTrue);

        final json = jsonDecode(result.value) as Map<String, dynamic>;

        // Verify flashcards are preserved
        expect(json.containsKey('flashcards'), isTrue);
        final flashcards = json['flashcards'] as List;
        expect(flashcards.length, equals(content.flashcards.length));

        for (int j = 0; j < flashcards.length; j++) {
          final fc = flashcards[j] as Map<String, dynamic>;
          final original = content.flashcards[j];

          expect(fc['id'], equals(original.id));
          expect(fc['lessonId'], equals(original.lessonId));
          expect(fc['frontText'], equals(original.frontText));
          expect(fc['backText'], equals(original.backText));
          expect(fc['exampleUsage'], equals(original.exampleUsage));
          if (original.audioUrl != null) {
            expect(fc['audioUrl'], equals(original.audioUrl));
          }
        }
      }
    });

    test('Property: Serialization preserves quiz fields', () {
      final generator = LessonContentGenerator();

      for (int i = 0; i < 100; i++) {
        final content = generator.generateValid();

        final result = parser.prettyPrint(content);
        expect(result.isSuccess, isTrue);

        final json = jsonDecode(result.value) as Map<String, dynamic>;

        // Verify quiz is preserved
        expect(json.containsKey('quiz'), isTrue);
        final quiz = json['quiz'] as Map<String, dynamic>;
        final original = content.quiz;

        expect(quiz['id'], equals(original.id));
        expect(quiz['lessonId'], equals(original.lessonId));
        expect(quiz['title'], equals(original.title));

        final questions = quiz['questions'] as List;
        expect(questions.length, equals(original.questions.length));

        for (int j = 0; j < questions.length; j++) {
          final q = questions[j] as Map<String, dynamic>;
          final originalQ = original.questions[j];

          expect(q['id'], equals(originalQ.id));
          expect(q['type'], equals(originalQ.type.name));
          expect(q['questionText'], equals(originalQ.questionText));
          expect(q['correctAnswer'], equals(originalQ.correctAnswer));
          expect(q['explanation'], equals(originalQ.explanation));
        }
      }
    });

    test('Property: Serialization preserves optional listening exercise', () {
      final generator = LessonContentGenerator();

      for (int i = 0; i < 50; i++) {
        final content = generator.generateWithListening();

        final result = parser.prettyPrint(content);
        expect(result.isSuccess, isTrue);

        final json = jsonDecode(result.value) as Map<String, dynamic>;

        if (content.listeningExercise != null) {
          expect(json.containsKey('listeningExercise'), isTrue);
          final listening = json['listeningExercise'] as Map<String, dynamic>;
          final original = content.listeningExercise!;

          expect(listening['id'], equals(original.id));
          expect(listening['lessonId'], equals(original.lessonId));
          expect(listening['audioUrl'], equals(original.audioUrl));
          expect(
              listening['durationSeconds'], equals(original.durationSeconds));
        }
      }
    });

    test('Property: Serialization preserves optional speaking exercise', () {
      final generator = LessonContentGenerator();

      for (int i = 0; i < 50; i++) {
        final content = generator.generateWithSpeaking();

        final result = parser.prettyPrint(content);
        expect(result.isSuccess, isTrue);

        final json = jsonDecode(result.value) as Map<String, dynamic>;

        if (content.speakingExercise != null) {
          expect(json.containsKey('speakingExercise'), isTrue);
          final speaking = json['speakingExercise'] as Map<String, dynamic>;
          final original = content.speakingExercise!;

          expect(speaking['id'], equals(original.id));
          expect(speaking['lessonId'], equals(original.lessonId));
          expect(speaking['phrase'], equals(original.phrase));
          expect(speaking['modelAudioUrl'], equals(original.modelAudioUrl));
        }
      }
    });
  });

  group('Property 26: Content Parser Round-Trip', () {
    late ContentParser parser;

    setUp(() {
      parser = ContentParser();
    });

    test('Property: parse(prettyPrint(content)) produces equivalent object',
        () {
      final generator = LessonContentGenerator();

      for (int i = 0; i < 100; i++) {
        final originalContent = generator.generateValid();

        // Serialize
        final serialized = parser.prettyPrint(originalContent);
        expect(
          serialized.isSuccess,
          isTrue,
          reason: 'Serialization should succeed (iteration $i)',
        );

        // Parse
        final parsed = parser.parse(serialized.value);
        expect(
          parsed.isSuccess,
          isTrue,
          reason: 'Parsing should succeed (iteration $i)',
        );

        // Compare
        final parsedContent = parsed.value;

        expect(
          parsedContent,
          equals(originalContent),
          reason: 'Round-trip should preserve content (iteration $i)',
        );
      }
    });

    test('Property: Round-trip preserves content with all optional fields', () {
      final generator = LessonContentGenerator();

      for (int i = 0; i < 100; i++) {
        final originalContent = generator.generateWithAllFields();

        // Serialize
        final serialized = parser.prettyPrint(originalContent);
        expect(serialized.isSuccess, isTrue);

        // Parse
        final parsed = parser.parse(serialized.value);
        expect(parsed.isSuccess, isTrue);

        // Compare
        final parsedContent = parsed.value;

        expect(parsedContent, equals(originalContent));
      }
    });

    test('Property: Multiple round-trips produce stable results', () {
      final generator = LessonContentGenerator();

      for (int i = 0; i < 50; i++) {
        final originalContent = generator.generateValid();

        // First round-trip
        final serialized1 = parser.prettyPrint(originalContent);
        final parsed1 = parser.parse(serialized1.value);

        // Second round-trip
        final serialized2 = parser.prettyPrint(parsed1.value);
        final parsed2 = parser.parse(serialized2.value);

        // Third round-trip
        final serialized3 = parser.prettyPrint(parsed2.value);
        final parsed3 = parser.parse(serialized3.value);

        // All should be equal
        expect(parsed1.value, equals(originalContent));
        expect(parsed2.value, equals(originalContent));
        expect(parsed3.value, equals(originalContent));
      }
    });
  });

  group('Property 27: UTF-8 Encoding Support', () {
    late ContentParser parser;

    setUp(() {
      parser = ContentParser();
    });

    test('Property: Parser preserves Chinese characters', () {
      final chineseTexts = [
        '你好',
        '谢谢',
        '再见',
        '早上好',
        '晚安',
        '我爱你',
        '对不起',
        '没关系',
        '中文',
        '汉字',
      ];

      for (final text in chineseTexts) {
        final content = LessonContent(
          flashcards: [
            Flashcard(
              id: 'f1',
              lessonId: 'l1',
              frontText: text,
              backText: 'Translation',
              exampleUsage: '例句: $text',
            ),
          ],
          quiz: Quiz(
            id: 'q1',
            lessonId: 'l1',
            title: text,
            questions: [
              QuizQuestion(
                id: 'q1',
                type: QuestionType.multipleChoice,
                questionText: text,
                options: [text, 'Other'],
                correctAnswer: text,
                explanation: '解释: $text',
              ),
            ],
          ),
        );

        // Serialize and parse
        final serialized = parser.prettyPrint(content);
        expect(serialized.isSuccess, isTrue);

        final parsed = parser.parse(serialized.value);
        expect(parsed.isSuccess, isTrue);

        // Verify Chinese characters are preserved
        expect(parsed.value.flashcards[0].frontText, equals(text));
        expect(parsed.value.flashcards[0].exampleUsage, contains(text));
        expect(parsed.value.quiz.title, equals(text));
        expect(parsed.value.quiz.questions[0].questionText, equals(text));
        expect(parsed.value.quiz.questions[0].explanation, contains(text));
      }
    });

    test('Property: Parser preserves Korean characters', () {
      final koreanTexts = [
        '안녕하세요',
        '감사합니다',
        '안녕히 가세요',
        '좋은 아침',
        '잘 자요',
        '사랑해요',
        '미안합니다',
        '괜찮아요',
        '한국어',
        '한글',
      ];

      for (final text in koreanTexts) {
        final content = LessonContent(
          flashcards: [
            Flashcard(
              id: 'f1',
              lessonId: 'l1',
              frontText: text,
              backText: 'Translation',
              exampleUsage: '예문: $text',
            ),
          ],
          quiz: Quiz(
            id: 'q1',
            lessonId: 'l1',
            title: text,
            questions: [
              QuizQuestion(
                id: 'q1',
                type: QuestionType.multipleChoice,
                questionText: text,
                options: [text, 'Other'],
                correctAnswer: text,
                explanation: '설명: $text',
              ),
            ],
          ),
        );

        // Serialize and parse
        final serialized = parser.prettyPrint(content);
        expect(serialized.isSuccess, isTrue);

        final parsed = parser.parse(serialized.value);
        expect(parsed.isSuccess, isTrue);

        // Verify Korean characters are preserved
        expect(parsed.value.flashcards[0].frontText, equals(text));
        expect(parsed.value.flashcards[0].exampleUsage, contains(text));
        expect(parsed.value.quiz.title, equals(text));
        expect(parsed.value.quiz.questions[0].questionText, equals(text));
        expect(parsed.value.quiz.questions[0].explanation, contains(text));
      }
    });

    test('Property: Parser preserves special characters and emojis', () {
      final specialTexts = [
        'Hello! 😊',
        'Test™ ©2024',
        'Price: \$100',
        'Math: 2+2=4',
        'Quote: "Hello"',
        "Apostrophe: it's",
        'Symbols: @#\$%^&*()',
        'Accents: café, naïve',
        'Mixed: 你好 Hello 안녕',
        'Emoji: 🎉🎊🎈',
      ];

      for (final text in specialTexts) {
        final content = LessonContent(
          flashcards: [
            Flashcard(
              id: 'f1',
              lessonId: 'l1',
              frontText: text,
              backText: 'Translation',
              exampleUsage: 'Example: $text',
            ),
          ],
          quiz: Quiz(
            id: 'q1',
            lessonId: 'l1',
            title: text,
            questions: [
              QuizQuestion(
                id: 'q1',
                type: QuestionType.multipleChoice,
                questionText: text,
                options: [text, 'Other'],
                correctAnswer: text,
                explanation: 'Explanation: $text',
              ),
            ],
          ),
        );

        // Serialize and parse
        final serialized = parser.prettyPrint(content);
        expect(serialized.isSuccess, isTrue);

        final parsed = parser.parse(serialized.value);
        expect(parsed.isSuccess, isTrue);

        // Verify special characters are preserved
        expect(parsed.value.flashcards[0].frontText, equals(text));
        expect(parsed.value.quiz.title, equals(text));
        expect(parsed.value.quiz.questions[0].questionText, equals(text));
      }
    });

    test('Property: Parser handles mixed language content', () {
      for (int i = 0; i < 100; i++) {
        final content = LessonContent(
          flashcards: [
            Flashcard(
              id: 'f1',
              lessonId: 'l1',
              frontText: '你好 (Hello) 안녕하세요',
              backText: 'Greetings in Chinese, English, Korean',
              exampleUsage: 'Example: 你好! Hello! 안녕하세요! 😊',
            ),
            Flashcard(
              id: 'f2',
              lessonId: 'l1',
              frontText: '谢谢 (Thank you) 감사합니다',
              backText: 'Thanks in multiple languages',
              exampleUsage: 'Say: 谢谢! Thank you! 감사합니다! 🙏',
            ),
          ],
          quiz: Quiz(
            id: 'q1',
            lessonId: 'l1',
            title: 'Mixed Language Quiz: 中文 English 한국어',
            questions: [
              QuizQuestion(
                id: 'q1',
                type: QuestionType.multipleChoice,
                questionText: 'What does "你好" mean?',
                options: ['Hello', 'Goodbye', 'Thank you'],
                correctAnswer: 'Hello',
                explanation: '你好 means Hello in Chinese',
              ),
            ],
          ),
        );

        // Serialize and parse
        final serialized = parser.prettyPrint(content);
        expect(serialized.isSuccess, isTrue);

        final parsed = parser.parse(serialized.value);
        expect(parsed.isSuccess, isTrue);

        // Verify all mixed content is preserved
        expect(parsed.value, equals(content));
      }
    });
  });
}

/// Generator for creating test lesson content
class LessonContentGenerator {
  final Random _random = Random();

  /// Generate valid lesson content
  LessonContent generateValid() {
    final flashcardCount = _random.nextInt(5) + 1; // 1-5 flashcards
    final questionCount = _random.nextInt(5) + 1; // 1-5 questions

    return LessonContent(
      flashcards: List.generate(
        flashcardCount,
        (i) => _generateFlashcard(i),
      ),
      quiz: _generateQuiz(questionCount),
    );
  }

  /// Generate content with listening exercise
  LessonContent generateWithListening() {
    return LessonContent(
      flashcards: [_generateFlashcard(0)],
      listeningExercise: _generateListeningExercise(),
      quiz: _generateQuiz(1),
    );
  }

  /// Generate content with speaking exercise
  LessonContent generateWithSpeaking() {
    return LessonContent(
      flashcards: [_generateFlashcard(0)],
      quiz: _generateQuiz(1),
      speakingExercise: _generateSpeakingExercise(),
    );
  }

  /// Generate content with all optional fields
  LessonContent generateWithAllFields() {
    return LessonContent(
      flashcards: List.generate(2, (i) => _generateFlashcard(i)),
      listeningExercise: _generateListeningExercise(),
      quiz: _generateQuiz(2),
      speakingExercise: _generateSpeakingExercise(),
    );
  }

  Flashcard _generateFlashcard(int index) {
    return Flashcard(
      id: 'f${index + 1}',
      lessonId: 'lesson_${_random.nextInt(100)}',
      frontText: 'Front text ${index + 1}',
      backText: 'Back text ${index + 1}',
      exampleUsage: 'Example usage ${index + 1}',
      audioUrl: _random.nextBool()
          ? 'https://example.com/audio${index + 1}.mp3'
          : null,
    );
  }

  Quiz _generateQuiz(int questionCount) {
    return Quiz(
      id: 'quiz_${_random.nextInt(100)}',
      lessonId: 'lesson_${_random.nextInt(100)}',
      title: 'Quiz Title',
      questions: List.generate(
        questionCount,
        (i) => _generateQuizQuestion(i),
      ),
    );
  }

  QuizQuestion _generateQuizQuestion(int index) {
    final types = QuestionType.values;
    return QuizQuestion(
      id: 'q${index + 1}',
      type: types[_random.nextInt(types.length)],
      questionText: 'Question ${index + 1}?',
      options: ['Option A', 'Option B', 'Option C'],
      correctAnswer: 'Option A',
      explanation: 'Explanation ${index + 1}',
    );
  }

  ListeningExercise _generateListeningExercise() {
    return ListeningExercise(
      id: 'listening_${_random.nextInt(100)}',
      lessonId: 'lesson_${_random.nextInt(100)}',
      audioUrl: 'https://example.com/listening.mp3',
      durationSeconds: _random.nextInt(60) + 10,
      questions: [
        ComprehensionQuestion(
          id: 'cq1',
          questionText: 'Comprehension question?',
          options: ['A', 'B', 'C'],
          correctAnswer: 'A',
          explanation: 'Explanation',
        ),
      ],
    );
  }

  SpeakingExercise _generateSpeakingExercise() {
    return SpeakingExercise(
      id: 'speaking_${_random.nextInt(100)}',
      lessonId: 'lesson_${_random.nextInt(100)}',
      phrase: 'Practice phrase',
      modelAudioUrl: 'https://example.com/model.mp3',
    );
  }
}
