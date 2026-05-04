import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/review_item.dart';

/// Repository interface for review items (spaced repetition)
abstract class ReviewRepository {
  /// Add a new review item to the system
  Future<Result<void>> addReviewItem(ReviewItem item);

  /// Get all due review items for a user
  Future<Result<List<ReviewItem>>> getDueReviews(String userId);

  /// Get all review items for a user (including future reviews)
  Future<Result<List<ReviewItem>>> getAllReviews(String userId);

  /// Update a review item after review
  Future<Result<void>> updateReviewItem(ReviewItem item);

  /// Delete a review item
  Future<Result<void>> deleteReviewItem(String itemId);

  /// Get review item by ID
  Future<Result<ReviewItem>> getReviewItemById(String itemId);

  /// Get review item by content ID
  Future<Result<ReviewItem?>> getReviewItemByContentId(
    String userId,
    String contentId,
  );

  /// Get count of due reviews
  Future<Result<int>> getDueReviewCount(String userId);
}
