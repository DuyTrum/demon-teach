import 'dart:convert';

import 'package:demon_teach/core/errors/failures.dart';
import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/flashcard.dart';
import 'package:demon_teach/domain/entities/listening_exercise.dart';
import 'package:demon_teach/domain/entities/quiz.dart';
import 'package:demon_teach/domain/entities/speaking_exercise.dart';

/// Validation result for content parsing
class ValidationResult {
  final bool isValid;
  final List<String> errors;

  const ValidationResult({
    required this.isValid,
    required this.errors,
  });

  factory ValidationResult.valid() {
    return const ValidationResult(isValid: true, errors: []);
  }

  factory ValidationResult.invalid(List<String> errors) {
    return ValidationResult(isValid: false, errors: errors);
  }
}

/// Lesson content structure for parsing
class LessonContent {
  final List<Flashcard> flashcards;
  final ListeningExercise? listeningExercise;
  final Quiz quiz;
  final SpeakingExercise? speakingExercise;

  const LessonContent({
    required this.flashcards,
    this.listeningExercise,
    required this.quiz,
    this.speakingExercise,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LessonContent &&
        _listEquals(other.flashcards, flashcards) &&
        other.listeningExercise == listeningExercise &&
        other.quiz == quiz &&
        other.speakingExercise == speakingExercise;
  }

  @override
  int get hashCode {
    return flashcards.hashCode ^
        listeningExercise.hashCode ^
        quiz.hashCode ^
        speakingExercise.hashCode;
  }

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'flashcards': flashcards.map((f) => f.toJson()).toList(),
      if (listeningExercise != null)
        'listeningExercise': listeningExercise!.toJson(),
      'quiz': quiz.toJson(),
      if (speakingExercise != null)
        'speakingExercise': speakingExercise!.toJson(),
    };
  }

  /// Create from JSON
  factory LessonContent.fromJson(Map<String, dynamic> json) {
    final rawFlashcards = json['flashcards'] ?? [];
    final List<Flashcard> resolvedFlashcards = rawFlashcards is List
        ? rawFlashcards.map((f) => Flashcard.fromJson(f as Map<String, dynamic>)).toList()
        : [];

    final rawQuiz = json['quiz'] is Map<String, dynamic>
        ? Quiz.fromJson(json['quiz'] as Map<String, dynamic>)
        : Quiz(id: '', lessonId: '', title: '', questions: []);

    return LessonContent(
      flashcards: resolvedFlashcards,
      listeningExercise: json['listeningExercise'] != null
          ? ListeningExercise.fromJson(
              json['listeningExercise'] as Map<String, dynamic>)
          : null,
      quiz: rawQuiz,
      speakingExercise: json['speakingExercise'] != null
          ? SpeakingExercise.fromJson(
              json['speakingExercise'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Content parser for lesson content files
///
/// Parses and validates lesson content JSON files with the following features:
/// - JSON parsing into LessonContent objects
/// - Content structure validation against schema
/// - Pretty printing for content serialization
/// - Round-trip validation (parse → print → parse)
/// - UTF-8 encoding support for all languages (EN, ZH, KO)
class ContentParser {
  /// Parse lesson content from JSON string
  ///
  /// Returns Result<LessonContent> with either:
  /// - Success: Parsed LessonContent object
  /// - Failure: ValidationFailure with descriptive error messages
  Result<LessonContent> parse(String contentJson) {
    try {
      // Decode JSON
      final dynamic decoded = jsonDecode(contentJson);

      if (decoded is! Map<String, dynamic>) {
        return Result.failure(
          const ValidationFailure(
            field: 'root',
            message: 'Content must be a JSON object',
          ),
        );
      }

      final json = decoded;

      // Validate structure
      final validation = _validateStructure(json);
      if (!validation.isValid) {
        return Result.failure(
          ValidationFailure(
            field: 'content',
            message: validation.errors.join('; '),
          ),
        );
      }

      // Parse into domain objects
      final content = LessonContent.fromJson(json);

      return Result.success(content);
    } on FormatException catch (e) {
      return Result.failure(
        ValidationFailure(
          field: 'json',
          message: 'Invalid JSON format: ${e.message}',
        ),
      );
    } catch (e) {
      return Result.failure(
        ValidationFailure(
          field: 'parse',
          message: 'Parse error: ${e.toString()}',
        ),
      );
    }
  }

  /// Pretty print lesson content to JSON string
  ///
  /// Returns Result<String> with either:
  /// - Success: Formatted JSON string with 2-space indentation
  /// - Failure: ValidationFailure if serialization fails
  Result<String> prettyPrint(LessonContent content) {
    try {
      final json = content.toJson();
      const encoder = JsonEncoder.withIndent('  ');
      final prettyJson = encoder.convert(json);

      return Result.success(prettyJson);
    } catch (e) {
      return Result.failure(
        ValidationFailure(
          field: 'serialize',
          message: 'Serialization error: ${e.toString()}',
        ),
      );
    }
  }

  /// Validate content structure against schema
  ///
  /// Checks for:
  /// - Required fields (flashcards, quiz)
  /// - Correct data types
  /// - Required fields within nested objects
  /// - Valid URL formats for audio/image resources
  ValidationResult _validateStructure(Map<String, dynamic> json) {
    final errors = <String>[];

    // Required fields
    if (!json.containsKey('flashcards')) {
      errors.add('Missing required field: flashcards');
    }
    if (!json.containsKey('quiz')) {
      errors.add('Missing required field: quiz');
    }

    // Validate flashcards
    if (json.containsKey('flashcards')) {
      if (json['flashcards'] is! List) {
        errors.add('flashcards must be an array');
      } else {
        final flashcards = json['flashcards'] as List;
        if (flashcards.isEmpty) {
          errors.add('flashcards array cannot be empty');
        }
        for (int i = 0; i < flashcards.length; i++) {
          if (flashcards[i] is! Map<String, dynamic>) {
            errors.add('flashcards[$i]: must be an object');
            continue;
          }
          final fc = flashcards[i] as Map<String, dynamic>;
          _validateFlashcard(fc, i, errors);
        }
      }
    }

    // Validate quiz
    if (json.containsKey('quiz')) {
      if (json['quiz'] is! Map<String, dynamic>) {
        errors.add('quiz must be an object');
      } else {
        final quiz = json['quiz'] as Map<String, dynamic>;
        _validateQuiz(quiz, errors);
      }
    }

    // Validate optional listening exercise
    if (json.containsKey('listeningExercise')) {
      if (json['listeningExercise'] is! Map<String, dynamic>) {
        errors.add('listeningExercise must be an object');
      } else {
        final listening = json['listeningExercise'] as Map<String, dynamic>;
        _validateListeningExercise(listening, errors);
      }
    }

    // Validate optional speaking exercise
    if (json.containsKey('speakingExercise')) {
      if (json['speakingExercise'] is! Map<String, dynamic>) {
        errors.add('speakingExercise must be an object');
      } else {
        final speaking = json['speakingExercise'] as Map<String, dynamic>;
        _validateSpeakingExercise(speaking, errors);
      }
    }

    return errors.isEmpty
        ? ValidationResult.valid()
        : ValidationResult.invalid(errors);
  }

  /// Validate flashcard structure
  void _validateFlashcard(
      Map<String, dynamic> fc, int index, List<String> errors) {
    final requiredFields = [
      'id',
      'frontText',
      'backText',
    ];
    for (final field in requiredFields) {
      if (!fc.containsKey(field)) {
        // Fallback checks
        if (field == 'frontText' && fc.containsKey('word')) continue;
        if (field == 'backText' && fc.containsKey('translation')) continue;
        errors.add('flashcards[$index]: missing required field "$field"');
      } else if (fc[field] is! String) {
        errors.add('flashcards[$index]: field "$field" must be a string');
      } else if ((fc[field] as String).isEmpty) {
        errors.add('flashcards[$index]: field "$field" cannot be empty');
      }
    }

    // Validate optional audioUrl
    if (fc.containsKey('audioUrl') && fc['audioUrl'] != null) {
      if (fc['audioUrl'] is! String) {
        errors.add('flashcards[$index]: audioUrl must be a string');
      } else {
        final url = fc['audioUrl'] as String;
        if (!_isValidUrl(url)) {
          errors.add('flashcards[$index]: audioUrl is not a valid URL');
        }
      }
    }
  }

  /// Validate quiz structure
  void _validateQuiz(Map<String, dynamic> quiz, List<String> errors) {
    final requiredFields = ['id', 'lessonId', 'title', 'questions'];
    for (final field in requiredFields) {
      if (!quiz.containsKey(field)) {
        errors.add('quiz: missing required field "$field"');
      }
    }

    if (quiz.containsKey('questions')) {
      if (quiz['questions'] is! List) {
        errors.add('quiz: questions must be an array');
      } else {
        final questions = quiz['questions'] as List;
        if (questions.isEmpty) {
          errors.add('quiz: questions array cannot be empty');
        }
        for (int i = 0; i < questions.length; i++) {
          if (questions[i] is! Map<String, dynamic>) {
            errors.add('quiz.questions[$i]: must be an object');
            continue;
          }
          final q = questions[i] as Map<String, dynamic>;
          _validateQuizQuestion(q, i, errors);
        }
      }
    }
  }

  /// Validate quiz question structure
  void _validateQuizQuestion(
      Map<String, dynamic> q, int index, List<String> errors) {
    final requiredFields = [
      'id',
      'type',
      'questionText',
      'options',
      'correctAnswer',
      'explanation'
    ];
    for (final field in requiredFields) {
      if (!q.containsKey(field)) {
        errors.add('quiz.questions[$index]: missing required field "$field"');
      }
    }

    // Validate type
    if (q.containsKey('type')) {
      if (q['type'] is! String) {
        errors.add('quiz.questions[$index]: type must be a string');
      } else {
        final type = q['type'] as String;
        if (!['multipleChoice', 'fillInBlank', 'matching'].contains(type)) {
          errors.add(
              'quiz.questions[$index]: type must be one of: multipleChoice, fillInBlank, matching');
        }
      }
    }

    // Validate options
    if (q.containsKey('options')) {
      if (q['options'] is! List) {
        errors.add('quiz.questions[$index]: options must be an array');
      }
    }
  }

  /// Validate listening exercise structure
  void _validateListeningExercise(
      Map<String, dynamic> listening, List<String> errors) {
    final requiredFields = [
      'id',
      'lessonId',
      'audioUrl',
      'durationSeconds',
      'questions'
    ];
    for (final field in requiredFields) {
      if (!listening.containsKey(field)) {
        errors.add('listeningExercise: missing required field "$field"');
      }
    }

    // Validate audioUrl
    if (listening.containsKey('audioUrl')) {
      if (listening['audioUrl'] is! String) {
        errors.add('listeningExercise: audioUrl must be a string');
      } else {
        final url = listening['audioUrl'] as String;
        if (!_isValidUrl(url)) {
          errors.add('listeningExercise: audioUrl is not a valid URL');
        }
      }
    }

    // Validate durationSeconds
    if (listening.containsKey('durationSeconds')) {
      if (listening['durationSeconds'] is! int) {
        errors.add('listeningExercise: durationSeconds must be an integer');
      }
    }

    // Validate questions
    if (listening.containsKey('questions')) {
      if (listening['questions'] is! List) {
        errors.add('listeningExercise: questions must be an array');
      } else {
        final questions = listening['questions'] as List;
        if (questions.isEmpty) {
          errors.add('listeningExercise: questions array cannot be empty');
        }
      }
    }
  }

  /// Validate speaking exercise structure
  void _validateSpeakingExercise(
      Map<String, dynamic> speaking, List<String> errors) {
    final requiredFields = ['id', 'lessonId', 'phrase', 'modelAudioUrl'];
    for (final field in requiredFields) {
      if (!speaking.containsKey(field)) {
        errors.add('speakingExercise: missing required field "$field"');
      }
    }

    // Validate modelAudioUrl
    if (speaking.containsKey('modelAudioUrl')) {
      if (speaking['modelAudioUrl'] is! String) {
        errors.add('speakingExercise: modelAudioUrl must be a string');
      } else {
        final url = speaking['modelAudioUrl'] as String;
        if (!_isValidUrl(url)) {
          errors.add('speakingExercise: modelAudioUrl is not a valid URL');
        }
      }
    }
  }

  /// Validate URL format
  bool _isValidUrl(String url) {
    if (url.isEmpty) return false;
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }
}
