import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demon_teach/core/constants/app_constants.dart';
import 'package:demon_teach/core/errors/failures.dart';
import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/progress.dart';
import 'package:demon_teach/domain/repositories/progress_repository.dart';
import 'package:demon_teach/domain/services/progress_tracker.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Implementation of ProgressRepository using Firestore
class ProgressRepositoryImpl implements ProgressRepository {
  final SharedPreferences _prefs;
  final ProgressTracker _tracker;

  ProgressRepositoryImpl(this._prefs, this._tracker);

  String _getDocumentId(String userId, String targetLanguage) {
    return 'progress_${userId}_$targetLanguage';
  }

  @override
  Future<Result<Progress>> getProgress(
      String userId, String targetLanguage) async {
    try {
      final docId = _getDocumentId(userId, targetLanguage);
      final docSnap = await FirebaseFirestore.instance.collection('progress').doc(docId).get();

      if (!docSnap.exists || docSnap.data() == null) {
        // Create initial progress
        final initialProgress = Progress.initial(
          userId: userId,
          targetLanguage: targetLanguage,
        );
        await updateProgress(initialProgress);
        return Result.success(initialProgress);
      }

      final progress = Progress.fromJson(docSnap.data()!);
      final regeneratedProgress = _tracker.checkAndRegenerateHearts(progress);
      if (regeneratedProgress != progress) {
        await updateProgress(regeneratedProgress);
      }
      return Result.success(regeneratedProgress);
    } catch (e) {
      return Result.failure(
        ServerFailure(message: 'Failed to get progress from Firestore: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<void>> updateProgress(Progress progress) async {
    try {
      final docId = _getDocumentId(progress.userId, progress.targetLanguage);
      await FirebaseFirestore.instance
          .collection('progress')
          .doc(docId)
          .set(progress.toJson());

      return Result.success(null);
    } catch (e) {
      return Result.failure(
        ServerFailure(message: 'Failed to update progress on Firestore: ${e.toString()}'),
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
          int oldLevel = (progress.totalXP / 100).floor() + 1;
          int newLevel = ((progress.totalXP + xp) / 100).floor() + 1;
          int levelsGained = newLevel - oldLevel;
          int soulsGained = levelsGained * 50; // 50 souls per level up

          final updatedProgress = progress.copyWith(
            totalXP: progress.totalXP + xp,
            souls: progress.souls + soulsGained,
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
        ServerFailure(message: 'Failed to add XP: ${e.toString()}'),
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
        ServerFailure(message: 'Failed to update streak: ${e.toString()}'),
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
        ServerFailure(
            message: 'Failed to increment lessons completed: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<Progress>> consumeHeart(
    String userId,
    String targetLanguage,
  ) async {
    try {
      final progressResult = await getProgress(userId, targetLanguage);

      return await progressResult.when(
        success: (progress) async {
          if (progress.hearts <= 0) {
            return Result.success(progress);
          }

          final now = DateTime.now();
          // If hearts was at max (5), set regen timer to now when consuming
          final newRegenTime = progress.hearts == AppConstants.maxHearts
              ? now
              : progress.lastHeartRegenTime;

          final updatedProgress = progress.copyWith(
            hearts: progress.hearts - 1,
            lastHeartRegenTime: newRegenTime,
            updatedAt: now,
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
        ServerFailure(message: 'Failed to consume heart: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<Progress>> refillHeartWithSouls(
    String userId,
    String targetLanguage,
  ) async {
    try {
      final progressResult = await getProgress(userId, targetLanguage);

      return await progressResult.when(
        success: (progress) async {
          if (progress.hearts >= AppConstants.maxHearts) {
            return Result.failure(
              const ServerFailure(message: '👿 Thần lực đã đầy 5/5 Tim, không thể nạp thêm!'),
            );
          }

          if (progress.souls < 50) {
            return Result.failure(
              const ServerFailure(message: '👿 Ngươi không đủ 50 Souls (Linh hồn) để đổi lấy ma lực!'),
            );
          }

          final now = DateTime.now();
          final newHearts = progress.hearts + 1;
          final updatedProgress = progress.copyWith(
            hearts: newHearts,
            souls: progress.souls - 50,
            // If hearts becomes full, reset regen timer to now
            lastHeartRegenTime: newHearts == AppConstants.maxHearts ? now : progress.lastHeartRegenTime,
            updatedAt: now,
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
        ServerFailure(message: 'Failed to refill heart with Souls: ${e.toString()}'),
      );
    }
  }
}
