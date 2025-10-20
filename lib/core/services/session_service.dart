import 'package:flutter/foundation.dart';
import 'unified_auth_service.dart';
import '../routes/app_routes.dart';
import '../first_launch_service.dart';

class SessionService {
  final UnifiedAuthService _authService = UnifiedAuthService();

  /// Check if user has a valid session and automatically log them in
  Future<bool> checkAndRestoreSession() async {
    try {
      debugPrint('🔐 SESSION SERVICE: Checking for existing session...');

      // First, check if we have a token at all
      final token = await _authService.getToken();
      if (token == null) {
        debugPrint('🔐 SESSION SERVICE: No token found, session invalid');
        return false;
      }

      debugPrint('🔐 SESSION SERVICE: Token found, checking validity...');

      // Check if session is valid using available method
      final isSessionValid = await _authService.isAuthenticated();
      debugPrint(
          '🔐 SESSION SERVICE: Session validity check result: $isSessionValid');

      if (isSessionValid) {
        debugPrint(
            '🔐 SESSION SERVICE: Session restored successfully (local validation)');
        return true;
      }

      // If local validation fails, try to re-authenticate
      debugPrint(
          '🔐 SESSION SERVICE: Local validation failed, attempting re-authentication...');
      try {
        // Check if session is still valid after a brief delay
        await Future.delayed(const Duration(milliseconds: 500));
        final isStillValid = await _authService.isAuthenticated();
        if (isStillValid) {
          debugPrint('🔐 SESSION SERVICE: Session is still valid after delay');
          return true;
        }
      } catch (refreshError) {
        debugPrint(
            '🔐 SESSION SERVICE: Session re-authentication failed: $refreshError');
      }

      debugPrint('🔐 SESSION SERVICE: Session validation and refresh failed');
      return false;
    } catch (e) {
      debugPrint('🔐 SESSION SERVICE ERROR: $e');
      // Don't clear session on error, just return false
      return false;
    }
  }

  /// Get the initial route based on session status and first launch
  Future<String> getInitialRoute() async {
    try {
      // PRIORITIZE SESSION: If user has a valid session, go straight to home
      final hasValidSession = await checkAndRestoreSession();

      if (hasValidSession) {
        debugPrint(
            '🔐 SESSION SERVICE: User is authenticated, redirecting to home');
        return AppRoutes.homeScreen;
      } else {
        // No valid session, then evaluate first launch / onboarding
        final isFirstLaunch = await FirstLaunchService.isFirstLaunch();
        debugPrint('🔐 SESSION SERVICE: Is first launch: $isFirstLaunch');

        if (isFirstLaunch) {
          final isOnboardingCompleted =
              await FirstLaunchService.isOnboardingCompleted();
          final isOnboardingSkipped =
              await FirstLaunchService.isOnboardingSkipped();

          debugPrint(
              '🔐 SESSION SERVICE: Onboarding completed: $isOnboardingCompleted, skipped: $isOnboardingSkipped');

          if (!isOnboardingCompleted && !isOnboardingSkipped) {
            debugPrint('🔐 SESSION SERVICE: First launch - showing onboarding');
            return AppRoutes.onboardingFlow;
          }
        }

        debugPrint(
            '🔐 SESSION SERVICE: No session, redirecting to authentication');
        return AppRoutes.authenticationScreen;
      }
    } catch (e) {
      debugPrint('🔐 SESSION SERVICE ERROR: $e');
      // On error, default to authentication screen
      return AppRoutes.authenticationScreen;
    }
  }

  /// Clear session data
  Future<void> clearSession() async {
    try {
      await _authService.clearAuthData();
      debugPrint('🔐 SESSION SERVICE: Session cleared');
    } catch (e) {
      debugPrint('🔐 SESSION SERVICE ERROR: Failed to clear session: $e');
    }
  }
}
