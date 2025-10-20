import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../core/navigation_service.dart';
import '../../models/playlist.dart';
import '../../services/library_api_service.dart';
import '../../services/podcastindex_service.dart'; // Added import for PodcastIndexService
import '../../core/error_handling/global_error_handler.dart';
import '../../core/utils/smooth_scroll_utils.dart';
import '../../core/utils/mini_player_positioning.dart';
import '../../widgets/episode_list_item.dart';
import '../../widgets/episode_detail_modal.dart';
import '../../data/models/episode.dart' as episode_model;
import '../../providers/podcast_player_provider.dart';
import 'package:provider/provider.dart';
import '../../core/utils/safe_area_utils.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final Playlist playlist;

  const PlaylistDetailScreen({
    super.key,
    required this.playlist,
  });

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen>
    with SafeStateMixin, SmoothScrollMixin {
  final LibraryApiService _apiService = LibraryApiService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _isLoading = false;
  bool _isEditing = false;
  List<PlaylistItem> _playlistItems = [];
  List<int> _selectedItems = [];

  // Bottom navigation state

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.playlist.name;
    _descriptionController.text = widget.playlist.description ?? '';
    _loadPlaylistItems();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadPlaylistItems() async {
    safeSetState(() {
      _isLoading = true;
    });

    try {
      _playlistItems = await _apiService.getPlaylistItems(widget.playlist.id);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading playlist items: $e')),
      );
    } finally {
      safeSetState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _savePlaylist() async {
    try {
      await _apiService.updatePlaylist(widget.playlist.id, {
        'name': _nameController.text,
        'description': _descriptionController.text,
      });

      safeSetState(() {
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Playlist updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating playlist: $e')),
      );
    }
  }

  Future<void> _removeSelectedItems() async {
    if (_selectedItems.isEmpty) return;

    try {
      await _apiService.batchRemovePlaylistItems(_selectedItems);
      await _loadPlaylistItems();
      safeSetState(() {
        _selectedItems.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Items removed successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing items: $e')),
      );
    }
  }

  Future<void> _reorderItems(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final item = _playlistItems.removeAt(oldIndex);
    _playlistItems.insert(newIndex, item);

    // Update the order of all items
    final itemOrders = _playlistItems.asMap().entries.map((entry) {
      return {
        'playlist_item_id': entry.value.id,
        'order': entry.key + 1,
      };
    }).toList();

    try {
      await _apiService.reorderPlaylist(widget.playlist.id, itemOrders);
    } catch (e) {
      // Revert the change if API call fails
      _playlistItems.removeAt(newIndex);
      _playlistItems.insert(oldIndex, item);
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error reordering items: $e')),
      );
    }
  }

  Future<List<Map<String, dynamic>>>
      _buildPlaylistEpisodesWithAudioUrls() async {
    final List<Map<String, dynamic>> episodesWithAudio = [];

    for (final item in _playlistItems) {
      final episode = item.episode;
      if (episode == null) continue;

      // Start with the episode's audio URL
      String? audioUrl = episode.audioUrl;

      // If episode doesn't have audioUrl, try to fetch it from the podcast
      if (audioUrl == null || audioUrl.isEmpty) {
        if (episode.podcast?.id != null) {
          try {
            // Fetch podcast details with episodes to get audioUrl
            final podcastService = PodcastIndexService();
            final podcastData =
                await podcastService.getPodcastDetailsWithEpisodes(
              episode.podcast!.id.toString(),
            );

            // Find the specific episode in the episodes list
            final episodes = podcastData['episodes'] as List?;
            if (episodes != null) {
              final episodeData = episodes.firstWhere(
                (ep) => ep['id'] == episode.id,
                orElse: () => <String, dynamic>{},
              );
              if (episodeData.isNotEmpty) {
                audioUrl = episodeData['audioUrl'] ??
                    episodeData['enclosureUrl'] ??
                    episodeData['audio_url'];
                debugPrint(
                    'AudioPlayerService: Fetched audio URL for episode ${episode.id}: $audioUrl');
              }
            }
          } catch (e) {
            debugPrint(
                'Error fetching audio URL for episode ${episode.id}: $e');
            // Continue without audio URL - the episode will be marked as not having audio
          }
        }
      }

      // Include episodes even without audio URLs, but mark them appropriately
      int durationSeconds = episode.duration ?? 0;

      episodesWithAudio.add({
        'id': episode.id,
        'title': episode.title,
        'description': episode.description,
        'audioUrl': audioUrl ?? '', // Use empty string if no audio URL
        'coverImage': episode.image,
        'duration': durationSeconds,
        'publishedAt': episode.pubDate?.toIso8601String(),
        'feedId': episode.podcast?.id,
        'podcast': {
          'id': episode.podcast?.id,
          'title': episode.podcast?.title,
          'author': episode.podcast?.author,
          'coverImage': episode.podcast?.image,
        },
        'playlistOrder': item.order,
        'isFromPlaylist': true,
        'hasAudioUrl': audioUrl != null && audioUrl.isNotEmpty,
      });
    }

    return episodesWithAudio;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.lightTheme.colorScheme.surface,
        elevation: 0,
        title: _isEditing
            ? TextField(
                controller: _nameController,
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Playlist name',
                ),
              )
            : Text(
                widget.playlist.name,
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                ),
              ),
        centerTitle: !_isEditing,
        leading: IconButton(
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            color: AppTheme.lightTheme.colorScheme.onSurface,
            size: 24,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_selectedItems.isNotEmpty)
            IconButton(
              icon: CustomIconWidget(
                iconName: 'delete',
                color: AppTheme.lightTheme.colorScheme.error,
                size: 24,
              ),
              onPressed: _removeSelectedItems,
            )
          else if (!_isEditing)
            IconButton(
              icon: CustomIconWidget(
                iconName: 'edit',
                color: AppTheme.lightTheme.colorScheme.onSurface,
                size: 24,
              ),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            )
          else
            IconButton(
              icon: CustomIconWidget(
                iconName: 'check',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 24,
              ),
              onPressed: _savePlaylist,
            ),
        ],
      ),
      body: Column(
        children: [
          // Playlist info section
          if (!_isEditing)
            Container(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.playlist.description != null)
                    Text(
                      widget.playlist.description!,
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'music_note',
                        size: 16,
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        '${_playlistItems.length} episodes',
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Created ${_formatDate(widget.playlist.createdAt)}',
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Description edit field
          if (_isEditing)
            Container(
              padding: EdgeInsets.all(4.w),
              child: TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add a description (optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

          // Divider
          Divider(
            color: AppTheme.lightTheme.colorScheme.outline.withOpacity(0.2),
            height: 1,
          ),

          // Playlist items
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _playlistItems.isEmpty
                    ? _buildEmptyState()
                    : ReorderableListView.builder(
                        physics: SmoothScrollUtils.defaultPhysics,
                        padding: EdgeInsets.only(
                          left: 4.w,
                          right: 4.w,
                          top: 4.w,
                          bottom: MiniPlayerPositioning
                              .bottomPaddingForScrollables(),
                        ),
                        itemCount: _playlistItems.length,
                        onReorder: _reorderItems,
                        itemBuilder: (context, index) {
                          final item = _playlistItems[index];
                          final episode = item.episode;

                          if (episode == null) return const SizedBox.shrink();

                          return Card(
                            key: ValueKey(item.id),
                            child: _buildEnhancedEpisodeItem(
                                context, item, episode),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: _playlistItems.isNotEmpty
          ? FloatingActionButton(
              mini: true,
              onPressed: scrollToTop,
              backgroundColor: AppTheme.lightTheme.colorScheme.primary,
              foregroundColor: Colors.white,
              child: const Icon(Icons.keyboard_arrow_up),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'playlist_play',
              size: 80,
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: 3.h),
            Text(
              'No Episodes Yet',
              style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            Text(
              'Add episodes to your playlist to start listening',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            ElevatedButton(
              onPressed: () {
                NavigationService().navigateToHomeTab();
              },
              child: const Text('Browse Episodes'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  /// Build enhanced episode item using EpisodeListItem component
  Widget _buildEnhancedEpisodeItem(
      BuildContext context, PlaylistItem item, dynamic episode) {
    // Convert to our enhanced Episode model with progress tracking
    final enhancedEpisode = episode_model.Episode(
      id: episode.id,
      title: episode.title,
      description: episode.description ?? '',
      audioUrl: episode.audioUrl,
      coverImage: episode.podcast?.image ?? episode.image ?? '',
      duration: episode.duration?.toString() ?? '0',
      releaseDate: episode.pubDate ?? DateTime.now(),
      podcastName: episode.podcast?.title ?? 'Unknown Podcast',
      creator: episode.podcast?.author ?? 'Unknown Author',
      isDownloaded: false,
      podcastId: episode.podcast?.id?.toString(),
      // Progress tracking fields - will be populated from player provider
      lastPlayedPosition: null,
      totalDuration: episode.duration != null ? episode.duration! * 1000 : null,
      lastPlayedAt: null,
      isCompleted: false,
    );

    return Consumer<PodcastPlayerProvider>(
      builder: (context, playerProvider, child) {
        // Check if this episode is currently playing
        final isCurrentlyPlaying =
            playerProvider.currentEpisode?.id == episode.id;
        final isPlaying = isCurrentlyPlaying && playerProvider.isPlaying;

        // If currently playing, use real-time data
        if (isCurrentlyPlaying) {
          final realTimeData = {
            'id': enhancedEpisode.id,
            'title': enhancedEpisode.title,
            'description': enhancedEpisode.description,
            'audioUrl': enhancedEpisode.audioUrl,
            'coverImage': enhancedEpisode.coverImage,
            'duration': enhancedEpisode.duration,
            'podcastName': enhancedEpisode.podcastName,
            'creator': enhancedEpisode.creator,
            'isDownloaded': enhancedEpisode.isDownloaded,
            'hasTranscript': false,
            'lastPlayedPosition': playerProvider.position.inMilliseconds,
            'totalDuration': playerProvider.duration.inMilliseconds,
            'lastPlayedAt': DateTime.now().toIso8601String(),
            'isCompleted': playerProvider.progressPercentage >= 1.0,
            'isCurrentlyPlaying': true,
            'isPlaying': isPlaying,
          };

          return EpisodeListItem(
            episode: realTimeData,
            onPlay: () => _playPlaylistEpisode(context, item, episode),
            onLongPress: () =>
                _showPlaylistEpisodeOptions(context, item, episode),
            onShowDetails: () => _showPlaylistEpisodeDetails(
                context, item, episode, enhancedEpisode),
            showTranscriptIcon: false,
            showArchived: false,
            playProgress: _getEpisodeProgress(realTimeData),
            isCurrentlyPlaying: true,
            isActiveEpisode: true,
            isPlaying: isPlaying,
            lastPlayedPosition: realTimeData['lastPlayedPosition'] as int?,
            totalDuration: realTimeData['totalDuration'] as int?,
            lastPlayedAt: DateTime.now(),
          );
        }

        // For non-playing episodes, load progress from storage to show remaining time
        return FutureBuilder<Map<String, dynamic>>(
          future: _loadEpisodeProgressForDisplay(enhancedEpisode.id, context),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // Show episode immediately with fallback progress data
              return EpisodeListItem(
                episode: {
                  'id': enhancedEpisode.id,
                  'title': enhancedEpisode.title,
                  'description': enhancedEpisode.description,
                  'audioUrl': enhancedEpisode.audioUrl,
                  'coverImage': enhancedEpisode.coverImage,
                  'duration': enhancedEpisode.duration,
                  'podcastName': enhancedEpisode.podcastName,
                  'creator': enhancedEpisode.creator,
                  'isDownloaded': enhancedEpisode.isDownloaded,
                  'hasTranscript': false,
                  'lastPlayedPosition': enhancedEpisode.lastPlayedPosition,
                  'totalDuration': enhancedEpisode.totalDuration,
                  'lastPlayedAt':
                      enhancedEpisode.lastPlayedAt?.toIso8601String(),
                  'isCompleted': enhancedEpisode.isCompleted,
                  'isCurrentlyPlaying': false,
                  'isPlaying': false,
                },
                onPlay: () => _playPlaylistEpisode(context, item, episode),
                onLongPress: () =>
                    _showPlaylistEpisodeOptions(context, item, episode),
                onShowDetails: () => _showPlaylistEpisodeDetails(
                    context, item, episode, enhancedEpisode),
                showTranscriptIcon: false,
                showArchived: false,
                playProgress: _getEpisodeProgress({
                  'lastPlayedPosition': enhancedEpisode.lastPlayedPosition,
                  'totalDuration': enhancedEpisode.totalDuration,
                }),
                isCurrentlyPlaying: false,
                isActiveEpisode: false,
                isPlaying: false,
                lastPlayedPosition: enhancedEpisode.lastPlayedPosition,
                totalDuration: enhancedEpisode.totalDuration,
                lastPlayedAt: enhancedEpisode.lastPlayedAt,
              );
            }

            if (snapshot.hasError) {
              // Show episode with fallback progress data on error
              return EpisodeListItem(
                episode: {
                  'id': enhancedEpisode.id,
                  'title': enhancedEpisode.title,
                  'description': enhancedEpisode.description,
                  'audioUrl': enhancedEpisode.audioUrl,
                  'coverImage': enhancedEpisode.coverImage,
                  'duration': enhancedEpisode.duration,
                  'podcastName': enhancedEpisode.podcastName,
                  'creator': enhancedEpisode.creator,
                  'isDownloaded': enhancedEpisode.isDownloaded,
                  'hasTranscript': false,
                  'lastPlayedPosition': enhancedEpisode.lastPlayedPosition,
                  'totalDuration': enhancedEpisode.totalDuration,
                  'lastPlayedAt':
                      enhancedEpisode.lastPlayedAt?.toIso8601String(),
                  'isCompleted': enhancedEpisode.isCompleted,
                  'isCurrentlyPlaying': false,
                  'isPlaying': false,
                },
                onPlay: () => _playPlaylistEpisode(context, item, episode),
                onLongPress: () =>
                    _showPlaylistEpisodeOptions(context, item, episode),
                onShowDetails: () => _showPlaylistEpisodeDetails(
                    context, item, episode, enhancedEpisode),
                showTranscriptIcon: false,
                showArchived: false,
                playProgress: _getEpisodeProgress({
                  'lastPlayedPosition': enhancedEpisode.lastPlayedPosition,
                  'totalDuration': enhancedEpisode.totalDuration,
                }),
                isCurrentlyPlaying: false,
                isActiveEpisode: false,
                isPlaying: false,
                lastPlayedPosition: enhancedEpisode.lastPlayedPosition,
                totalDuration: enhancedEpisode.totalDuration,
                lastPlayedAt: enhancedEpisode.lastPlayedAt,
              );
            }

            final progressData = snapshot.data!;

            // Use the most recent progress data, fallback to episode data if storage data is null
            final finalProgressData = {
              'lastPlayedPosition': progressData['lastPlayedPosition'] ??
                  enhancedEpisode.lastPlayedPosition,
              'totalDuration': progressData['totalDuration'] ??
                  enhancedEpisode.totalDuration,
              'lastPlayedAt': progressData['lastPlayedAt'] ??
                  enhancedEpisode.lastPlayedAt?.toIso8601String(),
              'isCompleted':
                  progressData['isCompleted'] ?? enhancedEpisode.isCompleted,
            };

            return EpisodeListItem(
              episode: {
                'id': enhancedEpisode.id,
                'title': enhancedEpisode.title,
                'description': enhancedEpisode.description,
                'audioUrl': enhancedEpisode.audioUrl,
                'coverImage': enhancedEpisode.coverImage,
                'duration': enhancedEpisode.duration,
                'podcastName': enhancedEpisode.podcastName,
                'creator': enhancedEpisode.creator,
                'isDownloaded': enhancedEpisode.isDownloaded,
                'hasTranscript': false,
                'lastPlayedPosition': finalProgressData['lastPlayedPosition'],
                'totalDuration': finalProgressData['totalDuration'],
                'lastPlayedAt': finalProgressData['lastPlayedAt'],
                'isCompleted': finalProgressData['isCompleted'],
                'isCurrentlyPlaying': false,
                'isPlaying': false,
              },
              onPlay: () => _playPlaylistEpisode(context, item, episode),
              onLongPress: () =>
                  _showPlaylistEpisodeOptions(context, item, episode),
              onShowDetails: () => _showPlaylistEpisodeDetails(
                  context, item, episode, enhancedEpisode),
              showTranscriptIcon: false,
              showArchived: false,
              playProgress: _getEpisodeProgress(finalProgressData),
              isCurrentlyPlaying: false,
              isActiveEpisode: false,
              isPlaying: false,
              lastPlayedPosition: finalProgressData['lastPlayedPosition'],
              totalDuration: finalProgressData['totalDuration'],
              lastPlayedAt: finalProgressData['lastPlayedAt'] != null
                  ? DateTime.tryParse(finalProgressData['lastPlayedAt'])
                  : null,
            );
          },
        );
      },
    );
  }

  /// Get progress percentage for an episode
  double _getEpisodeProgress(Map<String, dynamic> episodeData) {
    final lastPlayedPosition = episodeData['lastPlayedPosition'];
    final totalDuration = episodeData['totalDuration'];

    if (lastPlayedPosition != null &&
        totalDuration != null &&
        totalDuration > 0) {
      return (lastPlayedPosition / totalDuration).clamp(0.0, 1.0);
    }
    return 0.0;
  }

  /// Load progress data for display in EpisodeListItem
  Future<Map<String, dynamic>> _loadEpisodeProgressForDisplay(
    int episodeId,
    BuildContext context,
  ) async {
    try {
      final playerProvider =
          Provider.of<PodcastPlayerProvider>(context, listen: false);

      final progress = await playerProvider.loadEpisodeProgress(episodeId);

      if (progress != null) {
        return {
          'lastPlayedPosition': progress['position'],
          'totalDuration': progress['duration'],
          'lastPlayedAt': progress['lastPlayed'] != null
              ? DateTime.fromMillisecondsSinceEpoch(progress['lastPlayed'])
              : null,
          'isCompleted': progress['completed'] ?? false,
        };
      }
      return {
        'lastPlayedPosition': null,
        'totalDuration': null,
        'lastPlayedAt': null,
        'isCompleted': false,
      };
    } catch (e) {
      debugPrint('❌ Error loading episode progress: $e');
      return {
        'lastPlayedPosition': null,
        'totalDuration': null,
        'lastPlayedAt': null,
        'isCompleted': false,
      };
    }
  }

  /// Play playlist episode
  void _playPlaylistEpisode(
      BuildContext context, PlaylistItem item, dynamic episode) async {
    try {
      debugPrint('🎵 Playing playlist episode: ${episode.title}');

      // Build playlist episodes with audio URLs first
      final playlistEpisodes = await _buildPlaylistEpisodesWithAudioUrls();

      // Find current episode
      final currentEpisode = playlistEpisodes.firstWhere(
        (ep) => ep['id'].toString() == episode.id.toString(),
        orElse: () => <String, dynamic>{},
      );

      // Check if episode has audio URL
      if (currentEpisode.isEmpty ||
          currentEpisode['audioUrl'] == null ||
          currentEpisode['audioUrl'].toString().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'This episode has no audio available. Please try another episode.'),
            backgroundColor: AppTheme.lightTheme.colorScheme.error,
          ),
        );
        return;
      }

      // Start immediate playback with new player system
      _startPlaylistEpisodePlayback(context, currentEpisode, playlistEpisodes);
    } catch (e) {
      debugPrint('Error playing playlist episode: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error playing episode: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Start playlist episode playback with new player system
  void _startPlaylistEpisodePlayback(
      BuildContext context,
      Map<String, dynamic> episodeData,
      List<Map<String, dynamic>> playlistEpisodes) {
    try {
      debugPrint(
          '🎵 Starting playlist episode playback: ${episodeData['title']}');

      // Get the player provider
      final playerProvider =
          Provider.of<PodcastPlayerProvider>(context, listen: false);

      // Convert episode to Episode model
      final episodeModel = episode_model.Episode(
        id: episodeData['id'],
        title: episodeData['title'] ?? 'Unknown Episode',
        description: episodeData['description'] ?? '',
        audioUrl: episodeData['audioUrl'] ?? '',
        coverImage: episodeData['coverImage'] ?? '',
        duration: episodeData['duration']?.toString() ?? '0',
        releaseDate: episodeData['publishedAt'] != null
            ? DateTime.tryParse(episodeData['publishedAt']) ?? DateTime.now()
            : DateTime.now(),
        podcastName: episodeData['podcast']?['title'] ?? 'Unknown Podcast',
        creator: episodeData['podcast']?['author'] ?? 'Unknown Author',
        isDownloaded: false,
      );

      // Find the episode index in the playlist
      final episodeIndex = playlistEpisodes.indexWhere(
        (ep) => ep['id'].toString() == episodeData['id'].toString(),
      );
      final startIndex = episodeIndex >= 0 ? episodeIndex : 0;

      // Set episode queue for auto-play functionality - convert all playlist episodes to Episode models
      final episodeModels = playlistEpisodes.map((ep) {
        return episode_model.Episode(
          id: ep['id'],
          title: ep['title'] ?? 'Unknown Episode',
          description: ep['description'] ?? '',
          audioUrl: ep['audioUrl'] ?? '',
          coverImage: ep['coverImage'] ?? '',
          duration: ep['duration']?.toString() ?? '0',
          releaseDate: ep['publishedAt'] != null
              ? DateTime.tryParse(ep['publishedAt']) ?? DateTime.now()
              : DateTime.now(),
          podcastName: ep['podcast']?['title'] ?? 'Unknown Podcast',
          creator: ep['podcast']?['author'] ?? 'Unknown Author',
          isDownloaded: false,
        );
      }).toList();

      // Set the episode queue for auto-play functionality
      debugPrint('🎵 Setting episode queue for playlist auto-play...');
      playerProvider.setEpisodeQueue(episodeModels, startIndex: startIndex);
      debugPrint('🎵 Episode queue set successfully for playlist auto-play');

      // Load and play the episode directly
      playerProvider.loadAndPlayEpisode(episodeModel, clearQueue: false);

      // Show the floating mini-player
      playerProvider.showFloatingMiniPlayer(
        context,
        episodeData,
        playlistEpisodes,
        startIndex,
      );

      debugPrint(
          '✅ Playlist episode playback started successfully with auto-play enabled');
    } catch (e) {
      debugPrint('❌ Error starting playlist episode playback: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error playing episode: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Show playlist episode options menu
  void _showPlaylistEpisodeOptions(
      BuildContext context, PlaylistItem item, dynamic episode) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeAreaUtils.wrapWithSafeArea(
        Container(
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.play_arrow),
                title: Text('Play'),
                onTap: () {
                  Navigator.pop(context);
                  _playPlaylistEpisode(context, item, episode);
                },
              ),
              ListTile(
                leading: Icon(Icons.remove_circle_outline),
                title: Text('Remove from playlist'),
                onTap: () async {
                  Navigator.pop(context);
                  // Handle remove action
                  try {
                    await _apiService.batchRemovePlaylistItems([item.id]);
                    await _loadPlaylistItems();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Episode removed from playlist')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error removing episode: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show playlist episode details using EpisodeDetailModal
  void _showPlaylistEpisodeDetails(BuildContext context, PlaylistItem item,
      dynamic episode, episode_model.Episode enhancedEpisode) {
    // Convert episode to map format for EpisodeDetailModal
    final episodeMap = {
      'id': enhancedEpisode.id,
      'title': enhancedEpisode.title,
      'description': enhancedEpisode.description,
      'audioUrl': enhancedEpisode.audioUrl,
      'coverImage': enhancedEpisode.coverImage,
      'duration': enhancedEpisode.duration,
      'podcast': {
        'id': enhancedEpisode.podcastId,
        'feedId': enhancedEpisode.podcastId,
        'title': enhancedEpisode.podcastName,
        'coverImage': enhancedEpisode.coverImage,
      },
      'podcastName': enhancedEpisode.podcastName,
      'creator': enhancedEpisode.creator,
      'isDownloaded': enhancedEpisode.isDownloaded,
      'hasTranscript': false,
      'lastPlayedPosition': enhancedEpisode.lastPlayedPosition,
      'totalDuration': enhancedEpisode.totalDuration,
      'lastPlayedAt': enhancedEpisode.lastPlayedAt?.toIso8601String(),
      'isCompleted': enhancedEpisode.isCompleted,
      'isCurrentlyPlaying': false,
      'isPlaying': false,
      'feedId': enhancedEpisode.podcastId,
      'podcastId': enhancedEpisode.podcastId,
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeAreaUtils.wrapWithSafeArea(
        Container(
          width: double.infinity,
          height: double.infinity,
          child: EpisodeDetailModal(
            episode: episodeMap,
            episodes: [episodeMap], // Single episode for detail view
            episodeIndex: 0,
          ),
        ),
      ),
    );
  }
}
