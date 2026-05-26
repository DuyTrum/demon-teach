import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demon_teach/core/errors/failures.dart';
import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/leaderboard_entry.dart';
import 'package:demon_teach/domain/entities/progress.dart';
import 'package:demon_teach/domain/repositories/leaderboard_repository.dart';

class LeaderboardRepositoryImpl implements LeaderboardRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<Result<List<LeaderboardEntry>>> getLeaderboard({
    required String targetLanguage,
    required String currentUserId,
  }) async {
    try {
      // 1. Fetch all progress records for the target language from Firestore
      final progressQuery = await _firestore
          .collection('progress')
          .where('targetLanguage', isEqualTo: targetLanguage)
          .get();

      final List<Progress> progresses = progressQuery.docs
          .map((doc) => Progress.fromJson(doc.data()))
          .toList();

      final List<LeaderboardEntry> realEntries = [];

      // 2. Fetch user information for each progress record
      for (final progress in progresses) {
        try {
          final userDoc =
              await _firestore.collection('users').doc(progress.userId).get();
          String displayName = 'Học giả bí ẩn';

          if (userDoc.exists && userDoc.data() != null) {
            final data = userDoc.data()!;
            // Use displayName if available, otherwise fallback to email username
            displayName = data['displayName'] ?? '';
            if (displayName.isEmpty) {
              final email = data['email'] ?? '';
              if (email.isNotEmpty) {
                displayName = email.split('@').first;
                // Capitalize first letter
                if (displayName.isNotEmpty) {
                  displayName =
                      displayName[0].toUpperCase() + displayName.substring(1);
                }
              }
            }
          }

          realEntries.add(
            LeaderboardEntry(
              userId: progress.userId,
              displayName: displayName,
              totalXP: progress.totalXP,
              streak: progress.currentStreak,
              rank: 0, // Will be calculated after sorting
              isCurrentUser: progress.userId == currentUserId,
              avatarSeed: displayName.isNotEmpty ? displayName[0] : 'U',
            ),
          );
        } catch (e) {
          // If we fail to fetch a specific user profile, create a placeholder
          realEntries.add(
            LeaderboardEntry(
              userId: progress.userId,
              displayName: 'Chiến binh ẩn danh',
              totalXP: progress.totalXP,
              streak: progress.currentStreak,
              rank: 0,
              isCurrentUser: progress.userId == currentUserId,
              avatarSeed: 'A',
            ),
          );
        }
      }

      // Ensure the current user is present in the list, even if no progress exists in Firestore yet
      final hasCurrentUser = realEntries.any((entry) => entry.isCurrentUser);
      if (!hasCurrentUser) {
        try {
          final currentUserDoc =
              await _firestore.collection('users').doc(currentUserId).get();
          String displayName = 'Tôi';
          if (currentUserDoc.exists && currentUserDoc.data() != null) {
            final data = currentUserDoc.data()!;
            displayName = data['displayName'] ?? '';
            if (displayName.isEmpty) {
              final email = data['email'] ?? '';
              if (email.isNotEmpty) {
                displayName = email.split('@').first;
                if (displayName.length > 1) {
                  displayName =
                      displayName[0].toUpperCase() + displayName.substring(1);
                }
              }
            }
          }

          // Fetch local/Firestore progress fallback if any
          final progressDocId = 'progress_${currentUserId}_$targetLanguage';
          final progressDoc =
              await _firestore.collection('progress').doc(progressDocId).get();
          int totalXP = 0;
          int streak = 0;
          if (progressDoc.exists && progressDoc.data() != null) {
            final progressData = Progress.fromJson(progressDoc.data()!);
            totalXP = progressData.totalXP;
            streak = progressData.currentStreak;
          }

          realEntries.add(
            LeaderboardEntry(
              userId: currentUserId,
              displayName: displayName,
              totalXP: totalXP,
              streak: streak,
              rank: 0,
              isCurrentUser: true,
              avatarSeed: displayName.isNotEmpty ? displayName[0] : 'I',
            ),
          );
        } catch (_) {
          // Fallback if current user doc cannot be retrieved
          realEntries.add(
            LeaderboardEntry(
              userId: currentUserId,
              displayName: 'Tôi',
              totalXP: 0,
              streak: 0,
              rank: 0,
              isCurrentUser: true,
              avatarSeed: 'T',
            ),
          );
        }
      }

      // Sort real entries by XP descending
      realEntries.sort((a, b) => b.totalXP.compareTo(a.totalXP));

      // Calculate final ranks
      final List<LeaderboardEntry> rankedEntries = [];
      for (int i = 0; i < realEntries.length; i++) {
        rankedEntries.add(realEntries[i].copyWith(rank: i + 1));
      }

      return Result.success(rankedEntries);
    } catch (e) {
      return Result.failure(
        ServerFailure(message: 'Không thể tải bảng xếp hạng: ${e.toString()}'),
      );
    }
  }
}
