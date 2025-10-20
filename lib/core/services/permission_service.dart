import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';

/// Service to handle storage and download permissions
class PermissionService {
  static const String _tag = 'PERMISSION_SERVICE';

  /// Check if storage permissions are granted
  static Future<bool> hasStoragePermission() async {
    try {
      debugPrint('$_tag: Checking storage permissions...');

      // For Android 13+ (API 33+), check media permissions
      try {
        final audioPermission = await Permission.audio.status;
        debugPrint('$_tag: Media Audio permission: ${audioPermission.name}');

        // Check storage permission for older Android compatibility
        final storagePermission = await Permission.storage.status;
        debugPrint('$_tag: Storage permission: ${storagePermission.name}');

        // For Android 13+, media audio permission is the primary requirement
        if (audioPermission.isGranted || storagePermission.isGranted) {
          debugPrint(
              '$_tag: Permissions granted - Audio: ${audioPermission.isGranted}, Storage: ${storagePermission.isGranted}');
          return true;
        } else {
          debugPrint(
              '$_tag: No permissions granted - Audio: ${audioPermission.isGranted}, Storage: ${storagePermission.isGranted}');
          return false;
        }
      } catch (e) {
        debugPrint(
            '$_tag: Media permissions not available, checking storage only: $e');

        // Fallback to storage permission only for older Android
        final storagePermission = await Permission.storage.status;
        debugPrint('$_tag: Storage permission: ${storagePermission.name}');
        return storagePermission.isGranted;
      }
    } catch (e) {
      debugPrint('$_tag: Error checking permissions: $e');
      return false;
    }
  }

  /// Request storage permissions
  static Future<bool> requestStoragePermission(BuildContext context) async {
    try {
      debugPrint('$_tag: Requesting storage permissions...');

      // For Android 13+ (API 33+), request media permissions
      try {
        // Try to request media permissions (Android 13+)
        final mediaAudioStatus = await Permission.audio.request();
        debugPrint(
            '$_tag: Media Audio permission result: ${mediaAudioStatus.name}');

        // Also try to request storage permission for older Android compatibility
        final storageStatus = await Permission.storage.request();
        debugPrint('$_tag: Storage permission result: ${storageStatus.name}');

        // For Android 13+, media audio permission is the primary requirement
        final allGranted =
            mediaAudioStatus.isGranted || storageStatus.isGranted;

        debugPrint(
            '$_tag: Final permission status - Media Audio: ${mediaAudioStatus.isGranted}, Storage: ${storageStatus.isGranted}, All: $allGranted');

        if (!allGranted) {
          _showPermissionDeniedDialog(
              context, 'Storage permission is required to download episodes.');
        }

        return allGranted;
      } catch (e) {
        debugPrint(
            '$_tag: Media permissions not available, trying storage only: $e');

        // Fallback to storage permission only for older Android
        final storageStatus = await Permission.storage.request();
        debugPrint('$_tag: Storage permission result: ${storageStatus.name}');

        if (!storageStatus.isGranted) {
          _showPermissionDeniedDialog(
              context, 'Storage permission is required to download episodes.');
        }

        return storageStatus.isGranted;
      }
    } catch (e) {
      debugPrint('$_tag: Error requesting permissions: $e');
      _showErrorToast('Failed to request permissions: $e');
      return false;
    }
  }

  /// Show permission denied dialog with option to go to settings
  static void _showPermissionDeniedDialog(
      BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permission Required'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('Settings'),
            ),
          ],
        );
      },
    );
  }

  /// Show error toast
  static void _showErrorToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
    );
  }

  /// Check and request permissions with user-friendly messaging
  static Future<bool> ensureStoragePermission(BuildContext context) async {
    try {
      debugPrint('$_tag: Ensuring storage permissions...');

      // Check if we already have permission
      if (await hasStoragePermission()) {
        debugPrint('$_tag: Storage permissions already granted');
        return true;
      }

      // Show info dialog before requesting permission
      final shouldRequest = await _showPermissionInfoDialog(context);
      if (!shouldRequest) {
        debugPrint('$_tag: User declined to grant permissions');
        return false;
      }

      // Request permissions
      final granted = await requestStoragePermission(context);

      if (granted) {
        _showSuccessToast(
            'Storage permission granted! You can now download episodes.');
      } else {
        // Show additional help if permission was denied
        _showPermissionHelpDialog(context);
      }

      return granted;
    } catch (e) {
      debugPrint('$_tag: Error ensuring permissions: $e');
      _showErrorToast('Failed to check permissions: $e');
      return false;
    }
  }

  /// Show additional help dialog for permission issues
  static void _showPermissionHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permission Help'),
          content: const Text(
            'If you denied the permission, you can enable it manually:\n\n'
            '1. Go to your device Settings\n'
            '2. Find "Apps" or "Application Manager"\n'
            '3. Find "Pelevo" app\n'
            '4. Tap "Permissions"\n'
            '5. Enable "Storage" permission\n\n'
            'Then try downloading again.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  /// Show permission info dialog
  static Future<bool> _showPermissionInfoDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Download Permission'),
              content: const Text(
                'This app needs storage permission to download episodes for offline listening. '
                'The downloaded files will be stored securely on your device.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Not Now'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Allow'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  /// Show success toast
  static void _showSuccessToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );
  }

  /// Get permission status for debugging
  static Future<Map<String, String>> getPermissionStatus() async {
    try {
      final Map<String, String> statuses = {};

      // Always check storage permission
      statuses['storage'] = (await Permission.storage.status).name;

      // Try to check newer permissions if available
      try {
        statuses['audio'] = (await Permission.audio.status).name;
      } catch (e) {
        statuses['audio'] = 'Not available';
      }

      try {
        statuses['notification'] = (await Permission.notification.status).name;
      } catch (e) {
        statuses['notification'] = 'Not available';
      }

      return statuses;
    } catch (e) {
      debugPrint('$_tag: Error getting permission status: $e');
      return {'error': e.toString()};
    }
  }

  /// Debug method to test permission flow
  static Future<void> debugPermissionFlow(BuildContext context) async {
    try {
      debugPrint('$_tag: === DEBUG PERMISSION FLOW START ===');

      // Check current status
      final status = await getPermissionStatus();
      debugPrint('$_tag: Current permission status: $status');

      // Test permission checking
      final hasPermission = await hasStoragePermission();
      debugPrint('$_tag: Has storage permission: $hasPermission');

      if (!hasPermission) {
        debugPrint('$_tag: Requesting permissions...');
        final granted = await requestStoragePermission(context);
        debugPrint('$_tag: Permission request result: $granted');
      }

      debugPrint('$_tag: === DEBUG PERMISSION FLOW END ===');
    } catch (e) {
      debugPrint('$_tag: Error in debug permission flow: $e');
    }
  }
}
