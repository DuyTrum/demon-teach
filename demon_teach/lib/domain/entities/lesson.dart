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
    // Safely parse category, check lesson id or topic or fallback
    LessonCategory category = LessonCategory.vocabulary;
    if (json['category'] != null) {
      category = LessonCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => LessonCategory.vocabulary,
      );
    } else {
      // Fallback: guess from id (e.g. en_basic_vocab_001 -> vocabulary)
      final id = (json['id'] ?? '').toString().toLowerCase();
      if (id.contains('vocab')) {
        category = LessonCategory.vocabulary;
      } else if (id.contains('grammar')) {
        category = LessonCategory.grammar;
      } else if (id.contains('listening')) {
        category = LessonCategory.listening;
      } else if (id.contains('speaking')) {
        category = LessonCategory.speaking;
      }
    }

    // Safely parse difficulty
    LessonDifficulty difficulty = LessonDifficulty.beginner;
    if (json['difficulty'] != null) {
      difficulty = LessonDifficulty.values.firstWhere(
        (e) => e.name == json['difficulty'] || e.name.toLowerCase() == json['difficulty'].toString().toLowerCase(),
        orElse: () {
          final diffStr = json['difficulty'].toString().toLowerCase();
          if (diffStr == 'basic') return LessonDifficulty.beginner;
          return LessonDifficulty.beginner;
        },
      );
    } else {
      final id = (json['id'] ?? '').toString().toLowerCase();
      if (id.contains('basic')) {
        difficulty = LessonDifficulty.beginner;
      } else if (id.contains('intermediate')) {
        difficulty = LessonDifficulty.intermediate;
      } else if (id.contains('advanced')) {
        difficulty = LessonDifficulty.advanced;
      }
    }

    // Safely parse duration
    final duration = json['estimatedDurationMinutes'] as int? ??
        json['durationEstimate'] as int? ??
        10;

    return LessonMetadata(
      id: (json['id'] ?? json['lessonId'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? json['topic'] ?? '').toString(),
      category: category,
      difficulty: difficulty,
      targetLanguage: (json['targetLanguage'] ?? json['language'] ?? 'en').toString(),
      estimatedDurationMinutes: duration,
      tags: List<String>.from(json['tags'] as List? ?? []),
      thumbnailUrl: json['thumbnailUrl'] as String?,
    );
  }

  /// Create a copy with updated fields
  LessonMetadata copyWith({
    String? id,
    String? title,
    String? description,
    LessonCategory? category,
    LessonDifficulty? difficulty,
    String? targetLanguage,
    int? estimatedDurationMinutes,
    List<String>? tags,
    String? thumbnailUrl,
  }) {
    return LessonMetadata(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      estimatedDurationMinutes: estimatedDurationMinutes ?? this.estimatedDurationMinutes,
      tags: tags ?? this.tags,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
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
      lessonId: (json['lessonId'] ?? json['id'] ?? '').toString(),
      content: json['content'] as Map<String, dynamic>? ?? json,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'] as String)
              : DateTime.now(),
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
    final metadataMap = json['metadata'] is Map<String, dynamic>
        ? json['metadata'] as Map<String, dynamic>
        : json;

    final contentMap = json['content'] is Map<String, dynamic>
        ? json['content'] as Map<String, dynamic>
        : null;

    return Lesson(
      metadata: LessonMetadata.fromJson(metadataMap),
      content: contentMap != null
          ? LessonContent.fromJson({
              'lessonId': json['id'] ?? json['lessonId'],
              'content': contentMap,
              'lastUpdated': json['updatedAt'] ?? json['lastUpdated'],
            })
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
