import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Service for managing playback effects settings
class PlaybackEffectsService {
  static final PlaybackEffectsService _instance =
      PlaybackEffectsService._internal();
  factory PlaybackEffectsService() => _instance;
  PlaybackEffectsService._internal();

  late SharedPreferences _prefs;
  bool _isInitialized = false;

  // Default values
  static const double _defaultPlaybackSpeed = 1.0;
  static const bool _defaultTrimSilence = false;
  static const bool _defaultVolumeBoost = false;
  static const bool _defaultApplyToAllPodcasts = true;

  // Current settings
  double _playbackSpeed = _defaultPlaybackSpeed;
  bool _trimSilence = _defaultTrimSilence;
  bool _volumeBoost = _defaultVolumeBoost;
  bool _applyToAllPodcasts = _defaultApplyToAllPodcasts;

  // Getters
  double get playbackSpeed => _playbackSpeed;
  bool get trimSilence => _trimSilence;
  bool get volumeBoost => _volumeBoost;
  bool get applyToAllPodcasts => _applyToAllPodcasts;

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadSettings();
      _isInitialized = true;
      debugPrint('PlaybackEffectsService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing PlaybackEffectsService: $e');
      rethrow;
    }
  }

  /// Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    try {
      _playbackSpeed =
          _prefs.getDouble('playback_speed') ?? _defaultPlaybackSpeed;
      _trimSilence = _prefs.getBool('trim_silence') ?? _defaultTrimSilence;
      _volumeBoost = _prefs.getBool('volume_boost') ?? _defaultVolumeBoost;
      _applyToAllPodcasts =
          _prefs.getBool('apply_to_all_podcasts') ?? _defaultApplyToAllPodcasts;

      debugPrint('Playback effects settings loaded:');
      debugPrint('  Speed: $_playbackSpeed');
      debugPrint('  Trim Silence: $_trimSilence');
      debugPrint('  Volume Boost: $_volumeBoost');
      debugPrint('  Apply to All: $_applyToAllPodcasts');
    } catch (e) {
      debugPrint('Error loading playback effects settings: $e');
      // Use default values on error
    }
  }

  /// Save settings to SharedPreferences
  Future<void> _saveSettings() async {
    try {
      await _prefs.setDouble('playback_speed', _playbackSpeed);
      await _prefs.setBool('trim_silence', _trimSilence);
      await _prefs.setBool('volume_boost', _volumeBoost);
      await _prefs.setBool('apply_to_all_podcasts', _applyToAllPodcasts);

      debugPrint('Playback effects settings saved');
    } catch (e) {
      debugPrint('Error saving playback effects settings: $e');
    }
  }

  /// Set playback speed
  Future<void> setPlaybackSpeed(double speed) async {
    await initialize();

    // Validate and clamp speed between 0.5x and 3.0x
    if (speed < 0.5 || speed > 3.0) {
      debugPrint(
          'Warning: Playback speed $speed is out of range, clamping to valid range');
    }
    _playbackSpeed = speed.clamp(0.5, 3.0);

    // Save settings asynchronously to avoid blocking
    _saveSettings().catchError((e) {
      debugPrint('Error saving playback speed: $e');
    });

    debugPrint(
        '🎵 PlaybackEffectsService: Playback speed set to: $_playbackSpeed');
  }

  /// Set trim silence
  Future<void> setTrimSilence(bool enabled) async {
    await initialize();

    _trimSilence = enabled;

    // Save settings asynchronously to avoid blocking
    _saveSettings().catchError((e) {
      debugPrint('Error saving trim silence: $e');
    });

    debugPrint('🎵 PlaybackEffectsService: Trim silence set to: $_trimSilence');
  }

  /// Set volume boost
  Future<void> setVolumeBoost(bool enabled) async {
    await initialize();

    _volumeBoost = enabled;

    // Save settings asynchronously to avoid blocking
    _saveSettings().catchError((e) {
      debugPrint('Error saving volume boost: $e');
    });

    debugPrint('🎵 PlaybackEffectsService: Volume boost set to: $_volumeBoost');
  }

  /// Set apply to all podcasts
  Future<void> setApplyToAllPodcasts(bool enabled) async {
    await initialize();

    _applyToAllPodcasts = enabled;
    await _saveSettings();

    debugPrint('Apply to all podcasts set to: $_applyToAllPodcasts');
  }

  /// Get available playback speeds
  List<double> getAvailableSpeeds() {
    return [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 2.25, 2.5, 2.75, 3.0];
  }

  /// Get speed label
  String getSpeedLabel(double speed) {
    if (speed == 1.0) return 'Normal';
    return '${speed}x';
  }

  /// Reset all settings to default
  Future<void> resetToDefaults() async {
    await initialize();

    _playbackSpeed = _defaultPlaybackSpeed;
    _trimSilence = _defaultTrimSilence;
    _volumeBoost = _defaultVolumeBoost;
    _applyToAllPodcasts = _defaultApplyToAllPodcasts;

    await _saveSettings();

    debugPrint('Playback effects settings reset to defaults');
  }

  /// Get settings as map
  Map<String, dynamic> getSettings() {
    return {
      'playbackSpeed': _playbackSpeed,
      'trimSilence': _trimSilence,
      'volumeBoost': _volumeBoost,
      'applyToAllPodcasts': _applyToAllPodcasts,
    };
  }
}
