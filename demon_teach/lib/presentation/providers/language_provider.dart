import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:demon_teach/core/di/injection_container.dart';
import 'package:demon_teach/data/repositories/language_repository_impl.dart';
import 'package:demon_teach/domain/entities/language_preference.dart';
import 'package:demon_teach/domain/repositories/language_repository.dart';
import 'package:demon_teach/domain/usecases/language/get_language_preferences.dart';
import 'package:demon_teach/domain/usecases/language/save_language_preferences.dart';

// ============================================================================
// Repository Provider
// ============================================================================

final languageRepositoryProvider = Provider<LanguageRepository>((ref) {
  return LanguageRepositoryImpl(
    sharedPreferences: ref.watch(sharedPreferencesProvider),
  );
});

// ============================================================================
// Use Case Providers
// ============================================================================

final saveLanguagePreferencesProvider =
    Provider<SaveLanguagePreferences>((ref) {
  return SaveLanguagePreferences(ref.watch(languageRepositoryProvider));
});

final getLanguagePreferencesProvider = Provider<GetLanguagePreferences>((ref) {
  return GetLanguagePreferences(ref.watch(languageRepositoryProvider));
});

// ============================================================================
// Helper Providers
// ============================================================================

final supportedTargetLanguagesProvider = Provider<List<String>>((ref) {
  return ref.watch(languageRepositoryProvider).getSupportedTargetLanguages();
});

final supportedNativeLanguagesProvider = Provider<List<String>>((ref) {
  return ref.watch(languageRepositoryProvider).getSupportedNativeLanguages();
});

final languageDisplayNameProvider =
    Provider.family<String, String>((ref, languageCode) {
  return ref
      .watch(languageRepositoryProvider)
      .getLanguageDisplayName(languageCode);
});

// ============================================================================
// State Provider
// ============================================================================

class LanguageState {
  final LanguagePreference? preference;
  final bool isLoading;
  final String? error;

  const LanguageState({
    this.preference,
    this.isLoading = false,
    this.error,
  });

  LanguageState copyWith({
    LanguagePreference? preference,
    bool? isLoading,
    String? error,
  }) {
    return LanguageState(
      preference: preference ?? this.preference,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class LanguageNotifier extends StateNotifier<LanguageState> {
  final SaveLanguagePreferences saveLanguagePreferencesUseCase;
  final GetLanguagePreferences getLanguagePreferencesUseCase;

  LanguageNotifier({
    required this.saveLanguagePreferencesUseCase,
    required this.getLanguagePreferencesUseCase,
  }) : super(const LanguageState()) {
    loadPreferences();
  }

  Future<void> loadPreferences() async {
    state = state.copyWith(isLoading: true);

    final result = await getLanguagePreferencesUseCase();

    result.when(
      success: (preference) {
        state = LanguageState(preference: preference, isLoading: false);
      },
      failure: (failure) {
        state = LanguageState(
          isLoading: false,
          error: failure.message,
        );
      },
    );
  }

  Future<bool> savePreferences({
    required String targetLanguage,
    required String nativeLanguage,
  }) async {
    state = state.copyWith(isLoading: true);

    final preference = LanguagePreference(
      targetLanguage: targetLanguage,
      nativeLanguage: nativeLanguage,
    );

    final result = await saveLanguagePreferencesUseCase(
      SaveLanguagePreferencesParams(preference: preference),
    );

    return result.when(
      success: (_) {
        state = LanguageState(preference: preference, isLoading: false);
        return true;
      },
      failure: (failure) {
        state = LanguageState(
          preference: state.preference,
          isLoading: false,
          error: failure.message,
        );
        return false;
      },
    );
  }

  Future<void> clearPreferences() async {
    state = state.copyWith(isLoading: true);
    final result = await saveLanguagePreferencesUseCase.repository.clearLanguagePreferences();
    result.when(
      success: (_) {
        state = const LanguageState(preference: null, isLoading: false);
      },
      failure: (failure) {
        state = LanguageState(
          preference: state.preference,
          isLoading: false,
          error: failure.message,
        );
      },
    );
  }
}

final languageProvider =
    StateNotifierProvider<LanguageNotifier, LanguageState>((ref) {
  return LanguageNotifier(
    saveLanguagePreferencesUseCase: ref.watch(saveLanguagePreferencesProvider),
    getLanguagePreferencesUseCase: ref.watch(getLanguagePreferencesProvider),
  );
});
