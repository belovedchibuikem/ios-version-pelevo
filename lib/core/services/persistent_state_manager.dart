import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages persistent state to prevent app auto-reload and maintain player state
class PersistentStateManager {
  static const String _playerStateKey = 'player_state';
  static const String _appSessionKey = 'app_session';
  static const String _lastCloseTimeKey = 'last_close_time';
  static const String _appVersionKey = 'app_version';

  static const String _currentAppVersion =
      '1.0.0'; // Update this when app changes

  static PersistentStateManager? _instance;
  static SharedPreferences? _prefs;

  factory PersistentStateManager() {
    _instance ??= PersistentStateManager._internal();
    return _instance!;
  }

  PersistentStateManager._internal();

  /// Initialize the persistent state manager
  Future<void> initialize() async {
    if (_prefs != null) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      debugPrint('✅ PersistentStateManager initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize PersistentStateManager: $e');
    }
  }

  /// Save player state (episode, position, queue, etc.)
  Future<void> savePlayerState(Map<String, dynamic> state) async {
    try {
      await initialize();
      if (_prefs == null) return;

      final stateJson = jsonEncode(state);
      await _prefs!.setString(_playerStateKey, stateJson);

      debugPrint(
          '💾 Player state saved: ${state['episode_title'] ?? 'Unknown'}');
    } catch (e) {
      debugPrint('❌ Failed to save player state: $e');
    }
  }

  /// Restore player state on app launch
  Future<Map<String, dynamic>?> restorePlayerState() async {
    try {
      await initialize();
      if (_prefs == null) return null;

      final stateJson = _prefs!.getString(_playerStateKey);
      if (stateJson == null) return null;

      final state = jsonDecode(stateJson) as Map<String, dynamic>;
      debugPrint(
          '🔄 Player state restored: ${state['episode_title'] ?? 'Unknown'}');

      return state;
    } catch (e) {
      debugPrint('❌ Failed to restore player state: $e');
      return null;
    }
  }

  /// Check if app was properly closed vs crashed
  Future<bool> wasAppProperlyClosed() async {
    try {
      await initialize();
      if (_prefs == null) return false;

      final lastCloseTime = _prefs!.getInt(_lastCloseTimeKey) ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;

      // If app was closed more than 5 minutes ago, consider it a fresh start
      if (currentTime - lastCloseTime > 5 * 60 * 1000) {
        debugPrint(
            '🔄 App was closed more than 5 minutes ago, treating as fresh start');
        return false;
      }

      // Check if app version changed
      final savedVersion = _prefs!.getString(_appVersionKey);
      if (savedVersion != _currentAppVersion) {
        debugPrint(
            '🔄 App version changed from $savedVersion to $_currentAppVersion, treating as fresh start');
        return false;
      }

      debugPrint('✅ App was properly closed, can restore state');
      return true;
    } catch (e) {
      debugPrint('❌ Error checking app close status: $e');
      return false;
    }
  }

  /// Mark app as properly closing
  Future<void> markAppProperlyClosing() async {
    try {
      await initialize();
      if (_prefs == null) return;

      final currentTime = DateTime.now().millisecondsSinceEpoch;
      await _prefs!.setInt(_lastCloseTimeKey, currentTime);
      await _prefs!.setString(_appVersionKey, _currentAppVersion);

      debugPrint('✅ App marked as properly closing');
    } catch (e) {
      debugPrint('❌ Failed to mark app as properly closing: $e');
    }
  }

  /// Clear saved player state
  Future<void> clearPlayerState() async {
    try {
      await initialize();
      if (_prefs == null) return;

      await _prefs!.remove(_playerStateKey);
      debugPrint('🗑️ Player state cleared');
    } catch (e) {
      debugPrint('❌ Failed to clear player state: $e');
    }
  }

  /// Get last saved player state timestamp
  Future<DateTime?> getLastStateTimestamp() async {
    try {
      await initialize();
      if (_prefs == null) return null;

      final timestamp = _prefs!.getInt(_lastCloseTimeKey);
      if (timestamp == null) return null;

      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } catch (e) {
      debugPrint('❌ Failed to get last state timestamp: $e');
      return null;
    }
  }

  /// Check if player state is stale (older than 24 hours)
  Future<bool> isPlayerStateStale() async {
    try {
      final timestamp = await getLastStateTimestamp();
      if (timestamp == null) return true;

      final now = DateTime.now();
      final difference = now.difference(timestamp);

      return difference.inHours > 24;
    } catch (e) {
      debugPrint('❌ Error checking if player state is stale: $e');
      return true;
    }
  }
}


