import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_update_service.dart';

/// Service for managing local notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    try {
      if (_isInitialized) return;

      debugPrint('🔔 Initializing notification service...');

      // Android initialization settings
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization settings
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Combined initialization settings
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Initialize the plugin
      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Request permissions
      await _requestPermissions();

      _isInitialized = true;
      debugPrint('✅ Notification service initialized');
    } catch (e) {
      debugPrint('❌ Error initializing notification service: $e');
    }
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    try {
      // For Android 13+
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      // For iOS
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    } catch (e) {
      debugPrint('❌ Error requesting notification permissions: $e');
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    try {
      debugPrint('🔔 Notification tapped: ${response.payload}');

      final payload = response.payload;
      if (payload != null && payload.startsWith('update:')) {
        // Handle update notification
        _handleUpdateNotificationTap(payload);
      }
    } catch (e) {
      debugPrint('❌ Error handling notification tap: $e');
    }
  }

  /// Handle update notification tap
  Future<void> _handleUpdateNotificationTap(String payload) async {
    try {
      // Extract update info from payload
      final updateInfoJson = payload.substring(7); // Remove 'update:' prefix
      final updateInfo = AppUpdateInfo.fromJson(
          Map<String, dynamic>.from(jsonDecode(updateInfoJson)));

      // Open app store or download URL
      await _openUpdateUrl(updateInfo);
    } catch (e) {
      debugPrint('❌ Error handling update notification tap: $e');
    }
  }

  /// Open update URL (App Store, Play Store, or direct download)
  Future<void> _openUpdateUrl(AppUpdateInfo updateInfo) async {
    try {
      String url = updateInfo.downloadUrl ?? _getDefaultStoreUrl();

      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
        debugPrint('✅ Opened update URL: $url');
      } else {
        debugPrint('❌ Cannot launch URL: $url');
      }
    } catch (e) {
      debugPrint('❌ Error opening update URL: $e');
    }
  }

  /// Get default store URL based on platform
  String _getDefaultStoreUrl() {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'https://apps.apple.com/app/pelevo/id[YOUR_APP_ID]';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'https://play.google.com/store/apps/details?id=com.pelevo.app';
    }
    return 'https://pelevo.com/download';
  }

  /// Show update notification
  Future<void> showUpdateNotification({
    required String title,
    required String body,
    required AppUpdateInfo updateInfo,
  }) async {
    try {
      await initialize();

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'app_updates',
        'App Updates',
        channelDescription: 'Notifications for app updates',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Create payload with update info
      final payload = 'update:${jsonEncode(updateInfo.toJson())}';

      await _notificationsPlugin.show(
        updateInfo.hashCode, // Use hash as notification ID
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      debugPrint('✅ Update notification shown');
    } catch (e) {
      debugPrint('❌ Error showing update notification: $e');
    }
  }

  /// Show general notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      await initialize();

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'general',
        'General Notifications',
        channelDescription: 'General app notifications',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      debugPrint('✅ Notification shown: $title');
    } catch (e) {
      debugPrint('❌ Error showing notification: $e');
    }
  }

  /// Cancel notification
  Future<void> cancelNotification(int id) async {
    try {
      await _notificationsPlugin.cancel(id);
      debugPrint('✅ Notification cancelled: $id');
    } catch (e) {
      debugPrint('❌ Error cancelling notification: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _notificationsPlugin.cancelAll();
      debugPrint('✅ All notifications cancelled');
    } catch (e) {
      debugPrint('❌ Error cancelling all notifications: $e');
    }
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _notificationsPlugin.pendingNotificationRequests();
    } catch (e) {
      debugPrint('❌ Error getting pending notifications: $e');
      return [];
    }
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    try {
      await initialize();
      // For Android, check if notifications are enabled
      final androidPlugin =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        return await androidPlugin.areNotificationsEnabled() ?? false;
      }
      // For iOS, assume enabled if initialized
      return _isInitialized;
    } catch (e) {
      debugPrint('❌ Error checking notification status: $e');
      return false;
    }
  }

  /// Request notification permissions
  Future<void> requestPermissions() async {
    try {
      await _requestPermissions();
    } catch (e) {
      debugPrint('❌ Error requesting permissions: $e');
    }
  }

  /// Show sync notification
  Future<void> showSyncNotification({
    required String title,
    required String body,
    bool isOngoing = false,
  }) async {
    try {
      await initialize();

      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'sync',
        'Sync Notifications',
        channelDescription: 'Notifications for sync operations',
        importance: isOngoing ? Importance.low : Importance.defaultImportance,
        priority: isOngoing ? Priority.low : Priority.defaultPriority,
        showWhen: true,
        ongoing: isOngoing,
        icon: '@mipmap/ic_launcher',
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.show(
        'sync'.hashCode, // Use consistent ID for sync notifications
        title,
        body,
        notificationDetails,
      );

      debugPrint('✅ Sync notification shown: $title');
    } catch (e) {
      debugPrint('❌ Error showing sync notification: $e');
    }
  }

  /// Dispose the notification service
  Future<void> dispose() async {
    try {
      _isInitialized = false;
      debugPrint('✅ NotificationService disposed');
    } catch (e) {
      debugPrint('❌ Error disposing NotificationService: $e');
    }
  }
}
