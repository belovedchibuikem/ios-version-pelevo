import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/common_bottom_navigation_widget.dart';
import './widgets/trending_filter_widget.dart';
import './widgets/trending_list_widget.dart';
import './widgets/trending_search_widget.dart';
import '../../core/routes/app_routes.dart';

// lib/presentation/trending_podcasts_screen/trending_podcasts_screen.dart

class TrendingPodcastsScreen extends StatefulWidget {
  final List<dynamic>? podcasts;
  const TrendingPodcastsScreen({super.key, this.podcasts});

  @override
  State<TrendingPodcastsScreen> createState() => _TrendingPodcastsScreenState();
}

class _TrendingPodcastsScreenState extends State<TrendingPodcastsScreen> {
  final NavigationService _navigationService = NavigationService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _filteredPodcasts = [];
  String _selectedTimeFilter = 'week';
  String _selectedSortFilter = 'popular';
  bool _isSearchActive = false;

  late final List<Map<String, dynamic>> _allTrendingPodcasts;

  @override
  void initState() {
    super.initState();
    // Use provided podcasts if available, otherwise fallback to mock data
    if (widget.podcasts != null && widget.podcasts!.isNotEmpty) {
      _allTrendingPodcasts = widget.podcasts!
          .map((p) => p is Map<String, dynamic>
              ? p
              : (p.toJson != null
                  ? p.toJson() as Map<String, dynamic>
                  : <String, dynamic>{}))
          .toList();
    } else {
      _allTrendingPodcasts = [
        {
          "id": 1,
          "title": "Crime Junkie",
          "creator": "Ashley Flowers",
          "coverImage":
              "https://images.pexels.com/photos/6257/Flatlay-Iron-Notebooks.jpg?w=300&h=300&fit=crop",
          "duration": "1h 15m",
          "isDownloaded": false,
          "category": "True Crime",
          "trendingRank": 1,
          "listenerGrowth": "+25%",
          "listeners": "2.5M",
          "description":
              "Weekly true crime podcast covering missing persons and murders",
          "tags": ["trending", "popular"]
        },
        {
          "id": 2,
          "title": "The Joe Rogan Experience",
          "creator": "Joe Rogan",
          "coverImage":
              "https://images.pixabay.com/photo/2020/02/06/20/01/university-4825366_1280.jpg?w=300&h=300&fit=crop",
          "duration": "2h 45m",
          "isDownloaded": true,
          "category": "Comedy",
          "trendingRank": 2,
          "listenerGrowth": "+18%",
          "listeners": "11M",
          "description": "Long form conversations with interesting people",
          "tags": ["comedy", "interviews"]
        },
        {
          "id": 3,
          "title": "Call Her Daddy",
          "creator": "Alex Cooper",
          "coverImage":
              "https://images.unsplash.com/photo-1478737270239-2f02b77fc618?w=300&h=300&fit=crop",
          "duration": "55m",
          "isDownloaded": false,
          "category": "Society & Culture",
          "trendingRank": 3,
          "listenerGrowth": "+32%",
          "listeners": "3.8M",
          "description":
              "Unfiltered conversations about relationships and pop culture",
          "tags": ["trending", "culture"]
        },
        {
          "id": 4,
          "title": "The Daily",
          "creator": "The New York Times",
          "coverImage":
              "https://images.pexels.com/photos/261909/pexels-photo-261909.jpeg?w=300&h=300&fit=crop",
          "duration": "25m",
          "isDownloaded": true,
          "category": "News",
          "trendingRank": 4,
          "listenerGrowth": "+12%",
          "listeners": "4.2M",
          "description": "Daily news podcast from The New York Times",
          "tags": ["news", "daily"]
        },
        {
          "id": 5,
          "title": "Huberman Lab",
          "creator": "Andrew Huberman",
          "coverImage":
              "https://images.pixabay.com/photo/2017/03/29/15/18/tianjin-2185510_1280.jpg?w=300&h=300&fit=crop",
          "duration": "1h 45m",
          "isDownloaded": false,
          "category": "Science",
          "trendingRank": 5,
          "listenerGrowth": "+28%",
          "listeners": "1.9M",
          "description": "Science-based tools for everyday life",
          "tags": ["science", "health"]
        },
        {
          "id": 6,
          "title": "SmartLess",
          "creator": "Jason Bateman, Sean Hayes, Will Arnett",
          "coverImage":
              "https://images.unsplash.com/photo-1590602847861-f357a9332bbc?w=300&h=300&fit=crop",
          "duration": "1h 10m",
          "isDownloaded": false,
          "category": "Comedy",
          "trendingRank": 6,
          "listenerGrowth": "+15%",
          "listeners": "2.1M",
          "description": "Comedy podcast with celebrity guests",
          "tags": ["comedy", "celebrity"]
        },
      ];
    }
    _filteredPodcasts = _allTrendingPodcasts;
    _navigationService.trackNavigation(AppRoutes.trendingPodcastsScreen);
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredPodcasts = _allTrendingPodcasts;
        _isSearchActive = false;
      } else {
        _filteredPodcasts = _allTrendingPodcasts
            .where((podcast) =>
                podcast['title'].toLowerCase().contains(query.toLowerCase()) ||
                podcast['creator'].toLowerCase().contains(query.toLowerCase()))
            .toList();
        _isSearchActive = true;
      }
      _applySorting();
    });
  }

  void _onTimeFilterChanged(String filter) {
    setState(() {
      _selectedTimeFilter = filter;
      _applySorting();
    });
  }

  void _onSortFilterChanged(String filter) {
    setState(() {
      _selectedSortFilter = filter;
      _applySorting();
    });
  }

  void _applySorting() {
    setState(() {
      switch (_selectedSortFilter) {
        case 'popular':
          _filteredPodcasts
              .sort((a, b) => a['trendingRank'].compareTo(b['trendingRank']));
          break;
        case 'growth':
          _filteredPodcasts.sort((a, b) {
            final aGrowth = int.parse(
                a['listenerGrowth'].replaceAll(RegExp(r'[^0-9]'), ''));
            final bGrowth = int.parse(
                b['listenerGrowth'].replaceAll(RegExp(r'[^0-9]'), ''));
            return bGrowth.compareTo(aGrowth);
          });
          break;
        case 'recent':
          // For demo purposes, reverse the trending rank for "recent"
          _filteredPodcasts
              .sort((a, b) => b['trendingRank'].compareTo(a['trendingRank']));
          break;
      }
    });
  }

  void _onPodcastTap(Map<String, dynamic> podcast) {
    _navigationService.navigateTo(AppRoutes.podcastDetailScreen,
        arguments: podcast);
  }

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      // Simulate refreshed trending data
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildHeader(),
          TrendingSearchWidget(
            controller: _searchController,
            onChanged: _onSearchChanged,
            isActive: _isSearchActive,
          ),
          TrendingFilterWidget(
            selectedTimeFilter: _selectedTimeFilter,
            selectedSortFilter: _selectedSortFilter,
            onTimeFilterChanged: _onTimeFilterChanged,
            onSortFilterChanged: _onSortFilterChanged,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              color: AppTheme.lightTheme.colorScheme.primary,
              child: TrendingListWidget(
                podcasts: _filteredPodcasts,
                onPodcastTap: _onPodcastTap,
                scrollController: _scrollController,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 2.h,
        left: 4.w,
        right: 4.w,
        bottom: 2.h,
      ),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _navigationService.goBack(),
            child: Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.lightTheme.colorScheme.outline.withAlpha(51),
                ),
              ),
              child: CustomIconWidget(
                iconName: 'arrow_back_ios',
                color: AppTheme.lightTheme.colorScheme.onSurface,
                size: 20,
              ),
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trending Now',
                  style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  '${_filteredPodcasts.length} trending podcasts',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
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
