import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demon_teach/core/errors/failures.dart';
import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/flashcard.dart';
import 'package:demon_teach/domain/repositories/flashcard_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Implementation of FlashcardRepository using Firestore
class FlashcardRepositoryImpl implements FlashcardRepository {
  final SharedPreferences _prefs;
  static const String _flashcardRatingsKey = 'flashcard_ratings';
  static const String _fcLessonMappingKeyPrefix = 'fc_lesson_';

  FlashcardRepositoryImpl(this._prefs);

  @override
  Future<Result<List<Flashcard>>> getFlashcardsForLesson(
      String lessonId) async {
    try {
      final docSnap = await FirebaseFirestore.instance.collection('lessons').doc(lessonId).get();
      if (!docSnap.exists || docSnap.data() == null) {
        return Result.failure(
          ServerFailure(message: 'Lesson $lessonId not found in Firestore.'),
        );
      }

      final data = docSnap.data()!;
      final content = data['content'] as Map<String, dynamic>?;
      if (content == null || content['flashcards'] == null) {
        return Result.failure(
          const ServerFailure(message: 'Flashcards are not generated for this lesson.'),
        );
      }

      final List<dynamic> flashcardList = content['flashcards'] as List;
      final flashcards = flashcardList.map((fc) {
        final fcMap = Map<String, dynamic>.from(fc as Map);
        if (fcMap['lessonId'] == null) {
          fcMap['lessonId'] = lessonId;
        }
        return Flashcard.fromJson(fcMap);
      }).toList();

      // Cache flashcardId -> lessonId mapping for later lookups in getFlashcardById
      for (final fc in flashcards) {
        await _prefs.setString('$_fcLessonMappingKeyPrefix${fc.id}', lessonId);
      }

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
        ServerFailure(message: 'Failed to get flashcards from Firestore: ${e.toString()}'),
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
      // Look up cached lessonId
      final lessonId = _prefs.getString('$_fcLessonMappingKeyPrefix$flashcardId');
      if (lessonId == null) {
        return Result.failure(
          const CacheFailure(message: 'Lesson mapping not found for flashcard. Please visit the lesson first.'),
        );
      }

      // Get all flashcards for the lesson
      final flashcardsResult = await getFlashcardsForLesson(lessonId);

      return flashcardsResult.when(
        success: (flashcards) {
          final flashcard = flashcards.firstWhere(
            (fc) => fc.id == flashcardId,
            orElse: () => throw Exception('Flashcard not found in lesson $lessonId'),
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
