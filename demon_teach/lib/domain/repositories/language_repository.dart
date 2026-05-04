import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/language_preference.dart';

/// Language repository interface
abstract class LanguageRepository {
  /// Save language preferences
  Future<Result<void>> saveLanguagePreferences(String userId, LanguagePreference preference);

  /// Get saved language preferences
  Future<Result<LanguagePreference?>> getLanguagePreferences(String userId);

  /// Get list of supported target languages
  List<String> getSupportedTargetLanguages();

  /// Get list of supported native languages
  List<String> getSupportedNativeLanguages();

  /// Get language display name
  String getLanguageDisplayName(String languageCode);
}
