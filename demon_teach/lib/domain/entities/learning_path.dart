import 'package:demon_teach/domain/entities/entity.dart';
import 'package:demon_teach/domain/entities/assessment.dart';
import 'package:demon_teach/domain/entities/learning_goal.dart';

/// Learning path entity representing a personalized learning journey
class LearningPath extends Entity {
  final String id;
  final String userId;
  final String targetLanguage;
  final ProficiencyLevel proficiencyLevel;
  final GoalType goalType;
  final List<String> lessonIds; // Ordered list of lesson IDs
  final int currentLessonIndex;
  final DateTime createdAt;
  final DateTime? lastModifiedAt;

  const LearningPath({
    required this.id,
    required this.userId,
    required this.targetLanguage,
    required this.proficiencyLevel,
    required this.goalType,
    required this.lessonIds,
    this.currentLessonIndex = 0,
    required this.createdAt,
    this.lastModifiedAt,
  });

  /// Get current lesson ID
  String? get currentLessonId => currentLessonIndex < lessonIds.length
      ? lessonIds[currentLessonIndex]
      : null;

  /// Get next lesson ID
  String? get nextLessonId => currentLessonIndex + 1 < lessonIds.length
      ? lessonIds[currentLessonIndex + 1]
      : null;

  /// Calculate completion percentage
  double get completionPercentage =>
      lessonIds.isEmpty ? 0.0 : (currentLessonIndex / lessonIds.length) * 100;

  /// Check if path is completed
  bool get isCompleted => currentLessonIndex >= lessonIds.length;

  @override
  List<Object?> get props => [
        id,
        userId,
        targetLanguage,
        proficiencyLevel,
        goalType,
        lessonIds,
        currentLessonIndex,
        createdAt,
        lastModifiedAt,
      ];

  /// Create a copy with updated fields
  LearningPath copyWith({
    String? id,
    String? userId,
    String? targetLanguage,
    ProficiencyLevel? proficiencyLevel,
    GoalType? goalType,
    List<String>? lessonIds,
    int? currentLessonIndex,
    DateTime? createdAt,
    DateTime? lastModifiedAt,
  }) {
    return LearningPath(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      proficiencyLevel: proficiencyLevel ?? this.proficiencyLevel,
      goalType: goalType ?? this.goalType,
      lessonIds: lessonIds ?? this.lessonIds,
      currentLessonIndex: currentLessonIndex ?? this.currentLessonIndex,
      createdAt: createdAt ?? this.createdAt,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'targetLanguage': targetLanguage,
      'proficiencyLevel': proficiencyLevel.name,
      'goalType': goalType.name,
      'lessonIds': lessonIds,
      'currentLessonIndex': currentLessonIndex,
      'createdAt': createdAt.toIso8601String(),
      'lastModifiedAt': lastModifiedAt?.toIso8601String(),
    };
  }

  /// Create from JSON
  factory LearningPath.fromJson(Map<String, dynamic> json) {
    return LearningPath(
      id: json['id'] as String,
      userId: json['userId'] as String,
      targetLanguage: json['targetLanguage'] as String,
      proficiencyLevel: ProficiencyLevel.values.firstWhere(
        (e) => e.name == json['proficiencyLevel'],
      ),
      goalType: GoalType.values.firstWhere(
        (e) => e.name == json['goalType'],
      ),
      lessonIds: List<String>.from(json['lessonIds'] as List),
      currentLessonIndex: json['currentLessonIndex'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastModifiedAt: json['lastModifiedAt'] != null
          ? DateTime.parse(json['lastModifiedAt'] as String)
          : null,
    );
  }
}
