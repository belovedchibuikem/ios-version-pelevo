import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../exceptions/auth_exception.dart';
import 'unified_auth_service.dart';
import 'package:flutter/foundation.dart';

class SocialAuthService {
  final String baseUrl = ApiConfig.baseUrl;
  final UnifiedAuthService _authService = UnifiedAuthService();

  Future<void> signInWithGoogle() async {
    try {
      debugPrint('🟢 GOOGLE SIGN-IN: Starting authentication...');

      // Call the backend Google OAuth endpoint
      final response = await http.get(
        Uri.parse('$baseUrl/api/auth/google'),
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint(
          '🟢 GOOGLE SIGN-IN: Backend response status: ${response.statusCode}');
      debugPrint('🟢 GOOGLE SIGN-IN: Backend response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          // Handle successful authentication
          final authData = responseData['data'];
          await _authService.setToken(authData['token']);
          await _authService.setUserData(authData['user']);

          // Save token expiry if provided
          if (authData['expires_at'] != null) {
            await _authService.setRefreshToken(authData['expires_at']);
            debugPrint(
                '🟢 GOOGLE SIGN-IN: Token expiry saved: ${authData['expires_at']}');
          }

          debugPrint('🟢 GOOGLE SIGN-IN: Authentication successful');
          debugPrint(
              '🟢 GOOGLE SIGN-IN: Token saved: ${authData['token'].substring(0, 10)}...');
        } else {
          throw ServerException(
              responseData['message'] ?? 'Google authentication failed');
        }
      } else {
        throw ServerException(
            'Google authentication failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('🔴 GOOGLE SIGN-IN ERROR: $e');
      rethrow;
    }
  }

  Future<void> signInWithApple() async {
    try {
      debugPrint('🟢 APPLE SIGN-IN: Starting authentication...');

      // Call the backend Apple OAuth endpoint
      final response = await http.get(
        Uri.parse('$baseUrl/api/auth/apple'),
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint(
          '🟢 APPLE SIGN-IN: Backend response status: ${response.statusCode}');
      debugPrint('🟢 APPLE SIGN-IN: Backend response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          // Handle successful authentication
          final authData = responseData['data'];
          await _authService.setToken(authData['token']);
          await _authService.setUserData(authData['user']);

          // Save token expiry if provided
          if (authData['expires_at'] != null) {
            await _authService.setRefreshToken(authData['expires_at']);
            debugPrint(
                '🟢 APPLE SIGN-IN: Token expiry saved: ${authData['expires_at']}');
          }

          debugPrint('🟢 APPLE SIGN-IN: Authentication successful');
          debugPrint(
              '🟢 APPLE SIGN-IN: Token saved: ${authData['token'].substring(0, 10)}...');
        } else {
          throw ServerException(
              responseData['message'] ?? 'Apple authentication failed');
        }
      } else {
        throw ServerException(
            'Apple authentication failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('🔴 APPLE SIGN-IN ERROR: $e');
      rethrow;
    }
  }

  Future<void> signInWithSpotify() async {
    try {
      debugPrint('🟢 SPOTIFY SIGN-IN: Starting authentication...');

      // Call the backend Spotify OAuth endpoint
      final response = await http.get(
        Uri.parse('$baseUrl/api/auth/spotify'),
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint(
          '🟢 SPOTIFY SIGN-IN: Backend response status: ${response.statusCode}');
      debugPrint('🟢 SPOTIFY SIGN-IN: Backend response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          // Handle successful authentication
          final authData = responseData['data'];
          await _authService.setToken(authData['token']);
          await _authService.setUserData(authData['user']);

          // Save token expiry if provided
          if (authData['expires_at'] != null) {
            await _authService.setRefreshToken(authData['expires_at']);
            debugPrint(
                '🟢 SPOTIFY SIGN-IN: Token expiry saved: ${authData['expires_at']}');
          }

          debugPrint('🟢 SPOTIFY SIGN-IN: Authentication successful');
          debugPrint(
              '🟢 SPOTIFY SIGN-IN: Token saved: ${authData['token'].substring(0, 10)}...');
        } else {
          throw ServerException(
              responseData['message'] ?? 'Spotify authentication failed');
        }
      } else {
        throw ServerException(
            'Spotify authentication failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('🔴 SPOTIFY SIGN-IN ERROR: $e');
      rethrow;
    }
  }
}
