import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/language_preference.dart';
import 'package:demon_teach/domain/repositories/language_repository.dart';
import 'package:demon_teach/domain/usecases/usecase.dart';

/// Use case for getting language preferences
class GetLanguagePreferences implements NoParamsUseCase<LanguagePreference?> {
  final LanguageRepository repository;

  GetLanguagePreferences(this.repository);

  @override
  Future<Result<LanguagePreference?>> call() async {
    return await repository.getLanguagePreferences();
  }
}
