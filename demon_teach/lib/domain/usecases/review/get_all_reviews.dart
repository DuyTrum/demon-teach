import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/review_item.dart';
import 'package:demon_teach/domain/repositories/review_repository.dart';

/// Use case to get all review items for a user (including future reviews)
class GetAllReviews {
  final ReviewRepository _repository;

  GetAllReviews(this._repository);

  Future<Result<List<ReviewItem>>> call(String userId) async {
    return await _repository.getAllReviews(userId);
  }
}
