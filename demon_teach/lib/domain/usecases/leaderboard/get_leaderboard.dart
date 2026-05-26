import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/leaderboard_entry.dart';
import 'package:demon_teach/domain/repositories/leaderboard_repository.dart';

/// Use case to retrieve target language leaderboard entries
class GetLeaderboard {
  final LeaderboardRepository _repository;

  GetLeaderboard(this._repository);

  Future<Result<List<LeaderboardEntry>>> call({
    required String targetLanguage,
    required String currentUserId,
  }) async {
    return await _repository.getLeaderboard(
      targetLanguage: targetLanguage,
      currentUserId: currentUserId,
    );
  }
}
