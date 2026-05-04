import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/review_item.dart';
import 'package:demon_teach/domain/repositories/review_repository.dart';

/// Use case to add a new review item to the spaced repetition system
class AddReviewItem {
  final ReviewRepository _repository;

  AddReviewItem(this._repository);

  Future<Result<void>> call(ReviewItem item) async {
    return await _repository.addReviewItem(item);
  }
}
