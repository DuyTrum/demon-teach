import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:demon_teach/core/theme/app_theme.dart';
import 'package:demon_teach/domain/entities/leaderboard_entry.dart';
import 'package:demon_teach/presentation/providers/auth_provider.dart';
import 'package:demon_teach/presentation/providers/language_provider.dart';
import 'package:demon_teach/presentation/providers/leaderboard_provider.dart';
import 'package:demon_teach/presentation/widgets/common/demon_background_particles.dart';

/// Leaderboard screen showing top user rankings with a premium podium design
class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final user = ref.read(authProvider).user;
    final languagePref = ref.read(languageProvider).preference;
    if (user != null && languagePref != null) {
      ref.read(leaderboardProvider.notifier).loadLeaderboard(
            targetLanguage: languagePref.targetLanguage,
            currentUserId: user.id,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(leaderboardProvider);
    final user = ref.watch(authProvider).user;
    final languagePref = ref.watch(languageProvider).preference;

    final String targetLang = languagePref?.targetLanguage ?? 'en';
    final String currentUserId = user?.id ?? '';

    // Find current user's entry if loaded
    LeaderboardEntry? currentUserEntry;
    if (state.entries.isNotEmpty) {
      try {
        currentUserEntry = state.entries.firstWhere((e) => e.userId == currentUserId);
      } catch (_) {}
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppTheme.demonBgGradientBot,
      appBar: AppBar(
        title: const Text(
          'Đấu Trường Ác Quỷ',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.demonGlowPurple),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Dark Purple Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.demonBgGradientTop,
                  AppTheme.demonBgGradientMid,
                  AppTheme.demonBgGradientBot,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Eerie Floating Particles
          const Positioned.fill(
            child: DemonBackgroundParticles(),
          ),

          // Main Content Area
          SafeArea(
            child: _buildBody(context, state, targetLang, currentUserEntry),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    LeaderboardState state,
    String targetLang,
    LeaderboardEntry? currentUserEntry,
  ) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.demonGlowPurple),
      );
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.redAccent,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              state.error!,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingLg),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.demonGlowPurple,
                foregroundColor: Colors.white,
              ),
              onPressed: _loadData,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (state.entries.isEmpty) {
      return const Center(
        child: Text(
          'Không tìm thấy dữ liệu xếp hạng.',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }

    // Split entries: podium (top 3) vs scrollable list (rest)
    final List<LeaderboardEntry> podiumEntries = state.entries.take(3).toList();
    final List<LeaderboardEntry> listEntries = state.entries.skip(3).toList();

    // Map language code to full display name
    String langName = targetLang.toUpperCase();
    if (targetLang.toLowerCase() == 'en') langName = 'Tiếng Anh';
    if (targetLang.toLowerCase() == 'ja') langName = 'Tiếng Nhật';
    if (targetLang.toLowerCase() == 'ko') langName = 'Tiếng Hàn';
    if (targetLang.toLowerCase() == 'zh') langName = 'Tiếng Trung';

    return RefreshIndicator(
      color: AppTheme.demonGlowPurple,
      backgroundColor: AppTheme.demonNodeLocked,
      onRefresh: () async {
        _loadData();
      },
      child: Column(
        children: [
          // Header info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.demonGlowPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.demonGlowPurple.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.language, size: 16, color: AppTheme.demonGlowPurple),
                  const SizedBox(width: 6),
                  Text(
                    'Đấu trường: $langName',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Podium Section
                  _buildPodium(context, podiumEntries),
                  const SizedBox(height: 30),

                  // Rankings Title/Label
                  if (listEntries.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                      child: Row(
                        children: [
                          const Icon(Icons.list_alt_rounded, color: AppTheme.demonTextMuted, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Bảng xếp hạng chi tiết',
                            style: TextStyle(
                              color: AppTheme.demonTextMuted,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // List Section
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    itemCount: listEntries.length,
                    itemBuilder: (context, index) {
                      final entry = listEntries[index];
                      return _buildRankRow(context, entry);
                    },
                  ),
                  const SizedBox(height: 100), // Padding to prevent cutoff by sticky bar
                ],
              ),
            ),
          ),

          // Sticky bottom bar for current user (if loaded and outside top 3)
          if (currentUserEntry != null && currentUserEntry.rank > 3)
            _buildStickyBottomBar(context, currentUserEntry),
        ],
      ),
    );
  }

  // podium entries can be less than 3, though repo handles padding
  Widget _buildPodium(BuildContext context, List<LeaderboardEntry> topEntries) {
    // We need up to 3 entries. Pad with nulls if somehow there are fewer than 3
    final entry1 = topEntries.isNotEmpty ? topEntries[0] : null;
    final entry2 = topEntries.length > 1 ? topEntries[1] : null;
    final entry3 = topEntries.length > 2 ? topEntries[2] : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd Place (Left)
          Expanded(
            child: _buildPodiumItem(context, entry2, 2, 90, 60, Colors.grey[400]!),
          ),
          const SizedBox(width: 8),
          // 1st Place (Middle)
          Expanded(
            child: _buildPodiumItem(context, entry1, 1, 125, 75, Colors.amber),
          ),
          const SizedBox(width: 8),
          // 3rd Place (Right)
          Expanded(
            child: _buildPodiumItem(context, entry3, 3, 75, 55, Colors.brown[400]!),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumItem(
    BuildContext context,
    LeaderboardEntry? entry,
    int rank,
    double pedestalHeight,
    double avatarSize,
    Color accentColor,
  ) {
    if (entry == null) return const SizedBox.shrink();

    // Determine colors
    final List<Color> pedestalGradient = rank == 1
        ? [Colors.amber.withOpacity(0.6), Colors.orangeAccent.withOpacity(0.8)]
        : rank == 2
            ? [Colors.grey[400]!.withOpacity(0.5), Colors.grey[600]!.withOpacity(0.7)]
            : [Colors.brown[400]!.withOpacity(0.4), Colors.brown[700]!.withOpacity(0.6)];

    final Color shadowColor = rank == 1
        ? Colors.amber.withOpacity(0.3)
        : rank == 2
            ? Colors.grey.withOpacity(0.2)
            : Colors.brown.withOpacity(0.15);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Avatar + Crown Section
        Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Glowing circular avatar border
            Container(
              width: avatarSize + 8,
              height: avatarSize + 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: entry.isCurrentUser ? AppTheme.demonGlowPurple : accentColor,
                  width: entry.isCurrentUser ? 3.0 : 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: entry.isCurrentUser ? AppTheme.demonGlowPurple.withOpacity(0.5) : shadowColor,
                    blurRadius: 12,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: CircleAvatar(
                radius: avatarSize / 2,
                backgroundColor: AppTheme.demonNodeLocked,
                child: Text(
                  entry.avatarSeed,
                  style: TextStyle(
                    color: entry.isCurrentUser ? AppTheme.demonGlowPurple : accentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: avatarSize * 0.4,
                  ),
                ),
              ),
            ),

            // Crown for 1st place
            if (rank == 1)
              const Positioned(
                top: -24,
                child: RotationTransition(
                  turns: AlwaysStoppedAnimation(0.0),
                  child: Icon(
                    Icons.emoji_events,
                    color: Colors.amber,
                    size: 26,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // User info details
        Text(
          entry.displayName,
          style: TextStyle(
            color: entry.isCurrentUser ? AppTheme.demonGlowPurple : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: rank == 1 ? 14 : 12,
            shadows: entry.isCurrentUser
                ? [const Shadow(color: AppTheme.demonGlowPurple, blurRadius: 8)]
                : null,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          '${entry.totalXP} XP',
          style: TextStyle(
            color: rank == 1 ? Colors.amber : AppTheme.demonTextMuted,
            fontSize: rank == 1 ? 13 : 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),

        // Pedestal base block
        Container(
          height: pedestalHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: pedestalGradient,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            border: Border.all(
              color: entry.isCurrentUser ? AppTheme.demonGlowPurple.withOpacity(0.8) : accentColor.withOpacity(0.4),
              width: entry.isCurrentUser ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                  shadows: [
                    Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(1, 2))
                  ],
                ),
              ),
              if (entry.streak > 0) ...[
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 14),
                    Text(
                      '${entry.streak}d',
                      style: const TextStyle(
                        color: Colors.orangeAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRankRow(BuildContext context, LeaderboardEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: entry.isCurrentUser
            ? AppTheme.demonGlowPurple.withOpacity(0.12)
            : AppTheme.demonNodeLocked.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: entry.isCurrentUser
              ? AppTheme.demonGlowPurple
              : Colors.white.withOpacity(0.08),
          width: entry.isCurrentUser ? 1.5 : 1.0,
        ),
        boxShadow: entry.isCurrentUser
            ? [
                BoxShadow(
                  color: AppTheme.demonGlowPurple.withOpacity(0.15),
                  blurRadius: 10,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: SizedBox(
          width: 75,
          child: Row(
            children: [
              // Rank number
              SizedBox(
                width: 25,
                child: Text(
                  '${entry.rank}',
                  style: TextStyle(
                    color: entry.isCurrentUser ? AppTheme.demonGlowPurple : AppTheme.demonTextMuted,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Mini Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: entry.isCurrentUser
                    ? AppTheme.demonGlowPurple.withOpacity(0.3)
                    : AppTheme.demonNodeLocked,
                child: Text(
                  entry.avatarSeed,
                  style: TextStyle(
                    color: entry.isCurrentUser ? Colors.white : AppTheme.demonTextMuted,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        title: Text(
          entry.displayName,
          style: TextStyle(
            fontWeight: entry.isCurrentUser ? FontWeight.bold : FontWeight.normal,
            color: entry.isCurrentUser ? Colors.white : AppTheme.demonTextLight,
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: entry.streak > 0
            ? Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 14),
                    const SizedBox(width: 2),
                    Text(
                      'Chuỗi ${entry.streak} ngày',
                      style: const TextStyle(color: Colors.orangeAccent, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              )
            : null,
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '${entry.totalXP} XP',
            style: TextStyle(
              color: entry.isCurrentUser ? AppTheme.demonGlowPurple : Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStickyBottomBar(BuildContext context, LeaderboardEntry entry) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.demonBgGradientBot.withOpacity(0.85),
            border: const Border(
              top: BorderSide(
                color: AppTheme.demonGlowPurple,
                width: 1.5,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                // Rank number
                Text(
                  '${entry.rank}',
                  style: const TextStyle(
                    color: AppTheme.demonGlowPurple,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(width: 16),
                // Avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.demonGlowPurple.withOpacity(0.3),
                  child: Text(
                    entry.avatarSeed,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Hạng của bạn',
                        style: TextStyle(
                          color: AppTheme.demonTextMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        entry.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Streak
                if (entry.streak > 0) ...[
                  Row(
                    children: [
                      const Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 18),
                      Text(
                        '${entry.streak}d',
                        style: const TextStyle(
                          color: Colors.orangeAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                ],
                // XP
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.demonGlowPurple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.demonGlowPurple.withOpacity(0.5)),
                  ),
                  child: Text(
                    '${entry.totalXP} XP',
                    style: const TextStyle(
                      color: AppTheme.demonGlowPurple,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
