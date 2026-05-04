import 'package:demon_teach/core/constants/app_constants.dart';
import 'package:demon_teach/core/errors/failures.dart';
import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/language_preference.dart';
import 'package:demon_teach/domain/repositories/language_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Implementation of LanguageRepository
class LanguageRepositoryImpl implements LanguageRepository {
  final SharedPreferences sharedPreferences;

  static const String _keyTargetLanguage = 'target_language';
  static const String _keyNativeLanguage = 'native_language';

  LanguageRepositoryImpl({required this.sharedPreferences});

  @override
  Future<Result<void>> saveLanguagePreferences(
      String userId, LanguagePreference preference) async {
    try {
      await sharedPreferences.setString(
        '${userId}_$_keyTargetLanguage',
        preference.targetLanguage,
      );
      await sharedPreferences.setString(
        '${userId}_$_keyNativeLanguage',
        preference.nativeLanguage,
      );
      return Result.success(null);
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to save language preferences: $e'),
      );
    }
  }

  @override
  Future<Result<LanguagePreference?>> getLanguagePreferences(String userId) async {
    try {
      final targetLanguage = sharedPreferences.getString('${userId}_$_keyTargetLanguage');
      final nativeLanguage = sharedPreferences.getString('${userId}_$_keyNativeLanguage');

      if (targetLanguage == null || nativeLanguage == null) {
        return Result.success(null);
      }

      return Result.success(
        LanguagePreference(
          targetLanguage: targetLanguage,
          nativeLanguage: nativeLanguage,
        ),
      );
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to get language preferences: $e'),
      );
    }
  }

  @override
  List<String> getSupportedTargetLanguages() {
    return AppConstants.supportedTargetLanguages;
  }

  @override
  List<String> getSupportedNativeLanguages() {
    return AppConstants.supportedNativeLanguages;
  }

  @override
  String getLanguageDisplayName(String languageCode) {
    return AppConstants.languageNames[languageCode] ?? languageCode;
  }
}
