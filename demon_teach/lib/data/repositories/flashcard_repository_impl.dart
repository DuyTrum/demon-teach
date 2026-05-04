import 'package:demon_teach/core/errors/failures.dart';
import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/flashcard.dart';
import 'package:demon_teach/domain/repositories/flashcard_repository.dart';
import 'package:demon_teach/data/datasources/local/mock_flashcard_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Implementation of FlashcardRepository using SharedPreferences and mock data
class FlashcardRepositoryImpl implements FlashcardRepository {
  final SharedPreferences _prefs;
  static const String _flashcardRatingsKey = 'flashcard_ratings';

  FlashcardRepositoryImpl(this._prefs);

  @override
  Future<Result<List<Flashcard>>> getFlashcardsForLesson(
      String lessonId) async {
    try {
      // Extract target language from lessonId (format: lesson_en_1, lesson_zh_1, etc.)
      final parts = lessonId.split('_');
      final targetLanguage = parts.length > 1 ? parts[1] : 'en';

      // Get mock flashcards
      final flashcards =
          MockFlashcardData.getFlashcardsForLanguage(lessonId, targetLanguage);

      // Load user ratings from SharedPreferences
      final ratingsJson = _prefs.getString(_flashcardRatingsKey);
      Map<String, dynamic> ratings = {};
      if (ratingsJson != null) {
        ratings = json.decode(ratingsJson) as Map<String, dynamic>;
      }

      // Apply user ratings to flashcards
      final flashcardsWithRatings = flashcards.map((flashcard) {
        final ratingData = ratings[flashcard.id] as Map<String, dynamic>?;
        if (ratingData != null) {
          return flashcard.copyWith(
            userRating: DifficultyRating.values.firstWhere(
              (e) => e.name == ratingData['rating'],
            ),
            lastReviewed: DateTime.parse(ratingData['lastReviewed'] as String),
          );
        }
        return flashcard;
      }).toList();

      return Result.success(flashcardsWithRatings);
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to get flashcards: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<void>> markFlashcardDifficulty(
    String flashcardId,
    DifficultyRating rating,
  ) async {
    try {
      // Load existing ratings
      final ratingsJson = _prefs.getString(_flashcardRatingsKey);
      Map<String, dynamic> ratings = {};
      if (ratingsJson != null) {
        ratings = json.decode(ratingsJson) as Map<String, dynamic>;
      }

      // Update rating
      ratings[flashcardId] = {
        'rating': rating.name,
        'lastReviewed': DateTime.now().toIso8601String(),
      };

      // Save back to SharedPreferences
      await _prefs.setString(_flashcardRatingsKey, json.encode(ratings));

      return Result.success(null);
    } catch (e) {
      return Result.failure(
        CacheFailure(
            message: 'Failed to mark flashcard difficulty: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<Flashcard>> getFlashcardById(String flashcardId) async {
    try {
      // Extract lessonId from flashcardId (format: fc_en_lessonId_1)
      final parts = flashcardId.split('_');
      if (parts.length < 4) {
        return Result.failure(
          const ValidationFailure(
            field: 'flashcardId',
            message: 'Invalid flashcard ID format',
          ),
        );
      }

      final lessonId = parts.sublist(2, parts.length - 1).join('_');

      // Get all flashcards for the lesson
      final flashcardsResult = await getFlashcardsForLesson(lessonId);

      return flashcardsResult.when(
        success: (flashcards) {
          final flashcard = flashcards.firstWhere(
            (fc) => fc.id == flashcardId,
            orElse: () => throw Exception('Flashcard not found'),
          );
          return Result.success(flashcard);
        },
        failure: (failure) => Result.failure(failure),
      );
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to get flashcard: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<List<Flashcard>>> getHardFlashcards(String userId) async {
    try {
      // Load ratings
      final ratingsJson = _prefs.getString(_flashcardRatingsKey);
      if (ratingsJson == null) {
        return Result.success([]);
      }

      final ratings = json.decode(ratingsJson) as Map<String, dynamic>;

      // Filter flashcards marked as hard
      final hardFlashcardIds = ratings.entries
          .where((entry) {
            final ratingData = entry.value as Map<String, dynamic>;
            return ratingData['rating'] == DifficultyRating.hard.name;
          })
          .map((entry) => entry.key)
          .toList();

      // Get full flashcard objects
      final hardFlashcards = <Flashcard>[];
      for (final flashcardId in hardFlashcardIds) {
        final result = await getFlashcardById(flashcardId);
        result.when(
          success: (flashcard) => hardFlashcards.add(flashcard),
          failure: (_) {}, // Skip if not found
        );
      }

      return Result.success(hardFlashcards);
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to get hard flashcards: ${e.toString()}'),
      );
    }
  }
}
