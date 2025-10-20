import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../core/app_export.dart';

// lib/widgets/back_to_start_button_widget.dart

class BackToStartButtonWidget extends StatelessWidget {
  final VoidCallback? onPressed;
  final String? label;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? margin;
  final bool showIcon;
  final bool isFloating;

  const BackToStartButtonWidget({
    super.key,
    this.onPressed,
    this.label,
    this.backgroundColor,
    this.foregroundColor,
    this.margin,
    this.showIcon = true,
    this.isFloating = false,
  });

  @override
  Widget build(BuildContext context) {
    final navigationService = NavigationService();
    final canGoBack = navigationService.canGoBackToStart();

    if (!canGoBack) {
      return const SizedBox.shrink();
    }

    if (isFloating) {
      return Container(
        margin: margin ?? EdgeInsets.all(4.w),
        child: FloatingActionButton.extended(
          onPressed: onPressed ?? () => navigationService.goBackToStart(),
          backgroundColor:
              backgroundColor ?? AppTheme.lightTheme.colorScheme.primary,
          foregroundColor:
              foregroundColor ?? AppTheme.lightTheme.colorScheme.onPrimary,
          icon: showIcon
              ? CustomIconWidget(
                  iconName: 'home',
                  color: foregroundColor ??
                      AppTheme.lightTheme.colorScheme.onPrimary,
                  size: 20,
                )
              : null,
          label: Text(
            label ?? 'Back to Start',
            style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
              color:
                  foregroundColor ?? AppTheme.lightTheme.colorScheme.onPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Container(
      margin: margin ?? EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: ElevatedButton.icon(
        onPressed: onPressed ?? () => navigationService.goBackToStart(),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              backgroundColor ?? AppTheme.lightTheme.colorScheme.secondary,
          foregroundColor:
              foregroundColor ?? AppTheme.lightTheme.colorScheme.onSecondary,
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        icon: showIcon
            ? CustomIconWidget(
                iconName: 'home',
                color: foregroundColor ??
                    AppTheme.lightTheme.colorScheme.onSecondary,
                size: 20,
              )
            : const SizedBox.shrink(),
        label: Text(
          label ?? 'Back to Start',
          style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
            color:
                foregroundColor ?? AppTheme.lightTheme.colorScheme.onSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
