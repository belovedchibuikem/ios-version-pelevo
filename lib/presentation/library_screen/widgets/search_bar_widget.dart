import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

// lib/presentation/library_screen/widgets/search_bar_widget.dart

class SearchBarWidget extends StatefulWidget {
  final String hintText;
  final Function(String) onChanged;
  final VoidCallback? onFilterTap;

  const SearchBarWidget({
    super.key,
    required this.hintText,
    required this.onChanged,
    this.onFilterTap,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color:
                AppTheme.lightTheme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: widget.onChanged,
              decoration: InputDecoration(
                hintText: widget.hintText,
                prefixIcon: Padding(
                  padding: EdgeInsets.all(3.w),
                  child: CustomIconWidget(
                    iconName: 'search',
                    size: 24,
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _controller.clear();
                          widget.onChanged('');
                        },
                        icon: CustomIconWidget(
                          iconName: 'clear',
                          size: 20,
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        ),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 4.w,
                  vertical: 2.h,
                ),
              ),
              style: AppTheme.lightTheme.textTheme.bodyMedium,
            ),
          ),
          if (widget.onFilterTap != null)
            Container(
              margin: EdgeInsets.only(right: 3.w),
              child: IconButton(
                onPressed: widget.onFilterTap,
                icon: CustomIconWidget(
                  iconName: 'tune',
                  size: 24,
                  color: AppTheme.lightTheme.colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
