import 'package:demon_teach/domain/entities/user.dart';
import 'package:demon_teach/domain/repositories/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:demon_teach/core/di/injection_container.dart';

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

  AuthNotifier(this._repository) : super(const AuthState()) {
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
    state = const AuthState(isAuthenticated: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
