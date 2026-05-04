import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/repositories/review_repository.dart';

/// Use case to get count of due reviews for a user
class GetDueReviewCount {
  final ReviewRepository _repository;

  GetDueReviewCount(this._repository);

  Future<Result<int>> call(String userId) async {
    return await _repository.getDueReviewCount(userId);
  }
}
