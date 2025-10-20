import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage player settings and preferences
class PlayerSettingsService {
  static final PlayerSettingsService _instance =
      PlayerSettingsService._internal();
  factory PlayerSettingsService() => _instance;
  PlayerSettingsService._internal();

  static const String _useEnhancedPlayerKey = 'use_enhanced_player';
  static const String _autoSwitchToEnhancedKey = 'auto_switch_to_enhanced';
  static const String _showBufferingIndicatorsKey = 'show_buffering_indicators';
  static const String _networkQualityMonitoringKey =
      'network_quality_monitoring';
  static const String _adaptiveBufferingKey = 'adaptive_buffering';
  static const String _autoPlayNextEpisodeKey = 'auto_play_next_episode';
  static const String _autoPlayOnAppLaunchKey = 'auto_play_on_app_launch';

  bool _useEnhancedPlayer = true;
  bool _autoSwitchToEnhanced = true;
  bool _showBufferingIndicators = true;
  bool _networkQualityMonitoring = true;
  bool _adaptiveBuffering = true;
  bool _autoPlayNextEpisode = true;
  bool _autoPlayOnAppLaunch = false;

  // Getters
  bool get useEnhancedPlayer => _useEnhancedPlayer;
  bool get autoSwitchToEnhanced => _autoSwitchToEnhanced;
  bool get showBufferingIndicators => _showBufferingIndicators;
  bool get networkQualityMonitoring => _networkQualityMonitoring;
  bool get adaptiveBuffering => _adaptiveBuffering;
  bool get autoPlayNextEpisode => _autoPlayNextEpisode;
  bool get autoPlayOnAppLaunch => _autoPlayOnAppLaunch;

  /// Initialize settings from storage
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _useEnhancedPlayer = prefs.getBool(_useEnhancedPlayerKey) ?? true;
      _autoSwitchToEnhanced = prefs.getBool(_autoSwitchToEnhancedKey) ?? true;
      _showBufferingIndicators =
          prefs.getBool(_showBufferingIndicatorsKey) ?? true;
      _networkQualityMonitoring =
          prefs.getBool(_networkQualityMonitoringKey) ?? true;
      _adaptiveBuffering = prefs.getBool(_adaptiveBufferingKey) ?? true;
      _autoPlayNextEpisode = prefs.getBool(_autoPlayNextEpisodeKey) ?? true;
      _autoPlayOnAppLaunch = prefs.getBool(_autoPlayOnAppLaunchKey) ?? false;

      debugPrint(
          'PlayerSettingsService: Loaded settings - Enhanced: $_useEnhancedPlayer');
    } catch (e) {
      debugPrint('PlayerSettingsService: Error loading settings: $e');
    }
  }

  /// Set enhanced player preference
  Future<void> setUseEnhancedPlayer(bool useEnhanced) async {
    _useEnhancedPlayer = useEnhanced;
    await _saveSetting(_useEnhancedPlayerKey, useEnhanced);
    debugPrint(
        'PlayerSettingsService: Enhanced player ${useEnhanced ? "enabled" : "disabled"}');
  }

  /// Set auto-switch preference
  Future<void> setAutoSwitchToEnhanced(bool autoSwitch) async {
    _autoSwitchToEnhanced = autoSwitch;
    await _saveSetting(_autoSwitchToEnhancedKey, autoSwitch);
  }

  /// Set buffering indicators preference
  Future<void> setShowBufferingIndicators(bool show) async {
    _showBufferingIndicators = show;
    await _saveSetting(_showBufferingIndicatorsKey, show);
  }

  /// Set network quality monitoring preference
  Future<void> setNetworkQualityMonitoring(bool enabled) async {
    _networkQualityMonitoring = enabled;
    await _saveSetting(_networkQualityMonitoringKey, enabled);
  }

  /// Set adaptive buffering preference
  Future<void> setAdaptiveBuffering(bool enabled) async {
    _adaptiveBuffering = enabled;
    await _saveSetting(_adaptiveBufferingKey, enabled);
  }

  /// Set auto-play next episode preference
  Future<void> setAutoPlayNextEpisode(bool enabled) async {
    _autoPlayNextEpisode = enabled;
    await _saveSetting(_autoPlayNextEpisodeKey, enabled);
  }

  /// Set auto-play on app launch preference
  Future<void> setAutoPlayOnAppLaunch(bool enabled) async {
    _autoPlayOnAppLaunch = enabled;
    await _saveSetting(_autoPlayOnAppLaunchKey, enabled);
  }

  /// Save a setting to storage
  Future<void> _saveSetting(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (e) {
      debugPrint('PlayerSettingsService: Error saving setting $key: $e');
    }
  }

  /// Get all settings as a map
  Map<String, dynamic> getAllSettings() {
    return {
      'useEnhancedPlayer': _useEnhancedPlayer,
      'autoSwitchToEnhanced': _autoSwitchToEnhanced,
      'showBufferingIndicators': _showBufferingIndicators,
      'networkQualityMonitoring': _networkQualityMonitoring,
      'adaptiveBuffering': _adaptiveBuffering,
      'autoPlayNextEpisode': _autoPlayNextEpisode,
      'autoPlayOnAppLaunch': _autoPlayOnAppLaunch,
    };
  }

  /// Reset all settings to defaults
  Future<void> resetToDefaults() async {
    _useEnhancedPlayer = false;
    _autoSwitchToEnhanced = true;
    _showBufferingIndicators = true;
    _networkQualityMonitoring = true;
    _adaptiveBuffering = true;

    await _saveSetting(_useEnhancedPlayerKey, _useEnhancedPlayer);
    await _saveSetting(_autoSwitchToEnhancedKey, _autoSwitchToEnhanced);
    await _saveSetting(_showBufferingIndicatorsKey, _showBufferingIndicators);
    await _saveSetting(_networkQualityMonitoringKey, _networkQualityMonitoring);
    await _saveSetting(_adaptiveBufferingKey, _adaptiveBuffering);

    debugPrint('PlayerSettingsService: Settings reset to defaults');
  }
}
