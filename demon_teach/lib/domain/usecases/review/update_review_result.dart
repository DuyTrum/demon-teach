import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/review_item.dart';
import 'package:demon_teach/domain/repositories/review_repository.dart';
import 'package:demon_teach/domain/services/spaced_repetition_engine.dart';

/// Parameters for updating review result
class UpdateReviewResultParams {
  final String itemId;
  final ReviewResult result;

  UpdateReviewResultParams({
    required this.itemId,
    required this.result,
  });
}

/// Use case to update a review item after user completes review
class UpdateReviewResult {
  final ReviewRepository _repository;
  final SpacedRepetitionEngine _engine;

  UpdateReviewResult(this._repository, this._engine);

  Future<Result<ReviewItem>> call(UpdateReviewResultParams params) async {
    // Get the current review item
    final itemResult = await _repository.getReviewItemById(params.itemId);

    return await itemResult.when(
      success: (item) async {
        // Calculate updated review item using SM-2 algorithm
        final updatedItem = _engine.calculateUpdatedReviewItem(
          item,
          params.result,
        );

        // Save updated item
        final updateResult = await _repository.updateReviewItem(updatedItem);

        return updateResult.when(
          success: (_) => Result.success(updatedItem),
          failure: (failure) => Result.failure(failure),
        );
      },
      failure: (failure) => Result.failure(failure),
    );
  }
}
