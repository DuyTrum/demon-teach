import 'package:demon_teach/domain/entities/quiz.dart';

/// Mock quiz data for testing and development
class MockQuizData {
  /// Get mock quiz for English lessons
  static Quiz getEnglishQuiz(String lessonId) {
    return Quiz(
      id: 'quiz_en_$lessonId',
      lessonId: lessonId,
      title: 'English Vocabulary Quiz',
      questions: [
        QuizQuestion(
          id: 'q1',
          type: QuestionType.multipleChoice,
          questionText: 'What does "Hello" mean in Vietnamese?',
          options: ['Tạm biệt', 'Xin chào', 'Cảm ơn', 'Xin lỗi'],
          correctAnswer: 'Xin chào',
          explanation: '"Hello" translates to "Xin chào" in Vietnamese.',
          points: 10,
        ),
        QuizQuestion(
          id: 'q2',
          type: QuestionType.multipleChoice,
          questionText: 'How do you say "Thank you" in English?',
          options: ['Please', 'Thank you', 'Sorry', 'Goodbye'],
          correctAnswer: 'Thank you',
          explanation: '"Thank you" is the correct way to express gratitude.',
          points: 10,
        ),
        QuizQuestion(
          id: 'q3',
          type: QuestionType.fillInBlank,
          questionText: 'Complete: "_____ me, where is the bathroom?"',
          options: ['Excuse', 'Sorry', 'Please', 'Thank'],
          correctAnswer: 'Excuse',
          explanation:
              '"Excuse me" is the polite way to get someone\'s attention.',
          points: 10,
        ),
        QuizQuestion(
          id: 'q4',
          type: QuestionType.multipleChoice,
          questionText: 'What is the opposite of "Hello"?',
          options: ['Goodbye', 'Please', 'Thank you', 'Sorry'],
          correctAnswer: 'Goodbye',
          explanation:
              '"Goodbye" is used when leaving or ending a conversation.',
          points: 10,
        ),
      ],
      passingScore: 60,
    );
  }

  /// Get mock quiz for Chinese lessons
  static Quiz getChineseQuiz(String lessonId) {
    return Quiz(
      id: 'quiz_zh_$lessonId',
      lessonId: lessonId,
      title: 'Chinese Vocabulary Quiz',
      questions: [
        QuizQuestion(
          id: 'q1',
          type: QuestionType.multipleChoice,
          questionText: 'What does "你好" (Nǐ hǎo) mean?',
          options: ['Goodbye', 'Hello', 'Thank you', 'Sorry'],
          correctAnswer: 'Hello',
          explanation: '"你好" (Nǐ hǎo) means "Hello" in Chinese.',
          points: 10,
        ),
        QuizQuestion(
          id: 'q2',
          type: QuestionType.multipleChoice,
          questionText: 'How do you say "Thank you" in Chinese?',
          options: ['你好', '再见', '谢谢', '对不起'],
          correctAnswer: '谢谢',
          explanation: '"谢谢" (Xièxiè) means "Thank you" in Chinese.',
          points: 10,
        ),
        QuizQuestion(
          id: 'q3',
          type: QuestionType.fillInBlank,
          questionText: 'Complete: "_____ (Goodbye) in Chinese is..."',
          options: ['你好', '再见', '谢谢', '请'],
          correctAnswer: '再见',
          explanation: '"再见" (Zàijiàn) means "Goodbye" in Chinese.',
          points: 10,
        ),
        QuizQuestion(
          id: 'q4',
          type: QuestionType.multipleChoice,
          questionText: 'What does "请" (Qǐng) mean?',
          options: ['Hello', 'Goodbye', 'Please', 'Sorry'],
          correctAnswer: 'Please',
          explanation: '"请" (Qǐng) means "Please" in Chinese.',
          points: 10,
        ),
      ],
      passingScore: 60,
    );
  }

  /// Get mock quiz for Korean lessons
  static Quiz getKoreanQuiz(String lessonId) {
    return Quiz(
      id: 'quiz_ko_$lessonId',
      lessonId: lessonId,
      title: 'Korean Vocabulary Quiz',
      questions: [
        QuizQuestion(
          id: 'q1',
          type: QuestionType.multipleChoice,
          questionText: 'What does "안녕하세요" (Annyeonghaseyo) mean?',
          options: ['Goodbye', 'Hello', 'Thank you', 'Sorry'],
          correctAnswer: 'Hello',
          explanation: '"안녕하세요" (Annyeonghaseyo) means "Hello" in Korean.',
          points: 10,
        ),
        QuizQuestion(
          id: 'q2',
          type: QuestionType.multipleChoice,
          questionText: 'How do you say "Thank you" in Korean?',
          options: ['안녕하세요', '안녕히 가세요', '감사합니다', '실례합니다'],
          correctAnswer: '감사합니다',
          explanation: '"감사합니다" (Gamsahamnida) means "Thank you" in Korean.',
          points: 10,
        ),
        QuizQuestion(
          id: 'q3',
          type: QuestionType.fillInBlank,
          questionText: 'Complete: "_____ (Goodbye) in Korean is..."',
          options: ['안녕하세요', '안녕히 가세요', '감사합니다', '주세요'],
          correctAnswer: '안녕히 가세요',
          explanation:
              '"안녕히 가세요" (Annyeonghi gaseyo) means "Goodbye" in Korean.',
          points: 10,
        ),
        QuizQuestion(
          id: 'q4',
          type: QuestionType.multipleChoice,
          questionText: 'What does "주세요" (Juseyo) mean?',
          options: ['Hello', 'Goodbye', 'Please (give me)', 'Sorry'],
          correctAnswer: 'Please (give me)',
          explanation: '"주세요" (Juseyo) means "Please give me" in Korean.',
          points: 10,
        ),
      ],
      passingScore: 60,
    );
  }

  /// Get quiz based on target language
  static Quiz getQuizForLanguage(String lessonId, String targetLanguage) {
    switch (targetLanguage.toLowerCase()) {
      case 'en':
      case 'english':
        return getEnglishQuiz(lessonId);
      case 'zh':
      case 'chinese':
        return getChineseQuiz(lessonId);
      case 'ko':
      case 'korean':
        return getKoreanQuiz(lessonId);
      default:
        return getEnglishQuiz(lessonId);
    }
  }
}
