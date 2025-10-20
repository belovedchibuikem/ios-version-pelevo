import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/podcastindex_service.dart';

class EpisodeSearchWidget extends StatefulWidget {
  final Set<int> selectedEpisodes;
  final Function(int) onEpisodeToggle;

  const EpisodeSearchWidget({
    super.key,
    required this.selectedEpisodes,
    required this.onEpisodeToggle,
  });

  @override
  State<EpisodeSearchWidget> createState() => _EpisodeSearchWidgetState();
}

class _EpisodeSearchWidgetState extends State<EpisodeSearchWidget> {
  final PodcastIndexService _podcastService = PodcastIndexService();
  final TextEditingController _searchController = TextEditingController();
  final List<String> _recentSearches = [];

  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  String? _error;
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadRecentSearches() {
    // TODO: Load from shared preferences
    _recentSearches.addAll([
      'true crime',
      'health',
      'technology',
      'business',
      'comedy',
    ]);
  }

  void _addToRecentSearches(String query) {
    if (query.isNotEmpty && !_recentSearches.contains(query)) {
      setState(() {
        _recentSearches.insert(0, query);
        if (_recentSearches.length > 10) {
          _recentSearches.removeLast();
        }
      });
      // TODO: Save to shared preferences
    }
  }

    Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _currentQuery = '';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _error = null;
      _currentQuery = query;
    });

    try {
      final podcasts = await _podcastService.searchPodcasts(query);
      final episodes = await _fetchEpisodesForPodcasts(podcasts);
      
      if (mounted) {
        setState(() {
          _searchResults = episodes;
          _isSearching = false;
        });
        _addToRecentSearches(query);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isSearching = false;
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchEpisodesForPodcasts(List<dynamic> podcasts) async {
    List<Map<String, dynamic>> allEpisodes = [];
    
    for (final podcast in podcasts) {
      try {
        final feedId = podcast['feedId']?.toString() ?? podcast['id']?.toString();
        if (feedId != null) {
          final episodeData = await _podcastService.getPodcastDetailsWithEpisodes(feedId);
          final episodes = episodeData['episodes'] as List<dynamic>? ?? [];
          
          for (final episode in episodes) {
            allEpisodes.add({
              ...episode,
              'podcast': podcast,
            });
          }
        }
      } catch (e) {
        debugPrint('Error fetching episodes for podcast ${podcast['title']}: $e');
        // Continue with other podcasts even if one fails
      }
    }
    
    return allEpisodes;
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
            onSubmitted: _performSearch,
            decoration: InputDecoration(
              hintText: 'Search episodes, podcasts, or authors...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _performSearch('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: AppTheme.lightTheme.colorScheme.surfaceContainer,
            ),
          ),
        ),

        // Content
        Expanded(
          child: _buildContent(),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_currentQuery.isEmpty) {
      return _buildSearchSuggestions();
    }

    if (_searchResults.isEmpty) {
      return _buildNoResults();
    }

    return _buildSearchResults();
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
            'Error searching episodes',
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
            onPressed: () => _performSearch(_currentQuery),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSuggestions() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Searches',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          Wrap(
            spacing: 2.w,
            runSpacing: 2.h,
            children: _recentSearches.map((search) {
              return ActionChip(
                label: Text(search),
                onPressed: () {
                  _searchController.text = search;
                  _performSearch(search);
                },
                backgroundColor:
                    AppTheme.lightTheme.colorScheme.surfaceContainer,
              );
            }).toList(),
          ),
          SizedBox(height: 4.h),
          Text(
            'Popular Categories',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          Wrap(
            spacing: 2.w,
            runSpacing: 2.h,
            children: [
              'True Crime',
              'Health & Wellness',
              'Technology',
              'Business',
              'Comedy',
              'News',
              'Education',
              'Sports',
            ].map((category) {
              return ActionChip(
                label: Text(category),
                onPressed: () {
                  _searchController.text = category;
                  _performSearch(category);
                },
                backgroundColor:
                    AppTheme.lightTheme.colorScheme.primaryContainer,
                labelStyle: TextStyle(
                  color: AppTheme.lightTheme.colorScheme.onPrimaryContainer,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'search_off',
            size: 80,
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
          SizedBox(height: 3.h),
          Text(
            'No Episodes Found',
            style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2.h),
          Text(
            'Try adjusting your search terms or browse categories',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return ListView.separated(
      padding: EdgeInsets.all(4.w),
      itemCount: _searchResults.length,
      separatorBuilder: (context, index) => SizedBox(height: 2.h),
      itemBuilder: (context, index) {
        final episode = _searchResults[index];
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
                                style: AppTheme.lightTheme.textTheme.bodySmall,
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
