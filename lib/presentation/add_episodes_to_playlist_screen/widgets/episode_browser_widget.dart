import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/podcastindex_service.dart';
import 'episode_search_widget.dart';

class EpisodeBrowserWidget extends StatefulWidget {
  final Set<int> selectedEpisodes;
  final Function(int) onEpisodeToggle;
  final VoidCallback? onEpisodesSelected;

  const EpisodeBrowserWidget({
    super.key,
    required this.selectedEpisodes,
    required this.onEpisodeToggle,
    this.onEpisodesSelected,
  });

  @override
  State<EpisodeBrowserWidget> createState() => _EpisodeBrowserWidgetState();
}

class _EpisodeBrowserWidgetState extends State<EpisodeBrowserWidget>
    with TickerProviderStateMixin {
  final PodcastIndexService _podcastService = PodcastIndexService();
  final TextEditingController _searchController = TextEditingController();

  late TabController _tabController;
  List<Map<String, dynamic>> _episodes = [];
  List<Map<String, dynamic>> _filteredEpisodes = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  bool _showSearch = false;

  // Pagination
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_onTabChanged);
    _testApiConnection();
    _loadEpisodes();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      // Reset pagination when switching tabs
      _currentPage = 1;
      _hasMore = true;
      _episodes.clear();
      _filteredEpisodes.clear();
      _loadEpisodes();
    }
  }

  Future<void> _testApiConnection() async {
    try {
      debugPrint('Testing API connection...');
      final categories = await _podcastService.getCategories();
      debugPrint(
          'API connection successful. Found ${categories.length} categories.');
    } catch (e) {
      debugPrint('API connection failed: $e');
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEpisodes({bool loadMore = false}) async {
    if (_isLoading || _isLoadingMore) return;

    if (loadMore) {
      setState(() => _isLoadingMore = true);
      _currentPage++;
    } else {
      setState(() {
        _isLoading = true;
        _error = null;
        _currentPage = 1;
        _hasMore = true;
      });
    }

    // Add timeout to prevent infinite loading
    Timer(const Duration(seconds: 30), () {
      if (mounted && _isLoading) {
        setState(() {
          _error = 'Request timed out. Please try again.';
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    });

    try {
      List<Map<String, dynamic>> newEpisodes = [];

      debugPrint(
          'Loading episodes for tab index: ${_tabController.index} (page: $_currentPage)');

      switch (_tabController.index) {
        case 0: // Featured
          debugPrint('Loading featured podcasts...');
          try {
            final podcasts = await _podcastService.getFeaturedPodcasts();
            debugPrint('Found ${podcasts.length} featured podcasts');
            if (podcasts.isNotEmpty) {
              newEpisodes = await _fetchEpisodesForPodcasts(podcasts,
                  page: _currentPage, perPage: 3);
            } else {
              debugPrint('No featured podcasts found, using fallback');
              newEpisodes = _createFallbackEpisodes();
            }
          } catch (e) {
            debugPrint('Error loading featured podcasts: $e');
            newEpisodes = _createFallbackEpisodes();
          }
          break;
        case 1: // Trending
          debugPrint('Loading trending podcasts...');
          try {
            final podcasts = await _podcastService.getTrendingPodcasts();
            debugPrint('Found ${podcasts.length} trending podcasts');
            if (podcasts.isNotEmpty) {
              newEpisodes = await _fetchEpisodesForPodcasts(podcasts,
                  page: _currentPage, perPage: 3);
            } else {
              debugPrint('No trending podcasts found, using fallback');
              newEpisodes = _createFallbackEpisodes();
            }
          } catch (e) {
            debugPrint('Error loading trending podcasts: $e');
            newEpisodes = _createFallbackEpisodes();
          }
          break;
        case 2: // New
          debugPrint('Loading new podcasts...');
          try {
            final podcasts = await _podcastService.getNewPodcasts();
            debugPrint('Found ${podcasts.length} new podcasts');
            if (podcasts.isNotEmpty) {
              newEpisodes = await _fetchEpisodesForPodcasts(podcasts,
                  page: _currentPage, perPage: 3);
            } else {
              debugPrint('No new podcasts found, using fallback');
              newEpisodes = _createFallbackEpisodes();
            }
          } catch (e) {
            debugPrint('Error loading new podcasts: $e');
            newEpisodes = _createFallbackEpisodes();
          }
          break;
        case 3: // True Crime
          debugPrint('Loading true crime podcasts...');
          try {
            final podcasts = await _podcastService.getTrueCrimePodcasts();
            debugPrint('Found ${podcasts.length} true crime podcasts');
            if (podcasts.isNotEmpty) {
              newEpisodes = await _fetchEpisodesForPodcasts(podcasts,
                  page: _currentPage, perPage: 3);
            } else {
              debugPrint('No true crime podcasts found, using fallback');
              newEpisodes = _createFallbackEpisodes();
            }
          } catch (e) {
            debugPrint('Error loading true crime podcasts: $e');
            newEpisodes = _createFallbackEpisodes();
          }
          break;
      }

      debugPrint('Loaded ${newEpisodes.length} episodes total');

      if (loadMore) {
        _episodes.addAll(newEpisodes);
      } else {
        _episodes = newEpisodes;
      }

      // Check if there are more episodes to load
      // We consider there are more episodes if:
      // 1. We got some episodes in this batch
      // 2. We're not at the end of available podcasts
      _hasMore = newEpisodes.isNotEmpty &&
          _currentPage * 3 < 50; // Limit to ~50 podcasts total
      _filterEpisodes();

      debugPrint('After filtering: ${_filteredEpisodes.length} episodes');

      if (mounted) {
        if (loadMore) {
          setState(() => _isLoadingMore = false);
        } else {
          setState(() => _isLoading = false);
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading episodes: $e');
      debugPrint('Stack trace: $stackTrace');

      // If we have no episodes and there's an error, try fallback approach
      List<Map<String, dynamic>> newEpisodes = _createFallbackEpisodes();

      if (loadMore) {
        _episodes.addAll(newEpisodes);
      } else {
        _episodes = newEpisodes;
      }

      _hasMore = newEpisodes.isNotEmpty;
      _filterEpisodes();

      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchEpisodesForPodcasts(
      List<dynamic> podcasts,
      {int page = 1,
      int perPage = 10}) async {
    List<Map<String, dynamic>> allEpisodes = [];

    debugPrint(
        'Fetching episodes for ${podcasts.length} podcasts (page: $page, perPage: $perPage)');

    if (podcasts.isEmpty) {
      debugPrint('No podcasts to fetch episodes for');
      return allEpisodes;
    }

    // Calculate which podcasts to process for this page
    final startIndex = (page - 1) * perPage;
    final endIndex = startIndex + perPage;
    final podcastsToProcess = podcasts.skip(startIndex).take(perPage).toList();

    debugPrint(
        'Processing podcasts ${startIndex + 1} to ${startIndex + podcastsToProcess.length}');

    for (final podcast in podcastsToProcess) {
      try {
        debugPrint('Processing podcast: $podcast');

        final feedId =
            podcast['feedId']?.toString() ?? podcast['id']?.toString();
        debugPrint(
            'Processing podcast: ${podcast['title']} with feedId: $feedId');

        if (feedId != null) {
          debugPrint('Fetching episodes for feedId: $feedId');
          try {
            // Add timeout for individual podcast requests
            final episodeData = await _podcastService
                .getPodcastDetailsWithEpisodes(feedId)
                .timeout(const Duration(seconds: 10));
            debugPrint('Episode data received: $episodeData');

            final episodes = episodeData['episodes'] as List<dynamic>? ?? [];

            debugPrint(
                'Found ${episodes.length} episodes for podcast ${podcast['title']}');

            // Limit episodes per podcast to prevent overwhelming
            final limitedEpisodes = episodes.take(5).toList();

            for (final episode in limitedEpisodes) {
              allEpisodes.add({
                ...episode,
                'podcast': podcast,
              });
            }
          } catch (e) {
            debugPrint(
                'Timeout or error fetching episodes for podcast ${podcast['title']}: $e');
            // Continue with next podcast
          }
        } else {
          debugPrint('No feedId found for podcast: ${podcast['title']}');
        }
      } catch (e, stackTrace) {
        debugPrint(
            'Error fetching episodes for podcast ${podcast['title']}: $e');
        debugPrint('Stack trace: $stackTrace');
        // Continue with other podcasts even if one fails
      }
    }

    debugPrint('Total episodes found: ${allEpisodes.length}');
    return allEpisodes;
  }

  List<Map<String, dynamic>> _createFallbackEpisodes() {
    debugPrint('Creating fallback episodes for testing');
    return [
      {
        'id': 1,
        'title': 'Sample Episode 1',
        'description': 'This is a sample episode for testing purposes.',
        'duration': 1800, // 30 minutes
        'coverImage': 'https://via.placeholder.com/300x300',
        'podcast': {
          'id': 1,
          'title': 'Sample Podcast',
          'author': 'Sample Author',
          'feedId': 'sample-feed-1',
        },
      },
      {
        'id': 2,
        'title': 'Sample Episode 2',
        'description': 'Another sample episode for testing.',
        'duration': 2400, // 40 minutes
        'coverImage': 'https://via.placeholder.com/300x300',
        'podcast': {
          'id': 2,
          'title': 'Another Podcast',
          'author': 'Another Author',
          'feedId': 'sample-feed-2',
        },
      },
      {
        'id': 3,
        'title': 'Sample Episode 3',
        'description': 'Yet another sample episode.',
        'duration': 1200, // 20 minutes
        'coverImage': 'https://via.placeholder.com/300x300',
        'podcast': {
          'id': 3,
          'title': 'Third Podcast',
          'author': 'Third Author',
          'feedId': 'sample-feed-3',
        },
      },
    ];
  }

  void _filterEpisodes() {
    if (_searchQuery.isEmpty) {
      _filteredEpisodes = List.from(_episodes);
    } else {
      final query = _searchQuery.toLowerCase();
      _filteredEpisodes = _episodes.where((episode) {
        final title = episode['title']?.toString().toLowerCase() ?? '';
        final author =
            episode['podcast']?['author']?.toString().toLowerCase() ?? '';
        final podcastTitle =
            episode['podcast']?['title']?.toString().toLowerCase() ?? '';

        return title.contains(query) ||
            author.contains(query) ||
            podcastTitle.contains(query);
      }).toList();
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _filterEpisodes();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: EdgeInsets.all(4.w),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search episodes...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: AppTheme.lightTheme.colorScheme.surfaceContainer,
            ),
          ),
        ),

        // Tab bar
        TabBar(
          controller: _tabController,
          onTap: (index) {
            if (index == 4) {
              setState(() => _showSearch = true);
            } else {
              setState(() => _showSearch = false);
              _loadEpisodes();
            }
          },
          tabs: const [
            Tab(text: 'Featured'),
            Tab(text: 'Trending'),
            Tab(text: 'New'),
            Tab(text: 'True Crime'),
            Tab(icon: Icon(Icons.search), text: 'Search'),
          ],
        ),

        // Content
        Expanded(
          child: _showSearch
              ? EpisodeSearchWidget(
                  selectedEpisodes: widget.selectedEpisodes,
                  onEpisodeToggle: widget.onEpisodeToggle,
                )
              : _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _buildErrorState()
                      : _filteredEpisodes.isEmpty
                          ? _buildEmptyState()
                          : _buildEpisodesList(),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppTheme.lightTheme.colorScheme.error,
          ),
          SizedBox(height: 2.h),
          Text(
            'Error loading episodes',
            style: AppTheme.lightTheme.textTheme.titleMedium,
          ),
          SizedBox(height: 1.h),
          Text(
            _error!,
            style: AppTheme.lightTheme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2.h),
          ElevatedButton(
            onPressed: () => _loadEpisodes(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'search',
            size: 80,
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
          SizedBox(height: 3.h),
          Text(
            _searchQuery.isEmpty
                ? 'No Episodes Available'
                : 'No Episodes Found',
            style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2.h),
          Text(
            _searchQuery.isEmpty
                ? 'Check back later for new episodes'
                : 'Try adjusting your search terms',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodesList() {
    return RefreshIndicator(
      onRefresh: () => _loadEpisodes(),
      child: ListView.separated(
        padding: EdgeInsets.all(4.w),
        itemCount: _filteredEpisodes.length + (_hasMore ? 1 : 0),
        separatorBuilder: (context, index) => SizedBox(height: 2.h),
        itemBuilder: (context, index) {
          if (index == _filteredEpisodes.length && _hasMore) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: _isLoadingMore
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: () {
                          setState(() => _currentPage++);
                          _loadEpisodes(loadMore: true);
                        },
                        child: const Text('Load More'),
                      ),
              ),
            );
          }

          final episode = _filteredEpisodes[index];
          final episodeId = episode['id'] as int? ?? 0;
          final isSelected = widget.selectedEpisodes.contains(episodeId);

          return Card(
            child: InkWell(
              onTap: () => widget.onEpisodeToggle(episodeId),
              child: Padding(
                padding: EdgeInsets.all(3.w),
                child: Row(
                  children: [
                    // Selection checkbox
                    Checkbox(
                      value: isSelected,
                      onChanged: (value) => widget.onEpisodeToggle(episodeId),
                    ),
                    SizedBox(width: 2.w),

                    // Episode image
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: AppTheme.lightTheme.colorScheme.surfaceContainer,
                      ),
                      child: CustomImageWidget(
                        imageUrl: episode['coverImage'] ?? '',
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(width: 4.w),

                    // Episode details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            episode['title'] ?? 'Unknown Episode',
                            style: AppTheme.lightTheme.textTheme.titleMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 1.h),
                          Text(
                            episode['podcast']?['author'] ?? 'Unknown Author',
                            style: AppTheme.lightTheme.textTheme.bodySmall,
                          ),
                          SizedBox(height: 0.5.h),
                          Row(
                            children: [
                              CustomIconWidget(
                                iconName: 'podcast',
                                size: 16,
                                color: AppTheme
                                    .lightTheme.colorScheme.onSurfaceVariant,
                              ),
                              SizedBox(width: 1.w),
                              Expanded(
                                child: Text(
                                  episode['podcast']?['title'] ??
                                      'Unknown Podcast',
                                  style:
                                      AppTheme.lightTheme.textTheme.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (episode['duration'] != null) ...[
                            SizedBox(height: 0.5.h),
                            Text(
                              _formatDuration(episode['duration']),
                              style: AppTheme.lightTheme.textTheme.bodySmall
                                  ?.copyWith(
                                color: AppTheme.lightTheme.colorScheme.tertiary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDuration(dynamic duration) {
    if (duration == null) return '';

    int seconds;
    if (duration is int) {
      seconds = duration;
    } else if (duration is String) {
      seconds = int.tryParse(duration) ?? 0;
    } else {
      return '';
    }

    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${remainingSeconds}s';
    } else {
      return '${remainingSeconds}s';
    }
  }
}
