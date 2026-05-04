import 'package:demon_teach/domain/entities/review_item.dart';
import 'package:demon_teach/domain/repositories/review_repository.dart';
import 'package:demon_teach/domain/usecases/review/get_due_reviews.dart';
import 'package:demon_teach/domain/usecases/review/get_all_reviews.dart';
import 'package:demon_teach/domain/usecases/review/update_review_result.dart';
import 'package:demon_teach/domain/usecases/review/add_review_item.dart';
import 'package:demon_teach/domain/usecases/review/get_due_review_count.dart';
import 'package:demon_teach/domain/services/spaced_repetition_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Repository provider
final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  throw UnimplementedError('ReviewRepository must be overridden');
});

// Service provider
final spacedRepetitionEngineProvider = Provider<SpacedRepetitionEngine>((ref) {
  return SpacedRepetitionEngine();
});

// Use case providers
final getDueReviewsProvider = Provider<GetDueReviews>((ref) {
  return GetDueReviews(ref.watch(reviewRepositoryProvider));
});

final getAllReviewsProvider = Provider<GetAllReviews>((ref) {
  return GetAllReviews(ref.watch(reviewRepositoryProvider));
});

final updateReviewResultProvider = Provider<UpdateReviewResult>((ref) {
  return UpdateReviewResult(
    ref.watch(reviewRepositoryProvider),
    ref.watch(spacedRepetitionEngineProvider),
  );
});

final addReviewItemProvider = Provider<AddReviewItem>((ref) {
  return AddReviewItem(ref.watch(reviewRepositoryProvider));
});

final getDueReviewCountProvider = Provider<GetDueReviewCount>((ref) {
  return GetDueReviewCount(ref.watch(reviewRepositoryProvider));
});

// Review state
class ReviewState {
  final List<ReviewItem> dueReviews;
  final List<ReviewItem> allReviews;
  final int currentIndex;
  final bool isLoading;
  final String? error;
  final bool isSubmitting;
  final int dueCount;

  const ReviewState({
    this.dueReviews = const [],
    this.allReviews = const [],
    this.currentIndex = 0,
    this.isLoading = false,
    this.error,
    this.isSubmitting = false,
    this.dueCount = 0,
  });

  ReviewItem? get currentReview {
    if (dueReviews.isEmpty || currentIndex >= dueReviews.length) {
      return null;
    }
    return dueReviews[currentIndex];
  }

  bool get hasNext => currentIndex < dueReviews.length - 1;
  bool get isComplete => currentIndex >= dueReviews.length;
  int get totalReviews => dueReviews.length;
  int get currentReviewNumber => currentIndex + 1;
  int get remainingReviews => totalReviews - currentIndex;

  ReviewState copyWith({
    List<ReviewItem>? dueReviews,
    List<ReviewItem>? allReviews,
    int? currentIndex,
    bool? isLoading,
    String? error,
    bool? isSubmitting,
    int? dueCount,
  }) {
    return ReviewState(
      dueReviews: dueReviews ?? this.dueReviews,
      allReviews: allReviews ?? this.allReviews,
      currentIndex: currentIndex ?? this.currentIndex,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      dueCount: dueCount ?? this.dueCount,
    );
  }
}

// Review notifier
class ReviewNotifier extends StateNotifier<ReviewState> {
  final GetDueReviews _getDueReviews;
  final GetAllReviews _getAllReviews;
  final UpdateReviewResult _updateReviewResult;
  final AddReviewItem _addReviewItem;
  final GetDueReviewCount _getDueReviewCount;

  ReviewNotifier(
    this._getDueReviews,
    this._getAllReviews,
    this._updateReviewResult,
    this._addReviewItem,
    this._getDueReviewCount,
  ) : super(const ReviewState());

  /// Load due reviews for a user
  Future<void> loadDueReviews(String userId) async {
    state = state.copyWith(isLoading: true);

    final result = await _getDueReviews(userId);

    result.when(
      success: (reviews) {
        state = ReviewState(
          dueReviews: reviews,
          currentIndex: 0,
          isLoading: false,
          dueCount: reviews.length,
        );
      },
      failure: (failure) {
        state = ReviewState(
          isLoading: false,
          error: failure.message,
        );
      },
    );
  }

  /// Load all reviews for a user (including future reviews)
  Future<void> loadAllReviews(String userId) async {
    final result = await _getAllReviews(userId);

    result.when(
      success: (reviews) {
        state = state.copyWith(allReviews: reviews);
      },
      failure: (failure) {
        state = state.copyWith(error: failure.message);
      },
    );
  }

  /// Load due review count
  Future<void> loadDueReviewCount(String userId) async {
    final result = await _getDueReviewCount(userId);

    result.when(
      success: (count) {
        state = state.copyWith(dueCount: count);
      },
      failure: (failure) {
        state = state.copyWith(error: failure.message);
      },
    );
  }

  /// Submit review result and move to next
  Future<void> submitReviewResult({
    required ReviewResult result,
  }) async {
    final currentReview = state.currentReview;
    if (currentReview == null) return;

    state = state.copyWith(isSubmitting: true);

    final updateResult = await _updateReviewResult(
      UpdateReviewResultParams(
        itemId: currentReview.id,
        result: result,
      ),
    );

    updateResult.when(
      success: (updatedItem) {
        // Move to next review
        if (state.hasNext) {
          state = state.copyWith(
            currentIndex: state.currentIndex + 1,
            isSubmitting: false,
          );
        } else {
          // Session complete
          state = state.copyWith(
            currentIndex: state.currentIndex + 1,
            isSubmitting: false,
          );
        }
      },
      failure: (failure) {
        state = state.copyWith(
          isSubmitting: false,
          error: failure.message,
        );
      },
    );
  }

  /// Add a new review item
  Future<void> addReview(ReviewItem item) async {
    final result = await _addReviewItem(item);

    result.when(
      success: (_) {
        // Optionally reload reviews
      },
      failure: (failure) {
        state = state.copyWith(error: failure.message);
      },
    );
  }

  /// Reset review session
  void reset() {
    state = state.copyWith(currentIndex: 0);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Review provider
final reviewProvider =
    StateNotifierProvider<ReviewNotifier, ReviewState>((ref) {
  return ReviewNotifier(
    ref.watch(getDueReviewsProvider),
    ref.watch(getAllReviewsProvider),
    ref.watch(updateReviewResultProvider),
    ref.watch(addReviewItemProvider),
    ref.watch(getDueReviewCountProvider),
  );
});
