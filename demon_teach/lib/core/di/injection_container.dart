import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:demon_teach/core/constants/app_constants.dart';

/// Dependency Injection Container
/// 
/// This file contains all the providers for dependency injection
/// using Riverpod

// ============================================================================
// External Dependencies
// ============================================================================

/// Provides SharedPreferences instance
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be initialized in main()');
});

/// Provides FlutterSecureStorage instance
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );
});

/// Provides Dio HTTP client instance
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: AppConstants.apiTimeout,
      receiveTimeout: AppConstants.apiTimeout,
      sendTimeout: AppConstants.apiTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // Add interceptors
  dio.interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: true,
    error: true,
  ));

  // Add auth interceptor
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          final storage = ref.read(secureStorageProvider);
          final token = await storage.read(key: 'auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        } catch (e) {
          // Ignore storage errors on web
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Handle token refresh here
          // For now, just pass the error
          handler.next(error);
        } else {
          handler.next(error);
        }
      },
    ),
  );

  return dio;
});

// ============================================================================
// Data Sources
// ============================================================================

// TODO: Add data source providers here as they are implemented

// ============================================================================
// Repositories
// ============================================================================

// TODO: Add repository providers here as they are implemented

// ============================================================================
// Use Cases
// ============================================================================

// TODO: Add use case providers here as they are implemented
