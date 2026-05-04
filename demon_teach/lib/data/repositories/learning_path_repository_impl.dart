import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:demon_teach/core/errors/failures.dart';
import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/learning_path.dart';
import 'package:demon_teach/domain/repositories/learning_path_repository.dart';

/// Implementation of LearningPathRepository using SharedPreferences
class LearningPathRepositoryImpl implements LearningPathRepository {
  final SharedPreferences _prefs;

  // Keys for SharedPreferences
  static const String _keyPrefix = 'learning_path_';

  LearningPathRepositoryImpl(this._prefs);

  /// Generate storage key for user and language
  String _getKey({required String userId, required String targetLanguage}) {
    return '$_keyPrefix${userId}_$targetLanguage';
  }

  @override
  Future<Result<void>> saveLearningPath(LearningPath path) async {
    try {
      final key = _getKey(
        userId: path.userId,
        targetLanguage: path.targetLanguage,
      );
      final json = jsonEncode(path.toJson());
      await _prefs.setString(key, json);
      return Result.success(null);
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to save learning path: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<LearningPath?>> getLearningPath({
    required String userId,
    required String targetLanguage,
  }) async {
    try {
      final key = _getKey(userId: userId, targetLanguage: targetLanguage);
      final jsonString = _prefs.getString(key);

      if (jsonString == null) {
        return Result.success(null);
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final path = LearningPath.fromJson(json);
      return Result.success(path);
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to get learning path: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<void>> updateProgress({
    required String pathId,
    required int currentLessonIndex,
  }) async {
    try {
      // Find the path by iterating through all stored paths
      final keys = _prefs.getKeys().where((key) => key.startsWith(_keyPrefix));

      for (final key in keys) {
        final jsonString = _prefs.getString(key);
        if (jsonString != null) {
          final json = jsonDecode(jsonString) as Map<String, dynamic>;
          if (json['id'] == pathId) {
            // Update the current lesson index
            json['currentLessonIndex'] = currentLessonIndex;
            json['lastModifiedAt'] = DateTime.now().toIso8601String();

            // Save back to SharedPreferences
            await _prefs.setString(key, jsonEncode(json));
            return Result.success(null);
          }
        }
      }

      return Result.failure(
        CacheFailure(message: 'Learning path not found: $pathId'),
      );
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to update progress: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<void>> deleteLearningPath(String pathId) async {
    try {
      // Find and delete the path by iterating through all stored paths
      final keys = _prefs.getKeys().where((key) => key.startsWith(_keyPrefix));

      for (final key in keys) {
        final jsonString = _prefs.getString(key);
        if (jsonString != null) {
          final json = jsonDecode(jsonString) as Map<String, dynamic>;
          if (json['id'] == pathId) {
            await _prefs.remove(key);
            return Result.success(null);
          }
        }
      }

      return Result.failure(
        CacheFailure(message: 'Learning path not found: $pathId'),
      );
    } catch (e) {
      return Result.failure(
        CacheFailure(
            message: 'Failed to delete learning path: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<bool>> hasLearningPath({
    required String userId,
    required String targetLanguage,
  }) async {
    try {
      final key = _getKey(userId: userId, targetLanguage: targetLanguage);
      final exists = _prefs.containsKey(key);
      return Result.success(exists);
    } catch (e) {
      return Result.failure(
        CacheFailure(
            message:
                'Failed to check learning path existence: ${e.toString()}'),
      );
    }
  }
}
