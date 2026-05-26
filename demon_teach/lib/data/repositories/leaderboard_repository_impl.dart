import 'dart:math';
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
          final userDoc = await _firestore.collection('users').doc(progress.userId).get();
          String email = '';
          String displayName = 'Học giả bí ẩn';

          if (userDoc.exists && userDoc.data() != null) {
            final data = userDoc.data()!;
            email = data['email'] ?? '';
            if (email.isNotEmpty) {
              final parts = email.split('@');
              displayName = parts.first;
              // Capitalize displayName beautifully
              if (displayName.length > 1) {
                displayName = displayName[0].toUpperCase() + displayName.substring(1);
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
          final currentUserDoc = await _firestore.collection('users').doc(currentUserId).get();
          String displayName = 'Tôi';
          if (currentUserDoc.exists && currentUserDoc.data() != null) {
            final email = currentUserDoc.data()!['email'] ?? '';
            if (email.isNotEmpty) {
              displayName = email.split('@').first;
              if (displayName.length > 1) {
                displayName = displayName[0].toUpperCase() + displayName.substring(1);
              }
            }
          }

          // Fetch local/Firestore progress fallback if any
          final progressDocId = 'progress_${currentUserId}_$targetLanguage';
          final progressDoc = await _firestore.collection('progress').doc(progressDocId).get();
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

      // 3. Sort real entries by XP descending
      realEntries.sort((a, b) => b.totalXP.compareTo(a.totalXP));

      // 4. Generate mock competitors if total entries are fewer than 10
      final List<LeaderboardEntry> finalEntries = List.from(realEntries);
      if (finalEntries.length < 10) {
        final int currentXp = realEntries.firstWhere((e) => e.isCurrentUser).totalXP;
        final int currentStreak = realEntries.firstWhere((e) => e.isCurrentUser).streak;

        // Names list for mock competitors (Demon/Dark themed + dynamic)
        final List<String> mockNames = [
          'Quỷ Dạ Xoa',
          'Chúa Tể Ngữ Pháp',
          'Ma Vương Từ Vựng',
          'Hắc Ám Sư',
          'Thợ Săn Tiếng Anh',
          'Phượng Hoàng Lửa',
          'Pháp Sư Ngôn Từ',
          'Chiến Thần Phát Âm',
          'Vương Tử Học Thuật',
          'Bóng Đêm Anh Ngữ',
        ];

        // Seed generator deterministically based on date (changes once a day)
        // and current user's ID hash to prevent random reshuffling on page refresh
        final int dateSeed = DateTime.now().year * 10000 + DateTime.now().month * 100 + DateTime.now().day;
        final int userIdHash = currentUserId.hashCode;
        final Random random = Random(dateSeed + userIdHash);

        // Remove names that are already taken by real users (unlikely, but safe)
        final Set<String> takenNames = realEntries.map((e) => e.displayName).toSet();
        final List<String> availableMockNames = mockNames.where((name) => !takenNames.contains(name)).toList();

        // Calculate XP offsets relative to current user's XP to keep it competitive
        // We'll place some competitors above the user and some below.
        final List<int> relativeXpOffsets = [
          420, // High rank
          280,
          150,
          70,
          -20, // Slightly below
          -70,
          -150,
          -260,
          -400,
        ];

        int mockIndex = 0;
        while (finalEntries.length < 10 && mockIndex < availableMockNames.length && mockIndex < relativeXpOffsets.length) {
          final name = availableMockNames[mockIndex];
          final offset = relativeXpOffsets[mockIndex];
          
          // Ensure XP is positive and has a slight random variation
          int mockXp = currentXp + offset + random.nextInt(40) - 20;
          if (mockXp < 0) {
            mockXp = max(5, 50 + offset.abs() ~/ 4 + random.nextInt(20));
          }

          // Streak calculation
          int mockStreak = currentStreak + (offset > 0 ? random.nextInt(6) + 1 : -random.nextInt(3));
          mockStreak = max(0, mockStreak);

          finalEntries.add(
            LeaderboardEntry(
              userId: 'mock_user_$mockIndex',
              displayName: name,
              totalXP: mockXp,
              streak: mockStreak,
              rank: 0,
              isCurrentUser: false,
              avatarSeed: name.isNotEmpty ? name[0] : 'M',
            ),
          );
          mockIndex++;
        }
      }

      // 5. Sort final combined list and calculate final ranks
      finalEntries.sort((a, b) => b.totalXP.compareTo(a.totalXP));
      
      final List<LeaderboardEntry> rankedEntries = [];
      for (int i = 0; i < finalEntries.length; i++) {
        rankedEntries.add(finalEntries[i].copyWith(rank: i + 1));
      }

      return Result.success(rankedEntries);
    } catch (e) {
      return Result.failure(
        ServerFailure(message: 'Không thể tải bảng xếp hạng: ${e.toString()}'),
      );
    }
  }
}
