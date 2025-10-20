import 'package:flutter/material.dart';

/// Utility class for mini-player positioning constants
///
/// **Note: Bottom navigation cache has been removed.**
/// The mini-player now always auto-detects positioning for optimal performance.
/// This class now only provides constants for reference.
class MiniPlayerPositioning {
  /// Standard bottom navigation height (percentage-based to match CommonBottomNavigationWidget)
  /// Using 8% of screen height (8.h) to match the actual navigation widget
  static double getStandardHeight(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return screenHeight * 0.08; // 8% of screen height (8.h)
  }

  /// Fixed spacing between mini-player and bottom navigation
  static const double spacing =
      0.0; // No spacing - mini-player sits directly on nav bar

  /// Minimal spacing for screens without navigation bars
  static const double minimalSpacing = 8.0; // Small spacing from bottom edge

  /// Fixed spacing for screens with navigation bars
  static const double optimalSpacing =
      0.0; // No spacing - mini-player sits directly on nav bar

  /// Approximate visual height of the mini-player card itself (in logical pixels)
  /// Used to reserve scrollable bottom space so content isn't obscured
  static const double miniPlayerVisualHeight =
      84.0; // Reduced from 96.0 to 84.0

  /// Note: All positioning methods have been removed.
  /// The mini-player now always auto-detects positioning for optimal performance.

  /// Calculate actual navigation bar height for CommonBottomNavigationWidget
  /// Using percentage-based height to match the actual widget implementation
  static double calculateActualNavHeight(BuildContext context) {
    return getStandardHeight(context); // 8% of screen height (8.h)
  }

  /// Recommended bottom padding for scrollables to avoid being covered by mini-player
  /// Combines the nav offset + mini-player visual height
  static double bottomPaddingForScrollables() {
    // Since cache is removed, return a reasonable default
    return miniPlayerVisualHeight + 20.0; // Mini-player height + some padding
  }

  /// Debug: Print current positioning information
  static void debugCurrentPosition() {
    debugPrint('🎯 MiniPlayerPositioning: Cache removed - always auto-detects');
    debugPrint('🎯 MiniPlayerPositioning: Spacing: ${spacing}px');
    debugPrint(
        '🎯 MiniPlayerPositioning: Mini-player visual height: ${miniPlayerVisualHeight}px');
    debugPrint(
        '🎯 MiniPlayerPositioning: Bottom padding for scrollables: ${bottomPaddingForScrollables()}px');
  }
}
