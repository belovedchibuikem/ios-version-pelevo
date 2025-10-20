// lib/services/thermal_optimization_service.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../services/audio_player_service.dart';
import 'smart_buffering_service.dart';
import '../core/services/local_storage_service.dart';

class ThermalOptimizationService {
  static final ThermalOptimizationService _instance =
      ThermalOptimizationService._internal();
  factory ThermalOptimizationService() => _instance;
  ThermalOptimizationService._internal();

  // Local storage service for persistence
  final LocalStorageService _localStorage = LocalStorageService();

  // Storage key for battery saving mode
  static const String _batterySavingModeKey = 'battery_saving_mode';

  // Thermal state tracking
  bool _isThermalThrottling = false;
  double _estimatedTemperature = 25.0; // Celsius
  Timer? _thermalMonitorTimer;

  // Optimization settings
  bool _reducedUpdateFrequency = false;
  bool _debugLoggingDisabled = false;
  bool _aggressiveBatterySaving =
      true; // Default to true for better battery optimization

  // Stream controllers
  final StreamController<bool> _thermalController =
      StreamController<bool>.broadcast();
  final StreamController<double> _temperatureController =
      StreamController<double>.broadcast();

  // Getters
  bool get isThermalThrottling => _isThermalThrottling;
  double get estimatedTemperature => _estimatedTemperature;
  bool get isOptimizedForBattery => _aggressiveBatterySaving;

  // Streams
  Stream<bool> get thermalThrottlingStream => _thermalController.stream;
  Stream<double> get temperatureStream => _temperatureController.stream;

  /// Initialize thermal optimization
  Future<void> initialize() async {
    try {
      // Load saved battery saving mode setting
      await _loadBatterySavingModeSetting();

      // Start thermal monitoring
      _startThermalMonitoring();

      // Apply initial optimizations
      await _applyThermalOptimizations();

      debugPrint('🌡️ ThermalOptimizationService initialized');
    } catch (e) {
      debugPrint('❌ Error initializing thermal optimization: $e');
    }
  }

  /// Start monitoring device thermal state
  void _startThermalMonitoring() {
    // Simulate thermal monitoring (in real implementation, use platform channels)
    _thermalMonitorTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _updateThermalState();
    });
  }

  /// Update thermal state based on playback activity
  void _updateThermalState() {
    final audioService = AudioPlayerService();
    final isPlaying = audioService.isPlaying;

    // Simulate temperature estimation based on activity
    if (isPlaying) {
      // Temperature increases during playback
      _estimatedTemperature += Random().nextDouble() * 2.0;
    } else {
      // Temperature decreases when idle
      _estimatedTemperature =
          max(25.0, _estimatedTemperature - Random().nextDouble() * 1.0);
    }

    // Check for thermal throttling threshold (simulated at 45°C)
    final wasThrottling = _isThermalThrottling;
    _isThermalThrottling = _estimatedTemperature > 45.0;

    if (_isThermalThrottling != wasThrottling) {
      _thermalController.add(_isThermalThrottling);
      _applyThermalOptimizations();
    }

    _temperatureController.add(_estimatedTemperature);

    if (_isThermalThrottling) {
      debugPrint(
          '🌡️ Thermal throttling active - Temperature: ${_estimatedTemperature.toStringAsFixed(1)}°C');
    }
  }

  /// Apply thermal optimizations based on current state
  Future<void> _applyThermalOptimizations() async {
    if (_isThermalThrottling || _aggressiveBatterySaving) {
      await _enableAggressiveOptimizations();
    } else {
      await _enableNormalOptimizations();
    }
  }

  /// Enable aggressive optimizations for thermal management
  Future<void> _enableAggressiveOptimizations() async {
    try {
      // Disable verbose debug logging
      _debugLoggingDisabled = true;
      final audioService = AudioPlayerService();
      audioService.setVerboseDebug(false);

      // Reduce update frequency
      _reducedUpdateFrequency = true;

      // Set conservative buffering strategy
      audioService.setBufferingStrategy(BufferingStrategy.conservative);

      debugPrint('🌡️ Aggressive thermal optimizations enabled');
    } catch (e) {
      debugPrint('❌ Error enabling aggressive optimizations: $e');
    }
  }

  /// Enable normal optimizations
  Future<void> _enableNormalOptimizations() async {
    try {
      // Re-enable debug logging if not manually disabled
      if (!_debugLoggingDisabled) {
        final audioService = AudioPlayerService();
        audioService.setVerboseDebug(true);
      }

      // Normal update frequency
      _reducedUpdateFrequency = false;

      debugPrint('🌡️ Normal optimizations restored');
    } catch (e) {
      debugPrint('❌ Error restoring normal optimizations: $e');
    }
  }

  /// Load battery saving mode setting from storage
  Future<void> _loadBatterySavingModeSetting() async {
    try {
      // Wait for local storage to be ready
      int attempts = 0;
      while (!_localStorage.canOperate && attempts < 10) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }

      if (_localStorage.canOperate) {
        final savedValue = _localStorage.getSetting(_batterySavingModeKey);
        if (savedValue != null) {
          _aggressiveBatterySaving = savedValue.toLowerCase() == 'true';
          debugPrint(
              '🔋 Loaded battery saving mode setting: $_aggressiveBatterySaving');
        } else {
          // Save default value on first run
          await _saveBatterySavingModeSetting(_aggressiveBatterySaving);
          debugPrint(
              '🔋 Battery saving mode setting not found, using default: $_aggressiveBatterySaving');
        }
      } else {
        debugPrint(
            '⚠️ Local storage not available, using default battery saving mode: $_aggressiveBatterySaving');
      }
    } catch (e) {
      debugPrint('❌ Error loading battery saving mode setting: $e');
    }
  }

  /// Save battery saving mode setting to storage
  Future<void> _saveBatterySavingModeSetting(bool enabled) async {
    try {
      if (_localStorage.canOperate) {
        await _localStorage.saveSetting(
            _batterySavingModeKey, enabled.toString());
        debugPrint('🔋 Saved battery saving mode setting: $enabled');
      } else {
        debugPrint(
            '⚠️ Local storage not available, cannot save battery saving mode setting');
      }
    } catch (e) {
      debugPrint('❌ Error saving battery saving mode setting: $e');
    }
  }

  /// Enable aggressive battery saving mode
  void enableBatterySavingMode(bool enabled) {
    _aggressiveBatterySaving = enabled;
    _applyThermalOptimizations();

    // Save the setting to storage
    _saveBatterySavingModeSetting(enabled);

    debugPrint('🔋 Battery saving mode ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Check if reduced update frequency is active
  bool shouldReduceUpdateFrequency() =>
      _reducedUpdateFrequency || _isThermalThrottling;

  /// Get optimal progress save interval based on thermal state
  Duration getOptimalProgressSaveInterval() {
    if (_isThermalThrottling) {
      return const Duration(seconds: 30); // Save less frequently
    } else if (_aggressiveBatterySaving) {
      return const Duration(seconds: 20);
    } else {
      return const Duration(seconds: 10); // Normal frequency
    }
  }

  /// Get optimal position update interval
  Duration getOptimalPositionUpdateInterval() {
    if (_isThermalThrottling) {
      return const Duration(seconds: 2); // Update less frequently
    } else if (_aggressiveBatterySaving) {
      return const Duration(seconds: 1);
    } else {
      return const Duration(milliseconds: 500); // Normal frequency
    }
  }

  /// Force thermal cooling (pause playback briefly)
  Future<void> forceThermalCooling() async {
    if (_isThermalThrottling) {
      debugPrint('🌡️ Forcing thermal cooling - pausing playback');

      final audioService = AudioPlayerService();
      await audioService.pause();

      // Wait for cooling
      await Future.delayed(const Duration(seconds: 5));

      // Resume playback
      await audioService.play();

      debugPrint('🌡️ Thermal cooling completed - playback resumed');
    }
  }

  /// Get thermal statistics
  Map<String, dynamic> getThermalStats() {
    return {
      'isThermalThrottling': _isThermalThrottling,
      'estimatedTemperature': _estimatedTemperature,
      'reducedUpdateFrequency': _reducedUpdateFrequency,
      'debugLoggingDisabled': _debugLoggingDisabled,
      'aggressiveBatterySaving': _aggressiveBatterySaving,
    };
  }

  /// Dispose resources
  Future<void> dispose() async {
    try {
      _thermalMonitorTimer?.cancel();
      await _thermalController.close();
      await _temperatureController.close();
      debugPrint('🌡️ ThermalOptimizationService disposed');
    } catch (e) {
      debugPrint('❌ Error disposing thermal optimization: $e');
    }
  }
}
