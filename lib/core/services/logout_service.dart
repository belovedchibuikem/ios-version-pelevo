import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'unified_auth_service.dart';
import '../../services/podcastindex_service.dart';

class LogoutService {
  static final LogoutService _instance = LogoutService._internal();
  factory LogoutService() => _instance;
  LogoutService._internal();

  final UnifiedAuthService _authService = UnifiedAuthService();

  /// Comprehensive logout with multiple security layers
  Future<LogoutResult> performLogout({
    bool forceLogout = false,
    String? reason,
  }) async {
    final startTime = DateTime.now();

    try {
      debugPrint(
          'LogoutService: Starting logout process${reason != null ? ' - Reason: $reason' : ''}');

      // Step 1: Attempt backend logout
      final backendResult = await _logoutFromBackend();

      // Step 2: Clear all local data (regardless of backend result)
      await _clearAllLocalData();

      // Step 3: Clear external service tokens
      await _clearExternalServiceTokens();

      // Step 4: Clear app cache and preferences
      await _clearAppCache();

      // Step 5: Log the logout event
      _logLogoutEvent(startTime, backendResult.success, reason);

      return LogoutResult(
        success: true,
        backendSuccess: backendResult.success,
        message: 'Successfully logged out',
        duration: DateTime.now().difference(startTime),
      );
    } catch (e) {
      debugPrint('LogoutService: Error during logout: $e');

      // Even on error, ensure local data is cleared for security
      try {
        await _clearAllLocalData();
        await _clearExternalServiceTokens();
        await _clearAppCache();
      } catch (clearError) {
        debugPrint('LogoutService: Error clearing data: $clearError');
      }

      return LogoutResult(
        success: false,
        backendSuccess: false,
        message: 'Logout completed with errors: ${e.toString()}',
        duration: DateTime.now().difference(startTime),
        error: e.toString(),
      );
    }
  }

  /// Logout from backend API
  Future<BackendLogoutResult> _logoutFromBackend() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        debugPrint('LogoutService: No token found, skipping backend logout');
        return BackendLogoutResult(success: true, message: 'No token found');
      }

      await _authService.clearAuthData();
      return BackendLogoutResult(
          success: true, message: 'Backend logout successful');
    } catch (e) {
      debugPrint('LogoutService: Backend logout failed: $e');
      return BackendLogoutResult(success: false, message: e.toString());
    }
  }

  /// Clear all local storage and cached data
  Future<void> _clearAllLocalData() async {
    try {
      // Clear all auth data from unified service
      await _authService.clearAuthData();

      debugPrint('LogoutService: Cleared all local storage');
    } catch (e) {
      debugPrint('LogoutService: Error clearing local storage: $e');
    }
  }

  /// Clear external service tokens
  Future<void> _clearExternalServiceTokens() async {
    try {
      // Clear PodcastIndex service token (no longer needed - authentication is automatic)
      try {
        debugPrint(
            'LogoutService: PodcastIndex authentication is now automatic - no manual clearing needed');
      } catch (e) {
        debugPrint('LogoutService: Error logging PodcastIndex auth status: $e');
      }

      // Clear any other external service tokens here
      // For example: Google, Facebook, Apple, etc.
    } catch (e) {
      debugPrint('LogoutService: Error clearing external tokens: $e');
    }
  }

  /// Clear app cache and preferences
  Future<void> _clearAppCache() async {
    try {
      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Clear any other cached data
      // This could include image cache, network cache, etc.

      debugPrint('LogoutService: Cleared app cache and preferences');
    } catch (e) {
      debugPrint('LogoutService: Error clearing app cache: $e');
    }
  }

  /// Log logout event for analytics/security
  void _logLogoutEvent(
      DateTime startTime, bool backendSuccess, String? reason) {
    final duration = DateTime.now().difference(startTime);

    debugPrint('LogoutService: Logout completed - '
        'Backend: ${backendSuccess ? 'Success' : 'Failed'}, '
        'Duration: ${duration.inMilliseconds}ms'
        '${reason != null ? ', Reason: $reason' : ''}');

    // Here you could send analytics events, security logs, etc.
  }

  /// Force logout without backend communication (for offline scenarios)
  Future<LogoutResult> forceLogout({String? reason}) async {
    final startTime = DateTime.now();

    try {
      debugPrint(
          'LogoutService: Performing force logout${reason != null ? ' - Reason: $reason' : ''}');

      await _clearAllLocalData();
      await _clearExternalServiceTokens();
      await _clearAppCache();

      _logLogoutEvent(startTime, false, reason);

      return LogoutResult(
        success: true,
        backendSuccess: false,
        message: 'Force logout completed',
        duration: DateTime.now().difference(startTime),
      );
    } catch (e) {
      debugPrint('LogoutService: Error during force logout: $e');
      return LogoutResult(
        success: false,
        backendSuccess: false,
        message: 'Force logout failed: ${e.toString()}',
        duration: DateTime.now().difference(startTime),
        error: e.toString(),
      );
    }
  }

  /// Check if user is currently logged in
  Future<bool> isLoggedIn() async {
    try {
      final token = await _authService.getToken();
      return token != null;
    } catch (e) {
      debugPrint('LogoutService: Error checking login status: $e');
      return false;
    }
  }
}

/// Result of logout operation
class LogoutResult {
  final bool success;
  final bool backendSuccess;
  final String message;
  final Duration duration;
  final String? error;

  LogoutResult({
    required this.success,
    required this.backendSuccess,
    required this.message,
    required this.duration,
    this.error,
  });

  @override
  String toString() {
    return 'LogoutResult(success: $success, backendSuccess: $backendSuccess, '
        'message: $message, duration: ${duration.inMilliseconds}ms, error: $error)';
  }
}

/// Result of backend logout operation
class BackendLogoutResult {
  final bool success;
  final String message;

  BackendLogoutResult({
    required this.success,
    required this.message,
  });
}
