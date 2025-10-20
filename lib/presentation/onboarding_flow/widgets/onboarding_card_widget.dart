import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

// lib/presentation/onboarding_flow/widgets/onboarding_card_widget.dart

class OnboardingCardWidget extends StatefulWidget {
  final String title;
  final String description;
  final String imageUrl;
  final String buttonText;
  final bool isLastPage;
  final bool isAnimating;
  final VoidCallback onButtonPressed;

  const OnboardingCardWidget({
    super.key,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.buttonText,
    required this.isLastPage,
    required this.isAnimating,
    required this.onButtonPressed,
  });

  @override
  State<OnboardingCardWidget> createState() => _OnboardingCardWidgetState();
}

class _OnboardingCardWidgetState extends State<OnboardingCardWidget>
    with TickerProviderStateMixin {
  late AnimationController _contentAnimationController;
  late AnimationController _buttonAnimationController;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideUpAnimation;
  late Animation<double> _buttonScaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
  }

  void _setupAnimations() {
    _contentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _fadeInAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _contentAnimationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));

    _slideUpAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentAnimationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
    ));

    _buttonScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _buttonAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  void _startAnimations() {
    _contentAnimationController.forward();
  }

  void _onButtonTap() {
    _buttonAnimationController.forward().then((_) {
      _buttonAnimationController.reverse();
      widget.onButtonPressed();
    });
  }

  @override
  void dispose() {
    _contentAnimationController.dispose();
    _buttonAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _contentAnimationController,
      builder: (context, child) {
        return SlideTransition(
          position: _slideUpAnimation,
          child: FadeTransition(
            opacity: _fadeInAnimation,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 6.w),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.top -
                        MediaQuery.of(context).padding.bottom -
                        120, // Account for skip button and page indicator
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Hero Illustration with enhanced shadow
                        Container(
                          width: 85.w,
                          height: MediaQuery.of(context).size.height *
                              0.35, // More responsive height
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.lightTheme.colorScheme.shadow
                                    .withValues(alpha: 0.15),
                                blurRadius: 25,
                                offset: const Offset(0, 12),
                                spreadRadius: 2,
                              ),
                              BoxShadow(
                                color: AppTheme.lightTheme.colorScheme.primary
                                    .withValues(alpha: 0.1),
                                blurRadius: 40,
                                offset: const Offset(0, 20),
                                spreadRadius: -5,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Stack(
                              children: [
                                CustomImageWidget(
                                  imageUrl: widget.imageUrl,
                                  width: 85.w,
                                  height:
                                      MediaQuery.of(context).size.height * 0.35,
                                  fit: BoxFit.cover,
                                ),
                                // Subtle overlay for better text readability
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24),
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withValues(alpha: 0.1),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: 4.h),

                        // Title with enhanced typography
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 2.w),
                          child: Text(
                            widget.title,
                            style: AppTheme.lightTheme.textTheme.headlineMedium
                                ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppTheme.lightTheme.colorScheme.onSurface,
                              height: 1.2,
                              letterSpacing: -0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        SizedBox(height: 2.h),

                        // Description with better spacing
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4.w),
                          child: Text(
                            widget.description,
                            style: AppTheme.lightTheme.textTheme.bodyLarge
                                ?.copyWith(
                              color: AppTheme
                                  .lightTheme.colorScheme.onSurfaceVariant,
                              height: 1.6,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        SizedBox(height: 3.h),

                        // Enhanced Action Button
                        AnimatedBuilder(
                          animation: _buttonAnimationController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _buttonScaleAnimation.value,
                              child: Container(
                                width: double.infinity,
                                height: 56,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: LinearGradient(
                                    colors: [
                                      AppTheme.lightTheme.colorScheme.primary,
                                      AppTheme.lightTheme.colorScheme
                                          .primaryContainer,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme
                                          .lightTheme.colorScheme.primary
                                          .withValues(alpha: 0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed:
                                      widget.isAnimating ? null : _onButtonTap,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (widget.isAnimating) ...[
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              Colors.white
                                                  .withValues(alpha: 0.8),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                      ],
                                      Text(
                                        widget.buttonText,
                                        style: AppTheme
                                            .lightTheme.textTheme.labelLarge
                                            ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                      if (!widget.isAnimating) ...[
                                        const SizedBox(width: 8),
                                        CustomIconWidget(
                                          iconName: 'arrow_forward',
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        // Add bottom padding to ensure content is not cut off
                        SizedBox(height: 2.h),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
