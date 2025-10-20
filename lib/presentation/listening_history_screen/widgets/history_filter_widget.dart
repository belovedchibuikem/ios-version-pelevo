import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class HistoryFilterWidget extends StatelessWidget {
  final String selectedFilter;
  final String searchQuery;
  final List<String> filterOptions;
  final Function(String) onFilterChanged;
  final Function(String) onSearchChanged;

  const HistoryFilterWidget({
    super.key,
    required this.selectedFilter,
    required this.searchQuery,
    required this.filterOptions,
    required this.onFilterChanged,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final currentTheme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: currentTheme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: currentTheme.colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Search Bar
          TextField(
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search episodes...',
              prefixIcon: Icon(
                Icons.search,
                color: currentTheme.colorScheme.onSurfaceVariant,
              ),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () => onSearchChanged(''),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: currentTheme.colorScheme.surfaceVariant,
            ),
          ),
          SizedBox(height: 2.h),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: filterOptions.map((filter) {
                final isSelected = filter == selectedFilter;
                return Padding(
                  padding: EdgeInsets.only(right: 2.w),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        onFilterChanged(filter);
                      }
                    },
                    backgroundColor: currentTheme.colorScheme.surfaceVariant,
                    selectedColor:
                        currentTheme.colorScheme.primary.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? currentTheme.colorScheme.primary
                          : currentTheme.colorScheme.onSurface,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? currentTheme.colorScheme.primary
                          : currentTheme.colorScheme.outline.withOpacity(0.3),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
