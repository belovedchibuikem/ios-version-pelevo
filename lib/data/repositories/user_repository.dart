// lib/data/repositories/user_repository.dart

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';

import '../models/user.dart';
import '../../core/config/api_config.dart';
import '../../core/services/unified_auth_service.dart';

class UserRepository {
  static final UserRepository _instance = UserRepository._internal();
  factory UserRepository() => _instance;

  final Dio _dio = Dio();

  User? _cachedUser;

  UserRepository._internal() {
    _dio.options = BaseOptions(
      baseUrl: ApiConfig.baseUrl + '/api',
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'Pelevo/1.0 (Android; +https://pelevo.app)',
        // Add 'Authorization': 'Bearer <token>' if needed
      },
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    );
  }

  Future<User?> getCurrentUser() async {
    try {
      final token = await UnifiedAuthService().getToken();
      final response = await _dio.get(
        '/profile',
        options: Options(headers: {
          'Authorization': 'Bearer $token',
        }),
      );
      if (response.statusCode == 200 && response.data != null) {
        _cachedUser = User.fromJson(response.data['data'] ?? response.data);
        return _cachedUser;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      rethrow;
    }
  }

  Future<bool> updateUserProfile(Map<String, dynamic> profileData) async {
    try {
      final token = await UnifiedAuthService().getToken();
      final response = await _dio.patch(
        '/profile',
        data: profileData,
        options: Options(headers: {
          'Authorization': 'Bearer $token',
        }),
      );
      if (response.statusCode == 200) {
        if (response.data != null) {
          _cachedUser = User.fromJson(response.data['data'] ?? response.data);
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      return false;
    }
  }

  Future<String?> uploadAvatar(String filePath) async {
    try {
      final token = await UnifiedAuthService().getToken();
      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(filePath),
      });
      final response = await _dio.post(
        '/profile/avatar',
        data: formData,
        options: Options(headers: {
          'Authorization': 'Bearer $token',
        }),
      );
      if (response.statusCode == 200 && response.data != null) {
        final url = response.data['data']['profile_image_url'] ??
            response.data['profile_image_url'];
        if (_cachedUser != null && url != null) {
          _cachedUser = User(
            id: _cachedUser!.id,
            email: _cachedUser!.email,
            name: _cachedUser!.name,
            profileImageUrl: url,
            balance: _cachedUser!.balance,
            subscribedCategories: _cachedUser!.subscribedCategories,
          );
        }
        return url;
      }
      return null;
    } catch (e) {
      debugPrint('Error uploading avatar: $e');
      return null;
    }
  }

  Future<bool> deleteAccount() async {
    try {
      final token = await UnifiedAuthService().getToken();
      final response = await _dio.delete(
        '/profile',
        options: Options(headers: {
          'Authorization': 'Bearer $token',
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error deleting account: $e');
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    // Mock login
    await Future.delayed(const Duration(milliseconds: 1000));
    return email.contains('@') && password.length >= 6;
  }

  Future<bool> register(String email, String password) async {
    // Mock registration
    await Future.delayed(const Duration(milliseconds: 1200));
    return email.contains('@') && password.length >= 6;
  }

  Future<bool> logout() async {
    try {
      final token = await UnifiedAuthService().getToken();
      if (token == null) {
        debugPrint('UserRepository: No token found for logout');
        return true; // Consider it successful if no token
      }

      final response = await _dio.post(
        '/logout',
        options: Options(headers: {
          'Authorization': 'Bearer $token',
        }),
      );

      if (response.statusCode == 200) {
        // Clear cached user data
        _cachedUser = null;
        debugPrint('UserRepository: Successfully logged out');
        return true;
      }

      debugPrint(
          'UserRepository: Logout failed with status ${response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('UserRepository: Error during logout: $e');
      // Clear cached user data even on error
      _cachedUser = null;
      return false;
    }
  }

  Future<double> getUserBalance() async {
    // Mock balance
    await Future.delayed(const Duration(milliseconds: 600));
    return 250.0;
  }
}
