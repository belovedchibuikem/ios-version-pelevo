import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'dart:math';
import '../core/app_export.dart';
import '../services/animation_service.dart';

/// Enhanced loading widget with beautiful animations and visual feedback
class EnhancedLoadingWidget extends StatefulWidget {
  final String? message;
  final LoadingType type;
  final Color? color;
  final double size;
  final bool showMessage;
  final VoidCallback? onRetry;

  const EnhancedLoadingWidget({
    super.key,
    this.message,
    this.type = LoadingType.spinner,
    this.color,
    this.size = 60.0,
    this.showMessage = true,
    this.onRetry,
  });

  @override
  State<EnhancedLoadingWidget> createState() => _EnhancedLoadingWidgetState();
}

class _EnhancedLoadingWidgetState extends State<EnhancedLoadingWidget>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late AnimationController _rotationController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  final AnimationService _animationService = AnimationService();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    // Main animation controller
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Pulse animation controller
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Rotation animation controller
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Create animations
    _fadeAnimation = _animationService.createFadeInAnimation(_mainController);
    _scaleAnimation = _animationService.createScaleAnimation(_mainController);
    _pulseAnimation = _animationService.createPulseAnimation(_pulseController);
    _rotationAnimation =
        _animationService.createRotationAnimation(_rotationController);
  }

  void _startAnimations() {
    _mainController.repeat(reverse: true);
    _pulseController.repeat(reverse: true);
    _rotationController.repeat();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Loading animation
          AnimatedBuilder(
            animation: Listenable.merge([_mainController, _pulseController]),
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value * _pulseAnimation.value,
                child: _buildLoadingAnimation(),
              );
            },
          ),

          // Message
          if (widget.showMessage && widget.message != null) ...[
            SizedBox(height: 2.h),
            FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                widget.message!,
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],

          // Retry button (if applicable)
          if (widget.onRetry != null) ...[
            SizedBox(height: 3.h),
            FadeTransition(
              opacity: _fadeAnimation,
              child: _buildRetryButton(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingAnimation() {
    switch (widget.type) {
      case LoadingType.spinner:
        return _buildSpinner();
      case LoadingType.dots:
        return _buildDots();
      case LoadingType.bars:
        return _buildBars();
      case LoadingType.circle:
        return _buildCircle();
      case LoadingType.ripple:
        return _buildRipple();
      case LoadingType.pulse:
        return _buildPulse();
      case LoadingType.wave:
        return _buildWave();
      case LoadingType.heartbeat:
        return _buildHeartbeat();
    }
  }

  Widget _buildSpinner() {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _rotationController,
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotationAnimation.value * 2 * pi,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.color ?? AppTheme.lightTheme.colorScheme.primary,
              ),
              strokeWidth: 4.0,
            ),
          );
        },
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final delay = index * 0.2;
            final animationValue = (_pulseController.value + delay) % 1.0;

            return Container(
              margin: EdgeInsets.symmetric(horizontal: 4),
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: widget.color ?? AppTheme.lightTheme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Transform.scale(
                scale: 0.5 + (animationValue * 0.5),
                child: Container(),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildBars() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final delay = index * 0.1;
            final animationValue = (_pulseController.value + delay) % 1.0;

            return Container(
              margin: EdgeInsets.symmetric(horizontal: 2),
              width: 8,
              height: 40 * (0.3 + (animationValue * 0.7)),
              decoration: BoxDecoration(
                color: widget.color ?? AppTheme.lightTheme.colorScheme.primary,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildCircle() {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _mainController,
        builder: (context, child) {
          return CustomPaint(
            painter: CircleLoadingPainter(
              progress: _mainController.value,
              color: widget.color ?? AppTheme.lightTheme.colorScheme.primary,
            ),
          );
        },
      ),
    );
  }

  Widget _buildRipple() {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _mainController,
            builder: (context, child) {
              final delay = index * 0.3;
              final animationValue = (_mainController.value + delay) % 1.0;

              return Transform.scale(
                scale: animationValue,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: (widget.color ??
                              AppTheme.lightTheme.colorScheme.primary)
                          .withValues(alpha: 1.0 - animationValue),
                      width: 2.0,
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildPulse() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: (widget.color ?? AppTheme.lightTheme.colorScheme.primary)
                .withValues(alpha: 0.3 + (_pulseController.value * 0.7)),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              Icons.play_arrow,
              color: Colors.white,
              size: widget.size * 0.4,
            ),
          ),
        );
      },
    );
  }

  Widget _buildWave() {
    return SizedBox(
      width: widget.size * 2,
      height: widget.size,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(4, (index) {
          return AnimatedBuilder(
            animation: _mainController,
            builder: (context, child) {
              final delay = index * 0.1;
              final animationValue = (_mainController.value + delay) % 1.0;

              return Container(
                margin: EdgeInsets.symmetric(horizontal: 2),
                width: 6,
                height: widget.size * (0.2 + (animationValue * 0.8)),
                decoration: BoxDecoration(
                  color:
                      widget.color ?? AppTheme.lightTheme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildHeartbeat() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + (_pulseController.value * 0.4),
          child: Icon(
            Icons.favorite,
            color: widget.color ?? AppTheme.lightTheme.colorScheme.primary,
            size: widget.size,
          ),
        );
      },
    );
  }

  Widget _buildRetryButton() {
    return ElevatedButton.icon(
      onPressed: widget.onRetry,
      icon: Icon(Icons.refresh),
      label: Text('Retry'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

/// Loading type enum
enum LoadingType {
  spinner,
  dots,
  bars,
  circle,
  ripple,
  pulse,
  wave,
  heartbeat,
}

/// Custom painter for circle loading animation
class CircleLoadingPainter extends CustomPainter {
  final double progress;
  final Color color;

  CircleLoadingPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 4) / 2;

    // Draw background circle
    canvas.drawCircle(
        center, radius, paint..color = color.withValues(alpha: 0.2));

    // Draw progress arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -pi / 2,
      2 * pi * progress,
      false,
      paint..color = color,
    );
  }

  @override
  bool shouldRepaint(CircleLoadingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

/// Enhanced loading overlay widget
class EnhancedLoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final String? loadingMessage;
  final LoadingType loadingType;
  final Color? loadingColor;
  final bool dismissible;

  const EnhancedLoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.loadingMessage,
    this.loadingType = LoadingType.spinner,
    this.loadingColor,
    this.dismissible = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.5),
            child: GestureDetector(
              onTap: dismissible ? () {} : null,
              child: EnhancedLoadingWidget(
                message: loadingMessage,
                type: loadingType,
                color: loadingColor,
                size: 80.0,
              ),
            ),
          ),
      ],
    );
  }
}

/// Shimmer loading effect widget
class ShimmerLoadingWidget extends StatefulWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration duration;

  const ShimmerLoadingWidget({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<ShimmerLoadingWidget> createState() => _ShimmerLoadingWidgetState();
}

class _ShimmerLoadingWidgetState extends State<ShimmerLoadingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat();

    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              colors: [
                widget.baseColor ?? Colors.grey.shade300,
                widget.highlightColor ?? Colors.grey.shade100,
                widget.baseColor ?? Colors.grey.shade300,
              ],
              stops: [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}
