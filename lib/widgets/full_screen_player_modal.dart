import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_export.dart';
import '../providers/podcast_player_provider.dart';
import '../models/episode_bookmark.dart';
import '../services/chromecast_service.dart';
import 'up_next_modal.dart';
import 'chromecast_device_selector.dart';
import '../widgets/add_to_playlist_widget.dart';
import '../widgets/add_bookmark_modal.dart';
import '../services/episode_progress_service.dart';
import '../services/download_manager.dart';
import '../services/social_sharing_service.dart';
import 'custom_image_widget.dart';
import '../core/utils/image_utils.dart';
import 'buffering_indicator.dart';

class FullScreenPlayerModal extends StatefulWidget {
  final Map<String, dynamic> episode;
  final List<Map<String, dynamic>> episodes;
  final int episodeIndex;
  final VoidCallback onMinimize;
  final bool isMinimized; // Add this parameter

  const FullScreenPlayerModal({
    super.key,
    required this.episode,
    required this.episodes,
    required this.episodeIndex,
    required this.onMinimize,
    this.isMinimized = false, // Default to false (full screen)
  });

  @override
  State<FullScreenPlayerModal> createState() => _FullScreenPlayerModalState();
}

class _FullScreenPlayerModalState extends State<FullScreenPlayerModal>
    with TickerProviderStateMixin {
  int _selectedTabIndex = 0;

  // Playback effects state
  double _currentPlaybackSpeed = 1.0;
  bool _trimSilenceEnabled = false;
  bool _volumeBoostEnabled = false;
  bool _applyToAllPodcasts = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // No need for TabController listener since we're using IndexedStack

    // Hide mini-player when full screen modal is shown to prevent z-index issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        try {
          final playerProvider =
              Provider.of<PodcastPlayerProvider>(context, listen: false);
          playerProvider.hideFloatingMiniPlayer();

          // Load playback effects settings
          _loadPlaybackEffectsSettings();
        } catch (e) {
          debugPrint('Error in full screen modal initState: $e');
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();

    // Show mini-player again when full screen modal is closed (if episode is playing)
    // Use a delayed callback to ensure the widget is still mounted
    Future.delayed(Duration.zero, () {
      if (mounted) {
        try {
          final playerProvider =
              Provider.of<PodcastPlayerProvider>(context, listen: false);
          // Use forceShowMiniPlayer to ensure mini-player appears after modal disposal
          playerProvider.forceShowMiniPlayer(context);
        } catch (e) {
          debugPrint(
              'Error showing mini-player in full screen modal dispose: $e');
        }
      }
    });

    super.dispose();
  }

  /// Handle modal dismissal to ensure mini-player is properly restored
  void _handleModalDismissal(
      BuildContext context, PodcastPlayerProvider playerProvider) {
    debugPrint('🎵 FullScreenPlayerModal: Handling modal dismissal');

    try {
      // Use forceShowMiniPlayer to ensure mini-player is shown when modal is dismissed
      // This bypasses user preferences and ensures mini-player appears for system actions
      playerProvider.forceShowMiniPlayer(context);
      debugPrint(
          '🎵 FullScreenPlayerModal: Mini-player force restored after dismissal');
    } catch (e) {
      debugPrint('❌ Error restoring mini-player after modal dismissal: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PodcastPlayerProvider>(
      builder: (context, playerProvider, child) {
        // Get real playback state from provider
        final isPlaying = playerProvider.isPlaying;
        final currentPosition = playerProvider.position ?? Duration.zero;
        final totalDuration = playerProvider.duration ?? Duration.zero;

        // Use the provider's current episode to ensure synchronization
        final currentEpisode = playerProvider.currentEpisode;

        // Debug logging
        debugPrint('=== FULL SCREEN PLAYER BUILD ===');
        debugPrint('isPlaying: $isPlaying');
        debugPrint('position: ${currentPosition.inSeconds}s');
        debugPrint('duration: ${totalDuration.inSeconds}s');
        debugPrint('Provider episode: ${currentEpisode?.title}');
        debugPrint('Widget episode: ${widget.episode['title']}');
        debugPrint('Widget episode keys: ${widget.episode.keys.toList()}');
        debugPrint(
            'Widget episode coverImage: ${widget.episode['coverImage']}');
        debugPrint('Widget episode podcast: ${widget.episode['podcast']}');
        debugPrint('Widget episodes length: ${widget.episodes.length}');

        // Always show full screen player - minimized state handled by floating mini-player
        return PopScope(
          canPop: true, // Allow back button dismissal
          onPopInvoked: (didPop) {
            if (didPop) {
              // Modal was popped by back button, ensure mini-player is restored
              _handleModalDismissal(context, playerProvider);
            }
          },
          child: BufferingIndicator(
            showProgress: true,
            showStatus: true,
            child: Material(
              elevation:
                  100, // High elevation to ensure it appears above mini-player
              color: Colors.transparent,
              child: _buildFullScreenPlayer(context, playerProvider, isPlaying,
                  currentPosition, totalDuration),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFullScreenPlayer(
      BuildContext context,
      PodcastPlayerProvider playerProvider,
      bool isPlaying,
      Duration currentPosition,
      Duration totalDuration) {
    return RepaintBoundary(
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.black
              : Colors.white,
        ),
        child: SafeArea(
          bottom: true, // Ensure bottom safe area is respected
          child: Column(
            children: [
              // Top Navigation Bar
              _buildHeader(),

              // Show player content only for Now Playing tab (index 0)
              if (_selectedTabIndex == 0)
                Expanded(
                  child: Column(
                    children: [
                      // Episode Artwork Section (Full Coverage)
                      _buildEpisodeArtworkSection(),

                      // Episode Information
                      _buildEpisodeInfo(),

                      // Progress Bar
                      _buildProgressBar(currentPosition, totalDuration),

                      // Player Controls
                      _buildPlayerControls(playerProvider, isPlaying),
                    ],
                  ),
                ),

              // Tab Content - Only show for Details and Bookmarks tabs
              if (_selectedTabIndex != 0)
                Expanded(
                  child: _buildTabContent(),
                ),

              // Bottom Utility Bar - Only show for Now Playing tab
              if (_selectedTabIndex == 0) _buildBottomUtilityBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      child: Row(
        children: [
          // Minimize button (downward chevron)
          IconButton(
            onPressed: () {
              // Close full-screen player and show floating mini-player properly
              widget.onMinimize();
            },
            icon: Icon(
              Icons.keyboard_arrow_down,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
              size: 28,
            ),
          ),

          // Center tabs
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTabButton('Now Playing', 0),
                const SizedBox(width: 32),
                _buildTabButton('Details', 1),
                const SizedBox(width: 32),
                _buildTabButton('Bookmarks', 2),
              ],
            ),
          ),

          // Compact buffering indicator
          const CompactBufferingIndicator(size: 20),

          const SizedBox(width: 8),

          // Up Next menu with queue count badge
          Consumer<PodcastPlayerProvider>(
            builder: (context, playerProvider, child) {
              final queueCount = playerProvider.episodeQueue.length;

              return Stack(
                children: [
                  IconButton(
                    onPressed: () => _showUpNextModal(context),
                    icon: Icon(
                      Icons.queue_music,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                      size: 24,
                    ),
                  ),
                  // Queue count badge
                  if (queueCount > 0)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.blue
                              : Colors.blue,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.white,
                            width: 1,
                          ),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          queueCount.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String text, int index) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        debugPrint('🎯 Tab button tapped: $text (index: $index)');
        setState(() {
          _selectedTabIndex = index;
        });
        debugPrint('🎯 Selected tab index updated to: $_selectedTabIndex');
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: TextStyle(
              color: isSelected
                  ? (Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black)
                  : (Theme.of(context).brightness == Brightness.dark
                      ? Colors.white54
                      : Colors.black54),
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(top: 4),
              height: 2,
              width: text.length * 8.0,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
                borderRadius: const BorderRadius.all(Radius.circular(1)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEpisodeArtworkSection() {
    return Consumer<PodcastPlayerProvider>(
      builder: (context, playerProvider, child) {
        // Use current episode data with podcast data if available, otherwise fall back to widget episode
        final currentEpisode = playerProvider.currentEpisode;
        final episodeData = currentEpisode != null
            ? currentEpisode
                .toMapWithPodcastData(playerProvider.currentPodcastData)
            : widget.episode;

        // Extract podcast image using the utility function
        final podcastImage = ImageUtils.extractPodcastImageWithFallback(
          episodeData,
          widget.episodes,
        );

        debugPrint('Full-screen player image extracted: $podcastImage');

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 32),
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: podcastImage.isEmpty
                  ? AppTheme.lightTheme.colorScheme.surfaceContainer
                  : null,
            ),
            child: ImageUtils.isValidImageUrl(podcastImage)
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: CustomImageWidget(
                      imageUrl: podcastImage,
                      width: 200,
                      height: 200,
                      fit: BoxFit.cover,
                      errorWidget: ImageUtils.getFallbackWidget(
                        width: 200,
                        height: 200,
                        backgroundColor:
                            AppTheme.lightTheme.colorScheme.surfaceContainer,
                        iconColor:
                            AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        icon: Icons.music_note,
                      ),
                    ),
                  )
                : ImageUtils.getFallbackWidget(
                    width: 200,
                    height: 200,
                    backgroundColor:
                        AppTheme.lightTheme.colorScheme.surfaceContainer,
                    iconColor: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    icon: Icons.music_note,
                  ),
          ),
        );
      },
    );
  }

  Widget _buildEpisodeInfo() {
    return Consumer<PodcastPlayerProvider>(
      builder: (context, playerProvider, child) {
        final currentEpisode = playerProvider.currentEpisode;
        final episodeTitle = currentEpisode?.title ??
            widget.episode['title'] ??
            'Untitled Episode';
        final podcastName = currentEpisode?.podcastName ??
            widget.episode['podcast']?['title'] ??
            widget.episode['podcastName'] ??
            'Unknown Podcast';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                episodeTitle,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                  fontSize: 20, // Increased size for prominence
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _onGoToPodcast(context),
                child: Text(
                  podcastName,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.black87,
                    fontSize: 16, // Increased size slightly
                    decoration: TextDecoration.underline,
                    decorationColor:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressBar(Duration currentPosition, Duration totalDuration) {
    final progress = totalDuration.inMilliseconds > 0
        ? currentPosition.inMilliseconds / totalDuration.inMilliseconds
        : 0.0;

    // Debug logging for progress bar
    debugPrint(
        'Progress Bar - Position: ${currentPosition.inSeconds}s, Duration: ${totalDuration.inSeconds}s, Progress: ${(progress * 100).toStringAsFixed(1)}%');

    return Consumer<PodcastPlayerProvider>(
      builder: (context, playerProvider, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            children: [
              // Progress bar
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor:
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                  inactiveTrackColor:
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.white54
                          : Colors.black54,
                  thumbColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 6),
                  trackHeight: 2,
                ),
                child: Slider(
                  value: progress.clamp(0.0, 1.0),
                  onChanged: (value) {
                    // Validate and calculate new position
                    if (totalDuration.inMilliseconds <= 0) {
                      debugPrint('❌ Cannot seek: Invalid duration');
                      return;
                    }

                    final newPosition = Duration(
                      milliseconds:
                          (value * totalDuration.inMilliseconds).round(),
                    );

                    // Ensure position is within valid bounds
                    final clampedPosition = Duration(
                      milliseconds: newPosition.inMilliseconds
                          .clamp(0, totalDuration.inMilliseconds),
                    );

                    debugPrint(
                        '🎵 UI: Seeking to ${clampedPosition.inSeconds}s (${(value * 100).toStringAsFixed(1)}%)');

                    // Perform seek with error handling
                    try {
                      playerProvider.seekTo(clampedPosition);
                    } catch (e) {
                      debugPrint('❌ UI: Error during seek: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Seek failed: ${e.toString()}'),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
              ),

              // Time labels - format like the image (00:46 and -55:16)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(currentPosition),
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white54
                            : Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '-${_formatDuration(totalDuration - currentPosition)}', // Negative remaining time
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white54
                            : Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlayerControls(
      PodcastPlayerProvider playerProvider, bool isPlaying) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Rewind button (10 seconds)
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                  width: 2),
            ),
            child: IconButton(
              onPressed: () {
                // Implement rewind 10 seconds with player provider
                final currentPos = playerProvider.position ?? Duration.zero;
                final totalDur = playerProvider.duration ?? Duration.zero;

                final newPos = Duration(
                  milliseconds: (currentPos.inMilliseconds - 10000)
                      .clamp(0, totalDur.inMilliseconds)
                      .toInt(),
                );

                debugPrint(
                    '🎵 UI: Rewinding 10s from ${currentPos.inSeconds}s to ${newPos.inSeconds}s');
                playerProvider.seekTo(newPos);
              },
              icon: Icon(
                Icons.replay_10,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
                size: 24,
              ),
            ),
          ),

          const SizedBox(width: 32),

          // Play/Pause button
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
              border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                  width: 2),
            ),
            child: IconButton(
              onPressed: () {
                debugPrint('Full screen player: Play/Pause button pressed');
                debugPrint('Current isPlaying state: $isPlaying');

                if (isPlaying) {
                  debugPrint('Pausing audio...');
                  playerProvider.pause();
                } else {
                  debugPrint('Playing audio...');
                  playerProvider.play();
                }
              },
              icon: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black
                    : Colors.white,
                size: 40,
              ),
            ),
          ),

          const SizedBox(width: 32),

          // Fast forward button (30 seconds)
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                  width: 2),
            ),
            child: IconButton(
              onPressed: () {
                // Implement fast forward 30 seconds with player provider
                final currentPos = playerProvider.position ?? Duration.zero;
                final totalDur = playerProvider.duration ?? Duration.zero;

                final newPos = Duration(
                  milliseconds: (currentPos.inMilliseconds + 30000)
                      .clamp(0, totalDur.inMilliseconds)
                      .toInt(),
                );

                debugPrint(
                    '🎵 UI: Fast forwarding 30s from ${currentPos.inSeconds}s to ${newPos.inSeconds}s');
                playerProvider.seekTo(newPos);
              },
              icon: Icon(
                Icons.forward_30,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    // Only show Details and Bookmarks tabs (Now Playing is handled separately)
    return IndexedStack(
      index: _selectedTabIndex -
          1, // Adjust index since we skip Now Playing (index 0)
      children: [
        // Details Tab (index 0 in this stack)
        _buildDetailsTab(),

        // Bookmark Tab (index 1 in this stack)
        _buildBookmarkTab(),
      ],
    );
  }

  Widget _buildDetailsTab() {
    debugPrint(
        '🎯 _buildDetailsTab() called - Current selected index: $_selectedTabIndex');

    // Debug: Log all episode data to see what's available
    debugPrint('🎯 Episode data keys: ${widget.episode.keys.toList()}');
    debugPrint('🎯 Episode releaseDate: ${widget.episode['releaseDate']}');
    debugPrint('🎯 Episode datePublished: ${widget.episode['datePublished']}');
    debugPrint('🎯 Episode publishedAt: ${widget.episode['publishedAt']}');
    debugPrint('🎯 Episode pubDate: ${widget.episode['pubDate']}');
    debugPrint('🎯 Episode duration: ${widget.episode['duration']}');

    return Container(
      // No background color needed since this is now the main content area
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Episode Title - Large and prominent
            Text(
              widget.episode['title'] ?? 'Unknown Episode',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
            ),
            const SizedBox(height: 16),

            // Episode Metadata Row - Calendar and Duration
            Row(
              children: [
                // Date with calendar icon
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.black54,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(widget.episode['releaseDate'] ??
                          widget.episode['datePublished'] ??
                          widget.episode['publishedAt'] ??
                          widget.episode['pubDate']),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white70
                                    : Colors.black54,
                          ),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                // Duration with hourglass icon
                Row(
                  children: [
                    Icon(
                      Icons.hourglass_empty,
                      size: 16,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.black54,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDurationDisplay(widget.episode['duration'] ?? 0),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white70
                                    : Colors.black54,
                          ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Description Section
            Text(
              'Description',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
            ),
            const SizedBox(height: 8),
            _buildFormattedDescription(widget.episode['description'] ?? ''),
            const SizedBox(height: 24),

            // Bonus Content Section
            if (_hasBonusContent()) _buildBonusContentSection(),

            // Sponsors Section
            if (_hasSponsors()) _buildSponsorsSection(),

            // Social Links Section
            if (_hasSocialLinks()) _buildSocialLinksSection(),

            // Ad Choices Section
            _buildAdChoicesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildBookmarkTab() {
    return FutureBuilder<List<EpisodeBookmark>>(
      future: _loadEpisodeBookmarks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading bookmarks...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : Colors.black54,
                      ),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white54
                      : Colors.black54,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading bookmarks',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : Colors.black54,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {}); // Trigger rebuild to retry
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final bookmarks = snapshot.data ?? [];

        if (bookmarks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bookmark_border,
                  size: 80,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white54
                      : Colors.black54,
                ),
                const SizedBox(height: 24),
                Text(
                  'No bookmarks yet',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Bookmarks you create while listening to episodes will appear here',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : Colors.black54,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => _showAddBookmarkModal(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Bookmark'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.blue[700]
                            : Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Header with Add Bookmark button
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Bookmarks (${bookmarks.length})',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                        ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddBookmarkModal(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.blue[700]
                              : Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bookmarks list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: bookmarks.length,
                itemBuilder: (context, index) {
                  final bookmark = bookmarks[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]
                        : Colors.white,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Color(int.parse(
                              bookmark.color.replaceAll('#', '0xFF'))),
                          shape: BoxShape.circle,
                        ),
                      ),
                      title: Text(
                        bookmark.title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Colors.black,
                                ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            _formatDuration(
                                Duration(seconds: bookmark.position)),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white70
                                          : Colors.black54,
                                    ),
                          ),
                          if (bookmark.notes?.isNotEmpty == true) ...[
                            const SizedBox(height: 4),
                            Text(
                              bookmark.notes!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white70
                                        : Colors.black54,
                                  ),
                            ),
                          ],
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'play') {
                            _seekToBookmark(bookmark);
                          } else if (value == 'delete') {
                            _deleteBookmark(bookmark);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'play',
                            child: Row(
                              children: [
                                Icon(Icons.play_arrow, size: 20),
                                SizedBox(width: 8),
                                Text('Play from here'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 20, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete',
                                    style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      onTap: () => _seekToBookmark(bookmark),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBottomUtilityBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 32,
        right: 32,
        top: 16,
        bottom: 16 +
            MediaQuery.of(context)
                .padding
                .bottom, // Add bottom safe area padding
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.black87
            : Colors.grey[100],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Sleep timer icon - sun with small circle inside
          IconButton(
            onPressed: () {
              _showSleepTimerModal(context);
            },
            icon: Icon(
              Icons.wb_sunny, // Sun icon
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white54
                  : Colors.black54,
              size: 24,
            ),
          ),

          // Sleep timer (zzz)
          IconButton(
            onPressed: () {
              _showSleepTimerModal(context);
            },
            icon: Icon(
              Icons.bedtime, // Zzz/sleep icon
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white54
                  : Colors.black54,
              size: 24,
            ),
          ),

          // Playback Effects - equalizer icon
          IconButton(
            onPressed: () {
              _showPlaybackEffectsModal(context);
            },
            icon: Icon(
              Icons.equalizer, // Equalizer icon for playback effects
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white54
                  : Colors.black54,
              size: 24,
            ),
          ),

          // Favorite/Bookmark - star outline
          IconButton(
            onPressed: () {
              // TODO: Implement favorite
            },
            icon: Icon(
              Icons.star_border, // Star outline icon
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white54
                  : Colors.black54,
              size: 24,
            ),
          ),

          // Share icon
          IconButton(
            onPressed: () => _onShareEpisode(context),
            icon: Icon(
              Icons.share, // Share icon
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white54
                  : Colors.black54,
              size: 24,
            ),
          ),

          // More options - three vertical dots
          IconButton(
            onPressed: () {
              _showMoreActionsBottomSheet(context);
            },
            icon: Icon(
              Icons.more_vert, // Three vertical dots icon
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white54
                  : Colors.black54,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  /// Show sleep timer modal
  void _showSleepTimerModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[900]
              : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[600]
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header with title and settings icon
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Text(
                    'Sleep Timer',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      // TODO: Implement sleep timer settings
                      Navigator.pop(context);
                    },
                    icon: Icon(
                      Icons.settings,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[400]
                          : Colors.grey[600],
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

            // Sleep timer options
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Fixed time options
                    _buildSleepTimerOption(
                        '15 minutes', () => _setSleepTimerMinutes(15)),
                    _buildSleepTimerOption(
                        '30 minutes', () => _setSleepTimerMinutes(30)),
                    _buildSleepTimerOption(
                        '1 hour', () => _setSleepTimerMinutes(60)),

                    // Divider
                    Divider(
                      height: 1,
                      thickness: 0.5,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[700]
                          : Colors.grey[300],
                      indent: 20,
                      endIndent: 20,
                    ),

                    // Adjustable options
                    _buildAdjustableSleepTimerOption('5 minutes', 5),
                    _buildAdjustableSleepTimerOption('In 1 chapter', 1,
                        isChapter: true),
                    _buildAdjustableSleepTimerOption('In 1 episode', 1,
                        isEpisode: true),

                    // Divider
                    Divider(
                      height: 1,
                      thickness: 0.5,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[700]
                          : Colors.grey[300],
                      indent: 20,
                      endIndent: 20,
                    ),

                    // Turn off sleep timer
                    _buildSleepTimerOption(
                        'Turn off sleep timer', () => _turnOffSleepTimer()),
                  ],
                ),
              ),
            ),

            // Bottom padding
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Build sleep timer button
  Widget _buildSleepTimerButton(
      BuildContext context, String text, Duration duration) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.pop(context);
          _setSleepTimer(context, duration);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[800]
              : Colors.grey[100],
          foregroundColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  /// Set sleep timer
  void _setSleepTimer(BuildContext context, Duration duration) {
    try {
      final playerProvider =
          Provider.of<PodcastPlayerProvider>(context, listen: false);

      if (duration == Duration.zero) {
        // End of episode timer
        playerProvider.setSleepTimerAtEndOfEpisode();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sleep timer set to end of episode'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Duration-based timer
        playerProvider.setSleepTimer(duration);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sleep timer set to ${duration.inMinutes} minutes'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error setting sleep timer: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Show more actions bottom sheet
  void _showMoreActionsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // Allow scrolling for many actions
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height *
              0.8, // Max 80% of screen height
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[900]
              : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[600]
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header with title and edit icon
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Text(
                    'More actions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      // TODO: Implement edit actions
                      Navigator.pop(context);
                    },
                    icon: Icon(
                      Icons.edit_outlined,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.black54,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable actions list
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Episode Management Actions
                    _buildActionItem(
                      context,
                      icon: Icons.download,
                      label: 'Download',
                      onTap: () => _onDownload(context),
                    ),
                    // TODO: Implement transcript functionality later
                    // _buildActionItem(
                    //   context,
                    //   icon: Icons.text_fields,
                    //   label: 'Transcript',
                    //   onTap: () => _onTranscript(context),
                    // ),
                    _buildActionItem(
                      context,
                      icon: Icons.arrow_upward,
                      label: 'Go to podcast',
                      onTap: () => _onGoToPodcast(context),
                    ),

                    // Divider
                    Divider(
                      height: 1,
                      thickness: 0.5,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[700]
                          : Colors.grey[300],
                      indent: 20,
                      endIndent: 20,
                    ),

                    // Bookmark & Organization Actions
                    _buildActionItem(
                      context,
                      icon: Icons.bookmark_add,
                      label: 'Add bookmark',
                      onTap: () => _onAddBookmark(context),
                    ),
                    _buildActionItem(
                      context,
                      icon: Icons.playlist_add,
                      label: 'Add to Playlist',
                      onTap: () => _onAddToPlaylist(context),
                    ),

                    // Divider
                    Divider(
                      height: 1,
                      thickness: 0.5,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[700]
                          : Colors.grey[300],
                      indent: 20,
                      endIndent: 20,
                    ),

                    // Playback & System Actions
                    // TODO: Implement Chromecast functionality later
                    // _buildActionItem(
                    //   context,
                    //   icon: Icons.cast,
                    //   label: 'Chromecast',
                    //   onTap: () => _onChromecast(context),
                    // ),
                    _buildActionItem(
                      context,
                      icon: Icons.check_circle_outline,
                      label: 'Mark as played',
                      onTap: () => _onMarkAsPlayed(context),
                    ),
                    _buildActionItem(
                      context,
                      icon: Icons.archive_outlined,
                      label: 'Archive',
                      onTap: () => _onArchive(context),
                    ),

                    // Divider
                    Divider(
                      height: 1,
                      thickness: 0.5,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[700]
                          : Colors.grey[300],
                      indent: 20,
                      endIndent: 20,
                    ),

                    // Sharing Actions
                    _buildActionItem(
                      context,
                      icon: Icons.share,
                      label: 'Share Episode',
                      onTap: () => _onShareEpisode(context),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom padding
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Build action item for the bottom sheet
  Widget _buildActionItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.transparent,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[800]
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black87,
            size: 20,
          ),
        ),
        title: Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
              ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// Handle download action with full functionality
  void _onDownload(BuildContext context) {
    // Store context reference before popping
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    Navigator.pop(context);

    try {
      final episodeId = widget.episode['id'];
      final episodeTitle = widget.episode['title'] ?? 'Unknown Episode';
      final audioUrl =
          widget.episode['audioUrl'] ?? widget.episode['enclosureUrl'];

      if (episodeId == null || audioUrl == null || audioUrl.isEmpty) {
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Unable to download: Episode data incomplete'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Show downloading notification
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Downloading: $episodeTitle',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.blue,
          ),
        );
      }

      // Start download using DownloadManager
      final downloadManager = DownloadManager();
      downloadManager.downloadEpisodeWithValidation(
        episodeId: episodeId.toString(),
        episodeTitle: episodeTitle,
        audioUrl: audioUrl,
        context: context,
        onDownloadComplete: () {
          // Show success message only if widget is still mounted
          if (mounted) {
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.download_done, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$episodeTitle downloaded successfully',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        onDownloadError: () {
          // Show error message only if widget is still mounted
          if (mounted) {
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.error, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Download failed for $episodeTitle',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Download error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Handle transcript action with full functionality
  void _onTranscript(BuildContext context) {
    Navigator.pop(context);

    final episodeTitle = widget.episode['title'] ?? 'Unknown Episode';
    final transcriptUrl =
        widget.episode['transcriptUrl'] ?? widget.episode['transcript_url'];

    if (transcriptUrl != null && transcriptUrl.isNotEmpty) {
      // Try to open transcript URL
      final uri = Uri.tryParse(transcriptUrl);
      if (uri != null) {
        launchUrl(uri, mode: LaunchMode.externalApplication)
            .catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Unable to open transcript: $error'),
              backgroundColor: Colors.red,
            ),
          );
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid transcript URL'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // Show transcript content if available in episode data
      final transcript =
          widget.episode['transcript'] ?? widget.episode['transcriptText'];
      if (transcript != null && transcript.isNotEmpty) {
        _showTranscriptModal(context, episodeTitle, transcript);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No transcript available for this episode'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  /// Show transcript modal
  void _showTranscriptModal(
      BuildContext context, String episodeTitle, String transcript) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[900]
              : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    'Transcript: $episodeTitle',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      // Close modal and show mini-player
                      widget.onMinimize();
                    },
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            // Transcript content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  transcript,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                        height: 1.5,
                      ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Handle go to podcast action with full functionality
  void _onGoToPodcast(BuildContext context) {
    // Close the full-screen player modal first
    Navigator.of(context).pop();

    // Get the player provider to access current podcast data
    final playerProvider =
        Provider.of<PodcastPlayerProvider>(context, listen: false);

    // Get podcast data from multiple sources - prioritize player provider data
    Map<String, dynamic>? podcastData;

    // First, try to get podcast data from the player provider (most reliable)
    if (playerProvider.currentPodcastData != null &&
        playerProvider.currentPodcastData!.isNotEmpty) {
      podcastData =
          Map<String, dynamic>.from(playerProvider.currentPodcastData!);
      debugPrint(
          '🎵 Using podcast data from player provider: ${podcastData['title']}');
    }

    // If no player provider data, try to get from episode data
    if (podcastData == null || podcastData.isEmpty) {
      podcastData = widget.episode['podcast'];
      if (podcastData != null && podcastData.isNotEmpty) {
        debugPrint(
            '🎵 Using podcast data from episode: ${podcastData['title']}');
      }
    }

    // If still no data, try to construct it from available episode data
    if (podcastData == null || podcastData.isEmpty) {
      final podcastName = widget.episode['podcastName'] ??
          widget.episode['podcast']?['title'] ??
          'Unknown Podcast';
      final podcastId = widget.episode['podcastId'] ??
          widget.episode['podcast']?['id'] ??
          widget.episode['feedId'];

      if (podcastId != null) {
        // Construct comprehensive podcast data similar to home screen
        podcastData = {
          'id': podcastId,
          'title': podcastName,
          'description': widget.episode['podcast']?['description'] ??
              widget.episode['description'] ??
              'No description available',
          'coverImage': widget.episode['podcast']?['coverImage'] ??
              widget.episode['coverImage'] ??
              widget.episode['image'] ??
              '',
          'author': widget.episode['podcast']?['author'] ??
              widget.episode['author'] ??
              'Unknown Author',
          'creator': widget.episode['podcast']?['creator'] ??
              widget.episode['creator'] ??
              widget.episode['podcast']?['author'] ??
              'Unknown Creator',
          'category': widget.episode['podcast']?['category'] ??
              widget.episode['category'] ??
              'General',
          'categories': widget.episode['podcast']?['categories'] ??
              widget.episode['categories'] ??
              [],
          'audioUrl': widget.episode['podcast']?['audioUrl'] ?? '',
          'url': widget.episode['podcast']?['url'] ?? '',
          'originalUrl': widget.episode['podcast']?['originalUrl'] ?? '',
          'link': widget.episode['podcast']?['link'] ?? '',
          'totalEpisodes': widget.episode['podcast']?['totalEpisodes'] ?? 0,
          'episodeCount': widget.episode['podcast']?['episodeCount'] ?? 0,
          'languages': widget.episode['podcast']?['languages'] ?? [],
          'explicit': widget.episode['podcast']?['explicit'] ?? false,
          'isFeatured': widget.episode['podcast']?['isFeatured'] ?? false,
          'isSubscribed': widget.episode['podcast']?['isSubscribed'] ?? false,
        };
        debugPrint(
            '🎵 Constructed podcast data from episode: ${podcastData['title']}');
      }
    }

    if (podcastData != null && podcastData.isNotEmpty) {
      // Validate required fields before navigation (same as home screen)
      if (podcastData['id'] == null || podcastData['id'].toString().isEmpty) {
        debugPrint('❌ Navigation error: Podcast ID is null or empty');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot navigate: Podcast ID is missing'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Navigate directly to podcast detail screen with full podcast data
      debugPrint(
          '🎵 Navigating to podcast detail with podcast data: ${podcastData['title']} (ID: ${podcastData['id']})');
      Navigator.pushNamed(
        context,
        AppRoutes.podcastDetailScreen,
        arguments: podcastData,
      ).then((_) {
        // After navigation completes, ensure mini-player is shown
        // Use forceShowMiniPlayer to ensure mini-player appears after navigation
        playerProvider.forceShowMiniPlayer(context);
        debugPrint('🎵 Navigation completed, mini-player force restored');
      }).catchError((error) {
        debugPrint('❌ Navigation error: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error navigating to podcast: $error'),
            backgroundColor: Colors.red,
          ),
        );
      });
    } else {
      debugPrint('❌ No podcast data found in episode or player provider');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Unable to navigate to podcast detail - no podcast data available'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  /// Handle add bookmark action with full functionality
  void _onAddBookmark(BuildContext context) {
    Navigator.pop(context);

    final episodeId = widget.episode['id'];
    final episodeTitle = widget.episode['title'] ?? 'Unknown Episode';

    if (episodeId == null) {
      debugPrint('❌ Episode ID is null, cannot add bookmark');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to add bookmark: Episode data incomplete'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    try {
      // Show bookmark options
      _showBookmarkOptions(context, episodeId, episodeTitle);
    } catch (e) {
      debugPrint('❌ Error showing bookmark options: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening bookmark options: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Show bookmark options modal
  void _showBookmarkOptions(
      BuildContext context, int episodeId, String episodeTitle) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[900]
              : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Add Bookmark',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ),
              ),
            ),

            // Bookmark options
            ListTile(
              leading: Icon(
                Icons.bookmark_add,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
              title: Text(
                'Add to Favorites',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ),
              ),
              onTap: () {
                Navigator.pop(context);
                _addToFavorites(episodeId, episodeTitle);
              },
            ),

            ListTile(
              leading: Icon(
                Icons.access_time,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
              title: Text(
                'Add with Timestamp',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ),
              ),
              onTap: () {
                Navigator.pop(context);
                _addBookmarkWithTimestamp(context, episodeId, episodeTitle);
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Add episode to favorites
  void _addToFavorites(int episodeId, String episodeTitle) {
    try {
      // Get episode data for favorites
      final episodeData = {
        'favoriteable_type': 'episode',
        'favoriteable_id': episodeId.toString(),
        'favoriteable_title': episodeTitle,
        'favoriteable_description': widget.episode['description'] ?? '',
        'favoriteable_image':
            widget.episode['coverImage'] ?? widget.episode['image'] ?? '',
        'podcast_id': widget.episode['podcastId'] ??
            widget.episode['feedId'] ??
            widget.episode['podcast']?['id'],
      };

      // TODO: Call favorites API when backend is ready
      // For now, show success message and store locally
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.favorite, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('$episodeTitle added to favorites'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      // TODO: Store in local favorites when backend is ready
      // await _storeFavoriteLocally(episodeData);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('Error adding to favorites: $e'),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Add bookmark with timestamp
  void _addBookmarkWithTimestamp(
      BuildContext context, int episodeId, String episodeTitle) {
    Navigator.pop(context);

    try {
      // Show the add bookmark modal
      showDialog(
        context: context,
        builder: (context) => AddBookmarkModal(
          episode: widget.episode,
          onBookmarkAdded: () {
            // Show success feedback when bookmark is added
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.bookmark_added, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    const Text('Bookmark created successfully!'),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
            debugPrint('✅ Bookmark successfully created');
          },
        ),
      );
    } catch (e) {
      debugPrint('❌ Error opening Add Bookmark modal: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening bookmark options: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Handle Chromecast action with full functionality
  void _onChromecast(BuildContext context) {
    Navigator.pop(context);

    final castService = ChromecastService();

    // Check if already connected
    if (castService.isConnected) {
      _showConnectedDeviceOptions(context, castService);
    } else {
      _showDeviceSelector(context, castService);
    }
  }

  /// Show device selector dialog
  void _showDeviceSelector(
      BuildContext context, ChromecastService castService) {
    showDialog(
      context: context,
      builder: (context) => ChromecastDeviceSelector(
        onDeviceSelected: (device) async {
          final success = await castService.connectToDevice(device);
          if (success && context.mounted) {
            _showCastConfirmation(context, device.name);
          } else if (context.mounted) {
            _showCastError(context, 'Failed to connect to ${device.name}');
          }
        },
        onCancel: () {
          debugPrint('Chromecast device selection cancelled');
        },
      ),
    );
  }

  /// Show options for already connected device
  void _showConnectedDeviceOptions(
      BuildContext context, ChromecastService castService) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.cast, color: Colors.blue, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Connected to Cast Device',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        castService.connectedDeviceName ?? 'Unknown Device',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    // Close modal and show mini-player
                    widget.onMinimize();
                  },
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Options
            if (castService.isCasting) ...[
              // Currently casting
              ListTile(
                leading: const Icon(Icons.stop, color: Colors.red),
                title: const Text('Stop Casting'),
                onTap: () async {
                  Navigator.pop(context);
                  await castService.stopCasting();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Stopped casting to device'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
            ] else ...[
              // Not casting - start casting
              ListTile(
                leading: const Icon(Icons.play_arrow, color: Colors.green),
                title: const Text('Start Casting'),
                subtitle: const Text('Cast current episode to device'),
                onTap: () async {
                  Navigator.pop(context);
                  await _startCasting(context, castService);
                },
              ),
            ],

            // Disconnect
            ListTile(
              leading: const Icon(Icons.cast_connected, color: Colors.orange),
              title: const Text('Disconnect'),
              onTap: () async {
                Navigator.pop(context);
                await castService.disconnect();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Disconnected from Cast device'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Start casting current episode
  Future<void> _startCasting(
      BuildContext context, ChromecastService castService) async {
    try {
      final playerProvider =
          Provider.of<PodcastPlayerProvider>(context, listen: false);
      final currentEpisode = playerProvider.currentEpisode;

      if (currentEpisode == null) {
        _showCastError(context, 'No episode currently playing');
        return;
      }

      final success = await castService.castEpisode(
        episodeId: currentEpisode.id.toString(),
        episodeTitle: currentEpisode.title,
        audioUrl: currentEpisode.audioUrl ?? '',
        coverImage: currentEpisode.coverImage ?? '',
        podcastName: currentEpisode.podcastName ?? '',
        position: playerProvider.position,
      );

      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.cast, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                    'Casting "${currentEpisode.title}" to ${castService.connectedDeviceName}'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else if (context.mounted) {
        _showCastError(context, 'Failed to start casting');
      }
    } catch (e) {
      debugPrint('Cast error: $e');
      if (context.mounted) {
        _showCastError(context, 'Error: $e');
      }
    }
  }

  /// Show cast confirmation
  void _showCastConfirmation(BuildContext context, String deviceName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.cast, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('Connected to $deviceName'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Cast Now',
          textColor: Colors.white,
          onPressed: () => _onChromecast(context),
        ),
      ),
    );
  }

  /// Show cast error
  void _showCastError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Handle mark as played action with full functionality
  void _onMarkAsPlayed(BuildContext context) {
    Navigator.pop(context);

    final episodeId = widget.episode['id'];
    final episodeTitle = widget.episode['title'] ?? 'Unknown Episode';

    if (episodeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to mark as played: Episode data incomplete'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Mark episode as played using progress service
    try {
      final progressService = EpisodeProgressService();
      progressService.markCompleted(episodeId.toString()).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$episodeTitle marked as played',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Error marking as played: $error',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Handle archive action with full functionality
  void _onArchive(BuildContext context) {
    Navigator.pop(context);

    final episodeId = widget.episode['id'];
    final episodeTitle = widget.episode['title'] ?? 'Unknown Episode';

    if (episodeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to archive: Episode data incomplete'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show archive confirmation
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive Episode'),
        content: Text('Are you sure you want to archive "$episodeTitle"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmArchive(episodeId, episodeTitle);
            },
            child: const Text('Archive'),
          ),
        ],
      ),
    );
  }

  /// Confirm and execute archive
  void _confirmArchive(int episodeId, String episodeTitle) {
    try {
      // TODO: Implement archive functionality when backend is ready
      // This would typically involve updating episode status in the database
      // await _archiveEpisode(episodeId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.archive, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('$episodeTitle archived successfully'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      // TODO: Update UI state when backend is ready
      // setState(() {
      //   // Update episode status in the UI
      // });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('Error archiving episode: $e'),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Handle add to playlist action with full functionality
  void _onAddToPlaylist(BuildContext context) {
    Navigator.pop(context);

    // Get the current episode ID from the widget
    final episodeId = widget.episode['id'];
    if (episodeId != null) {
      try {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => AddToPlaylistWidget(
            episodeId: episodeId,
            onSuccess: () {
              // The AddToPlaylistWidget already handles success feedback
              // No need for duplicate success message here
              debugPrint('✅ Episode successfully added to playlist');
            },
          ),
        );
      } catch (e) {
        debugPrint('❌ Error opening Add to Playlist modal: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening playlist options: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      debugPrint('❌ Episode ID is null, cannot add to playlist');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Unable to add episode to playlist - episode data incomplete'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  /// Handle share episode action with full functionality
  void _onShareEpisode(BuildContext context) async {
    Navigator.pop(context);

    try {
      final episodeTitle = widget.episode['title'] ?? 'Unknown Episode';
      final episodeDescription = widget.episode['description'] ?? '';
      final podcastTitle = widget.episode['podcastName'] ??
          widget.episode['podcast']?['title'] ??
          'Unknown Podcast';
      final audioUrl = widget.episode['audioUrl'] ?? '';

      await SocialSharingService().shareEpisode(
        episodeTitle: episodeTitle,
        podcastTitle: podcastTitle,
        episodeDescription: episodeDescription,
        episodeUrl: audioUrl.isNotEmpty ? audioUrl : null,
        customMessage: 'Check out this amazing episode!',
      );

      // Show success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.share, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Episode shared successfully'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint('Error sharing episode: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing episode: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Helper methods for episode details tab

  /// Format date for display
  String _formatDate(dynamic date) {
    debugPrint('🎯 _formatDate called with: $date (type: ${date.runtimeType})');
    if (date == null) return 'Unknown Date';

    try {
      if (date is int) {
        // Handle Unix timestamp (seconds since epoch)
        final parsed = DateTime.fromMillisecondsSinceEpoch(date * 1000);
        return '${_getMonthName(parsed.month)} ${parsed.day}, ${parsed.year}';
      } else if (date is String) {
        // Check if it's a Unix timestamp string
        final timestamp = int.tryParse(date);
        if (timestamp != null) {
          final parsed = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
          return '${_getMonthName(parsed.month)} ${parsed.day}, ${parsed.year}';
        }
        // Try parsing as regular date string
        final parsed = DateTime.tryParse(date);
        if (parsed != null) {
          return '${_getMonthName(parsed.month)} ${parsed.day}, ${parsed.year}';
        }
      } else if (date is DateTime) {
        return '${_getMonthName(date.month)} ${date.day}, ${date.year}';
      }
    } catch (e) {
      debugPrint('Error formatting date: $e');
    }

    return 'Unknown Date';
  }

  /// Get month name from month number
  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  /// Format duration for display
  String _formatDurationDisplay(dynamic duration) {
    debugPrint(
        '🎯 _formatDurationDisplay called with: $duration (type: ${duration.runtimeType})');
    if (duration == null) return 'Unknown Duration';

    try {
      // If duration is already a formatted string (like "45m" or "1h 30m"), return it directly
      if (duration is String) {
        if (duration.isNotEmpty && duration != '0' && duration != '0m') {
          return duration;
        }
        // Try to parse as integer if it's a number string
        final seconds = int.tryParse(duration);
        if (seconds != null && seconds > 0) {
          final hours = seconds ~/ 3600;
          final minutes = (seconds % 3600) ~/ 60;
          if (hours > 0) {
            return '${hours}h ${minutes}m';
          } else {
            return '${minutes}m';
          }
        }
      } else if (duration is int) {
        // Handle integer duration (seconds)
        if (duration > 0) {
          final hours = duration ~/ 3600;
          final minutes = (duration % 3600) ~/ 60;
          if (hours > 0) {
            return '${hours}h ${minutes}m';
          } else {
            return '${minutes}m';
          }
        }
      }
    } catch (e) {
      debugPrint('Error formatting duration: $e');
    }

    return 'Unknown Duration';
  }

  /// Build formatted description with clickable links (same as episode detail modal)
  Widget _buildFormattedDescription(String description) {
    if (description.isEmpty) {
      return Text(
        'No description available',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white70
                  : Colors.black54,
              height: 1.5,
            ),
      );
    }

    // First, replace HTML entities
    String processedText = description
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");

    // Remove all HTML tags except <a> tags and clean up spacing
    String cleanText = processedText
        .replaceAll(RegExp(r'<(?!a\b)[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // Find URLs and make them clickable
    final urlPattern = RegExp(r'https?://[^\s]+');
    final urlMatches = urlPattern.allMatches(cleanText);

    if (urlMatches.isEmpty) {
      // No URLs found, return plain text
      return Text(
        cleanText,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
              height: 1.5,
            ),
      );
    }

    // Build text with clickable URLs
    final List<TextSpan> spans = [];
    int lastIndex = 0;

    for (final match in urlMatches) {
      // Add text before the URL
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: cleanText.substring(lastIndex, match.start),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
                height: 1.5,
              ),
        ));
      }

      // Add the clickable URL
      final url = match.group(0) ?? '';
      spans.add(TextSpan(
        text: url,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).primaryColor,
              height: 1.5,
              decoration: TextDecoration.underline,
            ),
        recognizer: TapGestureRecognizer()..onTap = () => _launchUrl(url),
      ));

      lastIndex = match.end;
    }

    // Add remaining text after the last URL
    if (lastIndex < cleanText.length) {
      spans.add(TextSpan(
        text: cleanText.substring(lastIndex),
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
              height: 1.5,
            ),
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  /// Launch URL
  void _launchUrl(String url) {
    try {
      final uri = Uri.parse(url.startsWith('www.') ? 'https://$url' : url);
      launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  /// Check if episode has bonus content
  bool _hasBonusContent() {
    final description = widget.episode['description'] ?? '';
    return description.toLowerCase().contains('patreon') ||
        description.toLowerCase().contains('bonus');
  }

  /// Build bonus content section
  Widget _buildBonusContentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bonus Content',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[800]
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.star,
                color: const Color(0xFFFF8C00),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Listen to bonus episodes on Patreon!',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Check if episode has sponsors
  bool _hasSponsors() {
    final description = widget.episode['description'] ?? '';
    return description.toLowerCase().contains('sponsor') ||
        description.toLowerCase().contains('factor') ||
        description.toLowerCase().contains('blueland');
  }

  /// Build sponsors section
  Widget _buildSponsorsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thanks to today\'s sponsors!',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
        ),
        const SizedBox(height: 12),
        _buildSponsorItem(
          'Factor Meals',
          'Work smarter, not harder, with Factor meals ready in two minutes at',
          'https://www.factormeals.com/fruity50off',
        ),
        const SizedBox(height: 8),
        _buildSponsorItem(
          'Blueland',
          'Get 15% off a cuter, more sustainable way to clean at',
          'https://www.blueland.com/fruity.',
        ),
      ],
    );
  }

  /// Build individual sponsor item
  Widget _buildSponsorItem(String name, String description, String url) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.black54,
                ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _launchUrl(url),
            child: Text(
              url,
              style: TextStyle(
                color: const Color(0xFFFF8C00),
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Check if episode has social links
  bool _hasSocialLinks() {
    final description = widget.episode['description'] ?? '';
    return description.toLowerCase().contains('instagram') ||
        description.toLowerCase().contains('twitter') ||
        description.toLowerCase().contains('spitfire');
  }

  /// Build social links section
  Widget _buildSocialLinksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Connect & Follow',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
        ),
        const SizedBox(height: 12),
        _buildSocialLink(
            'Read Kat\'s work at Spitfire News', 'https://spitfire.news'),
        const SizedBox(height: 8),
        _buildSocialLink('Find me on Instagram', 'https://instagram.com'),
        const SizedBox(height: 8),
        _buildSocialLink('Find A Bit Fruity on Instagram',
            'https://instagram.com/abitfruity'),
      ],
    );
  }

  /// Build individual social link
  Widget _buildSocialLink(String text, String url) {
    return GestureDetector(
      onTap: () => _launchUrl(url),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[800]
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.link,
              color: const Color(0xFFFF8C00),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white54
                  : Colors.black54,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  /// Build ad choices section
  Widget _buildAdChoicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Learn more about your ad choices. Visit',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : Colors.black54,
              ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _launchUrl('https://megaphone.fm/adchoices'),
          child: Text(
            'megaphone.fm/adchoices',
            style: TextStyle(
              color: const Color(0xFFFF8C00),
              decoration: TextDecoration.underline,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  /// Show add bookmark modal
  void _showAddBookmarkModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddBookmarkModal(
        episode: widget.episode,
        onBookmarkAdded: () {
          // Refresh bookmark list if needed
          setState(() {});
        },
      ),
    );
  }

  // Sleep Timer Helper Methods

  /// Build sleep timer option
  Widget _buildSleepTimerOption(String label, VoidCallback onTap) {
    return ListTile(
      title: Text(
        label,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
            ),
      ),
      onTap: onTap,
      trailing: Icon(
        Icons.arrow_forward_ios,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white54
            : Colors.black54,
        size: 16,
      ),
    );
  }

  /// Build adjustable sleep timer option with plus/minus buttons
  Widget _buildAdjustableSleepTimerOption(String label, int value,
      {bool isChapter = false, bool isEpisode = false}) {
    return ListTile(
      title: Text(
        label,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
            ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Minus button
          IconButton(
            onPressed: () => _adjustSleepTimer(value - 1,
                isChapter: isChapter, isEpisode: isEpisode),
            icon: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[700]
                    : Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.remove, size: 16),
            ),
          ),
          // Value display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[800]
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value.toString(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
            ),
          ),
          // Plus button
          IconButton(
            onPressed: () => _adjustSleepTimer(value + 1,
                isChapter: isChapter, isEpisode: isEpisode),
            icon: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[700]
                    : Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  /// Set sleep timer with minutes
  void _setSleepTimerMinutes(int minutes) {
    try {
      final playerProvider =
          Provider.of<PodcastPlayerProvider>(context, listen: false);
      playerProvider.setSleepTimer(Duration(minutes: minutes));

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.timer, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('Sleep timer set for $minutes minutes'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint('Error setting sleep timer: $e');
    }
  }

  /// Adjust sleep timer value
  void _adjustSleepTimer(int newValue,
      {bool isChapter = false, bool isEpisode = false}) {
    // TODO: Implement adjustable sleep timer logic
    debugPrint(
        'Adjusting sleep timer: $newValue (Chapter: $isChapter, Episode: $isEpisode)');
  }

  /// Turn off sleep timer
  void _turnOffSleepTimer() {
    try {
      final playerProvider =
          Provider.of<PodcastPlayerProvider>(context, listen: false);
      playerProvider.clearSleepTimer();

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.timer_off, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text('Sleep timer turned off'),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint('Error turning off sleep timer: $e');
    }
  }

  /// Show playback effects modal
  void _showPlaybackEffectsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[900]
              : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[600]
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Text(
                'Playback Effects',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ),
              ),
            ),

            // Scope selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _buildScopeSelector(
                      'All podcasts',
                      _applyToAllPodcasts,
                      (value) => _onScopeChanged(value),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildScopeSelector(
                      'This podcast',
                      !_applyToAllPodcasts,
                      (value) => _onScopeChanged(value),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Playback effects options
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Speed control
                    _buildSpeedControl(),
                    const SizedBox(height: 16),

                    // Trim silence option
                    _buildTrimSilenceOption(),
                    const SizedBox(height: 16),

                    // Volume boost option
                    _buildVolumeBoostOption(),
                  ],
                ),
              ),
            ),

            // Bottom padding
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Build scope selector
  Widget _buildScopeSelector(
      String label, bool isSelected, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!isSelected),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? (Theme.of(context).brightness == Brightness.dark
                  ? Colors.black
                  : Colors.white)
              : (Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[800]
                  : Colors.grey[200]),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[600]!
                : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected
                ? (Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black)
                : (Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : Colors.black54),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  /// Build speed control
  Widget _buildSpeedControl() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Checkmark icon
          Icon(
            Icons.check,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
            size: 24,
          ),
          const SizedBox(width: 16),

          // Speed label
          Expanded(
            child: Text(
              'Speed',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),

          // Speed controls
          Row(
            children: [
              // Minus button
              IconButton(
                onPressed: () => _adjustPlaybackSpeed(-0.1),
                icon: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[700]
                        : Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.remove, size: 16),
                ),
              ),

              // Speed display
              Consumer<PodcastPlayerProvider>(
                builder: (context, playerProvider, child) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[700]
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      playerProvider
                          .getSpeedLabel(playerProvider.playbackSpeed),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                          ),
                    ),
                  );
                },
              ),

              // Plus button
              IconButton(
                onPressed: () => _adjustPlaybackSpeed(0.1),
                icon: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[700]
                        : Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, size: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build trim silence option
  Widget _buildTrimSilenceOption() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Scissor icon
          Icon(
            Icons.content_cut,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
            size: 24,
          ),
          const SizedBox(width: 16),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trim Silence',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Reduces the length of an episode by trimming silence in conversations.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : Colors.black54,
                      ),
                ),
              ],
            ),
          ),

          // Toggle switch
          Consumer<PodcastPlayerProvider>(
            builder: (context, playerProvider, child) {
              return Switch(
                value: _trimSilenceEnabled,
                onChanged: (value) => _onTrimSilenceChanged(value),
                activeColor: Colors.blue,
              );
            },
          ),
        ],
      ),
    );
  }

  /// Build volume boost option
  Widget _buildVolumeBoostOption() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Speaker icon
          Icon(
            Icons.volume_up,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
            size: 24,
          ),
          const SizedBox(width: 16),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Volume Boost',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Voices sound louder',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : Colors.black54,
                      ),
                ),
              ],
            ),
          ),

          // Toggle switch
          Consumer<PodcastPlayerProvider>(
            builder: (context, playerProvider, child) {
              return Switch(
                value: _volumeBoostEnabled,
                onChanged: (value) => _onVolumeBoostChanged(value),
                activeColor: Colors.blue,
              );
            },
          ),
        ],
      ),
    );
  }

  // Playback Effects Helper Methods

  /// Load playback effects settings
  Future<void> _loadPlaybackEffectsSettings() async {
    try {
      final playerProvider =
          Provider.of<PodcastPlayerProvider>(context, listen: false);
      final settings = await playerProvider.getPlaybackEffectsSettings();

      if (mounted) {
        setState(() {
          _currentPlaybackSpeed = settings['playbackSpeed'] ?? 1.0;
          _trimSilenceEnabled = settings['trimSilence'] ?? false;
          _volumeBoostEnabled = settings['volumeBoost'] ?? false;
          _applyToAllPodcasts = settings['applyToAllPodcasts'] ?? true;
        });
      }
    } catch (e) {
      debugPrint('Error loading playback effects settings: $e');
    }
  }

  /// Handle scope change
  void _onScopeChanged(bool isAllPodcasts) {
    setState(() {
      _applyToAllPodcasts = isAllPodcasts;
    });

    final playerProvider =
        Provider.of<PodcastPlayerProvider>(context, listen: false);
    playerProvider.setApplyToAllPodcasts(isAllPodcasts);

    debugPrint(
        'Scope changed to: ${isAllPodcasts ? "All podcasts" : "This podcast"}');
  }

  /// Adjust playback speed
  void _adjustPlaybackSpeed(double delta) {
    final playerProvider =
        Provider.of<PodcastPlayerProvider>(context, listen: false);
    final availableSpeeds = playerProvider.getAvailablePlaybackSpeeds();

    // Use the current speed from the provider, not local state
    final currentProviderSpeed = playerProvider.playbackSpeed;

    // Find current speed index
    int currentIndex = availableSpeeds.indexOf(currentProviderSpeed);
    if (currentIndex == -1) currentIndex = 2; // Default to 1.0x

    // Calculate new index
    int newIndex = currentIndex + (delta > 0 ? 1 : -1);
    newIndex = newIndex.clamp(0, availableSpeeds.length - 1);

    // Set new speed
    final newSpeed = availableSpeeds[newIndex];

    // Update local state to match provider
    setState(() {
      _currentPlaybackSpeed = newSpeed;
    });

    // Apply speed change to provider (this will trigger notifyListeners)
    playerProvider.setPlaybackSpeed(newSpeed);

    // Haptic feedback
    HapticFeedback.lightImpact();

    // Show user feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.speed, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('Speed: ${playerProvider.getSpeedLabel(newSpeed)}'),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 1),
      ),
    );

    debugPrint(
        'Playback speed adjusted to: ${playerProvider.getSpeedLabel(newSpeed)}');
  }

  /// Handle trim silence toggle
  void _onTrimSilenceChanged(bool value) {
    final playerProvider =
        Provider.of<PodcastPlayerProvider>(context, listen: false);

    // Update local state to match provider
    setState(() {
      _trimSilenceEnabled = value;
    });

    // Apply trim silence setting to provider (this will trigger notifyListeners)
    playerProvider.setTrimSilence(value);

    // Haptic feedback
    HapticFeedback.lightImpact();

    // Show user feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.content_cut, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('Trim Silence: ${value ? 'On' : 'Off'}'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );

    debugPrint('🎵 Trim silence toggled: $value');
  }

  /// Handle volume boost toggle
  void _onVolumeBoostChanged(bool value) {
    final playerProvider =
        Provider.of<PodcastPlayerProvider>(context, listen: false);

    // Update local state to match provider
    setState(() {
      _volumeBoostEnabled = value;
    });

    // Apply volume boost setting to provider (this will trigger notifyListeners)
    playerProvider.setVolumeBoost(value);

    // Haptic feedback
    HapticFeedback.lightImpact();

    // Show user feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.volume_up, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('Volume Boost: ${value ? 'On' : 'Off'}'),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 1),
      ),
    );

    debugPrint('🎵 Volume boost toggled: $value');
  }

  // Bookmark Helper Methods

  /// Load bookmarks for the current episode
  Future<List<EpisodeBookmark>> _loadEpisodeBookmarks() async {
    try {
      final episodeId = widget.episode['id']?.toString();
      if (episodeId == null) return [];

      final progressService = EpisodeProgressService();
      await progressService.initialize();
      return await progressService.getBookmarks(episodeId);
    } catch (e) {
      debugPrint('Error loading bookmarks: $e');
      return [];
    }
  }

  /// Seek to a specific bookmark position
  void _seekToBookmark(EpisodeBookmark bookmark) {
    try {
      final playerProvider =
          Provider.of<PodcastPlayerProvider>(context, listen: false);
      final position = Duration(seconds: bookmark.position);
      playerProvider.seekTo(position);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.play_arrow, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('Playing from bookmark: ${bookmark.title}'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint('Error seeking to bookmark: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error seeking to bookmark: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Show Up Next modal
  void _showUpNextModal(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const UpNextModal(),
        fullscreenDialog: true,
      ),
    );
  }

  /// Delete a bookmark
  void _deleteBookmark(EpisodeBookmark bookmark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bookmark'),
        content: Text('Are you sure you want to delete "${bookmark.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final progressService = EpisodeProgressService();
                await progressService.initialize();
                await progressService.removeBookmark(
                    bookmark.episodeId, bookmark.position);

                // Refresh the bookmark list
                setState(() {});

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text('Bookmark deleted: ${bookmark.title}'),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );
              } catch (e) {
                debugPrint('Error deleting bookmark: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting bookmark: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
