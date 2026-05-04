import 'dart:convert';
import 'package:demon_teach/core/errors/failures.dart';
import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/review_item.dart';
import 'package:demon_teach/domain/repositories/review_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Implementation of ReviewRepository using SharedPreferences
class ReviewRepositoryImpl implements ReviewRepository {
  final SharedPreferences _prefs;
  static const String _reviewItemsKey = 'review_items';

  ReviewRepositoryImpl(this._prefs);

  /// Load all review items from SharedPreferences
  Future<Map<String, ReviewItem>> _loadReviewItems() async {
    try {
      final jsonString = _prefs.getString(_reviewItemsKey);
      if (jsonString == null) {
        return {};
      }

      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      final Map<String, ReviewItem> items = {};

      jsonMap.forEach((key, value) {
        items[key] = ReviewItem.fromJson(value as Map<String, dynamic>);
      });

      return items;
    } catch (e) {
      throw CacheFailure(
          message: 'Failed to load review items: ${e.toString()}');
    }
  }

  /// Save all review items to SharedPreferences
  Future<void> _saveReviewItems(Map<String, ReviewItem> items) async {
    try {
      final Map<String, dynamic> jsonMap = {};
      items.forEach((key, value) {
        jsonMap[key] = value.toJson();
      });

      final jsonString = json.encode(jsonMap);
      await _prefs.setString(_reviewItemsKey, jsonString);
    } catch (e) {
      throw CacheFailure(
          message: 'Failed to save review items: ${e.toString()}');
    }
  }

  @override
  Future<Result<void>> addReviewItem(ReviewItem item) async {
    try {
      final items = await _loadReviewItems();

      // Check if item already exists
      if (items.containsKey(item.id)) {
        return Result.failure(
          const ValidationFailure(
            field: 'id',
            message: 'Review item already exists',
          ),
        );
      }

      items[item.id] = item;
      await _saveReviewItems(items);

      return Result.success(null);
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to add review item: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<List<ReviewItem>>> getDueReviews(String userId) async {
    try {
      final items = await _loadReviewItems();
      final now = DateTime.now();

      final dueReviews = items.values
          .where((item) =>
              item.userId == userId && item.nextReviewDate.isBefore(now))
          .toList();

      // Sort by next review date (oldest first)
      dueReviews.sort((a, b) => a.nextReviewDate.compareTo(b.nextReviewDate));

      return Result.success(dueReviews);
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to get due reviews: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<List<ReviewItem>>> getAllReviews(String userId) async {
    try {
      final items = await _loadReviewItems();

      final userReviews =
          items.values.where((item) => item.userId == userId).toList();

      // Sort by next review date
      userReviews.sort((a, b) => a.nextReviewDate.compareTo(b.nextReviewDate));

      return Result.success(userReviews);
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to get all reviews: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<void>> updateReviewItem(ReviewItem item) async {
    try {
      final items = await _loadReviewItems();

      if (!items.containsKey(item.id)) {
        return Result.failure(
          const ValidationFailure(
            field: 'id',
            message: 'Review item not found',
          ),
        );
      }

      items[item.id] = item;
      await _saveReviewItems(items);

      return Result.success(null);
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to update review item: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<void>> deleteReviewItem(String itemId) async {
    try {
      final items = await _loadReviewItems();

      if (!items.containsKey(itemId)) {
        return Result.failure(
          const ValidationFailure(
            field: 'id',
            message: 'Review item not found',
          ),
        );
      }

      items.remove(itemId);
      await _saveReviewItems(items);

      return Result.success(null);
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to delete review item: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<ReviewItem>> getReviewItemById(String itemId) async {
    try {
      final items = await _loadReviewItems();

      if (!items.containsKey(itemId)) {
        return Result.failure(
          const ValidationFailure(
            field: 'id',
            message: 'Review item not found',
          ),
        );
      }

      return Result.success(items[itemId]!);
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to get review item: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<ReviewItem?>> getReviewItemByContentId(
    String userId,
    String contentId,
  ) async {
    try {
      final items = await _loadReviewItems();

      final reviewItem = items.values.firstWhere(
        (item) => item.userId == userId && item.contentId == contentId,
        orElse: () => throw Exception('Not found'),
      );

      return Result.success(reviewItem);
    } catch (e) {
      // Return null if not found (not an error)
      if (e.toString().contains('Not found')) {
        return Result.success(null);
      }
      return Result.failure(
        CacheFailure(
            message: 'Failed to get review item by content: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<int>> getDueReviewCount(String userId) async {
    try {
      final dueReviewsResult = await getDueReviews(userId);

      return dueReviewsResult.when(
        success: (reviews) => Result.success(reviews.length),
        failure: (failure) => Result.failure(failure),
      );
    } catch (e) {
      return Result.failure(
        CacheFailure(
            message: 'Failed to get due review count: ${e.toString()}'),
      );
    }
  }
}
