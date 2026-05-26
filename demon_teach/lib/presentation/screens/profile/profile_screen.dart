import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:demon_teach/core/theme/app_theme.dart';
import 'package:demon_teach/presentation/providers/auth_provider.dart';
import 'package:demon_teach/presentation/providers/language_provider.dart';
import 'package:demon_teach/presentation/providers/progress_provider.dart';
import 'package:demon_teach/presentation/screens/onboarding/language_selection_screen.dart';
import 'package:demon_teach/presentation/widgets/common/demon_background_particles.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProgress();
    });
  }

  void _loadProgress() {
    final user = ref.read(authProvider).user;
    final languagePref = ref.read(languageProvider).preference;
    final String userId = user?.id ?? 'default_user';
    final String targetLang = languagePref?.targetLanguage ?? 'en';

    ref.read(progressProvider.notifier).loadProgress(
          userId: userId,
          targetLanguage: targetLang,
        );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final progressState = ref.watch(progressProvider);
    final progress = progressState.progress;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppTheme.demonBgGradientBot,
      appBar: AppBar(
        title: const Text(
          'Hồ sơ',
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
            onPressed: _loadProgress,
          ),
        ],
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

          // Eerie Particles
          const Positioned.fill(child: DemonBackgroundParticles()),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: AppTheme.spacingMd),
                  // Glowing Avatar
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.demonGlowPurple.withOpacity(0.25),
                      border: Border.all(
                        color: AppTheme.demonGlowPurple.withOpacity(0.8),
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.demonGlowPurple.withOpacity(0.5),
                          blurRadius: 30,
                          spreadRadius: 5,
                        )
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.person,
                        size: 55,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                  Text(
                    user?.email ?? 'Đệ tử Ác Quỷ',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: AppTheme.demonGlowPurple,
                          blurRadius: 10,
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXs),
                  const Text(
                    'Đệ tử Demon Teach',
                    style: TextStyle(
                      color: AppTheme.demonTextMuted,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXl),

                  // Real Progress Metrics Section
                  if (progressState.isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(
                        child: CircularProgressIndicator(
                            color: AppTheme.demonGlowPurple),
                      ),
                    )
                  else if (progress != null) ...[
                    _buildStatsGrid(progress),
                    const SizedBox(height: AppTheme.spacingLg),
                    _buildLevelProgressCard(progress),
                    const SizedBox(height: AppTheme.spacingLg),
                  ] else ...[
                    // Empty/Fallback state
                    _buildStatsGrid(null),
                    const SizedBox(height: AppTheme.spacingLg),
                  ],

                  _buildSettingsCard(context, ref),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(dynamic progress) {
    final int streak = progress?.currentStreak ?? 0;
    final int longestStreak = progress?.longestStreak ?? 0;
    final int completed = progress?.lessonsCompleted ?? 0;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Chuỗi học',
            '$streak ngày',
            Icons.local_fire_department,
            Colors.orangeAccent,
          ),
        ),
        const SizedBox(width: AppTheme.spacingMd),
        Expanded(
          child: _buildStatCard(
            'Bài học',
            completed.toString(),
            Icons.school,
            AppTheme.demonGlowGreen,
          ),
        ),
        const SizedBox(width: AppTheme.spacingMd),
        Expanded(
          child: _buildStatCard(
            'Kỷ lục',
            '$longestStreak ngày',
            Icons.emoji_events,
            AppTheme.demonGlowPurple,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: AppTheme.demonNodeLocked.withOpacity(0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: AppTheme.demonTextMuted,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelProgressCard(dynamic progress) {
    final int level = progress.level;
    final int totalXP = progress.totalXP;
    final double pct = progress.progressToNextLevel;
    final int xpLeft = progress.xpToNextLevel;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          decoration: BoxDecoration(
            color: AppTheme.demonNodeLocked.withOpacity(0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Đệ tử Cấp $level',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.demonGlowPurple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.demonGlowPurple.withOpacity(0.4)),
                    ),
                    child: Text(
                      'Tổng $totalXP XP',
                      style: const TextStyle(
                        color: AppTheme.demonGlowPurple,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Linear Progress Indicator
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.demonGlowPurple.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: Colors.black.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.demonGlowPurple),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Cần thêm $xpLeft XP để gia tăng ma lực',
                style: const TextStyle(
                  color: AppTheme.demonTextMuted,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, WidgetRef ref) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.demonNodeLocked.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              _buildSettingTile(
                context,
                icon: Icons.edit,
                color: AppTheme.demonGlowGreen,
                title: 'Đổi tên hiển thị',
                onTap: () => _showEditDisplayNameDialog(context, ref),
              ),
              Divider(height: 1, color: Colors.white.withOpacity(0.1)),
              _buildSettingTile(
                context,
                icon: Icons.language,
                color: AppTheme.demonGlowPurple,
                title: 'Thay đổi ngôn ngữ học',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          const LanguageSelectionScreen(isFromSettings: true),
                    ),
                  );
                },
              ),
              Divider(height: 1, color: Colors.white.withOpacity(0.1)),
              _buildSettingTile(
                context,
                icon: Icons.notifications,
                color: Colors.orangeAccent,
                title: 'Cài đặt thông báo',
                onTap: () {
                  _showDemonDialog(
                    context,
                    title: 'Thông báo',
                    content:
                        'Lời thì thầm của ác quỷ đang được tinh chỉnh. Hãy quay lại sau!',
                  );
                },
              ),
              Divider(height: 1, color: Colors.white.withOpacity(0.1)),
              _buildSettingTile(
                context,
                icon: Icons.logout,
                color: Colors.redAccent,
                title: 'Đăng xuất',
                textColor: Colors.redAccent,
                onTap: () async {
                  _showDemonDialog(
                    context,
                    title: 'Đăng xuất',
                    content: 'Bạn có chắc chắn muốn cắt đứt liên kết?',
                    isDestructive: true,
                    onConfirm: () async {
                      Navigator.pop(context);
                      await ref.read(authProvider.notifier).logout();
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.5)),
      onTap: onTap,
    );
  }

  void _showDemonDialog(
    BuildContext context, {
    required String title,
    required String content,
    bool isDestructive = false,
    VoidCallback? onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.demonNodeLocked,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
              color: isDestructive
                  ? Colors.redAccent.withOpacity(0.5)
                  : AppTheme.demonGlowPurple.withOpacity(0.5)),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive ? Colors.redAccent : AppTheme.demonGlowPurple,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          content,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy',
                style: TextStyle(color: AppTheme.demonTextMuted)),
          ),
          if (onConfirm != null)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDestructive
                    ? Colors.redAccent.withOpacity(0.2)
                    : AppTheme.demonGlowPurple.withOpacity(0.2),
                foregroundColor:
                    isDestructive ? Colors.redAccent : AppTheme.demonGlowPurple,
                side: BorderSide(
                    color: isDestructive
                        ? Colors.redAccent
                        : AppTheme.demonGlowPurple),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: onConfirm,
              child: Text(isDestructive ? 'Cắt đứt' : 'Xác nhận'),
            ),
        ],
      ),
    );
  }

  void _showEditDisplayNameDialog(BuildContext context, WidgetRef ref) {
    final user = ref.read(authProvider).user;
    final TextEditingController controller = TextEditingController();

    // Get current display name from Firestore or fallback to email username
    String currentDisplayName = '';
    if (user != null) {
      final email = user.email;
      if (email.isNotEmpty) {
        currentDisplayName = email.split('@').first;
      }
    }
    controller.text = currentDisplayName;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.demonNodeLocked,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppTheme.demonGlowPurple.withOpacity(0.5)),
        ),
        title: const Text(
          'Đổi tên hiển thị',
          style: TextStyle(
            color: AppTheme.demonGlowPurple,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tên này sẽ hiển thị trên bảng xếp hạng',
              style: TextStyle(color: AppTheme.demonTextMuted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              maxLength: 20,
              decoration: InputDecoration(
                hintText: 'Nhập tên hiển thị',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                filled: true,
                fillColor: Colors.black.withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: AppTheme.demonGlowPurple.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: AppTheme.demonGlowPurple.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: AppTheme.demonGlowPurple, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy',
                style: TextStyle(color: AppTheme.demonTextMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.demonGlowPurple.withOpacity(0.2),
              foregroundColor: AppTheme.demonGlowPurple,
              side: const BorderSide(color: AppTheme.demonGlowPurple),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tên hiển thị không được để trống'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
                return;
              }

              Navigator.pop(context);

              // Update display name
              final result = await ref
                  .read(authProvider.notifier)
                  .updateDisplayName(newName);

              if (context.mounted) {
                result.when(
                  success: (_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Đã đổi tên thành "$newName"'),
                        backgroundColor: AppTheme.demonGlowGreen,
                      ),
                    );
                  },
                  failure: (failure) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lỗi: ${failure.message}'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  },
                );
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }
}
