import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demon_teach/core/errors/failures.dart';
import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/learning_path.dart';
import 'package:demon_teach/domain/repositories/learning_path_repository.dart';

/// Implementation of LearningPathRepository using Cloud Firestore
class LearningPathRepositoryImpl implements LearningPathRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  LearningPathRepositoryImpl([dynamic _]); // Accept parameter for backward compatibility

  String _getDocId({required String userId, required String targetLanguage}) {
    return 'user_${userId}_$targetLanguage';
  }

  @override
  Future<Result<void>> saveLearningPath(LearningPath path) async {
    try {
      final docId = _getDocId(
        userId: path.userId,
        targetLanguage: path.targetLanguage,
      );
      await _firestore.collection('learning_paths').doc(docId).set(path.toJson());
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
      final docId = _getDocId(userId: userId, targetLanguage: targetLanguage);
      final docSnap = await _firestore.collection('learning_paths').doc(docId).get();

      if (!docSnap.exists || docSnap.data() == null) {
        return Result.success(null);
      }

      final parsedPath = LearningPath.fromJson(docSnap.data()!);
      final path = parsedPath.id == docId 
          ? parsedPath 
          : parsedPath.copyWith(id: docId);
          
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
      await _firestore
          .collection('learning_paths')
          .doc(pathId)
          .update({
        'currentLessonIndex': currentLessonIndex,
        'lastModifiedAt': DateTime.now().toIso8601String(),
      });

      return Result.success(null);
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to update progress: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<void>> deleteLearningPath(String pathId) async {
    try {
      await _firestore.collection('learning_paths').doc(pathId).delete();
      return Result.success(null);
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to delete learning path: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<bool>> hasLearningPath({
    required String userId,
    required String targetLanguage,
  }) async {
    try {
      final docId = _getDocId(userId: userId, targetLanguage: targetLanguage);
      final docSnap = await _firestore.collection('learning_paths').doc(docId).get();
      return Result.success(docSnap.exists);
    } catch (e) {
      return Result.failure(
        CacheFailure(
            message: 'Failed to check learning path existence: ${e.toString()}'),
      );
    }
  }
}
