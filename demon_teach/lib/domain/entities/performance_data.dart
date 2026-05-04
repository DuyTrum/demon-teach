import 'package:demon_teach/domain/entities/entity.dart';

/// Performance data entity for tracking lesson completion metrics
class PerformanceData extends Entity {
  final String id;
  final String userId;
  final String lessonId;
  final String targetLanguage;
  final DateTime completedAt;
  final double accuracy; // 0.0 to 1.0
  final int completionTimeSeconds;
  final String difficulty; // 'basic', 'intermediate', 'advanced'
  final Map<String, dynamic> detailedMetrics;

  const PerformanceData({
    required this.id,
    required this.userId,
    required this.lessonId,
    required this.targetLanguage,
    required this.completedAt,
    required this.accuracy,
    required this.completionTimeSeconds,
    required this.difficulty,
    this.detailedMetrics = const {},
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        lessonId,
        targetLanguage,
        completedAt,
        accuracy,
        completionTimeSeconds,
        difficulty,
        detailedMetrics,
      ];

  /// Create a copy with updated fields
  PerformanceData copyWith({
    String? id,
    String? userId,
    String? lessonId,
    String? targetLanguage,
    DateTime? completedAt,
    double? accuracy,
    int? completionTimeSeconds,
    String? difficulty,
    Map<String, dynamic>? detailedMetrics,
  }) {
    return PerformanceData(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      lessonId: lessonId ?? this.lessonId,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      completedAt: completedAt ?? this.completedAt,
      accuracy: accuracy ?? this.accuracy,
      completionTimeSeconds:
          completionTimeSeconds ?? this.completionTimeSeconds,
      difficulty: difficulty ?? this.difficulty,
      detailedMetrics: detailedMetrics ?? this.detailedMetrics,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'lessonId': lessonId,
      'targetLanguage': targetLanguage,
      'completedAt': completedAt.toIso8601String(),
      'accuracy': accuracy,
      'completionTimeSeconds': completionTimeSeconds,
      'difficulty': difficulty,
      'detailedMetrics': detailedMetrics,
    };
  }

  /// Create from JSON
  factory PerformanceData.fromJson(Map<String, dynamic> json) {
    return PerformanceData(
      id: json['id'] as String,
      userId: json['userId'] as String,
      lessonId: json['lessonId'] as String,
      targetLanguage: json['targetLanguage'] as String,
      completedAt: DateTime.parse(json['completedAt'] as String),
      accuracy: (json['accuracy'] as num).toDouble(),
      completionTimeSeconds: json['completionTimeSeconds'] as int,
      difficulty: json['difficulty'] as String,
      detailedMetrics: json['detailedMetrics'] as Map<String, dynamic>? ?? {},
    );
  }
}

/// Difficulty adjustment recommendation
enum DifficultyAdjustment {
  increase,
  decrease,
  maintain;

  String get displayName {
    switch (this) {
      case DifficultyAdjustment.increase:
        return 'Increase';
      case DifficultyAdjustment.decrease:
        return 'Decrease';
      case DifficultyAdjustment.maintain:
        return 'Maintain';
    }
  }

  String get description {
    switch (this) {
      case DifficultyAdjustment.increase:
        return 'Your performance is excellent! We\'ll increase the difficulty.';
      case DifficultyAdjustment.decrease:
        return 'Let\'s adjust the difficulty to better match your current level.';
      case DifficultyAdjustment.maintain:
        return 'You\'re progressing well at the current difficulty level.';
    }
  }
}
