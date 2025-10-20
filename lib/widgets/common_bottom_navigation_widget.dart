import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../core/app_export.dart';

// lib/widgets/common_bottom_navigation_widget.dart

class CommonBottomNavigationWidget extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabSelected;

  const CommonBottomNavigationWidget({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: 8.h,
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: AppTheme.lightTheme.colorScheme.shadow.withAlpha(26),
              blurRadius: 4,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, 'home', 'Home'),
            _buildNavItem(1, 'monetization_on', 'Earn'),
            _buildNavItem(2, 'library_books', 'Library'),
            _buildNavItem(3, 'account_balance_wallet', 'Wallet'),
            _buildNavItem(4, 'person', 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String iconName, String label) {
    final bool isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTabSelected(index),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 0.3.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomIconWidget(
              iconName: iconName,
              color: isSelected
                  ? AppTheme.lightTheme.colorScheme.primary
                  : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 24,
            ),
            SizedBox(height: 0.2.h),
            Text(
              label,
              style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                color: isSelected
                    ? AppTheme.lightTheme.colorScheme.primary
                    : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 8.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
