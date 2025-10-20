import 'package:flutter/material.dart';

/// Utility class for safe area handling throughout the app
class SafeAreaUtils {
  /// Wrap content with safe area, respecting system UI boundaries
  static Widget wrapWithSafeArea(
    Widget child, {
    bool top = true,
    bool bottom = true,
    bool left = true,
    bool right = true,
    EdgeInsets minimum = EdgeInsets.zero,
  }) {
    return SafeArea(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      minimum: minimum,
      child: child,
    );
  }

  /// Get safe area padding for the current context
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  /// Get bottom safe area height (useful for floating elements)
  static double getBottomSafeAreaHeight(BuildContext context) {
    return MediaQuery.of(context).padding.bottom;
  }

  /// Get top safe area height (useful for status bar)
  static double getTopSafeAreaHeight(BuildContext context) {
    return MediaQuery.of(context).padding.top;
  }

  /// Create a bottom sheet with proper safe area handling
  static Future<T?> showSafeBottomSheet<T>({
    required BuildContext context,
    required Widget child,
    bool isScrollControlled = true,
    Color? backgroundColor,
    bool isDismissible = true,
    bool enableDrag = true,
    Color? barrierColor,
    double? elevation,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: backgroundColor ?? Colors.transparent,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      barrierColor: barrierColor ?? Colors.black54,
      elevation: elevation ?? 24,
      builder: (context) => SafeArea(
        child: child,
      ),
    );
  }

  /// Create a floating action button with safe area consideration
  static Widget createSafeFloatingActionButton({
    required VoidCallback onPressed,
    required Widget child,
    String? tooltip,
    Color? backgroundColor,
    Color? foregroundColor,
    double? elevation,
    double? focusElevation,
    double? hoverElevation,
    double? highlightElevation,
    double? disabledElevation,
    ShapeBorder? shape,
    Clip clipBehavior = Clip.none,
    FocusNode? focusNode,
    bool autofocus = false,
    MaterialTapTargetSize? materialTapTargetSize,
    bool isExtended = false,
    bool? enableFeedback,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: 16.0, // Add bottom padding to avoid safe area
      ),
      child: FloatingActionButton(
        onPressed: onPressed,
        tooltip: tooltip,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        elevation: elevation,
        focusElevation: focusElevation,
        hoverElevation: hoverElevation,
        highlightElevation: highlightElevation,
        disabledElevation: disabledElevation,
        shape: shape,
        clipBehavior: clipBehavior,
        focusNode: focusNode,
        autofocus: autofocus,
        materialTapTargetSize: materialTapTargetSize,
        isExtended: isExtended,
        enableFeedback: enableFeedback,
        child: child,
      ),
    );
  }

  /// Create a container with safe area padding
  static Widget createSafeContainer({
    required Widget child,
    EdgeInsets? padding,
    EdgeInsets? margin,
    Color? color,
    Decoration? decoration,
    BoxConstraints? constraints,
    AlignmentGeometry? alignment,
    Clip clipBehavior = Clip.none,
  }) {
    return Container(
      padding: padding,
      margin: margin,
      color: color,
      decoration: decoration,
      constraints: constraints,
      alignment: alignment,
      clipBehavior: clipBehavior,
      child: child,
    );
  }

  /// Get recommended padding for content areas
  static EdgeInsets getContentPadding(BuildContext context) {
    final safeArea = getSafeAreaPadding(context);
    return EdgeInsets.only(
      top: safeArea.top + 16.0,
      bottom: safeArea.bottom + 16.0,
      left: safeArea.left + 16.0,
      right: safeArea.right + 16.0,
    );
  }
}
