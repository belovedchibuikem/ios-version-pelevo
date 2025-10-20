import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../widgets/floating_mini_player_overlay.dart';

/// Manages Snackbar positioning to ensure they appear above the mini-player
class SnackbarManager {
  /// Show Snackbar with smart positioning above mini-player
  static void showSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
    bool showAboveMiniPlayer = true,
    Color? backgroundColor,
    Color? textColor,
    double? elevation,
  }) {
    try {
      // Check if mini-player is visible
      final isMiniPlayerVisible = FloatingMiniPlayerOverlay.isVisible;

      if (isMiniPlayerVisible && showAboveMiniPlayer) {
        // Show above mini-player
        _showAboveMiniPlayer(
          context,
          message,
          duration: duration,
          action: action,
          backgroundColor: backgroundColor,
          textColor: textColor,
          elevation: elevation,
        );
      } else {
        // Show in normal position
        _showNormalSnackbar(
          context,
          message,
          duration: duration,
          action: action,
          backgroundColor: backgroundColor,
          textColor: textColor,
          elevation: elevation,
        );
      }
    } catch (e) {
      debugPrint('❌ Error showing Snackbar: $e');
      // Fallback to normal Snackbar
      _showNormalSnackbar(
        context,
        message,
        duration: duration,
        action: action,
        backgroundColor: backgroundColor,
        textColor: textColor,
        elevation: elevation,
      );
    }
  }

  /// Show Snackbar above mini-player with proper positioning
  static void _showAboveMiniPlayer(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
    Color? backgroundColor,
    Color? textColor,
    double? elevation,
  }) {
    try {
      // Calculate position above mini-player
      final miniPlayerHeight = FloatingMiniPlayerOverlay.getMiniPlayerHeight();

      // Position Snackbar above mini-player with some spacing
      // Note: Cache removed - using estimated positioning
      final snackbarPosition =
          miniPlayerHeight + 100.0; // Estimated safe position

      debugPrint(
          '🔔 Showing Snackbar above mini-player at position: ${snackbarPosition}px');

      // Show Snackbar with custom positioning
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: TextStyle(
              color: textColor ?? Colors.white,
              fontSize: 16,
            ),
          ),
          duration: duration,
          action: action,
          behavior: SnackBarBehavior.floating,
          backgroundColor: backgroundColor ?? Colors.black87,
          elevation: elevation ?? 8,
          margin: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: snackbarPosition,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } catch (e) {
      debugPrint('❌ Error showing Snackbar above mini-player: $e');
      // Fallback to normal Snackbar
      _showNormalSnackbar(
        context,
        message,
        duration: duration,
        action: action,
        backgroundColor: backgroundColor,
        textColor: textColor,
        elevation: elevation,
      );
    }
  }

  /// Show Snackbar in normal position
  static void _showNormalSnackbar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
    Color? backgroundColor,
    Color? textColor,
    double? elevation,
  }) {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: TextStyle(
              color: textColor ?? Colors.white,
              fontSize: 16,
            ),
          ),
          duration: duration,
          action: action,
          backgroundColor: backgroundColor ?? Colors.black87,
          elevation: elevation ?? 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } catch (e) {
      debugPrint('❌ Error showing normal Snackbar: $e');
    }
  }

  /// Show Snackbar above mini-player (convenience method)
  static void showAboveMiniPlayer(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
    Color? backgroundColor,
    Color? textColor,
    double? elevation,
  }) {
    _showAboveMiniPlayer(
      context,
      message,
      duration: duration,
      action: action,
      backgroundColor: backgroundColor,
      textColor: textColor,
      elevation: elevation,
    );
  }

  /// Show Snackbar below mini-player (convenience method)
  static void showBelowMiniPlayer(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
    Color? backgroundColor,
    Color? textColor,
    double? elevation,
  }) {
    try {
      // Calculate position below mini-player
      final miniPlayerHeight = FloatingMiniPlayerOverlay.getMiniPlayerHeight();

      // Position Snackbar below mini-player with some spacing
      // Note: Cache removed - using estimated positioning
      final snackbarPosition = 16.0; // Safe bottom position

      debugPrint(
          '🔔 Showing Snackbar below mini-player at position: ${snackbarPosition}px');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: TextStyle(
              color: textColor ?? Colors.white,
              fontSize: 16,
            ),
          ),
          duration: duration,
          action: action,
          behavior: SnackBarBehavior.floating,
          backgroundColor: backgroundColor ?? Colors.black87,
          elevation: elevation ?? 8,
          margin: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: snackbarPosition,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } catch (e) {
      debugPrint('❌ Error showing Snackbar below mini-player: $e');
      // Fallback to normal Snackbar
      _showNormalSnackbar(
        context,
        message,
        duration: duration,
        action: action,
        backgroundColor: backgroundColor,
        textColor: textColor,
        elevation: elevation,
      );
    }
  }

  /// Show success Snackbar above mini-player
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    showSnackBar(
      context,
      message,
      duration: duration,
      action: action,
      backgroundColor: Colors.green[700],
      textColor: Colors.white,
    );
  }

  /// Show error Snackbar above mini-player
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    showSnackBar(
      context,
      message,
      duration: duration,
      action: action,
      backgroundColor: Colors.red[700],
      textColor: Colors.white,
    );
  }

  /// Show warning Snackbar above mini-player
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    showSnackBar(
      context,
      message,
      duration: duration,
      action: action,
      backgroundColor: Colors.orange[700],
      textColor: Colors.white,
    );
  }

  /// Show info Snackbar above mini-player
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    showSnackBar(
      context,
      message,
      duration: duration,
      action: action,
      backgroundColor: Colors.blue[700],
      textColor: Colors.white,
    );
  }

  /// Check if mini-player is currently visible
  static bool get isMiniPlayerVisible => FloatingMiniPlayerOverlay.isVisible;

  /// Get current mini-player height for positioning calculations
  static double get miniPlayerHeight =>
      FloatingMiniPlayerOverlay.getMiniPlayerHeight();

  /// Note: Bottom navigation height cache has been removed.
  /// The mini-player now always auto-detects positioning for optimal performance.
}
