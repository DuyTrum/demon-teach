import 'package:demon_teach/domain/entities/entity.dart';

/// Progress tracking entity
class Progress extends Entity {
  final String userId;
  final String targetLanguage;
  final int totalXP;
  final int currentStreak;
  final int longestStreak;
  final int lessonsCompleted;
  final DateTime? lastLessonDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Progress({
    required this.userId,
    required this.targetLanguage,
    required this.totalXP,
    required this.currentStreak,
    required this.longestStreak,
    required this.lessonsCompleted,
    this.lastLessonDate,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Calculate level based on XP (every 100 XP = 1 level)
  int get level => (totalXP / 100).floor() + 1;

  /// Calculate XP progress to next level
  int get xpToNextLevel => 100 - (totalXP % 100);

  /// Calculate progress percentage to next level
  double get progressToNextLevel => (totalXP % 100) / 100;

  @override
  List<Object?> get props => [
        userId,
        targetLanguage,
        totalXP,
        currentStreak,
        longestStreak,
        lessonsCompleted,
        lastLessonDate,
        createdAt,
        updatedAt,
      ];

  /// Create a copy with updated fields
  Progress copyWith({
    String? userId,
    String? targetLanguage,
    int? totalXP,
    int? currentStreak,
    int? longestStreak,
    int? lessonsCompleted,
    DateTime? lastLessonDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Progress(
      userId: userId ?? this.userId,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      totalXP: totalXP ?? this.totalXP,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lessonsCompleted: lessonsCompleted ?? this.lessonsCompleted,
      lastLessonDate: lastLessonDate ?? this.lastLessonDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'targetLanguage': targetLanguage,
      'totalXP': totalXP,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lessonsCompleted': lessonsCompleted,
      'lastLessonDate': lastLessonDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory Progress.fromJson(Map<String, dynamic> json) {
    return Progress(
      userId: json['userId'] as String,
      targetLanguage: json['targetLanguage'] as String,
      totalXP: json['totalXP'] as int,
      currentStreak: json['currentStreak'] as int,
      longestStreak: json['longestStreak'] as int,
      lessonsCompleted: json['lessonsCompleted'] as int,
      lastLessonDate: json['lastLessonDate'] != null
          ? DateTime.parse(json['lastLessonDate'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Create initial progress for a user
  factory Progress.initial({
    required String userId,
    required String targetLanguage,
  }) {
    final now = DateTime.now();
    return Progress(
      userId: userId,
      targetLanguage: targetLanguage,
      totalXP: 0,
      currentStreak: 0,
      longestStreak: 0,
      lessonsCompleted: 0,
      lastLessonDate: null,
      createdAt: now,
      updatedAt: now,
    );
  }
}
