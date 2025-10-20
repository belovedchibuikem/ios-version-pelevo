import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/local_storage_service.dart';

/// Data model for current playback state
class CurrentPlaybackState {
  final String episodeId;
  final int positionMs;
  final int durationMs;
  final bool isPlaying;
  final bool isPaused;
  final double playbackSpeed;
  final DateTime timestamp;
  final String? podcastId;

  CurrentPlaybackState({
    required this.episodeId,
    required this.positionMs,
    required this.durationMs,
    required this.isPlaying,
    required this.isPaused,
    required this.playbackSpeed,
    required this.timestamp,
    this.podcastId,
  });

  Map<String, dynamic> toJson() => {
        'episodeId': episodeId,
        'positionMs': positionMs,
        'durationMs': durationMs,
        'isPlaying': isPlaying,
        'isPaused': isPaused,
        'playbackSpeed': playbackSpeed,
        'timestamp': timestamp.toIso8601String(),
        'podcastId': podcastId,
      };

  factory CurrentPlaybackState.fromJson(Map<String, dynamic> json) {
    return CurrentPlaybackState(
      episodeId: json['episodeId'] ?? '',
      positionMs: json['positionMs'] ?? 0,
      durationMs: json['durationMs'] ?? 0,
      isPlaying: json['isPlaying'] ?? false,
      isPaused: json['isPaused'] ?? false,
      playbackSpeed: (json['playbackSpeed'] ?? 1.0).toDouble(),
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      podcastId: json['podcastId'],
    );
  }
}

/// Data model for episode queue state
class EpisodeQueueState {
  final List<String> episodeIds;
  final int currentIndex;
  final DateTime timestamp;

  EpisodeQueueState({
    required this.episodeIds,
    required this.currentIndex,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'episodeIds': episodeIds,
        'currentIndex': currentIndex,
        'timestamp': timestamp.toIso8601String(),
      };

  factory EpisodeQueueState.fromJson(Map<String, dynamic> json) {
    return EpisodeQueueState(
      episodeIds: List<String>.from(json['episodeIds'] ?? []),
      currentIndex: json['currentIndex'] ?? 0,
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    );
  }
}

/// Service responsible for persisting and restoring playback state
/// across app sessions and app lifecycle changes
class PlaybackPersistenceService {
  static const String _storageKey = 'current_playback_state';
  static const String _queueStorageKey = 'episode_queue_state';
  static const Duration _saveThrottle = Duration(seconds: 5);

  final LocalStorageService? _localStorage;
  DateTime? _lastSaveTime;

  PlaybackPersistenceService({LocalStorageService? localStorage})
      : _localStorage = localStorage;

  /// Save current playback state with throttling
  Future<bool> savePlaybackState({
    required String episodeId,
    required int positionMs,
    required int durationMs,
    required bool isPlaying,
    required bool isPaused,
    required double playbackSpeed,
    String? podcastId,
  }) async {
    try {
      // Throttle saves to avoid excessive writes
      final now = DateTime.now();
      if (_lastSaveTime != null &&
          now.difference(_lastSaveTime!) < _saveThrottle) {
        debugPrint('💾 PlaybackPersistenceService: Save throttled, skipping');
        return true;
      }

      final state = CurrentPlaybackState(
        episodeId: episodeId,
        positionMs: positionMs,
        durationMs: durationMs,
        isPlaying: isPlaying,
        isPaused: isPaused,
        playbackSpeed: playbackSpeed,
        timestamp: now,
        podcastId: podcastId,
      );

      // Save to SharedPreferences for immediate access
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(state.toJson()));

      // Also save to LocalStorageService if available
      if (_localStorage != null) {
        await _localStorage!
            .saveUserData(_storageKey, jsonEncode(state.toJson()));
      }

      _lastSaveTime = now;
      debugPrint('💾 PlaybackPersistenceService: State saved successfully');
      return true;
    } catch (e) {
      debugPrint('❌ PlaybackPersistenceService: Error saving state: $e');
      return false;
    }
  }

  /// Save episode queue state
  Future<bool> saveQueueState({
    required List<String> episodeIds,
    required int currentIndex,
  }) async {
    try {
      final state = EpisodeQueueState(
        episodeIds: episodeIds,
        currentIndex: currentIndex,
        timestamp: DateTime.now(),
      );

      // Save to SharedPreferences for immediate access
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_queueStorageKey, jsonEncode(state.toJson()));

      // Also save to LocalStorageService if available
      if (_localStorage != null) {
        await _localStorage!
            .saveUserData(_queueStorageKey, jsonEncode(state.toJson()));
      }

      debugPrint(
          '💾 PlaybackPersistenceService: Queue state saved successfully');
      return true;
    } catch (e) {
      debugPrint('❌ PlaybackPersistenceService: Error saving queue state: $e');
      return false;
    }
  }

  /// Load current playback state
  Future<CurrentPlaybackState?> loadPlaybackState() async {
    try {
      // Try SharedPreferences first for immediate access
      final prefs = await SharedPreferences.getInstance();
      final stateJson = prefs.getString(_storageKey);

      if (stateJson != null) {
        final state = CurrentPlaybackState.fromJson(jsonDecode(stateJson));

        // Check if state is stale (older than 30 days)
        if (DateTime.now().difference(state.timestamp).inDays > 30) {
          debugPrint('💾 PlaybackPersistenceService: State is stale, clearing');
          await clearPlaybackState();
          return null;
        }

        debugPrint(
            '💾 PlaybackPersistenceService: State loaded from SharedPreferences');
        return state;
      }

      // Fallback to LocalStorageService
      if (_localStorage != null) {
        final storedData = _localStorage!.getUserData(_storageKey);
        if (storedData != null) {
          final state = CurrentPlaybackState.fromJson(jsonDecode(storedData));

          // Check if state is stale
          if (DateTime.now().difference(state.timestamp).inDays > 30) {
            debugPrint(
                '💾 PlaybackPersistenceService: State is stale, clearing');
            await clearPlaybackState();
            return null;
          }

          debugPrint(
              '💾 PlaybackPersistenceService: State loaded from LocalStorage');
          return state;
        }
      }

      debugPrint('💾 PlaybackPersistenceService: No saved state found');
      return null;
    } catch (e) {
      debugPrint('❌ PlaybackPersistenceService: Error loading state: $e');
      return null;
    }
  }

  /// Load episode queue state
  Future<EpisodeQueueState?> loadQueueState() async {
    try {
      // Try SharedPreferences first
      final prefs = await SharedPreferences.getInstance();
      final stateJson = prefs.getString(_queueStorageKey);

      if (stateJson != null) {
        final state = EpisodeQueueState.fromJson(jsonDecode(stateJson));

        // Check if state is stale (older than 30 days)
        if (DateTime.now().difference(state.timestamp).inDays > 30) {
          debugPrint(
              '💾 PlaybackPersistenceService: Queue state is stale, clearing');
          await clearQueueState();
          return null;
        }

        debugPrint(
            '💾 PlaybackPersistenceService: Queue state loaded from SharedPreferences');
        return state;
      }

      // Fallback to LocalStorageService
      if (_localStorage != null) {
        final storedData = _localStorage!.getUserData(_queueStorageKey);
        if (storedData != null) {
          final state = EpisodeQueueState.fromJson(jsonDecode(storedData));

          // Check if state is stale
          if (DateTime.now().difference(state.timestamp).inDays > 30) {
            debugPrint(
                '💾 PlaybackPersistenceService: Queue state is stale, clearing');
            await clearQueueState();
            return null;
          }

          debugPrint(
              '💾 PlaybackPersistenceService: Queue state loaded from LocalStorage');
          return state;
        }
      }

      debugPrint('💾 PlaybackPersistenceService: No saved queue state found');
      return null;
    } catch (e) {
      debugPrint('❌ PlaybackPersistenceService: Error loading queue state: $e');
      return null;
    }
  }

  /// Clear all saved playback state
  Future<bool> clearPlaybackState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);

      if (_localStorage != null) {
        await _localStorage!.deleteUserData(_storageKey);
      }

      debugPrint('💾 PlaybackPersistenceService: Playback state cleared');
      return true;
    } catch (e) {
      debugPrint('❌ PlaybackPersistenceService: Error clearing state: $e');
      return false;
    }
  }

  /// Clear saved queue state
  Future<bool> clearQueueState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_queueStorageKey);

      if (_localStorage != null) {
        await _localStorage!.deleteUserData(_queueStorageKey);
      }

      debugPrint('💾 PlaybackPersistenceService: Queue state cleared');
      return true;
    } catch (e) {
      debugPrint(
          '❌ PlaybackPersistenceService: Error clearing queue state: $e');
      return false;
    }
  }

  /// Check if there's any saved playback state
  Future<bool> hasSavedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_storageKey);
    } catch (e) {
      debugPrint(
          '❌ PlaybackPersistenceService: Error checking saved state: $e');
      return false;
    }
  }

  /// Get the age of the saved state
  Future<Duration?> getStateAge() async {
    try {
      final state = await loadPlaybackState();
      if (state != null) {
        return DateTime.now().difference(state.timestamp);
      }
      return null;
    } catch (e) {
      debugPrint('❌ PlaybackPersistenceService: Error getting state age: $e');
      return null;
    }
  }
}
