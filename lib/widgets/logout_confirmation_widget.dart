import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../core/services/logout_service.dart';
import '../core/navigation_service.dart';
import '../core/routes/app_routes.dart';
import 'custom_icon_widget.dart';

class LogoutConfirmationWidget {
  static Future<bool> showLogoutDialog(BuildContext context) async {
    final currentTheme = Theme.of(context);

    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: currentTheme.colorScheme.error.withAlpha(26),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: CustomIconWidget(
                      iconName: 'logout',
                      size: 24,
                      color: currentTheme.colorScheme.error,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Text(
                      'Logout',
                      style: currentTheme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Are you sure you want to logout?',
                    style: currentTheme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Container(
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color:
                          currentTheme.colorScheme.errorContainer.withAlpha(50),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: currentTheme.colorScheme.error.withAlpha(50),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CustomIconWidget(
                              iconName: 'info',
                              size: 16,
                              color: currentTheme.colorScheme.error,
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              'This will:',
                              style:
                                  currentTheme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: currentTheme.colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 1.h),
                        _buildLogoutItem(
                          context,
                          'Clear all your data',
                          'profile_data',
                        ),
                        _buildLogoutItem(
                          context,
                          'Sign you out of the app',
                          'security',
                        ),
                        _buildLogoutItem(
                          context,
                          'Revoke your session',
                          'lock',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Cancel',
                    style: currentTheme.textTheme.labelLarge?.copyWith(
                      color: currentTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: currentTheme.colorScheme.error,
                    foregroundColor: currentTheme.colorScheme.onError,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Logout',
                    style: currentTheme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  static Widget _buildLogoutItem(
    BuildContext context,
    String text,
    String iconName,
  ) {
    final currentTheme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: iconName,
            size: 14,
            color: currentTheme.colorScheme.error,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              text,
              style: currentTheme.textTheme.bodySmall?.copyWith(
                color: currentTheme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static void showLogoutProgress(BuildContext context) {
    final currentTheme = Theme.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    currentTheme.colorScheme.primary,
                  ),
                  strokeWidth: 3,
                ),
              ),
              SizedBox(height: 3.h),
              Text(
                'Logging out...',
                style: currentTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                'Please wait while we secure your data',
                style: currentTheme.textTheme.bodySmall?.copyWith(
                  color: currentTheme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 2.h),
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color:
                      currentTheme.colorScheme.primaryContainer.withAlpha(50),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomIconWidget(
                      iconName: 'security',
                      size: 16,
                      color: currentTheme.colorScheme.primary,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Securing your data',
                      style: currentTheme.textTheme.bodySmall?.copyWith(
                        color: currentTheme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static void showLogoutResult(
    BuildContext context,
    LogoutResult result,
  ) {
    final currentTheme = Theme.of(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            CustomIconWidget(
              iconName: result.success ? 'check_circle' : 'warning',
              size: 20,
              color: Colors.white,
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    result.success
                        ? 'Successfully logged out'
                        : 'Logout completed',
                    style: currentTheme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  if (!result.backendSuccess)
                    Text(
                      'Backend logout failed, but local data cleared',
                      style: currentTheme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withAlpha(200),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: result.success
            ? currentTheme.colorScheme.primary
            : currentTheme.colorScheme.tertiary,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: result.success ? 2 : 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  static void showLogoutError(
    BuildContext context,
    String error,
    VoidCallback? onForceLogout,
  ) {
    final currentTheme = Theme.of(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            CustomIconWidget(
              iconName: 'error',
              size: 20,
              color: Colors.white,
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: Text('Logout failed: $error'),
            ),
          ],
        ),
        backgroundColor: currentTheme.colorScheme.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: onForceLogout != null
            ? SnackBarAction(
                label: 'Force Logout',
                textColor: Colors.white,
                onPressed: onForceLogout,
              )
            : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
