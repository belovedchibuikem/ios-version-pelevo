import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../exceptions/auth_exception.dart';
import 'storage_service.dart';

/// Simple auth service for token management
class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';

  final StorageService _storageService = StorageService();

  /// Get stored auth token
  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      debugPrint('❌ Error getting auth token: $e');
      return null;
    }
  }

  /// Store auth token
  Future<void> setToken(String token) async {
    try {
      // Store in both SharedPreferences and secure storage for consistency
      await Future.wait([
        _storageService.saveToken(token),
        _saveTokenToPreferences(token),
      ]);
      debugPrint('✅ Auth token stored successfully in both storage systems');
    } catch (e) {
      debugPrint('❌ Error storing auth token: $e');
      // Fallback to just SharedPreferences if secure storage fails
      try {
        await _saveTokenToPreferences(token);
        debugPrint(
            '⚠️ Auth token stored in SharedPreferences only (secure storage failed)');
      } catch (fallbackError) {
        debugPrint('❌ Fallback storage also failed: $fallbackError');
      }
    }
  }

  /// Helper method to save token to SharedPreferences
  Future<void> _saveTokenToPreferences(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Get stored refresh token
  Future<String?> getRefreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_refreshTokenKey);
    } catch (e) {
      debugPrint('❌ Error getting refresh token: $e');
      return null;
    }
  }

  /// Store refresh token
  Future<void> setRefreshToken(String refreshToken) async {
    try {
      // Store in both secure storage and SharedPreferences for consistency
      await Future.wait([
        _storageService.saveTokenExpiry(refreshToken),
        _saveRefreshTokenToPreferences(refreshToken),
      ]);
      debugPrint('✅ Refresh token stored successfully in both storage systems');
    } catch (e) {
      debugPrint('❌ Error storing refresh token: $e');
      // Fallback to just SharedPreferences if secure storage fails
      try {
        await _saveRefreshTokenToPreferences(refreshToken);
        debugPrint(
            '⚠️ Refresh token stored in SharedPreferences only (secure storage failed)');
      } catch (fallbackError) {
        debugPrint('❌ Fallback storage also failed: $fallbackError');
      }
    }
  }

  /// Helper method to save refresh token to SharedPreferences
  Future<void> _saveRefreshTokenToPreferences(String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_refreshTokenKey, refreshToken);
  }

  /// Get stored user ID
  Future<String?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userIdKey);
    } catch (e) {
      debugPrint('❌ Error getting user ID: $e');
      return null;
    }
  }

  /// Store user ID
  Future<void> setUserId(String userId) async {
    try {
      // Store in both secure storage and SharedPreferences for consistency
      await Future.wait([
        _storageService.saveUserData({'id': userId}),
        _saveUserIdToPreferences(userId),
      ]);
      debugPrint('✅ User ID stored successfully in both storage systems');
    } catch (e) {
      debugPrint('❌ Error storing user ID: $e');
      // Fallback to just SharedPreferences if secure storage fails
      try {
        await _saveUserIdToPreferences(userId);
        debugPrint(
            '⚠️ User ID stored in SharedPreferences only (secure storage failed)');
      } catch (fallbackError) {
        debugPrint('❌ Fallback storage also failed: $fallbackError');
      }
    }
  }

  /// Helper method to save user ID to SharedPreferences
  Future<void> _saveUserIdToPreferences(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
  }

  /// Get stored user email
  Future<String?> getUserEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userEmailKey);
    } catch (e) {
      debugPrint('❌ Error getting user email: $e');
      return null;
    }
  }

  /// Store user email
  Future<void> setUserEmail(String email) async {
    try {
      // Store in both secure storage and SharedPreferences for consistency
      await Future.wait([
        _storageService.saveUserData({'email': email}),
        _saveUserEmailToPreferences(email),
      ]);
      debugPrint('✅ User email stored successfully in both storage systems');
    } catch (e) {
      debugPrint('❌ Error storing user email: $e');
      // Fallback to just SharedPreferences if secure storage fails
      try {
        await _saveUserEmailToPreferences(email);
        debugPrint(
            '⚠️ User email stored in SharedPreferences only (secure storage failed)');
      } catch (fallbackError) {
        debugPrint('❌ Fallback storage also failed: $fallbackError');
      }
    }
  }

  /// Helper method to save user email to SharedPreferences
  Future<void> _saveUserEmailToPreferences(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userEmailKey, email);
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Resend verification email
  Future<void> resendVerificationEmail(String email) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/email/resend-by-email'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        debugPrint('✅ Verification email resent successfully');
      } else {
        final errorMessage =
            responseData['message'] ?? 'Failed to resend verification email';
        debugPrint('❌ Error resending verification email: $errorMessage');
        throw ServerException(errorMessage);
      }
    } catch (e) {
      debugPrint('❌ Error resending verification email: $e');
      if (e is ServerException) {
        rethrow;
      } else if (e is SocketException || e is TimeoutException) {
        throw NetworkException();
      } else {
        throw ServerException(
            'An unexpected error occurred. Please try again.');
      }
    }
  }

  /// Clear all auth data
  Future<void> clearAuthData() async {
    try {
      // Clear from both storage systems for consistency
      await Future.wait([
        _storageService.clearAll(),
        _clearPreferencesData(),
      ]);
      debugPrint('✅ Auth data cleared successfully from both storage systems');
    } catch (e) {
      debugPrint('❌ Error clearing auth data: $e');
      // Fallback to just clearing SharedPreferences if secure storage fails
      try {
        await _clearPreferencesData();
        debugPrint(
            '⚠️ Auth data cleared from SharedPreferences only (secure storage failed)');
      } catch (fallbackError) {
        debugPrint('❌ Fallback clearing also failed: $fallbackError');
      }
    }
  }

  /// Helper method to clear data from SharedPreferences
  Future<void> _clearPreferencesData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userEmailKey);
  }

  /// Clear any existing mock tokens and ensure clean state
  Future<void> clearMockTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);

      // Check if current token is a mock token
      if (token != null && token.startsWith('mock_token_')) {
        debugPrint('🧹 Clearing mock token: ${token.substring(0, 20)}...');
        await clearAuthData();
        debugPrint('✅ Mock tokens cleared');
      }
    } catch (e) {
      debugPrint('❌ Error clearing mock tokens: $e');
    }
  }

  /// Store user credentials
  Future<void> storeUserCredentials({
    required String token,
    required String refreshToken,
    required String userId,
    required String email,
  }) async {
    try {
      await Future.wait([
        setToken(token),
        setRefreshToken(refreshToken),
        setUserId(userId),
        setUserEmail(email),
      ]);
      debugPrint('✅ User credentials stored successfully');
    } catch (e) {
      debugPrint('❌ Error storing user credentials: $e');
    }
  }

  /// Login user with email and password
  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      // Use proper API URL construction
      final loginUrl = ApiConfig.getApiUrl('login');
      debugPrint('🔐 Login: Attempting to authenticate at: $loginUrl');

      // Make actual API call to backend
      final response = await http.post(
        Uri.parse(loginUrl),
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      debugPrint('🔐 Login: Response status: ${response.statusCode}');
      debugPrint('🔐 Login: Response headers: ${response.headers}');
      debugPrint(
          '🔐 Login: Response body preview: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}...');

      if (response.statusCode == 200) {
        // Check if response is JSON
        final contentType = response.headers['content-type'];
        if (contentType == null || !contentType.contains('application/json')) {
          debugPrint(
              '⚠️ Login: Response is not JSON, content-type: $contentType');
          throw ServerException(
              'Invalid response format from server. Expected JSON but got: $contentType');
        }

        try {
          final responseData = jsonDecode(response.body);
          debugPrint('🔐 Login: Parsed response data: $responseData');

          if (responseData['success'] == true && responseData['data'] != null) {
            final authData = responseData['data'];

            // Store real credentials from backend
            await storeUserCredentials(
              token: authData['token'],
              refreshToken: authData['refreshToken'] ?? '',
              userId: authData['user']['id'].toString(),
              email: authData['user']['email'],
            );

            debugPrint('✅ Login successful with real token');
          } else {
            throw ServerException(responseData['message'] ?? 'Login failed');
          }
        } catch (jsonError) {
          debugPrint('❌ Login: JSON parsing error: $jsonError');
          debugPrint('❌ Login: Raw response body: ${response.body}');
          throw ServerException(
              'Invalid JSON response from server: $jsonError');
        }
      } else {
        debugPrint('❌ Login: HTTP error status: ${response.statusCode}');

        // Try to parse error response as JSON
        try {
          final errorData = jsonDecode(response.body);
          final message = errorData['message'] ?? 'Login failed';

          // Handle specific error cases with user-friendly messages
          if (response.statusCode == 401) {
            throw ServerException(
                'Invalid email or password. Please check your credentials and try again.');
          } else if (response.statusCode == 403) {
            if (message.contains('Email address is not verified')) {
              throw ServerException(
                  'Please verify your email address before logging in. Check your inbox for a verification link.');
            } else if (message.contains('Account is deactivated')) {
              throw ServerException(
                  'Your account has been deactivated. Please contact support for assistance.');
            }
            throw ServerException(
                'Access denied. Please contact support if you believe this is an error.');
          } else if (response.statusCode == 422) {
            // Handle validation errors
            if (errorData['errors'] != null) {
              final errors = errorData['errors'] as Map<String, dynamic>;
              if (errors.containsKey('validation_errors')) {
                final validationErrors =
                    errors['validation_errors'] as Map<String, dynamic>;
                if (validationErrors.containsKey('email')) {
                  throw ServerException('Please enter a valid email address.');
                } else if (validationErrors.containsKey('password')) {
                  throw ServerException('Please enter a valid password.');
                }
              }
            }
            throw ServerException('Please check your input and try again.');
          } else if (response.statusCode == 429) {
            final retryAfter = errorData['errors']?['retry_after'] ?? 60;
            throw ServerException(
                'Too many login attempts. Please wait ${retryAfter} seconds before trying again.');
          }

          throw ServerException(message);
        } catch (jsonError) {
          // If error response is not JSON, provide a generic error
          debugPrint('❌ Login: Error response is not JSON: ${response.body}');
          if (response.statusCode == 401) {
            throw ServerException(
                'Invalid email or password. Please check your credentials and try again.');
          } else if (response.statusCode == 403) {
            throw ServerException(
                'Access denied. Please contact support if you believe this is an error.');
          } else if (response.statusCode == 429) {
            throw ServerException(
                'Too many login attempts. Please wait a few minutes before trying again.');
          }
          throw ServerException('Login failed. Please try again later.');
        }
      }
    } catch (e) {
      debugPrint('❌ Login error: $e');
      rethrow;
    }
  }

  /// Register new user
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      // Use proper API URL construction
      final registerUrl = ApiConfig.getApiUrl('register');
      debugPrint('🔐 Register: Attempting to register at: $registerUrl');

      // Make actual API call to backend
      final response = await http.post(
        Uri.parse(registerUrl),
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      );

      debugPrint('🔐 Register: Response status: ${response.statusCode}');
      debugPrint('🔐 Register: Response headers: ${response.headers}');
      debugPrint(
          '🔐 Register: Response body preview: ${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}...');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Check if response is JSON
        final contentType = response.headers['content-type'];
        if (contentType == null || !contentType.contains('application/json')) {
          debugPrint(
              '⚠️ Register: Response is not JSON, content-type: $contentType');
          throw ServerException(
              'Invalid response format from server. Expected JSON but got: $contentType');
        }

        try {
          final responseData = jsonDecode(response.body);
          debugPrint('🔐 Register: Parsed response data: $responseData');

          if (responseData['success'] == true && responseData['data'] != null) {
            final authData = responseData['data'];

            // Store real credentials from backend
            await storeUserCredentials(
              token: authData['token'],
              refreshToken: authData['refreshToken'] ?? '',
              userId: authData['user']['id'].toString(),
              email: authData['user']['email'],
            );

            debugPrint('✅ Registration successful with real token');
            return {'success': true, 'message': 'User registered successfully'};
          } else {
            throw ServerException(
                responseData['message'] ?? 'Registration failed');
          }
        } catch (jsonError) {
          debugPrint('❌ Register: JSON parsing error: $jsonError');
          debugPrint('❌ Register: Raw response body: ${response.body}');
          throw ServerException(
              'Invalid JSON response from server: $jsonError');
        }
      } else {
        debugPrint('❌ Register: HTTP error status: ${response.statusCode}');

        // Try to parse error response as JSON
        try {
          final errorData = jsonDecode(response.body);
          final message = errorData['message'] ?? 'Registration failed';

          // Handle specific error cases with user-friendly messages
          if (response.statusCode == 422) {
            // Handle validation errors
            if (errorData['errors'] != null) {
              final errors = errorData['errors'] as Map<String, dynamic>;
              if (errors.containsKey('validation_errors')) {
                final validationErrors =
                    errors['validation_errors'] as Map<String, dynamic>;
                if (validationErrors.containsKey('name')) {
                  throw ServerException(
                      'Please enter a valid name (letters and spaces only).');
                } else if (validationErrors.containsKey('email')) {
                  if (validationErrors['email'][0].contains('unique')) {
                    throw ServerException(
                        'An account with this email address already exists. Please use a different email or try logging in.');
                  }
                  throw ServerException('Please enter a valid email address.');
                } else if (validationErrors.containsKey('password')) {
                  throw ServerException(
                      'Password must be at least 8 characters long.');
                } else if (validationErrors
                    .containsKey('password_confirmation')) {
                  throw ServerException(
                      'Password confirmation does not match. Please make sure both passwords are identical.');
                }
              } else if (errors.containsKey('password_requirements')) {
                final requirements = errors['password_requirements'] as List;
                throw ServerException(
                    'Password requirements not met: ${requirements.join(', ')}');
              } else if (errors.containsKey('field')) {
                final field = errors['field'];
                if (field == 'email') {
                  throw ServerException('Please enter a valid email address.');
                }
              }
            }
            throw ServerException('Please check your input and try again.');
          } else if (response.statusCode == 429) {
            final retryAfter = errorData['errors']?['retry_after'] ?? 60;
            throw ServerException(
                'Too many registration attempts. Please wait ${retryAfter} seconds before trying again.');
          }

          throw ServerException(message);
        } catch (jsonError) {
          // If error response is not JSON, provide a generic error
          debugPrint(
              '❌ Register: Error response is not JSON: ${response.body}');
          if (response.statusCode == 422) {
            throw ServerException('Please check your input and try again.');
          } else if (response.statusCode == 429) {
            throw ServerException(
                'Too many registration attempts. Please wait a few minutes before trying again.');
          }
          throw ServerException('Registration failed. Please try again later.');
        }
      }
    } catch (e) {
      debugPrint('❌ Registration error: $e');
      rethrow;
    }
  }

  /// Send password reset email
  Future<void> forgotPassword({required String email}) async {
    // TODO: Implement actual API call to backend
    // For now, just simulate the process
    debugPrint('Password reset requested for: $email');
    await Future.delayed(const Duration(seconds: 1)); // Simulate API call
  }

  /// Reset password with token
  Future<void> resetPassword({
    required String token,
    required String email,
    required String password,
  }) async {
    // TODO: Implement actual API call to backend
    // For now, just simulate the process
    debugPrint('Password reset for: $email with token: $token');
    await Future.delayed(const Duration(seconds: 1)); // Simulate API call
  }
}
