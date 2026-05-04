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
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.textSecondaryColor,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: 'Học tập',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.replay),
            label: 'Ôn tập',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Tiến độ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Hồ sơ',
          ),
        ],
      ),
    );
  }
}
