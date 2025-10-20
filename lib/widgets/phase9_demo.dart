import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../core/app_export.dart';
import 'enhanced_gesture_detector.dart';
import 'enhanced_accessibility_widget.dart';
import 'enhanced_ui_polish.dart';
import 'enhanced_loading_widget.dart';
import '../services/animation_service.dart';

/// Demo widget showcasing all Phase 9 User Experience Enhancements
class Phase9Demo extends StatefulWidget {
  const Phase9Demo({super.key});

  @override
  State<Phase9Demo> createState() => _Phase9DemoState();
}

class _Phase9DemoState extends State<Phase9Demo> with TickerProviderStateMixin {
  final AnimationService _animationService = AnimationService();

  late AnimationController _mainController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _showAdvancedFeatures = false;
  double _sliderValue = 0.5;
  bool _checkboxValue = false;
  bool _switchValue = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = _animationService.createFadeInAnimation(_mainController);
    _slideAnimation =
        _animationService.createSlideInFromBottomAnimation(_mainController);

    _mainController.forward();
  }

  @override
  void dispose() {
    _mainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phase 9: UX Enhancements Demo'),
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _showAdvancedFeatures = !_showAdvancedFeatures;
              });
            },
            icon: Icon(_showAdvancedFeatures
                ? Icons.visibility_off
                : Icons.visibility),
            tooltip: 'Toggle Advanced Features',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Enhanced Animations & Transitions'),
                _buildAnimationDemo(),
                SizedBox(height: 4.h),
                _buildSectionHeader('Enhanced Visual Feedback'),
                _buildVisualFeedbackDemo(),
                SizedBox(height: 4.h),
                _buildSectionHeader('Accessibility Improvements'),
                _buildAccessibilityDemo(),
                SizedBox(height: 4.h),
                _buildSectionHeader('Gesture Enhancements'),
                _buildGestureDemo(),
                SizedBox(height: 4.h),
                _buildSectionHeader('UI Polish & Refinements'),
                _buildUIPolishDemo(),
                if (_showAdvancedFeatures) ...[
                  SizedBox(height: 4.h),
                  _buildSectionHeader('Advanced Features'),
                  _buildAdvancedFeaturesDemo(),
                ],
                SizedBox(height: 4.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Text(
        title,
        style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
          color: AppTheme.lightTheme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildAnimationDemo() {
    return EnhancedContainer(
      enableGradient: true,
      gradientColors: [
        Colors.blue.withValues(alpha: 0.1),
        Colors.purple.withValues(alpha: 0.1),
      ],
      borderRadius: BorderRadius.circular(16),
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Smooth Animations',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildAnimatedCard('Fade In', Icons.visibility),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildAnimatedCard('Slide In', Icons.swipe),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildAnimatedCard('Scale', Icons.zoom_in),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedCard(String title, IconData icon) {
    return EnhancedCard(
      enableHoverEffect: true,
      enablePressEffect: true,
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title animation triggered!')),
        );
      },
      child: Column(
        children: [
          Icon(icon, size: 32, color: AppTheme.lightTheme.colorScheme.primary),
          SizedBox(height: 1.h),
          Text(
            title,
            style: AppTheme.lightTheme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVisualFeedbackDemo() {
    return EnhancedContainer(
      enableShadow: true,
      borderRadius: BorderRadius.circular(16),
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Interactive Feedback',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: EnhancedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Button pressed!')),
                    );
                  },
                  child: const Text('Enhanced Button'),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: EnhancedCard(
                  enableShimmer: true,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Card tapped!')),
                    );
                  },
                  child: const Text('Shimmer Card'),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          EnhancedText(
            'Typewriter Effect',
            enableTypewriter: true,
            style: AppTheme.lightTheme.textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildAccessibilityDemo() {
    return EnhancedContainer(
      enableGradient: true,
      gradientColors: [
        Colors.green.withValues(alpha: 0.1),
        Colors.teal.withValues(alpha: 0.1),
      ],
      borderRadius: BorderRadius.circular(16),
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Accessibility Features',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: AccessibleButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Accessible button pressed!')),
                    );
                  },
                  label: 'Accessible Button',
                  hint: 'Press to trigger an action',
                  child: const Text('Accessible'),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: AccessibleCheckbox(
                  value: _checkboxValue,
                  onChanged: (value) {
                    setState(() {
                      _checkboxValue = value;
                    });
                  },
                  label: 'Accessible Checkbox',
                  hint: 'Toggle this option',
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          AccessibleSwitch(
            value: _switchValue,
            onChanged: (value) {
              setState(() {
                _switchValue = value;
              });
            },
            label: 'Accessible Switch',
            hint: 'Toggle this setting',
          ),
        ],
      ),
    );
  }

  Widget _buildGestureDemo() {
    return EnhancedContainer(
      enableShadow: true,
      borderRadius: BorderRadius.circular(16),
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Advanced Gestures',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: EnhancedGestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Enhanced gesture detected!')),
                    );
                  },
                  enableRippleEffect: true,
                  enableScaleAnimation: true,
                  child: Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.touch_app, size: 24),
                        SizedBox(height: 0.5.h),
                        Text('Tap Me', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: SwipeableWidget(
                  onSwipeLeft: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Swiped left!')),
                    );
                  },
                  onSwipeRight: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Swiped right!')),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.swipe, size: 24),
                        SizedBox(height: 0.5.h),
                        Text('Swipe Me', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            'Pinch to zoom the image below:',
            style: AppTheme.lightTheme.textTheme.bodyMedium,
          ),
          SizedBox(height: 1.h),
          PinchToZoomWidget(
            child: Container(
              height: 20.h,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(
                  Icons.zoom_in,
                  size: 48,
                  color: AppTheme.lightTheme.colorScheme.onTertiaryContainer,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUIPolishDemo() {
    return EnhancedContainer(
      enableGradient: true,
      gradientColors: [
        Colors.orange.withValues(alpha: 0.1),
        Colors.red.withValues(alpha: 0.1),
      ],
      borderRadius: BorderRadius.circular(16),
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'UI Polish & Refinements',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: EnhancedCard(
                  enableHoverEffect: true,
                  enablePressEffect: true,
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 32),
                      SizedBox(height: 1.h),
                      Text(
                        'Hover & Press',
                        style: AppTheme.lightTheme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: EnhancedContainer(
                  enableGradient: true,
                  gradientColors: [
                    Colors.purple.withValues(alpha: 0.3),
                    Colors.blue.withValues(alpha: 0.3),
                  ],
                  borderRadius: BorderRadius.circular(12),
                  padding: EdgeInsets.all(2.w),
                  child: Column(
                    children: [
                      Icon(Icons.gradient, color: Colors.white, size: 32),
                      SizedBox(height: 1.h),
                      Text(
                        'Gradient',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          EnhancedText(
            'Glowing Text Effect',
            enableGlow: true,
            glowColor: Colors.blue,
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedFeaturesDemo() {
    return EnhancedContainer(
      enableShadow: true,
      borderRadius: BorderRadius.circular(16),
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Advanced Features',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: EnhancedListTile(
                  leading: Icon(Icons.animation),
                  title: Text('Animated List Item'),
                  subtitle: Text('With slide and fade effects'),
                  animationIndex: 0,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: EnhancedListTile(
                  leading: Icon(Icons.touch_app),
                  title: Text('Another Item'),
                  subtitle: Text('Staggered animation'),
                  animationIndex: 1,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          AccessibleSlider(
            value: _sliderValue,
            onChanged: (value) {
              setState(() {
                _sliderValue = value;
              });
            },
            label: 'Accessible Slider',
            hint: 'Adjust the value',
            min: 0.0,
            max: 1.0,
            divisions: 10,
          ),
          SizedBox(height: 2.h),
          EnhancedLoadingWidget(
            type: LoadingType.ripple,
            message: 'Loading with enhanced animations...',
            size: 60.0,
          ),
        ],
      ),
    );
  }
}
