import 'package:demon_teach/domain/entities/entity.dart';

/// Lesson difficulty level
enum LessonDifficulty {
  beginner,
  elementary,
  intermediate,
  upperIntermediate,
  advanced;

  String get displayName {
    switch (this) {
      case LessonDifficulty.beginner:
        return 'Beginner';
      case LessonDifficulty.elementary:
        return 'Elementary';
      case LessonDifficulty.intermediate:
        return 'Intermediate';
      case LessonDifficulty.upperIntermediate:
        return 'Upper Intermediate';
      case LessonDifficulty.advanced:
        return 'Advanced';
    }
  }
}

/// Lesson category
enum LessonCategory {
  vocabulary,
  grammar,
  listening,
  speaking,
  reading,
  writing;

  String get displayName {
    switch (this) {
      case LessonCategory.vocabulary:
        return 'Vocabulary';
      case LessonCategory.grammar:
        return 'Grammar';
      case LessonCategory.listening:
        return 'Listening';
      case LessonCategory.speaking:
        return 'Speaking';
      case LessonCategory.reading:
        return 'Reading';
      case LessonCategory.writing:
        return 'Writing';
    }
  }

  String get icon {
    switch (this) {
      case LessonCategory.vocabulary:
        return '📚';
      case LessonCategory.grammar:
        return '📝';
      case LessonCategory.listening:
        return '🎧';
      case LessonCategory.speaking:
        return '🗣️';
      case LessonCategory.reading:
        return '📖';
      case LessonCategory.writing:
        return '✍️';
    }
  }
}

/// Lesson completion status
enum LessonStatus {
  notStarted,
  inProgress,
  completed;

  String get displayName {
    switch (this) {
      case LessonStatus.notStarted:
        return 'Not Started';
      case LessonStatus.inProgress:
        return 'In Progress';
      case LessonStatus.completed:
        return 'Completed';
    }
  }
}

/// Lesson metadata entity
class LessonMetadata extends Entity {
  final String id;
  final String title;
  final String description;
  final LessonCategory category;
  final LessonDifficulty difficulty;
  final String targetLanguage;
  final int estimatedDurationMinutes;
  final List<String> tags;
  final String? thumbnailUrl;

  const LessonMetadata({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.targetLanguage,
    required this.estimatedDurationMinutes,
    this.tags = const [],
    this.thumbnailUrl,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        category,
        difficulty,
        targetLanguage,
        estimatedDurationMinutes,
        tags,
        thumbnailUrl,
      ];

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.name,
      'difficulty': difficulty.name,
      'targetLanguage': targetLanguage,
      'estimatedDurationMinutes': estimatedDurationMinutes,
      'tags': tags,
      'thumbnailUrl': thumbnailUrl,
    };
  }

  /// Create from JSON
  factory LessonMetadata.fromJson(Map<String, dynamic> json) {
    return LessonMetadata(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: LessonCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => LessonCategory.vocabulary,
      ),
      difficulty: LessonDifficulty.values.firstWhere(
        (e) => e.name == json['difficulty'],
        orElse: () => LessonDifficulty.beginner,
      ),
      targetLanguage: json['targetLanguage'] as String,
      estimatedDurationMinutes: json['estimatedDurationMinutes'] as int,
      tags: List<String>.from(json['tags'] as List? ?? []),
      thumbnailUrl: json['thumbnailUrl'] as String?,
    );
  }
}

/// Lesson content entity (stores actual lesson data)
class LessonContent extends Entity {
  final String lessonId;
  final Map<String, dynamic> content; // Flexible JSON content structure
  final DateTime lastUpdated;

  const LessonContent({
    required this.lessonId,
    required this.content,
    required this.lastUpdated,
  });

  @override
  List<Object?> get props => [lessonId, content, lastUpdated];

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'lessonId': lessonId,
      'content': content,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  /// Create from JSON
  factory LessonContent.fromJson(Map<String, dynamic> json) {
    return LessonContent(
      lessonId: json['lessonId'] as String,
      content: json['content'] as Map<String, dynamic>,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }
}

/// Complete lesson entity
class Lesson extends Entity {
  final LessonMetadata metadata;
  final LessonContent? content; // Nullable for lazy loading
  final LessonStatus status;
  final int? progressPercentage; // 0-100
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int? score; // Final score if completed

  const Lesson({
    required this.metadata,
    this.content,
    this.status = LessonStatus.notStarted,
    this.progressPercentage,
    this.startedAt,
    this.completedAt,
    this.score,
  });

  /// Check if lesson is completed
  bool get isCompleted => status == LessonStatus.completed;

  /// Check if lesson is in progress
  bool get isInProgress => status == LessonStatus.inProgress;

  /// Check if lesson is not started
  bool get isNotStarted => status == LessonStatus.notStarted;

  /// Check if content is loaded
  bool get hasContent => content != null;

  @override
  List<Object?> get props => [
        metadata,
        content,
        status,
        progressPercentage,
        startedAt,
        completedAt,
        score,
      ];

  /// Create a copy with updated fields
  Lesson copyWith({
    LessonMetadata? metadata,
    LessonContent? content,
    LessonStatus? status,
    int? progressPercentage,
    DateTime? startedAt,
    DateTime? completedAt,
    int? score,
  }) {
    return Lesson(
      metadata: metadata ?? this.metadata,
      content: content ?? this.content,
      status: status ?? this.status,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      score: score ?? this.score,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'metadata': metadata.toJson(),
      'content': content?.toJson(),
      'status': status.name,
      'progressPercentage': progressPercentage,
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'score': score,
    };
  }

  /// Create from JSON
  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      metadata:
          LessonMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
      content: json['content'] != null
          ? LessonContent.fromJson(json['content'] as Map<String, dynamic>)
          : null,
      status: LessonStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => LessonStatus.notStarted,
      ),
      progressPercentage: json['progressPercentage'] as int?,
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      score: json['score'] as int?,
    );
  }
}
