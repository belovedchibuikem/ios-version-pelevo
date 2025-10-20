import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'unified_auth_service.dart';
import 'comprehensive_cache_service.dart';

/// Service to handle session persistence and data retention during long idle periods
class SessionPersistenceService {
  static final SessionPersistenceService _instance =
      SessionPersistenceService._internal();
  factory SessionPersistenceService() => _instance;
  SessionPersistenceService._internal();

  final UnifiedAuthService _authService = UnifiedAuthService();
  final ComprehensiveCacheService _cacheService = ComprehensiveCacheService();

  // Keys for persistent storage
  static const String _lastActiveKey = 'last_active_timestamp';
  static const String _sessionValidKey = 'session_valid';
  static const String _dataRetentionKey = 'data_retention_enabled';

  // Timeout thresholds
  static const Duration _sessionTimeout =
      Duration(hours: 4); // Extended from 2 hours
  static const Duration _dataRetentionPeriod =
      Duration(hours: 24); // Keep data for 24 hours

  /// Check if session should be considered active
  Future<bool> isSessionActive() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastActive = prefs.getInt(_lastActiveKey);

      if (lastActive == null) {
        debugPrint('🔄 SESSION PERSISTENCE: No last active timestamp found');
        return false;
      }

      final lastActiveTime = DateTime.fromMillisecondsSinceEpoch(lastActive);
      final timeSinceLastActive = DateTime.now().difference(lastActiveTime);

      debugPrint(
          '🔄 SESSION PERSISTENCE: Time since last active: ${timeSinceLastActive.inHours}h ${timeSinceLastActive.inMinutes % 60}m');

      return timeSinceLastActive < _sessionTimeout;
    } catch (e) {
      debugPrint('❌ SESSION PERSISTENCE: Error checking session activity: $e');
      return false;
    }
  }

  /// Update last active timestamp
  Future<void> updateLastActive() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastActiveKey, DateTime.now().millisecondsSinceEpoch);
      debugPrint('🔄 SESSION PERSISTENCE: Updated last active timestamp');
    } catch (e) {
      debugPrint('❌ SESSION PERSISTENCE: Error updating last active: $e');
    }
  }

  /// Check if we should retain cached data
  Future<bool> shouldRetainData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataRetentionEnabled = prefs.getBool(_dataRetentionKey) ?? true;

      if (!dataRetentionEnabled) {
        debugPrint('🔄 SESSION PERSISTENCE: Data retention disabled');
        return false;
      }

      final lastActive = prefs.getInt(_lastActiveKey);
      if (lastActive == null) {
        debugPrint(
            '🔄 SESSION PERSISTENCE: No last active timestamp, retaining data');
        return true;
      }

      final lastActiveTime = DateTime.fromMillisecondsSinceEpoch(lastActive);
      final timeSinceLastActive = DateTime.now().difference(lastActiveTime);

      final shouldRetain = timeSinceLastActive < _dataRetentionPeriod;
      debugPrint(
          '🔄 SESSION PERSISTENCE: Should retain data: $shouldRetain (${timeSinceLastActive.inHours}h ago)');

      return shouldRetain;
    } catch (e) {
      debugPrint('❌ SESSION PERSISTENCE: Error checking data retention: $e');
      return true; // Default to retaining data on error
    }
  }

  /// Handle session restoration after long idle period
  Future<bool> restoreSessionAfterIdle() async {
    try {
      debugPrint(
          '🔄 SESSION PERSISTENCE: Attempting session restoration after idle period...');

      // Check if we should retain data
      final shouldRetain = await shouldRetainData();
      if (!shouldRetain) {
        debugPrint(
            '🔄 SESSION PERSISTENCE: Data retention period expired, clearing cache');
        await _cacheService.clear();
        return false;
      }

      // Try to restore session
      final token = await _authService.getToken();
      if (token == null) {
        debugPrint('🔄 SESSION PERSISTENCE: No token found, session invalid');
        return false;
      }

      // Check if session is still valid
      final isSessionValid = await _authService.isAuthenticated();
      if (isSessionValid) {
        debugPrint('🔄 SESSION PERSISTENCE: Session is still valid');
        await updateLastActive();
        return true;
      }

      // Try to refresh the session
      debugPrint(
          '🔄 SESSION PERSISTENCE: Session expired, attempting refresh...');
      try {
        // Check if session is still valid after a brief delay
        await Future.delayed(const Duration(milliseconds: 500));
        final isStillValid = await _authService.isAuthenticated();
        if (isStillValid) {
          debugPrint(
              '🔄 SESSION PERSISTENCE: Session is still valid after delay');
          await updateLastActive();
          return true;
        }
      } catch (refreshError) {
        debugPrint(
            '🔄 SESSION PERSISTENCE: Session refresh failed: $refreshError');
      }

      debugPrint('🔄 SESSION PERSISTENCE: Session restoration failed');
      return false;
    } catch (e) {
      debugPrint('❌ SESSION PERSISTENCE: Error in session restoration: $e');
      return false;
    }
  }

  /// Initialize session persistence
  Future<void> initialize() async {
    try {
      await updateLastActive();
      debugPrint('🔄 SESSION PERSISTENCE: Initialized session persistence');
    } catch (e) {
      debugPrint('❌ SESSION PERSISTENCE: Error initializing: $e');
    }
  }

  /// Clear session data
  Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastActiveKey);
      await prefs.remove(_sessionValidKey);
      debugPrint('🔄 SESSION PERSISTENCE: Cleared session data');
    } catch (e) {
      debugPrint('❌ SESSION PERSISTENCE: Error clearing session: $e');
    }
  }

  /// Enable/disable data retention
  Future<void> setDataRetention(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_dataRetentionKey, enabled);
      debugPrint(
          '🔄 SESSION PERSISTENCE: Data retention ${enabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      debugPrint('❌ SESSION PERSISTENCE: Error setting data retention: $e');
    }
  }

  /// Get session statistics
  Future<Map<String, dynamic>> getSessionStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastActive = prefs.getInt(_lastActiveKey);
      final dataRetentionEnabled = prefs.getBool(_dataRetentionKey) ?? true;

      DateTime? lastActiveTime;
      Duration? timeSinceLastActive;

      if (lastActive != null) {
        lastActiveTime = DateTime.fromMillisecondsSinceEpoch(lastActive);
        timeSinceLastActive = DateTime.now().difference(lastActiveTime);
      }

      return {
        'last_active': lastActiveTime?.toIso8601String(),
        'time_since_last_active': timeSinceLastActive?.inHours,
        'session_active': await isSessionActive(),
        'data_retention_enabled': dataRetentionEnabled,
        'should_retain_data': await shouldRetainData(),
      };
    } catch (e) {
      debugPrint('❌ SESSION PERSISTENCE: Error getting session stats: $e');
      return {};
    }
  }
}
