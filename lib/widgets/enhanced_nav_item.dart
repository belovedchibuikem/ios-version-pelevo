import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import '../core/app_export.dart';
import '../theme/navigation_theme.dart';

/// Enhanced Navigation Item Widget
///
/// Features:
/// - Smooth animations and transitions
/// - Enhanced visual feedback
/// - Badge support for notifications
/// - Responsive design
/// - Accessibility support
class EnhancedNavItem extends StatefulWidget {
  final int index;
  final String iconName;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool showBadge;
  final int? badgeCount;
  final bool isEnabled;
  final String? tooltip;

  const EnhancedNavItem({
    super.key,
    required this.index,
    required this.iconName,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.showBadge = false,
    this.badgeCount,
    this.isEnabled = true,
    this.tooltip,
  });

  @override
  State<EnhancedNavItem> createState() => _EnhancedNavItemState();
}

class _EnhancedNavItemState extends State<EnhancedNavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _colorAnimation;
  late Animation<double> _elevationAnimation;

  bool _isPressed = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _colorAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _elevationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    // Start animation if selected
    if (widget.isSelected) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(EnhancedNavItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Animate when selection changes
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!widget.isEnabled) return;

    // Haptic feedback
    HapticFeedback.lightImpact();

    // Animate tap
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    // Execute callback
    widget.onTap();
  }

  void _handleLongPress() {
    if (!widget.isEnabled) return;

    HapticFeedback.mediumImpact();

    // Show tooltip or context menu
    if (widget.tooltip != null) {
      _showTooltip();
    }
  }

  void _showTooltip() {
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);

    final tooltipEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx + renderBox.size.width / 2 - 50,
        top: position.dy - 60,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              widget.tooltip!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(tooltipEntry);

    // Auto-hide after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      tooltipEntry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = NavigationTheme.isDarkMode(context);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: widget.isSelected
                      ? colorScheme.primary
                          .withOpacity(0.3 * _elevationAnimation.value)
                      : Colors.transparent,
                  blurRadius: 8 * _elevationAnimation.value,
                  offset: Offset(0, 4 * _elevationAnimation.value),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _handleTap,
                onLongPress: _handleLongPress,
                onHover: (hovered) {
                  setState(() {
                    _isHovered = hovered;
                  });
                },
                borderRadius: BorderRadius.circular(16),
                splashColor: colorScheme.primary.withOpacity(0.1),
                highlightColor: colorScheme.primary.withOpacity(0.05),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 4.w,
                    vertical: 1.h,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: _getBackgroundColor(colorScheme),
                    border: Border.all(
                      color: _getBorderColor(colorScheme),
                      width: widget.isSelected ? 2.0 : 1.0,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon with badge
                      Stack(
                        children: [
                          // Main icon
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            child: CustomIconWidget(
                              iconName: widget.iconName,
                              color: _getIconColor(colorScheme),
                              size: _getIconSize(),
                            ),
                          ),

                          // Badge
                          if (widget.showBadge && widget.badgeCount != null)
                            Positioned(
                              right: -2,
                              top: -2,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: colorScheme.error,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  widget.badgeCount! > 99
                                      ? '99+'
                                      : widget.badgeCount.toString(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),

                      SizedBox(height: 0.5.h),

                      // Label
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: _getLabelStyle(colorScheme),
                        child: Text(
                          widget.label,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getBackgroundColor(ColorScheme colorScheme) {
    if (!widget.isEnabled) {
      return colorScheme.surface.withOpacity(0.5);
    }

    if (widget.isSelected) {
      return colorScheme.primaryContainer.withOpacity(0.1);
    }

    if (_isPressed) {
      return colorScheme.primary.withOpacity(0.05);
    }

    if (_isHovered) {
      return colorScheme.primary.withOpacity(0.02);
    }

    return Colors.transparent;
  }

  Color _getBorderColor(ColorScheme colorScheme) {
    if (!widget.isEnabled) {
      return colorScheme.outline.withOpacity(0.3);
    }

    if (widget.isSelected) {
      return colorScheme.primary;
    }

    if (_isHovered) {
      return colorScheme.primary.withOpacity(0.3);
    }

    return Colors.transparent;
  }

  Color _getIconColor(ColorScheme colorScheme) {
    if (!widget.isEnabled) {
      return colorScheme.onSurface.withOpacity(0.3);
    }

    if (widget.isSelected) {
      return colorScheme.primary;
    }

    if (_isHovered) {
      return colorScheme.primary.withOpacity(0.7);
    }

    return colorScheme.onSurfaceVariant;
  }

  TextStyle _getLabelStyle(ColorScheme colorScheme) {
    if (!widget.isEnabled) {
      return TextStyle(
        color: colorScheme.onSurface.withOpacity(0.3),
        fontSize: 10.sp,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.3,
        height: 1.2,
      );
    }

    if (widget.isSelected) {
      return TextStyle(
        color: colorScheme.primary,
        fontSize: 10.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        height: 1.2,
      );
    }

    if (_isHovered) {
      return TextStyle(
        color: colorScheme.primary.withOpacity(0.7),
        fontSize: 10.sp,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
        height: 1.2,
      );
    }

    return TextStyle(
      color: colorScheme.onSurfaceVariant,
      fontSize: 10.sp,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.3,
      height: 1.2,
    );
  }

  double _getIconSize() {
    if (widget.isSelected) {
      return 28.0;
    }

    if (_isHovered) {
      return 26.0;
    }

    return 24.0;
  }
}
