import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demon_teach/core/errors/failures.dart';
import 'package:demon_teach/core/utils/result.dart';
import 'package:demon_teach/domain/entities/user.dart';
import 'package:demon_teach/domain/repositories/auth_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepositoryImpl implements AuthRepository {
  final Dio _dio;
  final FlutterSecureStorage _storage;
  final SharedPreferences _prefs;
  final fb_auth.FirebaseAuth _firebaseAuth = fb_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _tokenKey = 'auth_token';

  AuthRepositoryImpl(this._dio, this._storage, this._prefs);

  @override
  Future<Result<User>> login(String email, String password) async {
    try {
      // 1. Authenticate with Firebase
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final fbUser = userCredential.user;
      if (fbUser == null) {
        return Result.failure(const AuthFailure(message: 'Login failed - User is null'));
      }

      // 2. Fetch/update user doc in Firestore
      final userDoc = await _firestore.collection('users').doc(fbUser.uid).get();
      User user;
      
      if (userDoc.exists) {
        user = User.fromJson({
          'id': fbUser.uid,
          ...userDoc.data()!,
        });
      } else {
        // Create fallback if doc doesn't exist
        user = User(
          id: fbUser.uid,
          email: fbUser.email ?? email,
          nativeLanguage: 'vi',
          targetLanguages: const [],
          createdAt: DateTime.now(),
          lastActiveAt: DateTime.now(),
        );
        await _firestore.collection('users').doc(fbUser.uid).set(user.toJson());
      }

      // 3. Save Firebase ID Token and User ID
      final token = await fbUser.getIdToken();
      if (token != null) {
        await _storage.write(key: _tokenKey, value: token);
      }
      await _prefs.setString('current_user_id', user.id);

      return Result.success(user);
    } on fb_auth.FirebaseAuthException catch (e) {
      return Result.failure(AuthFailure(message: _mapFirebaseAuthException(e)));
    } catch (e) {
      return Result.failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await _firebaseAuth.signOut();
      await _storage.delete(key: _tokenKey);
      await _prefs.remove('current_user_id');
      return Result.success(null);
    } catch (e) {
      return Result.failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<User>> getCurrentUser() async {
    try {
      final fbUser = _firebaseAuth.currentUser;
      if (fbUser == null) {
        return Result.failure(const AuthFailure(message: 'Not authenticated'));
      }

      final userDoc = await _firestore.collection('users').doc(fbUser.uid).get();
      if (userDoc.exists) {
        final user = User.fromJson({
          'id': fbUser.uid,
          ...userDoc.data()!,
        });
        await _prefs.setString('current_user_id', user.id);
        
        // Refresh token in storage
        final token = await fbUser.getIdToken();
        if (token != null) {
          await _storage.write(key: _tokenKey, value: token);
        }
        
        return Result.success(user);
      }
      return Result.failure(const AuthFailure(message: 'User profile not found in Firestore'));
    } catch (e) {
      return Result.failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<User>> register(String email, String password, String nativeLanguage) async {
    try {
      // 1. Create user with Firebase Auth
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final fbUser = userCredential.user;
      if (fbUser == null) {
        return Result.failure(const AuthFailure(message: 'Registration failed - User is null'));
      }

      // 2. Save profile in Firestore
      final user = User(
        id: fbUser.uid,
        email: fbUser.email ?? email,
        nativeLanguage: nativeLanguage,
        targetLanguages: const [],
        createdAt: DateTime.now(),
        lastActiveAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(fbUser.uid).set(user.toJson());

      // 3. Save Firebase ID Token and User ID
      final token = await fbUser.getIdToken();
      if (token != null) {
        await _storage.write(key: _tokenKey, value: token);
      }
      await _prefs.setString('current_user_id', user.id);

      return Result.success(user);
    } on fb_auth.FirebaseAuthException catch (e) {
      return Result.failure(AuthFailure(message: _mapFirebaseAuthException(e)));
    } catch (e) {
      return Result.failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    return _firebaseAuth.currentUser != null;
  }

  @override
  Future<Result<void>> refreshToken() async {
    try {
      final fbUser = _firebaseAuth.currentUser;
      if (fbUser != null) {
        final token = await fbUser.getIdToken(true);
        if (token != null) {
          await _storage.write(key: _tokenKey, value: token);
        }
      }
      return Result.success(null);
    } catch (e) {
      return Result.failure(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<User>> updateProfile({
    String? nativeLanguage,
    List<String>? targetLanguages,
  }) async {
    try {
      final fbUser = _firebaseAuth.currentUser;
      if (fbUser == null) {
        return Result.failure(const AuthFailure(message: 'Not authenticated'));
      }

      final docRef = _firestore.collection('users').doc(fbUser.uid);
      final Map<String, dynamic> updates = {};
      if (nativeLanguage != null) updates['nativeLanguage'] = nativeLanguage;
      if (targetLanguages != null) updates['targetLanguages'] = targetLanguages;
      updates['lastActiveAt'] = DateTime.now().toIso8601String();

      await docRef.update(updates);

      final userDoc = await docRef.get();
      final user = User.fromJson({
        'id': fbUser.uid,
        ...userDoc.data()!,
      });

      return Result.success(user);
    } on fb_auth.FirebaseAuthException catch (e) {
      return Result.failure(AuthFailure(message: _mapFirebaseAuthException(e)));
    } catch (e) {
      return Result.failure(AuthFailure(message: e.toString()));
    }
  }

  String _mapFirebaseAuthException(fb_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Email này đã được đăng ký bởi tài khoản khác.';
      case 'invalid-email':
        return 'Địa chỉ email không hợp lệ.';
      case 'operation-not-allowed':
        return 'Hình thức đăng nhập này chưa được kích hoạt.';
      case 'weak-password':
        return 'Mật khẩu quá yếu, vui lòng chọn mật khẩu mạnh hơn.';
      case 'user-disabled':
        return 'Tài khoản này đã bị vô hiệu hóa.';
      case 'user-not-found':
        return 'Tài khoản không tồn tại trong hệ thống.';
      case 'wrong-password':
        return 'Mật khẩu không chính xác.';
      case 'invalid-credential':
        return 'Thông tin đăng nhập không chính xác.';
      default:
        return e.message ?? 'Đã xảy ra lỗi bảo mật.';
    }
  }
}
