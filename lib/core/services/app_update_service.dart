import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'notification_service.dart';

/// Service for checking and managing app updates
class AppUpdateService {
  static const String _lastUpdateCheckKey = 'last_update_check';
  static const String _updateCheckIntervalHours = 'update_check_interval';
  static const String _lastKnownVersionKey = 'last_known_version';

  final NotificationService _notificationService = NotificationService();

  /// Check for app updates
  Future<AppUpdateInfo?> checkForUpdates({bool forceCheck = false}) async {
    try {
      debugPrint('🔍 Checking for app updates...');

      // Check if we should skip this check
      if (!forceCheck && !await _shouldCheckForUpdates()) {
        debugPrint('⏭️ Skipping update check (too soon)');
        return null;
      }

      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final buildNumber = packageInfo.buildNumber;

      debugPrint('📱 Current version: $currentVersion ($buildNumber)');

      // Check with backend for latest version
      final updateInfo = await _fetchUpdateInfo();

      if (updateInfo != null) {
        final hasUpdate =
            _compareVersions(currentVersion, updateInfo.latestVersion);

        if (hasUpdate) {
          debugPrint('🆕 Update available: ${updateInfo.latestVersion}');

          // Store last check time
          await _updateLastCheckTime();

          // Show update notification if it's important or forced
          if (updateInfo.isCritical || forceCheck) {
            await _showUpdateNotification(updateInfo);
          }

          return updateInfo;
        } else {
          debugPrint('✅ App is up to date');
          await _updateLastCheckTime();
          return null;
        }
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error checking for updates: $e');
      return null;
    }
  }

  /// Check if we should perform an update check
  Future<bool> _shouldCheckForUpdates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCheck = prefs.getInt(_lastUpdateCheckKey);
      final interval =
          prefs.getInt(_updateCheckIntervalHours) ?? 24; // Default 24 hours

      if (lastCheck == null) return true;

      final now = DateTime.now().millisecondsSinceEpoch;
      final hoursSinceLastCheck = (now - lastCheck) / (1000 * 60 * 60);

      return hoursSinceLastCheck >= interval;
    } catch (e) {
      debugPrint('❌ Error checking update interval: $e');
      return true; // Default to checking if error
    }
  }

  /// Update the last check time
  Future<void> _updateLastCheckTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
          _lastUpdateCheckKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('❌ Error updating last check time: $e');
    }
  }

  /// Fetch update information from backend
  Future<AppUpdateInfo?> _fetchUpdateInfo() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/app/version-check'),
        headers: ApiConfig.defaultHeaders,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return AppUpdateInfo.fromJson(data['data']);
        }
      }

      debugPrint('⚠️ Failed to fetch update info: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('❌ Error fetching update info: $e');
      return null;
    }
  }

  /// Compare version strings to determine if update is needed
  bool _compareVersions(String current, String latest) {
    try {
      final currentParts = current.split('.').map(int.parse).toList();
      final latestParts = latest.split('.').map(int.parse).toList();

      // Ensure both lists have same length
      while (currentParts.length < latestParts.length) {
        currentParts.add(0);
      }
      while (latestParts.length < currentParts.length) {
        latestParts.add(0);
      }

      for (int i = 0; i < currentParts.length; i++) {
        if (latestParts[i] > currentParts[i]) {
          return true;
        } else if (latestParts[i] < currentParts[i]) {
          return false;
        }
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error comparing versions: $e');
      return false;
    }
  }

  /// Show update notification
  Future<void> _showUpdateNotification(AppUpdateInfo updateInfo) async {
    try {
      await _notificationService.showUpdateNotification(
        title: updateInfo.isCritical
            ? 'Critical Update Available'
            : 'App Update Available',
        body: updateInfo.message ?? 'A new version of Pelevo is available',
        updateInfo: updateInfo,
      );
    } catch (e) {
      debugPrint('❌ Error showing update notification: $e');
    }
  }

  /// Set update check interval
  Future<void> setUpdateCheckInterval(int hours) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_updateCheckIntervalHours, hours);
      debugPrint('✅ Update check interval set to $hours hours');
    } catch (e) {
      debugPrint('❌ Error setting update interval: $e');
    }
  }

  /// Get update check interval
  Future<int> getUpdateCheckInterval() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_updateCheckIntervalHours) ?? 24;
    } catch (e) {
      debugPrint('❌ Error getting update interval: $e');
      return 24;
    }
  }
}

/// App update information model
class AppUpdateInfo {
  final String latestVersion;
  final bool isCritical;
  final String? message;
  final String? downloadUrl;
  final List<String>? releaseNotes;
  final DateTime? releaseDate;

  AppUpdateInfo({
    required this.latestVersion,
    required this.isCritical,
    this.message,
    this.downloadUrl,
    this.releaseNotes,
    this.releaseDate,
  });

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    return AppUpdateInfo(
      latestVersion: json['latest_version'] ?? '',
      isCritical: json['is_critical'] ?? false,
      message: json['message'],
      downloadUrl: json['download_url'],
      releaseNotes: json['release_notes']?.cast<String>(),
      releaseDate: json['release_date'] != null
          ? DateTime.parse(json['release_date'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latest_version': latestVersion,
      'is_critical': isCritical,
      'message': message,
      'download_url': downloadUrl,
      'release_notes': releaseNotes,
      'release_date': releaseDate?.toIso8601String(),
    };
  }
}
