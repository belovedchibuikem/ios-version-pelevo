import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/app_export.dart';
import '../../../widgets/enhanced_search_bar.dart';
import '../../../widgets/episode_list_item.dart';

import '../../../core/utils/mini_player_positioning.dart';
import '../../../widgets/episode_detail_modal.dart';
import '../../../providers/podcast_player_provider.dart';
import '../../../providers/episode_progress_provider.dart';
import '../../../data/models/episode.dart';
import 'package:provider/provider.dart';

class RedesignedEpisodesTabWidget extends StatefulWidget {
  final List<Map<String, dynamic>> episodes;
  final Function(Map<String, dynamic>) onPlayEpisode;
  final Function(Map<String, dynamic>) onDownloadEpisode;
  final Function(Map<String, dynamic>) onShareEpisode;
  final VoidCallback? onShowArchivedToggle;
  final bool showArchived;
  final int totalEpisodes;
  final int archivedEpisodes;
  final Map<String, dynamic>? podcastData;
  // Pagination properties
  final bool hasMorePages;
  final bool isLoadingMore;
  final VoidCallback? onLoadMore;

  const RedesignedEpisodesTabWidget({
    super.key,
    required this.episodes,
    required this.onPlayEpisode,
    required this.onDownloadEpisode,
    required this.onShareEpisode,
    this.onShowArchivedToggle,
    this.showArchived = false,
    this.totalEpisodes = 0,
    this.archivedEpisodes = 0,
    this.podcastData,
    this.hasMorePages = false,
    this.isLoadingMore = false,
    this.onLoadMore,
  });

  @override
  State<RedesignedEpisodesTabWidget> createState() =>
      _RedesignedEpisodesTabWidgetState();
}

class _RedesignedEpisodesTabWidgetState
    extends State<RedesignedEpisodesTabWidget> {
  String _searchQuery = '';
  List<Map<String, dynamic>> _filteredEpisodes = [];
  // Removed date grouping - episodes are now displayed in a simple list

  // Selection mode variables
  bool _isSelectionMode = false;
  Set<String> _selectedEpisodeIds = {};

  // Sorting variables
  String _currentSortType = 'newest_to_oldest'; // Default sort

  // Episode data cache to prevent unnecessary object recreation
  final Map<String, Map<String, dynamic>> _episodeDataCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheValidityDuration = Duration(minutes: 5);

  // Progress initialization state
  bool _isProgressInitialized = false;

  @override
  void initState() {
    super.initState();
    _filterAndGroupEpisodes();

    // Initialize EpisodeProgressProvider for all episodes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeEpisodeProgress();
    });
  }

  /// Initialize episode progress for all episodes
  Future<void> _initializeEpisodeProgress() async {
    try {
      final progressProvider = context.read<EpisodeProgressProvider>();
      final episodeIds =
          widget.episodes.map((e) => e['id'].toString()).toList();

      // Load progress for all episodes to initialize the provider
      await progressProvider.loadProgressForEpisodes(episodeIds);

      if (mounted) {
        setState(() {
          _isProgressInitialized = true;
        });
      }

      debugPrint(
          '✅ Episode progress initialized for ${episodeIds.length} episodes');
    } catch (e) {
      debugPrint('⚠️ Could not initialize episode progress: $e');
    }
  }

  @override
  void didUpdateWidget(RedesignedEpisodesTabWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.episodes != widget.episodes ||
        oldWidget.showArchived != widget.showArchived) {
      _filterAndGroupEpisodes();

      // Reinitialize progress when episodes change
      _initializeEpisodeProgress();
    }
  }

  void _filterAndGroupEpisodes() {
    // Log all episode data to see what fields are available
    debugPrint(
        '🚀 _filterAndGroupEpisodes called with ${widget.episodes.length} episodes');
    for (int i = 0; i < widget.episodes.length && i < 3; i++) {
      final episode = widget.episodes[i];
      debugPrint('📋 Episode $i (${episode['title']}):');
      debugPrint(
          '  - datePublished: ${episode['datePublished']} (${episode['datePublished'].runtimeType})');
      debugPrint(
          '  - publishedAt: ${episode['publishedAt']} (${episode['publishedAt'].runtimeType})');
      debugPrint(
          '  - releaseDate: ${episode['releaseDate']} (${episode['releaseDate'].runtimeType})');
      debugPrint(
          '  - pubDate: ${episode['pubDate']} (${episode['pubDate'].runtimeType})');
      debugPrint(
          '  - date_published: ${episode['date_published']} (${episode['date_published'].runtimeType})');

      // Log image fields
      debugPrint('  - IMAGE FIELDS:');
      debugPrint('    - coverImage: ${episode['coverImage']}');
      debugPrint('    - image: ${episode['image']}');
      debugPrint('    - feedImage: ${episode['feedImage']}');
      debugPrint('    - feed_image: ${episode['feed_image']}');
      if (episode['podcast'] != null) {
        debugPrint('    - podcast.image: ${episode['podcast']['image']}');
        debugPrint(
            '    - podcast.coverImage: ${episode['podcast']['coverImage']}');
        debugPrint(
            '    - podcast.cover_image: ${episode['podcast']['cover_image']}');
        debugPrint('    - podcast.artwork: ${episode['podcast']['artwork']}');
      }

      debugPrint('  - All keys: ${episode.keys.toList()}');
    }

    // Filter episodes based on search query
    _filteredEpisodes = widget.episodes.where((episode) {
      if (_searchQuery.isEmpty) return true;

      final title = (episode['title'] ?? '').toString().toLowerCase();
      final description =
          (episode['description'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();

      return title.contains(query) || description.contains(query);
    }).toList();

    // Apply current sorting
    _applySortingToEpisodes();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _filterAndGroupEpisodes();
    });
  }

  void _onMoreOptionsTap() {
    _showMoreOptionsDialog();
  }

  /// Apply sorting to episodes and update queue
  void _applySorting(String sortType) {
    setState(() {
      _currentSortType = sortType;
    });

    // Apply sorting to filtered episodes
    _applySortingToEpisodes();

    // Update the episode queue in the player provider if available
    _updateEpisodeQueue();
  }

  /// Apply the current sort type to episodes
  void _applySortingToEpisodes() {
    debugPrint(
        '🔄 _applySortingToEpisodes called with sort type: $_currentSortType');
    debugPrint('📊 Episodes to sort: ${_filteredEpisodes.length}');

    switch (_currentSortType) {
      case 'title_asc':
        _filteredEpisodes.sort((a, b) => (a['title'] ?? '')
            .toString()
            .compareTo((b['title'] ?? '').toString()));
        break;
      case 'title_desc':
        _filteredEpisodes.sort((a, b) => (b['title'] ?? '')
            .toString()
            .compareTo((a['title'] ?? '').toString()));
        break;
      case 'newest_to_oldest':
        _filteredEpisodes.sort((a, b) {
          // Log all date fields for debugging
          debugPrint('📅 Episode A (${a['title']}):');
          debugPrint(
              '  - datePublished: ${a['datePublished']} (${a['datePublished'].runtimeType})');
          debugPrint(
              '  - publishedAt: ${a['publishedAt']} (${a['publishedAt'].runtimeType})');
          debugPrint(
              '  - releaseDate: ${a['releaseDate']} (${a['releaseDate'].runtimeType})');
          debugPrint(
              '  - pubDate: ${a['pubDate']} (${a['pubDate'].runtimeType})');
          debugPrint(
              '  - date_published: ${a['date_published']} (${a['date_published'].runtimeType})');

          debugPrint('📅 Episode B (${b['title']}):');
          debugPrint(
              '  - datePublished: ${b['datePublished']} (${b['datePublished'].runtimeType})');
          debugPrint(
              '  - publishedAt: ${b['publishedAt']} (${b['publishedAt'].runtimeType})');
          debugPrint(
              '  - releaseDate: ${b['releaseDate']} (${b['releaseDate'].runtimeType})');
          debugPrint(
              '  - pubDate: ${b['pubDate']} (${b['pubDate'].runtimeType})');
          debugPrint(
              '  - date_published: ${b['date_published']} (${b['date_published'].runtimeType})');

          // Use datePublished field (Unix timestamp) for sorting
          final dateA = _parseDatePublished(a['datePublished']);
          final dateB = _parseDatePublished(b['datePublished']);
          debugPrint('🔄 Comparing: $dateA vs $dateB');

          // If both dates are 1900 (null), try fallback date fields
          if (dateA.year == 1900 && dateB.year == 1900) {
            debugPrint('⚠️ Both dates are null, trying fallback date fields');
            final fallbackDateA = _parseFallbackDate(a);
            final fallbackDateB = _parseFallbackDate(b);
            debugPrint(
                '🔄 Fallback comparison: $fallbackDateA vs $fallbackDateB');
            return fallbackDateB.compareTo(fallbackDateA);
          }

          return dateB.compareTo(dateA); // Newest first
        });
        break;
      case 'oldest_to_newest':
        _filteredEpisodes.sort((a, b) {
          // Use datePublished field (Unix timestamp) for sorting
          final dateA = _parseDatePublished(a['datePublished']);
          final dateB = _parseDatePublished(b['datePublished']);
          return dateA.compareTo(dateB); // Oldest first
        });
        break;
      case 'duration_asc':
        _filteredEpisodes.sort((a, b) {
          final durationA = _parseDuration(a['duration'] ?? '0') ?? 0;
          final durationB = _parseDuration(b['duration'] ?? '0') ?? 0;
          return durationA.compareTo(durationB); // Shortest first
        });
        break;
      case 'duration_desc':
        _filteredEpisodes.sort((a, b) {
          final durationA = _parseDuration(a['duration'] ?? '0') ?? 0;
          final durationB = _parseDuration(b['duration'] ?? '0') ?? 0;
          return durationB.compareTo(durationA); // Longest first
        });
        break;
    }

    // Log final sorted order
    debugPrint('✅ Final sorted episode order:');
    for (int i = 0; i < _filteredEpisodes.length && i < 5; i++) {
      final episode = _filteredEpisodes[i];
      debugPrint(
          '  $i. ${episode['title']} - datePublished: ${episode['datePublished']}');
    }

    // No more grouping - episodes are displayed in a simple list
  }

  /// Parse datePublished field (Unix timestamp) to DateTime
  DateTime _parseDatePublished(dynamic datePublished) {
    debugPrint(
        '🔍 _parseDatePublished called with: $datePublished (type: ${datePublished.runtimeType})');

    if (datePublished == null) {
      debugPrint('❌ datePublished is null, returning DateTime(1900)');
      return DateTime(1900);
    }

    // Handle Unix timestamp (seconds since epoch)
    if (datePublished is int) {
      final date = DateTime.fromMillisecondsSinceEpoch(datePublished * 1000);
      debugPrint('✅ Parsed int timestamp: $datePublished -> $date');
      return date;
    }

    // Handle string representation of Unix timestamp
    if (datePublished is String) {
      final timestamp = int.tryParse(datePublished);
      if (timestamp != null) {
        final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
        debugPrint('✅ Parsed string timestamp: $datePublished -> $date');
        return date;
      }
    }

    // Fallback to old date parsing for backward compatibility
    final fallbackDate =
        DateTime.tryParse(datePublished.toString()) ?? DateTime(1900);
    debugPrint('⚠️ Using fallback parsing: $datePublished -> $fallbackDate');
    return fallbackDate;
  }

  /// Parse fallback date fields when datePublished is null
  DateTime _parseFallbackDate(Map<String, dynamic> episode) {
    debugPrint('🔍 _parseFallbackDate called for episode: ${episode['title']}');

    // Try different date fields in order of preference
    final dateFields = [
      'publishedAt',
      'releaseDate',
      'pubDate',
      'date_published',
      'datePublishedPretty'
    ];

    for (final field in dateFields) {
      final value = episode[field];
      if (value != null) {
        debugPrint(
            '✅ Found fallback date in field $field: $value (${value.runtimeType})');

        // Try parsing as DateTime string
        final parsed = DateTime.tryParse(value.toString());
        if (parsed != null) {
          debugPrint('✅ Successfully parsed fallback date: $parsed');
          return parsed;
        }
      }
    }

    debugPrint('❌ No valid fallback date found, returning DateTime(1900)');
    return DateTime(1900);
  }

  /// Update episode queue in player provider
  void _updateEpisodeQueue() {
    try {
      final playerProvider =
          Provider.of<PodcastPlayerProvider>(context, listen: false);

      // Convert episodes to Episode models
      final episodeModels = _filteredEpisodes.map((episode) {
        return Episode.fromJson(episode);
      }).toList();

      // Get podcast ID from the first episode if available
      final podcastId = _filteredEpisodes.first['podcast']?['id']?.toString() ??
          _filteredEpisodes.first['podcastId']?.toString();

      // Update the episode queue with new order
      playerProvider.setEpisodeQueue(episodeModels, podcastId: podcastId);

      debugPrint(
          '✅ Episode queue updated with new sort order: $_currentSortType');
    } catch (e) {
      debugPrint('⚠️ Could not update episode queue: $e');
    }
  }

  /// Get display name for sort type
  String _getSortTypeDisplayName(String sortType) {
    switch (sortType) {
      case 'title_asc':
        return 'Title (A-Z)';
      case 'title_desc':
        return 'Title (Z-A)';
      case 'newest_to_oldest':
        return 'Newest to oldest';
      case 'oldest_to_newest':
        return 'Oldest to newest';
      case 'duration_asc':
        return 'Shortest to longest';
      case 'duration_desc':
        return 'Longest to shortest';
      default:
        return 'Newest to oldest';
    }
  }

  /// Show episode detail modal for a specific episode
  void _showEpisodeDetailModal(
      BuildContext context, Map<String, dynamic> episode) {
    // Use podcast data from widget if available, otherwise try to get from first episode
    Map<String, dynamic>? podcastData = widget.podcastData;

    if (podcastData == null && widget.episodes.isNotEmpty) {
      final firstEpisode = widget.episodes.first;
      if (firstEpisode['podcast'] != null) {
        podcastData = firstEpisode['podcast'];
      }
    }

    // Create enhanced episode data with podcast information
    final enhancedEpisode = Map<String, dynamic>.from(episode);
    if (podcastData != null && enhancedEpisode['podcast'] == null) {
      enhancedEpisode['podcast'] = podcastData;
      debugPrint(
          'Added podcast data to enhanced episode: ${podcastData.keys.toList()}');
    }

    // Add feedId and podcastId for archive service
    if (podcastData != null) {
      enhancedEpisode['feedId'] = podcastData['id']?.toString() ?? '';
      enhancedEpisode['podcastId'] = podcastData['id']?.toString() ?? '';
    }

    debugPrint('Enhanced episode keys: ${enhancedEpisode.keys.toList()}');
    if (enhancedEpisode['podcast'] != null) {
      debugPrint(
          'Enhanced episode podcast keys: ${(enhancedEpisode['podcast'] as Map).keys.toList()}');
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: false,
      builder: (context) => SafeAreaUtils.wrapWithSafeArea(
        Container(
          width: double.infinity,
          height: double.infinity,
          child: EpisodeDetailModal(
            episode: enhancedEpisode,
            episodes: widget.episodes,
            episodeIndex: widget.episodes.indexWhere(
                (e) => e['id'].toString() == episode['id'].toString()),
          ),
        ),
      ),
    );
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedEpisodeIds.clear();
      }
    });
  }

  void _toggleEpisodeSelection(String episodeId) {
    setState(() {
      if (_selectedEpisodeIds.contains(episodeId)) {
        _selectedEpisodeIds.remove(episodeId);
      } else {
        _selectedEpisodeIds.add(episodeId);
      }

      // Exit selection mode if no episodes are selected
      if (_selectedEpisodeIds.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  void _selectAllEpisodes() {
    setState(() {
      _selectedEpisodeIds =
          _filteredEpisodes.map((episode) => episode['id'].toString()).toSet();
    });
  }

  void _deselectAllEpisodes() {
    setState(() {
      _selectedEpisodeIds.clear();
      _isSelectionMode = false;
    });
  }

  void _downloadSelectedEpisodes() {
    for (final episodeId in _selectedEpisodeIds) {
      final episode = _filteredEpisodes.firstWhere(
        (episode) => episode['id'].toString() == episodeId,
      );
      widget.onDownloadEpisode(episode);
    }
    _deselectAllEpisodes();
  }

  void _shareSelectedEpisodes() async {
    try {
      if (_selectedEpisodeIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No episodes selected'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Get selected episodes
      final selectedEpisodes = _filteredEpisodes.where((episode) {
        final episodeId = episode['id']?.toString();
        return episodeId != null && _selectedEpisodeIds.contains(episodeId);
      }).toList();

      if (selectedEpisodes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No episodes found to share'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Build share message for multiple episodes
      final buffer = StringBuffer();
      buffer.writeln('🎧 Check out these episodes:');
      buffer.writeln();

      for (int i = 0; i < selectedEpisodes.length; i++) {
        final episode = selectedEpisodes[i];
        final title = episode['title'] ?? 'Unknown Episode';
        final podcastTitle = episode['podcast']?['title'] ??
            episode['podcastTitle'] ??
            'Unknown Podcast';

        buffer.writeln('${i + 1}. $title');
        buffer.writeln('   📻 $podcastTitle');

        if (i < selectedEpisodes.length - 1) {
          buffer.writeln();
        }
      }

      buffer.writeln();
      buffer.writeln('Shared via Pelevo Podcast App');

      // Share using the share_plus package
      await Share.share(
        buffer.toString(),
        subject: '${selectedEpisodes.length} Podcast Episodes',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${selectedEpisodes.length} episodes shared successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      _deselectAllEpisodes();
    } catch (e) {
      debugPrint('Error sharing episodes: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing episodes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _archiveSelectedEpisodes() {
    // TODO: Implement archive multiple episodes
    debugPrint('Archive ${_selectedEpisodeIds.length} episodes');
    _deselectAllEpisodes();
  }

  void _deleteSelectedEpisodes() {
    // TODO: Implement delete multiple episodes
    debugPrint('Delete ${_selectedEpisodeIds.length} episodes');
    _deselectAllEpisodes();
  }

  void _showMoreOptionsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40.w,
              height: 0.5.h,
              margin: EdgeInsets.only(bottom: 2.h),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Options
            _buildOptionItem(
              context,
              'Refresh episode list',
              Icons.refresh,
              () {
                Navigator.pop(context);
                // Force refresh of EpisodeProgressProvider
                final progressProvider = Provider.of<EpisodeProgressProvider>(
                    context,
                    listen: false);
                final episodeIds =
                    widget.episodes.map((e) => e['id'].toString()).toList();
                progressProvider.refreshProgressForEpisodes(episodeIds);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Episode progress refreshed'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                debugPrint('Episode progress refreshed via provider');
              },
            ),

            _buildOptionItem(
              context,
              'Sort episodes',
              Icons.sort,
              () {
                Navigator.pop(context);
                _showSortingOptions(context);
              },
              trailing: Text(
                _getSortTypeDisplayName(_currentSortType),
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),

            _buildOptionItem(
              context,
              'Group episodes',
              Icons.grid_view,
              () {
                Navigator.pop(context);
                _showGroupingOptions(context);
              },
              trailing: Text(
                'None',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),

            _buildOptionItem(
              context,
              'Download all',
              Icons.download,
              () {
                Navigator.pop(context);
                // TODO: Implement download all episodes
                debugPrint('Download all episodes');
              },
            ),

            _buildOptionItem(
              context,
              'Archive all',
              Icons.archive,
              () {
                Navigator.pop(context);
                // TODO: Implement archive all episodes
                debugPrint('Archive all episodes');
              },
            ),

            _buildOptionItem(
              context,
              'Archive all played',
              Icons.archive,
              () {
                Navigator.pop(context);
                // TODO: Implement archive all played episodes
                debugPrint('Archive all played episodes');
              },
            ),

            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  void _showSortingOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40.w,
              height: 0.5.h,
              margin: EdgeInsets.only(bottom: 2.h),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Text(
              'Sort Episodes',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),

            SizedBox(height: 2.h),

            _buildSortOptionItem(
              context,
              'Title (A-Z)',
              Icons.sort_by_alpha,
              'title_asc',
              () {
                Navigator.pop(context);
                _applySorting('title_asc');
              },
            ),

            _buildSortOptionItem(
              context,
              'Title (Z-A)',
              Icons.sort_by_alpha,
              'title_desc',
              () {
                Navigator.pop(context);
                _applySorting('title_desc');
              },
            ),

            _buildSortOptionItem(
              context,
              'Newest to oldest',
              Icons.arrow_downward,
              'newest_to_oldest',
              () {
                Navigator.pop(context);
                _applySorting('newest_to_oldest');
              },
            ),

            _buildSortOptionItem(
              context,
              'Oldest to newest',
              Icons.arrow_upward,
              'oldest_to_newest',
              () {
                Navigator.pop(context);
                _applySorting('oldest_to_newest');
              },
            ),

            _buildSortOptionItem(
              context,
              'Shortest to longest',
              Icons.timer,
              'duration_asc',
              () {
                Navigator.pop(context);
                _applySorting('duration_asc');
              },
            ),

            _buildSortOptionItem(
              context,
              'Longest to shortest',
              Icons.timer,
              'duration_desc',
              () {
                Navigator.pop(context);
                _applySorting('duration_desc');
              },
            ),

            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  void _showGroupingOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40.w,
              height: 0.5.h,
              margin: EdgeInsets.only(bottom: 2.h),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Text(
              'Group Episodes',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),

            SizedBox(height: 2.h),

            _buildGroupOptionItem(
              context,
              'None',
              Icons.clear,
              () {
                Navigator.pop(context);
                // TODO: Implement no grouping
                debugPrint('Group: None');
              },
            ),

            _buildGroupOptionItem(
              context,
              'By Date',
              Icons.calendar_today,
              () {
                Navigator.pop(context);
                // TODO: Implement date grouping
                debugPrint('Group: By Date');
              },
            ),

            _buildGroupOptionItem(
              context,
              'By Season',
              Icons.folder,
              () {
                Navigator.pop(context);
                // TODO: Implement season grouping
                debugPrint('Group: By Season');
              },
            ),

            _buildGroupOptionItem(
              context,
              'By Category',
              Icons.category,
              () {
                Navigator.pop(context);
                // TODO: Implement category grouping
                debugPrint('Group: By Category');
              },
            ),

            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  /// Build Load More button
  Widget _buildLoadMoreButton() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: widget.isLoadingMore
          ? Center(
              child: Column(
                children: [
                  SizedBox(height: 1.h),
                  SizedBox(
                    width: 6.w,
                    height: 6.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.lightTheme.colorScheme.primary,
                      ),
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Loading more episodes...',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : ElevatedButton(
              onPressed: widget.onLoadMore,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                foregroundColor: AppTheme.lightTheme.colorScheme.onPrimary,
                elevation: 0,
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                minimumSize: Size(double.infinity, 5.h),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.expand_more,
                    size: 20,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    'Load More Episodes',
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.lightTheme.scaffoldBackgroundColor,
      child: Column(
        children: [
          // Top Action Bar (Selection Mode)
          if (_isSelectionMode)
            Container(
              width: double.infinity,
              color: AppTheme.lightTheme.colorScheme.primary,
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              child: SafeArea(
                child: Row(
                  children: [
                    // Back/Deselect button
                    GestureDetector(
                      onTap: _deselectAllEpisodes,
                      child: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),

                    SizedBox(width: 4.w),

                    // Selection count
                    Text(
                      '${_selectedEpisodeIds.length} selected',
                      style:
                          AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const Spacer(),

                    // Action buttons
                    Row(
                      children: [
                        // Download button
                        GestureDetector(
                          onTap: _downloadSelectedEpisodes,
                          child: Container(
                            padding: EdgeInsets.all(2.w),
                            child: Icon(
                              Icons.download,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),

                        SizedBox(width: 2.w),

                        // Share button
                        GestureDetector(
                          onTap: _shareSelectedEpisodes,
                          child: Container(
                            padding: EdgeInsets.all(2.w),
                            child: Icon(
                              Icons.share,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),

                        SizedBox(width: 2.w),

                        // Archive button
                        GestureDetector(
                          onTap: _archiveSelectedEpisodes,
                          child: Container(
                            padding: EdgeInsets.all(2.w),
                            child: Icon(
                              Icons.archive,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),

                        SizedBox(width: 2.w),

                        // Delete button
                        GestureDetector(
                          onTap: _deleteSelectedEpisodes,
                          child: Container(
                            padding: EdgeInsets.all(2.w),
                            child: Icon(
                              Icons.delete,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),

                        SizedBox(width: 2.w),

                        // More options button
                        GestureDetector(
                          onTap: () {
                            // TODO: Show more options for selected episodes
                            debugPrint('More options for selected episodes');
                          },
                          child: Container(
                            padding: EdgeInsets.all(2.w),
                            child: Icon(
                              Icons.more_vert,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // Enhanced search bar
          EnhancedSearchBar(
            hintText: 'Search episodes',
            onChanged: _onSearchChanged,
            onMoreOptionsTap: _onMoreOptionsTap,
          ),

          // Episode count summary
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${widget.totalEpisodes} episodes • ${widget.archivedEpisodes} archived',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                  ),
                ),
                if (widget.onShowArchivedToggle != null)
                  GestureDetector(
                    onTap: widget.onShowArchivedToggle,
                    child: Text(
                      widget.showArchived ? 'Hide archived' : 'Show archived',
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Episodes list - Simple list without date grouping
          _filteredEpisodes.isEmpty
              ? _buildEmptyState()
              : !_isProgressInitialized
                  ? _buildProgressLoadingState()
                  : Column(
                      children: [
                        // Episodes list
                        ..._filteredEpisodes
                            .map(
                              (episode) => _buildEpisodeWithRealTimeProgress(
                                episode,
                                context,
                              ),
                            )
                            .toList(),

                        // Load More button
                        if (widget.hasMorePages) _buildLoadMoreButton(),
                      ],
                    ),

          // Bottom padding for mini-player
          SizedBox(
            height: MiniPlayerPositioning.bottomPaddingForScrollables(),
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
            size: 20.w,
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
          SizedBox(height: 2.h),
          Text(
            _searchQuery.isEmpty
                ? 'No episodes found'
                : 'No episodes match your search',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            _searchQuery.isEmpty
                ? 'This podcast doesn\'t have any episodes yet'
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

  /// Build loading state while progress is being initialized
  Widget _buildProgressLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 4.h),
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              AppTheme.lightTheme.colorScheme.primary,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Loading episode progress...',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _showEpisodeOptions(BuildContext context, Map<String, dynamic> episode) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Episode title
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(4.w),
              child: Text(
                episode['title'] ?? 'Untitled Episode',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            SizedBox(height: 2.h),

            // Options
            _buildOptionItem(
              context,
              'Play Episode',
              Icons.play_arrow,
              () {
                Navigator.pop(context);
                widget.onPlayEpisode(episode);
              },
            ),
            _buildOptionItem(
              context,
              episode['isDownloaded'] == true ? 'Remove Download' : 'Download',
              episode['isDownloaded'] == true
                  ? Icons.download_done
                  : Icons.download,
              () {
                Navigator.pop(context);
                widget.onDownloadEpisode(episode);
              },
            ),
            _buildOptionItem(
              context,
              'Add to Queue',
              Icons.queue_music,
              () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Added to queue'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            _buildOptionItem(
              context,
              'Share Episode',
              Icons.share,
              () {
                Navigator.pop(context);
                widget.onShareEpisode(episode);
              },
            ),

            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionItem(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap, {
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: AppTheme.lightTheme.colorScheme.onSurface,
        size: 24,
      ),
      title: Text(
        title,
        style: AppTheme.lightTheme.textTheme.bodyLarge,
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _buildSortOptionItem(
    BuildContext context,
    String title,
    IconData icon,
    String sortType,
    VoidCallback onTap,
  ) {
    final isSelected = _currentSortType == sortType;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected
            ? AppTheme.lightTheme.colorScheme.primary
            : AppTheme.lightTheme.colorScheme.onSurface,
        size: 24,
      ),
      title: Text(
        title,
        style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
          color: isSelected
              ? AppTheme.lightTheme.colorScheme.primary
              : AppTheme.lightTheme.colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check,
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 20,
            )
          : null,
      onTap: onTap,
    );
  }

  Widget _buildGroupOptionItem(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(
        icon,
        color: AppTheme.lightTheme.colorScheme.onSurface,
        size: 24,
      ),
      title: Text(
        title,
        style: AppTheme.lightTheme.textTheme.bodyLarge,
      ),
      onTap: onTap,
    );
  }

  /// Build episode with real-time progress using EpisodeProgressProvider
  Widget _buildEpisodeWithRealTimeProgress(
      Map<String, dynamic> episode, BuildContext context) {
    final episodeId = episode['id'].toString();
    final isSelected = _selectedEpisodeIds.contains(episodeId);

    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.1)
            : Colors.transparent,
      ),
      child: Row(
        children: [
          // Checkbox for selection
          if (_isSelectionMode)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: GestureDetector(
                onTap: () => _toggleEpisodeSelection(episodeId),
                child: Container(
                  width: 6.w,
                  height: 6.w,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.lightTheme.colorScheme.primary
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.lightTheme.colorScheme.primary
                          : AppTheme.lightTheme.colorScheme.outline,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 4.w,
                        )
                      : null,
                ),
              ),
            ),

          // Episode content - Single Consumer to avoid multiple listeners
          Expanded(
            child: GestureDetector(
              onTap: _isSelectionMode
                  ? () => _toggleEpisodeSelection(episodeId)
                  : null,
              onLongPress: () {
                if (!_isSelectionMode) {
                  _toggleSelectionMode();
                  _toggleEpisodeSelection(episodeId);
                }
              },
              child: Consumer<PodcastPlayerProvider>(
                builder: (context, playerProvider, child) {
                  final isActiveEpisode =
                      playerProvider.currentEpisode?.id.toString() ==
                          episode['id'].toString();
                  final isPlaying = isActiveEpisode && playerProvider.isPlaying;

                  // If currently playing, use real-time data
                  if (isActiveEpisode) {
                    final realTimeData = {
                      ...episode,
                      'lastPlayedPosition':
                          playerProvider.position.inMilliseconds,
                      'totalDuration': playerProvider.duration.inMilliseconds,
                      'lastPlayedAt': DateTime.now().toIso8601String(),
                      'isCompleted': playerProvider.progressPercentage >= 1.0,
                      'isCurrentlyPlaying': true,
                      'isPlaying': isPlaying,
                    };

                    return EpisodeListItem(
                      episode: realTimeData,
                      onPlay: () => widget.onPlayEpisode(episode),
                      onLongPress: () {
                        if (!_isSelectionMode) {
                          _toggleSelectionMode();
                          _toggleEpisodeSelection(episodeId);
                        }
                      },
                      onShowDetails: () =>
                          _showEpisodeDetailModal(context, episode),
                      showTranscriptIcon: episode['hasTranscript'] ?? false,
                      showArchived: widget.showArchived,
                      playProgress:
                          _getCurrentPlaybackProgress(playerProvider) ?? 0.0,
                      isCurrentlyPlaying: true,
                      isActiveEpisode: true,
                      isPlaying: isPlaying,
                      lastPlayedPosition: realTimeData['lastPlayedPosition'],
                      totalDuration: realTimeData['totalDuration'],
                      lastPlayedAt: DateTime.now(),
                    );
                  }

                  // For non-playing episodes, use real-time progress from EpisodeProgressProvider
                  return Consumer<EpisodeProgressProvider>(
                    builder: (context, progressProvider, child) {
                      final episodeId = episode['id'].toString();

                      // Check if provider is initialized, use fallback values if not
                      if (!progressProvider.isInitialized) {
                        return EpisodeListItem(
                          episode: {
                            ...episode,
                            'lastPlayedPosition': null,
                            'totalDuration': episode['duration'] != null
                                ? int.tryParse(
                                        episode['duration'].toString()) ??
                                    0
                                : 0,
                            'lastPlayedAt': null,
                            'isCompleted': false,
                            'isCurrentlyPlaying': false,
                            'isPlaying': false,
                          },
                          onPlay: () => widget.onPlayEpisode(episode),
                          onLongPress: () {
                            if (!_isSelectionMode) {
                              _toggleSelectionMode();
                              _toggleEpisodeSelection(episodeId);
                            }
                          },
                          onShowDetails: () =>
                              _showEpisodeDetailModal(context, episode),
                          showTranscriptIcon: episode['hasTranscript'] ?? false,
                          showArchived: widget.showArchived,
                          playProgress: 0.0,
                          isCurrentlyPlaying: false,
                          isActiveEpisode: false,
                          isPlaying: false,
                          lastPlayedPosition: null,
                          totalDuration: episode['duration'] != null
                              ? int.tryParse(episode['duration'].toString()) ??
                                  0
                              : 0,
                          lastPlayedAt: null,
                        );
                      }

                      final isCompleted =
                          progressProvider.isEpisodeCompleted(episodeId);
                      final progressPercentage =
                          progressProvider.getProgressPercentage(episodeId);
                      final currentPosition =
                          progressProvider.getCurrentPosition(episodeId);
                      final totalDuration = episode['duration'] != null
                          ? int.tryParse(episode['duration'].toString()) ?? 0
                          : 0;

                      final progressData = {
                        ...episode,
                        'lastPlayedPosition': currentPosition,
                        'totalDuration': totalDuration,
                        'lastPlayedAt':
                            progressProvider.getLastUpdateTime(episodeId),
                        'isCompleted': isCompleted,
                        'isCurrentlyPlaying': false,
                        'isPlaying': false,
                      };

                      return EpisodeListItem(
                        episode: progressData,
                        onPlay: () => widget.onPlayEpisode(episode),
                        onLongPress: () {
                          if (!_isSelectionMode) {
                            _toggleSelectionMode();
                            _toggleEpisodeSelection(episodeId);
                          }
                        },
                        onShowDetails: () =>
                            _showEpisodeDetailModal(context, episode),
                        showTranscriptIcon: episode['hasTranscript'] ?? false,
                        showArchived: widget.showArchived,
                        playProgress: progressPercentage / 100,
                        isCurrentlyPlaying: false,
                        isActiveEpisode: false,
                        isPlaying: false,
                        lastPlayedPosition: currentPosition,
                        totalDuration: totalDuration,
                        lastPlayedAt:
                            progressProvider.getLastUpdateTime(episodeId),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Get the play progress for an episode (0.0 to 1.0)
  double? _getEpisodeProgress(Map<String, dynamic> episode) {
    // Check if episode has progress data
    if (episode.containsKey('playProgress')) {
      final progress = episode['playProgress'];
      if (progress is double) return progress;
      if (progress is int) return progress.toDouble();
      if (progress is String) {
        try {
          return double.parse(progress);
        } catch (e) {
          return null;
        }
      }
    }

    // Check if episode has played duration and total duration
    if (episode.containsKey('playedDuration') &&
        episode.containsKey('duration')) {
      final playedDuration = _parseDuration(episode['playedDuration']);
      final totalDuration = _parseDuration(episode['duration']);

      if (playedDuration != null &&
          totalDuration != null &&
          totalDuration > 0) {
        return (playedDuration / totalDuration).clamp(0.0, 1.0);
      }
    }

    // Check if episode is marked as completed
    if (episode['isCompleted'] == true) {
      return 1.0;
    }

    // Check if episode is marked as played
    if (episode['isPlayed'] == true) {
      return 1.0;
    }

    return null;
  }

  /// Check if an episode is currently playing
  bool _isEpisodeCurrentlyPlaying(Map<String, dynamic> episode) {
    // Check if episode has a currently playing flag
    if (episode.containsKey('isCurrentlyPlaying')) {
      return episode['isCurrentlyPlaying'] == true;
    }

    // Check if episode has a playing state
    if (episode.containsKey('playingState')) {
      final state = episode['playingState'];
      return state == 'playing' || state == 'paused';
    }

    // Check if episode is in a queue or active state
    if (episode.containsKey('queueStatus')) {
      final status = episode['queueStatus'];
      return status == 'active' || status == 'current';
    }

    return false;
  }

  /// Get current playback progress from PodcastPlayerProvider
  double? _getCurrentPlaybackProgress(PodcastPlayerProvider playerProvider) {
    if (playerProvider.currentEpisode == null) return null;

    final position = playerProvider.position;
    final duration = playerProvider.duration;

    if (position.inSeconds <= 0 || duration.inSeconds <= 0) return 0.0;

    return (position.inSeconds / duration.inSeconds).clamp(0.0, 1.0);
  }

  /// Parse duration from various formats
  int? _parseDuration(dynamic duration) {
    if (duration is int) return duration;
    if (duration is double) return duration.toInt();
    if (duration is String) {
      try {
        return int.parse(duration);
      } catch (e) {
        // Try to parse duration strings like "1:30:45" or "45:30"
        final parts = duration.split(':');
        if (parts.length == 2) {
          // Format: "MM:SS"
          final minutes = int.tryParse(parts[0]) ?? 0;
          final seconds = int.tryParse(parts[1]) ?? 0;
          return minutes * 60 + seconds;
        } else if (parts.length == 3) {
          // Format: "HH:MM:SS"
          final hours = int.tryParse(parts[0]) ?? 0;
          final minutes = int.tryParse(parts[1]) ?? 0;
          final seconds = int.tryParse(parts[2]) ?? 0;
          return hours * 3600 + minutes * 60 + seconds;
        }
      }
    }
    return null;
  }
}
