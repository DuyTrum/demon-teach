import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/review_item.dart';
import 'package:demon_teach/domain/repositories/review_repository.dart';

/// Use case to get all due review items for a user
class GetDueReviews {
  final ReviewRepository _repository;

  GetDueReviews(this._repository);

  Future<Result<List<ReviewItem>>> call(String userId) async {
    return await _repository.getDueReviews(userId);
  }
}
