import 'package:dio/dio.dart';
import 'package:demon_teach/core/errors/failures.dart';
import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/lesson.dart';

/// Interface for lesson remote data source
abstract class LessonRemoteDataSource {
  Future<Result<List<Lesson>>> getLessons(String targetLanguage);
  Future<Result<Lesson>> getLessonById(String id);
  Future<Result<Lesson>> generateLesson({
    required String id,
    required String topic,
    required String language,
    required String difficulty,
    double? assessmentScore,
    String? goalType,
    int? dailyStudyMinutes,
  });
}

/// Implementation of LessonRemoteDataSource using Dio
class LessonRemoteDataSourceImpl implements LessonRemoteDataSource {
  final Dio _dio;

  LessonRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  @override
  Future<Result<List<Lesson>>> getLessons(String targetLanguage) async {
    try {
      final response = await _dio.get(
        '/api/content/lessons',
        queryParameters: {'language': targetLanguage},
      );

      if (response.statusCode == 200) {
        final List data = response.data['data'] ?? [];
        final lessons = data.map((json) => Lesson.fromJson(json)).toList();
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
        return Result.success(Lesson.fromJson(data));
      }

      return Result.failure(const ServerFailure(message: 'Lesson not found'));
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: e.message ?? 'Network error'));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<Lesson>> generateLesson({
    required String id,
    required String topic,
    required String language,
    required String difficulty,
    double? assessmentScore,
    String? goalType,
    int? dailyStudyMinutes,
  }) async {
    try {
      final Map<String, dynamic> postData = {
        'id': id,
        'topic': topic,
        'language': language,
        'difficulty': difficulty,
      };
      if (assessmentScore != null) {
        postData['assessmentScore'] = assessmentScore;
      }
      if (goalType != null) {
        postData['goalType'] = goalType;
      }
      if (dailyStudyMinutes != null) {
        postData['dailyStudyMinutes'] = dailyStudyMinutes;
      }
      final response = await _dio.post(
        '/api/generator/lesson',
        data: postData,
      );

      if (response.statusCode == 201) {
        final data = response.data['data'];
        return Result.success(Lesson.fromJson(data));
      }

      return Result.failure(const ServerFailure(message: 'Failed to generate AI lesson'));
    } on DioException catch (e) {
      return Result.failure(ServerFailure(message: e.response?.data['message'] ?? e.message ?? 'Network error'));
    } catch (e) {
      return Result.failure(ServerFailure(message: e.toString()));
    }
  }
}
