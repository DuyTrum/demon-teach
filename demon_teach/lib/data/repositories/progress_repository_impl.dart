import 'package:demon_teach/core/errors/failures.dart';
import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/progress.dart';
import 'package:demon_teach/domain/repositories/progress_repository.dart';
import 'package:demon_teach/domain/services/progress_tracker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Implementation of ProgressRepository using SharedPreferences
class ProgressRepositoryImpl implements ProgressRepository {
  final SharedPreferences _prefs;
  final ProgressTracker _tracker;
  static const String _progressKeyPrefix = 'progress_';

  ProgressRepositoryImpl(this._prefs, this._tracker);

  String _getProgressKey(String userId, String targetLanguage) {
    return '${_progressKeyPrefix}${userId}_$targetLanguage';
  }

  @override
  Future<Result<Progress>> getProgress(
      String userId, String targetLanguage) async {
    try {
      final key = _getProgressKey(userId, targetLanguage);
      final progressJson = _prefs.getString(key);

      if (progressJson == null) {
        // Create initial progress
        final initialProgress = Progress.initial(
          userId: userId,
          targetLanguage: targetLanguage,
        );
        await updateProgress(initialProgress);
        return Result.success(initialProgress);
      }

      final progressData = json.decode(progressJson) as Map<String, dynamic>;
      final progress = Progress.fromJson(progressData);

      return Result.success(progress);
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to get progress: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<void>> updateProgress(Progress progress) async {
    try {
      final key = _getProgressKey(progress.userId, progress.targetLanguage);
      final progressJson = json.encode(progress.toJson());
      await _prefs.setString(key, progressJson);

      return Result.success(null);
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to update progress: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<Progress>> addXP(
    String userId,
    String targetLanguage,
    int xp,
  ) async {
    try {
      final progressResult = await getProgress(userId, targetLanguage);

      return await progressResult.when(
        success: (progress) async {
          final updatedProgress = progress.copyWith(
            totalXP: progress.totalXP + xp,
            updatedAt: DateTime.now(),
          );

          final updateResult = await updateProgress(updatedProgress);

          return updateResult.when(
            success: (_) => Result.success(updatedProgress),
            failure: (failure) => Result.failure(failure),
          );
        },
        failure: (failure) => Future.value(Result.failure(failure)),
      );
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to add XP: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<Progress>> updateStreak(
    String userId,
    String targetLanguage,
    DateTime completionDate,
  ) async {
    try {
      final progressResult = await getProgress(userId, targetLanguage);

      return await progressResult.when(
        success: (progress) async {
          final updatedProgress =
              _tracker.updateStreak(progress, completionDate);

          final updateResult = await updateProgress(updatedProgress);

          return updateResult.when(
            success: (_) => Result.success(updatedProgress),
            failure: (failure) => Result.failure(failure),
          );
        },
        failure: (failure) => Future.value(Result.failure(failure)),
      );
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to update streak: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<Progress>> incrementLessonsCompleted(
    String userId,
    String targetLanguage,
  ) async {
    try {
      final progressResult = await getProgress(userId, targetLanguage);

      return await progressResult.when(
        success: (progress) async {
          final updatedProgress = progress.copyWith(
            lessonsCompleted: progress.lessonsCompleted + 1,
            updatedAt: DateTime.now(),
          );

          final updateResult = await updateProgress(updatedProgress);

          return updateResult.when(
            success: (_) => Result.success(updatedProgress),
            failure: (failure) => Result.failure(failure),
          );
        },
        failure: (failure) => Future.value(Result.failure(failure)),
      );
    } catch (e) {
      return Result.failure(
        CacheFailure(
            message: 'Failed to increment lessons completed: ${e.toString()}'),
      );
    }
  }
}
