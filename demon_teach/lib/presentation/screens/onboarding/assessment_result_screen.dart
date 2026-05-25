import 'dart:ui';
import 'package:demon_teach/core/theme/app_theme.dart';
import 'package:demon_teach/domain/entities/assessment.dart';
import 'package:demon_teach/presentation/providers/assessment_provider.dart';
import 'package:demon_teach/presentation/screens/onboarding/goal_configuration_screen.dart';
import 'package:demon_teach/presentation/widgets/common/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:demon_teach/presentation/widgets/common/demon_background_particles.dart';

class AssessmentResultScreen extends ConsumerWidget {
  const AssessmentResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assessmentState = ref.watch(assessmentProvider);
    final result = assessmentState.result;

    if (result == null) {
      return const Scaffold(
        backgroundColor: AppTheme.demonBgGradientBot,
        body: Center(
          child: Text(
            'Không có kết quả khả dụng',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      );
    }

    final proficiencyColor = _getProficiencyColor(result.proficiencyLevel);

    return Scaffold(
      backgroundColor: AppTheme.demonBgGradientBot,
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
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),

                  // Success icon
                  Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: proficiencyColor.withOpacity(0.25),
                        shape: BoxShape.circle,
                        border: Border.all(color: proficiencyColor.withOpacity(0.6), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: proficiencyColor.withOpacity(0.4),
                            blurRadius: 25,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: Icon(
                        Icons.emoji_events_rounded,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Title
                  const Text(
                    'Đánh Giá Hoàn Tất! 😈',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      shadows: [
                        Shadow(color: AppTheme.demonGlowPurple, blurRadius: 15),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // Proficiency level
                  Text(
                    'Trình độ của bạn: ${result.proficiencyLevel.displayName}',
                    style: TextStyle(
                      color: proficiencyColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(color: proficiencyColor.withOpacity(0.5), blurRadius: 10),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // Score card (Glassmorphic)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppTheme.demonCardDark.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppTheme.demonGlowPurple.withOpacity(0.2)),
                        ),
                        child: Column(
                          children: [
                            // Score percentage
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Điểm số',
                                  style: TextStyle(
                                    color: AppTheme.demonTextLight,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '${result.score.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    color: proficiencyColor,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Correct answers
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Câu trả lời đúng',
                                  style: TextStyle(
                                    color: AppTheme.demonTextLight,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '${result.correctAnswers} / ${result.totalQuestions}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Progress bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                height: 12,
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: proficiencyColor.withOpacity(0.2),
                                      blurRadius: 8,
                                    )
                                  ],
                                ),
                                child: LinearProgressIndicator(
                                  value: result.percentage / 100,
                                  minHeight: 12,
                                  backgroundColor: Colors.black.withOpacity(0.3),
                                  valueColor: AlwaysStoppedAnimation<Color>(proficiencyColor),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Level description (Glassmorphic & Themed according to level)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: proficiencyColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: proficiencyColor.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getLevelTitle(result.proficiencyLevel),
                              style: TextStyle(
                                color: proficiencyColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _getLevelDescription(result.proficiencyLevel),
                              style: const TextStyle(
                                color: AppTheme.demonTextLight,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Continue button
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [AppTheme.demonGlowPurple, AppTheme.primaryColor],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.demonGlowPurple.withOpacity(0.25),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const GoalConfigurationScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Thiết lập mục tiêu học tập 😈',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getProficiencyColor(ProficiencyLevel level) {
    switch (level) {
      case ProficiencyLevel.basic:
        return Colors.orangeAccent;
      case ProficiencyLevel.intermediate:
        return AppTheme.demonGlowPurple;
      case ProficiencyLevel.advanced:
        return AppTheme.demonGlowGreen;
    }
  }

  String _getLevelTitle(ProficiencyLevel level) {
    switch (level) {
      case ProficiencyLevel.basic:
        return 'Cấp Độ Sơ Cấp (Basic)';
      case ProficiencyLevel.intermediate:
        return 'Cấp Độ Trung Cấp (Intermediate)';
      case ProficiencyLevel.advanced:
        return 'Cấp Độ Cao Cấp (Advanced)';
    }
  }

  String _getLevelDescription(ProficiencyLevel level) {
    switch (level) {
      case ProficiencyLevel.basic:
        return 'Bạn mới bắt đầu hành trình! Chúng tôi sẽ tập trung xây dựng nền tảng vững chắc với các từ vựng thiết yếu và ngữ pháp cơ bản nhất.';
      case ProficiencyLevel.intermediate:
        return 'Tiến bộ tuyệt vời! Bạn đã có một nền tảng khá tốt. Chúng tôi sẽ giúp bạn mở rộng kỹ năng với các hội thoại phức tạp hơn và ngữ pháp chuyên sâu.';
      case ProficiencyLevel.advanced:
        return 'Xuất sắc! Bạn sở hữu kỹ năng ngôn ngữ rất mạnh mẽ. Chúng tôi sẽ thử thách bạn với các chủ đề nâng cao để giúp bạn đạt tới sự trôi chảy tuyệt đối.';
    }
  }
}
