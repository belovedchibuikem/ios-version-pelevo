import 'package:flutter/material.dart';

import '../../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class AuthButtonWidget extends StatelessWidget {
  final bool isLoginMode;
  final bool isLoading;
  final bool isEnabled;
  final VoidCallback onPressed;

  const AuthButtonWidget({
    super.key,
    required this.isLoginMode,
    required this.isLoading,
    required this.isEnabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isEnabled && !isLoading ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled
              ? AppTheme.lightTheme.primaryColor
              : AppTheme.lightTheme.colorScheme.outline,
          foregroundColor: AppTheme.lightTheme.colorScheme.onPrimary,
          disabledBackgroundColor: AppTheme.lightTheme.colorScheme.outline,
          disabledForegroundColor:
              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          elevation: isEnabled ? 2 : 0,
          shadowColor: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.lightTheme.colorScheme.onPrimary,
                  ),
                ),
              )
            : Text(
                isLoginMode ? 'Login' : 'Create Account',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isEnabled
                      ? AppTheme.lightTheme.colorScheme.onPrimary
                      : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
      ),
    );
  }
}
