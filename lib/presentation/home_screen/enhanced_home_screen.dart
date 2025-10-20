import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../../providers/home_provider.dart';
import '../../widgets/skeleton_loading_components.dart';
import '../../core/app_export.dart';

import '../../widgets/network_status_widget.dart';
import './widgets/search_header_widget.dart';
import './widgets/advanced_search_modal.dart';
import './widgets/categories_section_widget.dart';
import './widgets/featured_podcasts_section_widget.dart';
import './widgets/podcast_category_section_widget.dart';
import 'widgets/subscribe_button.dart';
import '../../core/routes/app_routes.dart';
import '../../services/subscription_helper.dart';
import '../../providers/subscription_provider.dart';
import '../../core/utils/smooth_scroll_utils.dart';

/// Enhanced home screen with caching, skeleton loading, and state preservation
class EnhancedHomeScreen extends StatefulWidget {
  const EnhancedHomeScreen({super.key});

  @override
  State<EnhancedHomeScreen> createState() => _EnhancedHomeScreenState();
}

class _EnhancedHomeScreenState extends State<EnhancedHomeScreen>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final NavigationService _navigationService = NavigationService();
  bool _isSearchActive = false;
  String _searchQuery = '';
  bool _hasShownOfflineNotification = false;
  bool _isInitializing = true; // Add initialization tracking

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Initialize in the correct order
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeHomeData();
      _initializeSubscriptionProvider();
    });
    _setupOfflineListener();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Trigger background refresh when returning to this screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final homeProvider = Provider.of<HomeProvider>(context, listen: false);
      // Only trigger background refresh if not already initializing
      if (!_isInitializing) {
        homeProvider.backgroundRefreshOnReturn();
      }
    });
  }

  void _setupOfflineListener() {
    // Listen to offline status changes
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    homeProvider.addListener(() {
      if (mounted && homeProvider.isOffline) {
        _showOfflineNotification();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeHomeData() async {
    try {
      final homeProvider = Provider.of<HomeProvider>(context, listen: false);

      debugPrint('🔍 EnhancedHomeScreen: Starting home data initialization');
      await homeProvider.initialize();

      // First, try to load cached data to show something immediately
      if (homeProvider.homeData == null) {
        debugPrint('🔍 EnhancedHomeScreen: Loading cached data first...');
        await homeProvider.loadCachedData();
      }

      // Check if we need to fetch fresh data
      if (homeProvider.homeData == null || !homeProvider.hasData) {
        debugPrint(
            '🔍 EnhancedHomeScreen: No cached data available, fetching fresh data...');
        await homeProvider.fetchHomeData(forceRefresh: true);
      } else {
        debugPrint(
            '🔍 EnhancedHomeScreen: Cached data available, checking if refresh needed...');
        // Only fetch fresh data if cached data is stale
        if (homeProvider.isDataStale) {
          debugPrint(
              '🔍 EnhancedHomeScreen: Cached data is stale, refreshing...');
          await homeProvider.fetchHomeData(forceRefresh: false);
        } else {
          debugPrint(
              '🔍 EnhancedHomeScreen: Cached data is fresh, no refresh needed');
        }
      }

      // Wait for the HomeProvider to actually finish loading data
      // Keep showing skeleton until we have data or an error
      int attempts = 0;
      const maxAttempts = 30; // Reduced timeout to 3 seconds (30 * 100ms)

      while (homeProvider.isLoading &&
          homeProvider.homeData == null &&
          homeProvider.error == null &&
          attempts < maxAttempts) {
        debugPrint(
            '🔍 EnhancedHomeScreen: Waiting for data to load... (attempt $attempts)');
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;

        // Check if widget is still mounted
        if (!mounted) return;
      }

      if (attempts >= maxAttempts) {
        debugPrint('⚠️ EnhancedHomeScreen: Timeout waiting for data to load');
        // Don't fail completely, just show cached data if available
        if (homeProvider.homeData != null) {
          debugPrint(
              '🔍 EnhancedHomeScreen: Showing cached data despite timeout');
        }
      }

      debugPrint(
          '🔍 EnhancedHomeScreen: Data loading completed - hasData: ${homeProvider.hasData}, error: ${homeProvider.error}');

      // Show offline notification if needed (only once)
      if (homeProvider.isOffline && mounted && !_hasShownOfflineNotification) {
        _hasShownOfflineNotification = true;
        _showOfflineNotification();
      }
    } catch (e) {
      debugPrint('❌ EnhancedHomeScreen: Error initializing home data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initialize home data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  void _showOfflineNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'You\'re offline. Showing cached content.',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange[700],
        duration: Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  Future<void> _initializeSubscriptionProvider() async {
    try {
      final subscriptionProvider =
          Provider.of<SubscriptionProvider>(context, listen: false);
      await subscriptionProvider.fetchAndSetSubscriptionsFromBackend();
    } catch (e) {
      debugPrint('Error initializing subscription provider: $e');
    }
  }

  /// Manually refresh home data
  Future<void> _refreshHomeData() async {
    try {
      debugPrint('🔄 EnhancedHomeScreen: Manual refresh triggered');
      final homeProvider = Provider.of<HomeProvider>(context, listen: false);

      // Force refresh all data
      await homeProvider.fetchHomeData(forceRefresh: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Home data refreshed!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ EnhancedHomeScreen: Error refreshing home data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onSearchTap() {
    setState(() {
      _isSearchActive = true;
    });
  }

  void _onSearchClose() {
    setState(() {
      _isSearchActive = false;
    });
  }

  void _onSearch(String query) async {
    debugPrint('🔍 EnhancedHomeScreen: Search triggered with query: $query');
    setState(() {
      _searchQuery = query;
    });
    _showAdvancedSearchModal();
  }

  void _showAdvancedSearchModal() {
    debugPrint(
        '🔍 EnhancedHomeScreen: Showing advanced search modal with query: $_searchQuery');
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AdvancedSearchModal(
          initialQuery: _searchQuery,
          onResults: (results) {
            debugPrint(
                '🔍 EnhancedHomeScreen: Received ${results.length} search results');
            // Handle search results if needed
          },
          onClose: () {
            debugPrint('🔍 EnhancedHomeScreen: Closing advanced search modal');
            Navigator.of(context).pop();
            setState(() {
              _isSearchActive = false;
            });
          },
        );
      },
    );
  }

  void _onPodcastTap(dynamic podcast) async {
    try {
      final arguments = {
        'id': podcast.id,
        'title': podcast.title ?? 'Unknown Title',
        'creator': podcast.creator ?? 'Unknown Creator',
        'author': podcast.author ?? podcast.creator ?? 'Unknown Author',
        'coverImage': podcast.coverImage ?? '',
        'image': podcast.coverImage ?? '',
        'duration': podcast.duration ?? '',
        'isDownloaded': podcast.isDownloaded ?? false,
        'description': podcast.description ?? 'No description available',
        'category': podcast.category ?? 'General',
        'categories': podcast.categories ?? [],
        'audioUrl': podcast.audioUrl ?? '',
        'url': podcast.url ?? '',
        'originalUrl': podcast.originalUrl ?? '',
        'link': podcast.link ?? '',
        'totalEpisodes': podcast.totalEpisodes ?? 0,
        'episodeCount': podcast.episodeCount ?? 0,
        'languages': podcast.languages ?? [],
        'explicit': podcast.explicit ?? false,
        'isFeatured': podcast.isFeatured ?? false,
        'isSubscribed': podcast.isSubscribed ?? false,
      };

      await _navigationService.navigateTo(AppRoutes.podcastDetailScreen,
          arguments: arguments);
      // Note: Removed navigation failed error message to mute yellow error during navigation
      // The NavigationService handles navigation gracefully and returns null on failure
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error navigating to podcast: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onCategoryTap(dynamic category) {
    _navigationService.navigateTo(AppRoutes.categoryPodcasts, arguments: {
      'id': category.id,
      'name': category.name,
      'icon': category.icon,
      'count': category.count,
      'gradientStart': category.gradientStart,
      'gradientEnd': category.gradientEnd,
    });
  }

  Future<void> _onViewAllCategories() async {
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    await _navigationService
        .navigateTo(AppRoutes.categoriesListScreen, arguments: {
      'categories': homeProvider.categories,
    });
  }

  Future<void> _onSeeAllTrending() async {
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    await _navigationService
        .navigateTo(AppRoutes.trendingPodcastsScreen, arguments: {
      'podcasts': homeProvider.trendingPodcasts,
      'title': 'Trending Now',
    });
  }

  Future<void> _onSeeAllRecommendations() async {
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    await _navigationService
        .navigateTo(AppRoutes.recommendationsScreen, arguments: {
      'podcasts': homeProvider.recommendedPodcasts,
      'title': 'Recommended for You',
    });
  }

  Future<void> _onSeeAllCrimeArchives() async {
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    await _navigationService
        .navigateTo(AppRoutes.crimeArchivesScreen, arguments: {
      'podcasts': homeProvider.crimeArchives,
      'title': 'Crime Archives',
    });
  }

  Future<void> _onSeeAllPodcastForHealth() async {
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    await _navigationService
        .navigateTo(AppRoutes.podcastForHealthScreen, arguments: {
      'podcasts': homeProvider.healthPodcasts,
      'title': 'Podcast for Health',
    });
  }

  // Enhanced subscribe/unsubscribe functionality
  Future<void> _onSubscribe(dynamic podcast) async {
    try {
      // Get the current subscription status from the provider to ensure consistency
      final subscriptionProvider =
          Provider.of<SubscriptionProvider>(context, listen: false);
      final isCurrentlySubscribed =
          subscriptionProvider.isSubscribed(podcast.id.toString());

      await handleSubscribeAction(
        context: context,
        podcastId: podcast.id.toString(),
        isCurrentlySubscribed: isCurrentlySubscribed,
        onStateChanged: (bool subscribed) {
          if (mounted) {
            setState(() {
              // Update subscription status in the UI
              podcast.isSubscribed = subscribed;
            });
            // Note: handleSubscribeAction already updates the subscription provider
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Subscription error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Enhanced podcast play functionality
  Future<void> _onFeaturedPodcastPlay(dynamic podcast) async {
    try {
      // Navigate to podcast detail and play first episode
      _onPodcastTap(podcast);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error playing podcast: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _onTrendingPodcastPlay(dynamic podcast) async {
    try {
      _onPodcastTap(podcast);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error playing podcast: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _onRecommendedPodcastPlay(dynamic podcast) async {
    try {
      _onPodcastTap(podcast);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error playing podcast: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: Column(
        children: [
          const NetworkStatusWidget(),
          SearchHeaderWidget(
            isSearchActive: _isSearchActive,
            onSearchTap: _onSearchTap,
            onSearchClose: _onSearchClose,
            onSearch: _onSearch,
          ),
          // Add refresh button for debugging
          if (_isInitializing)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Initializing... Please wait',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _refreshHomeData,
                    icon: Icon(Icons.refresh),
                    label: Text('Force Refresh'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[700],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Consumer<HomeProvider>(
              builder: (context, homeProvider, child) {
                // Debug logging to help troubleshoot
                debugPrint('🔍 EnhancedHomeScreen state check:');
                debugPrint('  - isLoading: ${homeProvider.isLoading}');
                debugPrint('  - error: ${homeProvider.error}');
                debugPrint(
                    '  - homeData exists: ${homeProvider.homeData != null}');
                debugPrint('  - hasData: ${homeProvider.hasData}');

                if (homeProvider.homeData != null) {
                  debugPrint('🔍 EnhancedHomeScreen data check:');
                  debugPrint(
                      '  - homeData exists: ${homeProvider.homeData != null}');
                  debugPrint('  - hasData: ${homeProvider.hasData}');
                  debugPrint(
                      '  - hasContent: ${homeProvider.homeData!.hasContent}');
                  debugPrint(
                      '  - Featured: ${homeProvider.homeData!.featuredPodcasts.length}');
                  debugPrint(
                      '  - Health: ${homeProvider.homeData!.healthPodcasts.length}');
                  debugPrint(
                      '  - Categories: ${homeProvider.homeData!.categories.length}');
                  debugPrint(
                      '  - Crime Archives: ${homeProvider.homeData!.crimeArchives.length}');
                  debugPrint(
                      '  - Recommended: ${homeProvider.homeData!.recommendedPodcasts.length}');
                  debugPrint(
                      '  - Trending: ${homeProvider.homeData!.trendingPodcasts.length}');

                  // Additional categories debugging
                  if (homeProvider.homeData!.categories.isNotEmpty) {
                    debugPrint('🔍 Categories details:');
                    for (int i = 0;
                        i < homeProvider.homeData!.categories.length;
                        i++) {
                      final category = homeProvider.homeData!.categories[i];
                      debugPrint(
                          '  - Category $i: ${category.name} (ID: ${category.id})');
                    }
                  } else {
                    debugPrint('⚠️ No categories found in homeData');
                  }
                }

                // Priority 1: If we have data, show it regardless of loading state
                if (homeProvider.homeData != null && homeProvider.hasData) {
                  debugPrint(
                      '🔍 EnhancedHomeScreen: Showing content - data exists and has content');

                  // Show content with pull-to-refresh
                  return RefreshIndicator(
                    onRefresh: () => homeProvider.backgroundRefresh(),
                    child: _buildContent(homeProvider),
                  );
                }

                // Priority 2: Show skeleton loading while initializing or when truly loading and no data exists
                // But only if we're not in the middle of a background refresh
                if (_isInitializing && !homeProvider.isRefreshing) {
                  debugPrint(
                      '🔍 EnhancedHomeScreen: Showing skeleton - initializing: $_isInitializing');
                  return const HomeScreenSkeleton();
                }

                // Priority 3: Show error state when there's an error and no data
                if (homeProvider.error != null &&
                    homeProvider.homeData == null) {
                  debugPrint(
                      '🔍 EnhancedHomeScreen: Showing error - error exists, no data');
                  return _buildErrorState(homeProvider);
                }

                // Priority 4: Show empty state when we have data structure but no content
                if (homeProvider.homeData != null && !homeProvider.hasData) {
                  debugPrint(
                      '🔍 EnhancedHomeScreen: Showing empty state - data exists but no content');
                  return _buildEmptyState();
                }

                // Priority 5: Fallback - try to load cached data one more time
                debugPrint(
                    '🔍 EnhancedHomeScreen: Fallback - attempting to load cached data');
                debugPrint(
                    '🔍 EnhancedHomeScreen: Final state - isLoading: ${homeProvider.isLoading}, homeData: ${homeProvider.homeData != null}, hasData: ${homeProvider.hasData}');

                // Try to load cached data as a last resort
                homeProvider.loadCachedData().then((_) {
                  if (mounted) {
                    setState(() {});
                  }
                });

                return const HomeScreenSkeleton();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(HomeProvider homeProvider) {
    final data = homeProvider.homeData!;

    return CustomScrollView(
      controller: _scrollController,
      physics: SmoothScrollUtils.defaultPhysics,
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FeaturedPodcastsSectionWidget(
                podcasts: data.featuredPodcasts,
                onPodcastTap: _onPodcastTap,
                onPlayEpisode: (podcast, _) => _onFeaturedPodcastPlay(podcast),
                isLoading: homeProvider.isLoading,
              ),
              const SizedBox(height: 24),
              CategoriesSectionWidget(
                categories: data.categories,
                onCategoryTap: _onCategoryTap,
                onViewAllTap: _onViewAllCategories,
                isLoading: homeProvider.isLoading,
              ),
              const SizedBox(height: 24),
              // Add Trending section back
              PodcastCategorySectionWidget(
                title: 'Trending Now',
                podcasts: data.trendingPodcasts,
                onPodcastTap: _onPodcastTap,
                onSeeAll: _onSeeAllTrending,
                isLoading: homeProvider.isLoading,
                onPlayEpisode: (podcast, _) => _onTrendingPodcastPlay(podcast),
                onSubscribe: (podcast, _) => _onSubscribe(podcast),
              ),
              const SizedBox(height: 24),
              // Crime Archives Section
              _buildCrimeArchivesSection(data.crimeArchives, homeProvider),
              const SizedBox(height: 24),
              // Health Podcasts Section
              _buildHealthPodcastsSection(data.healthPodcasts, homeProvider),
              const SizedBox(height: 40),
              PodcastCategorySectionWidget(
                title: 'Recommended for You',
                podcasts: data.recommendedPodcasts,
                onPodcastTap: _onPodcastTap,
                onSeeAll: _onSeeAllRecommendations,
                isLoading: homeProvider.isLoading,
                onPlayEpisode: (podcast, _) =>
                    _onRecommendedPodcastPlay(podcast),
                onSubscribe: (podcast, _) => _onSubscribe(podcast),
              ),
              const SizedBox(height: 16), // Reduced from 80px to 16px
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCrimeArchivesSection(
      List<dynamic> podcasts, HomeProvider homeProvider) {
    return Consumer<SubscriptionProvider>(
      builder: (context, subscriptionProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Crime Archives",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.deepPurple[900],
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  GestureDetector(
                    onTap: _onSeeAllCrimeArchives,
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View All',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.deepPurple[700],
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.deepPurple[700],
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            homeProvider.isLoading && podcasts.isEmpty
                ? SizedBox(
                    height: 220,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : podcasts.isEmpty
                    ? Center(
                        child: Text(
                          'No Crime Archives podcasts available',
                          style: TextStyle(
                            color: Colors.deepPurple[700],
                            fontSize: 16,
                          ),
                        ),
                      )
                    : SizedBox(
                        height: 38.h,
                        child: PageView.builder(
                          controller: PageController(viewportFraction: 0.95),
                          itemCount: (podcasts.length / 2).ceil(),
                          itemBuilder: (context, pageIndex) {
                            final start = pageIndex * 2;
                            final end = (start + 2) > podcasts.length
                                ? podcasts.length
                                : (start + 2);
                            final pageItems = podcasts.sublist(start, end);
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children:
                                  List.generate(pageItems.length, (index) {
                                final podcast = pageItems[index];
                                // Get real-time subscription status
                                final isSubscribed = subscriptionProvider
                                    .isSubscribed(podcast.id.toString());

                                return Expanded(
                                  child: Container(
                                    margin: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 8),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.08),
                                          blurRadius: 12,
                                          offset: Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Stack(
                                      children: [
                                        // Podcast image as background (clickable)
                                        GestureDetector(
                                          onTap: () => _onPodcastTap(podcast),
                                          behavior: HitTestBehavior.opaque,
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            child: CustomImageWidget(
                                              imageUrl: podcast.coverImage,
                                              width: double.infinity,
                                              height: double.infinity,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        // Gradient overlay for readability
                                        Positioned.fill(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Colors.transparent,
                                                  Colors.black.withOpacity(0.7),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Content overlay
                                        Positioned(
                                          left: 0,
                                          right: 0,
                                          bottom: 0,
                                          child: Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                GestureDetector(
                                                  onTap: () =>
                                                      _onPodcastTap(podcast),
                                                  behavior:
                                                      HitTestBehavior.opaque,
                                                  child: Text(
                                                    podcast.title,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleMedium
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.white,
                                                        ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  podcast.creator,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                        color: Colors.white70,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  podcast.description,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: Colors.white,
                                                      ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        // Subscribe Button (top right) - Now uses real-time subscription status
                                        Positioned(
                                          top: 12,
                                          right: 12,
                                          child: GestureDetector(
                                            onTap: () => _onSubscribe(podcast),
                                            behavior: HitTestBehavior.opaque,
                                            child: Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.10),
                                                    blurRadius: 4,
                                                    offset: Offset(0, 1),
                                                  ),
                                                ],
                                              ),
                                              child: Center(
                                                child: SubscribeButton(
                                                  isSubscribed: isSubscribed,
                                                  isLoading: false,
                                                  onPressed: () =>
                                                      _onSubscribe(podcast),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            );
                          },
                        ),
                      ),
          ],
        );
      },
    );
  }

  Widget _buildHealthPodcastsSection(
      List<dynamic> podcasts, HomeProvider homeProvider) {
    return Consumer<SubscriptionProvider>(
      builder: (context, subscriptionProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Podcast for Health",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.green[800],
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  GestureDetector(
                    onTap: _onSeeAllPodcastForHealth,
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View All',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.green[700],
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 38.h,
              child: homeProvider.isLoading && podcasts.isEmpty
                  ? Center(child: CircularProgressIndicator())
                  : podcasts.isEmpty
                      ? Center(
                          child: Text(
                            'No Health podcasts available',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontSize: 16,
                            ),
                          ),
                        )
                      : PageView.builder(
                          controller: PageController(viewportFraction: 0.95),
                          itemCount: (podcasts.length / 2).ceil(),
                          itemBuilder: (context, pageIndex) {
                            final start = pageIndex * 2;
                            final end = (start + 2) > podcasts.length
                                ? podcasts.length
                                : (start + 2);
                            final pageItems = podcasts.sublist(start, end);
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children:
                                  List.generate(pageItems.length, (index) {
                                final podcast = pageItems[index];
                                // Get real-time subscription status
                                final isSubscribed = subscriptionProvider
                                    .isSubscribed(podcast.id.toString());

                                return Expanded(
                                  child: Container(
                                    margin: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 8),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.08),
                                          blurRadius: 12,
                                          offset: Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Stack(
                                      children: [
                                        // Podcast image as background (clickable)
                                        GestureDetector(
                                          onTap: () => _onPodcastTap(podcast),
                                          behavior: HitTestBehavior.opaque,
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            child: CustomImageWidget(
                                              imageUrl: podcast.coverImage,
                                              width: double.infinity,
                                              height: double.infinity,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        // Gradient overlay for readability
                                        Positioned.fill(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Colors.transparent,
                                                  Colors.black.withOpacity(0.7),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Content overlay
                                        Positioned(
                                          left: 0,
                                          right: 0,
                                          bottom: 0,
                                          child: Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                GestureDetector(
                                                  onTap: () =>
                                                      _onPodcastTap(podcast),
                                                  behavior:
                                                      HitTestBehavior.opaque,
                                                  child: Text(
                                                    podcast.title,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleMedium
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.white,
                                                        ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  podcast.creator,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                        color: Colors.white70,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  podcast.description,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: Colors.white,
                                                      ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        // Subscribe Button (top right)
                                        Positioned(
                                          top: 12,
                                          right: 12,
                                          child: GestureDetector(
                                            onTap: () => _onSubscribe(podcast),
                                            behavior: HitTestBehavior.opaque,
                                            child: Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.10),
                                                    blurRadius: 4,
                                                    offset: Offset(0, 1),
                                                  ),
                                                ],
                                              ),
                                              child: Center(
                                                child: SubscribeButton(
                                                  isSubscribed: isSubscribed,
                                                  isLoading: false,
                                                  onPressed: () =>
                                                      _onSubscribe(podcast),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            );
                          },
                        ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildErrorState(HomeProvider homeProvider) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 20.w,
              color: AppTheme.lightTheme.colorScheme.error,
            ),
            SizedBox(height: 4.h),
            Text(
              'Something went wrong',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            Text(
              homeProvider.error ?? 'Unknown error occurred',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            // Show different actions based on error type
            if (homeProvider.isOffline) ...[
              Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.wifi_off, color: Colors.orange[700], size: 20),
                    SizedBox(width: 2.w),
                    Text(
                      'You\'re offline',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                'Check your internet connection and try again',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 3.h),
            ] else ...[
              SizedBox(height: 3.h),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => homeProvider.forceRefresh(),
                  icon: Icon(Icons.refresh),
                  label: Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding:
                        EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                  ),
                ),
                SizedBox(width: 3.w),
                OutlinedButton.icon(
                  onPressed: () => homeProvider.backgroundRefresh(),
                  icon: Icon(Icons.download),
                  label: Text('Load Cached'),
                  style: OutlinedButton.styleFrom(
                    padding:
                        EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Consumer<HomeProvider>(
      builder: (context, homeProvider, child) {
        return Center(
          child: Padding(
            padding: EdgeInsets.all(6.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.podcasts_outlined,
                  size: 20.w,
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
                SizedBox(height: 4.h),
                Text(
                  homeProvider.isOffline
                      ? 'No cached content'
                      : 'No podcasts available',
                  style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 2.h),
                Text(
                  homeProvider.isOffline
                      ? 'You\'re offline and no cached content is available'
                      : 'Check back later for new content',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (homeProvider.isOffline) ...[
                  SizedBox(height: 3.h),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.wifi_off,
                            color: Colors.orange[700], size: 20),
                        SizedBox(width: 2.w),
                        Text(
                          'Connect to internet to load content',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: 3.h),
                ElevatedButton.icon(
                  onPressed: () => homeProvider.forceRefresh(),
                  icon: Icon(Icons.refresh),
                  label: Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding:
                        EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
