import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:provider/provider.dart';

import '../../core/app_export.dart';
import '../../data/repositories/podcast_repository.dart';
import '../../data/models/podcast.dart';
import '../../data/models/episode.dart' as data_models;
import '../../core/services/storage_service.dart';
import '../../widgets/add_to_playlist_widget.dart';
import './widgets/earning_progress_widget.dart';
import './widgets/episode_info_widget.dart';
import './widgets/player_controls_widget.dart';
import './widgets/player_description_tab_widget.dart';
import './widgets/player_episodes_tab_widget.dart';
import './widgets/player_playlist_episodes_tab_widget.dart';
import './widgets/progress_slider_widget.dart';
import './widgets/speed_control_widget.dart';
import '../../services/library_api_service.dart';
import '../../services/subscription_helper.dart';
import '../../services/social_sharing_service.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/history_provider.dart';
import '../../providers/podcast_player_provider.dart';
import '../../services/history_service.dart';
import '../../services/hybrid_audio_player_service.dart';
import '../../services/player_settings_service.dart';
import '../../models/buffering_models.dart';
import '../widgets/player_settings_widget.dart';
import '../../services/download_manager.dart';
import '../../core/utils/episode_utils.dart';
import '../../core/routes/app_routes.dart';

import 'package:dio/dio.dart';
import 'package:provider/provider.dart';

// lib/presentation/podcast_player/podcast_player.dart

class PodcastPlayer extends StatefulWidget {
  const PodcastPlayer({super.key});

  @override
  State<PodcastPlayer> createState() => _PodcastPlayerState();
}

class _PodcastPlayerState extends State<PodcastPlayer>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late TabController _tabController;
  final NavigationService _navigationService = NavigationService();
  final HybridAudioPlayerService _audioPlayerService =
      HybridAudioPlayerService();
  final PlayerSettingsService _settingsService = PlayerSettingsService();
  final PodcastRepository _podcastRepository = PodcastRepository();
  final DownloadManager _downloadManager = DownloadManager();

  bool isPlaying = false;
  bool isLoading = false;
  bool isLoadingPodcast = false;
  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;
  double playbackSpeed = 1.0;
  bool isEarningEpisode = true;
  bool isEarningEnabled = false;
  double coinsEarned = 12.5;
  double coinsPerMinute = 2.5;
  bool isSubscribed = false;
  bool notificationsEnabled = true;
  bool isInWatchLater = false;
  bool isInPlaylist = false;
  bool isPlaylistMode = false;
  String? sourceRoute;
  Map<String, dynamic>? _episodePlaylistInfo;

  // Playlist-specific variables
  Map<String, dynamic>? currentPlaylist;
  int currentPlaylistIndex = 0;
  int totalPlaylistEpisodes = 0;

  // Dynamic podcast and episode data
  Map<String, dynamic>? currentPodcast;
  Map<String, dynamic>? currentEpisode;
  List<Map<String, dynamic>> podcastEpisodes = [];
  String? errorMessage;
  StreamSubscription<void>? _episodeCompleteSub;
  StreamSubscription<void>? _currentEpisodeSub;
  StreamSubscription<void>? _positionStreamSub;
  StreamSubscription<void>? _durationStreamSub;

  // Add this function to check if the current episode is in any playlist
  Future<void> _checkIfEpisodeInPlaylist() async {
    if (currentEpisode == null || currentEpisode?['id'] == null) {
      setState(() {
        isInPlaylist = false;
      });
      return;
    }
    try {
      final apiService = LibraryApiService();
      final result = await apiService
          .checkEpisodeInPlaylists(currentEpisode!['id'].toString());
      setState(() {
        isInPlaylist = result['is_in_playlists'] == true;
      });
    } catch (e) {
      setState(() {
        isInPlaylist = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(duration: const Duration(seconds: 2), vsync: this);
    _tabController = TabController(length: 2, vsync: this);

    // Initialize audio player service
    _initializeAudioPlayer();
    _initializeDownloadManager();

    // Parse navigation arguments to get source route and podcast data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _parseNavigationArguments();
      _checkIfEpisodeInPlaylist();
      // If no episode is passed, set currentEpisode from audio player service
      if (currentEpisode == null &&
          _audioPlayerService.currentEpisode != null) {
        setState(() {
          currentEpisode =
              Map<String, dynamic>.from(_audioPlayerService.currentEpisode!);
        });
      }
    });

    // Track this route
    _navigationService.trackNavigation(AppRoutes.podcastPlayer);
    _startRotationAnimation();

    // Listen to current episode changes from audio player service
    _currentEpisodeSub =
        _audioPlayerService.currentEpisodeStream.listen((episode) {
      if (episode != null && mounted) {
        setState(() {
          currentEpisode = Map<String, dynamic>.from(episode);
          // Optionally, update UI to highlight the current episode in the list
          if (podcastEpisodes.isNotEmpty && currentEpisode != null) {
            for (var ep in podcastEpisodes) {
              ep['isCurrentEpisode'] =
                  ep['id'].toString() == currentEpisode!['id'].toString();
            }
          }
        });
      }
    });

    // Listen to position and duration for history tracking
    _positionStreamSub = _audioPlayerService.positionStream.listen((position) {
      if (mounted && currentEpisode != null) {
        setState(() {
          currentPosition = position;
        });
        // Update play history with current progress
        _updatePlayHistoryProgress(position.inSeconds);
      }
    });

    _durationStreamSub = _audioPlayerService.durationStream.listen((duration) {
      if (mounted) {
        setState(() {
          totalDuration = duration;
        });
      }
    });
  }

  /// Initialize audio player and listen to state changes
  Future<void> _initializeAudioPlayer() async {
    try {
      // Initialize settings and hybrid service
      await _settingsService.initialize();
      await _audioPlayerService.initialize(playerProvider: null);

      // Switch to enhanced implementation if enabled
      if (_settingsService.useEnhancedPlayer) {
        await _audioPlayerService.switchImplementation(true);
      }

      // Listen to playing state changes
      _audioPlayerService.playingStateStream.listen((playing) {
        if (mounted) {
          setState(() {
            isPlaying = playing;
          });
          _startRotationAnimation();
        }
      });

      // Listen to loading state changes
      _audioPlayerService.loadingStateStream.listen((loading) {
        if (mounted) {
          setState(() {
            isLoading = loading;
          });
        }
      });

      // Listen to buffering state changes (enhanced feature)
      _audioPlayerService.bufferingStateStream.listen((bufferingState) {
        if (mounted) {
          setState(() {
            // Update loading state based on buffering state
            isLoading = bufferingState == BufferingState.loading ||
                bufferingState == BufferingState.buffering;
          });
        }
      });

      // Listen to position changes
      _audioPlayerService.positionStream.listen((position) {
        if (mounted) {
          setState(() {
            currentPosition = position;
          });
        }
      });

      // Listen to duration changes
      _audioPlayerService.durationStream.listen((duration) {
        if (mounted) {
          setState(() {
            totalDuration = duration;
          });
        }
      });

      // Listen to speed changes
      _audioPlayerService.speedStream.listen((speed) {
        if (mounted) {
          setState(() {
            playbackSpeed = speed;
          });
        }
      });

      // --- Auto-play next episode using centralized PodcastPlayerProvider ---
      _episodeCompleteSub = _audioPlayerService.onEpisodeComplete.listen((_) {
        // Track play history - episode completed
        if (currentEpisode != null) {
          _trackPlayHistoryEvent('completed');
        }

        // Use the centralized PodcastPlayerProvider for auto-play
        if (mounted) {
          final playerProvider =
              Provider.of<PodcastPlayerProvider>(context, listen: false);

          // Check if auto-play is enabled
          if (playerProvider.autoPlayNext) {
            debugPrint(
                'PodcastPlayer: Auto-play enabled, using centralized provider');

            // The PodcastPlayerProvider will handle auto-play automatically
            // We just need to ensure the episode queue is set correctly
            _ensureEpisodeQueueIsSet(playerProvider);
          } else {
            debugPrint('PodcastPlayer: Auto-play disabled');
            // Show end of playlist message
            if (currentEpisode != null && podcastEpisodes.isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Episode completed'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        }
      });
    } catch (e) {
      debugPrint('Error initializing audio player: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing audio player: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Ensure the episode queue is set in the PodcastPlayerProvider
  void _ensureEpisodeQueueIsSet(PodcastPlayerProvider playerProvider) {
    try {
      if (podcastEpisodes.isNotEmpty) {
        // Convert episode maps to Episode models
        final episodeModels = podcastEpisodes.map((episode) {
          return data_models.Episode.fromJson(episode);
        }).toList();

        // Find current episode index
        int currentIndex = 0;
        if (currentEpisode != null) {
          currentIndex = podcastEpisodes.indexWhere(
            (e) => e['id'].toString() == currentEpisode!['id'].toString(),
          );
          if (currentIndex == -1) currentIndex = 0;
        }

        // Set the episode queue in the provider
        playerProvider.setEpisodeQueue(episodeModels,
            startIndex: currentIndex,
            podcastId: currentPodcast?['id']?.toString());

        debugPrint(
            'PodcastPlayer: Episode queue set in provider with ${episodeModels.length} episodes');
        debugPrint('PodcastPlayer: Current episode index: $currentIndex');
      }
    } catch (e) {
      debugPrint('Error setting episode queue in provider: $e');
    }
  }

  Future<void> _initializeDownloadManager() async {
    await _downloadManager.initialize();
  }

  /// Parse navigation arguments and load podcast data
  void _parseNavigationArguments() async {
    try {
      // Clear previous state before loading new podcast detail
      setState(() {
        currentPodcast = null;
        currentEpisode = null;
        podcastEpisodes = [];
        errorMessage = null;
      });
      final arguments = ModalRoute.of(context)?.settings.arguments;
      debugPrint('PodcastPlayer: Received arguments: $arguments');

      if (arguments is Map<String, dynamic>) {
        // Extract source route and earning status from arguments
        sourceRoute = arguments['sourceRoute'] as String?;
        final explicitEarningEnabled = arguments['isEarningEnabled'] as bool?;

        debugPrint('PodcastPlayer: Source route: $sourceRoute');
        debugPrint(
            'PodcastPlayer: Explicit earning enabled: $explicitEarningEnabled');

        // Use explicit earning enabled flag if provided, otherwise validate source
        if (explicitEarningEnabled != null) {
          isEarningEnabled = explicitEarningEnabled;
        } else {
          isEarningEnabled = _navigationService.isEarningEnabled(sourceRoute);
        }

        debugPrint('PodcastPlayer: Final earning enabled: $isEarningEnabled');

        // Handle playlist mode
        final isPlaylistModeArg = arguments['isPlaylistMode'] as bool? ?? false;
        final playlistData = arguments['playlist'] as Map<String, dynamic>?;

        if (isPlaylistModeArg && playlistData != null) {
          debugPrint('PodcastPlayer: Entering playlist mode');
          debugPrint('PodcastPlayer: Playlist data: $playlistData');

          setState(() {
            isPlaylistMode = true;
            currentPlaylist = playlistData;
            currentPlaylistIndex = playlistData['currentEpisodeIndex'] ?? 0;
            totalPlaylistEpisodes = playlistData['totalEpisodes'] ?? 0;
            // Set currentPodcast for playlist mode to prevent "No Podcast Selected" error
            currentPodcast = arguments['podcast'] as Map<String, dynamic>?;
          });

          // Load playlist episodes
          final playlistEpisodes =
              playlistData['episodes'] as List<dynamic>? ?? [];
          podcastEpisodes = playlistEpisodes.cast<Map<String, dynamic>>();

          debugPrint('PodcastPlayer: Raw playlist episodes: $playlistEpisodes');
          debugPrint(
              'PodcastPlayer: Cast episodes length: ${podcastEpisodes.length}');

          // Set current episode from playlist
          final currentEpisodeArg =
              arguments['episode'] as Map<String, dynamic>?;
          if (currentEpisodeArg != null) {
            currentEpisode = Map<String, dynamic>.from(currentEpisodeArg);
            currentEpisode!['isCurrentEpisode'] = true;

            debugPrint('PodcastPlayer: Current episode set: $currentEpisode');

            // Mark current episode in playlist
            for (int i = 0; i < podcastEpisodes.length; i++) {
              podcastEpisodes[i]['isCurrentEpisode'] =
                  i == currentPlaylistIndex;
            }
          }

          debugPrint(
              'PodcastPlayer: Loaded ${podcastEpisodes.length} playlist episodes');
          debugPrint(
              'PodcastPlayer: Current episode: ${currentEpisode?['title']}');

          // Start playing the current episode
          if (currentEpisode != null) {
            final shouldPlay = _audioPlayerService.currentEpisode == null ||
                _audioPlayerService.currentEpisode!['id'].toString() !=
                    currentEpisode!['id'].toString();

            if (shouldPlay) {
              debugPrint('PodcastPlayer: Starting playlist episode playback');
              await _audioPlayerService.loadAndPlayEpisode(currentEpisode!);
            }
          }

          return; // Exit early for playlist mode
        }

        // Handle offline episode from downloads
        final isOffline = arguments['isOffline'] as bool? ?? false;
        final offlineEpisode = arguments['episode'] as Map<String, dynamic>?;

        if (isOffline && offlineEpisode != null) {
          debugPrint('PodcastPlayer: Loading offline episode: $offlineEpisode');

          // Set up offline episode data
          setState(() {
            currentEpisode = Map<String, dynamic>.from(offlineEpisode);
            currentEpisode!['isCurrentEpisode'] = true;
            currentEpisode!['isDownloaded'] = true;
            currentEpisode!['isOffline'] = true;

            // Create minimal podcast data for offline episodes
            currentPodcast =
                offlineEpisode['podcast'] as Map<String, dynamic>? ??
                    {
                      'id': 'offline',
                      'title': 'Offline Episodes',
                      'author': 'Downloaded Content',
                      'image': '',
                    };

            // Create single episode list for offline mode
            podcastEpisodes = [currentEpisode!];
          });

          debugPrint(
              'PodcastPlayer: Setting up offline episode for playback: ${currentEpisode!['title']}');

          // Start playing the offline episode
          final shouldPlay = _audioPlayerService.currentEpisode == null ||
              _audioPlayerService.currentEpisode!['id'].toString() !=
                  currentEpisode!['id'].toString();

          if (shouldPlay) {
            debugPrint('PodcastPlayer: Starting offline episode playback');
            await _audioPlayerService.loadAndPlayEpisode(currentEpisode!);
          }

          return; // Exit early for offline mode
        }

        // Handle podcast data (existing logic)
        final podcastData = arguments['podcast'];
        final episodesData = arguments['episodes'];
        final currentEpisodeArg = arguments['currentEpisode'];
        if (podcastData != null &&
            episodesData != null &&
            currentEpisodeArg != null) {
          debugPrint('PodcastPlayer: Loading podcast data: $podcastData');
          // Set current podcast and episodes
          currentPodcast = podcastData;
          podcastEpisodes = List<Map<String, dynamic>>.from(episodesData);
          _sortPodcastEpisodes();
          // Find the episode in the list that matches currentEpisodeArg by id or audioUrl
          Map<String, dynamic>? matchedEpisode;
          try {
            matchedEpisode = podcastEpisodes.firstWhere(
              (e) =>
                  e['id'].toString() == currentEpisodeArg['id'].toString() ||
                  (e['audioUrl'] != null &&
                      e['audioUrl'] == currentEpisodeArg['audioUrl']),
            );
          } catch (_) {
            matchedEpisode = currentEpisodeArg;
          }
          setState(() {
            currentEpisode = Map<String, dynamic>.from(matchedEpisode!);
            currentEpisode!['isCurrentEpisode'] = true;
            // Ensure feedId is always attached
            if (currentPodcast != null && currentPodcast!['id'] != null) {
              currentEpisode!['feedId'] = currentPodcast!['id'];
            }
          });

          debugPrint(
              'PodcastPlayer: Setting up episode for playback: ${currentEpisode!['title']}');

          // Always load and play the episode when coming from podcast detail screen
          // or if not already playing this episode
          final shouldPlay = _audioPlayerService.currentEpisode == null ||
              _audioPlayerService.currentEpisode!['id'].toString() !=
                  currentEpisode!['id'].toString();

          debugPrint('PodcastPlayer: Should start playing: $shouldPlay');

          if (shouldPlay) {
            debugPrint('PodcastPlayer: Starting episode playback');
            // Set podcast data in the provider for proper image display
            final playerProvider =
                Provider.of<PodcastPlayerProvider>(context, listen: false);
            playerProvider.setCurrentPodcastData(podcastData);
            await _audioPlayerService.loadAndPlayEpisode(currentEpisode!);
          } else {
            debugPrint('PodcastPlayer: Episode already playing, skipping load');
          }
        } else if (podcastData != null) {
          // Fallback: load podcast data as before
          await _loadPodcastData(podcastData);
        } else {
          debugPrint('PodcastPlayer: No podcast data provided');
        }
      } else {
        // Fallback for direct podcast arguments (legacy support)
        debugPrint('PodcastPlayer: Using fallback navigation arguments');
        sourceRoute = _navigationService.getCurrentSourceRoute();
        isEarningEnabled = _navigationService.validateEarningContext();

        // If arguments is not null but not a Map, it might be direct podcast data
        if (arguments != null) {
          debugPrint(
              'PodcastPlayer: Treating arguments as direct podcast data');
          await _loadPodcastData(arguments as Map<String, dynamic>);
        }
      }

      // Update earning episode status based on validation
      if (!mounted) return;
      setState(() {
        if (!isEarningEnabled) {
          isEarningEpisode = false;
          coinsEarned = 0.0;
        } else {
          // Only enable earning for episodes that support it
          isEarningEpisode = currentEpisode?['isEarningEpisode'] ?? false;
        }
      });

      // Debug logging (remove in production)
      print(
          'Earning validation - Source: $sourceRoute, Enabled: $isEarningEnabled, Episode supports earning: ${currentEpisode?['isEarningEpisode']}');
    } catch (e) {
      // Handle parsing errors gracefully
      print('Error parsing navigation arguments: $e');
      sourceRoute = null;
      isEarningEnabled = false;
      if (!mounted) return;
      setState(() {
        isEarningEpisode = false;
        coinsEarned = 0.0;
        errorMessage = 'Error loading podcast data: $e';
      });
    }
  }

  /// Load podcast data and episodes from API
  Future<void> _loadPodcastData(Map<String, dynamic> podcastData) async {
    try {
      if (!mounted) return;
      setState(() {
        isLoadingPodcast = true;
        errorMessage = null;
      });

      debugPrint('PodcastPlayer: Received podcast data: $podcastData');
      debugPrint('PodcastPlayer: podcastData keys: ${podcastData.keys}');

      // Handle different data formats
      Map<String, dynamic>? actualPodcastData;
      List<Map<String, dynamic>>? actualEpisodesData;
      Map<String, dynamic>? currentEpisodeFromArgs;

      // Check if this is the format from mini player (podcast, episodes, currentEpisode)
      if (podcastData.containsKey('podcast') &&
          podcastData.containsKey('episodes')) {
        debugPrint('PodcastPlayer: Detected mini player format');
        actualPodcastData = podcastData['podcast'] as Map<String, dynamic>?;
        actualEpisodesData =
            (podcastData['episodes'] as List?)?.cast<Map<String, dynamic>>();
        currentEpisodeFromArgs =
            podcastData['currentEpisode'] as Map<String, dynamic>?;
      } else {
        // This is the direct podcast data format
        debugPrint('PodcastPlayer: Detected direct podcast format');
        actualPodcastData = podcastData;
        currentEpisodeFromArgs =
            podcastData['currentEpisode'] as Map<String, dynamic>?;
      }

      // Set current podcast data
      currentPodcast = Map<String, dynamic>.from(actualPodcastData ?? {});
      if (!currentPodcast!.containsKey('author') ||
          (currentPodcast!['author'] == null ||
              currentPodcast!['author'].toString().isEmpty)) {
        currentPodcast!['author'] = currentPodcast!['creator'] ?? 'Unknown';
      }
      debugPrint('=== PLAYER INITIAL DATA ===');
      debugPrint('Player initial currentPodcast: $currentPodcast');
      debugPrint('Player initial currentPodcast keys: ${currentPodcast!.keys}');
      debugPrint(
          'Player initial episodeCount: ${currentPodcast!['episodeCount']}');
      debugPrint(
          'Player initial totalDuration: ${currentPodcast!['totalDuration']}');
      debugPrint('PodcastPlayer: Actual podcast data: $actualPodcastData');
      debugPrint(
          'PodcastPlayer: Actual podcast data keys: ${actualPodcastData?.keys}');

      // Check if we have a current episode from mini player
      if (currentEpisodeFromArgs != null) {
        debugPrint(
            'PodcastPlayer: Preserving current episode from mini player: ${currentEpisodeFromArgs['title']}');
        debugPrint(
            'PodcastPlayer: Current episode data: $currentEpisodeFromArgs');
        currentEpisode = Map<String, dynamic>.from(currentEpisodeFromArgs);
        currentEpisode!['isCurrentEpisode'] = true;
        debugPrint('PodcastPlayer: Set current episode: $currentEpisode');
      }

      // If we already have episodes data from mini player, use it
      if (actualEpisodesData != null && actualEpisodesData.isNotEmpty) {
        debugPrint('PodcastPlayer: Using episodes data from mini player');
        podcastEpisodes = actualEpisodesData;
        _sortPodcastEpisodes();

        // Find and mark the current episode
        if (currentEpisode != null && currentEpisodeFromArgs != null) {
          final currentEpisodeId = currentEpisodeFromArgs['id']?.toString();
          if (currentEpisodeId != null) {
            final episodeIndex = podcastEpisodes.indexWhere(
                (episode) => episode['id'].toString() == currentEpisodeId);
            if (episodeIndex != -1) {
              podcastEpisodes[episodeIndex]['isCurrentEpisode'] = true;
              // Update current episode with full episode data
              currentEpisode =
                  Map<String, dynamic>.from(podcastEpisodes[episodeIndex]);
              currentEpisode!['isCurrentEpisode'] = true;
              // Ensure feedId is always attached
              if (currentPodcast != null && currentPodcast!['id'] != null) {
                currentEpisode!['feedId'] = currentPodcast!['id'];
              }
            }
          }
        }

        // Start playing the current episode if needed
        if (currentEpisode != null && currentEpisodeFromArgs != null) {
          debugPrint(
              'PodcastPlayer: Starting playback for episode from mini player: ${currentEpisode!['title']}');

          // Check if we should start playing (not already playing this episode)
          final shouldPlay = _audioPlayerService.currentEpisode == null ||
              _audioPlayerService.currentEpisode!['id'].toString() !=
                  currentEpisode!['id'].toString();

          if (shouldPlay) {
            debugPrint(
                'PodcastPlayer: Starting episode playback from mini player data');
            await _audioPlayerService.loadAndPlayEpisode(currentEpisode!);
          } else {
            debugPrint(
                'PodcastPlayer: Episode already playing, skipping load from mini player data');
          }
        }

        setState(() {
          isLoadingPodcast = false;
        });
        return; // Exit early since we have all the data we need
      }

      // Get user token for API calls
      final token = await _getUserToken();

      // Fetch podcast details and episodes from API
      final feedId = actualPodcastData?['id']?.toString();
      debugPrint('=== PLAYER API CALL SECTION ===');
      debugPrint('Player feedId: $feedId');
      debugPrint('Player feedId is null: ${feedId == null}');
      debugPrint('Player feedId is empty: ${feedId?.isEmpty}');
      debugPrint('PodcastPlayer: Using feedId: $feedId');
      debugPrint('PodcastPlayer: Full podcast data: $actualPodcastData');
      if (feedId != null && feedId.isNotEmpty) {
        debugPrint('=== PLAYER MAKING API CALL ===');
        debugPrint('Loading podcast details for feedId: $feedId');

        debugPrint('=== PLAYER API CALL START ===');
        debugPrint('Player calling API with feedId: $feedId');
        final result = await _podcastRepository.getPodcastDetailsWithEpisodes(
          feedId,
        );
        debugPrint('=== PLAYER API CALL COMPLETED ===');
        debugPrint('Player API result keys: ${result.keys}');
        debugPrint(
            'Player API result contains podcast: ${result.containsKey('podcast')}');
        debugPrint(
            'Player API result contains episodes: ${result.containsKey('episodes')}');

        if (result.containsKey('podcast') && result.containsKey('episodes')) {
          final podcast = result['podcast'] as Podcast?;
          final episodes = result['episodes'] as List<data_models.Episode>?;

          if (podcast != null && episodes != null) {
            // Debug the podcast data from API
            debugPrint('=== PLAYER PODCAST FROM API ===');
            debugPrint('Podcast title: ${podcast.title}');
            debugPrint('Podcast episodeCount: ${podcast.episodeCount}');
            debugPrint('Podcast totalEpisodes: ${podcast.totalEpisodes}');
            debugPrint('Episodes length: ${episodes.length}');

            // Update current podcast with API data
            currentPodcast = {
              'id': podcast.id,
              'title': podcast.title,
              'author': podcast.author.isNotEmpty
                  ? podcast.author
                  : podcast.creator, // Expose author, fallback to creator
              'creator': podcast.creator,
              'description': podcast.description ?? 'No description available',
              'coverImage': podcast.coverImage,
              'category': podcast.category ?? 'General',
              'categories': podcast.categories, // Add categories field
              'episodeCount': podcast.episodeCount, // Add episodeCount field
              'tags': [], // Default empty tags since not in model
              'updateFrequency': 'Weekly', // Default value
              'totalDuration': _calculateTotalDuration(episodes),
              'subscribers': '0', // Default value
              'rating': 4.5, // Default value
            };

            // Debug: Print the updated podcast data
            debugPrint('=== PLAYER PODCAST DATA UPDATED ===');
            debugPrint(
                'Player currentPodcast episodeCount: ${currentPodcast!['episodeCount']}');
            debugPrint(
                'Player currentPodcast totalDuration: ${currentPodcast!['totalDuration']}');
            debugPrint('Player episodes length: ${episodes.length}');

            // Convert episodes to map format for UI
            podcastEpisodes = episodes
                .map((episode) => {
                      'id': episode.id,
                      'title': episode.title,
                      'description': episode.description,
                      'coverImage': currentPodcast!['coverImage'].isNotEmpty
                          ? currentPodcast!['coverImage']
                          : episode.coverImage.isNotEmpty
                              ? episode.coverImage
                              : '',
                      'duration': episode.duration,
                      'publishDate':
                          episode.releaseDate.toIso8601String().split('T')[0],
                      'isEarningEpisode':
                          true, // Default to true since not in model
                      'coinsPerMinute': 2.5, // Default value since not in model
                      'isDownloaded': episode.isDownloaded,
                      'isPlayed': false, // Default value since not in model
                      'progress': 0.0, // Default value since not in model
                      'isCurrentEpisode': false,
                      'audioUrl': episode.audioUrl,
                    })
                .toList();
            _sortPodcastEpisodes();

            // If we have a current episode from mini player, find and mark it as current
            if (currentEpisode != null && currentEpisodeFromArgs != null) {
              final currentEpisodeId = currentEpisodeFromArgs['id']?.toString();
              if (currentEpisodeId != null) {
                final episodeIndex = podcastEpisodes.indexWhere(
                    (episode) => episode['id'].toString() == currentEpisodeId);
                if (episodeIndex != -1) {
                  podcastEpisodes[episodeIndex]['isCurrentEpisode'] = true;
                  // Update current episode with full episode data from API
                  currentEpisode =
                      Map<String, dynamic>.from(podcastEpisodes[episodeIndex]);
                  currentEpisode!['isCurrentEpisode'] = true;
                  // Ensure feedId is always attached
                  if (currentPodcast != null && currentPodcast!['id'] != null) {
                    currentEpisode!['feedId'] = currentPodcast!['id'];
                  }
                }
              }
            } else if (currentEpisode == null && podcastEpisodes.isNotEmpty) {
              // Only set first episode as current if no episode is selected
              currentEpisode = Map<String, dynamic>.from(podcastEpisodes.first);
              currentEpisode!['isCurrentEpisode'] = true;
              // Ensure feedId is always attached
              if (currentPodcast != null && currentPodcast!['id'] != null) {
                currentEpisode!['feedId'] = currentPodcast!['id'];
              }
            }

            debugPrint(
                'Successfully loaded ${podcastEpisodes.length} episodes');

            // If we have a current episode from arguments, start playing it immediately
            if (currentEpisode != null && currentEpisodeFromArgs != null) {
              debugPrint(
                  'PodcastPlayer: Starting playback for episode from arguments: ${currentEpisode!['title']}');

              // Check if we should start playing (not already playing this episode)
              final shouldPlay = _audioPlayerService.currentEpisode == null ||
                  _audioPlayerService.currentEpisode!['id'].toString() !=
                      currentEpisode!['id'].toString();

              if (shouldPlay) {
                debugPrint(
                    'PodcastPlayer: Starting episode playback from _loadPodcastData');
                await _audioPlayerService.loadAndPlayEpisode(currentEpisode!);
              } else {
                debugPrint(
                    'PodcastPlayer: Episode already playing, skipping load from _loadPodcastData');
              }
            }
          } else {
            throw Exception('Invalid podcast data received from API');
          }
        } else {
          throw Exception('Missing podcast or episodes data from API');
        }
      } else {
        debugPrint('=== PLAYER SKIPPING API CALL ===');
        debugPrint(
            'PodcastPlayer: Invalid podcast ID - feedId is null or empty');
        debugPrint('PodcastPlayer: podcastData keys: ${podcastData.keys}');
        debugPrint('PodcastPlayer: actualPodcastData: $actualPodcastData');
        debugPrint(
            'PodcastPlayer: actualPodcastData id: ${actualPodcastData?['id']}');
        debugPrint('PodcastPlayer: Using initial data without API call');
        debugPrint(
            'PodcastPlayer: Initial episodeCount: ${currentPodcast?['episodeCount']}');
        debugPrint(
            'PodcastPlayer: Initial totalDuration: ${currentPodcast?['totalDuration']}');
        // Don't throw exception, just use the initial data
        return;
      }
    } catch (e) {
      debugPrint('Error loading podcast data: $e');
      setState(() {
        errorMessage = 'Failed to load podcast data. Please try again.';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading podcast: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        isLoadingPodcast = false;
      });
    }
  }

  /// Get user authentication token
  Future<String?> _getUserToken() async {
    try {
      final storageService = StorageService();
      return await storageService.getToken();
    } catch (e) {
      debugPrint('Error getting user token: $e');
      return null;
    }
  }

  /// Calculate total duration from episodes
  String _calculateTotalDuration(List<data_models.Episode> episodes) {
    debugPrint('=== CALCULATING TOTAL DURATION ===');
    debugPrint('Number of episodes: ${episodes.length}');

    int totalSeconds = 0;
    for (int i = 0; i < episodes.length; i++) {
      final episode = episodes[i];
      final durationStr = episode.duration;
      debugPrint('Episode ${i + 1} duration: $durationStr');

      try {
        final seconds =
            DurationUtils.parseDurationToSeconds(durationStr).toInt();
        totalSeconds += seconds;
        debugPrint('Episode ${i + 1} parsed seconds: $seconds');
      } catch (e) {
        debugPrint('Error parsing duration for episode ${i + 1}: $e');
      }
    }

    debugPrint('Total seconds: $totalSeconds');
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final result = hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
    debugPrint('Final duration: $result');

    return result;
  }

  void _startRotationAnimation() {
    if (isPlaying) {
      _animationController.repeat();
    } else {
      _animationController.stop();
    }
  }

  void _togglePlayPause() async {
    try {
      if (currentEpisode == null) {
        if (podcastEpisodes.isNotEmpty) {
          // Load first episode if none is selected
          _playEpisode(podcastEpisodes.first);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No episodes available to play'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      if (isPlaying) {
        await _audioPlayerService.pause();
        // Track play history - episode paused
        _trackPlayHistoryEvent('paused');
      } else {
        // If no episode is loaded, load the current episode first
        if (_audioPlayerService.currentEpisode == null) {
          await _audioPlayerService.loadAndPlayEpisode(currentEpisode!);
        } else {
          await _audioPlayerService.play();
        }
        // Track play history - episode resumed
        _trackPlayHistoryEvent('played');
      }
    } catch (e) {
      debugPrint('Error toggling play/pause: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error playing audio: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onSeek(double value) async {
    final Duration newPosition = Duration(
      milliseconds: (value * totalDuration.inMilliseconds).round(),
    );
    try {
      await _audioPlayerService.seek(newPosition);
    } catch (e) {
      debugPrint('Error seeking: $e');
    }
  }

  void _changePlaybackSpeed(double speed) async {
    try {
      await _audioPlayerService.setPlaybackSpeed(speed);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Playback speed changed to ${speed}x'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1)));
      }
    } catch (e) {
      debugPrint('Error changing playback speed: $e');
    }
  }

  void _skipForward() async {
    try {
      await _audioPlayerService.skipForward(30);
    } catch (e) {
      debugPrint('Error skipping forward: $e');
    }
  }

  void _skipBackward() async {
    try {
      await _audioPlayerService.skipBackward(15);
    } catch (e) {
      debugPrint('Error skipping backward: $e');
    }
  }

  void _onShare() {
    if (currentEpisode != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Sharing: ${currentEpisode!['title']}'),
          behavior: SnackBarBehavior.floating));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No episode selected to share'),
          behavior: SnackBarBehavior.floating));
    }
  }

  // Play History Tracking Methods
  void _updatePlayHistoryProgress(int progressSeconds) {
    if (currentEpisode == null) return;

    try {
      final historyProvider =
          Provider.of<HistoryProvider>(context, listen: false);
      historyProvider.updateProgress(
        episodeId: currentEpisode!['id'].toString(),
        progressSeconds: progressSeconds,
        totalListeningTime: progressSeconds,
      );
    } catch (e) {
      debugPrint('Error updating play history progress: $e');
    }
  }

  void _trackPlayHistoryEvent(String status) {
    if (currentEpisode == null) return;

    try {
      final historyProvider =
          Provider.of<HistoryProvider>(context, listen: false);
      historyProvider.updatePlayHistory(
        episodeId: currentEpisode!['id'].toString(),
        status: status,
        position: currentPosition.inSeconds,
        progressSeconds: currentPosition.inSeconds,
        totalListeningTime: currentPosition.inSeconds,
      );
    } catch (e) {
      debugPrint('Error tracking play history event: $e');
    }
  }

  void _downloadEpisode(Map<String, dynamic> episode) async {
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
      // Check if already downloaded
      final isDownloaded =
          await _downloadManager.isEpisodeDownloaded(episodeId);

      if (isDownloaded) {
        // Remove download
        await _downloadManager.deleteDownloadedEpisode(episodeId, context);

        setState(() {
          final index = podcastEpisodes
              .indexWhere((e) => e['id'].toString() == episodeId);
          if (index != -1) {
            podcastEpisodes[index]['isDownloaded'] = false;
          }
        });
      } else {
        // Download episode
        await _downloadManager.downloadEpisodeWithValidation(
          episodeId: episodeId,
          episodeTitle: episodeTitle,
          audioUrl: audioUrl,
          context: context,
          onDownloadComplete: () {
            setState(() {
              final index = podcastEpisodes
                  .indexWhere((e) => e['id'].toString() == episodeId);
              if (index != -1) {
                podcastEpisodes[index]['isDownloaded'] = true;
              }
            });
          },
          onDownloadError: () {
            // Error handling is done in the download manager
          },
        );
      }
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

  void _onDownload() {
    if (currentEpisode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No episode selected to download'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _downloadEpisode(currentEpisode!);
  }

  void _onAddToPlaylist() {
    if (currentEpisode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No episode selected')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddToPlaylistWidget(
        episodeId: currentEpisode!['id'],
        onSuccess: () {
          setState(() {
            isInPlaylist = true;
          });
        },
      ),
    );
  }

  void _toggleWatchLater() {
    setState(() {
      isInWatchLater = !isInWatchLater;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isInWatchLater
            ? 'Added to Watch Later'
            : 'Removed from Watch Later'),
        behavior: SnackBarBehavior.floating));
  }

  void _toggleNotifications() {
    setState(() {
      notificationsEnabled = !notificationsEnabled;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(notificationsEnabled
            ? 'Notifications enabled for new episodes'
            : 'Notifications disabled'),
        behavior: SnackBarBehavior.floating));
  }

  void _toggleSubscription() async {
    if (currentPodcast == null) return;

    final podcastId = currentPodcast!['id'].toString();
    await handleSubscribeAction(
      context: context,
      podcastId: podcastId,
      isCurrentlySubscribed: isSubscribed,
      onStateChanged: (bool subscribed) {
        if (mounted) {
          setState(() {
            isSubscribed = subscribed;
          });
        }
      },
    );
  }

  // When starting an episode, check for saved progress and seek to that position if available
  void _playEpisode(Map<String, dynamic> episode) async {
    try {
      // Attach feedId from currentPodcast if not present
      final episodeWithFeedId = Map<String, dynamic>.from(episode);
      if (currentPodcast != null && currentPodcast!['id'] != null) {
        episodeWithFeedId['feedId'] = currentPodcast!['id'];
      }

      // Update UI immediately
      setState(() {
        // Reset current episode flags
        if (currentEpisode != null) {
          final currentIndex = podcastEpisodes.indexWhere(
              (e) => e['id'].toString() == currentEpisode!['id'].toString());
          if (currentIndex != -1) {
            podcastEpisodes[currentIndex]['isCurrentEpisode'] = false;
          }
        }

        // Set new episode as current
        final newIndex = podcastEpisodes
            .indexWhere((e) => e['id'].toString() == episode['id'].toString());
        if (newIndex != -1) {
          podcastEpisodes[newIndex]['isCurrentEpisode'] = true;

          // Update playlist index if in playlist mode
          if (isPlaylistMode) {
            currentPlaylistIndex = newIndex;
          }
        }

        currentEpisode = Map<String, dynamic>.from(episodeWithFeedId);
        currentEpisode!['isCurrentEpisode'] = true;
      });

      // Set episode queue in the centralized provider for auto-play functionality
      if (mounted) {
        final playerProvider =
            Provider.of<PodcastPlayerProvider>(context, listen: false);
        _ensureEpisodeQueueIsSet(playerProvider);
        // Set podcast data for proper image display
        if (currentPodcast != null) {
          playerProvider.setCurrentPodcastData(currentPodcast);
        }
      }

      // --- Advanced progress tracking: seek to saved position if available ---
      final savedMs = _audioPlayerService
          .getSavedProgress(episodeWithFeedId['id'].toString());
      await _audioPlayerService.loadAndPlayEpisode(episodeWithFeedId);
      if (savedMs != null && savedMs > 0) {
        await _audioPlayerService.seek(Duration(milliseconds: savedMs));
      }

      // After setting the new episode, check playlist status
      await _checkIfEpisodeInPlaylist();

      // Track play history - episode started
      _trackPlayHistoryEvent('played');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Now playing:  [1m${episodeWithFeedId['title']} [0m'),
            behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      debugPrint('Error playing episode: $e');
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

  // Playlist navigation methods
  // --- Playlist mode next/previous navigation ---
  void _playNextEpisode() {
    if (mounted) {
      final playerProvider =
          Provider.of<PodcastPlayerProvider>(context, listen: false);

      // Use the centralized provider for next episode
      if (playerProvider.autoPlayNext) {
        debugPrint(
            'PodcastPlayer: Using centralized provider for next episode');
        playerProvider.playNext();
      } else {
        // Fallback to local logic if auto-play is disabled
        if (isPlaylistMode &&
            currentPlaylistIndex + 1 < podcastEpisodes.length) {
          setState(() {
            currentPlaylistIndex++;
            currentEpisode = podcastEpisodes[currentPlaylistIndex];
            // Mark current episode
            for (int i = 0; i < podcastEpisodes.length; i++) {
              podcastEpisodes[i]['isCurrentEpisode'] =
                  i == currentPlaylistIndex;
            }
          });
          _audioPlayerService.loadAndPlayEpisode(currentEpisode!);
        } else if (!isPlaylistMode) {
          // Existing podcast mode logic
          _sortPodcastEpisodes();
          final idx = podcastEpisodes.indexWhere(
              (e) => e['id'].toString() == currentEpisode!['id'].toString());
          if (idx != -1 && idx + 1 < podcastEpisodes.length) {
            final nextEpisode = podcastEpisodes[idx + 1];
            setState(() {
              currentEpisode = nextEpisode;
            });
            _audioPlayerService.loadAndPlayEpisode(nextEpisode);
          }
        }
      }
    }
  }

  void _playPreviousEpisode() {
    if (mounted) {
      final playerProvider =
          Provider.of<PodcastPlayerProvider>(context, listen: false);

      // Use the centralized provider for previous episode
      if (playerProvider.autoPlayNext) {
        debugPrint(
            'PodcastPlayer: Using centralized provider for previous episode');
        playerProvider.playPrevious();
      } else {
        // Fallback to local logic if auto-play is disabled
        if (isPlaylistMode && currentPlaylistIndex > 0) {
          setState(() {
            currentPlaylistIndex--;
            currentEpisode = podcastEpisodes[currentPlaylistIndex];
            // Mark current episode
            for (int i = 0; i < podcastEpisodes.length; i++) {
              podcastEpisodes[i]['isCurrentEpisode'] =
                  i == currentPlaylistIndex;
            }
          });
          _audioPlayerService.loadAndPlayEpisode(currentEpisode!);
        } else if (!isPlaylistMode) {
          // Existing podcast mode logic
          _sortPodcastEpisodes();
          final idx = podcastEpisodes.indexWhere(
              (e) => e['id'].toString() == currentEpisode!['id'].toString());
          if (idx > 0) {
            final prevEpisode = podcastEpisodes[idx - 1];
            setState(() {
              currentEpisode = prevEpisode;
            });
            _audioPlayerService.loadAndPlayEpisode(prevEpisode);
          }
        }
      }
    }
  }

  bool get _canPlayNext =>
      isPlaylistMode && currentPlaylistIndex < podcastEpisodes.length - 1;
  bool get _canPlayPrevious => isPlaylistMode && currentPlaylistIndex > 0;

  void _shareEpisode(Map<String, dynamic> episode) async {
    try {
      final episodeTitle = episode['title'] ?? 'Unknown Episode';
      final podcastTitle = currentPodcast?['title'] ?? 'Unknown Podcast';
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

  String _formatDuration(double minutes) {
    final int totalMinutes = minutes.toInt();
    final int hours = totalMinutes ~/ 60;
    final int remainingMinutes = totalMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${remainingMinutes}m';
    } else {
      return '${remainingMinutes}m';
    }
  }

  // Get duration in seconds for calculations
  double get _episodeDurationInSeconds {
    if (currentEpisode == null) return 0.0;
    final duration = currentEpisode!['duration'];
    if (duration is int) {
      debugPrint('PodcastPlayer: Duration is int: $duration seconds');
      return duration.toDouble();
    } else if (duration is String) {
      debugPrint('PodcastPlayer: Parsing duration string: "$duration"');
      final seconds = DurationUtils.parseDurationToSeconds(duration);
      debugPrint('PodcastPlayer: Parsed duration to seconds: $seconds');
      return seconds;
    } else {
      debugPrint('PodcastPlayer: Duration is null or invalid type: $duration');
      return 0.0;
    }
  }

  void _showSpeedControlModal() {
    showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return SpeedControlWidget(
              currentSpeed: playbackSpeed,
              onSpeedChanged: _changePlaybackSpeed,
              onClose: () => Navigator.of(context).pop());
        });
  }

  // Helper to sort podcastEpisodes by datePublished (newest first)
  void _sortPodcastEpisodes() {
    podcastEpisodes.sort((a, b) {
      final aDate = _parseDatePublished(a['datePublished']);
      final bDate = _parseDatePublished(b['datePublished']);
      return bDate.compareTo(aDate); // Descending: newest first
    });
    debugPrint('PodcastPlayer: Sorted podcastEpisodes order (newest first):');
    for (var ep in podcastEpisodes) {
      debugPrint(
          '  -  [32m${ep['title']} (${ep['datePublished'] ?? ep['releaseDate'] ?? ep['publishDate']}) [0m');
    }
  }

  /// Parse datePublished field (Unix timestamp) to DateTime
  DateTime _parseDatePublished(dynamic datePublished) {
    if (datePublished == null) return DateTime(1970);

    // Handle Unix timestamp (seconds since epoch)
    if (datePublished is int) {
      return DateTime.fromMillisecondsSinceEpoch(datePublished * 1000);
    }

    // Handle string representation of Unix timestamp
    if (datePublished is String) {
      final timestamp = int.tryParse(datePublished);
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      }
    }

    // Fallback to old date parsing for backward compatibility
    return DateTime.tryParse(datePublished.toString()) ?? DateTime(1970);
  }

  @override
  void dispose() {
    // Track play history - episode abandoned when leaving player
    if (currentEpisode != null && isPlaying) {
      _trackPlayHistoryEvent('abandoned');
    }

    _animationController.dispose();
    _tabController.dispose();
    _currentEpisodeSub?.cancel();
    _episodeCompleteSub?.cancel();
    _positionStreamSub?.cancel();
    _durationStreamSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionProvider>(
      builder: (context, subscriptionProvider, child) {
        // Get subscription status from provider
        final podcastId = currentPodcast?['id']?.toString();
        final isSubscribedFromProvider = podcastId != null
            ? subscriptionProvider.isSubscribed(podcastId)
            : false;

        // Update local subscription status if it differs from provider
        if (isSubscribed != isSubscribedFromProvider) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                isSubscribed = isSubscribedFromProvider;
              });
            }
          });
        }

        // Show loading state while podcast data is being loaded
        if (isLoadingPodcast) {
          return Scaffold(
            backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: AppTheme.lightTheme.colorScheme.primary,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Loading podcast...',
                    style: AppTheme.lightTheme.textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          );
        }

        // Show error state if there's an error
        if (errorMessage != null) {
          return Scaffold(
            backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: CustomIconWidget(
                  iconName: 'arrow_back',
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                  size: 24,
                ),
                onPressed: () {
                  // Track play history - episode abandoned when leaving player
                  if (currentEpisode != null && isPlaying) {
                    _trackPlayHistoryEvent('abandoned');
                  }
                  _navigationService.goBack();
                },
              ),
              title: Text(
                'Error',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                ),
              ),
              centerTitle: true,
            ),
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomIconWidget(
                      iconName: 'error_outline',
                      color: Colors.red,
                      size: 48,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Oops! Something went wrong',
                      style: AppTheme.lightTheme.textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      errorMessage!,
                      style: AppTheme.lightTheme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 3.h),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          errorMessage = null;
                        });
                        if (currentPodcast != null) {
                          _loadPodcastData(currentPodcast!);
                        }
                      },
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Show empty state if no podcast data
        if (currentPodcast == null) {
          return Scaffold(
            backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: CustomIconWidget(
                  iconName: 'arrow_back',
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                  size: 24,
                ),
                onPressed: () {
                  // Track play history - episode abandoned when leaving player
                  if (currentEpisode != null && isPlaying) {
                    _trackPlayHistoryEvent('abandoned');
                  }
                  _navigationService.goBack();
                },
              ),
              title: Text(
                'No Podcast Selected',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                ),
              ),
              centerTitle: true,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomIconWidget(
                    iconName: 'podcasts',
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    size: 48,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'No podcast selected',
                    style: AppTheme.lightTheme.textTheme.titleLarge,
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Please select a podcast to start listening',
                    style: AppTheme.lightTheme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
            backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
            body: NestedScrollView(
                headerSliverBuilder:
                    (BuildContext context, bool innerBoxIsScrolled) {
                  return [
                    // Custom App Bar
                    SliverAppBar(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        floating: true,
                        pinned: false,
                        leading: IconButton(
                            icon: CustomIconWidget(
                                iconName: 'arrow_back',
                                color:
                                    AppTheme.lightTheme.colorScheme.onSurface,
                                size: 24),
                            onPressed: () {
                              // Track play history - episode abandoned when leaving player
                              if (currentEpisode != null && isPlaying) {
                                _trackPlayHistoryEvent('abandoned');
                              }
                              _navigationService.goBack();
                            }),
                        title: Text('Now Playing',
                            style: AppTheme.lightTheme.textTheme.titleLarge
                                ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme
                                        .lightTheme.colorScheme.onSurface)),
                        centerTitle: true,
                        actions: [
                          // Auto-play toggle button
                          Consumer<PodcastPlayerProvider>(
                            builder: (context, playerProvider, child) {
                              return IconButton(
                                icon: CustomIconWidget(
                                  iconName: playerProvider.autoPlayNext
                                      ? 'playlist_play'
                                      : 'playlist_remove',
                                  color: playerProvider.autoPlayNext
                                      ? AppTheme.lightTheme.colorScheme.primary
                                      : AppTheme
                                          .lightTheme.colorScheme.onSurface,
                                  size: 24,
                                ),
                                onPressed: () {
                                  playerProvider.toggleAutoPlayNext();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(playerProvider.autoPlayNext
                                          ? 'Auto-play enabled'
                                          : 'Auto-play disabled'),
                                      behavior: SnackBarBehavior.floating,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                                tooltip: playerProvider.autoPlayNext
                                    ? 'Disable auto-play'
                                    : 'Enable auto-play',
                              );
                            },
                          ),
                          IconButton(
                              icon: CustomIconWidget(
                                  iconName: 'settings',
                                  color:
                                      AppTheme.lightTheme.colorScheme.onSurface,
                                  size: 24),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PlayerSettingsWidget(
                                      onSettingsChanged: () {
                                        // Refresh player state if needed
                                        setState(() {});
                                      },
                                    ),
                                  ),
                                );
                              }),
                          IconButton(
                              icon: CustomIconWidget(
                                  iconName: 'share',
                                  color:
                                      AppTheme.lightTheme.colorScheme.onSurface,
                                  size: 24),
                              onPressed: _onShare),
                          PopupMenuButton<String>(
                              icon: CustomIconWidget(
                                  iconName: 'more_vert',
                                  color:
                                      AppTheme.lightTheme.colorScheme.onSurface,
                                  size: 24),
                              onSelected: (value) {
                                switch (value) {
                                  case 'download':
                                    _onDownload();
                                    break;
                                  case 'playlist':
                                    _onAddToPlaylist();
                                    break;
                                }
                              },
                              itemBuilder: (BuildContext context) => [
                                    PopupMenuItem<String>(
                                        value: 'download',
                                        child: Row(children: [
                                          CustomIconWidget(
                                              iconName: 'download',
                                              size: 20,
                                              color: AppTheme.lightTheme
                                                  .colorScheme.onSurface),
                                          SizedBox(width: 3.w),
                                          Text('Download',
                                              style: AppTheme.lightTheme
                                                  .textTheme.bodyMedium),
                                        ])),
                                    PopupMenuItem<String>(
                                        value: 'playlist',
                                        child: Row(children: [
                                          CustomIconWidget(
                                              iconName: isInPlaylist
                                                  ? 'playlist_remove'
                                                  : 'playlist_add',
                                              size: 20,
                                              color: AppTheme.lightTheme
                                                  .colorScheme.onSurface),
                                          SizedBox(width: 3.w),
                                          Text(
                                              isInPlaylist
                                                  ? 'Remove from Playlist'
                                                  : 'Add to Playlist',
                                              style: AppTheme.lightTheme
                                                  .textTheme.bodyMedium),
                                        ])),
                                  ]),
                        ]),

                    // Player Section
                    SliverToBoxAdapter(
                        child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 6.w),
                            child: Column(children: [
                              SizedBox(height: 2.h),

                              // Episode artwork with rotation animation
                              AnimatedBuilder(
                                  animation: _animationController,
                                  builder: (context, child) {
                                    return Transform.rotate(
                                        angle: isPlaying
                                            ? _animationController.value *
                                                2 *
                                                3.14159
                                            : 0,
                                        child: Container(
                                            width: 60.w,
                                            height: 60.w,
                                            decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                      color: AppTheme.lightTheme
                                                          .colorScheme.shadow,
                                                      blurRadius: 20,
                                                      offset:
                                                          const Offset(0, 8)),
                                                ]),
                                            child: ClipOval(
                                                child: CustomImageWidget(
                                                    imageUrl: currentPodcast?[
                                                            'coverImage'] ??
                                                        currentEpisode?[
                                                            'coverImage'] ??
                                                        '',
                                                    fit: BoxFit.cover,
                                                    width: 60.w,
                                                    height: 60.w))));
                                  }),

                              SizedBox(height: 4.h),

                              // Episode info
                              if (currentEpisode != null)
                                Column(
                                  children: [
                                    // Playlist progress indicator
                                    if (isPlaylistMode &&
                                        currentPlaylist != null)
                                      Container(
                                        margin: EdgeInsets.only(bottom: 2.h),
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: AppTheme.lightTheme.colorScheme
                                              .surfaceContainer,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          'Episode ${currentPlaylistIndex + 1} of $totalPlaylistEpisodes',
                                          style: AppTheme
                                              .lightTheme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: AppTheme.lightTheme
                                                .colorScheme.onSurfaceVariant,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    EpisodeInfoWidget(
                                      episode: currentEpisode!,
                                      isEarningEnabled: isEarningEnabled,
                                      podcast: currentPodcast,
                                    ),
                                  ],
                                )
                              else
                                Container(
                                  padding: EdgeInsets.all(4.w),
                                  child: Text(
                                    'Select an episode to start playing',
                                    style:
                                        AppTheme.lightTheme.textTheme.bodyLarge,
                                    textAlign: TextAlign.center,
                                  ),
                                ),

                              SizedBox(height: 3.h),

                              // Earning progress (only if earning is enabled and it's an earning episode)
                              if (isEarningEnabled &&
                                  isEarningEpisode &&
                                  currentEpisode != null) ...[
                                EarningProgressWidget(
                                    earnedCoins: coinsEarned,
                                    totalPotentialCoins:
                                        _episodeDurationInSeconds *
                                            coinsPerMinute /
                                            60,
                                    isActive: isPlaying),
                                SizedBox(height: 3.h),
                              ] else if (currentEpisode?['isEarningEpisode'] ==
                                      true &&
                                  !isEarningEnabled) ...[
                                Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                        color: AppTheme.warningLight
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                            color: AppTheme.warningLight
                                                .withValues(alpha: 0.3))),
                                    child: Row(children: [
                                      CustomIconWidget(
                                          iconName: 'info_outline',
                                          color: AppTheme.warningLight,
                                          size: 20),
                                      SizedBox(width: 2.w),
                                      Expanded(
                                          child: Text(
                                              'This episode supports earning. Navigate from the Earn tab to enable coin collection.',
                                              style: AppTheme.lightTheme
                                                  .textTheme.bodySmall
                                                  ?.copyWith(
                                                      color:
                                                          AppTheme.warningLight,
                                                      fontSize: 12))),
                                    ])),
                                SizedBox(height: 3.h),
                              ],

                              // Player controls section with progress slider
                              if (currentEpisode != null) ...[
                                Column(
                                  children: [
                                    // Progress slider
                                    ProgressSliderWidget(
                                      currentPosition: currentPosition,
                                      totalDuration: totalDuration,
                                      onSeek: _onSeek,
                                    ),

                                    SizedBox(height: 2.h),

                                    // Player controls
                                    PlayerControlsWidget(
                                        isPlaying: isPlaying,
                                        isLoading: isLoading,
                                        isEarningActive: isEarningEnabled &&
                                            isEarningEpisode,
                                        playbackSpeed: playbackSpeed,
                                        onSpeedControl: () =>
                                            _showSpeedControlModal(),
                                        onPlayPause: _togglePlayPause,
                                        onSkipForward: _skipForward,
                                        onSkipBackward: _skipBackward,
                                        isPlaylistMode: isPlaylistMode,
                                        canPlayNext: _canPlayNext,
                                        canPlayPrevious: _canPlayPrevious,
                                        onPlayNext: _playNextEpisode,
                                        onPlayPrevious: _playPreviousEpisode),
                                  ],
                                ),
                              ] else ...[
                                // Show play button when no episode is selected
                                ElevatedButton.icon(
                                  onPressed: podcastEpisodes.isNotEmpty
                                      ? () =>
                                          _playEpisode(podcastEpisodes.first)
                                      : null,
                                  icon: const Icon(Icons.play_arrow),
                                  label: Text(podcastEpisodes.isNotEmpty
                                      ? 'Play First Episode'
                                      : 'No Episodes Available'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        AppTheme.lightTheme.colorScheme.primary,
                                    foregroundColor: AppTheme
                                        .lightTheme.colorScheme.onPrimary,
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 4.w, vertical: 2.h),
                                  ),
                                ),
                              ],

                              SizedBox(height: 4.h),
                            ]))),

                    // Tab Bar
                    SliverPersistentHeader(
                        pinned: true,
                        delegate: _SliverTabBarDelegate(TabBar(
                            controller: _tabController,
                            labelStyle: AppTheme.lightTheme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                            unselectedLabelStyle: AppTheme
                                .lightTheme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w400),
                            indicatorColor:
                                AppTheme.lightTheme.colorScheme.primary,
                            labelColor: AppTheme.lightTheme.colorScheme.primary,
                            unselectedLabelColor: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                            tabs: const [
                              Tab(text: 'Episodes'),
                              Tab(text: 'Description'),
                            ]))),
                  ];
                },
                body: TabBarView(controller: _tabController, children: [
                  isPlaylistMode
                      ? PlayerPlaylistEpisodesTabWidget(
                          currentEpisodeId: currentEpisode?['id']?.toString(),
                          onPlayEpisode: _playEpisode,
                          onDownloadEpisode: _downloadEpisode,
                          onShareEpisode: _shareEpisode,
                          playlistEpisodes: podcastEpisodes,
                          playlistName: currentPlaylist?['name'] ?? 'Playlist',
                        )
                      : PlayerEpisodesTabWidget(
                          feedId: currentPodcast?['id']?.toString(),
                          currentEpisodeId: currentEpisode?['id']?.toString(),
                          onPlayEpisode: _playEpisode,
                          onDownloadEpisode: _downloadEpisode,
                          onShareEpisode: _shareEpisode,
                          currentPodcast: currentPodcast,
                          isEarningEnabled: isEarningEnabled,
                        ),
                  Builder(
                    builder: (context) {
                      final episodeCount = currentPodcast!['episodeCount'] ??
                          podcastEpisodes.length;
                      final totalDuration =
                          currentPodcast!['totalDuration'] ?? '0h';
                      debugPrint(
                          '=== PLAYER PASSING TO DESCRIPTION WIDGET ===');
                      debugPrint(
                          'currentPodcast keys: ${currentPodcast!.keys}');
                      debugPrint(
                          'currentPodcast episodeCount: ${currentPodcast!['episodeCount']}');
                      debugPrint(
                          'currentPodcast totalDuration: ${currentPodcast!['totalDuration']}');
                      debugPrint(
                          'podcastEpisodes length: ${podcastEpisodes.length}');
                      debugPrint('Passing episodeCount: $episodeCount');
                      debugPrint('Passing totalDuration: $totalDuration');
                      return PlayerDescriptionTabWidget(
                        podcast: currentPodcast!,
                        episodeCount: episodeCount,
                        totalDuration: totalDuration,
                        isSubscribed: isSubscribed,
                        notificationsEnabled: notificationsEnabled,
                        isInWatchLater: isInWatchLater,
                        isInPlaylist: isInPlaylist,
                        onSubscriptionToggle: _toggleSubscription,
                        onNotificationToggle: _toggleNotifications,
                        onWatchLaterToggle: _toggleWatchLater,
                        onPlaylistToggle: _onAddToPlaylist,
                      );
                    },
                  ),
                ])));
      },
    );
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
        color: AppTheme.lightTheme.colorScheme.surface, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
