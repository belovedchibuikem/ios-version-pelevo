import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Navigation Theme Configuration
///
/// Provides consistent styling and theming for the enhanced navigation system
/// across different screen sizes and themes.
class NavigationTheme {
  NavigationTheme._();

  // ===== COLOR PALETTE =====

  /// Primary navigation colors
  static const Color primaryLight = Color(0xFF00695C); // Teal 800
  static const Color primaryVariantLight = Color(0xFF004D40); // Teal 900
  static const Color secondaryLight = Color(0xFF4DB6AC); // Teal 300
  static const Color accentLight = Color(0xFF80CBC4); // Teal 200

  /// Dark theme colors
  static const Color primaryDark = Color(0xFF4DB6AC); // Teal 300
  static const Color primaryVariantDark = Color(0xFF00695C); // Teal 800
  static const Color secondaryDark = Color(0xFF80CBC4); // Teal 200
  static const Color accentDark = Color(0xFFB2DFDB); // Teal 100

  /// State colors
  static const Color successColor = Color(0xFF4CAF50); // Green
  static const Color warningColor = Color(0xFFFF9800); // Orange
  static const Color errorColor = Color(0xFFF44336); // Red
  static const Color infoColor = Color(0xFF2196F3); // Blue

  /// Neutral colors
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color outlineLight = Color(0xFFE0E0E0);
  static const Color outlineDark = Color(0xFF424242);

  // ===== TYPOGRAPHY =====

  /// Navigation label styles
  static TextStyle getLabelStyle({
    required bool isSelected,
    required bool isDark,
    required double fontSize,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
      letterSpacing: isSelected ? 0.5 : 0.3,
      height: 1.2,
      color: isSelected
          ? (isDark ? primaryDark : primaryLight)
          : (isDark ? Colors.white70 : Colors.black54),
    );
  }

  /// Badge text style
  static TextStyle getBadgeTextStyle({
    required bool isDark,
    required double fontSize,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      color: Colors.white,
      height: 1.0,
    );
  }

  // ===== DIMENSIONS =====

  /// Responsive navigation heights
  static double getNavigationHeight(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width > 900) {
      // Desktop
      return 100.0;
    } else if (width > 600) {
      // Tablet
      return 90.0;
    } else if (width > 400) {
      // Large phone
      return 85.0;
    } else {
      // Standard phone
      return 80.0;
    }
  }

  /// Icon sizes
  static double getIconSize({
    required bool isSelected,
    required bool isHovered,
    required double baseSize,
  }) {
    if (isSelected) {
      return baseSize + 4.0;
    } else if (isHovered) {
      return baseSize + 2.0;
    }
    return baseSize;
  }

  /// Spacing values
  static const double itemPadding = 16.0;
  static const double itemSpacing = 8.0;
  static const double labelSpacing = 4.0;
  static const double badgePadding = 4.0;
  static const double indicatorHeight = 4.0;
  static const double indicatorWidth = 32.0;

  // ===== SHADOWS =====

  /// Navigation shadows for light theme
  static List<BoxShadow> getLightShadows() {
    return [
      BoxShadow(
        color: Colors.black.withOpacity(0.08),
        blurRadius: 20,
        offset: const Offset(0, -6),
        spreadRadius: 0,
      ),
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 10,
        offset: const Offset(0, -2),
        spreadRadius: 0,
      ),
    ];
  }

  /// Navigation shadows for dark theme
  static List<BoxShadow> getDarkShadows() {
    return [
      BoxShadow(
        color: Colors.black.withOpacity(0.3),
        blurRadius: 16,
        offset: const Offset(0, -4),
        spreadRadius: 0,
      ),
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 8,
        offset: const Offset(0, -2),
        spreadRadius: 0,
      ),
    ];
  }

  // ===== BORDERS & RADIUS =====

  /// Border radius values
  static const double itemRadius = 16.0;
  static const double navigationRadius = 24.0;
  static const double badgeRadius = 12.0;
  static const double indicatorRadius = 2.0;

  /// Border widths
  static const double selectedBorderWidth = 2.0;
  static const double defaultBorderWidth = 1.0;
  static const double topBorderWidth = 0.5;

  // ===== ANIMATIONS =====

  /// Animation durations
  static const Duration fastAnimation = Duration(milliseconds: 150);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);

  /// Animation curves
  static const Curve selectionCurve = Curves.easeOutBack;
  static const Curve colorCurve = Curves.easeInOut;
  static const Curve elevationCurve = Curves.easeOutCubic;
  static const Curve slideCurve = Curves.easeOutCubic;
  static const Curve fadeCurve = Curves.easeInOut;

  // ===== RESPONSIVE BREAKPOINTS =====

  /// Screen size breakpoints
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 900.0;
  static const double desktopBreakpoint = 1200.0;

  /// Check if current screen is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width <= mobileBreakpoint;
  }

  /// Check if current screen is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width > mobileBreakpoint && width <= tabletBreakpoint;
  }

  /// Check if current screen is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width > tabletBreakpoint;
  }

  // ===== THEME HELPERS =====

  /// Get appropriate colors based on theme
  static ColorScheme getColorScheme(BuildContext context) {
    return Theme.of(context).colorScheme;
  }

  /// Check if dark mode is enabled
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  /// Get primary color based on theme
  static Color getPrimaryColor(BuildContext context) {
    return isDarkMode(context) ? primaryDark : primaryLight;
  }

  /// Get secondary color based on theme
  static Color getSecondaryColor(BuildContext context) {
    return isDarkMode(context) ? secondaryDark : secondaryLight;
  }

  /// Get surface color based on theme
  static Color getSurfaceColor(BuildContext context) {
    return isDarkMode(context) ? surfaceDark : surfaceLight;
  }

  /// Get outline color based on theme
  static Color getOutlineColor(BuildContext context) {
    return isDarkMode(context) ? outlineDark : outlineLight;
  }

  // ===== ACCESSIBILITY =====

  /// Minimum touch target size
  static const double minTouchTarget = 48.0;

  /// Check if touch target meets accessibility requirements
  static bool meetsTouchTargetRequirements(double size) {
    return size >= minTouchTarget;
  }

  /// Get recommended icon size for accessibility
  static double getAccessibleIconSize(BuildContext context) {
    final baseSize = isMobile(context) ? 24.0 : 28.0;
    return baseSize.clamp(minTouchTarget, minTouchTarget * 1.5);
  }
}


