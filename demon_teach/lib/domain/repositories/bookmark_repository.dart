import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/flashcard.dart';

/// Repository interface for user bookmarked flashcards/vocabulary
abstract class BookmarkRepository {
  /// Add a flashcard to user's favorites/bookmarks
  Future<Result<void>> addBookmark(String userId, Flashcard flashcard);

  /// Remove a flashcard from user's favorites/bookmarks
  Future<Result<void>> removeBookmark(String userId, String flashcardId);

  /// Get all bookmarked flashcards for a specific user
  Future<Result<List<Flashcard>>> getBookmarks(String userId);

  /// Check if a specific flashcard is bookmarked by a user
  Future<Result<bool>> isBookmarked(String userId, String flashcardId);
}
