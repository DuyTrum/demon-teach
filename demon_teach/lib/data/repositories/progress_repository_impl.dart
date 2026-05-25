import 'package:cloud_firestore/cloud_firestore.dart';
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
      return Result.success(progress);
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
}
