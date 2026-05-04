import 'package:demon_teach/domain/entities/entity.dart';

/// Difficulty rating for flashcards
enum DifficultyRating {
  easy,
  medium,
  hard;

  String get displayName {
    switch (this) {
      case DifficultyRating.easy:
        return 'Easy';
      case DifficultyRating.medium:
        return 'Medium';
      case DifficultyRating.hard:
        return 'Hard';
    }
  }

  String get emoji {
    switch (this) {
      case DifficultyRating.easy:
        return '😊';
      case DifficultyRating.medium:
        return '🤔';
      case DifficultyRating.hard:
        return '😰';
    }
  }
}

/// Flashcard entity for vocabulary learning
class Flashcard extends Entity {
  final String id;
  final String lessonId;
  final String frontText; // Word/phrase in target language
  final String backText; // Translation in native language
  final String exampleUsage; // Example sentence
  final String? exampleTranslation; // Translation of example sentence
  final String? phonetic; // Pinyin/IPA/Romanization
  final String? audioUrl; // Pronunciation audio URL
  final Map<String, dynamic>? details; // Extra info like Hanja/Hán Việt
  final DifficultyRating? userRating; // User's difficulty rating
  final DateTime? lastReviewed; // Last time user reviewed this card

  const Flashcard({
    required this.id,
    required this.lessonId,
    required this.frontText,
    required this.backText,
    required this.exampleUsage,
    this.exampleTranslation,
    this.phonetic,
    this.audioUrl,
    this.details,
    this.userRating,
    this.lastReviewed,
  });

  @override
  List<Object?> get props => [
        id,
        lessonId,
        frontText,
        backText,
        exampleUsage,
        exampleTranslation,
        phonetic,
        audioUrl,
        details,
        userRating,
        lastReviewed,
      ];

  /// Create a copy with updated fields
  Flashcard copyWith({
    String? id,
    String? lessonId,
    String? frontText,
    String? backText,
    String? exampleUsage,
    String? exampleTranslation,
    String? phonetic,
    String? audioUrl,
    Map<String, dynamic>? details,
    DifficultyRating? userRating,
    DateTime? lastReviewed,
  }) {
    return Flashcard(
      id: id ?? this.id,
      lessonId: lessonId ?? this.lessonId,
      frontText: frontText ?? this.frontText,
      backText: backText ?? this.backText,
      exampleUsage: exampleUsage ?? this.exampleUsage,
      exampleTranslation: exampleTranslation ?? this.exampleTranslation,
      phonetic: phonetic ?? this.phonetic,
      audioUrl: audioUrl ?? this.audioUrl,
      details: details ?? this.details,
      userRating: userRating ?? this.userRating,
      lastReviewed: lastReviewed ?? this.lastReviewed,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lessonId': lessonId,
      'frontText': frontText,
      'backText': backText,
      'exampleUsage': exampleUsage,
      'example_translation': exampleTranslation,
      'phonetic': phonetic,
      'audioUrl': audioUrl,
      'details': details,
      'userRating': userRating?.name,
      'lastReviewed': lastReviewed?.toIso8601String(),
    };
  }

  /// Create from JSON
  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      id: json['id'] as String,
      lessonId: json['lessonId'] as String,
      frontText: json['frontText'] as String,
      backText: json['backText'] as String,
      exampleUsage: (json['exampleUsage'] ?? json['example']) as String,
      exampleTranslation: json['example_translation'] as String?,
      phonetic: json['phonetic'] as String?,
      audioUrl: json['audioUrl'] as String?,
      details: json['details'] as Map<String, dynamic>?,
      userRating: json['userRating'] != null
          ? DifficultyRating.values.firstWhere(
              (e) => e.name == json['userRating'],
            )
          : null,
      lastReviewed: json['lastReviewed'] != null
          ? DateTime.parse(json['lastReviewed'] as String)
          : null,
    );
  }

  /// Helper to get Hán Việt/Hán Hàn reading
  String? get sinoVietReading => details?['hanyu_viet'];
}
