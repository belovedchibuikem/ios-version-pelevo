import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import '../core/app_export.dart';
import 'enhanced_nav_item.dart';
import '../theme/navigation_theme.dart';

/// Enhanced Bottom Navigation Widget
///
/// Features:
/// - Modern, sleek design with smooth animations
/// - Enhanced visual feedback and interactions
/// - Badge support for notifications and updates
/// - Responsive design for different screen sizes
/// - Mini-player integration and positioning
/// - Accessibility and gesture support
class EnhancedBottomNavigationWidget extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTabSelected;
  final Map<int, int>? badgeCounts;
  final bool showMiniPlayer;
  final double miniPlayerHeight;
  final bool isDarkMode;

  const EnhancedBottomNavigationWidget({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    this.badgeCounts,
    this.showMiniPlayer = false,
    this.miniPlayerHeight = 0.0,
    this.isDarkMode = false,
  });

  @override
  State<EnhancedBottomNavigationWidget> createState() =>
      _EnhancedBottomNavigationWidgetState();
}

class _EnhancedBottomNavigationWidgetState
    extends State<EnhancedBottomNavigationWidget>
    with TickerProviderStateMixin {
  late AnimationController _slideAnimationController;
  late AnimationController _fadeAnimationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  // Navigation items configuration
  static const List<Map<String, dynamic>> _navItems = [
    {
      'index': 0,
      'iconName': 'home',
      'label': 'Home',
      'tooltip': 'Go to Home',
    },
    {
      'index': 1,
      'iconName': 'monetization_on',
      'label': 'Earn',
      'tooltip': 'Earn rewards and money',
    },
    {
      'index': 2,
      'iconName': 'library_books',
      'label': 'Library',
      'tooltip': 'Your podcast library',
    },
    {
      'index': 3,
      'iconName': 'account_balance_wallet',
      'label': 'Wallet',
      'tooltip': 'Manage your wallet',
    },
    {
      'index': 4,
      'iconName': 'person',
      'label': 'Profile',
      'tooltip': 'Your profile and settings',
    },
  ];

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Slide animation - slides up from bottom
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeOutCubic,
    ));

    // Fade animation - fades in
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _slideAnimationController.forward();
    _fadeAnimationController.forward();
  }

  @override
  void dispose() {
    _slideAnimationController.dispose();
    _fadeAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = NavigationTheme.isDarkMode(context);

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          height: _getNavigationHeight(),
          decoration: BoxDecoration(
            color: _getBackgroundColor(colorScheme, isDark),
            // Remove excessive border radius that creates visual separation
            borderRadius: BorderRadius.zero,
            boxShadow: _getShadows(colorScheme, isDark),
            // Remove top border that adds extra visual weight
            border: null,
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Remove top indicator bar to reduce height
                // _buildTopIndicator(colorScheme, isDark),

                // Navigation items
                Expanded(
                  child: _buildNavigationItems(colorScheme),
                ),

                // Only add mini-player spacing if actually needed
                if (widget.showMiniPlayer && widget.miniPlayerHeight > 0)
                  SizedBox(height: widget.miniPlayerHeight),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopIndicator(ColorScheme colorScheme, bool isDark) {
    return Container(
      margin: EdgeInsets.only(top: 0.5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: _getIndicatorColor(colorScheme, isDark),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationItems(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: _navItems.map((item) {
        final index = item['index'] as int;
        final iconName = item['iconName'] as String;
        final label = item['label'] as String;
        final tooltip = item['tooltip'] as String;

        final isSelected = index == widget.currentIndex;
        final badgeCount = widget.badgeCounts?[index];
        final showBadge = badgeCount != null && badgeCount > 0;

        return Expanded(
          child: EnhancedNavItem(
            index: index,
            iconName: iconName,
            label: label,
            isSelected: isSelected,
            onTap: () => _handleTabSelection(index),
            showBadge: showBadge,
            badgeCount: badgeCount,
            tooltip: tooltip,
          ),
        );
      }).toList(),
    );
  }

  void _handleTabSelection(int index) {
    if (index != widget.currentIndex) {
      // Haptic feedback
      HapticFeedback.selectionClick();

      // Call the callback
      widget.onTabSelected(index);
    }
  }

  double _getNavigationHeight() {
    // Use consistent height like CommonBottomNavigationWidget
    // Instead of the excessive heights from NavigationTheme
    return 8.h; // 8% of screen height, approximately 64px on standard screens
  }

  Color _getBackgroundColor(ColorScheme colorScheme, bool isDark) {
    return NavigationTheme.getSurfaceColor(context);
  }

  Color _getBorderColor(ColorScheme colorScheme, bool isDark) {
    return NavigationTheme.getOutlineColor(context);
  }

  Color _getIndicatorColor(ColorScheme colorScheme, bool isDark) {
    return isDark
        ? colorScheme.onSurface.withOpacity(0.3)
        : colorScheme.onSurface.withOpacity(0.2);
  }

  List<BoxShadow> _getShadows(ColorScheme colorScheme, bool isDark) {
    // Use lighter shadows to avoid appearing as extra cards
    return [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 4,
        offset: const Offset(0, -1),
        spreadRadius: 0,
      ),
    ];
  }
}

/// Navigation Badge Manager
///
/// Manages badge counts for navigation items
class NavigationBadgeManager {
  static final Map<int, int> _badgeCounts = {};
  static final List<Function()> _listeners = [];

  /// Add a listener for badge updates
  static void addListener(Function() listener) {
    _listeners.add(listener);
  }

  /// Remove a listener
  static void removeListener(Function() listener) {
    _listeners.remove(listener);
  }

  /// Set badge count for a specific tab
  static void setBadgeCount(int tabIndex, int count) {
    _badgeCounts[tabIndex] = count;
    _notifyListeners();
  }

  /// Get badge count for a specific tab
  static int getBadgeCount(int tabIndex) {
    return _badgeCounts[tabIndex] ?? 0;
  }

  /// Clear badge count for a specific tab
  static void clearBadgeCount(int tabIndex) {
    _badgeCounts.remove(tabIndex);
    _notifyListeners();
  }

  /// Clear all badge counts
  static void clearAllBadgeCounts() {
    _badgeCounts.clear();
    _notifyListeners();
  }

  /// Get all badge counts
  static Map<int, int> getAllBadgeCounts() {
    return Map.from(_badgeCounts);
  }

  /// Notify all listeners
  static void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }
}
