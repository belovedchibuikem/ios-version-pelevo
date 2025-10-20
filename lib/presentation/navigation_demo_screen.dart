import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../core/app_export.dart';
import '../widgets/enhanced_bottom_navigation_widget.dart';
import '../widgets/enhanced_nav_item.dart';
import '../theme/navigation_theme.dart';

/// Navigation Demo Screen
///
/// This screen showcases the new enhanced navigation system
/// and allows testing of all its features and animations.
class NavigationDemoScreen extends StatefulWidget {
  const NavigationDemoScreen({super.key});

  @override
  State<NavigationDemoScreen> createState() => _NavigationDemoScreenState();
}

class _NavigationDemoScreenState extends State<NavigationDemoScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  Map<int, int> _badgeCounts = {};
  bool _showMiniPlayer = false;
  double _miniPlayerHeight = 84.0;
  bool _isDarkMode = false;

  late AnimationController _demoAnimationController;
  late Animation<double> _demoAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize demo animation
    _demoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _demoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _demoAnimationController,
      curve: Curves.easeInOut,
    ));

    // Start demo animation
    _demoAnimationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _demoAnimationController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _toggleMiniPlayer() {
    setState(() {
      _showMiniPlayer = !_showMiniPlayer;
    });
  }

  void _addBadge(int tabIndex) {
    setState(() {
      _badgeCounts[tabIndex] = (_badgeCounts[tabIndex] ?? 0) + 1;
    });
  }

  void _clearBadge(int tabIndex) {
    setState(() {
      _badgeCounts.remove(tabIndex);
    });
  }

  void _clearAllBadges() {
    setState(() {
      _badgeCounts.clear();
    });
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      child: Scaffold(
        backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.grey[50],
        appBar: AppBar(
          title: const Text('Navigation Demo'),
          backgroundColor: _isDarkMode ? Colors.grey[800] : Colors.white,
          foregroundColor: _isDarkMode ? Colors.white : Colors.black,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
              onPressed: _toggleTheme,
              tooltip: 'Toggle Theme',
            ),
          ],
        ),
        body: Column(
          children: [
            // Demo controls
            _buildDemoControls(),

            // Content area
            Expanded(
              child: _buildContentArea(),
            ),
          ],
        ),
        bottomNavigationBar: EnhancedBottomNavigationWidget(
          currentIndex: _currentIndex,
          onTabSelected: _onTabSelected,
          badgeCounts: _badgeCounts,
          showMiniPlayer: _showMiniPlayer,
          miniPlayerHeight: _miniPlayerHeight,
          isDarkMode: _isDarkMode,
        ),
      ),
    );
  }

  Widget _buildDemoControls() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: _isDarkMode ? Colors.grey[800] : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: _isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Demo Controls',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: _isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          SizedBox(height: 2.h),

          // Badge controls
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Badge Management',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: _isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Wrap(
                      spacing: 2.w,
                      children: List.generate(5, (index) {
                        return ElevatedButton(
                          onPressed: () => _addBadge(index),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: 3.w,
                              vertical: 1.h,
                            ),
                            minimumSize: Size.zero,
                          ),
                          child: Text('+${index + 1}'),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  ElevatedButton(
                    onPressed: _clearAllBadges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Clear All'),
                  ),
                  SizedBox(height: 1.h),
                  ElevatedButton(
                    onPressed: _toggleMiniPlayer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(_showMiniPlayer ? 'Hide' : 'Show'),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: 2.h),

          // Current state display
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: _isDarkMode ? Colors.grey[700] : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current State',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: _isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  'Selected Tab: $_currentIndex',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: _isDarkMode ? Colors.white60 : Colors.black45,
                  ),
                ),
                Text(
                  'Badges: ${_badgeCounts.values.fold(0, (sum, count) => sum + count)}',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: _isDarkMode ? Colors.white60 : Colors.black45,
                  ),
                ),
                Text(
                  'Mini Player: ${_showMiniPlayer ? 'Visible' : 'Hidden'}',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: _isDarkMode ? Colors.white60 : Colors.black45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentArea() {
    final contentItems = [
      {
        'title': 'Home',
        'icon': Icons.home,
        'color': Colors.blue,
        'description':
            'Welcome to the home screen! This is where you can discover new podcasts and trending content.',
      },
      {
        'title': 'Earn',
        'icon': Icons.monetization_on,
        'color': Colors.green,
        'description':
            'Earn rewards and money by listening to podcasts, completing tasks, and referring friends.',
      },
      {
        'title': 'Library',
        'icon': Icons.library_books,
        'color': Colors.purple,
        'description':
            'Access your personal podcast library, playlists, and downloaded episodes.',
      },
      {
        'title': 'Wallet',
        'icon': Icons.account_balance_wallet,
        'color': Colors.orange,
        'description':
            'Manage your earnings, view transaction history, and withdraw funds.',
      },
      {
        'title': 'Profile',
        'icon': Icons.person,
        'color': Colors.teal,
        'description':
            'Customize your profile, manage settings, and view your listening statistics.',
      },
    ];

    final currentContent = contentItems[_currentIndex];

    return Container(
      padding: EdgeInsets.all(5.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated icon
          AnimatedBuilder(
            animation: _demoAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: 0.8 + (_demoAnimation.value * 0.4),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: currentContent['color'] as Color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color:
                            (currentContent['color'] as Color).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    currentContent['icon'] as IconData,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),

          SizedBox(height: 4.h),

          // Title
          Text(
            currentContent['title'] as String,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: _isDarkMode ? Colors.white : Colors.black,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 2.h),

          // Description
          Text(
            currentContent['description'] as String,
            style: TextStyle(
              fontSize: 14.sp,
              color: _isDarkMode ? Colors.white70 : Colors.black54,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),

          SizedBox(height: 4.h),

          // Feature highlights
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: _isDarkMode ? Colors.grey[800] : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Enhanced Navigation Features',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: _isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                SizedBox(height: 2.h),
                _buildFeatureItem(
                  icon: Icons.animation,
                  title: 'Smooth Animations',
                  description: 'Fluid transitions and micro-interactions',
                ),
                _buildFeatureItem(
                  icon: Icons.notifications_active,
                  title: 'Smart Badges',
                  description: 'Contextual notifications and updates',
                ),
                _buildFeatureItem(
                  icon: Icons.touch_app,
                  title: 'Enhanced Touch',
                  description: 'Haptic feedback and gesture support',
                ),
                _buildFeatureItem(
                  icon: Icons.auto_awesome,
                  title: 'Responsive Design',
                  description: 'Adapts to all screen sizes',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: NavigationTheme.getPrimaryColor(context).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: NavigationTheme.getPrimaryColor(context),
              size: 20,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: _isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: _isDarkMode ? Colors.white60 : Colors.black45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
