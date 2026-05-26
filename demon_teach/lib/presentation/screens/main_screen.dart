import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demon_teach/core/theme/app_theme.dart';
import 'package:demon_teach/core/services/notification_service.dart';
import 'package:demon_teach/presentation/providers/auth_provider.dart';
import 'package:demon_teach/presentation/providers/language_provider.dart';
import 'package:demon_teach/presentation/screens/learning_path/learning_path_screen.dart';
import 'package:demon_teach/presentation/screens/progress/progress_dashboard_screen.dart';
import 'package:demon_teach/presentation/screens/review/review_queue_screen.dart';
import 'package:demon_teach/presentation/screens/leaderboard/leaderboard_screen.dart';
import 'package:demon_teach/presentation/screens/profile/profile_screen.dart';
import 'package:demon_teach/presentation/providers/review_provider.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;
  StreamSubscription? _notificationsSubscription;
  final DateTime _appStartTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  @override
  void dispose() {
    _notificationsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initNotifications() async {
    // 1. Initialize local notifications
    await NotificationService.initialize();
    await NotificationService.requestPermissions();

    // 2. Schedule daily study reminder
    final user = ref.read(authProvider).user;
    if (user != null) {
      await NotificationService.scheduleDailyReminder(
        id: 999,
        title: 'Thì thầm Ác Ma 😈',
        body: 'Đã đến giờ hiến tế... À không, giờ học từ vựng rồi! Vào ôn tập ngay.',
        hour: 20,
        minute: 0,
      );

      // 3. Listen to real-time broadcasts
      _notificationsSubscription = FirebaseFirestore.instance
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          final doc = snapshot.docs.first.data();
          if (doc['createdAt'] != null) {
            final createdAt = (doc['createdAt'] as Timestamp).toDate();
            // Show only new alerts posted after app startup
            if (createdAt.isAfter(_appStartTime)) {
              final title = doc['title'] ?? 'Thông báo từ Quỷ Vương 👑';
              final body = doc['body'] ?? '';
              NotificationService.showNotification(
                id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
                title: title,
                body: body,
              );
            }
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final languagePref = ref.watch(languageProvider).preference;

    final String userId = user?.id ?? 'default_user';
    final String targetLang = languagePref?.targetLanguage ?? 'en';

    final List<Widget> screens = [
      const LearningPathScreen(),
      ReviewQueueScreen(userId: userId),
      const LeaderboardScreen(),
      ProgressDashboardScreen(userId: userId, targetLanguage: targetLang),
      const ProfileScreen(),
    ];

    final reviewState = ref.watch(reviewProvider);
    final hasDueReviews = reviewState.dueCount > 0;

    Widget buildIconWithBadge(IconData icon, bool hasNotification) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon),
          if (hasNotification)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.demonNodeLocked, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.redAccent.withOpacity(0.5),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    }

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
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.school_rounded),
                  label: 'Học tập',
                ),
                BottomNavigationBarItem(
                  icon: buildIconWithBadge(Icons.replay_rounded, hasDueReviews),
                  label: 'Ôn tập',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.emoji_events_rounded),
                  label: 'Xếp hạng',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart_rounded),
                  label: 'Tiến độ',
                ),
                const BottomNavigationBarItem(
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
