import 'package:demon_teach/domain/entities/entity.dart';

/// Learning goal types
enum GoalType {
  conversation,
  exam,
  work,
  travel,
  hobby;

  String get displayName {
    switch (this) {
      case GoalType.conversation:
        return 'Conversation';
      case GoalType.exam:
        return 'Exam Preparation';
      case GoalType.work:
        return 'Work/Business';
      case GoalType.travel:
        return 'Travel';
      case GoalType.hobby:
        return 'Hobby/Interest';
    }
  }

  String get description {
    switch (this) {
      case GoalType.conversation:
        return 'Focus on speaking and listening for daily conversations';
      case GoalType.exam:
        return 'Prepare for language proficiency exams';
      case GoalType.work:
        return 'Learn professional and business language';
      case GoalType.travel:
        return 'Learn essential phrases for traveling';
      case GoalType.hobby:
        return 'Learn at your own pace for personal interest';
    }
  }

  String get icon {
    switch (this) {
      case GoalType.conversation:
        return '💬';
      case GoalType.exam:
        return '📝';
      case GoalType.work:
        return '💼';
      case GoalType.travel:
        return '✈️';
      case GoalType.hobby:
        return '🎨';
    }
  }
}

/// Learning goal preference entity
class LearningGoal extends Entity {
  final GoalType goalType;
  final int dailyStudyMinutes; // 5-30 minutes

  const LearningGoal({
    required this.goalType,
    required this.dailyStudyMinutes,
  });

  /// Validate study time is within range
  bool get isValidStudyTime =>
      dailyStudyMinutes >= 5 && dailyStudyMinutes <= 30;

  @override
  List<Object?> get props => [goalType, dailyStudyMinutes];

  /// Create a copy with updated fields
  LearningGoal copyWith({
    GoalType? goalType,
    int? dailyStudyMinutes,
  }) {
    return LearningGoal(
      goalType: goalType ?? this.goalType,
      dailyStudyMinutes: dailyStudyMinutes ?? this.dailyStudyMinutes,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'goalType': goalType.name,
      'dailyStudyMinutes': dailyStudyMinutes,
    };
  }

  /// Create from JSON
  factory LearningGoal.fromJson(Map<String, dynamic> json) {
    return LearningGoal(
      goalType: GoalType.values.firstWhere(
        (e) => e.name == json['goalType'],
        orElse: () => GoalType.hobby,
      ),
      dailyStudyMinutes: json['dailyStudyMinutes'] as int,
    );
  }
}
