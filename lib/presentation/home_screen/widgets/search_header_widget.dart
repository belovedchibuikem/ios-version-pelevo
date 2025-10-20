import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../../../core/app_export.dart';
import '../../library_screen/widgets/notifications_widget.dart';
import '../../../providers/notification_provider.dart';

class SearchHeaderWidget extends StatefulWidget {
  final bool isSearchActive;
  final VoidCallback onSearchTap;
  final VoidCallback onSearchClose;
  final ValueChanged<String> onSearch;

  const SearchHeaderWidget({
    super.key,
    required this.isSearchActive,
    required this.onSearchTap,
    required this.onSearchClose,
    required this.onSearch,
  });

  @override
  State<SearchHeaderWidget> createState() => _SearchHeaderWidgetState();
}

class _SearchHeaderWidgetState extends State<SearchHeaderWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<String> recentSearches = [];
  final List<String> trendingTopics = [
    "AI and Technology",
    "Mental Health",
    "Business Stories",
    "Science Explained",
    "History Mysteries",
  ];

  // Placeholder animation properties
  Timer? _placeholderTimer;
  int _currentPlaceholderIndex = 0;
  final List<String> _placeholders = [
    'Podcasts',
    'Creators',
    'RSS Feed',
    'Topics'
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _loadRecentSearches();
    _startPlaceholderAnimation();

    // Add focus listener to stop animation when typing
    _searchFocusNode.addListener(() {
      if (_searchFocusNode.hasFocus) {
        _stopPlaceholderAnimation();
      } else if (!widget.isSearchActive) {
        _startPlaceholderAnimation();
      }
    });
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      recentSearches = prefs.getStringList('recent_searches') ?? [];
    });
  }

  Future<void> _addRecentSearch(String query) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      recentSearches.remove(query);
      recentSearches.insert(0, query);
      if (recentSearches.length > 10)
        recentSearches = recentSearches.sublist(0, 10);
      prefs.setStringList('recent_searches', recentSearches);
    });
  }

  Future<void> _clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      recentSearches.clear();
      prefs.remove('recent_searches');
    });
  }

  @override
  void didUpdateWidget(SearchHeaderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSearchActive && !oldWidget.isSearchActive) {
      _animationController.forward();
      _searchFocusNode.requestFocus();
      _stopPlaceholderAnimation(); // Stop animation when search is active
    } else if (!widget.isSearchActive && oldWidget.isSearchActive) {
      _animationController.reverse();
      _searchFocusNode.unfocus();
      _searchController.clear();
      _startPlaceholderAnimation(); // Resume animation when search is closed
    }
  }

  void _startPlaceholderAnimation() {
    _placeholderTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          _currentPlaceholderIndex =
              (_currentPlaceholderIndex + 1) % _placeholders.length;
        });
      }
    });
  }

  void _stopPlaceholderAnimation() {
    _placeholderTimer?.cancel();
    _placeholderTimer = null;
  }

  @override
  void dispose() {
    _stopPlaceholderAnimation();
    _animationController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.colorScheme.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Stack(
          children: [
            _buildNormalHeader(),
            if (widget.isSearchActive) _buildSearchInterface(),
          ],
        ),
      ),
    );
  }

  Widget _buildNormalHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: widget.onSearchTap,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.surface
                      .withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.lightTheme.colorScheme.outline,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'search',
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        'Search ${_placeholders[_currentPlaceholderIndex]}...',
                        key: ValueKey(_currentPlaceholderIndex),
                        style:
                            AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              final unreadCount = notificationProvider.unreadCount;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NotificationsScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.lightTheme.colorScheme.outline,
                          width: 1,
                        ),
                      ),
                      child: CustomIconWidget(
                        iconName: 'notifications',
                        color: AppTheme.lightTheme.colorScheme.onSurface,
                        size: 24,
                      ),
                    ),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Center(
                          child: Text(
                            unreadCount > 9 ? '9+' : unreadCount.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchInterface() {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
              0, _slideAnimation.value * 60.h), // Reduced from 100.h to 60.h
          child: Container(
            height:
                60.h, // Reduced from 100.h to 60.h to prevent content blocking
            color: AppTheme.lightTheme.scaffoldBackgroundColor,
            child: Column(
              children: [
                _buildSearchBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(4.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (recentSearches.isNotEmpty) _buildRecentSearches(),
                        SizedBox(height: 3.h),
                        _buildTrendingTopics(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.colorScheme.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onSearchClose,
            child: Container(
              padding: EdgeInsets.all(2.w),
              child: CustomIconWidget(
                iconName: 'arrow_back',
                color: AppTheme.lightTheme.colorScheme.onSurface,
                size: 24,
              ),
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText:
                    'Search ${_placeholders[_currentPlaceholderIndex]}...',
                border: InputBorder.none,
                hintStyle: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
              style: AppTheme.lightTheme.textTheme.bodyMedium,
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  _addRecentSearch(value.trim());
                  widget.onSearch(value.trim());
                }
              },
            ),
          ),
          if (_searchController.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() {});
              },
              child: Container(
                padding: EdgeInsets.all(2.w),
                child: CustomIconWidget(
                  iconName: 'clear',
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentSearches() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Searches',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.lightTheme.colorScheme.onSurface,
              ),
            ),
            TextButton(
              onPressed: _clearRecentSearches,
              child: Text(
                'Clear All',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        ...recentSearches.map((search) => _buildSearchItem(
              search,
              'history',
              () {
                _addRecentSearch(search);
                widget.onSearch(search);
              },
            )),
      ],
    );
  }

  Widget _buildTrendingTopics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trending Topics',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.lightTheme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 1.h),
        ...trendingTopics.map((topic) => _buildSearchItem(
              topic,
              'trending_up',
              () {
                _addRecentSearch(topic);
                widget.onSearch(topic);
              },
            )),
      ],
    );
  }

  Widget _buildSearchItem(String text, String iconName, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 1.5.h),
        child: Row(
          children: [
            CustomIconWidget(
              iconName: iconName,
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: Text(
                text,
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                ),
              ),
            ),
            CustomIconWidget(
              iconName: 'north_west',
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Notifications')),
      body: NotificationsWidget(),
    );
  }
}
