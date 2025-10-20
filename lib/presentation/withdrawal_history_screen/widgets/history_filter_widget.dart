import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

// lib/presentation/withdrawal_history_screen/widgets/history_filter_widget.dart

class HistoryFilterWidget extends StatefulWidget {
  final TextEditingController searchController;
  final String selectedStatus;
  final DateTimeRange? selectedDateRange;
  final double minAmount;
  final double maxAmount;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<DateTimeRange?> onDateRangeChanged;
  final ValueChanged2<double, double> onAmountRangeChanged;

  const HistoryFilterWidget({
    super.key,
    required this.searchController,
    required this.selectedStatus,
    required this.selectedDateRange,
    required this.minAmount,
    required this.maxAmount,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onDateRangeChanged,
    required this.onAmountRangeChanged,
  });

  @override
  State<HistoryFilterWidget> createState() => _HistoryFilterWidgetState();
}

class _HistoryFilterWidgetState extends State<HistoryFilterWidget> {
  bool _isFilterExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.colorScheme.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: widget.searchController,
            decoration: InputDecoration(
              hintText: 'Search by transaction ID, bank, or reference',
              prefixIcon: Container(
                padding: EdgeInsets.all(3.w),
                child: CustomIconWidget(
                  iconName: 'search',
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
              suffixIcon: widget.searchController.text.isNotEmpty
                  ? IconButton(
                      icon: CustomIconWidget(
                        iconName: 'clear',
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      onPressed: () {
                        widget.searchController.clear();
                        widget.onSearchChanged('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppTheme.lightTheme.colorScheme.outline
                      .withValues(alpha: 0.3),
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
            onChanged: widget.onSearchChanged,
          ),

          SizedBox(height: 3.h),

          // Filter Toggle
          GestureDetector(
            onTap: () {
              setState(() {
                _isFilterExpanded = !_isFilterExpanded;
              });
            },
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'tune',
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 20,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    'Advanced Filters',
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.lightTheme.colorScheme.primary,
                    ),
                  ),
                ),
                CustomIconWidget(
                  iconName: _isFilterExpanded ? 'expand_less' : 'expand_more',
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 20,
                ),
              ],
            ),
          ),

          // Expandable Filter Options
          if (_isFilterExpanded) ...[
            SizedBox(height: 3.h),

            // Status Filter
            Row(
              children: [
                Text(
                  'Status:',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildStatusChip('All'),
                        _buildStatusChip('Completed'),
                        _buildStatusChip('Pending'),
                        _buildStatusChip('Failed'),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 3.h),

            // Date Range Filter
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Date Range:',
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _selectDateRange,
                  icon: CustomIconWidget(
                    iconName: 'date_range',
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 16,
                  ),
                  label: Text(
                    widget.selectedDateRange != null
                        ? '${_formatDate(widget.selectedDateRange!.start)} - ${_formatDate(widget.selectedDateRange!.end)}'
                        : 'Select Range',
                    style: AppTheme.lightTheme.textTheme.bodySmall,
                  ),
                ),
                if (widget.selectedDateRange != null)
                  IconButton(
                    icon: CustomIconWidget(
                      iconName: 'clear',
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      size: 16,
                    ),
                    onPressed: () => widget.onDateRangeChanged(null),
                  ),
              ],
            ),

            SizedBox(height: 3.h),

            // Amount Range Filter
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Amount Range: ₦${widget.minAmount.toStringAsFixed(0)} - ₦${widget.maxAmount.toStringAsFixed(0)}',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2.h),
                RangeSlider(
                  values: RangeValues(widget.minAmount, widget.maxAmount),
                  min: 0,
                  max: 100000,
                  divisions: 20,
                  activeColor: AppTheme.lightTheme.colorScheme.primary,
                  inactiveColor: AppTheme.lightTheme.colorScheme.outline
                      .withValues(alpha: 0.3),
                  onChanged: (RangeValues values) {
                    widget.onAmountRangeChanged(values.start, values.end);
                  },
                ),
              ],
            ),

            SizedBox(height: 2.h),

            // Clear Filters Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _clearAllFilters,
                child: Text('Clear All Filters'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final isSelected = widget.selectedStatus == status;
    return Container(
      margin: EdgeInsets.only(right: 2.w),
      child: ChoiceChip(
        label: Text(
          status,
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: isSelected
                ? AppTheme.lightTheme.colorScheme.onPrimary
                : AppTheme.lightTheme.colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        selected: isSelected,
        selectedColor: AppTheme.lightTheme.colorScheme.primary,
        backgroundColor:
            AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.1),
        onSelected: (selected) {
          if (selected) {
            widget.onStatusChanged(status);
          }
        },
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: widget.selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppTheme.lightTheme.colorScheme.primary,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      widget.onDateRangeChanged(picked);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _clearAllFilters() {
    widget.searchController.clear();
    widget.onSearchChanged('');
    widget.onStatusChanged('All');
    widget.onDateRangeChanged(null);
    widget.onAmountRangeChanged(0, 100000);
  }
}

typedef ValueChanged2<T, U> = void Function(T value1, U value2);
