import 'package:demon_teach/core/constants/app_constants.dart';
import 'package:demon_teach/core/errors/failures.dart';
import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/language_preference.dart';
import 'package:demon_teach/domain/repositories/language_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Implementation of LanguageRepository
class LanguageRepositoryImpl implements LanguageRepository {
  final SharedPreferences sharedPreferences;

  LanguageRepositoryImpl({required this.sharedPreferences});

  String? get _currentUserId => sharedPreferences.getString('current_user_id');

  String get _keyTargetLanguage => _currentUserId != null ? 'target_language_${_currentUserId}' : 'target_language';
  String get _keyNativeLanguage => _currentUserId != null ? 'native_language_${_currentUserId}' : 'native_language';

  @override
  Future<Result<void>> saveLanguagePreferences(
      LanguagePreference preference) async {
    try {
      await sharedPreferences.setString(
        _keyTargetLanguage,
        preference.targetLanguage,
      );
      await sharedPreferences.setString(
        _keyNativeLanguage,
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
  Future<Result<LanguagePreference?>> getLanguagePreferences() async {
    try {
      final targetLanguage = sharedPreferences.getString(_keyTargetLanguage);
      final nativeLanguage = sharedPreferences.getString(_keyNativeLanguage);

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
  Future<Result<void>> clearLanguagePreferences() async {
    try {
      await sharedPreferences.remove(_keyTargetLanguage);
      await sharedPreferences.remove(_keyNativeLanguage);
      return Result.success(null);
    } catch (e) {
      return Result.failure(
        CacheFailure(message: 'Failed to clear language preferences: $e'),
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
