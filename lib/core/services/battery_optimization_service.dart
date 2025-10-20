import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service to handle battery optimization settings for background audio playback
class BatteryOptimizationService {
  static final BatteryOptimizationService _instance =
      BatteryOptimizationService._internal();
  factory BatteryOptimizationService() => _instance;
  BatteryOptimizationService._internal();

  /// Check if battery optimization is enabled for the app
  Future<bool> isBatteryOptimizationEnabled() async {
    try {
      if (Platform.isAndroid) {
        // For Android, check if the app is whitelisted from battery optimization
        return await Permission.ignoreBatteryOptimizations.isGranted;
      }
      return false; // iOS doesn't have battery optimization in the same way
    } catch (e) {
      debugPrint('❌ Error checking battery optimization status: $e');
      return false;
    }
  }

  /// Request to disable battery optimization for the app
  Future<bool> requestBatteryOptimizationDisabled() async {
    try {
      if (Platform.isAndroid) {
        debugPrint('🔋 Requesting battery optimization to be disabled...');

        // Request permission to ignore battery optimization
        final status = await Permission.ignoreBatteryOptimizations.request();

        if (status.isGranted) {
          debugPrint('✅ Battery optimization disabled successfully');
          return true;
        } else {
          debugPrint('❌ Battery optimization permission denied');
          return false;
        }
      }
      return true; // iOS doesn't need this
    } catch (e) {
      debugPrint('❌ Error requesting battery optimization disable: $e');
      return false;
    }
  }

  /// Open battery optimization settings for the user to manually disable
  Future<void> openBatteryOptimizationSettings() async {
    try {
      if (Platform.isAndroid) {
        debugPrint('🔋 Opening battery optimization settings...');
        await openAppSettings();
      }
    } catch (e) {
      debugPrint('❌ Error opening battery optimization settings: $e');
    }
  }

  /// Get a user-friendly message about battery optimization
  String getBatteryOptimizationMessage() {
    if (Platform.isAndroid) {
      return 'To ensure uninterrupted podcast playback when your screen is off, please disable battery optimization for this app in your device settings.';
    }
    return 'Background audio playback is supported on iOS.';
  }
}
