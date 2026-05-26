import 'package:demon_teach/domain/entities/leaderboard_entry.dart';
import 'package:demon_teach/domain/repositories/leaderboard_repository.dart';
import 'package:demon_teach/domain/usecases/leaderboard/get_leaderboard.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Repository provider (to be overridden in main)
final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  throw UnimplementedError('LeaderboardRepository must be overridden');
});

// Use case provider
final getLeaderboardProvider = Provider<GetLeaderboard>((ref) {
  return GetLeaderboard(ref.watch(leaderboardRepositoryProvider));
});

// Leaderboard State
class LeaderboardState {
  final List<LeaderboardEntry> entries;
  final bool isLoading;
  final String? error;

  const LeaderboardState({
    this.entries = const [],
    this.isLoading = false,
    this.error,
  });

  LeaderboardState copyWith({
    List<LeaderboardEntry>? entries,
    bool? isLoading,
    String? error,
  }) {
    return LeaderboardState(
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      error: error, // Cleared if passed null
    );
  }
}

// Leaderboard Notifier
class LeaderboardNotifier extends StateNotifier<LeaderboardState> {
  final GetLeaderboard _getLeaderboard;

  LeaderboardNotifier(this._getLeaderboard) : super(const LeaderboardState());

  /// Load leaderboard for the target language
  Future<void> loadLeaderboard({
    required String targetLanguage,
    required String currentUserId,
  }) async {
    state = state.copyWith(isLoading: true);

    final result = await _getLeaderboard(
      targetLanguage: targetLanguage,
      currentUserId: currentUserId,
    );

    result.when(
      success: (entries) {
        state = LeaderboardState(
          entries: entries,
          isLoading: false,
        );
      },
      failure: (failure) {
        state = LeaderboardState(
          isLoading: false,
          error: failure.message,
        );
      },
    );
  }

  /// Refresh leaderboard data
  Future<void> refresh({
    required String targetLanguage,
    required String currentUserId,
  }) async {
    await loadLeaderboard(
      targetLanguage: targetLanguage,
      currentUserId: currentUserId,
    );
  }
}

// Leaderboard state notifier provider
final leaderboardProvider =
    StateNotifierProvider<LeaderboardNotifier, LeaderboardState>((ref) {
  return LeaderboardNotifier(ref.watch(getLeaderboardProvider));
});
