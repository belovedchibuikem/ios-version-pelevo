import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';

/// Enhanced animation service for smooth, delightful user interactions
class AnimationService {
  static final AnimationService _instance = AnimationService._internal();
  factory AnimationService() => _instance;
  AnimationService._internal();

  // Animation presets
  static const Duration _fastDuration = Duration(milliseconds: 200);
  static const Duration _normalDuration = Duration(milliseconds: 300);
  static const Duration _slowDuration = Duration(milliseconds: 500);
  static const Duration _bounceDuration = Duration(milliseconds: 600);

  // Animation curves
  static const Curve _easeOut = Curves.easeOut;
  static const Curve _easeInOut = Curves.easeInOut;
  static const Curve _elasticOut = Curves.elasticOut;
  static const Curve _bounceOut = Curves.bounceOut;

  /// Create a fade-in animation
  Animation<double> createFadeInAnimation(AnimationController controller) {
    return Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: _easeOut,
    ));
  }

  /// Create a slide-in animation from bottom
  Animation<Offset> createSlideInFromBottomAnimation(
      AnimationController controller) {
    return Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: _easeOut,
    ));
  }

  /// Create a slide-in animation from top
  Animation<Offset> createSlideInFromTopAnimation(
      AnimationController controller) {
    return Tween<Offset>(
      begin: const Offset(0.0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: _easeOut,
    ));
  }

  /// Create a slide-in animation from left
  Animation<Offset> createSlideInFromLeftAnimation(
      AnimationController controller) {
    return Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: _easeOut,
    ));
  }

  /// Create a slide-in animation from right
  Animation<Offset> createSlideInFromRightAnimation(
      AnimationController controller) {
    return Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: _easeOut,
    ));
  }

  /// Create a scale animation
  Animation<double> createScaleAnimation(AnimationController controller) {
    return Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: _elasticOut,
    ));
  }

  /// Create a bounce animation
  Animation<double> createBounceAnimation(AnimationController controller) {
    return Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: _bounceOut,
    ));
  }

  /// Create a rotation animation
  Animation<double> createRotationAnimation(AnimationController controller) {
    return Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: _easeInOut,
    ));
  }

  /// Create a staggered animation for lists
  List<Animation<double>> createStaggeredAnimations(
    AnimationController controller,
    int itemCount, {
    Duration staggerDelay = const Duration(milliseconds: 100),
  }) {
    final animations = <Animation<double>>[];

    for (int i = 0; i < itemCount; i++) {
      final delay = i * staggerDelay.inMilliseconds;
      final startTime = delay / controller.duration!.inMilliseconds;
      final endTime = (delay + _normalDuration.inMilliseconds) /
          controller.duration!.inMilliseconds;

      final animation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Interval(startTime, endTime, curve: _easeOut),
      ));

      animations.add(animation);
    }

    return animations;
  }

  /// Create a pulse animation
  Animation<double> createPulseAnimation(AnimationController controller) {
    return Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    ));
  }

  /// Create a shake animation
  Animation<double> createShakeAnimation(AnimationController controller) {
    return Tween<double>(
      begin: -10.0,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.elasticIn,
    ));
  }

  /// Create a ripple effect animation
  Animation<double> createRippleAnimation(AnimationController controller) {
    return Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: _easeOut,
    ));
  }

  /// Create a slide and fade animation
  Animation<double> createSlideAndFadeAnimation(
      AnimationController controller) {
    return Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: _easeOut,
    ));
  }

  /// Create a custom elastic animation
  Animation<double> createElasticAnimation(
    AnimationController controller, {
    double begin = 0.0,
    double end = 1.0,
    Curve curve = Curves.elasticOut,
  }) {
    return Tween<double>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: curve,
    ));
  }

  /// Create a staggered fade animation for grid items
  List<Animation<double>> createStaggeredFadeAnimations(
    AnimationController controller,
    int itemCount, {
    Duration staggerDelay = const Duration(milliseconds: 50),
  }) {
    final animations = <Animation<double>>[];

    for (int i = 0; i < itemCount; i++) {
      final delay = i * staggerDelay.inMilliseconds;
      final startTime = delay / controller.duration!.inMilliseconds;
      final endTime = (delay + _fastDuration.inMilliseconds) /
          controller.duration!.inMilliseconds;

      final animation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Interval(startTime, endTime, curve: _easeOut),
      ));

      animations.add(animation);
    }

    return animations;
  }

  /// Create a loading spinner animation
  Animation<double> createLoadingSpinnerAnimation(
      AnimationController controller) {
    return Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.linear,
    ));
  }

  /// Create a progress bar animation
  Animation<double> createProgressBarAnimation(
    AnimationController controller,
    double targetValue,
  ) {
    return Tween<double>(
      begin: 0.0,
      end: targetValue,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: _easeOut,
    ));
  }

  /// Create a card flip animation
  Animation<double> createCardFlipAnimation(AnimationController controller) {
    return Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: _easeInOut,
    ));
  }

  /// Create a parallax scroll animation
  Animation<double> createParallaxAnimation(AnimationController controller) {
    return Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeOut,
    ));
  }

  /// Create a custom spring animation
  Animation<double> createSpringAnimation(
    AnimationController controller, {
    double begin = 0.0,
    double end = 1.0,
    double damping = 20.0,
    double stiffness = 100.0,
  }) {
    return Tween<double>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeOut,
    ));
  }

  /// Create a staggered scale animation
  List<Animation<double>> createStaggeredScaleAnimations(
    AnimationController controller,
    int itemCount, {
    Duration staggerDelay = const Duration(milliseconds: 75),
  }) {
    final animations = <Animation<double>>[];

    for (int i = 0; i < itemCount; i++) {
      final delay = i * staggerDelay.inMilliseconds;
      final startTime = delay / controller.duration!.inMilliseconds;
      final endTime = (delay + _normalDuration.inMilliseconds) /
          controller.duration!.inMilliseconds;

      final animation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Interval(startTime, endTime, curve: _elasticOut),
      ));

      animations.add(animation);
    }

    return animations;
  }

  /// Create a custom curve animation
  Animation<double> createCustomCurveAnimation(
      AnimationController controller, Curve curve,
      {double begin = 0.0, double end = 1.0}) {
    return Tween<double>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: curve,
    ));
  }

  /// Create a staggered slide animation
  List<Animation<Offset>> createStaggeredSlideAnimations(
    AnimationController controller,
    int itemCount,
    Offset beginOffset, {
    Duration staggerDelay = const Duration(milliseconds: 100),
  }) {
    final animations = <Animation<Offset>>[];

    for (int i = 0; i < itemCount; i++) {
      final delay = i * staggerDelay.inMilliseconds;
      final startTime = delay / controller.duration!.inMilliseconds;
      final endTime = (delay + _normalDuration.inMilliseconds) /
          controller.duration!.inMilliseconds;

      final animation = Tween<Offset>(
        begin: beginOffset,
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Interval(startTime, endTime, curve: _easeOut),
      ));

      animations.add(animation);
    }

    return animations;
  }

  /// Get animation duration based on type
  Duration getAnimationDuration(AnimationType type) {
    switch (type) {
      case AnimationType.fast:
        return _fastDuration;
      case AnimationType.normal:
        return _normalDuration;
      case AnimationType.slow:
        return _slowDuration;
      case AnimationType.bounce:
        return _bounceDuration;
    }
  }

  /// Get animation curve based on type
  Curve getAnimationCurve(AnimationType type) {
    switch (type) {
      case AnimationType.fast:
        return _easeOut;
      case AnimationType.normal:
        return _easeInOut;
      case AnimationType.slow:
        return _easeInOut;
      case AnimationType.bounce:
        return _bounceOut;
    }
  }

  /// Create a combined animation (fade + slide)
  CombinedAnimation createCombinedAnimation(AnimationController controller) {
    final fadeAnimation = createFadeInAnimation(controller);
    final slideAnimation = createSlideInFromBottomAnimation(controller);

    return CombinedAnimation(
      fade: fadeAnimation,
      slide: slideAnimation,
    );
  }

  /// Create a staggered combined animation
  List<CombinedAnimation> createStaggeredCombinedAnimations(
    AnimationController controller,
    int itemCount, {
    Duration staggerDelay = const Duration(milliseconds: 100),
  }) {
    final animations = <CombinedAnimation>[];

    for (int i = 0; i < itemCount; i++) {
      final delay = i * staggerDelay.inMilliseconds;
      final startTime = delay / controller.duration!.inMilliseconds;
      final endTime = (delay + _normalDuration.inMilliseconds) /
          controller.duration!.inMilliseconds;

      final fadeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Interval(startTime, endTime, curve: _easeOut),
      ));

      final slideAnimation = Tween<Offset>(
        begin: const Offset(0.0, 0.3),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Interval(startTime, endTime, curve: _easeOut),
      ));

      animations.add(CombinedAnimation(
        fade: fadeAnimation,
        slide: slideAnimation,
      ));
    }

    return animations;
  }
}

/// Animation type enum
enum AnimationType {
  fast,
  normal,
  slow,
  bounce,
}

/// Combined animation class for complex animations
class CombinedAnimation {
  final Animation<double> fade;
  final Animation<Offset> slide;

  CombinedAnimation({
    required this.fade,
    required this.slide,
  });
}

/// Custom animation curves
class CustomCurves {
  static const Curve smooth = Curves.easeOutCubic;
  static const Curve bouncy = Curves.elasticOut;
  static const Curve snappy = Curves.easeOutBack;
  static const Curve gentle = Curves.easeOutQuart;
}

