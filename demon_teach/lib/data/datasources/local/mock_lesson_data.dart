import 'package:demon_teach/domain/entities/lesson.dart';

/// Mock lesson data for testing and development
class MockLessonData {
  /// Get mock lessons for a specific language and proficiency level
  static List<Lesson> getLessonsForLanguage(String language, {String nativeLanguage = 'en'}) {
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

    return lessons.map((lesson) => _translateLesson(lesson, nativeLanguage)).toList();
  }

  static Lesson _translateLesson(Lesson lesson, String nativeLanguage) {
    if (nativeLanguage != 'vi') return lesson;

    final titleTranslations = {
      'Basic Greetings': 'Chào hỏi cơ bản',
      'Numbers and Time': 'Số đếm và thời gian',
      'Present Simple Tense': 'Thì hiện tại đơn',
      'Work and Professions': 'Công việc và nghề nghiệp',
      'Academic Vocabulary': 'Từ vựng học thuật',
      '基本问候 (Basic Greetings)': 'Chào hỏi cơ bản',
      '기본 인사 (Basic Greetings)': 'Chào hỏi cơ bản',
    };

    final descriptionTranslations = {
      'Learn essential greetings and introductions in English': 'Học các câu chào hỏi và giới thiệu cơ bản bằng tiếng Anh',
      'Master numbers 1-100 and telling time': 'Nắm vững số đếm từ 1-100 và cách nói giờ',
      'Learn how to use present simple tense': 'Học cách sử dụng thì hiện tại đơn',
      'Vocabulary related to jobs and workplace': 'Từ vựng liên quan đến công việc và nơi làm việc',
      'Advanced vocabulary for academic contexts': 'Từ vựng nâng cao cho ngữ cảnh học thuật',
      'Learn essential Chinese greetings': 'Học các câu chào hỏi cơ bản bằng tiếng Trung',
      'Learn essential Korean greetings': 'Học các câu chào hỏi cơ bản bằng tiếng Hàn',
    };

    final contentTranslations = {
      'Present simple is used for habits, facts, and general truths.': 'Thì hiện tại đơn được dùng để diễn tả thói quen, sự thật hiển nhiên và chân lý.',
      'How do you greet someone in the morning?': 'Bạn chào ai đó vào buổi sáng như thế nào?',
      'Hello': 'Xin chào',
      'Good morning': 'Chào buổi sáng',
      'Thank you': 'Cảm ơn',
      'I work every day.': 'Tôi làm việc mỗi ngày.',
      'She likes coffee.': 'Cô ấy thích cà phê.',
      'They live in New York.': 'Họ sống ở New York.',
    };

    final metadata = LessonMetadata(
      id: lesson.metadata.id,
      title: titleTranslations[lesson.metadata.title] ?? lesson.metadata.title,
      description: descriptionTranslations[lesson.metadata.description] ?? lesson.metadata.description,
      category: lesson.metadata.category,
      difficulty: lesson.metadata.difficulty,
      targetLanguage: lesson.metadata.targetLanguage,
      estimatedDurationMinutes: lesson.metadata.estimatedDurationMinutes,
      tags: lesson.metadata.tags,
      thumbnailUrl: lesson.metadata.thumbnailUrl,
    );

    if (lesson.content == null) {
      return lesson.copyWith(metadata: metadata);
    }

    final rawContent = lesson.content!.content;
    final Map<String, dynamic> newContent = Map.from(rawContent);

    if (newContent['sections'] != null) {
      final sections = List<Map<String, dynamic>>.from(newContent['sections'].map((s) => Map<String, dynamic>.from(s)));
      for (var section in sections) {
        if (section['type'] == 'vocabulary' && section['items'] != null) {
          final items = List<Map<String, dynamic>>.from(section['items'].map((i) => Map<String, dynamic>.from(i)));
          for (var item in items) {
            if (item['translation'] != null) {
              item['translation'] = contentTranslations[item['translation']] ?? item['translation'];
            }
          }
          section['items'] = items;
        } else if (section['type'] == 'explanation' && section['content'] != null) {
          section['content'] = contentTranslations[section['content']] ?? section['content'];
        } else if (section['type'] == 'practice' && section['exercises'] != null) {
          final exercises = List<Map<String, dynamic>>.from(section['exercises'].map((e) => Map<String, dynamic>.from(e)));
          for (var exercise in exercises) {
            if (exercise['question'] != null) {
              exercise['question'] = contentTranslations[exercise['question']] ?? exercise['question'];
            }
          }
          section['exercises'] = exercises;
        }
      }
      newContent['sections'] = sections;
    }

    return lesson.copyWith(
      metadata: metadata,
      content: LessonContent(
        lessonId: lesson.content!.lessonId,
        lastUpdated: lesson.content!.lastUpdated,
        content: newContent,
      ),
    );
  }

  /// Get lesson by ID
  static Lesson? getLessonById(String lessonId, {String nativeLanguage = 'en'}) {
    final allLessons = [
      ..._getEnglishLessons(),
      ..._getChineseLessons(),
      ..._getKoreanLessons(),
    ];

    try {
      final lesson = allLessons.firstWhere((lesson) => lesson.metadata.id == lessonId);
      return _translateLesson(lesson, nativeLanguage);
    } catch (e) {
      Lesson fallback;
      final idLower = lessonId.toLowerCase();
      if (idLower.contains('grammar')) {
        fallback = allLessons.firstWhere((l) => l.metadata.id == 'en_basic_grammar_001', orElse: () => allLessons.first);
      } else if (idLower.contains('speaking') || idLower.contains('listening')) {
        fallback = allLessons.firstWhere((l) => l.metadata.id == 'en_basic_vocab_002', orElse: () => allLessons.first);
      } else {
        final lastChar = idLower.isNotEmpty ? idLower.codeUnitAt(idLower.length - 1) : 0;
        if (lastChar % 3 == 0) {
          fallback = allLessons.firstWhere((l) => l.metadata.id == 'en_intermediate_vocab_001', orElse: () => allLessons.first);
        } else if (lastChar % 2 == 0) {
          fallback = allLessons.firstWhere((l) => l.metadata.id == 'en_basic_vocab_002', orElse: () => allLessons.first);
        } else {
          fallback = allLessons.firstWhere((l) => l.metadata.id == 'en_basic_vocab_001', orElse: () => allLessons.first);
        }
      }

      final fallbackMetadata = LessonMetadata(
        id: lessonId,
        title: 'Mock Lesson ${lessonId.split('_').last}',
        description: fallback.metadata.description,
        category: fallback.metadata.category,
        difficulty: fallback.metadata.difficulty,
        targetLanguage: fallback.metadata.targetLanguage,
        estimatedDurationMinutes: fallback.metadata.estimatedDurationMinutes,
        tags: fallback.metadata.tags,
        thumbnailUrl: fallback.metadata.thumbnailUrl,
      );
      final fallbackContent = fallback.content != null 
          ? LessonContent(
              lessonId: lessonId,
              content: fallback.content!.content,
              lastUpdated: fallback.content!.lastUpdated,
            )
          : null;
          
      final modifiedFallback = fallback.copyWith(
        metadata: fallbackMetadata,
        content: fallbackContent,
      );
      return _translateLesson(modifiedFallback, nativeLanguage);
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
