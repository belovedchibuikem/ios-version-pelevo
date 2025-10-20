import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

// lib/presentation/trending_podcasts_screen/widgets/trending_filter_widget.dart

class TrendingFilterWidget extends StatelessWidget {
  final String selectedTimeFilter;
  final String selectedSortFilter;
  final Function(String) onTimeFilterChanged;
  final Function(String) onSortFilterChanged;

  const TrendingFilterWidget({
    super.key,
    required this.selectedTimeFilter,
    required this.selectedSortFilter,
    required this.onTimeFilterChanged,
    required this.onSortFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Column(
        children: [
          // Sort by row removed
          // Row(
          //   children: [ ... ],
          // ),
        ],
      ),
    );
  }

  Widget _buildTimeFilterChip(String value, String label) {
    final isSelected = selectedTimeFilter == value;
    return GestureDetector(
      onTap: () => onTimeFilterChanged(value),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.lightTheme.colorScheme.primary
              : AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.lightTheme.colorScheme.primary
                : AppTheme.lightTheme.colorScheme.outline.withAlpha(77),
          ),
        ),
        child: Text(
          label,
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: isSelected
                ? AppTheme.lightTheme.colorScheme.onPrimary
                : AppTheme.lightTheme.colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSortFilterChip(String value, String label) {
    final isSelected = selectedSortFilter == value;
    return GestureDetector(
      onTap: () => onSortFilterChanged(value),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.lightTheme.colorScheme.secondary
              : AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.lightTheme.colorScheme.secondary
                : AppTheme.lightTheme.colorScheme.outline.withAlpha(77),
          ),
        ),
        child: Text(
          label,
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: isSelected
                ? AppTheme.lightTheme.colorScheme.onSecondary
                : AppTheme.lightTheme.colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
