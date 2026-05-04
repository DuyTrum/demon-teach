import 'package:demon_teach/domain/entities/lesson.dart';

/// Mock lesson data for testing and development
class MockLessonData {
  /// Get mock lessons for a specific language and proficiency level
  static List<Lesson> getLessonsForLanguage(String language) {
    final lessons = <Lesson>[];

    // English lessons
    if (language.toLowerCase() == 'english' || language.toLowerCase() == 'en') {
      lessons.addAll(_getEnglishLessons());
    }
    // Chinese lessons
    else if (language.toLowerCase() == 'chinese' ||
        language.toLowerCase() == 'zh') {
      lessons.addAll(_getChineseLessons());
    }
    // Korean lessons
    else if (language.toLowerCase() == 'korean' ||
        language.toLowerCase() == 'ko') {
      lessons.addAll(_getKoreanLessons());
    }

    return lessons;
  }

  /// Get lesson by ID
  static Lesson? getLessonById(String lessonId) {
    final allLessons = [
      ..._getEnglishLessons(),
      ..._getChineseLessons(),
      ..._getKoreanLessons(),
    ];

    try {
      return allLessons.firstWhere((lesson) => lesson.metadata.id == lessonId);
    } catch (e) {
      return null;
    }
  }

  static List<Lesson> _getEnglishLessons() {
    return [
      // Basic level
      Lesson(
        metadata: LessonMetadata(
          id: 'en_basic_vocab_001',
          title: 'Basic Greetings',
          description: 'Learn essential greetings and introductions in English',
          category: LessonCategory.vocabulary,
          difficulty: LessonDifficulty.beginner,
          targetLanguage: 'english',
          estimatedDurationMinutes: 10,
          tags: ['greetings', 'basics', 'conversation'],
        ),
        content: LessonContent(
          lessonId: 'en_basic_vocab_001',
          content: {
            'sections': [
              {
                'type': 'vocabulary',
                'items': [
                  {
                    'word': 'Hello',
                    'translation': 'Xin chào',
                    'pronunciation': 'həˈloʊ'
                  },
                  {
                    'word': 'Good morning',
                    'translation': 'Chào buổi sáng',
                    'pronunciation': 'ɡʊd ˈmɔːrnɪŋ'
                  },
                  {
                    'word': 'How are you?',
                    'translation': 'Bạn khỏe không?',
                    'pronunciation': 'haʊ ɑːr juː'
                  },
                  {
                    'word': 'Nice to meet you',
                    'translation': 'Rất vui được gặp bạn',
                    'pronunciation': 'naɪs tuː miːt juː'
                  },
                ],
              },
              {
                'type': 'practice',
                'exercises': [
                  {
                    'question': 'How do you greet someone in the morning?',
                    'options': [
                      'Good morning',
                      'Good night',
                      'Goodbye',
                      'Hello'
                    ],
                    'correctAnswer': 'Good morning',
                  },
                ],
              },
            ],
          },
          lastUpdated: DateTime.now(),
        ),
      ),
      Lesson(
        metadata: LessonMetadata(
          id: 'en_basic_vocab_002',
          title: 'Numbers and Time',
          description: 'Master numbers 1-100 and telling time',
          category: LessonCategory.vocabulary,
          difficulty: LessonDifficulty.beginner,
          targetLanguage: 'english',
          estimatedDurationMinutes: 15,
          tags: ['numbers', 'time', 'basics'],
        ),
        content: LessonContent(
          lessonId: 'en_basic_vocab_002',
          content: {
            'sections': [
              {
                'type': 'vocabulary',
                'items': [
                  {'word': 'One', 'translation': 'Một', 'pronunciation': 'wʌn'},
                  {'word': 'Two', 'translation': 'Hai', 'pronunciation': 'tuː'},
                  {
                    'word': 'What time is it?',
                    'translation': 'Mấy giờ rồi?',
                    'pronunciation': 'wɒt taɪm ɪz ɪt'
                  },
                ],
              },
            ],
          },
          lastUpdated: DateTime.now(),
        ),
      ),
      Lesson(
        metadata: LessonMetadata(
          id: 'en_basic_grammar_001',
          title: 'Present Simple Tense',
          description: 'Learn how to use present simple tense',
          category: LessonCategory.grammar,
          difficulty: LessonDifficulty.beginner,
          targetLanguage: 'english',
          estimatedDurationMinutes: 20,
          tags: ['grammar', 'tense', 'present'],
        ),
        content: LessonContent(
          lessonId: 'en_basic_grammar_001',
          content: {
            'sections': [
              {
                'type': 'explanation',
                'content':
                    'Present simple is used for habits, facts, and general truths.',
              },
              {
                'type': 'examples',
                'items': [
                  'I work every day.',
                  'She likes coffee.',
                  'They live in New York.',
                ],
              },
            ],
          },
          lastUpdated: DateTime.now(),
        ),
      ),

      // Intermediate level
      Lesson(
        metadata: LessonMetadata(
          id: 'en_intermediate_vocab_001',
          title: 'Work and Professions',
          description: 'Vocabulary related to jobs and workplace',
          category: LessonCategory.vocabulary,
          difficulty: LessonDifficulty.intermediate,
          targetLanguage: 'english',
          estimatedDurationMinutes: 15,
          tags: ['work', 'jobs', 'professional'],
        ),
        content: LessonContent(
          lessonId: 'en_intermediate_vocab_001',
          content: {
            'sections': [
              {
                'type': 'vocabulary',
                'items': [
                  {
                    'word': 'Manager',
                    'translation': 'Quản lý',
                    'pronunciation': 'ˈmænɪdʒər'
                  },
                  {
                    'word': 'Employee',
                    'translation': 'Nhân viên',
                    'pronunciation': 'ɪmˈplɔɪiː'
                  },
                  {
                    'word': 'Meeting',
                    'translation': 'Cuộc họp',
                    'pronunciation': 'ˈmiːtɪŋ'
                  },
                ],
              },
            ],
          },
          lastUpdated: DateTime.now(),
        ),
      ),

      // Advanced level
      Lesson(
        metadata: LessonMetadata(
          id: 'en_advanced_vocab_001',
          title: 'Academic Vocabulary',
          description: 'Advanced vocabulary for academic contexts',
          category: LessonCategory.vocabulary,
          difficulty: LessonDifficulty.advanced,
          targetLanguage: 'english',
          estimatedDurationMinutes: 25,
          tags: ['academic', 'advanced', 'formal'],
        ),
        content: LessonContent(
          lessonId: 'en_advanced_vocab_001',
          content: {
            'sections': [
              {
                'type': 'vocabulary',
                'items': [
                  {
                    'word': 'Hypothesis',
                    'translation': 'Giả thuyết',
                    'pronunciation': 'haɪˈpɒθəsɪs'
                  },
                  {
                    'word': 'Methodology',
                    'translation': 'Phương pháp luận',
                    'pronunciation': 'ˌmeθəˈdɒlədʒi'
                  },
                ],
              },
            ],
          },
          lastUpdated: DateTime.now(),
        ),
      ),
    ];
  }

  static List<Lesson> _getChineseLessons() {
    return [
      Lesson(
        metadata: LessonMetadata(
          id: 'zh_basic_vocab_001',
          title: '基本问候 (Basic Greetings)',
          description: 'Learn essential Chinese greetings',
          category: LessonCategory.vocabulary,
          difficulty: LessonDifficulty.beginner,
          targetLanguage: 'chinese',
          estimatedDurationMinutes: 10,
          tags: ['greetings', 'basics'],
        ),
        content: LessonContent(
          lessonId: 'zh_basic_vocab_001',
          content: {
            'sections': [
              {
                'type': 'vocabulary',
                'items': [
                  {
                    'word': '你好',
                    'pinyin': 'nǐ hǎo',
                    'translation': 'Hello',
                    'pronunciation': 'ni hao'
                  },
                  {
                    'word': '早上好',
                    'pinyin': 'zǎo shàng hǎo',
                    'translation': 'Good morning',
                    'pronunciation': 'zao shang hao'
                  },
                ],
              },
            ],
          },
          lastUpdated: DateTime.now(),
        ),
      ),
    ];
  }

  static List<Lesson> _getKoreanLessons() {
    return [
      Lesson(
        metadata: LessonMetadata(
          id: 'ko_basic_vocab_001',
          title: '기본 인사 (Basic Greetings)',
          description: 'Learn essential Korean greetings',
          category: LessonCategory.vocabulary,
          difficulty: LessonDifficulty.beginner,
          targetLanguage: 'korean',
          estimatedDurationMinutes: 10,
          tags: ['greetings', 'basics'],
        ),
        content: LessonContent(
          lessonId: 'ko_basic_vocab_001',
          content: {
            'sections': [
              {
                'type': 'vocabulary',
                'items': [
                  {
                    'word': '안녕하세요',
                    'romanization': 'annyeonghaseyo',
                    'translation': 'Hello',
                    'pronunciation': 'an-nyeong-ha-se-yo'
                  },
                  {
                    'word': '감사합니다',
                    'romanization': 'gamsahamnida',
                    'translation': 'Thank you',
                    'pronunciation': 'gam-sa-ham-ni-da'
                  },
                ],
              },
            ],
          },
          lastUpdated: DateTime.now(),
        ),
      ),
    ];
  }
}
