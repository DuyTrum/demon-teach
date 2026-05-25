import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/language_preference.dart';
import 'package:demon_teach/domain/repositories/language_repository.dart';
import 'package:demon_teach/domain/usecases/usecase.dart';

/// Use case for saving language preferences
class SaveLanguagePreferences
    implements UseCase<void, SaveLanguagePreferencesParams> {
  final LanguageRepository repository;

  SaveLanguagePreferences(this.repository);

  @override
  Future<Result<void>> call(SaveLanguagePreferencesParams params) async {
    return await repository.saveLanguagePreferences(params.preference);
  }
}

class SaveLanguagePreferencesParams {
  final LanguagePreference preference;

  SaveLanguagePreferencesParams({required this.preference});
}
