import 'package:demon_teach/domain/entities/entity.dart';

/// Language preference entity
class LanguagePreference extends Entity {
  final String targetLanguage;
  final String nativeLanguage;

  const LanguagePreference({
    required this.targetLanguage,
    required this.nativeLanguage,
  });

  LanguagePreference copyWith({
    String? targetLanguage,
    String? nativeLanguage,
  }) {
    return LanguagePreference(
      targetLanguage: targetLanguage ?? this.targetLanguage,
      nativeLanguage: nativeLanguage ?? this.nativeLanguage,
    );
  }

  @override
  List<Object?> get props => [targetLanguage, nativeLanguage];
}
