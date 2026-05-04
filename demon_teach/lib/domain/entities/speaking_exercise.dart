import 'package:demon_teach/domain/entities/entity.dart';

/// Pronunciation feedback for speaking exercises
class PronunciationFeedback extends Entity {
  final double accuracyScore; // 0.0 to 1.0
  final String feedback;
  final List<String> suggestions;

  const PronunciationFeedback({
    required this.accuracyScore,
    required this.feedback,
    required this.suggestions,
  });

  @override
  List<Object?> get props => [accuracyScore, feedback, suggestions];

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'accuracyScore': accuracyScore,
      'feedback': feedback,
      'suggestions': suggestions,
    };
  }

  /// Create from JSON
  factory PronunciationFeedback.fromJson(Map<String, dynamic> json) {
    return PronunciationFeedback(
      accuracyScore: (json['accuracyScore'] as num).toDouble(),
      feedback: json['feedback'] as String,
      suggestions: List<String>.from(json['suggestions'] as List),
    );
  }
}

/// Speaking exercise entity
class SpeakingExercise extends Entity {
  final String id;
  final String lessonId;
  final String phrase;
  final String modelAudioUrl;
  final String? userRecordingPath;
  final PronunciationFeedback? feedback;
  final DateTime? recordedAt;

  const SpeakingExercise({
    required this.id,
    required this.lessonId,
    required this.phrase,
    required this.modelAudioUrl,
    this.userRecordingPath,
    this.feedback,
    this.recordedAt,
  });

  /// Check if user has recorded
  bool get hasRecording => userRecordingPath != null;

  /// Check if feedback is available
  bool get hasFeedback => feedback != null;

  @override
  List<Object?> get props => [
        id,
        lessonId,
        phrase,
        modelAudioUrl,
        userRecordingPath,
        feedback,
        recordedAt,
      ];

  /// Create a copy with updated fields
  SpeakingExercise copyWith({
    String? id,
    String? lessonId,
    String? phrase,
    String? modelAudioUrl,
    String? userRecordingPath,
    PronunciationFeedback? feedback,
    DateTime? recordedAt,
  }) {
    return SpeakingExercise(
      id: id ?? this.id,
      lessonId: lessonId ?? this.lessonId,
      phrase: phrase ?? this.phrase,
      modelAudioUrl: modelAudioUrl ?? this.modelAudioUrl,
      userRecordingPath: userRecordingPath ?? this.userRecordingPath,
      feedback: feedback ?? this.feedback,
      recordedAt: recordedAt ?? this.recordedAt,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lessonId': lessonId,
      'phrase': phrase,
      'modelAudioUrl': modelAudioUrl,
      'userRecordingPath': userRecordingPath,
      'feedback': feedback?.toJson(),
      'recordedAt': recordedAt?.toIso8601String(),
    };
  }

  /// Create from JSON
  factory SpeakingExercise.fromJson(Map<String, dynamic> json) {
    return SpeakingExercise(
      id: json['id'] as String,
      lessonId: json['lessonId'] as String,
      phrase: json['phrase'] as String,
      modelAudioUrl: json['modelAudioUrl'] as String,
      userRecordingPath: json['userRecordingPath'] as String?,
      feedback: json['feedback'] != null
          ? PronunciationFeedback.fromJson(
              json['feedback'] as Map<String, dynamic>)
          : null,
      recordedAt: json['recordedAt'] != null
          ? DateTime.parse(json['recordedAt'] as String)
          : null,
    );
  }
}
