import 'package:demon_teach/domain/entities/entity.dart';

/// Type of content being reviewed
enum ReviewItemType {
  flashcard,
  quiz,
  listening;

  String get displayName {
    switch (this) {
      case ReviewItemType.flashcard:
        return 'Flashcard';
      case ReviewItemType.quiz:
        return 'Quiz';
      case ReviewItemType.listening:
        return 'Listening';
    }
  }
}

/// Review item entity for spaced repetition system
class ReviewItem extends Entity {
  final String id;
  final String userId;
  final String contentId; // ID of the flashcard, quiz, or listening exercise
  final ReviewItemType type;
  final DateTime nextReviewDate;
  final int repetitionCount;
  final double easeFactor;
  final int intervalDays;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ReviewItem({
    required this.id,
    required this.userId,
    required this.contentId,
    required this.type,
    required this.nextReviewDate,
    required this.repetitionCount,
    required this.easeFactor,
    required this.intervalDays,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if this review item is due for review
  bool get isDue => nextReviewDate.isBefore(DateTime.now());

  @override
  List<Object?> get props => [
        id,
        userId,
        contentId,
        type,
        nextReviewDate,
        repetitionCount,
        easeFactor,
        intervalDays,
        createdAt,
        updatedAt,
      ];

  /// Create a copy with updated fields
  ReviewItem copyWith({
    String? id,
    String? userId,
    String? contentId,
    ReviewItemType? type,
    DateTime? nextReviewDate,
    int? repetitionCount,
    double? easeFactor,
    int? intervalDays,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReviewItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      contentId: contentId ?? this.contentId,
      type: type ?? this.type,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
      repetitionCount: repetitionCount ?? this.repetitionCount,
      easeFactor: easeFactor ?? this.easeFactor,
      intervalDays: intervalDays ?? this.intervalDays,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'contentId': contentId,
      'type': type.name,
      'nextReviewDate': nextReviewDate.toIso8601String(),
      'repetitionCount': repetitionCount,
      'easeFactor': easeFactor,
      'intervalDays': intervalDays,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory ReviewItem.fromJson(Map<String, dynamic> json) {
    return ReviewItem(
      id: json['id'] as String,
      userId: json['userId'] as String,
      contentId: json['contentId'] as String,
      type: ReviewItemType.values.firstWhere(
        (e) => e.name == json['type'],
      ),
      nextReviewDate: DateTime.parse(json['nextReviewDate'] as String),
      repetitionCount: json['repetitionCount'] as int,
      easeFactor: (json['easeFactor'] as num).toDouble(),
      intervalDays: json['intervalDays'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Create initial review item
  factory ReviewItem.initial({
    required String userId,
    required String contentId,
    required ReviewItemType type,
  }) {
    final now = DateTime.now();
    return ReviewItem(
      id: 'review_${contentId}_${now.millisecondsSinceEpoch}',
      userId: userId,
      contentId: contentId,
      type: type,
      nextReviewDate:
          now.add(const Duration(days: 1)), // Initial interval: 1 day
      repetitionCount: 0,
      easeFactor: 2.5, // Initial ease factor
      intervalDays: 1,
      createdAt: now,
      updatedAt: now,
    );
  }
}

/// Review result entity
class ReviewResult extends Entity {
  final bool isCorrect;
  final int quality; // 0-5 scale for SM-2 algorithm

  const ReviewResult({
    required this.isCorrect,
    required this.quality,
  });

  @override
  List<Object?> get props => [isCorrect, quality];

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'isCorrect': isCorrect,
      'quality': quality,
    };
  }

  /// Create from JSON
  factory ReviewResult.fromJson(Map<String, dynamic> json) {
    return ReviewResult(
      isCorrect: json['isCorrect'] as bool,
      quality: json['quality'] as int,
    );
  }
}
