import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../presentation/home_screen/enhanced_home_screen.dart';
import '../presentation/library_screen/library_screen.dart';
import '../presentation/profile_screen/profile_screen.dart';
import '../providers/home_provider.dart';
import '../providers/library_provider.dart';
import '../providers/profile_provider.dart';
import '../core/app_export.dart';
import '../core/navigation_service.dart';
import 'common_bottom_navigation_widget.dart';
import '../core/services/unified_auth_service.dart';

/// Enhanced main navigation with PageView and state preservation
class EnhancedMainNavigation extends StatefulWidget {
  const EnhancedMainNavigation({super.key});

  @override
  State<EnhancedMainNavigation> createState() => _EnhancedMainNavigationState();
}

class _EnhancedMainNavigationState extends State<EnhancedMainNavigation>
    with AutomaticKeepAliveClientMixin {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  final UnifiedAuthService _auth = UnifiedAuthService();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Register the tab selection callback with the navigation service
    NavigationService.registerTabSelectionCallback(_onTabSelected);

    // Defer provider initialization to after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProviders();
      _setInitialTab();
    });
  }

  /// Set the initial tab based on the current route
  void _setInitialTab() {
    final currentRoute = ModalRoute.of(context);
    if (currentRoute != null) {
      final routeName = currentRoute.settings.name;
      int targetIndex = 0; // Default to home tab

      // If a guest opened a non-home route that maps to a tab, redirect to login
      _auth.isGuestMode().then((isGuest) {
        if (isGuest && routeName != null && routeName != AppRoutes.homeScreen) {
          Navigator.pushReplacementNamed(context, AppRoutes.authenticationScreen);
          return;
        }
      });

      switch (routeName) {
        case '/home-screen':
          targetIndex = 0;
          break;
        case '/earn-screen':
          targetIndex = 1;
          break;
        case '/library-screen':
          targetIndex = 2;
          break;
        case '/wallet-screen':
          targetIndex = 3;
          break;
        case '/profile-screen':
          targetIndex = 4;
          break;
        default:
          targetIndex = 0; // Default to home
      }

      if (targetIndex != _currentIndex) {
        setState(() {
          _currentIndex = targetIndex;
        });

        // Animate to the correct tab
        _pageController.animateToPage(
          targetIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  void dispose() {
    // Unregister the tab selection callback from the navigation service
    NavigationService.unregisterTabSelectionCallback();
    _pageController.dispose();
    super.dispose();
  }

  /// Initialize all providers
  Future<void> _initializeProviders() async {
    try {
      final isGuest = await _auth.isGuestMode();
      if (isGuest) {
        // Guests: initialize only home-related data; skip auth-required providers
        await Provider.of<HomeProvider>(context, listen: false).initialize();
        debugPrint('✅ Initialized HomeProvider for guest session');
      } else {
        // Authenticated users: initialize all providers in parallel
        await Future.wait([
          Provider.of<HomeProvider>(context, listen: false).initialize(),
          Provider.of<LibraryProvider>(context, listen: false).initialize(),
          Provider.of<ProfileProvider>(context, listen: false).initialize(),
        ]);
      }
      debugPrint('✅ All providers initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing providers: $e');
    }
  }

  /// Handle tab selection
  void _onTabSelected(int index) {
    // If guest, only allow Home (index 0)
    _auth.isGuestMode().then((isGuest) {
      if (isGuest && index != 0) {
        Navigator.pushReplacementNamed(context, AppRoutes.authenticationScreen);
        return;
      }

      if (_currentIndex != index) {
        setState(() {
          _currentIndex = index;
        });

        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  /// Handle page changes from swipe gestures
  void _onPageChanged(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });

      // Clear mini-player positioning cache when navigating between pages
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return Scaffold(
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const NeverScrollableScrollPhysics(), // Disable swipe gestures
        children: [
          // Home Screen
          _buildPage(
            index: 0,
            child: const EnhancedHomeScreen(),
          ),

          // Earn Screen (placeholder for now)
          _buildPage(
            index: 1,
            child: _buildEarnScreen(),
          ),

          // Library Screen
          _buildPage(
            index: 2,
            child: const LibraryScreen(),
          ),

          // Wallet Screen (placeholder for now)
          _buildPage(
            index: 3,
            child: _buildWalletScreen(),
          ),

          // Profile Screen
          _buildPage(
            index: 4,
            child: const ProfileScreen(),
          ),
        ],
      ),
      bottomNavigationBar: CommonBottomNavigationWidget(
        currentIndex: _currentIndex,
        onTabSelected: _onTabSelected,
      ),
    );
  }

  /// Build a page with proper padding for mini player
  Widget _buildPage({
    required int index,
    required Widget child,
  }) {
    return Container(
      // Remove excessive bottom padding that creates gap
      // Only add minimal padding if mini-player is actually active
      padding: EdgeInsets.only(
        bottom: 0, // Remove the excessive padding
      ),
      child: child,
    );
  }

  /// Build earn screen placeholder
  Widget _buildEarnScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.monetization_on,
            size: 20.w,
            color: AppTheme.lightTheme.colorScheme.primary,
          ),
          SizedBox(height: 4.h),
          Text(
            'Earn Screen',
            style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Coming Soon',
            style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// Build wallet screen placeholder
  Widget _buildWalletScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet,
            size: 20.w,
            color: AppTheme.lightTheme.colorScheme.primary,
          ),
          SizedBox(height: 4.h),
          Text(
            'Wallet Screen',
            style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Coming Soon',
            style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
