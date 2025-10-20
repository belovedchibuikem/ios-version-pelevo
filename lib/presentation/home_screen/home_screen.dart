import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../data/models/category.dart';
import '../../data/models/podcast.dart';
import '../../data/models/episode.dart';
import '../../data/repositories/podcast_repository.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../core/services/auth_service.dart';
import '../../widgets/common_bottom_navigation_widget.dart';
import './widgets/categories_section_widget.dart';
import './widgets/featured_podcast_card_widget.dart';
import './widgets/podcast_category_section_widget.dart';
import './widgets/search_header_widget.dart';
import './widgets/featured_podcasts_section_widget.dart';
import './widgets/advanced_search_modal.dart';
//import './widgets/episodes_section_widget.dart';
import '../../core/routes/app_routes.dart';
import './see_all_podcasts_screen.dart';
import '../../services/audio_player_service.dart';
import '../../services/subscription_helper.dart';
import './widgets/subscribe_button.dart';
import 'package:provider/provider.dart';
import '../../providers/subscription_provider.dart';
import '../../core/error_handling/global_error_handler.dart';
import '../../core/utils/smooth_scroll_utils.dart';
import '../../core/utils/safe_error_handler.dart';
import '../../widgets/episode_detail_modal.dart';
import '../../providers/podcast_player_provider.dart';
import '../../widgets/floating_mini_player_overlay.dart';
import '../../widgets/network_status_widget.dart';
import '../../core/utils/mini_player_positioning.dart';

// lib/presentation/home_screen/home_screen.dart

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, SafeStateMixin, SmoothScrollMixin {
  final ScrollController _scrollController = ScrollController();
  final NavigationService _navigationService = NavigationService();
  final PodcastRepository _podcastRepository = PodcastRepository();
  final UserRepository _userRepository = UserRepository();
  int _selectedTabIndex = 0;
  bool _isSearchActive = false;
  bool _isLoading = true;
  String _errorMessage = '';

  // State variables to store fetched data
  List<Category> categories = [];
  List<Podcast> featuredPodcasts = [];
  List<Podcast> trendingPodcasts = [];
  List<Podcast> recommendedPodcasts = [];
  List<Podcast> crimeArchivesPodcasts = [];
  List<Podcast> healthPodcasts = [];
  bool _isCrimeArchivesLoading = true;
  bool _isHealthPodcastsLoading = true;
  List<String> subscribedCategories = [];
  List<Podcast> _searchResults = [];
  bool _isSearching = false;
  String _searchQuery = '';

  final AudioPlayerService _audioPlayerService = AudioPlayerService();
  StreamSubscription<bool>? _playingStateSub;
  StreamSubscription<Duration?>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription? _episodeSub;

  Map<String, bool> _trendingLoading = {};

  @override
  void initState() {
    super.initState();

    // Mini-player will auto-detect bottom navigation positioning

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final subscriptionProvider =
          Provider.of<SubscriptionProvider>(context, listen: false);
      subscriptionProvider.fetchAndSetSubscriptionsFromBackend();
    });
    _initializeData();
    _loadUserSubscriptions();
    _audioPlayerService.initialize();
    // AudioPlayerService no longer provides playingStateStream
    // Playing state will be managed locally when calling play/pause methods
    _positionSub = _audioPlayerService.positionStream.listen((pos) {
      safeSetState(() {
        // _currentPosition = pos ?? Duration.zero; // Removed
      });
    });
    _durationSub = _audioPlayerService.durationStream.listen((dur) {
      safeSetState(() {
        // _totalDuration = dur ?? Duration.zero; // Removed
      });
    });
    // _updatePlayerVisibility(); // Removed
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _playingStateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    super.dispose();
  }

  Future<void> _initializeData({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _isCrimeArchivesLoading = true;
      _isHealthPodcastsLoading = true;
    });

    try {
      // Get user token for authenticated requests
      final authService = AuthService();
      final token = await authService.getToken();
      debugPrint(
          '🔐 HomeScreen: Token retrieved: ${token != null ? 'Yes' : 'No'}');
      if (token != null) {
        debugPrint('🔐 HomeScreen: Token length: ${token.length}');
        debugPrint(
            '🔐 HomeScreen: Token preview: ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
        debugPrint('🔐 HomeScreen: Full token: $token');
      } else {
        debugPrint('⚠️ HomeScreen: No token available');
      }

      // Initialize repository if needed
      debugPrint('🔐 HomeScreen: Initializing repository...');
      await _podcastRepository.initialize();

      // Check API health first
      try {
        debugPrint('🏥 Checking API health...');
        final healthCheck = await _podcastRepository.getCategories();
        if (healthCheck.isEmpty) {
          debugPrint('⚠️ API health check failed - no categories returned');
          // Try to show cached data instead of failing completely
          debugPrint('📱 Attempting to load cached data...');
          _loadCachedData();
          return;
        }
        debugPrint('✅ API health check passed');
      } catch (e) {
        debugPrint('❌ API health check failed: $e');
        debugPrint('📱 Attempting to load cached data...');
        _loadCachedData();
        return;
      }

      // Fetch data sequentially to avoid overwhelming the server
      debugPrint('🔄 Starting sequential API calls...');

      try {
        // 1. Categories (most important)
        debugPrint('📂 Fetching categories...');
        final categoriesResult = await _podcastRepository.getCategories();
        if (mounted) {
          setState(() {
            categories = categoriesResult;
            debugPrint('✅ Categories loaded: ${categoriesResult.length}');
          });
        }

        // 2. Featured podcasts
        debugPrint('⭐ Fetching featured podcasts...');
        final featuredResult =
            await _podcastRepository.getFeaturedPodcasts(context: context);
        if (mounted) {
          setState(() {
            featuredPodcasts = featuredResult;
            debugPrint('✅ Featured podcasts loaded: ${featuredResult.length}');
          });
        }

        // 3. Trending podcasts
        debugPrint('🔥 Fetching trending podcasts...');
        final trendingResult =
            await _podcastRepository.getTrendingPodcasts(context: context);
        if (mounted) {
          setState(() {
            trendingPodcasts = trendingResult;
            debugPrint('✅ Trending podcasts loaded: ${trendingResult.length}');
          });
        }

        // 4. Recommended podcasts
        debugPrint('💡 Fetching recommended podcasts...');
        final recommendedResult =
            await _podcastRepository.getRecommendedPodcasts(context: context);
        if (mounted) {
          setState(() {
            recommendedPodcasts = recommendedResult;
            debugPrint(
                '✅ Recommended podcasts loaded: ${recommendedResult.length}');
          });
        }

        // 5. Crime archives
        debugPrint('🕵️ Fetching crime archives...');
        final crimeResult = await _podcastRepository.getCrimeArchivesPodcasts();
        if (mounted) {
          setState(() {
            crimeArchivesPodcasts = crimeResult;
            _isCrimeArchivesLoading = false;
            debugPrint('✅ Crime archives loaded: ${crimeResult.length}');
          });
        }

        // 6. Health podcasts
        debugPrint('🏥 Fetching health podcasts...');
        final healthResult = await _podcastRepository.getHealthPodcasts();
        if (mounted) {
          setState(() {
            healthPodcasts = healthResult;
            _isHealthPodcastsLoading = false;
            debugPrint('✅ Health podcasts loaded: ${healthResult.length}');
          });
        }

        // All done
        if (mounted) {
          setState(() {
            _isLoading = false;
            debugPrint('🎉 All podcast data loaded successfully!');
          });
        }
      } catch (e) {
        debugPrint('❌ Error in sequential API calls: $e');
        // Continue with whatever data we have
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isCrimeArchivesLoading = false;
            _isHealthPodcastsLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error initializing data: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load podcast data. Please try again.';
          _isLoading = false;
          _isCrimeArchivesLoading = false;
          _isHealthPodcastsLoading = false;
        });

        // Show a retry button
        _showRetryDialog();
      }
    }
  }

  Future<void> _loadUserSubscriptions() async {
    try {
      final user = await _userRepository.getCurrentUser();
      if (user != null && mounted) {
        setState(() {
          subscribedCategories = user.subscribedCategories;
        });
      }
    } catch (e) {
      debugPrint('Error loading user subscriptions: $e');
    }
  }

  void _showRetryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connection Error'),
        content: const Text(
            'Failed to load podcast data. Please check your internet connection and try again.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _initializeData(forceRefresh: true);
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _loadCachedData() {
    debugPrint('📱 Loading cached data...');
    // For now, just show empty state with retry option
    if (mounted) {
      setState(() {
        _errorMessage =
            'You\'re offline. Please check your connection and try again.';
        _isLoading = false;
        _isCrimeArchivesLoading = false;
        _isHealthPodcastsLoading = false;
      });
    }
  }

  Future<void> _onSubscribe(Podcast podcast) async {
    await handleSubscribeAction(
      context: context,
      podcastId: podcast.id.toString(),
      isCurrentlySubscribed: podcast.isSubscribed,
      onStateChanged: (bool subscribed) {
        if (mounted) {
          setState(() {
            void updateList(List<Podcast> list) {
              final idx = list.indexWhere((p) => p.id == podcast.id);
              if (idx != -1) {
                list[idx] = list[idx].copyWith(isSubscribed: subscribed);
              }
            }

            updateList(featuredPodcasts);
            updateList(trendingPodcasts);
            updateList(recommendedPodcasts);
            updateList(crimeArchivesPodcasts);
            updateList(healthPodcasts);
          });
        }
      },
    );
  }

  // void _updatePlayerVisibility() { // Removed
  //   setState(() {
  //     _isPlayerVisible = _currentEpisode != null &&
  //         (_isPlaying || _currentPosition > Duration.zero);

  //     // Debug logging for mini player episode data
  //     if (_currentEpisode != null) {
  //       debugPrint(
  //           'MiniPlayer: Current episode feedId: ${_currentEpisode!['feedId']}');
  //       debugPrint(
  //           'MiniPlayer: Current episode title: ${_currentEpisode!['title']}');
  //       debugPrint('MiniPlayer: Current episode data: $_currentEpisode');
  //     }
  //   });
  // }

  void _onPodcastPlay(Map<String, dynamic> episode) {
    if (episode['audioUrl'] != null && episode['audioUrl'].isNotEmpty) {
      safeSetState(() {
        // _currentEpisode = episode; // Removed
        // _isPlaying = true; // Removed
        // _isPlayerVisible = true; // Removed
      });

      // Use the provider to show the floating mini-player
      final playerProvider =
          Provider.of<PodcastPlayerProvider>(context, listen: false);
      if (playerProvider.currentEpisode == null) {
        // Convert episode to Episode model and set it
        final episodeModel = Episode.fromJson(episode);
        playerProvider.setCurrentEpisode(episodeModel);
        playerProvider.play();
      }

      debugPrint('Home Screen: Playing episode: ${episode['title']}');
      debugPrint('Home Screen: Episode data: $episode');
    }
  }

  /// Build a mapping of episode identifiers to podcast IDs for fallback matching
  Map<String, String> _buildEpisodeToPodcastMapping() {
    final Map<String, String> episodeToPodcast = {};

    // Add all podcasts to the mapping
    final allPodcasts = [
      ...featuredPodcasts,
      ...trendingPodcasts,
      ...recommendedPodcasts,
      ...crimeArchivesPodcasts,
      ...healthPodcasts,
    ];

    // For now, we'll use a simple approach: map podcast name/creator to podcast ID
    // This helps when we have episode data with podcastName/creator but no feedId
    for (final podcast in allPodcasts) {
      if (podcast.id.isNotEmpty) {
        // Map by podcast title (case insensitive)
        episodeToPodcast[podcast.title.toLowerCase()] = podcast.id;
        // Map by creator (case insensitive)
        episodeToPodcast[podcast.creator.toLowerCase()] = podcast.id;
      }
    }

    return episodeToPodcast;
  }

  /// Enhanced fallback matching for finding podcast from episode data
  String? _findPodcastIdFromEpisode(Map<String, dynamic> episode) {
    final episodeToPodcast = _buildEpisodeToPodcastMapping();

    // Try to match by podcastName
    final String? podcastName = episode['podcastName']?.toString();
    if (podcastName != null && podcastName.isNotEmpty) {
      final podcastId = episodeToPodcast[podcastName.toLowerCase()];
      if (podcastId != null) {
        debugPrint(
            'MiniPlayer Expand: Found podcast by podcastName: $podcastName -> $podcastId');
        return podcastId;
      }
    }

    // Try to match by creator
    final String? creator = episode['creator']?.toString();
    if (creator != null && creator.isNotEmpty) {
      final podcastId = episodeToPodcast[creator.toLowerCase()];
      if (podcastId != null) {
        debugPrint(
            'MiniPlayer Expand: Found podcast by creator: $creator -> $podcastId');
        return podcastId;
      }
    }

    // Try partial matching for podcastName
    if (podcastName != null && podcastName.isNotEmpty) {
      for (final entry in episodeToPodcast.entries) {
        if (entry.key.contains(podcastName.toLowerCase()) ||
            podcastName.toLowerCase().contains(entry.key)) {
          debugPrint(
              'MiniPlayer Expand: Found podcast by partial name match: $podcastName -> ${entry.value}');
          return entry.value;
        }
      }
    }

    // Try partial matching for creator
    if (creator != null && creator.isNotEmpty) {
      for (final entry in episodeToPodcast.entries) {
        if (entry.key.contains(creator.toLowerCase()) ||
            creator.toLowerCase().contains(entry.key)) {
          debugPrint(
              'MiniPlayer Expand: Found podcast by partial creator match: $creator -> ${entry.value}');
          return entry.value;
        }
      }
    }

    return null;
  }

  void _onPodcastExpand(Map<String, dynamic> episode) async {
    if (episode['audioUrl'] != null && episode['audioUrl'].isNotEmpty) {
      // Show episode detail modal
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        isDismissible: true,
        enableDrag: false,
        builder: (context) => EpisodeDetailModal(
          episode: episode,
          episodes: [episode], // Single episode for now
          episodeIndex: 0,
        ),
      );
    }
  }

  /// Find the full podcast object from episode data
  Map<String, dynamic>? _findPodcastFromEpisode(Map<String, dynamic> episode) {
    // Try to find the podcast in all available lists
    final allPodcasts = [
      ...featuredPodcasts,
      ...trendingPodcasts,
      ...recommendedPodcasts,
      ...crimeArchivesPodcasts,
      ...healthPodcasts,
    ];

    // Look for podcast by ID or title
    final episodeId = episode['id']?.toString();
    final episodeTitle = episode['title']?.toString();

    if (episodeId != null) {
      final podcast = allPodcasts.firstWhere(
        (podcast) => podcast.id.toString() == episodeId,
        orElse: () => allPodcasts.firstWhere(
          (podcast) => podcast.title == episodeTitle,
          orElse: () => allPodcasts.first,
        ),
      );

      // Convert podcast to map format expected by player
      return {
        'id': podcast.id,
        'title': podcast.title,
        'creator': podcast.creator,
        'description': podcast.description ?? 'No description available',
        'coverImage': podcast.coverImage,
        'category': podcast.category ?? 'General',
        'tags': [], // Default empty tags
        'updateFrequency': 'Weekly', // Default value
        'totalDuration': podcast.duration,
        'subscribers': '0', // Default value
        'rating': 4.5, // Default value
        // 'currentEpisode':
        //     _currentEpisode, // Pass the current episode separately // Removed
        'episodes': [
          // _currentEpisode! // Removed
        ], // Include current episode in episodes list
      };
    }

    return null;
  }

  /// Helper to play an episode and always attach feedId
  void _playEpisodeFromHome(Podcast podcast, Map<String, dynamic> episode) {
    if (podcast.id == null || podcast.id.toString().isEmpty) {
      debugPrint(
          'Error: Podcast ID is missing or invalid! Podcast: ${podcast.title}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot play episode: Podcast ID is invalid.')),
      );
      return;
    }
    final episodeWithFeedId = Map<String, dynamic>.from(episode);
    episodeWithFeedId['feedId'] =
        podcast.id; // Always set the unique podcast ID
    debugPrint(
        'Playing episode with feedId: ${podcast.id} for podcast: ${podcast.title}');
    debugPrint('Episode data before playing: $episodeWithFeedId');
    final episodeModel = Episode.fromJson(episodeWithFeedId);
    _audioPlayerService.playEpisode(episodeModel);
    setState(() {
      // _currentEpisode = episodeWithFeedId; // Removed
      // _isPlayerVisible = true; // Removed
    });
    debugPrint('Episode played successfully in home screen');
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedTabIndex = index;
    });

    switch (index) {
      case 0:
        // Already on Home
        break;
      case 1:
        _navigationService.navigateTo(AppRoutes.earnScreen);
        break;
      case 2:
        // Navigate to Library
        _navigationService.navigateTo(AppRoutes.libraryScreen);
        break;
      case 3:
        // Navigate to Wallet
        _navigationService.navigateTo(AppRoutes.walletScreen);
        break;
      case 4:
        // Navigate to Profile
        _navigationService.navigateTo(AppRoutes.profileScreen);
        break;
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
    debugPrint('🔍 HomeScreen: Search triggered with query: $query');
    setState(() {
      _searchQuery = query;
      _searchResults = [];
    });
    _showAdvancedSearchModal();
  }

  void _showAdvancedSearchModal() {
    debugPrint(
        '🔍 HomeScreen: Showing advanced search modal with query: $_searchQuery');
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AdvancedSearchModal(
          initialQuery: _searchQuery,
          onResults: (results) {
            debugPrint(
                '🔍 HomeScreen: Received ${results.length} search results');
            setState(() {
              _searchResults = results;
            });
          },
          onClose: () {
            debugPrint('🔍 HomeScreen: Closing advanced search modal');
            Navigator.of(context).pop();
            setState(() {
              _isSearchActive = false;
            });
          },
        );
      },
    );
  }

  void _showSearchResultsModal() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              insetPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 40),
              backgroundColor: Colors.transparent,
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(maxWidth: 600),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Search Results for "$_searchQuery"',
                              style: AppTheme.lightTheme.textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                    if (_isSearching)
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: CircularProgressIndicator(),
                      )
                    else if (_searchResults.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text('No podcasts found.'),
                      )
                    else
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: SmoothScrollUtils.defaultPhysics,
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final podcast = _searchResults[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: FeaturedPodcastCardWidget(
                                podcast: podcast.toJson(),
                                isSubscribed: podcast.isSubscribed,
                                onTap: () {
                                  Navigator.of(context).pop();
                                  _onPodcastTap(podcast);
                                },
                                onSubscribe: () async =>
                                    await _onSubscribe(podcast),
                                onPlay: () async {
                                  // Fetch episodes for this podcast
                                  final podcastId = podcast.id is int
                                      ? podcast.id as int
                                      : int.tryParse(podcast.id) ?? 0;
                                  final episodes = await _podcastRepository
                                      .getPodcastEpisodes(podcastId);
                                  if (episodes.isNotEmpty) {
                                    final episode = episodes.first;

                                    // Convert episodes to map format for the modal
                                    final episodeMaps = episodes
                                        .map((e) => e.toJson())
                                        .toList();
                                    final episodeIndex = 0; // First episode

                                    // Close search modal first
                                    Navigator.of(context).pop();

                                    // Show episode detail modal instead of just playing
                                    _showEpisodeDetailModal(
                                        context,
                                        episode.toJson(),
                                        episodeMaps,
                                        episodeIndex);
                                  } else {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'No episodes available for this podcast.')),
                                      );
                                    }
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _onPodcastTap(Podcast podcast) async {
    debugPrint('=== PODCAST TAP DEBUG ===');
    debugPrint('Podcast ID: ${podcast.id}');
    debugPrint('Podcast Title: ${podcast.title}');
    debugPrint('Podcast Creator: ${podcast.creator}');
    debugPrint('Podcast Cover Image: ${podcast.coverImage}');
    debugPrint('Navigation Service: $_navigationService');

    // Validate required fields before navigation
    if (podcast.id == null || podcast.id.toString().isEmpty) {
      debugPrint('Navigation error: Podcast ID is null or empty');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot navigate: Podcast ID is missing'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final arguments = {
        'id': podcast.id,
        'title': podcast.title ?? 'Unknown Title',
        'creator': podcast.creator ?? 'Unknown Creator',
        'author': podcast.author ?? podcast.creator ?? 'Unknown Author',
        'coverImage': podcast.coverImage ?? '',
        'image': podcast.coverImage ??
            '', // Also include 'image' field for compatibility
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

      debugPrint('Navigation arguments: $arguments');
      final result = await _navigationService
          .navigateTo(AppRoutes.podcastDetailScreen, arguments: arguments);
      // Note: Removed navigation failed error message to mute yellow error during navigation
      // The NavigationService handles navigation gracefully and returns null on failure
      if (result == null) {
        debugPrint('Navigation completed (result is null - this is normal)');
        return;
      }
      debugPrint('Navigation successful');
    } catch (e) {
      debugPrint('Navigation error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error navigating to podcast: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Show episode detail modal for a specific episode
  void _showEpisodeDetailModal(
      BuildContext context,
      Map<String, dynamic> episode,
      List<Map<String, dynamic>> episodes,
      int episodeIndex) {
    // Add feedId and podcastId to episode data for archive service
    final enhancedEpisode = Map<String, dynamic>.from(episode);
    if (episode['feedId'] == null && episode['podcastId'] == null) {
      // Try to get podcast ID from the episode data
      final podcastId = episode['podcast']?['id']?.toString() ??
          episode['podcastId']?.toString() ??
          episode['feedId']?.toString();

      if (podcastId != null && podcastId.isNotEmpty) {
        enhancedEpisode['feedId'] = podcastId;
        enhancedEpisode['podcastId'] = podcastId;
      }
    }

    // Ensure episode has proper podcast object structure for image display
    if (enhancedEpisode['podcast'] == null) {
      final podcastData = _constructPodcastDataFromEpisode(enhancedEpisode);
      if (podcastData.isNotEmpty) {
        enhancedEpisode['podcast'] = podcastData;
      }
    }

    // Enhance episodes list as well
    final enhancedEpisodes = episodes.map((e) {
      final enhancedE = Map<String, dynamic>.from(e);
      if (e['feedId'] == null && e['podcastId'] == null) {
        final podcastId = e['podcast']?['id']?.toString() ??
            e['podcastId']?.toString() ??
            e['feedId']?.toString();

        if (podcastId != null && podcastId.isNotEmpty) {
          enhancedE['feedId'] = podcastId;
          enhancedE['podcastId'] = podcastId;
        }
      }

      // Ensure each episode has proper podcast object structure
      if (enhancedE['podcast'] == null) {
        final podcastData = _constructPodcastDataFromEpisode(enhancedE);
        if (podcastData.isNotEmpty) {
          enhancedE['podcast'] = podcastData;
        }
      }

      return enhancedE;
    }).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: false,
      builder: (context) => Container(
        width: double.infinity,
        height: double.infinity,
        child: EpisodeDetailModal(
          episode: enhancedEpisode,
          episodes: enhancedEpisodes,
          episodeIndex: episodeIndex,
        ),
      ),
    );
  }

  /// Handle long press on podcast card to show episode details
  void _onPodcastLongPress(Podcast podcast) async {
    try {
      // Fetch episodes for this podcast
      final podcastId =
          podcast.id is int ? podcast.id as int : int.tryParse(podcast.id) ?? 0;
      final episodes = await _podcastRepository.getPodcastEpisodes(podcastId);

      if (episodes.isNotEmpty) {
        final episode = episodes.first;

        // Convert episodes to map format for the modal
        final episodeMaps = episodes.map((e) => e.toJson()).toList();
        final episodeIndex = 0; // First episode

        // Show episode detail modal
        _showEpisodeDetailModal(
            context, episode.toJson(), episodeMaps, episodeIndex);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No episodes available for this podcast.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading episodes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onCategoryTap(Category category) {
    _navigationService.navigateTo(AppRoutes.categoryPodcasts, arguments: {
      'id': category.id,
      'name': category.name,
      'icon': category.icon,
      'count': category.count,
      'gradientStart': category.gradientStart,
      'gradientEnd': category.gradientEnd,
    });
  }

  void _onViewAllFeatured() {
    _navigationService.navigateTo(AppRoutes.featuredPodcastsScreen, arguments: {
      'podcasts': featuredPodcasts,
    });
  }

  void _onViewAllCategories() {
    _navigationService.navigateTo(AppRoutes.categoriesListScreen, arguments: {
      'categories': categories,
    });
  }

  void _onSeeAllTrending() {
    _navigationService.navigateTo(AppRoutes.trendingPodcastsScreen, arguments: {
      'podcasts': trendingPodcasts,
    });
  }

  void _onSeeAllRecommendations() {
    _navigationService.navigateTo(AppRoutes.recommendationsScreen, arguments: {
      'podcasts': recommendedPodcasts,
    });
  }

  void _onSeeAllCrimeArchives() {
    _navigationService.navigateTo(AppRoutes.crimeArchivesScreen, arguments: {
      'podcasts': crimeArchivesPodcasts,
    });
  }

  void _onSeeAllPodcastForHealth() {
    _navigationService.navigateTo(AppRoutes.podcastForHealthScreen, arguments: {
      'podcasts': healthPodcasts,
    });
  }

  // Example integration for featured podcasts (repeat for other sections as needed):
  void _onFeaturedPodcastPlay(Podcast podcast,
      [Map<String, dynamic>? _]) async {
    // Fetch episodes for this podcast (from API or cache)
    final podcastId =
        podcast.id is int ? podcast.id as int : int.tryParse(podcast.id) ?? 0;
    final episodes = await _podcastRepository.getPodcastEpisodes(podcastId);
    if (episodes.isNotEmpty) {
      final episode = episodes.first; // Get the latest/first episode

      // Convert episodes to map format for the modal
      final episodeMaps = episodes.map((e) => e.toJson()).toList();
      final episodeIndex = 0; // First episode

      // Show episode detail modal instead of just playing
      _showEpisodeDetailModal(
          context, episode.toJson(), episodeMaps, episodeIndex);
    } else {
      // Show error: no episodes
      if (mounted) {
        SafeErrorHandler.showSafeSnackBar(
          context,
          'No episodes available for this podcast.',
          backgroundColor: Colors.orange,
        );
      }
    }
  }

  // Helper for trending podcasts
  void _onTrendingPodcastPlay(Podcast podcast,
      [Map<String, dynamic>? _]) async {
    final podcastId =
        podcast.id is int ? podcast.id as int : int.tryParse(podcast.id) ?? 0;
    final episodes = await _podcastRepository.getPodcastEpisodes(podcastId);
    if (episodes.isNotEmpty) {
      final episode = episodes.first;

      // Convert episodes to map format for the modal
      final episodeMaps = episodes.map((e) => e.toJson()).toList();
      final episodeIndex = 0; // First episode

      // Show episode detail modal instead of just playing
      _showEpisodeDetailModal(
          context, episode.toJson(), episodeMaps, episodeIndex);
    } else {
      if (mounted) {
        SafeErrorHandler.showSafeSnackBar(
          context,
          'No episodes available for this podcast.',
          backgroundColor: Colors.orange,
        );
      }
    }
  }

  // Helper for recommended podcasts
  void _onRecommendedPodcastPlay(Podcast podcast,
      [Map<String, dynamic>? _]) async {
    final podcastId =
        podcast.id is int ? podcast.id as int : int.tryParse(podcast.id) ?? 0;
    final episodes = await _podcastRepository.getPodcastEpisodes(podcastId);
    if (episodes.isNotEmpty) {
      final episode = episodes.first;

      // Convert episodes to map format for the modal
      final episodeMaps = episodes.map((e) => e.toJson()).toList();
      final episodeIndex = 0; // First episode

      // Show episode detail modal instead of just playing
      _showEpisodeDetailModal(
          context, episode.toJson(), episodeMaps, episodeIndex);
    } else {
      if (mounted) {
        SafeErrorHandler.showSafeSnackBar(
          context,
          'No episodes available for this podcast.',
          backgroundColor: Colors.orange,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);
    debugPrint(
        'Crime Archives in build:   [32m${crimeArchivesPodcasts.length} [0m');
    if (crimeArchivesPodcasts.isNotEmpty) {
      debugPrint(
          'First Crime Archives podcast:  ${crimeArchivesPodcasts.first.title}, image: ${crimeArchivesPodcasts.first.coverImage}');
    }
    // Show loading spinner only if podcasts are loading
    if (_isLoading) {
      return _buildLoadingView();
    }
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
          Expanded(
            child: _errorMessage.isNotEmpty
                ? _buildErrorView()
                : CustomScrollView(
                    controller: scrollController,
                    physics: SmoothScrollUtils.defaultPhysics,
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FeaturedPodcastsSectionWidget(
                              podcasts: featuredPodcasts,
                              onPodcastTap: _onPodcastTap,
                              onPlayEpisode: _onFeaturedPodcastPlay,
                              isLoading: _isLoading,
                            ),
                            const SizedBox(height: 24),
                            CategoriesSectionWidget(
                              categories: categories,
                              onCategoryTap: _onCategoryTap,
                              onViewAllTap: _onViewAllCategories,
                              isLoading: _isLoading,
                            ),
                            const SizedBox(height: 24),
                            PodcastCategorySectionWidget(
                              title: 'Trending Now',
                              podcasts: trendingPodcasts,
                              onPodcastTap: _onPodcastTap,
                              onSeeAll: _onSeeAllTrending,
                              isLoading: _isLoading,
                              onPlayEpisode: _onTrendingPodcastPlay,
                            ),
                            const SizedBox(height: 24),
                            // --- New Crime Archives Section ---
                            CrimeArchivesSectionWidget(
                              podcasts: crimeArchivesPodcasts,
                              onPodcastTap: _onPodcastTap,
                              isLoading: _isCrimeArchivesLoading,
                              onSeeAll: _onSeeAllCrimeArchives,
                              onSubscribe: (podcast) => _onSubscribe(podcast),
                            ),
                            const SizedBox(height: 24),
                            // --- New Podcast for Health Section ---
                            PodcastForHealthSectionWidget(
                              podcasts: healthPodcasts,
                              onPodcastTap: _onPodcastTap,
                              isLoading: _isHealthPodcastsLoading,
                              onSeeAll: _onSeeAllPodcastForHealth,
                            ),
                            const SizedBox(
                                height: 16), // Reduced from 80px to 16px
                            // Removed excessive bottom padding that was creating empty space
                            PodcastCategorySectionWidget(
                              title: 'Recommended for You',
                              podcasts: recommendedPodcasts,
                              onPodcastTap: _onPodcastTap,
                              onSeeAll: _onSeeAllRecommendations,
                              isLoading: _isLoading,
                              onPlayEpisode: _onRecommendedPodcastPlay,
                              onSubscribe: (podcast, _) =>
                                  _onSubscribe(podcast),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
          // Bottom Navigation with Mini Player
          Container(
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.lightTheme.colorScheme.shadow,
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: CommonBottomNavigationWidget(
              currentIndex: _selectedTabIndex,
              onTabSelected: _onTabSelected,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppTheme.lightTheme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading podcasts...',
            style: AppTheme.lightTheme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(5.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage.isNotEmpty
                  ? _errorMessage
                  : 'We encountered an error while loading content.',
              style: AppTheme.lightTheme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                safeSetState(() {
                  _errorMessage = '';
                  _isLoading = true;
                });
                _initializeData();
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedPodcasts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Featured Podcasts',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton(
                onPressed: _onViewAllFeatured,
                child: const Text('View All'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 320,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: featuredPodcasts.length,
            itemBuilder: (context, index) {
              final podcast = featuredPodcasts[index];
              return FeaturedPodcastCard(
                podcast: podcast,
                onTap: () => _onPodcastTap(podcast),
                onSubscribe: (p) => _onSubscribe(p),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Construct podcast data from episode data when podcast object is missing
  Map<String, dynamic> _constructPodcastDataFromEpisode(
      Map<String, dynamic> episodeData) {
    try {
      // Try to extract podcast information from episode-level fields
      final podcastId = episodeData['podcastId']?.toString() ??
          episodeData['feedId']?.toString() ??
          episodeData['podcast_id']?.toString();

      final podcastTitle = episodeData['podcastName']?.toString() ??
          episodeData['podcastTitle']?.toString() ??
          episodeData['feedTitle']?.toString();

      final podcastAuthor = episodeData['creator']?.toString() ??
          episodeData['author']?.toString();

      // Try to get podcast image from episode-level fields
      final podcastImage = episodeData['coverImage']?.toString() ??
          episodeData['image']?.toString() ??
          episodeData['feedImage']?.toString() ??
          episodeData['feed_image']?.toString() ??
          episodeData['artwork']?.toString() ??
          '';

      // Only construct if we have at least some basic information
      if (podcastId != null ||
          podcastTitle != null ||
          podcastImage.isNotEmpty) {
        return {
          'id': podcastId,
          'title': podcastTitle,
          'author': podcastAuthor,
          'creator': podcastAuthor,
          'coverImage': podcastImage,
          'cover_image': podcastImage,
          'image': podcastImage,
          'artwork': podcastImage,
        };
      }
    } catch (e) {
      debugPrint('Error constructing podcast data from episode: $e');
    }

    return {};
  }
}

class RefreshController {
  void refreshCompleted() {}
  void dispose() {}
}

// --- Crime Archives Section Widget ---
class CrimeArchivesSectionWidget extends StatelessWidget {
  final List<Podcast> podcasts;
  final Function(Podcast) onPodcastTap;
  final VoidCallback? onSeeAll;
  final void Function(Podcast)? onSubscribe;
  final bool isLoading;
  const CrimeArchivesSectionWidget({
    Key? key,
    required this.podcasts,
    required this.onPodcastTap,
    this.onSeeAll,
    this.onSubscribe,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);
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
              if (onSeeAll != null)
                GestureDetector(
                  onTap: onSeeAll,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View All',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
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
        isLoading && podcasts.isEmpty
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
                          children: List.generate(pageItems.length, (index) {
                            final podcast = pageItems[index];
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
                                      onTap: () => onPodcastTap(podcast),
                                      behavior: HitTestBehavior.opaque,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
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
                                                  onPodcastTap(podcast),
                                              behavior: HitTestBehavior.opaque,
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
                                                overflow: TextOverflow.ellipsis,
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
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
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
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // Subscribe Button (top right)
                                    if (onSubscribe != null)
                                      Positioned(
                                        top: 12,
                                        right: 12,
                                        child: GestureDetector(
                                          onTap: () => onSubscribe!(podcast),
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
                                                    onSubscribe!(podcast),
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
  }
}

// --- Podcast for Health Section Widget ---
class PodcastForHealthSectionWidget extends StatelessWidget {
  final List<Podcast> podcasts;
  final Function(Podcast) onPodcastTap;
  final VoidCallback? onSeeAll;
  final void Function(int index, bool subscribed)? onSubscribed;
  final bool isLoading;
  const PodcastForHealthSectionWidget({
    Key? key,
    required this.podcasts,
    required this.onPodcastTap,
    this.onSeeAll,
    this.onSubscribed,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);
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
              if (onSeeAll != null)
                GestureDetector(
                  onTap: onSeeAll,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View All',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
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
          child: isLoading && podcasts.isEmpty
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
                          children: List.generate(pageItems.length, (index) {
                            final podcast = pageItems[index];
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
                                      onTap: () => onPodcastTap(podcast),
                                      behavior: HitTestBehavior.opaque,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
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
                                                  onPodcastTap(podcast),
                                              behavior: HitTestBehavior.opaque,
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
                                                overflow: TextOverflow.ellipsis,
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
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
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
                                              overflow: TextOverflow.ellipsis,
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
                                        onTap: () async {
                                          final podcastId =
                                              podcast.id.toString();
                                          final isSubscribed =
                                              subscriptionProvider
                                                  .isSubscribed(podcastId);
                                          await handleSubscribeAction(
                                            context: context,
                                            podcastId: podcastId,
                                            isCurrentlySubscribed: isSubscribed,
                                            onStateChanged: (subscribed) {
                                              if (subscribed) {
                                                subscriptionProvider
                                                    .addSubscription(podcastId);
                                              } else {
                                                subscriptionProvider
                                                    .removeSubscription(
                                                        podcastId);
                                              }
                                            },
                                          );
                                        },
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
                                              onPressed: () async {
                                                final podcastId =
                                                    podcast.id.toString();
                                                final isSubscribed =
                                                    subscriptionProvider
                                                        .isSubscribed(
                                                            podcastId);
                                                await handleSubscribeAction(
                                                  context: context,
                                                  podcastId: podcastId,
                                                  isCurrentlySubscribed:
                                                      isSubscribed,
                                                  onStateChanged: (subscribed) {
                                                    if (subscribed) {
                                                      subscriptionProvider
                                                          .addSubscription(
                                                              podcastId);
                                                    } else {
                                                      subscriptionProvider
                                                          .removeSubscription(
                                                              podcastId);
                                                    }
                                                  },
                                                );
                                              },
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
  }
}

// --- Beautiful Featured Podcast Card Widget ---
class FeaturedPodcastCard extends StatelessWidget {
  final Podcast podcast;
  final VoidCallback? onTap;
  final void Function(Podcast)? onSubscribe;
  const FeaturedPodcastCard({
    Key? key,
    required this.podcast,
    this.onTap,
    this.onSubscribe,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        height: 300,
        margin: const EdgeInsets.only(right: 18.0, bottom: 4.0, top: 4.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  child: CustomImageWidget(
                    imageUrl: podcast.coverImage,
                    height: 140,
                    width: 220,
                    fit: BoxFit.cover,
                  ),
                ),
                // Gradient overlay at the bottom
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 60,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.vertical(bottom: Radius.circular(20)),
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
                // Title and creator on the gradient
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        podcast.title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.7),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        podcast.creator,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.7),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Description and subscribe button below image
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    podcast.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.black87,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Material(
                        color: podcast.isSubscribed
                            ? Colors.green[50]
                            : Colors.deepPurple[50],
                        borderRadius: BorderRadius.circular(30),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(30),
                          onTap: () => onSubscribe?.call(podcast),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            child: Row(
                              children: [
                                Icon(
                                  podcast.isSubscribed
                                      ? Icons.check_circle
                                      : Icons.add_circle_outline,
                                  color: podcast.isSubscribed
                                      ? Colors.green
                                      : Colors.deepPurple,
                                  size: 22,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  podcast.isSubscribed
                                      ? 'Subscribed'
                                      : 'Subscribe',
                                  style: TextStyle(
                                    color: podcast.isSubscribed
                                        ? Colors.green[900]
                                        : Colors.deepPurple[900],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TrendingNowPodcastCard extends StatefulWidget {
  final Podcast podcast;
  final ValueChanged<bool> onSubscribed;
  const TrendingNowPodcastCard(
      {Key? key, required this.podcast, required this.onSubscribed})
      : super(key: key);

  @override
  State<TrendingNowPodcastCard> createState() => _TrendingNowPodcastCardState();
}

class _TrendingNowPodcastCardState extends State<TrendingNowPodcastCard> {
  bool _isLoading = false;
  late bool _isSubscribed;

  @override
  void initState() {
    super.initState();
    _isSubscribed = widget.podcast.isSubscribed;
  }

  Future<void> _handleSubscribe() async {
    setState(() => _isLoading = true);
    await handleSubscribeAction(
      context: context,
      podcastId: widget.podcast.id.toString(),
      isCurrentlySubscribed: _isSubscribed,
      onStateChanged: (bool subscribed) {
        setState(() {
          _isSubscribed = subscribed;
          _isLoading = false;
        });
        widget.onSubscribed(subscribed);
      },
    );
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final podcast = widget.podcast;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8),
      height: 200,
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                child: CustomImageWidget(
                  imageUrl: podcast.coverImage,
                  width: double.infinity,
                  height: 110,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 27,
                  height: 27,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.10),
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Center(
                    child: SubscribeButton(
                      isSubscribed: _isSubscribed,
                      isLoading: _isLoading,
                      onPressed: _handleSubscribe,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  podcast.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  podcast.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
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
