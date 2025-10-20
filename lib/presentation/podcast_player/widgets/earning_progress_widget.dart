import 'package:flutter/material.dart';

import '../../../../core/app_export.dart';

class EarningProgressWidget extends StatefulWidget {
  final double earnedCoins;
  final double totalPotentialCoins;
  final bool isActive;

  const EarningProgressWidget({
    super.key,
    required this.earnedCoins,
    required this.totalPotentialCoins,
    required this.isActive,
  });

  @override
  State<EarningProgressWidget> createState() => _EarningProgressWidgetState();
}

class _EarningProgressWidgetState extends State<EarningProgressWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    if (widget.isActive) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(EarningProgressWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isActive && oldWidget.isActive) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double progress = widget.totalPotentialCoins > 0
        ? (widget.earnedCoins / widget.totalPotentialCoins).clamp(0.0, 1.0)
        : 0.0;

    // Determine colors based on theme
    final bool isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final Color primaryTextColor =
        isDarkTheme ? Colors.white : AppTheme.lightTheme.colorScheme.onSurface;
    final Color secondaryTextColor = isDarkTheme
        ? Colors.white.withValues(alpha: 0.7)
        : AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.7);
    final Color tertiaryTextColor = isDarkTheme
        ? Colors.white.withValues(alpha: 0.9)
        : AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.9);
    final Color progressBackgroundColor = isDarkTheme
        ? Colors.white.withValues(alpha: 0.2)
        : AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.2);
    final Color disabledIconColor = isDarkTheme
        ? Colors.white.withValues(alpha: 0.5)
        : AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.5);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.successLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.successLight.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: widget.isActive ? _pulseAnimation.value : 1.0,
                        child: CustomIconWidget(
                          iconName: 'monetization_on',
                          color: widget.isActive
                              ? AppTheme.successLight
                              : disabledIconColor,
                          size: 20,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Earning Progress',
                    style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                      color: primaryTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.isActive
                      ? AppTheme.successLight.withValues(alpha: 0.2)
                      : progressBackgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.isActive ? 'ACTIVE' : 'PAUSED',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: widget.isActive
                        ? AppTheme.successLight
                        : secondaryTextColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Progress bar
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: progressBackgroundColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(
                  widget.isActive ? AppTheme.successLight : disabledIconColor,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Coins info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Earned',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: secondaryTextColor,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'toll',
                        color: AppTheme.successLight,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.earnedCoins.toStringAsFixed(1),
                        style:
                            AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                          color: primaryTextColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Potential',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: secondaryTextColor,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'toll',
                        color: secondaryTextColor,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.totalPotentialCoins.toStringAsFixed(1),
                        style:
                            AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                          color: tertiaryTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          if (!widget.isActive)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'info_outline',
                    color: AppTheme.warningLight,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Earning paused. Resume playback to continue earning.',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.warningLight,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
