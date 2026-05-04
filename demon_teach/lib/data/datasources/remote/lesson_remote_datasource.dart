import 'package:dio/dio.dart';
import 'package:demon_teach/core/errors/failures.dart';
import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/lesson.dart';

/// Interface for lesson remote data source
abstract class LessonRemoteDataSource {
  Future<Result<List<Lesson>>> getLessons(String targetLanguage, {String? nativeLanguage});
  Future<Result<Lesson>> getLessonById(String id);
}

/// Implementation of LessonRemoteDataSource using Dio
class LessonRemoteDataSourceImpl implements LessonRemoteDataSource {
  final Dio _dio;

  LessonRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  @override
  Future<Result<List<Lesson>>> getLessons(String targetLanguage, {String? nativeLanguage}) async {
    try {
      final response = await _dio.get(
        '/api/content/lessons',
        queryParameters: {
          'language': targetLanguage,
          if (nativeLanguage != null) 'nativeLanguage': nativeLanguage,
        },
      );

      if (response.statusCode == 200) {
        final List data = response.data['data'] ?? [];
        final lessons = data.map((json) => _mapJsonToLesson(json as Map<String, dynamic>)).toList();
        return Result.success(lessons);
      }

      return Result.failure(const ServerFailure(message: 'Failed to load lessons'));
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: e.message ?? 'Network error'));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<Lesson>> getLessonById(String id) async {
    try {
      final response = await _dio.get('/api/content/lessons/$id');

      if (response.statusCode == 200) {
        final data = response.data['data'];
        return Result.success(_mapJsonToLesson(data as Map<String, dynamic>));
      }

      return Result.failure(const ServerFailure(message: 'Lesson not found'));
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: e.message ?? 'Network error'));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  Lesson _mapJsonToLesson(Map<String, dynamic> json) {
    // Map backend difficulty to frontend difficulty
    String difficulty = 'beginner';
    final backendDifficulty = json['difficulty'] as String;
    if (backendDifficulty == 'intermediate') {
      difficulty = 'intermediate';
    } else if (backendDifficulty == 'advanced') {
      difficulty = 'advanced';
    }

    // Map backend topic to frontend category
    String category = 'vocabulary';
    final backendTopic = json['topic'] as String;
    if (backendTopic == 'conversation') {
      category = 'speaking';
    } else if (backendTopic == 'grammar') {
      category = 'grammar';
    } else if (backendTopic == 'listening') {
      category = 'listening';
    }

    final metadata = {
      'id': json['id'],
      'title': json['title'],
      'description': json['description'] ?? json['title'],
      'category': category,
      'difficulty': difficulty,
      'targetLanguage': json['targetLanguage'],
      'estimatedDurationMinutes': json['durationEstimate'] ?? 10,
      'tags': [],
      'thumbnailUrl': null,
    };

    final content = json['content'] != null ? {
      'lessonId': json['id'],
      'content': json['content'],
      'lastUpdated': json['updatedAt'] ?? DateTime.now().toIso8601String(),
    } : null;

    return Lesson.fromJson({
      'metadata': metadata,
      'content': content,
      'status': 'notStarted',
    });
  }
}
