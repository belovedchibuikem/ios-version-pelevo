import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../core/app_export.dart';

class EnhancedSearchBar extends StatefulWidget {
  final String hintText;
  final Function(String) onChanged;
  final VoidCallback? onMoreOptionsTap;
  final TextEditingController? controller;
  final bool showClearButton;

  const EnhancedSearchBar({
    super.key,
    required this.hintText,
    required this.onChanged,
    this.onMoreOptionsTap,
    this.controller,
    this.showClearButton = true,
  });

  @override
  State<EnhancedSearchBar> createState() => _EnhancedSearchBarState();
}

class _EnhancedSearchBarState extends State<EnhancedSearchBar> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
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
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Search icon
          Container(
            margin: EdgeInsets.only(left: 4.w),
            child: Icon(
              Icons.search,
              size: 20,
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
          // Search input field
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: widget.onChanged,
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 3.w,
                  vertical: 2.h,
                ),
              ),
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurface,
              ),
            ),
          ),
          // Clear button (if text exists and showClearButton is true)
          if (widget.showClearButton && _controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _controller.clear();
                widget.onChanged('');
              },
              child: Container(
                margin: EdgeInsets.only(right: 2.w),
                padding: EdgeInsets.all(1.w),
                child: Icon(
                  Icons.clear,
                  size: 18,
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          // Three-dot menu
          GestureDetector(
            onTap: widget.onMoreOptionsTap,
            child: Container(
              margin: EdgeInsets.only(right: 4.w),
              padding: EdgeInsets.all(1.w),
              child: Icon(
                Icons.more_vert,
                size: 20,
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
