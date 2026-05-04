import 'package:demon_teach/domain/entities/entity.dart';

/// Achievement types
enum AchievementType {
  streak,
  xp,
  lessonCount,
  special,
}

/// Achievement criteria
enum AchievementCriteria {
  // Streak milestones
  streak7Days,
  streak30Days,
  streak100Days,

  // XP thresholds
  xp500,
  xp1000,
  xp5000,
  xp10000,

  // Lesson counts
  lessons10,
  lessons50,
  lessons100,
  lessons500,

  // Special achievements
  firstLesson,
  perfectQuiz,
  reviewMaster,
}

/// Achievement entity
class Achievement extends Entity {
  final String id;
  final String userId;
  final String targetLanguage;
  final AchievementCriteria criteria;
  final AchievementType type;
  final String title;
  final String description;
  final int bonusXP;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final double progress; // 0.0 to 1.0

  const Achievement({
    required this.id,
    required this.userId,
    required this.targetLanguage,
    required this.criteria,
    required this.type,
    required this.title,
    required this.description,
    required this.bonusXP,
    required this.isUnlocked,
    this.unlockedAt,
    required this.progress,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        targetLanguage,
        criteria,
        type,
        title,
        description,
        bonusXP,
        isUnlocked,
        unlockedAt,
        progress,
      ];

  /// Create a copy with updated fields
  Achievement copyWith({
    String? id,
    String? userId,
    String? targetLanguage,
    AchievementCriteria? criteria,
    AchievementType? type,
    String? title,
    String? description,
    int? bonusXP,
    bool? isUnlocked,
    DateTime? unlockedAt,
    double? progress,
  }) {
    return Achievement(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      criteria: criteria ?? this.criteria,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      bonusXP: bonusXP ?? this.bonusXP,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      progress: progress ?? this.progress,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'targetLanguage': targetLanguage,
      'criteria': criteria.name,
      'type': type.name,
      'title': title,
      'description': description,
      'bonusXP': bonusXP,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'progress': progress,
    };
  }

  /// Create from JSON
  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      userId: json['userId'] as String,
      targetLanguage: json['targetLanguage'] as String,
      criteria: AchievementCriteria.values.firstWhere(
        (e) => e.name == json['criteria'],
      ),
      type: AchievementType.values.firstWhere(
        (e) => e.name == json['type'],
      ),
      title: json['title'] as String,
      description: json['description'] as String,
      bonusXP: json['bonusXP'] as int,
      isUnlocked: json['isUnlocked'] as bool,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'] as String)
          : null,
      progress: (json['progress'] as num).toDouble(),
    );
  }

  /// Get target value for achievement criteria
  int getTargetValue() {
    switch (criteria) {
      case AchievementCriteria.streak7Days:
        return 7;
      case AchievementCriteria.streak30Days:
        return 30;
      case AchievementCriteria.streak100Days:
        return 100;
      case AchievementCriteria.xp500:
        return 500;
      case AchievementCriteria.xp1000:
        return 1000;
      case AchievementCriteria.xp5000:
        return 5000;
      case AchievementCriteria.xp10000:
        return 10000;
      case AchievementCriteria.lessons10:
        return 10;
      case AchievementCriteria.lessons50:
        return 50;
      case AchievementCriteria.lessons100:
        return 100;
      case AchievementCriteria.lessons500:
        return 500;
      case AchievementCriteria.firstLesson:
        return 1;
      case AchievementCriteria.perfectQuiz:
        return 1;
      case AchievementCriteria.reviewMaster:
        return 100;
    }
  }

  /// Get icon for achievement
  String getIcon() {
    switch (type) {
      case AchievementType.streak:
        return '🔥';
      case AchievementType.xp:
        return '⭐';
      case AchievementType.lessonCount:
        return '📚';
      case AchievementType.special:
        return '🏆';
    }
  }
}
