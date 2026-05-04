import 'package:demon_teach/domain/entities/assessment.dart';

/// Mock assessment data for different languages
class MockAssessmentData {
  /// Get mock assessment for English
  static Assessment getEnglishAssessment() {
    return const Assessment(
      id: 'assessment_en_1',
      targetLanguage: 'en',
      questions: [
        // Easy questions
        AssessmentQuestion(
          id: 'q1',
          questionText: 'What is the correct greeting?',
          options: ['Hello', 'Goodbye', 'Thank you', 'Sorry'],
          correctAnswer: 'Hello',
          difficulty: QuestionDifficulty.easy,
          category: 'vocabulary',
        ),
        AssessmentQuestion(
          id: 'q2',
          questionText: 'Choose the correct pronoun: ___ am a student.',
          options: ['I', 'You', 'He', 'They'],
          correctAnswer: 'I',
          difficulty: QuestionDifficulty.easy,
          category: 'grammar',
        ),
        AssessmentQuestion(
          id: 'q3',
          questionText: 'What does "cat" mean?',
          options: ['Dog', 'Animal with whiskers', 'Bird', 'Fish'],
          correctAnswer: 'Animal with whiskers',
          difficulty: QuestionDifficulty.easy,
          category: 'vocabulary',
        ),

        // Medium questions
        AssessmentQuestion(
          id: 'q4',
          questionText:
              'Choose the correct verb form: She ___ to school every day.',
          options: ['go', 'goes', 'going', 'gone'],
          correctAnswer: 'goes',
          difficulty: QuestionDifficulty.medium,
          category: 'grammar',
        ),
        AssessmentQuestion(
          id: 'q5',
          questionText: 'What is the past tense of "eat"?',
          options: ['eated', 'ate', 'eaten', 'eating'],
          correctAnswer: 'ate',
          difficulty: QuestionDifficulty.medium,
          category: 'grammar',
        ),
        AssessmentQuestion(
          id: 'q6',
          questionText: 'Which word means "happy"?',
          options: ['Sad', 'Angry', 'Joyful', 'Tired'],
          correctAnswer: 'Joyful',
          difficulty: QuestionDifficulty.medium,
          category: 'vocabulary',
        ),
        AssessmentQuestion(
          id: 'q7',
          questionText: 'Complete: If it rains, I ___ stay home.',
          options: ['will', 'would', 'can', 'must'],
          correctAnswer: 'will',
          difficulty: QuestionDifficulty.medium,
          category: 'grammar',
        ),

        // Hard questions
        AssessmentQuestion(
          id: 'q8',
          questionText:
              'Choose the correct form: By next year, I ___ English for 5 years.',
          options: [
            'will study',
            'will have studied',
            'will be studying',
            'have studied'
          ],
          correctAnswer: 'will have studied',
          difficulty: QuestionDifficulty.hard,
          category: 'grammar',
        ),
        AssessmentQuestion(
          id: 'q9',
          questionText: 'What does "procrastinate" mean?',
          options: [
            'To delay or postpone',
            'To work quickly',
            'To celebrate',
            'To organize'
          ],
          correctAnswer: 'To delay or postpone',
          difficulty: QuestionDifficulty.hard,
          category: 'vocabulary',
        ),
        AssessmentQuestion(
          id: 'q10',
          questionText: 'Identify the error: "She don\'t like coffee."',
          options: ['She', 'don\'t', 'like', 'No error'],
          correctAnswer: 'don\'t',
          difficulty: QuestionDifficulty.hard,
          category: 'grammar',
        ),
      ],
    );
  }

  /// Get mock assessment for Chinese
  static Assessment getChineseAssessment() {
    return const Assessment(
      id: 'assessment_zh_1',
      targetLanguage: 'zh',
      questions: [
        // Easy questions
        AssessmentQuestion(
          id: 'q1',
          questionText: '你好 means:',
          options: ['Hello', 'Goodbye', 'Thank you', 'Sorry'],
          correctAnswer: 'Hello',
          difficulty: QuestionDifficulty.easy,
          category: 'vocabulary',
        ),
        AssessmentQuestion(
          id: 'q2',
          questionText: 'What is the correct way to say "I"?',
          options: ['我', '你', '他', '她'],
          correctAnswer: '我',
          difficulty: QuestionDifficulty.easy,
          category: 'vocabulary',
        ),
        AssessmentQuestion(
          id: 'q3',
          questionText: '谢谢 means:',
          options: ['Hello', 'Goodbye', 'Thank you', 'Sorry'],
          correctAnswer: 'Thank you',
          difficulty: QuestionDifficulty.easy,
          category: 'vocabulary',
        ),

        // Medium questions
        AssessmentQuestion(
          id: 'q4',
          questionText: 'Complete: 我___ 学生 (I am a student)',
          options: ['是', '有', '在', '的'],
          correctAnswer: '是',
          difficulty: QuestionDifficulty.medium,
          category: 'grammar',
        ),
        AssessmentQuestion(
          id: 'q5',
          questionText: 'What does 吃饭 mean?',
          options: ['Sleep', 'Eat', 'Drink', 'Walk'],
          correctAnswer: 'Eat',
          difficulty: QuestionDifficulty.medium,
          category: 'vocabulary',
        ),
        AssessmentQuestion(
          id: 'q6',
          questionText: 'How do you say "tomorrow"?',
          options: ['今天', '明天', '昨天', '后天'],
          correctAnswer: '明天',
          difficulty: QuestionDifficulty.medium,
          category: 'vocabulary',
        ),
        AssessmentQuestion(
          id: 'q7',
          questionText: 'Complete: 我___ 去学校 (I want to go to school)',
          options: ['想', '要', '能', '会'],
          correctAnswer: '想',
          difficulty: QuestionDifficulty.medium,
          category: 'grammar',
        ),

        // Hard questions
        AssessmentQuestion(
          id: 'q8',
          questionText: 'What is the correct measure word for books?',
          options: ['本', '个', '只', '张'],
          correctAnswer: '本',
          difficulty: QuestionDifficulty.hard,
          category: 'grammar',
        ),
        AssessmentQuestion(
          id: 'q9',
          questionText: 'What does 虽然...但是... structure mean?',
          options: [
            'Although...but...',
            'Because...so...',
            'If...then...',
            'Not only...but also...'
          ],
          correctAnswer: 'Although...but...',
          difficulty: QuestionDifficulty.hard,
          category: 'grammar',
        ),
        AssessmentQuestion(
          id: 'q10',
          questionText: 'What does 一举两得 mean?',
          options: [
            'Kill two birds with one stone',
            'One step at a time',
            'First come first served',
            'Practice makes perfect'
          ],
          correctAnswer: 'Kill two birds with one stone',
          difficulty: QuestionDifficulty.hard,
          category: 'vocabulary',
        ),
      ],
    );
  }

  /// Get mock assessment for Korean
  static Assessment getKoreanAssessment() {
    return const Assessment(
      id: 'assessment_ko_1',
      targetLanguage: 'ko',
      questions: [
        // Easy questions
        AssessmentQuestion(
          id: 'q1',
          questionText: '안녕하세요 means:',
          options: ['Hello', 'Goodbye', 'Thank you', 'Sorry'],
          correctAnswer: 'Hello',
          difficulty: QuestionDifficulty.easy,
          category: 'vocabulary',
        ),
        AssessmentQuestion(
          id: 'q2',
          questionText: 'What is the correct way to say "I"?',
          options: ['나', '너', '그', '우리'],
          correctAnswer: '나',
          difficulty: QuestionDifficulty.easy,
          category: 'vocabulary',
        ),
        AssessmentQuestion(
          id: 'q3',
          questionText: '감사합니다 means:',
          options: ['Hello', 'Goodbye', 'Thank you', 'Sorry'],
          correctAnswer: 'Thank you',
          difficulty: QuestionDifficulty.easy,
          category: 'vocabulary',
        ),

        // Medium questions
        AssessmentQuestion(
          id: 'q4',
          questionText: 'Complete: 저는 학생___ (I am a student)',
          options: ['이에요', '있어요', '해요', '가요'],
          correctAnswer: '이에요',
          difficulty: QuestionDifficulty.medium,
          category: 'grammar',
        ),
        AssessmentQuestion(
          id: 'q5',
          questionText: 'What does 먹다 mean?',
          options: ['Sleep', 'Eat', 'Drink', 'Walk'],
          correctAnswer: 'Eat',
          difficulty: QuestionDifficulty.medium,
          category: 'vocabulary',
        ),
        AssessmentQuestion(
          id: 'q6',
          questionText: 'How do you say "tomorrow"?',
          options: ['오늘', '내일', '어제', '모레'],
          correctAnswer: '내일',
          difficulty: QuestionDifficulty.medium,
          category: 'vocabulary',
        ),
        AssessmentQuestion(
          id: 'q7',
          questionText: 'Complete: 학교에 ___ (go to school)',
          options: ['가요', '와요', '있어요', '해요'],
          correctAnswer: '가요',
          difficulty: QuestionDifficulty.medium,
          category: 'grammar',
        ),

        // Hard questions
        AssessmentQuestion(
          id: 'q8',
          questionText: 'What is the honorific form of 먹다?',
          options: ['드시다', '잡수시다', '먹으시다', '드세요'],
          correctAnswer: '드시다',
          difficulty: QuestionDifficulty.hard,
          category: 'grammar',
        ),
        AssessmentQuestion(
          id: 'q9',
          questionText: 'What does -(으)ㄹ 것 같다 express?',
          options: ['Probability/guess', 'Past tense', 'Command', 'Question'],
          correctAnswer: 'Probability/guess',
          difficulty: QuestionDifficulty.hard,
          category: 'grammar',
        ),
        AssessmentQuestion(
          id: 'q10',
          questionText: 'What does 금상첨화 mean?',
          options: [
            'Icing on the cake',
            'Better late than never',
            'Practice makes perfect',
            'Time flies'
          ],
          correctAnswer: 'Icing on the cake',
          difficulty: QuestionDifficulty.hard,
          category: 'vocabulary',
        ),
      ],
    );
  }

  /// Get assessment by language code
  static Assessment getAssessmentByLanguage(String languageCode) {
    switch (languageCode) {
      case 'en':
        return getEnglishAssessment();
      case 'zh':
        return getChineseAssessment();
      case 'ko':
        return getKoreanAssessment();
      default:
        return getEnglishAssessment();
    }
  }
}
