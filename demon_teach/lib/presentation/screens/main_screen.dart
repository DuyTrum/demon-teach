import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:demon_teach/core/theme/app_theme.dart';
import 'package:demon_teach/presentation/providers/auth_provider.dart';
import 'package:demon_teach/presentation/providers/language_provider.dart';
import 'package:demon_teach/presentation/screens/learning_path/learning_path_screen.dart';
import 'package:demon_teach/presentation/screens/progress/progress_dashboard_screen.dart';
import 'package:demon_teach/presentation/screens/review/review_queue_screen.dart';
import 'package:demon_teach/presentation/screens/profile/profile_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final languagePref = ref.watch(languageProvider).preference;

    final String userId = user?.id ?? 'default_user';
    final String targetLang = languagePref?.targetLanguage ?? 'en';

    final List<Widget> screens = [
      const LearningPathScreen(),
      ReviewQueueScreen(userId: userId),
      ProgressDashboardScreen(userId: userId, targetLanguage: targetLang),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppTheme.demonBgGradientBot,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: AppTheme.demonGlowPurple.withOpacity(0.25),
              width: 1.5,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.demonGlowPurple.withOpacity(0.08),
              blurRadius: 15,
              spreadRadius: 2,
            )
          ],
        ),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              type: BottomNavigationBarType.fixed,
              backgroundColor: AppTheme.demonNodeLocked.withOpacity(0.85),
              elevation: 0,
              selectedItemColor: AppTheme.demonGlowPurple,
              unselectedItemColor: AppTheme.demonTextMuted,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              unselectedLabelStyle: const TextStyle(fontSize: 11),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.school_rounded),
                  label: 'Học tập',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.replay_rounded),
                  label: 'Ôn tập',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart_rounded),
                  label: 'Tiến độ',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_rounded),
                  label: 'Hồ sơ',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
