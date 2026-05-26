import 'package:demon_teach/domain/entities/flashcard.dart';
import 'package:demon_teach/domain/repositories/bookmark_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for the BookmarkRepository interface (must be overridden in main.dart)
final bookmarkRepositoryProvider = Provider<BookmarkRepository>((ref) {
  throw UnimplementedError('BookmarkRepository must be overridden');
});

/// State structure for user bookmarks
class BookmarkState {
  final List<Flashcard> bookmarks;
  final Set<String> bookmarkedIds;
  final bool isLoading;
  final String? error;

  const BookmarkState({
    this.bookmarks = const [],
    this.bookmarkedIds = const {},
    this.isLoading = false,
    this.error,
  });

  BookmarkState copyWith({
    List<Flashcard>? bookmarks,
    Set<String>? bookmarkedIds,
    bool? isLoading,
    String? error,
  }) {
    return BookmarkState(
      bookmarks: bookmarks ?? this.bookmarks,
      bookmarkedIds: bookmarkedIds ?? this.bookmarkedIds,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// StateNotifier to manage adding, removing, and listing bookmarks
class BookmarkNotifier extends StateNotifier<BookmarkState> {
  final BookmarkRepository _repository;

  BookmarkNotifier(this._repository) : super(const BookmarkState());

  /// Load user's bookmarks from Firestore
  Future<void> loadBookmarks(String userId) async {
    state = state.copyWith(isLoading: true);
    final result = await _repository.getBookmarks(userId);
    result.when(
      success: (bookmarks) {
        final ids = bookmarks.map((fc) => fc.id).toSet();
        state = BookmarkState(
          bookmarks: bookmarks,
          bookmarkedIds: ids,
          isLoading: false,
        );
      },
      failure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
      },
    );
  }

  /// Toggle bookmark status of a flashcard
  Future<bool> toggleBookmark(String userId, Flashcard flashcard) async {
    final isBookmarked = state.bookmarkedIds.contains(flashcard.id);
    if (isBookmarked) {
      final result = await _repository.removeBookmark(userId, flashcard.id);
      return result.when(
        success: (_) {
          final updatedBookmarks =
              state.bookmarks.where((fc) => fc.id != flashcard.id).toList();
          final updatedIds = Set<String>.from(state.bookmarkedIds)
            ..remove(flashcard.id);
          state = state.copyWith(
            bookmarks: updatedBookmarks,
            bookmarkedIds: updatedIds,
          );
          return true;
        },
        failure: (failure) {
          state = state.copyWith(error: failure.message);
          return false;
        },
      );
    } else {
      final result = await _repository.addBookmark(userId, flashcard);
      return result.when(
        success: (_) {
          final updatedBookmarks = List<Flashcard>.from(state.bookmarks)
            ..add(flashcard);
          final updatedIds = Set<String>.from(state.bookmarkedIds)
            ..add(flashcard.id);
          state = state.copyWith(
            bookmarks: updatedBookmarks,
            bookmarkedIds: updatedIds,
          );
          return true;
        },
        failure: (failure) {
          state = state.copyWith(error: failure.message);
          return false;
        },
      );
    }
  }

  /// Clean error state
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Global provider for user bookmarks state
final bookmarkProvider =
    StateNotifierProvider<BookmarkNotifier, BookmarkState>((ref) {
  return BookmarkNotifier(ref.watch(bookmarkRepositoryProvider));
});
