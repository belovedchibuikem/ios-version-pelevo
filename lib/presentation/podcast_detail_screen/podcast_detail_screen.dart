import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/app_export.dart';
import '../../data/models/episode.dart';
import '../../data/models/podcast.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/about_tab_widget.dart';
import './widgets/redesigned_episodes_tab_widget.dart';
import './widgets/bookmarks_tab_widget.dart';
import './widgets/podcast_header_widget.dart';
import '../../services/library_api_service.dart';
import '../../services/subscription_helper.dart';
import '../../services/download_manager.dart';
import '../../services/social_sharing_service.dart';
import '../../providers/subscription_provider.dart';
import '../../core/utils/episode_utils.dart';
import '../../data/repositories/podcast_repository.dart';
import '../../core/routes/app_routes.dart';
import '../../core/error_handling/global_error_handler.dart';
import '../../core/utils/smooth_scroll_utils.dart';
import '../../widgets/episode_detail_modal.dart';
import '../../widgets/common_bottom_navigation_widget.dart';
import '../../providers/podcast_player_provider.dart';
import '../../core/utils/mini_player_positioning.dart';

class PodcastDetailScreen extends StatefulWidget {
  final Map<String, dynamic> podcast;

  const PodcastDetailScreen({
    super.key,
    required this.podcast,
  });

  @override
  State<PodcastDetailScreen> createState() => _PodcastDetailScreenState();
}

class _PodcastDetailScreenState extends State<PodcastDetailScreen>
    with TickerProviderStateMixin, SafeStateMixin, SmoothScrollMixin {
  late TabController _tabController;
  List<Episode> episodes = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  Podcast? _podcast;
  int _episodeCount = 0;
  int _currentPage = 1;
  bool _hasMorePages = true;
  final DownloadManager _downloadManager = DownloadManager();

  // Bottom navigation state

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeDownloadManager();
    _loadPodcastData();

    // Add listener to tab controller to rebuild when tabs change
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _initializeDownloadManager() async {
    await _downloadManager.initialize();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPodcastData() async {
    debugPrint('=== _loadPodcastData CALLED ===');
    safeSetState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Debug: Print the incoming podcast data
      debugPrint('=== PODCAST DETAIL DEBUG ===');
      debugPrint('Widget podcast data: ${widget.podcast}');
      debugPrint('Widget podcast author: ${widget.podcast['author']}');
      debugPrint('Widget podcast creator: ${widget.podcast['creator']}');

      // Load complete podcast details from API instead of using passed data
      await _loadCompletePodcastData();

      safeSetState(() {
        _isLoading = false;
      });

      debugPrint('=== _loadPodcastData COMPLETED ===');
      debugPrint('Final _episodeCount: $_episodeCount');
      debugPrint('Final episodes length: ${episodes.length}');
      debugPrint('Final _podcast episodeCount: ${_podcast?.episodeCount}');
    } catch (e) {
      debugPrint('=== _loadPodcastData ERROR: $e ===');
      safeSetState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _loadCompletePodcastData() async {
    debugPrint('=== _loadCompletePodcastData CALLED ===');
    try {
      final podcastId = widget.podcast['id']?.toString();
      debugPrint(
          'DetailScreen: Loading complete podcast data for podcastId: $podcastId');
      if (podcastId != null) {
        final podcastRepository = PodcastRepository();
        await podcastRepository.initialize();
        debugPrint(
            'DetailScreen: Making API call to get complete podcast details');
        final result = await podcastRepository
            .getPodcastDetailsWithEpisodes(podcastId, context: context);
        debugPrint('DetailScreen: API response received: ${result.keys}');
        debugPrint('DetailScreen: Full API response: $result');

        // Extract the complete podcast data from the API response
        if (result.containsKey('podcast')) {
          // The repository already returns a Podcast object, not a map
          _podcast = result['podcast'] as Podcast;

          // Debug the complete podcast data
          debugPrint(
              'DetailScreen: Complete podcast from API: ${_podcast?.title}');
          debugPrint(
              'DetailScreen: Complete podcast author: ${_podcast?.author}');
          debugPrint(
              'DetailScreen: Complete podcast creator: ${_podcast?.creator}');
          debugPrint(
              'DetailScreen: Complete podcast episodeCount: ${_podcast?.episodeCount}');
          debugPrint(
              'DetailScreen: Complete podcast totalEpisodes: ${_podcast?.totalEpisodes}');

          // Set the episode count from the complete podcast data
          _episodeCount = _podcast?.episodeCount ??
              _podcast?.totalEpisodes ??
              episodes.length;
          debugPrint('DetailScreen: Set episode count to: $_episodeCount');
        } else {
          // Fallback to using passed data if API doesn't return podcast data
          debugPrint(
              'DetailScreen: No podcast data in API response, using passed data');
          _podcast = Podcast.fromJson(widget.podcast);
          _episodeCount = _podcast?.episodeCount ??
              _podcast?.totalEpisodes ??
              episodes.length;
          debugPrint(
              'DetailScreen: Set episode count from fallback to: $_episodeCount');
        }

        // Load episodes
        if (result['episodes'] != null) {
          final episodesList = result['episodes'] as List<Episode>;
          debugPrint(
              'DetailScreen: About to set ${episodesList.length} episodes');
          setState(() {
            episodes = episodesList;
          });
          debugPrint(
              'DetailScreen: Episodes set successfully, length: ${episodes.length}');

          // Update episode count if it's still 0
          if (_episodeCount == 0 && episodes.length > 0) {
            _episodeCount = episodes.length;
            debugPrint(
                'DetailScreen: Updated _episodeCount to episodes length: $_episodeCount');
          }
        } else {
          debugPrint('DetailScreen: No episodes found in API response');
        }
      }
    } catch (e, stackTrace) {
      debugPrint('=== ERROR in _loadCompletePodcastData ===');
      debugPrint('Error loading complete podcast data: $e');
      debugPrint('Stack trace: $stackTrace');
      // Fallback to using passed data
      _podcast = Podcast.fromJson(widget.podcast);
      _episodeCount =
          _podcast?.episodeCount ?? _podcast?.totalEpisodes ?? episodes.length;
      debugPrint(
          'DetailScreen: Set episode count from error fallback to: $_episodeCount');
      debugPrint('=== END ERROR HANDLING ===');
    }
  }

  Future<void> _onRefresh() async {
    // Reset pagination state
    _currentPage = 1;
    _hasMorePages = true;
    episodes.clear();
    await _loadPodcastData();
  }

  Future<void> _loadMoreEpisodes() async {
    if (_isLoadingMore || !_hasMorePages) return;

    safeSetState(() {
      _isLoadingMore = true;
    });

    try {
      final podcastId = widget.podcast['id']?.toString();
      if (podcastId != null) {
        final podcastRepository = PodcastRepository();
        await podcastRepository.initialize();

        // Load next page of episodes
        final nextPage = _currentPage + 1;
        final result = await podcastRepository.getPodcastDetailsWithEpisodes(
          podcastId,
          context: context,
          page: nextPage,
          perPage: 50,
        );

        if (result['episodes'] != null) {
          final newEpisodes = result['episodes'] as List<Episode>;
          final meta = result['meta'] as Map<String, dynamic>?;

          setState(() {
            episodes.addAll(newEpisodes);
            _currentPage = nextPage;
            _hasMorePages = meta?['has_more'] ?? (newEpisodes.length >= 50);
            _isLoadingMore = false;
          });
        } else {
          setState(() {
            _isLoadingMore = false;
            _hasMorePages = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading more episodes: $e');
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  void _playEpisode(Map<String, dynamic> episode) {
    try {
      debugPrint('🎵 Playing episode directly: ${episode['title']}');

      // Get the player provider
      final playerProvider =
          Provider.of<PodcastPlayerProvider>(context, listen: false);

      // Convert episode to Episode model if needed
      final episodeModel = Episode(
        id: int.tryParse(episode['id']?.toString() ?? '0') ?? 0,
        title: episode['title'] ?? 'Untitled Episode',
        description: episode['description'] ?? '',
        audioUrl: episode['audioUrl'] ?? '',
        coverImage: episode['coverImage'] ?? '',
        duration: episode['duration']?.toString() ?? '0',
        releaseDate:
            DateTime.tryParse(episode['releaseDate'] ?? '') ?? DateTime.now(),
        podcastName: episode['podcastName'] ??
            widget.podcast['title'] ??
            'Unknown Podcast',
        creator:
            episode['creator'] ?? widget.podcast['author'] ?? 'Unknown Creator',
        isDownloaded: episode['isDownloaded'] ?? false,
        // Add progress tracking fields
        lastPlayedPosition: episode['lastPlayedPosition'],
        totalDuration: episode['totalDuration'],
        lastPlayedAt: episode['lastPlayedAt'] != null
            ? DateTime.tryParse(episode['lastPlayedAt'])
            : null,
        isCompleted: episode['isCompleted'] ?? false,
      );

      // Set episode queue for auto-play functionality
      debugPrint('🎵 Setting episode queue for auto-play...');
      final episodeModels = episodes; // episodes is already List<Episode>
      final episodeIndex = episodes
          .indexWhere((e) => e.id.toString() == episode['id'].toString());
      final startIndex = episodeIndex >= 0 ? episodeIndex : 0;

      playerProvider.setEpisodeQueue(episodeModels,
          startIndex: startIndex, podcastId: widget.podcast['id']?.toString());
      playerProvider.setCurrentPodcastData(widget.podcast);
      debugPrint('🎵 Episode queue set successfully for auto-play');

      // Load and play the episode directly
      playerProvider.loadAndPlayEpisode(episodeModel, clearQueue: false);

      // Prepare episode data with podcast information for mini-player
      final episodeWithPodcastInfo =
          episodeModel.toMapWithPodcastData(widget.podcast);

      // Show the floating mini-player with proper parameters
      playerProvider.showFloatingMiniPlayer(
        context,
        episodeWithPodcastInfo,
        episodes.map((e) => e.toMapWithPodcastData(widget.podcast)).toList(),
        startIndex,
      );

      debugPrint(
          '✅ Episode playback started successfully with auto-play enabled');
    } catch (e) {
      debugPrint('❌ Error playing episode: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error playing episode: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Show episode detail modal for a specific episode
  void _showEpisodeDetailModal(
      BuildContext context,
      Map<String, dynamic> episode,
      List<Map<String, dynamic>> episodes,
      int episodeIndex) {
    // Convert episode to Episode model and then back to map with podcast data
    final episodeModel = Episode.fromJson(episode);
    final episodeWithPodcastInfo =
        episodeModel.toMapWithPodcastData(widget.podcast);

    // Add feedId directly to episode data for archive service
    episodeWithPodcastInfo['feedId'] = widget.podcast['id']?.toString() ?? '';
    episodeWithPodcastInfo['podcastId'] =
        widget.podcast['id']?.toString() ?? '';

    // Prepare episodes list with podcast information
    final episodesWithPodcastInfo = episodes.map((e) {
      final episodeModel = Episode.fromJson(e);
      final episodeWithInfo = episodeModel.toMapWithPodcastData(widget.podcast);
      // Add feedId directly to episode data for archive service
      episodeWithInfo['feedId'] = widget.podcast['id']?.toString() ?? '';
      episodeWithInfo['podcastId'] = widget.podcast['id']?.toString() ?? '';
      return episodeWithInfo;
    }).toList();

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
            episode: episodeWithPodcastInfo,
            episodes: episodesWithPodcastInfo,
            episodeIndex: episodeIndex,
          ),
        ),
      ),
    );
  }

  Future<void> _downloadEpisode(Map<String, dynamic> episode) async {
    final episodeId =
        EpisodeUtils.extractEpisodeId(episode) ?? episode['id'].toString();
    final episodeTitle = EpisodeUtils.extractEpisodeTitle(episode);
    final audioUrl = EpisodeUtils.extractAudioUrl(episode);

    if (audioUrl == null || audioUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No audio URL available for download.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Use the new download system
      await _downloadManager.downloadEpisodeWithValidation(
        episodeId: episodeId,
        episodeTitle: episodeTitle,
        audioUrl: audioUrl,
        context: context,
        onDownloadComplete: () {
          // Update the episode's download status in the UI
          setState(() {
            final index = episodes.indexWhere(
              (e) => e.id.toString() == episodeId,
            );
            if (index != -1) {
              final updatedEpisode = Episode(
                id: episodes[index].id,
                title: episodes[index].title,
                podcastName: episodes[index].podcastName,
                creator: episodes[index].creator,
                coverImage: episodes[index].coverImage,
                duration: episodes[index].duration,
                isDownloaded: true, // Mark as downloaded
                description: episodes[index].description,
                audioUrl: episodes[index].audioUrl,
                releaseDate: episodes[index].releaseDate,
                // Add progress tracking fields
                lastPlayedPosition: episodes[index].lastPlayedPosition,
                totalDuration: episodes[index].totalDuration,
                lastPlayedAt: episodes[index].lastPlayedAt,
                isCompleted: episodes[index].isCompleted,
              );
              episodes[index] = updatedEpisode;
            }
          });
        },
        onDownloadError: () {
          // Handle download error
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Download failed. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('Download error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Extract audio URL from episode data
  String? _extractAudioUrl(Map<String, dynamic> episode) {
    // Try different possible keys for audio URL
    final possibleKeys = [
      'audioUrl',
      'enclosureUrl',
      'audio_url',
      'enclosure_url',
      'url',
      'link',
    ];

    for (final key in possibleKeys) {
      final value = episode[key];
      if (value != null && value is String && value.isNotEmpty) {
        debugPrint('Found audio URL in key "$key": $value');
        return value;
      }
    }

    debugPrint(
        'No audio URL found in episode data. Available keys: ${episode.keys.toList()}');
    return null;
  }

  Future<void> _removeDownload(Map<String, dynamic> episode) async {
    final episodeId = episode['id'].toString();

    try {
      await _downloadManager.deleteDownloadedEpisode(episodeId, context);

      // Update the episode's download status in the UI
      setState(() {
        final index = episodes.indexWhere(
          (e) => e.id.toString() == episodeId,
        );
        if (index != -1) {
          final updatedEpisode = Episode(
            id: episodes[index].id,
            title: episodes[index].title,
            podcastName: episodes[index].podcastName,
            creator: episodes[index].creator,
            coverImage: episodes[index].coverImage,
            duration: episodes[index].duration,
            isDownloaded: false, // Mark as not downloaded
            description: episodes[index].description,
            audioUrl: episodes[index].audioUrl,
            releaseDate: episodes[index].releaseDate,
            // Add progress tracking fields
            lastPlayedPosition: episodes[index].lastPlayedPosition,
            totalDuration: episodes[index].totalDuration,
            lastPlayedAt: episodes[index].lastPlayedAt,
            isCompleted: episodes[index].isCompleted,
          );
          episodes[index] = updatedEpisode;
        }
      });
    } catch (e) {
      debugPrint('Remove download error: $e');
    }
  }

  void _shareEpisode(Map<String, dynamic> episode) async {
    try {
      final episodeTitle = episode['title'] ?? 'Unknown Episode';
      final podcastTitle = widget.podcast['title'] ?? 'Unknown Podcast';
      final episodeDescription = episode['description'] ?? '';
      final audioUrl = episode['audioUrl'] ?? '';

      await SocialSharingService().shareEpisode(
        episodeTitle: episodeTitle,
        podcastTitle: podcastTitle,
        episodeDescription: episodeDescription,
        episodeUrl: audioUrl.isNotEmpty ? audioUrl : null,
        customMessage: 'Check out this amazing episode!',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Episode shared successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error sharing episode: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing episode: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionProvider>(
      builder: (context, subscriptionProvider, child) {
        final podcastId = widget.podcast['id'].toString();
        final isSubscribed = subscriptionProvider.isSubscribed(podcastId);
        final notificationsEnabled = true; // Enable notifications by default

        if (subscriptionProvider.errorMessage != null) {
          return Scaffold(
            appBar: AppBar(title: Text('Podcast Detail')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(subscriptionProvider.errorMessage!),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      subscriptionProvider
                          .fetchAndSetSubscriptionsFromBackend();
                    },
                    child: Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        // Use the loaded podcast data or fall back to the passed podcast data
        final podcastData =
            _podcast != null ? _podcast!.toMap() : widget.podcast;

        // Debug information
        debugPrint(
            'Build method - Loading:  [32m [1m$_isLoading [0m, Error: $_errorMessage');
        debugPrint('Build method - Episodes count: ${episodes.length}');
        debugPrint('Build method - Podcast data: ${podcastData['title']}');

        return Scaffold(
          backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
          bottomNavigationBar: CommonBottomNavigationWidget(
            currentIndex: 0, // Default to home tab
            onTabSelected: (index) {
              switch (index) {
                case 0:
                  Navigator.pushReplacementNamed(context, AppRoutes.homeScreen);
                  break;
                case 1:
                  Navigator.pushReplacementNamed(context, AppRoutes.earnScreen);
                  break;
                case 2:
                  Navigator.pushReplacementNamed(
                      context, AppRoutes.libraryScreen);
                  break;
                case 3:
                  Navigator.pushReplacementNamed(
                      context, AppRoutes.walletScreen);
                  break;
                case 4:
                  Navigator.pushReplacementNamed(
                      context, AppRoutes.profileScreen);
                  break;
              }
            },
          ),
          body: RefreshIndicator(
            onRefresh: _onRefresh,
            child: CustomScrollView(
              controller: scrollController,
              physics: SmoothScrollUtils.defaultPhysics,
              slivers: [
                // Header with podcast info
                SliverToBoxAdapter(
                  child: PodcastHeaderWidget(
                    podcast: podcastData,
                    isSubscribed: isSubscribed,
                    notificationsEnabled: notificationsEnabled,
                    onSubscriptionToggle: _toggleSubscription,
                    onNotificationToggle: _toggleNotifications,
                  ),
                ),

                // Tab bar
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverTabBarDelegate(
                    TabBar(
                      controller: _tabController,
                      labelStyle:
                          AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      unselectedLabelStyle:
                          AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w400,
                      ),
                      indicatorColor: AppTheme.lightTheme.colorScheme.primary,
                      labelColor: AppTheme.lightTheme.colorScheme.primary,
                      unselectedLabelColor:
                          AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      tabs: const [
                        Tab(text: 'Episodes'),
                        Tab(text: 'Bookmarks'),
                        Tab(text: 'About'),
                      ],
                    ),
                  ),
                ),

                // Tab content - Conditional rendering based on active tab
                if (_tabController.index == 0) ...[
                  // Episodes tab - Use SliverList to show all episodes
                  if (!_isLoading && (_errorMessage?.isEmpty ?? true))
                    _buildEpisodesSliverList()
                  else if (_isLoading)
                    SliverToBoxAdapter(child: _buildLoadingView())
                  else
                    SliverToBoxAdapter(child: _buildErrorView()),
                ] else if (_tabController.index == 1) ...[
                  // Bookmarks tab
                  SliverToBoxAdapter(
                    child: _isLoading
                        ? _buildLoadingView()
                        : (_errorMessage?.isNotEmpty ?? false)
                            ? _buildErrorView()
                            : _buildBookmarksTab(),
                  ),
                ] else ...[
                  // About tab
                  SliverToBoxAdapter(
                    child: Builder(
                      builder: (context) {
                        debugPrint(
                            'DetailScreen: AboutTabWidget episodeCount: $_episodeCount');
                        return AboutTabWidget(
                          podcast: _podcast,
                          episodeCount: _episodeCount,
                          episodes: episodes,
                          fromEarnTab: (ModalRoute.of(context)
                                  ?.settings
                                  .arguments is Map &&
                              (ModalRoute.of(context)?.settings.arguments
                                      as Map)['fromEarnTab'] ==
                                  true),
                        );
                      },
                    ),
                  ),
                ],

                // Add bottom padding for mini-player
                SliverToBoxAdapter(
                  child: SizedBox(
                      height:
                          MiniPlayerPositioning.bottomPaddingForScrollables()),
                ),
              ],
            ),
          ),
          // Scroll to top button - commented out for now
          // floatingActionButton: episodes.isNotEmpty
          //     ? FloatingActionButton(
          //         mini: true,
          //         onPressed: scrollToTop,
          //         backgroundColor: AppTheme.lightTheme.colorScheme.primary,
          //         foregroundColor: Colors.white,
          //         child: const Icon(Icons.keyboard_arrow_up),
          //       )
          //     : null,
        );
      },
    );
  }

  void _toggleSubscription() {
    // TODO: Implement subscription toggle
  }

  void _toggleNotifications() {
    // TODO: Implement notifications toggle
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppTheme.lightTheme.colorScheme.primary,
          ),
          SizedBox(height: 20),
          Text(
            'Loading podcast details...',
            style: AppTheme.lightTheme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'error',
            color: Colors.red,
            size: 48,
          ),
          const SizedBox(height: 20),
          Text(
            'Error Loading Podcast',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _errorMessage!,
              style: AppTheme.lightTheme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadPodcastData,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lightTheme.colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodesTab() {
    final convertedEpisodes = _convertEpisodesToMap();
    debugPrint(
        'Building redesigned episodes tab with ${convertedEpisodes.length} episodes');

    return RedesignedEpisodesTabWidget(
      episodes: convertedEpisodes,
      onPlayEpisode: _playEpisode,
      onDownloadEpisode: _downloadEpisode,
      onShareEpisode: _shareEpisode,
      totalEpisodes: _episodeCount,
      archivedEpisodes: 0, // TODO: Implement archived episodes count
      showArchived: false, // TODO: Implement archived episodes toggle
      onShowArchivedToggle: () {
        // TODO: Implement archived episodes toggle functionality
        debugPrint('Toggle archived episodes');
      },
      podcastData: widget.podcast, // Pass podcast data to episodes tab
      // Pagination properties
      hasMorePages: _hasMorePages,
      isLoadingMore: _isLoadingMore,
      onLoadMore: _loadMoreEpisodes,
    );
  }

  /// Build episodes as a SliverList to allow full expansion and scrolling
  Widget _buildEpisodesSliverList() {
    final convertedEpisodes = _convertEpisodesToMap();
    debugPrint(
        'Building episodes sliver list with ${convertedEpisodes.length} episodes');

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == 0) {
            // First item is the episodes tab widget
            return RedesignedEpisodesTabWidget(
              episodes: convertedEpisodes,
              onPlayEpisode: _playEpisode,
              onDownloadEpisode: _downloadEpisode,
              onShareEpisode: _shareEpisode,
              totalEpisodes: _episodeCount,
              archivedEpisodes: 0,
              showArchived: false,
              onShowArchivedToggle: () {
                debugPrint('Toggle archived episodes');
              },
              podcastData: widget.podcast, // Pass podcast data to episodes tab
              // Pagination properties
              hasMorePages: _hasMorePages,
              isLoadingMore: _isLoadingMore,
              onLoadMore: _loadMoreEpisodes,
            );
          }
          return null;
        },
        childCount: 1, // Only one child - the episodes tab widget
      ),
    );
  }

  Widget _buildBookmarksTab() {
    final convertedEpisodes = _convertEpisodesToMap();
    final podcastId = widget.podcast['id']?.toString() ?? '';

    return BookmarksTabWidget(
      episodes: convertedEpisodes,
      podcastId: podcastId,
    );
  }

  // Helper method to convert Episode objects to Maps for the episodes widget
  List<Map<String, dynamic>> _convertEpisodesToMap() {
    debugPrint('Converting ${episodes.length} episodes to map format');
    return episodes.map((episode) {
      final episodeMap = {
        'id': episode.id,
        'title': episode.title,
        'podcastName': episode.podcastName,
        'creator': episode.creator,
        'coverImage': episode.coverImage,
        'duration': episode.duration,
        'isDownloaded': episode.isDownloaded,
        'description': episode.description,
        'audioUrl': episode.audioUrl,
        'releaseDate': episode.releaseDate.toIso8601String(),
        'publishDate':
            '${episode.releaseDate.year}-${episode.releaseDate.month.toString().padLeft(2, '0')}-${episode.releaseDate.day.toString().padLeft(2, '0')}',
        'isEarningEpisode': false,
        'coinsPerMinute': 0.0,
        'isPlayed': false,
        'progress': 0.0,
        'hasTranscript': episode.description?.isNotEmpty ==
            true, // Simple transcript detection
      };
      debugPrint('Converted episode: ${episode.title} with ID: ${episode.id}');
      return episodeMap;
    }).toList();
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppTheme.lightTheme.colorScheme.surface,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
