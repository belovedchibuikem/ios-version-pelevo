import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../core/app_export.dart';
import '../providers/podcast_player_provider.dart';
import '../services/audio_player_service.dart';
import '../services/social_sharing_service.dart';
import '../data/models/episode.dart';
import 'episode_seek_bar.dart';

class PodcastPlayer extends StatefulWidget {
  const PodcastPlayer({super.key});

  @override
  State<PodcastPlayer> createState() => _PodcastPlayerState();
}

class _PodcastPlayerState extends State<PodcastPlayer>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final AudioPlayerService _audioService = AudioPlayerService();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeAudioService();
  }

  Future<void> _initializeAudioService() async {
    try {
      final playerProvider =
          Provider.of<PodcastPlayerProvider>(context, listen: false);
      await _audioService.initialize(playerProvider: playerProvider);
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('Error initializing audio service: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PodcastPlayerProvider>(
      builder: (context, playerProvider, child) {
        // Don't show player if no episode is loaded
        if (playerProvider.currentEpisode == null) {
          return const SizedBox.shrink();
        }

        // Show minimized player at bottom
        if (playerProvider.isMinimized) {
          return _buildMinimizedPlayer(playerProvider);
        }

        // Show full player (either modal or full screen)
        if (playerProvider.isEpisodeDetailModalOpen) {
          return _buildEpisodeDetailModal(playerProvider);
        } else {
          return _buildFullPlayer(playerProvider);
        }
      },
    );
  }

  // MARK: - Minimized Player (Bottom Floating)
  Widget _buildMinimizedPlayer(PodcastPlayerProvider playerProvider) {
    final episode = playerProvider.currentEpisode!;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 80,
        margin: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => playerProvider.setMinimized(false),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: EdgeInsets.all(3.w),
              child: Row(
                children: [
                  // Episode Artwork
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: episode.coverImage != null
                          ? DecorationImage(
                              image: NetworkImage(episode.coverImage!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: episode.coverImage == null
                        ? Icon(
                            Icons.mic,
                            color: AppTheme.lightTheme.colorScheme.primary,
                            size: 24,
                          )
                        : null,
                  ),

                  SizedBox(width: 3.w),

                  // Episode Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          episode.title,
                          style: AppTheme.lightTheme.textTheme.titleSmall
                              ?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          episode.podcastName ?? 'Unknown Podcast',
                          style:
                              AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Playback Controls
                  Row(
                    children: [
                      // Skip Backward
                      IconButton(
                        onPressed: () {
                          final newPosition = playerProvider.position -
                              const Duration(seconds: 10);
                          if (newPosition >= Duration.zero) {
                            _audioService.seekTo(newPosition);
                          }
                        },
                        icon: Icon(
                          Icons.replay_10,
                          color: AppTheme.lightTheme.colorScheme.onSurface,
                        ),
                        iconSize: 24,
                      ),

                      // Play/Pause
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.lightTheme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () {
                            if (playerProvider.isPlaying) {
                              _audioService.pause();
                            } else {
                              _audioService.play();
                            }
                          },
                          icon: Icon(
                            playerProvider.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                            color: Colors.white,
                          ),
                          iconSize: 28,
                        ),
                      ),

                      // Skip Forward
                      IconButton(
                        onPressed: () {
                          final newPosition = playerProvider.position +
                              const Duration(seconds: 30);
                          if (newPosition <= playerProvider.duration) {
                            _audioService.seekTo(newPosition);
                          }
                        },
                        icon: Icon(
                          Icons.forward_30,
                          color: AppTheme.lightTheme.colorScheme.onSurface,
                        ),
                        iconSize: 24,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // MARK: - Episode Detail Modal
  Widget _buildEpisodeDetailModal(PodcastPlayerProvider playerProvider) {
    final episode = playerProvider.currentEpisode!;

    return SafeAreaUtils.wrapWithSafeArea(
      Container(
        color: AppTheme.lightTheme.colorScheme.surface,
        child: Column(
          children: [
            // Header with close button
            Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.lightTheme.colorScheme.outline
                        .withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => playerProvider.closeEpisodeDetailModal(),
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: AppTheme.lightTheme.colorScheme.onSurface,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Episode Details',
                      style:
                          AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // TODO: Implement favorite functionality
                    },
                    icon: Icon(
                      Icons.favorite_border,
                      color: AppTheme.lightTheme.colorScheme.onSurface,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _shareCurrentEpisode(),
                    icon: Icon(
                      Icons.share,
                      color: AppTheme.lightTheme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),

            // Tab Bar
            Container(
              color: AppTheme.lightTheme.colorScheme.surface,
              child: TabBar(
                controller: _tabController,
                labelColor: AppTheme.lightTheme.colorScheme.primary,
                unselectedLabelColor:
                    AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                indicatorColor: AppTheme.lightTheme.colorScheme.primary,
                tabs: [
                  const Tab(text: 'Details'),
                  const Tab(text: 'Bookmarks'),
                  // Now Playing tab only shows when playing
                  if (playerProvider.isPlaying) const Tab(text: 'Now Playing'),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDetailsTab(episode, playerProvider),
                  _buildBookmarksTab(episode, playerProvider),
                  if (playerProvider.isPlaying)
                    _buildNowPlayingTab(episode, playerProvider),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // MARK: - Full Player Screen
  Widget _buildFullPlayer(PodcastPlayerProvider playerProvider) {
    final episode = playerProvider.currentEpisode!;

    return Scaffold(
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => playerProvider.setMinimized(true),
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: AppTheme.lightTheme.colorScheme.onSurface,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Now Playing',
                      style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // TODO: Implement more options
                    },
                    icon: Icon(
                      Icons.more_vert,
                      color: AppTheme.lightTheme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),

            // Tab Bar
            Container(
              color: AppTheme.lightTheme.colorScheme.surface,
              child: TabBar(
                controller: _tabController,
                labelColor: AppTheme.lightTheme.colorScheme.primary,
                unselectedLabelColor:
                    AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                indicatorColor: AppTheme.lightTheme.colorScheme.primary,
                tabs: [
                  const Tab(text: 'Now Playing'),
                  const Tab(text: 'Details'),
                  const Tab(text: 'Bookmarks'),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildNowPlayingTab(episode, playerProvider),
                  _buildDetailsTab(episode, playerProvider),
                  _buildBookmarksTab(episode, playerProvider),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // MARK: - Tab Content Widgets

  Widget _buildNowPlayingTab(
      Episode episode, PodcastPlayerProvider playerProvider) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        children: [
          // Episode Artwork
          Container(
            width: 80.w,
            height: 80.w,
            margin: EdgeInsets.only(bottom: 4.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: episode.coverImage != null
                  ? DecorationImage(
                      image: NetworkImage(episode.coverImage!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: episode.coverImage == null
                ? Icon(
                    Icons.mic,
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 48,
                  )
                : null,
          ),

          // Episode Title
          Text(
            episode.title,
            style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),

          SizedBox(height: 1.h),

          // Podcast Name
          Text(
            episode.podcastName ?? 'Unknown Podcast',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 4.h),

          // Progress Bar
          EpisodeSeekBar(
            progress: playerProvider.progressPercentage,
            currentPosition: playerProvider.position.inMilliseconds,
            totalDuration: playerProvider.duration.inMilliseconds,
            bookmarks: [], // TODO: Load bookmarks for this episode
            onSeek: (progress) {
              final newPosition = Duration(
                milliseconds:
                    (progress * playerProvider.duration.inMilliseconds).round(),
              );
              _audioService.seekTo(newPosition);
            },
            onBookmarkTap: (position, title) {
              // TODO: Handle bookmark tap
            },
            onBookmarkAdd: (position, title, notes) {
              // TODO: Handle bookmark add
            },
            isPlaying: playerProvider.isPlaying,
            showBookmarks: true,
          ),

          SizedBox(height: 2.h),

          // Time Display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                playerProvider.formattedPosition,
                style: AppTheme.lightTheme.textTheme.bodyMedium,
              ),
              Text(
                playerProvider.formattedRemainingTime,
                style: AppTheme.lightTheme.textTheme.bodyMedium,
              ),
            ],
          ),

          SizedBox(height: 4.h),

          // Playback Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Shuffle
              IconButton(
                onPressed: () => playerProvider.toggleShuffle(),
                icon: Icon(
                  Icons.shuffle,
                  color: playerProvider.isShuffled
                      ? AppTheme.lightTheme.colorScheme.primary
                      : AppTheme.lightTheme.colorScheme.onSurface,
                ),
                iconSize: 28,
              ),

              // Previous
              IconButton(
                onPressed: () {
                  // TODO: Implement previous episode
                },
                icon: Icon(
                  Icons.skip_previous,
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                ),
                iconSize: 32,
              ),

              // Play/Pause
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () {
                    if (playerProvider.isPlaying) {
                      _audioService.pause();
                    } else {
                      _audioService.play();
                    }
                  },
                  icon: Icon(
                    playerProvider.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                  ),
                  iconSize: 40,
                ),
              ),

              // Next
              IconButton(
                onPressed: () {
                  // TODO: Implement next episode
                },
                icon: Icon(
                  Icons.skip_next,
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                ),
                iconSize: 32,
              ),

              // Repeat
              IconButton(
                onPressed: () => playerProvider.toggleRepeat(),
                icon: Icon(
                  Icons.repeat,
                  color: playerProvider.isRepeating
                      ? AppTheme.lightTheme.colorScheme.primary
                      : AppTheme.lightTheme.colorScheme.onSurface,
                ),
                iconSize: 28,
              ),
            ],
          ),

          SizedBox(height: 4.h),

          // Additional Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Sleep Timer
              IconButton(
                onPressed: () {
                  // TODO: Show sleep timer options
                },
                icon: Icon(
                  Icons.timer,
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                ),
              ),

              // Speed
              TextButton(
                onPressed: () {
                  // TODO: Show speed options
                },
                child: Text(
                  '${playerProvider.playbackSpeed}x',
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.primary,
                  ),
                ),
              ),

              // Favorite
              IconButton(
                onPressed: () {
                  // TODO: Toggle favorite
                },
                icon: Icon(
                  Icons.favorite_border,
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                ),
              ),

              // Share
              IconButton(
                onPressed: () => _shareCurrentEpisode(),
                icon: Icon(
                  Icons.share,
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsTab(
      Episode episode, PodcastPlayerProvider playerProvider) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Episode Description
          if (episode.description?.isNotEmpty == true) ...[
            Text(
              'Description',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              episode.description!,
              style: AppTheme.lightTheme.textTheme.bodyMedium,
            ),
            SizedBox(height: 4.h),
          ],

          // Episode Metadata
          Text(
            'Episode Information',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),

          _buildMetadataRow('Duration', episode.duration),
          _buildMetadataRow('Release Date', _formatDate(episode.releaseDate)),
          if (episode.creator?.isNotEmpty == true)
            _buildMetadataRow('Creator', episode.creator!),

          SizedBox(height: 4.h),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Add to queue
                  },
                  icon: const Icon(Icons.queue),
                  label: const Text('Add to Queue'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Download episode
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Download'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.lightTheme.colorScheme.primary,
                    side: BorderSide(
                      color: AppTheme.lightTheme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookmarksTab(
      Episode episode, PodcastPlayerProvider playerProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border,
            size: 64,
            color: AppTheme.lightTheme.colorScheme.outline,
          ),
          SizedBox(height: 2.h),
          Text(
            'No bookmarks yet',
            style: AppTheme.lightTheme.textTheme.titleMedium,
          ),
          SizedBox(height: 1.h),
          Text(
            'Create bookmarks while listening to mark important moments',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 3.h),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Add bookmark at current position
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Bookmark'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lightTheme.colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // MARK: - Helper Widgets

  Widget _buildMetadataRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 30.w,
            child: Text(
              label,
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.lightTheme.textTheme.bodyMedium,
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
      return '${hours}h ${minutes}m ${seconds}s';
    } else {
      return '${minutes}m ${seconds}s';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Share current episode using social sharing service
  void _shareCurrentEpisode() async {
    try {
      final playerProvider =
          Provider.of<PodcastPlayerProvider>(context, listen: false);
      final currentEpisode = playerProvider.currentEpisode;

      if (currentEpisode == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No episode currently playing'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final episodeTitle = currentEpisode.title;
      final podcastTitle = currentEpisode.podcastName;
      final episodeDescription = currentEpisode.description;
      final audioUrl = currentEpisode.audioUrl;

      await SocialSharingService().shareEpisode(
        episodeTitle: episodeTitle,
        podcastTitle: podcastTitle,
        episodeDescription: episodeDescription,
        episodeUrl: audioUrl?.isNotEmpty == true ? audioUrl : null,
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
}
