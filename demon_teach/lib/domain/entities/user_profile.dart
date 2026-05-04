import 'package:demon_teach/domain/entities/entity.dart';

/// User profile domain entity
class UserProfile extends Entity {
  final String userId;
  final int dailyStudyMinutes;
  final bool audioAutoplay;
  final bool notificationEnabled;
  final String? notificationTime;

  const UserProfile({
    required this.userId,
    required this.dailyStudyMinutes,
    required this.audioAutoplay,
    required this.notificationEnabled,
    this.notificationTime,
  });

  UserProfile copyWith({
    String? userId,
    int? dailyStudyMinutes,
    bool? audioAutoplay,
    bool? notificationEnabled,
    String? notificationTime,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      dailyStudyMinutes: dailyStudyMinutes ?? this.dailyStudyMinutes,
      audioAutoplay: audioAutoplay ?? this.audioAutoplay,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      notificationTime: notificationTime ?? this.notificationTime,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        dailyStudyMinutes,
        audioAutoplay,
        notificationEnabled,
        notificationTime,
      ];
}
