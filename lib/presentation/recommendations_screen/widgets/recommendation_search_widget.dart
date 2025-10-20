import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

// lib/presentation/recommendations_screen/widgets/recommendation_search_widget.dart

class RecommendationSearchWidget extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onChanged;
  final bool isActive;

  const RecommendationSearchWidget({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search recommendations...',
          hintStyle: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color:
                AppTheme.lightTheme.colorScheme.onSurfaceVariant.withAlpha(153),
          ),
          prefixIcon: Padding(
            padding: EdgeInsets.all(3.w),
            child: CustomIconWidget(
              iconName: 'search',
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant
                  .withAlpha(153),
              size: 20,
            ),
          ),
          suffixIcon: isActive
              ? GestureDetector(
                  onTap: () {
                    controller.clear();
                    onChanged('');
                  },
                  child: Padding(
                    padding: EdgeInsets.all(3.w),
                    child: CustomIconWidget(
                      iconName: 'clear',
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant
                          .withAlpha(153),
                      size: 20,
                    ),
                  ),
                )
              : null,
          filled: true,
          fillColor: AppTheme.lightTheme.colorScheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppTheme.lightTheme.colorScheme.outline.withAlpha(51),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppTheme.lightTheme.colorScheme.outline.withAlpha(51),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppTheme.lightTheme.colorScheme.primary,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}
