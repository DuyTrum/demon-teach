import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/leaderboard_entry.dart';

/// Repository interface for leaderboard operations
abstract class LeaderboardRepository {
  /// Fetch leaderboard entries sorted by XP for a target language
  Future<Result<List<LeaderboardEntry>>> getLeaderboard({
    required String targetLanguage,
    required String currentUserId,
  });
}
