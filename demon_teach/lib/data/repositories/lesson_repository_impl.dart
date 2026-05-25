import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:demon_teach/core/errors/failures.dart';
import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/lesson.dart';
import 'package:demon_teach/domain/repositories/lesson_repository.dart';
import 'package:demon_teach/domain/repositories/learning_path_repository.dart';
import 'package:demon_teach/data/datasources/remote/lesson_remote_datasource.dart';
import 'package:demon_teach/data/datasources/local/mock_lesson_data.dart';

/// Implementation of LessonRepository using Remote API and local fallbacks
class LessonRepositoryImpl implements LessonRepository {
  final SharedPreferences _prefs;
  final LearningPathRepository _learningPathRepository;
  final LessonRemoteDataSource _remoteDataSource;

  // Keys for SharedPreferences
  static const String _progressKeyPrefix = 'lesson_progress_';
  static const String _downloadedLessonsKey = 'downloaded_lessons';

  LessonRepositoryImpl(this._prefs, this._learningPathRepository, this._remoteDataSource);

  /// Generate storage key for user lesson progress
  String _getProgressKey({required String userId, required String lessonId}) {
    return '$_progressKeyPrefix${userId}_$lessonId';
  }

  @override
  Future<Result<Lesson?>> getLessonById(String lessonId,
      {bool includeContent = true}) async {
    final nativeLanguage = _prefs.getString('native_language') ?? 'en';
    
    // Fetch from remote first. If not found on server, generate it using AI!
    try {
      final remoteResult = await _remoteDataSource.getLessonById(lessonId);
      return await remoteResult.when(
        success: (lesson) {
          if (!includeContent) {
            return Result.success(lesson.copyWith(content: null));
          }
          return Result.success(lesson);
        },
        failure: (failure) async {
          // If not found on server, generate it using AI!
          final genResult = await _generateLessonByAi(lessonId);
          return genResult.when(
            success: (generatedLesson) {
              if (!includeContent) {
                return Result.success(generatedLesson.copyWith(content: null));
              }
              return Result.success(generatedLesson);
            },
            failure: (genFailure) {
              // Fallback to a local mock fallback as last resort
              final fallbackLesson = MockLessonData.getLessonById(lessonId, nativeLanguage: nativeLanguage);
              if (fallbackLesson != null) {
                if (!includeContent) {
                  return Result.success(fallbackLesson.copyWith(content: null));
                }
                return Result.success(fallbackLesson);
              }
              return Result.failure(genFailure);
            },
          );
        },
      );
    } catch (e) {
      // Fallback to local mock data on exception
      final fallbackLesson = MockLessonData.getLessonById(lessonId, nativeLanguage: nativeLanguage);
      if (fallbackLesson != null) {
        if (!includeContent) {
          return Result.success(fallbackLesson.copyWith(content: null));
        }
        return Result.success(fallbackLesson);
      }
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<Lesson>>> getLessonsByIds(
    List<String> lessonIds, {
    bool includeContent = false,
  }) async {
    try {
      final lessons = <Lesson>[];

      for (final lessonId in lessonIds) {
        final result =
            await getLessonById(lessonId, includeContent: includeContent);
        result.when(
          success: (lesson) {
            if (lesson != null) {
              lessons.add(lesson);
            }
          },
          failure: (_) {
            // Skip failed lessons
          },
        );
      }

      return Result.success(lessons);
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to get lessons: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<Lesson?>> getNextLesson({
    required String userId,
    required String targetLanguage,
  }) async {
    try {
      // Get learning path
      final pathResult = await _learningPathRepository.getLearningPath(
        userId: userId,
        targetLanguage: targetLanguage,
      );

      return pathResult.when(
        success: (path) async {
          if (path == null || path.currentLessonId == null) {
            return Result.success(null);
          }

          // Get current lesson
          final lessonResult = await getLessonById(path.currentLessonId!);
          return lessonResult.when(
            success: (lesson) async {
              if (lesson == null) {
                return Result.success(null);
              }

              // Get user progress for this lesson
              final progressResult = await getUserLessonProgress(
                userId: userId,
                lessonId: lesson.metadata.id,
              );

              return progressResult.when(
                success: (progressLesson) {
                  // Merge lesson with user progress
                  if (progressLesson != null) {
                    return Result.success(lesson.copyWith(
                      status: progressLesson.status,
                      progressPercentage: progressLesson.progressPercentage,
                      startedAt: progressLesson.startedAt,
                      completedAt: progressLesson.completedAt,
                      score: progressLesson.score,
                    ));
                  }
                  return Result.success(lesson);
                },
                failure: (failure) => Result.success(lesson),
              );
            },
            failure: (failure) => Result.failure(failure),
          );
        },
        failure: (failure) => Result.failure(failure),
      );
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to get next lesson: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<void>> saveLessonProgress({
    required String userId,
    required String lessonId,
    required LessonStatus status,
    int? progressPercentage,
    DateTime? startedAt,
    DateTime? completedAt,
    int? score,
  }) async {
    try {
      final key = _getProgressKey(userId: userId, lessonId: lessonId);

      final progressData = {
        'userId': userId,
        'lessonId': lessonId,
        'status': status.name,
        'progressPercentage': progressPercentage,
        'startedAt': startedAt?.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'score': score,
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      await _prefs.setString(key, jsonEncode(progressData));
      return Result.success(null);
    } catch (e) {
      return Result.failure(
        CacheFailure(
            message: 'Failed to save lesson progress: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<void>> completeLesson({
    required String userId,
    required String lessonId,
    required int score,
  }) async {
    return await saveLessonProgress(
      userId: userId,
      lessonId: lessonId,
      status: LessonStatus.completed,
      progressPercentage: 100,
      completedAt: DateTime.now(),
      score: score,
    );
  }

  @override
  Future<Result<Lesson?>> getUserLessonProgress({
    required String userId,
    required String lessonId,
  }) async {
    try {
      final key = _getProgressKey(userId: userId, lessonId: lessonId);
      final jsonString = _prefs.getString(key);

      if (jsonString == null) {
        return Result.success(null);
      }

      final progressData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Get lesson metadata
      final lessonResult = await getLessonById(lessonId, includeContent: false);

      return lessonResult.when(
        success: (lesson) {
          if (lesson == null) {
            return Result.success(null);
          }

          // Create lesson with progress data
          return Result.success(lesson.copyWith(
            status: LessonStatus.values.firstWhere(
              (e) => e.name == progressData['status'],
              orElse: () => LessonStatus.notStarted,
            ),
            progressPercentage: progressData['progressPercentage'] as int?,
            startedAt: progressData['startedAt'] != null
                ? DateTime.parse(progressData['startedAt'] as String)
                : null,
            completedAt: progressData['completedAt'] != null
                ? DateTime.parse(progressData['completedAt'] as String)
                : null,
            score: progressData['score'] as int?,
          ));
        },
        failure: (failure) => Result.failure(failure),
      );
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to get lesson progress: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<bool>> isLessonAvailableOffline(String lessonId) async {
    try {
      final downloadedIds = await getDownloadedLessonIds();
      return downloadedIds.when(
        success: (ids) => Result.success(ids.contains(lessonId)),
        failure: (failure) => Result.failure(failure),
      );
    } catch (e) {
      return Result.failure(
        CacheFailure(
            message: 'Failed to check offline availability: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<void>> downloadLessonForOffline(String lessonId) async {
    try {
      final downloadedResult = await getDownloadedLessonIds();

      return downloadedResult.when(
        success: (ids) async {
          if (!ids.contains(lessonId)) {
            ids.add(lessonId);
            await _prefs.setString(_downloadedLessonsKey, jsonEncode(ids));
          }
          return Result.success(null);
        },
        failure: (failure) => Result.failure(failure),
      );
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to download lesson: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<List<Lesson>>> getLessonsByLanguage(String language) async {
    final nativeLanguage = _prefs.getString('native_language') ?? 'en';
    try {
      final result = await _remoteDataSource.getLessons(language);
      return result.when(
        success: (lessons) {
          if (lessons.isEmpty) {
            final mockLessons = MockLessonData.getLessonsForLanguage(language, nativeLanguage: nativeLanguage);
            if (mockLessons.isNotEmpty) return Result.success(mockLessons);
          }
          return Result.success(lessons);
        },
        failure: (failure) {
          final mockLessons = MockLessonData.getLessonsForLanguage(language, nativeLanguage: nativeLanguage);
          if (mockLessons.isNotEmpty) return Result.success(mockLessons);
          return Result.failure(failure);
        },
      );
    } catch (e) {
      final mockLessons = MockLessonData.getLessonsForLanguage(language, nativeLanguage: nativeLanguage);
      if (mockLessons.isNotEmpty) return Result.success(mockLessons);
      return Result.failure(
        ServerFailure(message: 'Failed to fetch lessons: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<List<String>>> getDownloadedLessonIds() async {
    try {
      final jsonString = _prefs.getString(_downloadedLessonsKey);

      if (jsonString == null) {
        return Result.success([]);
      }

      final ids = List<String>.from(jsonDecode(jsonString) as List);
      return Result.success(ids);
    } catch (e) {
      return Result.failure(
        CacheFailure(
            message: 'Failed to get downloaded lessons: ${e.toString()}'),
      );
    }
  }

  Future<Result<Lesson>> _generateLessonByAi(String lessonId) async {
    // Parse target language, difficulty, and determine topic from lessonId
    // Suffix format: {language}_{difficulty}_{category}_{number}
    // Example: en_basic_vocab_003
    final parts = lessonId.split('_');
    if (parts.length < 3) {
      return Result.failure(const ServerFailure(message: 'Invalid lesson ID format for generation'));
    }

    final langCode = parts[0];
    final difficultyStr = parts[1]; // basic, intermediate, advanced
    final categoryStr = parts[2]; // vocab, grammar, listening, speaking
    final numberStr = parts.length > 3 ? parts[3] : '001';

    // Map difficultyStr to backend ENUM: 'basic', 'intermediate', 'advanced'
    String difficulty = 'basic';
    if (difficultyStr == 'intermediate') {
      difficulty = 'intermediate';
    } else if (difficultyStr == 'advanced') {
      difficulty = 'advanced';
    }

    // Retrieve assessment score if available for custom difficulty
    final userId = _prefs.getString('current_user_id');
    double? assessmentScore;
    if (userId != null) {
      final key = 'assessment_result_${userId}_$langCode';
      final resultString = _prefs.getString(key);
      if (resultString != null) {
        try {
          final resultJson = jsonDecode(resultString) as Map<String, dynamic>;
          assessmentScore = (resultJson['score'] as num?)?.toDouble();
        } catch (e) {
          print('Error parsing assessment score: $e');
        }
      }
    }

    // Retrieve goal preferences
    final goalJsonString = _prefs.getString('learning_goal_preferences');
    String? goalType;
    int? dailyStudyMinutes;
    if (goalJsonString != null) {
      try {
        final goalJson = jsonDecode(goalJsonString) as Map<String, dynamic>;
        goalType = goalJson['goalType'] as String?;
        dailyStudyMinutes = goalJson['dailyStudyMinutes'] as int?;
      } catch (e) {
        print('Error parsing goal preferences: $e');
      }
    }

    // Map suffix/number to topic based on goalType
    final String topicKey = '${categoryStr}_$numberStr';
    String topic = 'General Practice';

    if (goalType == 'work') {
      if (topicKey == 'vocab_001') {
        topic = 'Business Greetings & Introductions';
      } else if (topicKey == 'vocab_002') {
        topic = 'Work Schedules & Telling Time';
      } else if (topicKey == 'vocab_003') {
        topic = 'Office Roles & Professional Relationships';
      } else if (topicKey == 'vocab_004') {
        topic = 'Business Lunches & Dining with Clients';
      } else if (topicKey == 'vocab_005') {
        topic = 'Daily Work Routines & Meetings';
      } else if (topicKey == 'grammar_001') {
        topic = 'Present Tense in Business Emails';
      } else if (topicKey == 'grammar_002') {
        topic = 'Writing Professional Sentences';
      } else if (topicKey == 'grammar_003') {
        topic = 'Asking Questions in Meetings';
      } else if (topicKey == 'listening_001') {
        topic = 'Listening to Office Conversations';
      } else if (topicKey == 'speaking_001') {
        topic = 'Professional Self-Introductions';
      } else if (categoryStr == 'vocab') {
        topic = 'Business Vocabulary Expansion Part $numberStr';
      } else if (categoryStr == 'grammar') {
        topic = 'Professional Grammar Part $numberStr';
      } else if (categoryStr == 'listening') {
        topic = 'Office Listening Session $numberStr';
      } else if (categoryStr == 'speaking') {
        topic = 'Professional Speaking Presentation $numberStr';
      }
    } else if (goalType == 'travel') {
      if (topicKey == 'vocab_001') {
        topic = 'Travel Greetings & Airport Introductions';
      } else if (topicKey == 'vocab_002') {
        topic = 'Booking Schedules, Flights & Time Zones';
      } else if (topicKey == 'vocab_003') {
        topic = 'Meeting Fellow Travelers & Local Guides';
      } else if (topicKey == 'vocab_004') {
        topic = 'Ordering Food & Local Dining';
      } else if (topicKey == 'vocab_005') {
        topic = 'Daily Sightseeing & Travel Activities';
      } else if (topicKey == 'grammar_001') {
        topic = 'Present Tense for Booking & Directions';
      } else if (topicKey == 'grammar_002') {
        topic = 'Basic Sentences for Navigation';
      } else if (topicKey == 'grammar_003') {
        topic = 'Asking Questions at Hotels & Customs';
      } else if (topicKey == 'listening_001') {
        topic = 'Listening to Airport Announcements';
      } else if (topicKey == 'speaking_001') {
        topic = 'Asking for Directions & Tourist Help';
      } else if (categoryStr == 'vocab') {
        topic = 'Travel Vocabulary Expansion Part $numberStr';
      } else if (categoryStr == 'grammar') {
        topic = 'Travel Grammar Essentials Part $numberStr';
      } else if (categoryStr == 'listening') {
        topic = 'Travel Listening Practice $numberStr';
      } else if (categoryStr == 'speaking') {
        topic = 'Tourist Speaking Exercises $numberStr';
      }
    } else if (goalType == 'conversation') {
      if (topicKey == 'vocab_001') {
        topic = 'Casual Greetings & Friend Introductions';
      } else if (topicKey == 'vocab_002') {
        topic = 'Socializing & Scheduling Meetups';
      } else if (topicKey == 'vocab_003') {
        topic = 'Talking About Family & Friends';
      } else if (topicKey == 'vocab_004') {
        topic = 'Conversing Over Food & Drinks';
      } else if (topicKey == 'vocab_005') {
        topic = 'Daily Social Activities & Hobbies';
      } else if (topicKey == 'grammar_001') {
        topic = 'Present Tense in Casual Chats';
      } else if (topicKey == 'grammar_002') {
        topic = 'Forming Conversational Sentences';
      } else if (topicKey == 'grammar_003') {
        topic = 'Asking Open Questions in Conversation';
      } else if (topicKey == 'listening_001') {
        topic = 'Listening to Friendly Chats';
      } else if (topicKey == 'speaking_001') {
        topic = 'Casual Self-Introductions';
      } else if (categoryStr == 'vocab') {
        topic = 'Conversational Vocabulary Part $numberStr';
      } else if (categoryStr == 'grammar') {
        topic = 'Conversational Grammar Part $numberStr';
      } else if (categoryStr == 'listening') {
        topic = 'Social Listening Session $numberStr';
      } else if (categoryStr == 'speaking') {
        topic = 'Daily Speaking Practice $numberStr';
      }
    } else if (goalType == 'exam') {
      if (topicKey == 'vocab_001') {
        topic = 'Academic Greetings & Formal Introductions';
      } else if (topicKey == 'vocab_002') {
        topic = 'Time Concepts & Quantitative Data';
      } else if (topicKey == 'vocab_003') {
        topic = 'Social Structures & Human Relationships';
      } else if (topicKey == 'vocab_004') {
        topic = 'Gastronomy & Cultural Food Vocabulary';
      } else if (topicKey == 'vocab_005') {
        topic = 'Academic Schedules & Daily Habits';
      } else if (topicKey == 'grammar_001') {
        topic = 'Present Tense in Academic Writing';
      } else if (topicKey == 'grammar_002') {
        topic = 'Formal Sentence Structures';
      } else if (topicKey == 'grammar_003') {
        topic = 'Formulating Hypothesis & Questions';
      } else if (topicKey == 'listening_001') {
        topic = 'Listening to Lectures & News Reports';
      } else if (topicKey == 'speaking_001') {
        topic = 'Structured Oral Self-Introductions';
      } else if (categoryStr == 'vocab') {
        topic = 'Exam Vocabulary Expansion Part $numberStr';
      } else if (categoryStr == 'grammar') {
        topic = 'Exam Grammar Essentials Part $numberStr';
      } else if (categoryStr == 'listening') {
        topic = 'Academic Listening Session $numberStr';
      } else if (categoryStr == 'speaking') {
        topic = 'Formal Speaking Challenge $numberStr';
      }
    } else {
      // General fallbacks
      if (topicKey == 'vocab_001') {
        topic = 'Greetings & Introductions';
      } else if (topicKey == 'vocab_002') {
        topic = 'Numbers & Telling Time';
      } else if (topicKey == 'vocab_003') {
        topic = 'Family & Relationships';
      } else if (topicKey == 'vocab_004') {
        topic = 'Food & Dining';
      } else if (topicKey == 'vocab_005') {
        topic = 'Daily Routines & Activities';
      } else if (topicKey == 'grammar_001') {
        topic = 'Present Tense Grammar';
      } else if (topicKey == 'grammar_002') {
        topic = 'Basic Sentence Structure';
      } else if (topicKey == 'grammar_003') {
        topic = 'Asking Questions';
      } else if (topicKey == 'listening_001') {
        topic = 'Everyday Conversations';
      } else if (topicKey == 'speaking_001') {
        topic = 'Self Introduction Speaking';
      } else {
        if (categoryStr == 'vocab') {
          topic = 'Vocabulary expansion Part $numberStr';
        } else if (categoryStr == 'grammar') {
          topic = 'Grammar Essentials Part $numberStr';
        } else if (categoryStr == 'listening') {
          topic = 'Listening practice session $numberStr';
        } else if (categoryStr == 'speaking') {
          topic = 'Speaking challenge $numberStr';
        }
      }
    }

    return await _remoteDataSource.generateLesson(
      id: lessonId,
      topic: topic,
      language: langCode,
      difficulty: difficulty,
      assessmentScore: assessmentScore,
      goalType: goalType,
      dailyStudyMinutes: dailyStudyMinutes,
    );
  }
}
