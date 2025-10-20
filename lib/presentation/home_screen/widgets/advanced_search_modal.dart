import 'package:flutter/material.dart';
import '../../../core/app_export.dart';
import '../../../data/models/podcast.dart';
import '../../../services/advanced_search_service.dart';
import '../../../core/navigation_service.dart';
import '../../../core/routes/app_routes.dart';

class AdvancedSearchModal extends StatefulWidget {
  final String initialQuery;
  final Function(List<Podcast>) onResults;
  final VoidCallback onClose;

  const AdvancedSearchModal({
    Key? key,
    required this.initialQuery,
    required this.onResults,
    required this.onClose,
  }) : super(key: key);

  @override
  State<AdvancedSearchModal> createState() => _AdvancedSearchModalState();
}

class _AdvancedSearchModalState extends State<AdvancedSearchModal> {
  final TextEditingController _searchController = TextEditingController();
  final AdvancedSearchService _searchService = AdvancedSearchService();
  final NavigationService _navigationService = NavigationService();

  SearchFilters _filters = const SearchFilters();
  SearchSortBy _sortBy = SearchSortBy.relevance;
  SearchSortOrder _sortOrder = SearchSortOrder.desc;

  List<Podcast> _results = [];
  bool _isLoading = false;
  bool _showFilters = false;
  int _currentPage = 1;
  bool _hasMore = false;
  int _totalResults = 0;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialQuery;
    if (widget.initialQuery.isNotEmpty) {
      _performSearch();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch({bool loadMore = false}) async {
    if (_searchController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      if (!loadMore) {
        _currentPage = 1;
        _results.clear();
      }
    });

    try {
      final result = await _searchService.searchPodcasts(
        query: _searchController.text.trim(),
        category: _filters.category,
        language: _filters.language,
        explicit: _filters.explicit,
        minEpisodes: _filters.minEpisodes,
        maxEpisodes: _filters.maxEpisodes,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
        page: _currentPage,
        perPage: 20,
        context: context,
      );

      setState(() {
        if (loadMore) {
          _results.addAll(result.podcasts);
        } else {
          _results = result.podcasts;
        }
        _hasMore = result.hasMore;
        _totalResults = result.total;
        _isLoading = false;
      });

      widget.onResults(_results);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onSearchChanged() {
    // Debounce search
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchController.text.trim().isNotEmpty && mounted) {
        _performSearch();
      }
    });
  }

  void _loadMore() {
    if (_hasMore && !_isLoading) {
      setState(() {
        _currentPage++;
      });
      _performSearch(loadMore: true);
    }
  }

  Future<void> _onPodcastTap(Podcast podcast) async {
    debugPrint('=== ADVANCED SEARCH PODCAST TAP DEBUG ===');
    debugPrint('Podcast ID: ${podcast.id}');
    debugPrint('Podcast Title: ${podcast.title}');
    debugPrint('Podcast Creator: ${podcast.creator}');
    debugPrint('Podcast Cover Image: ${podcast.coverImage}');

    // Validate required fields before navigation
    if (podcast.id.toString().isEmpty) {
      debugPrint('Navigation error: Podcast ID is empty');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot navigate: Podcast ID is missing'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final arguments = {
        'id': podcast.id,
        'title': podcast.title,
        'creator': podcast.creator,
        'author': podcast.author,
        'coverImage': podcast.coverImage,
        'image':
            podcast.coverImage, // Also include 'image' field for compatibility
        'duration': podcast.duration,
        'isDownloaded': podcast.isDownloaded,
        'description': podcast.description,
        'category': podcast.category,
        'categories': podcast.categories,
        'audioUrl': podcast.audioUrl,
        'url': podcast.url,
        'originalUrl': podcast.originalUrl,
        'link': podcast.link,
        'totalEpisodes': podcast.totalEpisodes,
        'episodeCount': podcast.episodeCount,
        'languages': podcast.languages,
        'explicit': podcast.explicit,
        'isFeatured': podcast.isFeatured,
        'isSubscribed': podcast.isSubscribed,
      };

      debugPrint('Navigation arguments: $arguments');
      final result = await _navigationService
          .navigateTo(AppRoutes.podcastDetailScreen, arguments: arguments);
      if (result == null) {
        debugPrint('Navigation completed (result is null - this is normal)');
        // Note: Removed navigation failed error message to mute yellow error during navigation
        return;
      }
      debugPrint('Navigation successful');
    } catch (e) {
      debugPrint('Navigation error: $e');
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            if (_showFilters) _buildFilters(),
            _buildResults(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.getPrimaryColor(context),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Advanced Search',
              style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: widget.onClose,
            icon: const Icon(
              Icons.close,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _onSearchChanged(),
              decoration: InputDecoration(
                hintText: 'Search podcasts...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _results.clear();
                            _totalResults = 0;
                          });
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
            icon: Icon(
              _showFilters ? Icons.filter_list_off : Icons.filter_list,
              color: _filters.hasActiveFilters
                  ? AppTheme.getPrimaryColor(context)
                  : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _filters.category,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('All Categories')),
                    const DropdownMenuItem(
                        value: 'comedy', child: Text('Comedy')),
                    const DropdownMenuItem(
                        value: 'true crime', child: Text('True Crime')),
                    const DropdownMenuItem(value: 'news', child: Text('News')),
                    const DropdownMenuItem(
                        value: 'business', child: Text('Business')),
                    const DropdownMenuItem(
                        value: 'technology', child: Text('Technology')),
                    const DropdownMenuItem(
                        value: 'science', child: Text('Science')),
                    const DropdownMenuItem(
                        value: 'health', child: Text('Health')),
                    const DropdownMenuItem(
                        value: 'education', child: Text('Education')),
                    const DropdownMenuItem(
                        value: 'history', child: Text('History')),
                    const DropdownMenuItem(
                        value: 'politics', child: Text('Politics')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _filters = _filters.copyWith(category: value);
                    });
                    _performSearch();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _filters.language,
                  decoration: const InputDecoration(
                    labelText: 'Language',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('All Languages')),
                    const DropdownMenuItem(value: 'en', child: Text('English')),
                    const DropdownMenuItem(value: 'es', child: Text('Spanish')),
                    const DropdownMenuItem(value: 'fr', child: Text('French')),
                    const DropdownMenuItem(value: 'de', child: Text('German')),
                    const DropdownMenuItem(value: 'it', child: Text('Italian')),
                    const DropdownMenuItem(
                        value: 'pt', child: Text('Portuguese')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _filters = _filters.copyWith(language: value);
                    });
                    _performSearch();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Checkbox(
                      value: _filters.explicit ?? false,
                      onChanged: (value) {
                        setState(() {
                          _filters = _filters.copyWith(explicit: value);
                        });
                        _performSearch();
                      },
                    ),
                    const Text('Explicit Content'),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    const Text('Min Episodes:'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                        onChanged: (value) {
                          final minEpisodes = int.tryParse(value);
                          setState(() {
                            _filters =
                                _filters.copyWith(minEpisodes: minEpisodes);
                          });
                          _performSearch();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<SearchSortBy>(
                  value: _sortBy,
                  decoration: const InputDecoration(
                    labelText: 'Sort By',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: SearchSortBy.values.map((sort) {
                    return DropdownMenuItem(
                      value: sort,
                      child: Text(sort.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _sortBy = value;
                      });
                      _performSearch();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<SearchSortOrder>(
                  value: _sortOrder,
                  decoration: const InputDecoration(
                    labelText: 'Order',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: SearchSortOrder.values.map((order) {
                    return DropdownMenuItem(
                      value: order,
                      child: Text(order.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _sortOrder = value;
                      });
                      _performSearch();
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    return Expanded(
      child: Column(
        children: [
          if (_totalResults > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    '${_totalResults} results found',
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  if (_filters.hasActiveFilters)
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _filters = const SearchFilters();
                        });
                        _performSearch();
                      },
                      icon: const Icon(Icons.clear, size: 16),
                      label: const Text('Clear Filters'),
                    ),
                ],
              ),
            ),
          Expanded(
            child: _isLoading && _results.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? _buildEmptyState()
                    : _buildResultsList(),
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
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No podcasts found',
            style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search terms or filters',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _results.length) {
          return _buildLoadMoreButton();
        }

        final podcast = _results[index];
        return _buildPodcastCard(podcast);
      },
    );
  }

  Widget _buildLoadMoreButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : ElevatedButton(
                onPressed: _loadMore,
                child: const Text('Load More'),
              ),
      ),
    );
  }

  Widget _buildPodcastCard(Podcast podcast) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            podcast.coverImage,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 60,
                height: 60,
                color: Colors.grey[300],
                child: const Icon(Icons.mic),
              );
            },
          ),
        ),
        title: Text(
          podcast.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              podcast.creator,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (podcast.category.isNotEmpty)
              Text(
                podcast.category,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Close the search modal first
          Navigator.of(context).pop();
          // Navigate to podcast details
          _onPodcastTap(podcast);
        },
      ),
    );
  }
}
