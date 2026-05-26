import 'dart:ui';
import 'dart:async';
import 'package:demon_teach/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:demon_teach/core/theme/app_theme.dart';
import 'package:demon_teach/domain/entities/progress.dart';
import 'package:demon_teach/domain/entities/achievement.dart';
import 'package:demon_teach/presentation/providers/progress_provider.dart';
import 'package:demon_teach/presentation/providers/achievement_provider.dart';
import 'package:demon_teach/presentation/widgets/common/demon_background_particles.dart';

/// Progress dashboard screen showing XP, streak, and achievements (Demon Theme)
class ProgressDashboardScreen extends ConsumerStatefulWidget {
  final String userId;
  final String targetLanguage;

  const ProgressDashboardScreen({
    super.key,
    required this.userId,
    required this.targetLanguage,
  });

  @override
  ConsumerState<ProgressDashboardScreen> createState() =>
      _ProgressDashboardScreenState();
}

class _ProgressDashboardScreenState extends ConsumerState<ProgressDashboardScreen> {
  Timer? _uiTimer;

  @override
  void initState() {
    super.initState();
    // Load progress
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(progressProvider.notifier).loadProgress(
            userId: widget.userId,
            targetLanguage: widget.targetLanguage,
          );
      ref.read(achievementProvider.notifier).loadAchievements(
            userId: widget.userId,
            targetLanguage: widget.targetLanguage,
          );
    });

    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(progressProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppTheme.demonBgGradientBot,
      appBar: AppBar(
        title: const Text(
          'Năng lượng ác quỷ',
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
            onPressed: () {
              ref.read(progressProvider.notifier).refresh(
                    userId: widget.userId,
                    targetLanguage: widget.targetLanguage,
                  );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Dark Gradient Background
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
          
          // Eerie Particles
          const Positioned.fill(
            child: DemonBackgroundParticles(),
          ),

          // Main Content
          SafeArea(
            child: _buildBody(context, state),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, ProgressState state) {
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
              'Lỗi: ${state.error}',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingLg),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.demonGlowPurple,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                ref.read(progressProvider.notifier).loadProgress(
                      userId: widget.userId,
                      targetLanguage: widget.targetLanguage,
                    );
              },
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (state.progress == null) {
      return const Center(
        child: Text(
          'Chưa phát hiện ma lực của ác quỷ.',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.demonGlowPurple,
      backgroundColor: AppTheme.demonNodeLocked,
      onRefresh: () async {
        await Future.wait([
          ref.read(progressProvider.notifier).refresh(
                userId: widget.userId,
                targetLanguage: widget.targetLanguage,
              ),
          ref.read(achievementProvider.notifier).refresh(
                userId: widget.userId,
                targetLanguage: widget.targetLanguage,
              ),
        ]);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildLevelCard(context, state.progress!),
            const SizedBox(height: AppTheme.spacingLg),
            _buildHeartsCard(context, state.progress!),
            const SizedBox(height: AppTheme.spacingLg),
            _buildStreakCard(context, state.progress!),
            const SizedBox(height: AppTheme.spacingLg),
            _buildStatsGrid(context, state.progress!),
            const SizedBox(height: AppTheme.spacingLg),
            _buildMilestonesCard(context, state.progress!),
            const SizedBox(height: AppTheme.spacingLg),
            _buildAchievementsCard(context),
            const SizedBox(height: 80), // Padding for scrolling
          ],
        ),
      ),
    );
  }

  Widget _buildLevelCard(BuildContext context, Progress progress) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.demonGlowPurple.withOpacity(0.5), width: 1.5),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.demonGlowPurple.withOpacity(0.3),
                AppTheme.demonNodeLocked.withOpacity(0.8),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.demonGlowPurple.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 2,
              )
            ],
          ),
          padding: const EdgeInsets.all(AppTheme.spacingXl),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cấp độ ${progress.level}',
                        style: const TextStyle(
                          fontSize: 36,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: AppTheme.demonGlowPurple,
                              blurRadius: 10,
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingXs),
                      Text(
                        '${progress.totalXP} XP • ${progress.souls} Linh Hồn',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppTheme.demonTextMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingLg),
                    decoration: BoxDecoration(
                      color: AppTheme.demonGlowPurple.withOpacity(0.2),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.demonGlowPurple.withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        )
                      ],
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingXl),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Cấp độ tiếp theo',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Cần ${progress.xpToNextLevel} XP để lên cấp',
                        style: const TextStyle(
                          color: AppTheme.demonGlowPurple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress.progressToNextLevel,
                        backgroundColor: Colors.transparent,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.demonGlowPurple),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStreakCard(BuildContext context, Progress progress) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.demonNodeLocked.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orangeAccent.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: Colors.orangeAccent.withOpacity(0.25),
              shape: BoxShape.circle,
              boxShadow: progress.currentStreak > 0
                  ? [
                      BoxShadow(
                        color: Colors.orangeAccent.withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      )
                    ]
                  : null,
            ),
            child: const Icon(
              Icons.local_fire_department,
              size: 40,
              color: Colors.orangeAccent,
            ),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chuỗi hiện tại',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.demonTextMuted,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXs),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${progress.currentStreak}',
                      style: const TextStyle(
                        fontSize: 32,
                        color: Colors.orangeAccent,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(color: Colors.orangeAccent, blurRadius: 10)],
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'ngày',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                if (progress.longestStreak > progress.currentStreak) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Kỷ lục: ${progress.longestStreak} ngày',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.demonTextMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (progress.currentStreak > 0)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMd,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.redAccent.withOpacity(0.8)),
                boxShadow: [
                  BoxShadow(color: Colors.redAccent.withOpacity(0.4), blurRadius: 10)
                ],
              ),
              child: const Text(
                '🔥 RỰC CHÁY',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, Progress progress) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            'Bài học',
            '${progress.lessonsCompleted}',
            Icons.menu_book,
            AppTheme.demonGlowGreen,
          ),
        ),
        const SizedBox(width: AppTheme.spacingMd),
        Expanded(
          child: _buildStatCard(
            context,
            'Kỷ lục chuỗi',
            '${progress.longestStreak}',
            Icons.emoji_events,
            Colors.orangeAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.demonNodeLocked.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: color),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              color: color,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(color: color.withOpacity(0.5), blurRadius: 10)],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.demonTextMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMilestonesCard(BuildContext context, Progress progress) {
    final milestones = [
      {'days': 7, 'label': 'Sống sót 1 tuần', 'icon': Icons.calendar_today},
      {'days': 30, 'label': 'Chiến binh 1 tháng', 'icon': Icons.calendar_month},
      {'days': 100, 'label': 'Ác quỷ 100 ngày', 'icon': Icons.military_tech},
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.demonNodeLocked.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cột mốc',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          ...milestones.map((milestone) {
            final days = milestone['days'] as int;
            final label = milestone['label'] as String;
            final icon = milestone['icon'] as IconData;
            final achieved = progress.longestStreak >= days;

            final color = achieved ? AppTheme.demonGlowPurple : AppTheme.demonTextMuted;

            return Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: achieved ? color.withOpacity(0.5) : Colors.transparent),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: AppTheme.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            color: achieved ? Colors.white : AppTheme.demonTextMuted,
                            fontWeight: achieved ? FontWeight.bold : FontWeight.normal,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Chuỗi $days ngày',
                          style: TextStyle(
                            color: AppTheme.demonTextMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (achieved)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.demonGlowPurple,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    )
                  else
                    Icon(
                      Icons.lock_outline,
                      color: AppTheme.demonTextMuted,
                      size: 20,
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAchievementsCard(BuildContext context) {
    final achievementState = ref.watch(achievementProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.demonNodeLocked.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Thành tựu',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.demonGlowPurple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.demonGlowPurple.withOpacity(0.5)),
                ),
                child: Text(
                  '${achievementState.unlockedCount}/${achievementState.totalAchievements}',
                  style: const TextStyle(
                    color: AppTheme.demonGlowPurple,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingLg),
          if (achievementState.isLoading)
            const Center(child: CircularProgressIndicator(color: AppTheme.demonGlowPurple))
          else if (achievementState.achievements.isEmpty)
            Text('Chưa có thành tựu khả dụng.', style: TextStyle(color: AppTheme.demonTextMuted))
          else
            ...achievementState.achievements.map((achievement) {
              final isUnlocked = achievement.isUnlocked;
              final iconColor = isUnlocked ? Colors.amber : AppTheme.demonTextMuted;
              
              return Container(
                margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
                decoration: BoxDecoration(
                  color: isUnlocked ? Colors.amber.withOpacity(0.05) : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isUnlocked ? Colors.amber.withOpacity(0.3) : Colors.white.withOpacity(0.05),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: iconColor.withOpacity(0.25),
                      boxShadow: isUnlocked
                          ? [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.3),
                                blurRadius: 10,
                                spreadRadius: 2,
                              )
                            ]
                          : null,
                    ),
                    child: Icon(
                      isUnlocked ? Icons.emoji_events : Icons.lock,
                      color: iconColor,
                      size: 24,
                    ),
                  ),
                  title: Text(
                    achievement.title,
                    style: TextStyle(
                      fontWeight: isUnlocked ? FontWeight.bold : FontWeight.normal,
                      color: isUnlocked ? Colors.white : AppTheme.demonTextMuted,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      achievement.description,
                      style: TextStyle(
                        color: isUnlocked ? Colors.white70 : AppTheme.demonTextMuted.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  trailing: isUnlocked
                      ? const Icon(Icons.stars, color: Colors.amber)
                      : null,
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildHeartsCard(BuildContext context, Progress currentProgress) {
    final isFull = currentProgress.hearts >= AppConstants.maxHearts;
    final hasEnoughSouls = currentProgress.souls >= 50;
    final progressState = ref.watch(progressProvider);
    final isUpdating = progressState.isUpdating;
    
    // Remaining time formatted
    final nextHeartTime = currentProgress.lastHeartRegenTime.add(AppConstants.heartRegenInterval);
    final remaining = nextHeartTime.difference(DateTime.now());
    String countdownStr = '';
    if (!isFull) {
      if (remaining.isNegative) {
        countdownStr = '00:00';
      } else {
        final minutes = remaining.inMinutes.toString().padLeft(2, '0');
        final seconds = (remaining.inSeconds % 60).toString().padLeft(2, '0');
        countdownStr = '$minutes:$seconds';
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.demonNodeLocked.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFF1744).withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF1744).withOpacity(0.15),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF1744).withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 1,
                    )
                  ],
                ),
                child: const Icon(
                  Icons.favorite,
                  size: 32,
                  color: Color(0xFFFF1744),
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tim Ma Pháp',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(AppConstants.maxHearts, (index) {
                        final isFilled = index < currentProgress.hearts;
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(
                            Icons.favorite,
                            color: isFilled ? const Color(0xFFFF1744) : Colors.white24,
                            size: 20,
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    isFull ? 'Đầy Năng Lượng' : 'Hồi phục tiếp theo',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.demonTextMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isFull ? '🔥 FULL' : countdownStr,
                    style: TextStyle(
                      fontSize: 16,
                      color: isFull ? Colors.greenAccent : const Color(0xFFFF1744),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  isFull
                      ? 'Năng lượng đang đạt giới hạn tối đa.'
                      : 'Hồi phục 1 Tim bằng 50 Linh Hồn.\n(Ngươi đang có 👻 ${currentProgress.souls} Linh Hồn)',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.demonTextLight,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: (isFull || !hasEnoughSouls || isUpdating)
                    ? null
                    : () async {
                        final success = await ref
                            .read(progressProvider.notifier)
                            .refillHeartWithSouls(
                              userId: currentProgress.userId,
                              targetLanguage: currentProgress.targetLanguage,
                            );
                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Hồi phục Tim thành công! 💖 Ma lực đã gia tăng.',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              backgroundColor: Color(0xFF43A047),
                            ),
                          );
                        } else if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Hồi phục thất bại!'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF1744),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.white12,
                  disabledForegroundColor: Colors.white24,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isFull
                    ? const Text('Đã Đầy', style: TextStyle(fontWeight: FontWeight.bold))
                    : isUpdating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Đổi 100 XP', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
