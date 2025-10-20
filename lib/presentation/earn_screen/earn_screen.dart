import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/common_bottom_navigation_widget.dart';
import '../../widgets/coming_soon_widget.dart';
import './widgets/coin_balance_header_widget.dart';
import './widgets/earn_podcast_card_widget.dart';
import './widgets/filter_chips_widget.dart';
import './widgets/geo_restriction_widget.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/mini_player_positioning.dart';

// lib/presentation/earn_screen/earn_screen.dart

class EarnScreen extends StatefulWidget {
  const EarnScreen({super.key});

  @override
  State<EarnScreen> createState() => _EarnScreenState();
}

class _EarnScreenState extends State<EarnScreen> with TickerProviderStateMixin {
  final NavigationService _navigationService = NavigationService();
  String selectedFilter = 'All';
  bool isGeoRestricted = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Toggle for coming soon vs full functionality
  bool _showComingSoon = true; // Set to false to show full functionality

  // Mock data for earning podcasts
  final List<Map<String, dynamic>> earningPodcasts = [
    {
      'id': 'earn_001',
      'title': 'The Future of Digital Finance',
      'creator': 'FinTech Weekly',
      'coverImage':
          'https://images.unsplash.com/photo-1559526324-4b87b5e36e44?w=300&h=300&fit=crop',
      'duration': '45m',
      'coinsPerMinute': 3.0,
      'totalCoins': 135,
      'category': 'Finance',
      'difficulty': 'Beginner',
      'isNew': true,
      'description':
          'Explore the latest trends in digital finance and cryptocurrency.',
      'estimatedEarnings': '135 coins',
      'listeners': 12500,
      'rating': 4.8,
    },
    {
      'id': 'earn_002',
      'title': 'Sustainable Technology Innovations',
      'creator': 'GreenTech Solutions',
      'coverImage':
          'https://images.pexels.com/photos/590016/pexels-photo-590016.jpeg?w=300&h=300&fit=crop',
      'duration': '38m',
      'coinsPerMinute': 2.5,
      'totalCoins': 95,
      'category': 'Technology',
      'difficulty': 'Intermediate',
      'isNew': false,
      'description':
          'Learn about cutting-edge sustainable technology and environmental solutions.',
      'estimatedEarnings': '95 coins',
      'listeners': 8750,
      'rating': 4.6,
    },
    {
      'id': 'earn_003',
      'title': 'Building Resilient Business Models',
      'creator': 'Entrepreneur Hub',
      'coverImage':
          'https://images.pixabay.com/photo/2015/12/01/20/28/road-1072823_1280.jpg?w=300&h=300&fit=crop',
      'duration': '52m',
      'coinsPerMinute': 2.8,
      'totalCoins': 146,
      'category': 'Business',
      'difficulty': 'Advanced',
      'isNew': true,
      'description':
          'Strategies for creating adaptable and resilient business models in uncertain times.',
      'estimatedEarnings': '146 coins',
      'listeners': 15200,
      'rating': 4.9,
    },
    {
      'id': 'earn_004',
      'title': 'Mental Health in the Digital Age',
      'creator': 'Wellness Today',
      'coverImage':
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=300&h=300&fit=crop',
      'duration': '41m',
      'coinsPerMinute': 2.2,
      'totalCoins': 90,
      'category': 'Health',
      'difficulty': 'Beginner',
      'isNew': false,
      'description':
          'Understanding and managing mental health in our increasingly digital world.',
      'estimatedEarnings': '90 coins',
      'listeners': 9800,
      'rating': 4.7,
    },
    {
      'id': 'earn_005',
      'title': 'The Art of Data Storytelling',
      'creator': 'Analytics Pro',
      'coverImage':
          'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=300&h=300&fit=crop',
      'duration': '36m',
      'coinsPerMinute': 3.2,
      'totalCoins': 115,
      'category': 'Technology',
      'difficulty': 'Intermediate',
      'isNew': false,
      'description':
          'Master the techniques of turning complex data into compelling narratives.',
      'estimatedEarnings': '115 coins',
      'listeners': 11400,
      'rating': 4.5,
    },
  ];

  final List<String> filterOptions = [
    'All',
    'Finance',
    'Technology',
    'Business',
    'Health',
    'Beginner',
    'Intermediate',
    'Advanced',
  ];

  @override
  void initState() {
    super.initState();

    // Mini-player will auto-detect bottom navigation positioning

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
    // Track this route
    _navigationService.trackNavigation(AppRoutes.earnScreen);
    _checkGeoRestriction();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _checkGeoRestriction() {
    // Mock geo-restriction check
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          isGeoRestricted = false; // Set to true to test geo-restriction UI
        });
      }
    });
  }

  void _onFilterSelected(String filter) {
    setState(() {
      selectedFilter = filter;
    });
  }

  void _onPodcastTap(Map<String, dynamic> podcast) {
    _navigationService.navigateTo(AppRoutes.podcastDetailScreen,
        arguments: podcast);
  }

  void _onPlayPodcast(Map<String, dynamic> podcast) {
    // Ensure earning context is properly set
    _navigationService.trackNavigation(AppRoutes.earnScreen);

    _navigationService.navigateToPlayerFromSource(
      AppRoutes.podcastPlayer,
      arguments: podcast,
      sourceRoute: AppRoutes.earnScreen,
    );
  }

  List<Map<String, dynamic>> get filteredPodcasts {
    if (selectedFilter == 'All') {
      return earningPodcasts;
    }
    return earningPodcasts.where((podcast) {
      return podcast['category'] == selectedFilter ||
          podcast['difficulty'] == selectedFilter;
    }).toList();
  }

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Earning podcasts updated successfully'),
          backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
          behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show coming soon if toggle is enabled
    if (_showComingSoon) {
      return Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        body: ComingSoonWidget(
          title: 'Earn While You Listen',
          description:
              'Get ready to earn coins and rewards by listening to your favorite podcasts. This feature will allow you to monetize your listening time and earn real rewards.',
          icon: Icons.monetization_on,
        ),
      );
    }

    // Show full functionality
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
          backgroundColor: AppTheme.lightTheme.colorScheme.surface,
          elevation: 0,
          title: Text('Earn Coins',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.lightTheme.colorScheme.onSurface)),
          centerTitle: true,
          leading: IconButton(
              icon: CustomIconWidget(
                  iconName: 'arrow_back',
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                  size: 24),
              onPressed: () => _navigationService.goBack()),
          actions: [
            IconButton(
                icon: CustomIconWidget(
                    iconName: 'info_outline',
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                    size: 24),
                onPressed: () {
                  _showEarningInfoDialog();
                }),
          ]),
      body: isGeoRestricted
          ? GeoRestrictionWidget()
          : RefreshIndicator(
              onRefresh: _onRefresh,
              color: AppTheme.lightTheme.colorScheme.primary,
              child: CustomScrollView(slivers: [
                // Coin balance header
                SliverToBoxAdapter(
                    child: CoinBalanceHeaderWidget(
                  animation: _animation,
                  conversionRate: 1.0,
                  currentCoins: 0,
                )),

                // Filter chips
                SliverToBoxAdapter(
                    child: FilterChipsWidget(
                        selectedFilter: selectedFilter,
                        onFilterChanged: _onFilterSelected)),

                // Earning podcasts list
                SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                      final podcast = filteredPodcasts[index];
                      return Padding(
                          padding: EdgeInsets.only(bottom: 2.h),
                          child: EarnPodcastCardWidget(
                              podcast: podcast,
                              onTap: () => _onPodcastTap(podcast),
                              onLongPress: () {}));
                    }, childCount: filteredPodcasts.length))),

                // Bottom spacing for mini-player
                SliverToBoxAdapter(
                    child: SizedBox(
                        height: MiniPlayerPositioning
                            .bottomPaddingForScrollables())),
              ])),
    );
  }

  void _showEarningInfoDialog() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              title: Text('How Earning Works',
                  style: AppTheme.lightTheme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w600)),
              content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        '• Listen to sponsored podcasts to earn coins\n'
                        '• Earning rate varies by episode (1.5 - 3.5 coins/minute)\n'
                        '• Complete the entire episode to maximize earnings\n'
                        '• Coins can be redeemed for rewards or withdrawn\n'
                        '• New earning episodes added weekly',
                        style: AppTheme.lightTheme.textTheme.bodyMedium),
                  ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Got it',
                        style: AppTheme.lightTheme.textTheme.labelLarge
                            ?.copyWith(
                                color: AppTheme.lightTheme.colorScheme.primary,
                                fontWeight: FontWeight.w600))),
              ]);
        });
  }
}
