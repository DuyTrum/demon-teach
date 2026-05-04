import 'package:dio/dio.dart';
import 'package:demon_teach/core/errors/failures.dart';
import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/user.dart';
import 'package:demon_teach/domain/repositories/auth_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthRepositoryImpl implements AuthRepository {
  final Dio _dio;
  final FlutterSecureStorage _storage;
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';

  AuthRepositoryImpl(this._dio, this._storage);

  @override
  Future<Result<User>> login(String email, String password) async {
    try {
      final response = await _dio.post('/api/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = response.data['data'];
        final token = data['accessToken'];
        final userData = data['user'];
        final user = User.fromJson(userData);

        await _storage.write(key: _tokenKey, value: token);
        // We'll add token to dio interceptor later
        
        return Result.success(user);
      }
      return Result.failure(const AuthFailure(message: 'Invalid credentials'));
    } on DioException catch (e) {
      print('DioException in login: ${e.message}');
      print('DioException response: ${e.response?.data}');
      String errorMsg = 'Login failed';
      if (e.response?.data is Map) {
        errorMsg = e.response?.data['message'] ?? errorMsg;
      }
      return Result.failure(AuthFailure(message: errorMsg));
    } catch (e) {
      print('General Exception in login: $e');
      return Result.failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> logout() async {
    await _storage.delete(key: _tokenKey);
    return Result.success(null);
  }

  @override
  Future<Result<User>> getCurrentUser() async {
    try {
      final response = await _dio.get('/api/auth/me');
      if (response.statusCode == 200) {
        return Result.success(User.fromJson(response.data['data']));
      }
      return Result.failure(const AuthFailure(message: 'Not authenticated'));
    } catch (e) {
      return Result.failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<User>> register(String email, String password, String nativeLanguage) async {
    try {
      final response = await _dio.post('/api/auth/register', data: {
        'email': email,
        'password': password,
        'nativeLanguage': nativeLanguage,
        'role': 'user', // Default role for mobile users
      });

      if (response.statusCode == 201) {
        return login(email, password);
      }
      return Result.failure(const AuthFailure(message: 'Registration failed'));
    } on DioException catch (e) {
      return Result.failure(AuthFailure(message: e.response?.data['message'] ?? 'Registration failed'));
    } catch (e) {
      return Result.failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await _storage.read(key: _tokenKey);
    return token != null;
  }

  @override
  Future<Result<void>> refreshToken() async {
    // Implement if backend supports refresh tokens
    return Result.success(null);
  }
}
