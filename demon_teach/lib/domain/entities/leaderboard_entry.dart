import 'package:demon_teach/domain/entities/entity.dart';

/// Leaderboard Entry domain entity
class LeaderboardEntry extends Entity {
  final String userId;
  final String displayName;
  final int totalXP;
  final int streak;
  final int rank;
  final bool isCurrentUser;
  final String avatarSeed;

  const LeaderboardEntry({
    required this.userId,
    required this.displayName,
    required this.totalXP,
    required this.streak,
    required this.rank,
    required this.isCurrentUser,
    required this.avatarSeed,
  });

  LeaderboardEntry copyWith({
    String? userId,
    String? displayName,
    int? totalXP,
    int? streak,
    int? rank,
    bool? isCurrentUser,
    String? avatarSeed,
  }) {
    return LeaderboardEntry(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      totalXP: totalXP ?? this.totalXP,
      streak: streak ?? this.streak,
      rank: rank ?? this.rank,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
      avatarSeed: avatarSeed ?? this.avatarSeed,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        displayName,
        totalXP,
        streak,
        rank,
        isCurrentUser,
        avatarSeed,
      ];

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['userId']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? '',
      totalXP: json['totalXP'] as int? ?? 0,
      streak: json['streak'] as int? ?? 0,
      rank: json['rank'] as int? ?? 0,
      isCurrentUser: json['isCurrentUser'] as bool? ?? false,
      avatarSeed: json['avatarSeed']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'displayName': displayName,
      'totalXP': totalXP,
      'streak': streak,
      'rank': rank,
      'isCurrentUser': isCurrentUser,
      'avatarSeed': avatarSeed,
    };
  }
}
