import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

// lib/presentation/recommendations_screen/widgets/recommendation_filter_widget.dart

class RecommendationFilterWidget extends StatelessWidget {
  final String selectedCategoryFilter;
  final String selectedDurationFilter;
  final Function(String) onCategoryFilterChanged;
  final Function(String) onDurationFilterChanged;

  const RecommendationFilterWidget({
    super.key,
    required this.selectedCategoryFilter,
    required this.selectedDurationFilter,
    required this.onCategoryFilterChanged,
    required this.onDurationFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Category:',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildCategoryFilterChip('all', 'All'),
                      SizedBox(width: 2.w),
                      _buildCategoryFilterChip('Business', 'Business'),
                      SizedBox(width: 2.w),
                      _buildCategoryFilterChip('Education', 'Education'),
                      SizedBox(width: 2.w),
                      _buildCategoryFilterChip('Comedy', 'Comedy'),
                      SizedBox(width: 2.w),
                      _buildCategoryFilterChip('Science', 'Science'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Text(
                'Duration:',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildDurationFilterChip('all', 'All'),
                      SizedBox(width: 2.w),
                      _buildDurationFilterChip('short', 'Short (<1h)'),
                      SizedBox(width: 2.w),
                      _buildDurationFilterChip('medium', 'Medium (1-2h)'),
                      SizedBox(width: 2.w),
                      _buildDurationFilterChip('long', 'Long (2h+)'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilterChip(String value, String label) {
    final isSelected = selectedCategoryFilter == value;
    return GestureDetector(
      onTap: () => onCategoryFilterChanged(value),
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

  Widget _buildDurationFilterChip(String value, String label) {
    final isSelected = selectedDurationFilter == value;
    return GestureDetector(
      onTap: () => onDurationFilterChanged(value),
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
