import 'package:flutter/foundation.dart';
import 'auth_service.dart';
import 'storage_service.dart';

/// Unified authentication service that bridges both AuthService and StorageService
/// This ensures all API calls use the same authentication token regardless of which
/// service the calling code uses.
class UnifiedAuthService {
  static final UnifiedAuthService _instance = UnifiedAuthService._internal();
  factory UnifiedAuthService() => _instance;
  UnifiedAuthService._internal();

  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();

  String? _cachedToken;
  DateTime? _lastTokenCheck;

  /// Get the current authentication token
  /// This method checks both storage systems and returns the most recent token
  Future<String?> getToken() async {
    try {
      // Check if we have a cached token that's still valid
      if (_cachedToken != null && _lastTokenCheck != null) {
        final timeSinceLastCheck = DateTime.now().difference(_lastTokenCheck!);
        // Cache token for 5 minutes to avoid excessive storage calls
        if (timeSinceLastCheck.inMinutes < 5) {
          return _cachedToken;
        }
      }

      // Try to get token from secure storage first (preferred)
      String? token = await _storageService.getToken();

      if (token != null && token.isNotEmpty) {
        // Validate that this is not a mock token
        if (token.startsWith('mock_token_')) {
          debugPrint('⚠️ UnifiedAuthService: Found mock token, clearing it');
          await _storageService.clearAll();
          token = null;
        } else {
          debugPrint(
              '🔐 UnifiedAuthService: Token retrieved from secure storage');
          _cachedToken = token;
          _lastTokenCheck = DateTime.now();
          return token;
        }
      }

      // Fallback to regular storage if secure storage is empty
      token = await _authService.getToken();
      if (token != null && token.isNotEmpty) {
        // Validate that this is not a mock token
        if (token.startsWith('mock_token_')) {
          debugPrint(
              '⚠️ UnifiedAuthService: Found mock token in regular storage, clearing it');
          await _authService.clearMockTokens();
          token = null;
        } else {
          debugPrint(
              '🔐 UnifiedAuthService: Token retrieved from regular storage');
          // Migrate token to secure storage
          await _storageService.saveToken(token);
          _cachedToken = token;
          _lastTokenCheck = DateTime.now();
          return token;
        }
      }

      debugPrint('🔐 UnifiedAuthService: No token found in either storage');
      _cachedToken = null;
      _lastTokenCheck = DateTime.now();
      return null;
    } catch (e) {
      debugPrint('❌ UnifiedAuthService: Error getting token: $e');
      return null;
    }
  }

  /// Store authentication token in both storage systems for compatibility
  Future<void> setToken(String token) async {
    try {
      debugPrint(
          '🔐 UnifiedAuthService: Storing token in both storage systems');

      // Store in both systems to ensure compatibility
      await Future.wait([
        _storageService.saveToken(token),
        _authService.setToken(token),
      ]);

      _cachedToken = token;
      _lastTokenCheck = DateTime.now();

      debugPrint(
          '✅ UnifiedAuthService: Token stored successfully in both systems');
    } catch (e) {
      debugPrint('❌ UnifiedAuthService: Error storing token: $e');
      rethrow;
    }
  }

  /// Clear authentication data from both storage systems
  Future<void> clearAuthData() async {
    try {
      debugPrint(
          '🔐 UnifiedAuthService: Clearing auth data from both storage systems');

      // Clear from both systems
      await Future.wait([
        _storageService.clearAll(),
        _authService.clearAuthData(),
      ]);

      _cachedToken = null;
      _lastTokenCheck = null;

      debugPrint('✅ UnifiedAuthService: Auth data cleared successfully');
    } catch (e) {
      debugPrint('❌ UnifiedAuthService: Error clearing auth data: $e');
      rethrow;
    }
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    try {
      final token = await getToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      debugPrint('❌ UnifiedAuthService: Error checking authentication: $e');
      return false;
    }
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    try {
      // Try secure storage first
      String? refreshToken = await _storageService.getTokenExpiry();
      if (refreshToken != null) {
        return refreshToken;
      }

      // Fallback to regular storage
      return await _authService.getRefreshToken();
    } catch (e) {
      debugPrint('❌ UnifiedAuthService: Error getting refresh token: $e');
      return null;
    }
  }

  /// Store refresh token
  Future<void> setRefreshToken(String refreshToken) async {
    try {
      await Future.wait([
        _storageService.saveTokenExpiry(refreshToken),
        _authService.setRefreshToken(refreshToken),
      ]);
    } catch (e) {
      debugPrint('❌ UnifiedAuthService: Error storing refresh token: $e');
      rethrow;
    }
  }

  /// Get user ID
  Future<String?> getUserId() async {
    try {
      // Try secure storage first
      final userData = await _storageService.getUserData();
      if (userData != null && userData['id'] != null) {
        return userData['id'].toString();
      }

      // Fallback to regular storage
      return await _authService.getUserId();
    } catch (e) {
      debugPrint('❌ UnifiedAuthService: Error getting user ID: $e');
      return null;
    }
  }

  /// Store user ID
  Future<void> setUserId(String userId) async {
    try {
      await Future.wait([
        _authService.setUserId(userId),
        // For secure storage, we need to update the user data
        _storageService.saveUserData({'id': userId}),
      ]);
    } catch (e) {
      debugPrint('❌ UnifiedAuthService: Error storing user ID: $e');
      rethrow;
    }
  }

  /// Get user email
  Future<String?> getUserEmail() async {
    try {
      // Try secure storage first
      final userData = await _storageService.getUserData();
      if (userData != null && userData['email'] != null) {
        return userData['email'].toString();
      }

      // Fallback to regular storage
      return await _authService.getUserEmail();
    } catch (e) {
      debugPrint('❌ UnifiedAuthService: Error getting user email: $e');
      return null;
    }
  }

  /// Store user email
  Future<void> setUserEmail(String email) async {
    try {
      await Future.wait([
        _authService.setUserEmail(email),
        // For secure storage, we need to update the user data
        _storageService.saveUserData({'email': email}),
      ]);
    } catch (e) {
      debugPrint('❌ UnifiedAuthService: Error storing user email: $e');
      rethrow;
    }
  }

  /// Store user data
  Future<void> setUserData(Map<String, dynamic> userData) async {
    try {
      await _storageService.saveUserData(userData);
    } catch (e) {
      debugPrint('❌ UnifiedAuthService: Error storing user data: $e');
      rethrow;
    }
  }

  /// Get user data
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      return await _storageService.getUserData();
    } catch (e) {
      debugPrint('❌ UnifiedAuthService: Error getting user data: $e');
      return null;
    }
  }

  /// Invalidate cached token (force refresh on next getToken call)
  void invalidateCache() {
    _cachedToken = null;
    _lastTokenCheck = null;
    debugPrint('🔐 UnifiedAuthService: Token cache invalidated');
  }
}
