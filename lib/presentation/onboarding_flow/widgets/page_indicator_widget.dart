// lib/presentation/onboarding_flow/widgets/page_indicator_widget.dart
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class PageIndicatorWidget extends StatefulWidget {
  final int currentPage;
  final int totalPages;

  const PageIndicatorWidget({
    super.key,
    required this.currentPage,
    required this.totalPages,
  });

  @override
  State<PageIndicatorWidget> createState() => _PageIndicatorWidgetState();
}

class _PageIndicatorWidgetState extends State<PageIndicatorWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<AnimationController> _dotControllers;
  late List<Animation<double>> _dotAnimations;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _dotControllers = List.generate(
      widget.totalPages,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 400),
        vsync: this,
      ),
    );

    _dotAnimations = _dotControllers
        .map((controller) => Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: controller, curve: Curves.elasticOut)))
        .toList();

    // Animate the current dot
    _dotControllers[widget.currentPage].forward();
  }

  @override
  void didUpdateWidget(PageIndicatorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPage != widget.currentPage) {
      // Reset previous dot
      if (oldWidget.currentPage < _dotControllers.length) {
        _dotControllers[oldWidget.currentPage].reverse();
      }
      // Animate new current dot
      if (widget.currentPage < _dotControllers.length) {
        _dotControllers[widget.currentPage].forward();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    for (var controller in _dotControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color:
                AppTheme.lightTheme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          widget.totalPages,
          (index) => AnimatedBuilder(
            animation: _dotAnimations[index],
            builder: (context, child) {
              final isActive = index == widget.currentPage;
              final animation = _dotAnimations[index].value;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 8.w : 2.5.w,
                height: 1.2.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: isActive
                      ? AppTheme.lightTheme.colorScheme.primary
                      : AppTheme.lightTheme.colorScheme.outline
                          .withValues(alpha: 0.3),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: AppTheme.lightTheme.colorScheme.primary
                                .withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: isActive
                    ? Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.lightTheme.colorScheme.primary,
                              AppTheme.lightTheme.colorScheme.primaryContainer,
                            ],
                          ),
                        ),
                      )
                    : null,
              );
            },
          ),
        ),
      ),
    );
  }
}
