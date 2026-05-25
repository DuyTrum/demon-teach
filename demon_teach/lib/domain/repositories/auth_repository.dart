import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/user.dart';

/// Authentication repository interface
abstract class AuthRepository {
  /// Login with email and password
  Future<Result<User>> login(String email, String password);

  /// Logout current user
  Future<Result<void>> logout();

  /// Get current authenticated user
  Future<Result<User>> getCurrentUser();

  /// Register new user
  Future<Result<User>> register(
      String email, String password, String nativeLanguage);

  /// Check if user is authenticated
  Future<bool> isAuthenticated();

  /// Refresh authentication token
  Future<Result<void>> refreshToken();

  /// Update user profile language preferences
  Future<Result<User>> updateProfile({
    String? nativeLanguage,
    List<String>? targetLanguages,
  });
}
