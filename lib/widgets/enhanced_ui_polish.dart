import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/animation_service.dart';

/// Enhanced card widget with smooth animations and visual polish
class EnhancedCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Color? shadowColor;
  final double? elevation;
  final BorderRadius? borderRadius;
  final Border? border;
  final bool enableHoverEffect;
  final bool enablePressEffect;
  final bool enableShimmer;
  final Duration animationDuration;
  final Curve animationCurve;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const EnhancedCard({
    super.key,
    required this.child,
    this.margin,
    this.padding,
    this.color,
    this.shadowColor,
    this.elevation,
    this.borderRadius,
    this.border,
    this.enableHoverEffect = true,
    this.enablePressEffect = true,
    this.enableShimmer = false,
    this.animationDuration = const Duration(milliseconds: 200),
    this.animationCurve = Curves.easeOut,
    this.onTap,
    this.onLongPress,
  });

  @override
  State<EnhancedCard> createState() => _EnhancedCardState();
}

class _EnhancedCardState extends State<EnhancedCard>
    with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late AnimationController _pressController;
  late AnimationController _shimmerController;

  late Animation<double> _hoverAnimation;
  late Animation<double> _pressAnimation;
  late Animation<double> _shimmerAnimation;

  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _hoverController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _pressController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _hoverAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: widget.animationCurve,
    ));

    _pressAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _pressController,
      curve: Curves.easeInOut,
    ));

    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));

    if (widget.enableShimmer) {
      _shimmerController.repeat();
    }
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _pressController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.enablePressEffect) {
      setState(() => _isPressed = true);
      _pressController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.enablePressEffect) {
      setState(() => _isPressed = false);
      _pressController.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.enablePressEffect) {
      setState(() => _isPressed = false);
      _pressController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget card = Card(
      margin: widget.margin,
      color: widget.color,
      shadowColor: widget.shadowColor,
      elevation: widget.elevation,
      shape: RoundedRectangleBorder(
        borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
        side: widget.border?.top ?? BorderSide.none,
      ),
      child: Container(
        padding: widget.padding ?? const EdgeInsets.all(16),
        child: widget.child,
      ),
    );

    // Apply hover effect
    if (widget.enableHoverEffect) {
      card = MouseRegion(
        onEnter: (_) {
          setState(() => _isHovered = true);
          _hoverController.forward();
        },
        onExit: (_) {
          setState(() => _isHovered = false);
          _hoverController.reverse();
        },
        child: AnimatedBuilder(
          animation: _hoverAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _hoverAnimation.value,
              child: child,
            );
          },
          child: card,
        ),
      );
    }

    // Apply press effect
    if (widget.enablePressEffect) {
      card = AnimatedBuilder(
        animation: _pressAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pressAnimation.value,
            child: child,
          );
        },
        child: card,
      );
    }

    // Apply shimmer effect
    if (widget.enableShimmer) {
      card = AnimatedBuilder(
        animation: _shimmerAnimation,
        builder: (context, child) {
          return ShaderMask(
            shaderCallback: (bounds) {
              return LinearGradient(
                begin: Alignment(_shimmerAnimation.value - 1, 0),
                end: Alignment(_shimmerAnimation.value, 0),
                colors: [
                  Colors.transparent,
                  Colors.white.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
                stops: [0.0, 0.5, 1.0],
              ).createShader(bounds);
            },
            child: child,
          );
        },
        child: card,
      );
    }

    // Apply tap functionality
    if (widget.onTap != null || widget.onLongPress != null) {
      card = GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: card,
      );
    }

    return card;
  }
}

/// Enhanced button with smooth animations and visual feedback
class EnhancedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final ButtonStyle? style;
  final bool enableRipple;
  final bool enableScale;
  final bool enableHover;
  final Duration animationDuration;
  final Curve animationCurve;
  final double scaleFactor;
  final Color? rippleColor;

  const EnhancedButton({
    super.key,
    required this.child,
    this.onPressed,
    this.onLongPress,
    this.style,
    this.enableRipple = true,
    this.enableScale = true,
    this.enableHover = true,
    this.animationDuration = const Duration(milliseconds: 150),
    this.animationCurve = Curves.easeOut,
    this.scaleFactor = 0.95,
    this.rippleColor,
  });

  @override
  State<EnhancedButton> createState() => _EnhancedButtonState();
}

class _EnhancedButtonState extends State<EnhancedButton>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _hoverAnimation;

  bool _isPressed = false;
  bool _isHovered = false;

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

    _hoverController = AnimationController(
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

    _hoverAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: widget.animationCurve,
    ));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _hoverController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.enableScale) {
      setState(() => _isPressed = true);
      _scaleController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.enableScale) {
      setState(() => _isPressed = false);
      _scaleController.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.enableScale) {
      setState(() => _isPressed = false);
      _scaleController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget button = ElevatedButton(
      onPressed: widget.onPressed,
      onLongPress: widget.onLongPress,
      style: widget.style,
      child: widget.child,
    );

    // Apply scale effect
    if (widget.enableScale) {
      button = AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: button,
      );
    }

    // Apply hover effect
    if (widget.enableHover) {
      button = MouseRegion(
        onEnter: (_) {
          setState(() => _isHovered = true);
          _hoverController.forward();
        },
        onExit: (_) {
          setState(() => _isHovered = false);
          _hoverController.reverse();
        },
        child: AnimatedBuilder(
          animation: _hoverAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _hoverAnimation.value,
              child: child,
            );
          },
          child: button,
        ),
      );
    }

    // Apply tap functionality
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: button,
    );
  }
}

/// Enhanced list tile with smooth animations
class EnhancedListTile extends StatefulWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final bool isThreeLine;
  final bool dense;
  final EdgeInsetsGeometry? contentPadding;
  final bool enabled;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onSecondaryTap;
  final bool enableSlideIn;
  final bool enableFadeIn;
  final Duration animationDuration;
  final Curve animationCurve;
  final int animationIndex;

  const EnhancedListTile({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.isThreeLine = false,
    this.dense = false,
    this.contentPadding,
    this.enabled = true,
    this.onTap,
    this.onLongPress,
    this.onSecondaryTap,
    this.enableSlideIn = true,
    this.enableFadeIn = true,
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeOut,
    this.animationIndex = 0,
  });

  @override
  State<EnhancedListTile> createState() => _EnhancedListTileState();
}

class _EnhancedListTileState extends State<EnhancedListTile>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Interval(
        widget.animationIndex * 0.1,
        (widget.animationIndex * 0.1) + 0.8,
        curve: widget.animationCurve,
      ),
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Interval(
        widget.animationIndex * 0.1,
        (widget.animationIndex * 0.1) + 0.8,
        curve: widget.animationCurve,
      ),
    ));

    // Start animations with staggered delay
    Future.delayed(Duration(milliseconds: widget.animationIndex * 50), () {
      if (mounted) {
        _slideController.forward();
        _fadeController.forward();
      }
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget tile = ListTile(
      leading: widget.leading,
      title: widget.title,
      subtitle: widget.subtitle,
      trailing: widget.trailing,
      isThreeLine: widget.isThreeLine,
      dense: widget.dense,
      contentPadding: widget.contentPadding,
      enabled: widget.enabled,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
    );

    // Apply slide animation
    if (widget.enableSlideIn) {
      tile = SlideTransition(
        position: _slideAnimation,
        child: tile,
      );
    }

    // Apply fade animation
    if (widget.enableFadeIn) {
      tile = FadeTransition(
        opacity: _fadeAnimation,
        child: tile,
      );
    }

    return tile;
  }
}

/// Enhanced container with gradient and shadow effects
class EnhancedContainer extends StatelessWidget {
  final Widget? child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Decoration? decoration;
  final Color? color;
  final List<Color>? gradientColors;
  final AlignmentGeometry? gradientBegin;
  final AlignmentGeometry? gradientEnd;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;
  final Border? border;
  final bool enableGradient;
  final bool enableShadow;
  final bool enableBorder;

  const EnhancedContainer({
    super.key,
    this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.decoration,
    this.color,
    this.gradientColors,
    this.gradientBegin,
    this.gradientEnd,
    this.borderRadius,
    this.boxShadow,
    this.border,
    this.enableGradient = false,
    this.enableShadow = true,
    this.enableBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    Decoration? finalDecoration = decoration;

    if (finalDecoration == null) {
      finalDecoration = BoxDecoration(
        color: enableGradient ? null : color,
        gradient: enableGradient && gradientColors != null
            ? LinearGradient(
                colors: gradientColors!,
                begin: gradientBegin ?? Alignment.topLeft,
                end: gradientEnd ?? Alignment.bottomRight,
              )
            : null,
        borderRadius: borderRadius,
        boxShadow: enableShadow
            ? (boxShadow ??
                [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ])
            : null,
        border: enableBorder ? border : null,
      );
    }

    return Container(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      decoration: finalDecoration,
      child: child,
    );
  }
}

/// Enhanced text with custom styling and animations
class EnhancedText extends StatefulWidget {
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;
  final bool enableTypewriter;
  final bool enableGlow;
  final bool enableGradient;
  final List<Color>? gradientColors;
  final Duration typewriterDuration;
  final Color? glowColor;
  final double glowRadius;

  const EnhancedText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.enableTypewriter = false,
    this.enableGlow = false,
    this.enableGradient = false,
    this.gradientColors,
    this.typewriterDuration = const Duration(milliseconds: 1000),
    this.glowColor,
    this.glowRadius = 10.0,
  });

  @override
  State<EnhancedText> createState() => _EnhancedTextState();
}

class _EnhancedTextState extends State<EnhancedText>
    with TickerProviderStateMixin {
  late AnimationController _typewriterController;
  late Animation<int> _typewriterAnimation;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    if (widget.enableTypewriter) {
      _typewriterController = AnimationController(
        duration: widget.typewriterDuration,
        vsync: this,
      );

      _typewriterAnimation = IntTween(
        begin: 0,
        end: widget.data.length,
      ).animate(CurvedAnimation(
        parent: _typewriterController,
        curve: Curves.easeOut,
      ));

      _typewriterController.forward();
    }

    if (widget.enableGlow) {
      _glowController = AnimationController(
        duration: const Duration(milliseconds: 2000),
        vsync: this,
      );

      _glowAnimation = Tween<double>(
        begin: 0.5,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _glowController,
        curve: Curves.easeInOut,
      ));

      _glowController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _typewriterController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget text = Text(
      widget.enableTypewriter
          ? widget.data.substring(0, _typewriterAnimation.value)
          : widget.data,
      style: widget.style,
      textAlign: widget.textAlign,
      overflow: widget.overflow,
      maxLines: widget.maxLines,
    );

    // Apply glow effect
    if (widget.enableGlow) {
      text = AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return ShaderMask(
            shaderCallback: (bounds) {
              return RadialGradient(
                center: Alignment.center,
                radius: widget.glowRadius * _glowAnimation.value,
                colors: [
                  widget.glowColor ?? Colors.white,
                  Colors.transparent,
                ],
              ).createShader(bounds);
            },
            child: child,
          );
        },
        child: text,
      );
    }

    // Apply gradient effect
    if (widget.enableGradient && widget.gradientColors != null) {
      text = ShaderMask(
        shaderCallback: (bounds) {
          return LinearGradient(
            colors: widget.gradientColors!,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds);
        },
        child: text,
      );
    }

    return text;
  }
}
