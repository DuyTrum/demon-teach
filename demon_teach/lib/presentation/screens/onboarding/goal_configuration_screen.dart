import 'dart:ui';
import 'package:demon_teach/core/theme/app_theme.dart';
import 'package:demon_teach/presentation/providers/auth_provider.dart';
import 'package:demon_teach/domain/entities/learning_goal.dart';
import 'package:demon_teach/presentation/providers/goal_provider.dart';
import 'package:demon_teach/presentation/providers/language_provider.dart';
import 'package:demon_teach/presentation/providers/assessment_provider.dart';
import 'package:demon_teach/presentation/providers/learning_path_provider.dart';
import 'package:demon_teach/presentation/screens/learning_path/learning_path_screen.dart';
import 'package:demon_teach/presentation/widgets/common/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:demon_teach/presentation/widgets/common/demon_background_particles.dart';

class GoalConfigurationScreen extends ConsumerStatefulWidget {
  const GoalConfigurationScreen({super.key});

  @override
  ConsumerState<GoalConfigurationScreen> createState() =>
      _GoalConfigurationScreenState();
}

class _GoalConfigurationScreenState
    extends ConsumerState<GoalConfigurationScreen> {
  GoalType? selectedGoalType;
  int selectedStudyMinutes = 15; // Default 15 minutes

  @override
  Widget build(BuildContext context) {
    final goalState = ref.watch(goalProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppTheme.demonBgGradientBot,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Mục tiêu học tập',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background Gradient
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
          // Embers
          const Positioned.fill(
            child: DemonBackgroundParticles(),
          ),

          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppTheme.spacingLg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header
                        const Text(
                          'Mục tiêu học tập của bạn là gì? 😈',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(color: AppTheme.demonGlowPurple, blurRadius: 10),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppTheme.spacingSm),
                        const Text(
                          'Điều này giúp chúng tôi tối ưu lộ trình học tập của riêng bạn',
                          style: TextStyle(
                            color: AppTheme.demonTextMuted,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppTheme.spacingXl),

                        // Goal type selection
                        ...GoalType.values.map((goalType) {
                          final isSelected = selectedGoalType == goalType;
                          return Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppTheme.spacingMd),
                            child: _GoalCard(
                              goalType: goalType,
                              isSelected: isSelected,
                              onTap: () {
                                setState(() {
                                  selectedGoalType = goalType;
                                });
                              },
                            ),
                          );
                        }),

                        const SizedBox(height: AppTheme.spacingXl),

                        // Study time selection
                        const Text(
                          'Thời gian học mỗi ngày',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingSm),
                        const Text(
                          'Bạn có thể dành bao nhiêu thời gian học mỗi ngày?',
                          style: TextStyle(
                            color: AppTheme.demonTextMuted,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingMd),

                        // Study time slider (Glassmorphic)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.all(AppTheme.spacingLg),
                              decoration: BoxDecoration(
                                color: AppTheme.demonCardDark.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: AppTheme.demonGlowPurple.withOpacity(0.2)),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '$selectedStudyMinutes phút',
                                    style: const TextStyle(
                                      color: AppTheme.demonGlowPurple,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        Shadow(color: AppTheme.demonGlowPurple, blurRadius: 10),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: AppTheme.spacingMd),
                                  SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      activeTrackColor: AppTheme.demonGlowPurple,
                                      inactiveTrackColor: Colors.black.withOpacity(0.3),
                                      thumbColor: Colors.white,
                                      overlayColor: AppTheme.demonGlowPurple.withOpacity(0.2),
                                      valueIndicatorColor: AppTheme.demonGlowPurple,
                                      valueIndicatorTextStyle: const TextStyle(color: Colors.white),
                                    ),
                                    child: Slider(
                                      value: selectedStudyMinutes.toDouble(),
                                      min: 5,
                                      max: 30,
                                      divisions: 25,
                                      label: '$selectedStudyMinutes phút',
                                      onChanged: (value) {
                                        setState(() {
                                          selectedStudyMinutes = value.round();
                                        });
                                      },
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: const [
                                      Text(
                                        '5 phút',
                                        style: TextStyle(
                                          color: AppTheme.demonTextMuted,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        '30 phút',
                                        style: TextStyle(
                                          color: AppTheme.demonTextMuted,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: AppTheme.spacingLg),

                        // Time recommendation (Glassmorphic)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                            child: Container(
                              padding: const EdgeInsets.all(AppTheme.spacingMd),
                              decoration: BoxDecoration(
                                color: AppTheme.demonGlowPurple.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTheme.demonGlowPurple.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.lightbulb_outline_rounded,
                                    color: AppTheme.demonGlowPurple,
                                  ),
                                  const SizedBox(width: AppTheme.spacingMd),
                                  Expanded(
                                    child: Text(
                                      _getTimeRecommendation(selectedStudyMinutes),
                                      style: const TextStyle(
                                        color: AppTheme.demonGlowPurple,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Continue button
                Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingLg),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: selectedGoalType != null
                          ? const LinearGradient(colors: [AppTheme.demonGlowPurple, AppTheme.primaryColor])
                          : null,
                      color: selectedGoalType != null ? null : AppTheme.demonNodeLocked.withOpacity(0.4),
                      border: Border.all(
                        color: selectedGoalType != null
                            ? AppTheme.demonGlowPurple.withOpacity(0.5)
                            : Colors.white.withOpacity(0.05),
                      ),
                      boxShadow: selectedGoalType != null
                          ? [
                              BoxShadow(
                                color: AppTheme.demonGlowPurple.withOpacity(0.2),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ]
                          : null,
                    ),
                    child: ElevatedButton(
                      onPressed: selectedGoalType != null && !goalState.isLoading
                          ? () => _handleContinue(context)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: goalState.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Khởi tạo lộ trình 😈',
                              style: TextStyle(
                                color: selectedGoalType != null ? Colors.white : AppTheme.demonTextMuted,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeRecommendation(int minutes) {
    if (minutes < 10) {
      return 'Rất phù hợp cho lịch trình bận rộn! Luyện tập ngắn hàng ngày giúp tạo thói quen tốt.';
    } else if (minutes < 20) {
      return 'Sự cân bằng tuyệt vời! Đủ thời gian để tạo ra tiến bộ thực sự mỗi ngày.';
    } else {
      return 'Đầy tham vọng! Thời lượng này sẽ tăng tốc đáng kể tiến trình học của bạn.';
    }
  }

  Future<void> _handleContinue(BuildContext context) async {
    if (selectedGoalType == null) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final goal = LearningGoal(
      goalType: selectedGoalType!,
      dailyStudyMinutes: selectedStudyMinutes,
    );

    // Save goal preferences
    final success =
        await ref.read(goalProvider.notifier).saveGoalPreferences(goal);

    if (!success) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Không thể lưu mục tiêu học tập. Vui lòng thử lại.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (!context.mounted) return;

    // Get language preference and assessment result
    final languageState = ref.read(languageProvider);
    final assessmentState = ref.read(assessmentProvider);

    if (languageState.preference == null || assessmentState.result == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
              'Thiếu thông tin ngôn ngữ hoặc kết quả kiểm tra. Vui lòng khởi động lại.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final user = ref.read(authProvider).user;
    final actualUserId = user?.id ?? 'default_user';

    // Generate learning path
    final pathSuccess =
        await ref.read(learningPathProvider.notifier).generatePath(
              userId: actualUserId,
              targetLanguage: languageState.preference!.targetLanguage,
              proficiencyLevel: assessmentState.result!.proficiencyLevel,
              goalType: goal.goalType,
            );

    if (!context.mounted) return;

    if (pathSuccess) {
      // Pop back to main screen
      navigator.popUntil((route) => route.isFirst);
    } else {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Không thể khởi tạo lộ trình học tập. Vui lòng thử lại.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
}

class _GoalCard extends StatelessWidget {
  final GoalType goalType;
  final bool isSelected;
  final VoidCallback onTap;

  const _GoalCard({
    required this.goalType,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.demonGlowPurple.withOpacity(0.15)
            : AppTheme.demonCardDark.withOpacity(0.5),
        border: Border.all(
          color: isSelected ? AppTheme.demonGlowPurple : Colors.white.withOpacity(0.1),
          width: isSelected ? 2 : 1.5,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: isSelected
            ? [BoxShadow(color: AppTheme.demonGlowPurple.withOpacity(0.2), blurRadius: 10)]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.demonGlowPurple.withOpacity(0.2)
                            : AppTheme.demonNodeLocked.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.demonGlowPurple.withOpacity(0.4)
                              : Colors.white.withOpacity(0.05),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          goalType.icon,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingMd),

                    // Text content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getGoalTypeDisplayName(goalType),
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppTheme.demonTextLight,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getGoalTypeDescription(goalType),
                            style: const TextStyle(
                              color: AppTheme.demonTextMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Checkmark
                    if (isSelected)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppTheme.demonGlowPurple,
                        size: 28,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getGoalTypeDisplayName(GoalType type) {
    switch (type) {
      case GoalType.conversation:
        return 'Giao tiếp hàng ngày';
      case GoalType.exam:
        return 'Thi cử & Học thuật';
      case GoalType.work:
        return 'Công việc & Sự nghiệp';
      case GoalType.travel:
        return 'Du lịch & Khám phá';
      case GoalType.hobby:
        return 'Sở thích & Giải trí';
    }
  }

  String _getGoalTypeDescription(GoalType type) {
    switch (type) {
      case GoalType.conversation:
        return 'Tập trung nghe nói, giao tiếp thường nhật';
      case GoalType.exam:
        return 'Luyện thi chứng chỉ, học tập nâng cao';
      case GoalType.work:
        return 'Thăng tiến công việc, viết email, đàm phán';
      case GoalType.travel:
        return 'Hỏi đường, gọi món, giao tiếp cơ bản';
      case GoalType.hobby:
        return 'Xem phim, nghe nhạc, rèn luyện trí não';
    }
  }
}
