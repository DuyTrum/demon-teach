import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demon_teach/core/errors/failures.dart';
import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/flashcard.dart';
import 'package:demon_teach/domain/repositories/bookmark_repository.dart';

/// Implementation of BookmarkRepository using Cloud Firestore
class BookmarkRepositoryImpl implements BookmarkRepository {
  final FirebaseFirestore _firestore;

  BookmarkRepositoryImpl(this._firestore);

  /// Helper to get the user's bookmarks subcollection
  CollectionReference<Map<String, dynamic>> _getBookmarkCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('bookmarks');
  }

  @override
  Future<Result<void>> addBookmark(String userId, Flashcard flashcard) async {
    try {
      // Save full flashcard payload in the bookmark document
      await _getBookmarkCollection(userId)
          .doc(flashcard.id)
          .set(flashcard.toJson());
      return Result.success(null);
    } catch (e) {
      return Result.failure(
        ServerFailure(message: 'Failed to bookmark word: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<void>> removeBookmark(String userId, String flashcardId) async {
    try {
      await _getBookmarkCollection(userId).doc(flashcardId).delete();
      return Result.success(null);
    } catch (e) {
      return Result.failure(
        ServerFailure(message: 'Failed to remove bookmark: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<List<Flashcard>>> getBookmarks(String userId) async {
    try {
      final snapshot = await _getBookmarkCollection(userId).get();
      final bookmarks = snapshot.docs.map((doc) {
        return Flashcard.fromJson(doc.data());
      }).toList();
      return Result.success(bookmarks);
    } catch (e) {
      return Result.failure(
        ServerFailure(message: 'Failed to retrieve bookmarks: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<bool>> isBookmarked(String userId, String flashcardId) async {
    try {
      final doc = await _getBookmarkCollection(userId).doc(flashcardId).get();
      return Result.success(doc.exists);
    } catch (e) {
      return Result.failure(
        ServerFailure(message: 'Failed to check bookmark status: ${e.toString()}'),
      );
    }
  }
}
