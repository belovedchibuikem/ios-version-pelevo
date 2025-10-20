import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/common_bottom_navigation_widget.dart';
import './widgets/search_bar_widget.dart';
import './widgets/tab_content_widget.dart';
import '../../core/routes/app_routes.dart';
import '../../core/error_handling/global_error_handler.dart';
import '../../core/utils/smooth_scroll_utils.dart';
import '../../core/utils/mini_player_positioning.dart';

// lib/presentation/library_screen/library_screen.dart

// lib/presentation/library_screen/library_screen.dart

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with TickerProviderStateMixin, SafeStateMixin, SmoothScrollMixin {
  late TabController _tabController;
  final NavigationService _navigationService = NavigationService();
  String searchQuery = '';
  bool isSearchActive = false;
  int _selectedTabIndex = 2; // Library tab is index 2

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Mini-player will auto-detect bottom navigation positioning

    // Track this route
    _navigationService.trackNavigation(AppRoutes.libraryScreen);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    safeSetState(() {
      searchQuery = query;
    });
  }

  void _onSearchToggle() {
    safeSetState(() {
      isSearchActive = !isSearchActive;
      if (!isSearchActive) {
        searchQuery = '';
      }
    });
  }

  void _onTabSelected(int index) {
    safeSetState(() {
      _selectedTabIndex = index;
    });

    switch (index) {
      case 0:
        _navigationService.navigateTo(AppRoutes.homeScreen);
        break;
      case 1:
        _navigationService.navigateTo(AppRoutes.earnScreen);
        break;
      case 2:
        // Already on Library
        break;
      case 3:
        _navigationService.navigateTo(AppRoutes.walletScreen);
        break;
      case 4:
        _navigationService.navigateTo(AppRoutes.profileScreen);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
          backgroundColor: AppTheme.lightTheme.colorScheme.surface,
          elevation: 0,
          title: isSearchActive
              ? null
              : Text('My Library',
                  style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.lightTheme.colorScheme.onSurface)),
          centerTitle: !isSearchActive,
          leading: IconButton(
              icon: CustomIconWidget(
                  iconName: 'arrow_back',
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                  size: 24),
              onPressed: () => _navigationService.goBack()),
          actions: [
            if (!isSearchActive) ...[
              IconButton(
                  icon: CustomIconWidget(
                      iconName: 'history',
                      color: AppTheme.lightTheme.colorScheme.onSurface,
                      size: 24),
                  onPressed: () => Navigator.pushNamed(
                      context, AppRoutes.listeningHistoryScreen)),
              IconButton(
                  icon: Icon(
                    Icons.archive,
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                    size: 24,
                  ),
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.archiveScreen)),
              IconButton(
                  icon: CustomIconWidget(
                      iconName: 'search',
                      color: AppTheme.lightTheme.colorScheme.onSurface,
                      size: 24),
                  onPressed: _onSearchToggle),
            ],
          ],
          bottom: isSearchActive
              ? PreferredSize(
                  preferredSize: Size.fromHeight(8.h),
                  child: SearchBarWidget(
                    hintText: 'Search in library',
                    onChanged: _onSearchChanged,
                  ))
              : PreferredSize(
                  preferredSize: Size.fromHeight(6.h),
                  child: TabBar(
                      controller: _tabController,
                      labelStyle: AppTheme.lightTheme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                      unselectedLabelStyle: AppTheme
                          .lightTheme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w400),
                      indicatorColor: AppTheme.lightTheme.colorScheme.primary,
                      labelColor: AppTheme.lightTheme.colorScheme.primary,
                      unselectedLabelColor:
                          AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      tabs: const [
                        Tab(text: 'Downloads'),
                        Tab(text: 'Subscriptions'),
                        Tab(text: 'History'),
                        Tab(text: 'Playlists'),
                      ]))),
      body: Column(children: [
        // Tab content
        Expanded(
            child: TabBarView(controller: _tabController, children: [
          TabContentWidget(
              items: [], tabType: 'downloads', searchQuery: searchQuery),
          TabContentWidget(
              items: [], tabType: 'subscriptions', searchQuery: searchQuery),
          TabContentWidget(
              items: [], tabType: 'history', searchQuery: searchQuery),
          TabContentWidget(
              items: [], tabType: 'playlists', searchQuery: searchQuery),
        ])),
        // Remove excessive bottom spacing - the main navigation handles this
        // SizedBox(height: 8.h), // Space for bottom navigation
      ]),
    );
  }
}
