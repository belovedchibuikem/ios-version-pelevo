import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../services/animation_service.dart';

/// Enhanced gesture detector with advanced touch interactions and haptic feedback
class EnhancedGestureDetector extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onSecondaryTap;
  final GestureTapDownCallback? onTapDown;
  final GestureTapUpCallback? onTapUp;
  final GestureTapCancelCallback? onTapCancel;
  final GestureDragStartCallback? onPanStart;
  final GestureDragUpdateCallback? onPanUpdate;
  final GestureDragEndCallback? onPanEnd;
  final GestureScaleStartCallback? onScaleStart;
  final GestureScaleUpdateCallback? onScaleUpdate;
  final GestureScaleEndCallback? onScaleEnd;
  final bool enableHapticFeedback;
  final bool enableRippleEffect;
  final bool enableScaleAnimation;
  final Duration animationDuration;
  final Curve animationCurve;
  final double scaleFactor;
  final Color? rippleColor;
  final BorderRadius? borderRadius;

  const EnhancedGestureDetector({
    super.key,
    required this.child,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.onSecondaryTap,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
    this.onScaleStart,
    this.onScaleUpdate,
    this.onScaleEnd,
    this.enableHapticFeedback = true,
    this.enableRippleEffect = true,
    this.enableScaleAnimation = true,
    this.animationDuration = const Duration(milliseconds: 150),
    this.animationCurve = Curves.easeOut,
    this.scaleFactor = 0.95,
    this.rippleColor,
    this.borderRadius,
  });

  @override
  State<EnhancedGestureDetector> createState() =>
      _EnhancedGestureDetectorState();
}

class _EnhancedGestureDetectorState extends State<EnhancedGestureDetector>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _rippleController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rippleAnimation;

  Offset? _rippleCenter;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _scaleController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _rippleController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleFactor,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: widget.animationCurve,
    ));

    _rippleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rippleController,
      curve: widget.animationCurve,
    ));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }

    if (widget.enableRippleEffect) {
      setState(() {
        _rippleCenter = details.localPosition;
        _isPressed = true;
      });
      _rippleController.forward();
    }

    if (widget.enableScaleAnimation) {
      _scaleController.forward();
    }

    widget.onTapDown?.call(details);
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.enableScaleAnimation) {
      _scaleController.reverse();
    }

    if (widget.enableRippleEffect) {
      _rippleController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _isPressed = false;
          });
        }
      });
    }

    widget.onTapUp?.call(details);
  }

  void _handleTapCancel() {
    if (widget.enableScaleAnimation) {
      _scaleController.reverse();
    }

    if (widget.enableRippleEffect) {
      _rippleController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _isPressed = false;
          });
        }
      });
    }

    widget.onTapCancel?.call();
  }

  void _handleTap() {
    if (widget.enableHapticFeedback) {
      HapticFeedback.selectionClick();
    }
    widget.onTap?.call();
  }

  void _handleDoubleTap() {
    if (widget.enableHapticFeedback) {
      HapticFeedback.heavyImpact();
    }
    widget.onDoubleTap?.call();
  }

  void _handleLongPress() {
    if (widget.enableHapticFeedback) {
      HapticFeedback.mediumImpact();
    }
    widget.onLongPress?.call();
  }

  @override
  Widget build(BuildContext context) {
    Widget gestureWidget = GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: _handleTap,
      onDoubleTap: _handleDoubleTap,
      onLongPress: _handleLongPress,
      onSecondaryTap: widget.onSecondaryTap,
      onPanStart: widget.onPanStart,
      onPanUpdate: widget.onPanUpdate,
      onPanEnd: widget.onPanEnd,
      onScaleStart: widget.onScaleStart,
      onScaleUpdate: widget.onScaleUpdate,
      onScaleEnd: widget.onScaleEnd,
      child: widget.child,
    );

    // Apply scale animation
    if (widget.enableScaleAnimation) {
      gestureWidget = AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: gestureWidget,
      );
    }

    // Apply ripple effect
    if (widget.enableRippleEffect) {
      gestureWidget = Stack(
        children: [
          gestureWidget,
          if (_isPressed && _rippleCenter != null)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _rippleAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: RipplePainter(
                      center: _rippleCenter!,
                      progress: _rippleAnimation.value,
                      color: widget.rippleColor ??
                          Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.3),
                      borderRadius: widget.borderRadius,
                    ),
                  );
                },
              ),
            ),
        ],
      );
    }

    return gestureWidget;
  }
}

/// Custom painter for ripple effect
class RipplePainter extends CustomPainter {
  final Offset center;
  final double progress;
  final Color color;
  final BorderRadius? borderRadius;

  RipplePainter({
    required this.center,
    required this.progress,
    required this.color,
    this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: color.opacity * (1.0 - progress))
      ..style = PaintingStyle.fill;

    final radius = progress * size.width * 0.8;

    if (borderRadius != null) {
      // Clip to border radius if specified
      canvas.save();
      final path = Path()
        ..addRRect(borderRadius!
            .toRRect(Rect.fromLTWH(0, 0, size.width, size.height)));
      canvas.clipPath(path);
    }

    canvas.drawCircle(center, radius, paint);

    if (borderRadius != null) {
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(RipplePainter oldDelegate) {
    return oldDelegate.center != center ||
        oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.borderRadius != borderRadius;
  }
}

/// Enhanced tap target widget for better accessibility
class EnhancedTapTarget extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double minTapTargetSize;
  final EdgeInsets padding;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;

  const EnhancedTapTarget({
    super.key,
    required this.child,
    this.onTap,
    this.minTapTargetSize = 48.0,
    this.padding = const EdgeInsets.all(8.0),
    this.backgroundColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? BorderRadius.circular(8.0),
        child: Container(
          constraints: BoxConstraints(
            minWidth: minTapTargetSize,
            minHeight: minTapTargetSize,
          ),
          padding: padding,
          child: Center(child: child),
        ),
      ),
    );
  }
}

/// Swipeable widget with gesture callbacks
class SwipeableWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final VoidCallback? onSwipeUp;
  final VoidCallback? onSwipeDown;
  final double swipeThreshold;
  final bool enableHapticFeedback;

  const SwipeableWidget({
    super.key,
    required this.child,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.onSwipeUp,
    this.onSwipeDown,
    this.swipeThreshold = 100.0,
    this.enableHapticFeedback = true,
  });

  @override
  State<SwipeableWidget> createState() => _SwipeableWidgetState();
}

class _SwipeableWidgetState extends State<SwipeableWidget> {
  Offset? _startPosition;
  Offset? _currentPosition;

  void _handlePanStart(DragStartDetails details) {
    _startPosition = details.localPosition;
    _currentPosition = details.localPosition;
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    _currentPosition = details.localPosition;
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_startPosition == null || _currentPosition == null) return;

    final delta = _currentPosition! - _startPosition!;
    final distance = delta.distance;

    if (distance < widget.swipeThreshold) return;

    // Determine swipe direction
    if (delta.dx.abs() > delta.dy.abs()) {
      // Horizontal swipe
      if (delta.dx > 0) {
        _handleSwipe(widget.onSwipeRight, 'right');
      } else {
        _handleSwipe(widget.onSwipeLeft, 'left');
      }
    } else {
      // Vertical swipe
      if (delta.dy > 0) {
        _handleSwipe(widget.onSwipeDown, 'down');
      } else {
        _handleSwipe(widget.onSwipeUp, 'up');
      }
    }

    _startPosition = null;
    _currentPosition = null;
  }

  void _handleSwipe(VoidCallback? callback, String direction) {
    if (callback != null) {
      if (widget.enableHapticFeedback) {
        HapticFeedback.mediumImpact();
      }
      callback();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      child: widget.child,
    );
  }
}

/// Pinch to zoom widget
class PinchToZoomWidget extends StatefulWidget {
  final Widget child;
  final double minScale;
  final double maxScale;
  final Duration animationDuration;
  final Curve animationCurve;

  const PinchToZoomWidget({
    super.key,
    required this.child,
    this.minScale = 0.5,
    this.maxScale = 3.0,
    this.animationDuration = const Duration(milliseconds: 200),
    this.animationCurve = Curves.easeOut,
  });

  @override
  State<PinchToZoomWidget> createState() => _PinchToZoomWidgetState();
}

class _PinchToZoomWidgetState extends State<PinchToZoomWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _offsetAnimation;

  double _currentScale = 1.0;
  Offset _currentOffset = Offset.zero;
  Offset _focalPoint = Offset.zero;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: widget.animationCurve,
    ));

    _offsetAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: widget.animationCurve,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _focalPoint = details.localFocalPoint;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      _currentScale = (_currentScale * details.scale).clamp(
        widget.minScale,
        widget.maxScale,
      );

      if (details.scale != 1.0) {
        final delta = details.localFocalPoint - _focalPoint;
        _currentOffset += delta * (1.0 - 1.0 / details.scale);
        _focalPoint = details.localFocalPoint;
      }
    });
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    // Animate to bounds if needed
    final targetScale = _currentScale.clamp(widget.minScale, widget.maxScale);
    final targetOffset = _currentOffset;

    if (targetScale != _currentScale || targetOffset != _currentOffset) {
      _scaleAnimation = Tween<double>(
        begin: _currentScale,
        end: targetScale,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: widget.animationCurve,
      ));

      _offsetAnimation = Tween<Offset>(
        begin: _currentOffset,
        end: targetOffset,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: widget.animationCurve,
      ));

      _animationController.forward().then((_) {
        setState(() {
          _currentScale = targetScale;
          _currentOffset = targetOffset;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleStart: _handleScaleStart,
      onScaleUpdate: _handleScaleUpdate,
      onScaleEnd: _handleScaleEnd,
      child: Transform(
        transform: Matrix4.identity()
          ..translate(_currentOffset.dx, _currentOffset.dy)
          ..scale(_currentScale),
        child: widget.child,
      ),
    );
  }
}
