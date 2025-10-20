import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../core/first_launch_service.dart';
import '../../models/onboarding_content.dart';
import './widgets/onboarding_card_widget.dart';
import './widgets/page_indicator_widget.dart';

// lib/presentation/onboarding_flow/onboarding_flow.dart

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isAnimating = false;
  late AnimationController _slideAnimationController;
  late Animation<Offset> _slideAnimation;
  late List<OnboardingContent> _onboardingContents = [];
  bool _isLoading = true;

  final List<Map<String, dynamic>> _onboardingData = [
    {
      "id": 1,
      "title": "Discover Amazing Podcasts",
      "description":
          "Explore thousands of podcasts across various categories and find your next favorite show with personalized recommendations.",
      "image": "assets/images/img1.png",
      "buttonText": "Next"
    },
    {
      "id": 2,
      "title": "Earn While You Listen",
      "description":
          "Get rewarded with convertible coins for listening to monetized podcast content from start to finish. Turn your listening time into earnings.",
      "image": "assets/images/img2.png",
      "buttonText": "Next"
    },
    {
      "id": 3,
      "title": "Convert Coins to Cash",
      "description":
          "Transform your earned coins into Nigerian Naira and withdraw directly to your bank account. Start earning today!",
      "image": "assets/images/img3.png",
      "buttonText": "Next"
    },
    {
      "id": 4,
      "title": "Start Your Podcast Journey",
      "description":
          "You're all set! Start exploring amazing podcasts, discover new content, and begin your personalized listening experience.",
      "image": "assets/images/img4.png",
      "buttonText": "Get Started"
    }
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadOnboardingData();
  }

  void _loadOnboardingData() {
    try {
      setState(() {
        _onboardingContents = _onboardingData
            .map((data) => OnboardingContent.fromJson(data))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading onboarding data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _setupAnimations() {
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeInOut,
    ));

    // Start animation immediately
    _slideAnimationController.forward();
  }

  void _nextPage() async {
    if (_isAnimating) return;

    setState(() {
      _isAnimating = true;
    });

    HapticFeedback.lightImpact();

    if (_currentPage < _onboardingContents.length - 1) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      await _completeOnboarding();
    }

    setState(() {
      _isAnimating = false;
    });
  }

  void _skipOnboarding() async {
    if (_isAnimating) return;

    HapticFeedback.lightImpact();
    await FirstLaunchService.setOnboardingSkipped();
    _navigateToNextScreen();
  }

  Future<void> _completeOnboarding() async {
    await FirstLaunchService.setOnboardingCompleted();
    _navigateToNextScreen();
  }

  void _navigateToNextScreen() {
    // Add a fade out animation before navigation
    _slideAnimationController.reverse().then((_) {
      Navigator.pushReplacementNamed(context, '/authentication-screen');
    });
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    _slideAnimationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _slideAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: AppTheme.lightTheme.colorScheme.primary,
                ),
              )
            : _onboardingContents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppTheme.errorLight,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load onboarding content',
                          style: AppTheme.lightTheme.textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _skipOnboarding,
                          child: const Text('Continue to App'),
                        ),
                      ],
                    ),
                  )
                : Stack(
                    children: [
                      // Background gradient
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.lightTheme.scaffoldBackgroundColor,
                              AppTheme.lightTheme.colorScheme.primaryContainer
                                  .withValues(alpha: 0.1),
                            ],
                          ),
                        ),
                      ),

                      // Main content with slide animation
                      SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          children: [
                            // Skip Button with enhanced design
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 16, right: 16),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme
                                        .lightTheme.colorScheme.surface
                                        .withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme
                                            .lightTheme.colorScheme.shadow
                                            .withValues(alpha: 0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: TextButton(
                                    onPressed:
                                        _isAnimating ? null : _skipOnboarding,
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppTheme
                                          .lightTheme.colorScheme.primary,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 10),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Skip',
                                          style: AppTheme
                                              .lightTheme.textTheme.labelLarge
                                              ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme
                                                .lightTheme.colorScheme.primary,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        CustomIconWidget(
                                          iconName: 'arrow_forward',
                                          color: AppTheme
                                              .lightTheme.colorScheme.primary,
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Page View
                            Expanded(
                              child: PageView.builder(
                                controller: _pageController,
                                onPageChanged: _onPageChanged,
                                itemCount: _onboardingContents.length,
                                physics: _isAnimating
                                    ? const NeverScrollableScrollPhysics()
                                    : const BouncingScrollPhysics(),
                                itemBuilder: (context, index) {
                                  final content = _onboardingContents[index];
                                  return SafeArea(
                                    child: OnboardingCardWidget(
                                      title: content.title,
                                      description: content.description,
                                      imageUrl: content.imageUrl,
                                      buttonText: content.buttonText,
                                      isLastPage: index ==
                                          _onboardingContents.length - 1,
                                      isAnimating: _isAnimating,
                                      onButtonPressed: () {
                                        _nextPage();
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),

                            // Enhanced Page Indicator
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: PageIndicatorWidget(
                                currentPage: _currentPage,
                                totalPages: _onboardingContents.length,
                              ),
                            ),

                            SizedBox(height: 2.h),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
