import 'package:demon_teach/domain/entities/user.dart';
import 'package:demon_teach/domain/repositories/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:demon_teach/core/di/injection_container.dart';
import 'package:demon_teach/presentation/providers/language_provider.dart';

// Repository provider (to be overridden in main)
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  throw UnimplementedError('AuthRepository must be overridden');
});

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final LanguageNotifier _languageNotifier;

  AuthNotifier(this._repository, this._languageNotifier) : super(const AuthState()) {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    state = state.copyWith(isLoading: true);
    final isAuth = await _repository.isAuthenticated();
    
    if (isAuth) {
      final result = await _repository.getCurrentUser();
      result.when(
        success: (user) {
          state = AuthState(user: user, isAuthenticated: true, isLoading: false);
          if (user.nativeLanguage.isNotEmpty && user.targetLanguages.isNotEmpty) {
            _languageNotifier.savePreferences(
              targetLanguage: user.targetLanguages.first,
              nativeLanguage: user.nativeLanguage,
            );
          } else {
            _languageNotifier.clearPreferences();
          }
        },
        failure: (failure) {
          state = AuthState(isAuthenticated: false, isLoading: false, error: failure.message);
        },
      );
    } else {
      state = const AuthState(isAuthenticated: false, isLoading: false);
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true);
    final result = await _repository.login(email, password);

    return result.when(
      success: (user) {
        state = AuthState(user: user, isAuthenticated: true, isLoading: false);
        if (user.nativeLanguage.isNotEmpty && user.targetLanguages.isNotEmpty) {
          _languageNotifier.savePreferences(
            targetLanguage: user.targetLanguages.first,
            nativeLanguage: user.nativeLanguage,
          );
        } else {
          _languageNotifier.clearPreferences();
        }
        return true;
      },
      failure: (failure) {
        state = AuthState(isLoading: false, error: failure.message);
        return false;
      },
    );
  }

  Future<bool> register(String email, String password, String nativeLanguage) async {
    state = state.copyWith(isLoading: true);
    final result = await _repository.register(email, password, nativeLanguage);

    return result.when(
      success: (user) {
        state = AuthState(user: user, isAuthenticated: true, isLoading: false);
        if (user.nativeLanguage.isNotEmpty && user.targetLanguages.isNotEmpty) {
          _languageNotifier.savePreferences(
            targetLanguage: user.targetLanguages.first,
            nativeLanguage: user.nativeLanguage,
          );
        } else {
          _languageNotifier.clearPreferences();
        }
        return true;
      },
      failure: (failure) {
        state = AuthState(isLoading: false, error: failure.message);
        return false;
      },
    );
  }

  Future<void> logout() async {
    await _repository.logout();
    await _languageNotifier.clearPreferences();
    state = const AuthState(isAuthenticated: false);
  }

  Future<bool> updateProfile({
    String? nativeLanguage,
    List<String>? targetLanguages,
  }) async {
    state = state.copyWith(isLoading: true);
    final result = await _repository.updateProfile(
      nativeLanguage: nativeLanguage,
      targetLanguages: targetLanguages,
    );

    return result.when(
      success: (user) {
        state = AuthState(user: user, isAuthenticated: true, isLoading: false);
        return true;
      },
      failure: (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
        return false;
      },
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(authRepositoryProvider),
    ref.read(languageProvider.notifier),
  );
});
