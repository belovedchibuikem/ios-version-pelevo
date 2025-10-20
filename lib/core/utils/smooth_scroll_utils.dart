import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async'; // Added for Timer

/// Utility class for smooth scrolling functionality
class SmoothScrollUtils {
  /// Default scroll physics for smooth scrolling
  static const ScrollPhysics defaultPhysics = BouncingScrollPhysics(
    parent: AlwaysScrollableScrollPhysics(),
  );

  /// Smooth scroll physics with custom parameters
  static ScrollPhysics customPhysics({
    ScrollPhysics? parent,
    double? decelerationRate,
    double? velocityScale,
  }) {
    return BouncingScrollPhysics(
      parent: parent ?? const AlwaysScrollableScrollPhysics(),
    );
  }

  /// Scroll to top with smooth animation
  static Future<void> scrollToTop(
    ScrollController controller, {
    Duration duration = const Duration(milliseconds: 500),
    Curve curve = Curves.easeInOut,
  }) async {
    if (controller.hasClients) {
      await controller.animateTo(
        0,
        duration: duration,
        curve: curve,
      );
    }
  }

  /// Scroll to specific position with smooth animation
  static Future<void> scrollToPosition(
    ScrollController controller,
    double position, {
    Duration duration = const Duration(milliseconds: 500),
    Curve curve = Curves.easeInOut,
  }) async {
    if (controller.hasClients) {
      await controller.animateTo(
        position,
        duration: duration,
        curve: curve,
      );
    }
  }

  /// Scroll to specific item index with smooth animation
  static Future<void> scrollToIndex(
    ScrollController controller,
    int index, {
    Duration duration = const Duration(milliseconds: 500),
    Curve curve = Curves.easeInOut,
    double alignment = 0.0,
  }) async {
    if (controller.hasClients) {
      // Calculate approximate position based on index
      // This is a rough estimate - for precise positioning, use ScrollController.position
      final estimatedPosition = index * 100.0; // Assuming average item height
      await controller.animateTo(
        estimatedPosition,
        duration: duration,
        curve: curve,
      );
    }
  }

  /// Check if scroll position is at top
  static bool isAtTop(ScrollController controller) {
    return controller.hasClients && controller.position.pixels == 0;
  }

  /// Check if scroll position is at bottom
  static bool isAtBottom(ScrollController controller) {
    if (!controller.hasClients) return false;
    final position = controller.position;
    return position.pixels >= position.maxScrollExtent;
  }

  /// Get current scroll percentage (0.0 to 1.0)
  static double getScrollPercentage(ScrollController controller) {
    if (!controller.hasClients) return 0.0;
    final position = controller.position;
    if (position.maxScrollExtent == 0) return 0.0;
    return position.pixels / position.maxScrollExtent;
  }

  /// Add scroll listener with debouncing
  static void addScrollListener(
    ScrollController controller,
    VoidCallback callback, {
    Duration debounceTime = const Duration(milliseconds: 100),
  }) {
    Timer? _debounceTimer;

    controller.addListener(() {
      if (_debounceTimer?.isActive ?? false) {
        _debounceTimer!.cancel();
      }
      _debounceTimer = Timer(debounceTime, callback);
    });
  }
}

/// Custom scroll behavior for consistent scrolling across platforms
class CustomScrollBehavior extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

/// Mixin for adding smooth scrolling capabilities to StatefulWidgets
mixin SmoothScrollMixin<T extends StatefulWidget> on State<T> {
  late ScrollController _scrollController;

  ScrollController get scrollController => _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Scroll to top with smooth animation
  Future<void> scrollToTop() async {
    await SmoothScrollUtils.scrollToTop(_scrollController);
  }

  /// Scroll to specific position with smooth animation
  Future<void> scrollToPosition(double position) async {
    await SmoothScrollUtils.scrollToPosition(_scrollController, position);
  }

  /// Scroll to specific index with smooth animation
  Future<void> scrollToIndex(int index) async {
    await SmoothScrollUtils.scrollToIndex(_scrollController, index);
  }

  /// Check if at top
  bool get isAtTop => SmoothScrollUtils.isAtTop(_scrollController);

  /// Check if at bottom
  bool get isAtBottom => SmoothScrollUtils.isAtBottom(_scrollController);

  /// Get scroll percentage
  double get scrollPercentage =>
      SmoothScrollUtils.getScrollPercentage(_scrollController);
}
