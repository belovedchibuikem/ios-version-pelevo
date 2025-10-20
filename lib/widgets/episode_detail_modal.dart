import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_export.dart';
import '../providers/podcast_player_provider.dart';
import '../data/models/episode.dart';
import '../models/episode_bookmark.dart';
import '../services/episode_progress_service.dart';
import '../services/download_manager.dart';
import '../services/episode_archive_service.dart';
import '../services/social_sharing_service.dart';
import '../core/utils/mini_player_positioning.dart';
import '../core/utils/image_utils.dart';

class EpisodeDetailModal extends StatefulWidget {
  final Map<String, dynamic> episode;
  final List<Map<String, dynamic>> episodes;
  final int episodeIndex;

  const EpisodeDetailModal({
    super.key,
    required this.episode,
    required this.episodes,
    required this.episodeIndex,
  });

  @override
  State<EpisodeDetailModal> createState() => _EpisodeDetailModalState();
}

class _EpisodeDetailModalState extends State<EpisodeDetailModal> {
  bool _isDetailsTabSelected = true;
  List<EpisodeBookmark> _bookmarks = [];
  final EpisodeProgressService _progressService = EpisodeProgressService();
  final DownloadManager _downloadManager = DownloadManager();
  final EpisodeArchiveService _archiveService = EpisodeArchiveService();
  bool _isLoadingBookmarks = false;

  // Action button states
  bool _isInQueue = false;
  bool _isDownloading = false;
  bool _isMarkedAsPlayed = false;
  bool _isArchived = false;
  bool _isDownloaded = false;
  String _downloadedFileSize = '';
  String _episodeFileSize = '';

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
    _initializeEpisodeStates();

    // Hide mini-player when episode detail modal is shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final playerProvider =
          Provider.of<PodcastPlayerProvider>(context, listen: false);
      playerProvider.hideFloatingMiniPlayer();
    });
  }

  @override
  void didUpdateWidget(EpisodeDetailModal oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if the episode has changed
    if (oldWidget.episode['id']?.toString() !=
        widget.episode['id']?.toString()) {
      debugPrint(
          'Episode detail modal: Episode changed from ${oldWidget.episode['id']} to ${widget.episode['id']}');
      // Re-initialize episode states when episode changes
      _initializeEpisodeStates();
    }
  }

  void _initializeEpisodeStates() {
    // Check if episode is in queue and archive status
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final playerProvider =
          Provider.of<PodcastPlayerProvider>(context, listen: false);
      final episodeModel = Episode.fromJson(widget.episode);

      final isInQueue = playerProvider.episodeQueue.any(
        (episode) => episode.id == episodeModel.id,
      );

      // Check archive status
      final episodeId = widget.episode['id']?.toString();
      bool isArchived = false;
      if (episodeId != null) {
        isArchived = await _archiveService.isEpisodeArchived(episodeId);
      }

      // Check download status and get file size
      bool isDownloaded = false;
      String downloadedFileSize = '';
      String episodeFileSize = '';
      if (episodeId != null) {
        isDownloaded = await _downloadManager.isEpisodeDownloaded(episodeId);
        if (isDownloaded) {
          downloadedFileSize = await _getDownloadedFileSize(episodeId);
        } else {
          // Get file size from audio URL for non-downloaded episodes
          episodeFileSize = await _getEpisodeFileSizeFromUrl();
        }
      }

      if (mounted) {
        setState(() {
          _isInQueue = isInQueue;
          _isArchived = isArchived;
          _isDownloaded = isDownloaded;
          _downloadedFileSize = downloadedFileSize;
          _episodeFileSize = episodeFileSize;
        });
      }
    });
  }

  Future<void> _loadBookmarks() async {
    try {
      if (!mounted) return;
      setState(() {
        _isLoadingBookmarks = true;
      });

      // Ensure the service is properly initialized
      await _progressService.initialize();

      if (!mounted) return;

      final episodeId = widget.episode['id'].toString();
      debugPrint('Loading bookmarks for episode: $episodeId');

      final bookmarks = await _progressService.getBookmarks(episodeId);
      debugPrint('getBookmarks returned type: ${bookmarks.runtimeType}');
      debugPrint('getBookmarks returned: $bookmarks');

      if (!mounted) return;

      // Handle the case where we get the expected type
      setState(() {
        _bookmarks = bookmarks;
        _isLoadingBookmarks = false;
      });
    } catch (e) {
      debugPrint('Error loading bookmarks: $e');
      if (mounted) {
        setState(() {
          _bookmarks = [];
          _isLoadingBookmarks = false;
        });
      }
    }
  }

  @override
  void dispose() {
    // Show mini-player again when episode detail modal is closed
    // Use a delayed callback to ensure the widget is still mounted
    Future.delayed(Duration.zero, () {
      if (mounted) {
        try {
          final playerProvider =
              Provider.of<PodcastPlayerProvider>(context, listen: false);
          // Use the new persistent mini-player logic
          playerProvider.showMiniPlayerIfAppropriate(context);
        } catch (e) {
          debugPrint(
              'Error showing mini-player in episode detail modal dispose: $e');
        }
      }
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Consumer<PodcastPlayerProvider>(
        key: ValueKey('episode_detail_modal_${widget.episode['id']}'),
        builder: (context, playerProvider, child) {
          return Material(
            elevation:
                100, // High elevation to ensure it appears above mini-player
            color: Colors.transparent,
            child: SafeAreaUtils.wrapWithSafeArea(
              Container(
                width: double.infinity,
                height: double.infinity,
                color: AppTheme.lightTheme.scaffoldBackgroundColor,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Top Bar / Header
                      _buildHeader(context),

                      // Show different content based on selected tab
                      if (_isDetailsTabSelected) ...[
                        // Details Tab Content
                        _buildPodcastArtwork(),
                        _buildTitleSection(),

                        // Horizontal rule line
                        Container(
                          margin: EdgeInsets.symmetric(
                              horizontal: 32, vertical: 16),
                          height: 2,
                          color: AppTheme.lightTheme.colorScheme.outline
                              .withOpacity(0.6),
                        ),

                        // Action Bar - Moved after title section, before description
                        _buildPlayerControls(context, playerProvider),

                        _buildEpisodeDetails(),
                      ] else ...[
                        // Bookmarks Tab Content
                        _buildBookmarksTab(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          right: 16,
          bottom: 16),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back,
              color: AppTheme.lightTheme.colorScheme.onSurface,
              size: 24,
            ),
          ),

          // Tab navigation
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTabButton('Details', _isDetailsTabSelected, () {
                  if (mounted) {
                    setState(() {
                      _isDetailsTabSelected = true;
                    });
                  }
                }),
                SizedBox(width: 32),
                _buildTabButton('Bookmarks', !_isDetailsTabSelected, () {
                  if (mounted) {
                    setState(() {
                      _isDetailsTabSelected = false;
                    });
                  }
                }),
              ],
            ),
          ),

          // Action icons
          Row(
            children: [
              IconButton(
                onPressed: () {
                  // TODO: Implement favorite functionality
                },
                icon: Icon(
                  Icons.star_outline,
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                  size: 24,
                ),
              ),
              IconButton(
                onPressed: () => _shareEpisode(),
                icon: Icon(
                  Icons.share,
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                  size: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              color: isSelected
                  ? AppTheme.lightTheme.colorScheme.onSurface
                  : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          if (isSelected)
            Container(
              margin: EdgeInsets.only(top: 4),
              height: 2,
              width: text.length * 8.0,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primary,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPodcastArtwork() {
    return Consumer<PodcastPlayerProvider>(
      key: ValueKey('episode_artwork_${widget.episode['id']}'),
      builder: (context, playerProvider, child) {
        // Use current episode data with podcast data if available, otherwise fall back to widget episode
        final currentEpisode = playerProvider.currentEpisode;

        // Debug: Log episode IDs for comparison
        debugPrint(
            'Episode detail modal: Widget episode ID: ${widget.episode['id']}');
        debugPrint(
            'Episode detail modal: Current episode ID: ${currentEpisode?.id}');
        debugPrint(
            'Episode detail modal: Current episode title: ${currentEpisode?.title}');

        // Determine which episode data to use
        Map<String, dynamic> episodeData;

        // Always prioritize current episode if it exists and matches the widget episode
        if (currentEpisode != null &&
            currentEpisode.id.toString() == widget.episode['id']?.toString()) {
          // Use current episode from player provider (when episode is playing and matches)
          episodeData = currentEpisode
              .toMapWithPodcastData(playerProvider.currentPodcastData);
          debugPrint(
              'Episode detail modal: Using current episode data from player provider (matches widget episode)');
        } else {
          // Use widget episode data (when modal is opened without playing or different episode)
          episodeData = Map<String, dynamic>.from(widget.episode);
          debugPrint(
              'Episode detail modal: Using widget episode data (no current episode or different episode)');

          // Ensure the episode data has proper podcast structure for image extraction
          if (episodeData['podcast'] == null) {
            // First try to construct podcast data from the current episode
            final constructedPodcastData =
                _constructPodcastDataFromEpisode(episodeData);
            if (constructedPodcastData.isNotEmpty) {
              episodeData['podcast'] = constructedPodcastData;
              debugPrint(
                  'Episode detail modal: Constructed podcast data from current episode');
            } else if (widget.episodes.isNotEmpty) {
              // If construction fails, try to get podcast data from any episode in the list
              for (final episode in widget.episodes) {
                if (episode['podcast'] != null) {
                  episodeData['podcast'] = episode['podcast'];
                  debugPrint(
                      'Episode detail modal: Added podcast data from episodes list');
                  break;
                }
              }
            }
          }
        }

        // Debug: Log the episode data structure
        debugPrint(
            'Episode detail modal episode data keys: ${episodeData.keys.toList()}');
        debugPrint('Episode detail modal episode data: $episodeData');

        // Debug: Check if podcast object exists and its structure
        if (episodeData['podcast'] != null) {
          debugPrint('Podcast object exists: ${episodeData['podcast']}');
        } else {
          debugPrint('No podcast object found in episode data');
        }

        // Extract podcast image using the utility function
        String podcastImage = ImageUtils.extractPodcastImageWithFallback(
          episodeData,
          widget.episodes,
        );

        debugPrint('Episode detail modal image extracted: $podcastImage');
        debugPrint(
            'Is valid image URL: ${ImageUtils.isValidImageUrl(podcastImage)}');

        // If still no image found, try additional fallback strategies
        if (podcastImage.isEmpty) {
          debugPrint(
              'No image found, trying additional fallback strategies...');

          // Try to get image from any episode in the episodes list
          for (final episode in widget.episodes) {
            final fallbackImage = ImageUtils.extractPodcastImage(episode);
            if (fallbackImage.isNotEmpty) {
              podcastImage = fallbackImage;
              debugPrint(
                  'Found fallback image from episodes list: $podcastImage');
              break;
            }
          }

          // If still no image, try to get it from the original widget episode
          if (podcastImage.isEmpty) {
            final originalImage =
                ImageUtils.extractPodcastImage(widget.episode);
            if (originalImage.isNotEmpty) {
              podcastImage = originalImage;
              debugPrint(
                  'Found image from original widget episode: $podcastImage');
            }
          }

          // Final fallback: try to get podcast info from API if we have a podcast ID
          if (podcastImage.isEmpty) {
            final podcastId = episodeData['podcastId']?.toString() ??
                episodeData['feedId']?.toString() ??
                episodeData['podcast']?['id']?.toString();
            if (podcastId != null && podcastId.isNotEmpty) {
              debugPrint(
                  'Attempting to get podcast info from API for podcast ID: $podcastId');
              // Note: This would require an API call, but for now we'll just log it
              // In a real implementation, you might want to make an API call here
            }
          }

          // Last resort: try to get image from any available source
          if (podcastImage.isEmpty) {
            debugPrint(
                'No image found through any method. Checking all available data sources...');
            debugPrint('Widget episode keys: ${widget.episode.keys.toList()}');
            debugPrint('Widget episodes length: ${widget.episodes.length}');
            if (widget.episodes.isNotEmpty) {
              debugPrint(
                  'First episode in list keys: ${widget.episodes.first.keys.toList()}');
              if (widget.episodes.first['podcast'] != null) {
                debugPrint(
                    'First episode podcast keys: ${(widget.episodes.first['podcast'] as Map).keys.toList()}');
              }
            }
          }
        }

        debugPrint('Final podcast image after all fallbacks: $podcastImage');
        debugPrint(
            'Final is valid image URL: ${ImageUtils.isValidImageUrl(podcastImage)}');

        // Force rebuild by using episode ID in the widget key
        final imageKey =
            ValueKey('episode_image_${widget.episode['id']}_${podcastImage}');

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 32),
          child: Container(
            width: 60.w,
            height: 60.w,
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
                      key: imageKey,
                      imageUrl: podcastImage,
                      width: 60.w,
                      height: 60.w,
                      fit: BoxFit.cover,
                      errorWidget: ImageUtils.getFallbackWidget(
                        width: 60.w,
                        height: 60.w,
                        backgroundColor:
                            AppTheme.lightTheme.colorScheme.surfaceContainer,
                        iconColor:
                            AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        icon: Icons.music_note,
                      ),
                    ),
                  )
                : ImageUtils.getFallbackWidget(
                    width: 60.w,
                    height: 60.w,
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

  Widget _buildTitleSection() {
    final podcastTitle = widget.episode['podcast']?['title'] ??
        widget.episode['podcastName'] ??
        'Unknown Podcast';
    final episodeTitle = widget.episode['title'] ?? 'Untitled Episode';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            episodeTitle,
            style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              _navigateToPodcastDetail();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  podcastTitle,
                  style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppTheme.lightTheme.colorScheme.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerControls(
      BuildContext context, PodcastPlayerProvider playerProvider) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12), // Reduced vertical padding to move closer to title
      // Removed decoration to match uniform background color
      child: Column(
        children: [
          // Main play button
          Container(
            width: 72, // Slightly smaller for top positioning
            height: 72, // Slightly smaller for top positioning
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.lightTheme.colorScheme
                  .primary, // Use primary color for better visibility
              boxShadow: [
                BoxShadow(
                  color:
                      AppTheme.lightTheme.colorScheme.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              onPressed: () => _playEpisode(context, playerProvider),
              icon: Icon(
                Icons.play_arrow,
                color: AppTheme.lightTheme.colorScheme.surface,
                size: 36, // Adjusted size
              ),
              iconSize: 36, // Adjusted size
            ),
          ),

          SizedBox(height: 24), // Reduced spacing for top positioning

          // Action buttons row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                icon: _isDownloading
                    ? Icons.downloading
                    : _isDownloaded
                        ? Icons.download_done
                        : Icons.download,
                label: _isDownloading
                    ? 'Downloading...'
                    : _isDownloaded
                        ? _downloadedFileSize.isNotEmpty
                            ? _downloadedFileSize
                            : 'Downloaded'
                        : _episodeFileSize.isNotEmpty
                            ? _episodeFileSize
                            : 'Download',
                onTap: _onDownloadTap,
                isLoading: _isDownloading,
              ),
              _buildActionButton(
                icon: _isInQueue ? Icons.playlist_remove : Icons.playlist_add,
                label: _isInQueue ? 'Remove' : 'Up Next',
                onTap: _onUpNextTap,
              ),
              _buildActionButton(
                icon: _isMarkedAsPlayed
                    ? Icons.check_circle
                    : Icons.check_circle_outline,
                label: 'Mark Played',
                onTap: _onMarkPlayedTap,
              ),
              _buildActionButton(
                icon: _isArchived ? Icons.unarchive : Icons.archive_outlined,
                label: _isArchived ? 'Unarchive' : 'Archive',
                onTap: _onArchiveTap,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(24),
            ),
            child: isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.lightTheme.colorScheme.onSurface,
                      ),
                    ),
                  )
                : Icon(
                    icon,
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                    size: 24,
                  ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBookmarksTab() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Divider line - Made more visible
          Container(
            height: 2, // Increased from 1 to 2
            color: AppTheme.lightTheme.colorScheme.outline
                .withOpacity(0.6), // Increased opacity from 0.3 to 0.6
          ),

          SizedBox(height: 24),

          // Bookmarks header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bookmarks',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () => _loadBookmarks(),
                    icon: Icon(
                      Icons.refresh,
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                    tooltip: 'Refresh Bookmarks',
                  ),
                  IconButton(
                    onPressed: () => _addBookmark(),
                    icon: Icon(
                      Icons.bookmark_add,
                      color: AppTheme.lightTheme.colorScheme.primary,
                      size: 24,
                    ),
                    tooltip: 'Add Bookmark',
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: 16),

          // Bookmarks list
          if (_isLoadingBookmarks)
            _buildLoadingBookmarks()
          else if (_bookmarks.isEmpty)
            _buildEmptyBookmarks()
          else
            _buildBookmarksList(),
        ],
      ),
    );
  }

  Widget _buildLoadingBookmarks() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildEmptyBookmarks() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(
            Icons.bookmark_border,
            size: 64,
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
          SizedBox(height: 16),
          Text(
            'No bookmarks yet',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Tap the + button to add your first bookmark',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBookmarksList() {
    return Column(
      children: _bookmarks.asMap().entries.map((entry) {
        final index = entry.key;
        final bookmark = entry.value;
        return _buildBookmarkItem(index, bookmark);
      }).toList(),
    );
  }

  Widget _buildBookmarkItem(int index, EpisodeBookmark bookmark) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bookmark icon with color
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Color(int.parse(bookmark.color.replaceAll('#', '0xFF'))),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.bookmark,
              color: Colors.white,
              size: 20,
            ),
          ),

          SizedBox(width: 16),

          // Bookmark content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bookmark.title,
                  style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (bookmark.notes != null && bookmark.notes!.isNotEmpty) ...[
                  SizedBox(height: 4),
                  Text(
                    bookmark.notes!,
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      height: 1.3,
                    ),
                  ),
                ],
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: AppTheme.lightTheme.colorScheme.primary,
                    ),
                    SizedBox(width: 4),
                    Text(
                      bookmark.formattedPositionShort,
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 16),
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(width: 4),
                    Text(
                      _formatBookmarkDate(bookmark.createdAt),
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Actions
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
            onSelected: (value) {
              if (value == 'edit') {
                _editBookmark(index, bookmark);
              } else if (value == 'delete') {
                _deleteBookmark(index);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _addBookmark() {
    final titleController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Bookmark'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Bookmark title...',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                hintText: 'Notes (optional)...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = titleController.text.trim();
              if (title.isNotEmpty) {
                await _progressService.addBookmark(
                  episodeId: widget.episode['id'].toString(),
                  podcastId: widget.episode['podcast']?['id']?.toString() ??
                      widget.episode['podcastId']?.toString() ??
                      '',
                  position: 0, // TODO: Get current playback position
                  title: title,
                  notes: notesController.text.trim().isNotEmpty
                      ? notesController.text.trim()
                      : null,
                );
                await _loadBookmarks(); // Reload bookmarks
                if (mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  void _editBookmark(int index, EpisodeBookmark currentBookmark) {
    final titleController = TextEditingController(text: currentBookmark.title);
    final notesController =
        TextEditingController(text: currentBookmark.notes ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Bookmark'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Bookmark title...',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                hintText: 'Notes (optional)...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = titleController.text.trim();
              if (title.isNotEmpty) {
                // Create updated bookmark
                final updatedBookmark = currentBookmark.copyWith(
                  title: title,
                  notes: notesController.text.trim().isNotEmpty
                      ? notesController.text.trim()
                      : null,
                  updatedAt: DateTime.now(),
                );

                // Remove old bookmark and add updated one
                await _progressService.removeBookmark(
                    currentBookmark.episodeId, currentBookmark.position);

                await _progressService.addBookmark(
                  episodeId: updatedBookmark.episodeId,
                  podcastId: updatedBookmark.podcastId,
                  position: updatedBookmark.position,
                  title: updatedBookmark.title,
                  notes: updatedBookmark.notes,
                  color: updatedBookmark.color,
                  isPublic: updatedBookmark.isPublic,
                );

                await _loadBookmarks(); // Reload bookmarks
                if (mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteBookmark(int index) {
    final bookmarkToDelete = _bookmarks[index];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Bookmark'),
        content: Text(
            'Are you sure you want to delete "${bookmarkToDelete.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _progressService.removeBookmark(
                bookmarkToDelete.episodeId,
                bookmarkToDelete.position,
              );
              await _loadBookmarks(); // Reload bookmarks
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodeDetails() {
    // Use datePublished field if available, otherwise fallback to other date fields
    final releaseDate = widget.episode['datePublished'] ??
        widget.episode['publishedAt'] ??
        widget.episode['releaseDate'] ??
        'Unknown Date';
    final duration = widget.episode['duration'] ?? 'Unknown Duration';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Divider line - Made more visible
          Container(
            height: 2, // Increased from 1 to 2
            color: AppTheme.lightTheme.colorScheme.outline
                .withOpacity(0.6), // Increased opacity from 0.3 to 0.6
          ),

          SizedBox(height: 24),

          // Date and duration row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDate(releaseDate),
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                _formatDuration(duration),
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),

          SizedBox(height: 24),

          // Episode description - HTML formatted with clickable links
          _formatHtmlText(
              widget.episode['description'] ?? 'No description available.'),
        ],
      ),
    );
  }

  // Function to format HTML text with clickable links
  Widget _formatHtmlText(String htmlText) {
    // First, replace HTML entities
    String processedText = htmlText
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
        style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
          color: AppTheme.lightTheme.colorScheme.onSurface,
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
          style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurface,
            height: 1.5,
          ),
        ));
      }

      // Add the clickable URL
      final url = match.group(0) ?? '';
      spans.add(TextSpan(
        text: url,
        style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
          color: AppTheme.lightTheme.colorScheme.primary,
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
        style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
          color: AppTheme.lightTheme.colorScheme.onSurface,
          height: 1.5,
        ),
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  // Function to launch URLs
  void _launchUrl(String url) async {
    if (url.isNotEmpty) {
      try {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Could not open link: $url'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invalid URL: $url'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _formatDate(dynamic date) {
    if (date is int) {
      // Handle Unix timestamp (seconds since epoch)
      final parsedDate = DateTime.fromMillisecondsSinceEpoch(date * 1000);
      return '${_getMonthName(parsedDate.month)} ${parsedDate.day}, ${parsedDate.year}';
    } else if (date is String) {
      // Check if it's a Unix timestamp string
      final timestamp = int.tryParse(date);
      if (timestamp != null) {
        final parsedDate =
            DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
        return '${_getMonthName(parsedDate.month)} ${parsedDate.day}, ${parsedDate.year}';
      }
      // Try parsing as regular date string
      try {
        final parsedDate = DateTime.parse(date);
        return '${_getMonthName(parsedDate.month)} ${parsedDate.day}, ${parsedDate.year}';
      } catch (e) {
        return date;
      }
    } else if (date is DateTime) {
      return '${_getMonthName(date.month)} ${date.day}, ${date.year}';
    }
    return date.toString();
  }

  String _formatBookmarkDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return _formatDate(date);
    }
  }

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

  String _formatDuration(dynamic duration) {
    if (duration is int) {
      final minutes = duration ~/ 60;
      final seconds = duration % 60;
      if (minutes > 0) {
        return '${minutes}m ${seconds}s';
      }
      return '${seconds}s';
    } else if (duration is String) {
      return duration;
    }
    return duration.toString();
  }

  void _navigateToPodcastDetail() {
    try {
      // First try to go back to the previous screen (same as back arrow)
      // This will take the user back to where they came from (likely podcast detail screen)
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('Error navigating back: $e');
      // Fallback: try to navigate to podcast detail screen directly
      try {
        final podcastData = widget.episode['podcast'];

        if (podcastData != null && podcastData is Map<String, dynamic>) {
          Navigator.pushNamed(
            context,
            '/podcast-detail-screen',
            arguments: podcastData,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Unable to navigate: Podcast information not available'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (fallbackError) {
        debugPrint('Error with fallback navigation: $fallbackError');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Error navigating to podcast: ${fallbackError.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Action button methods
  void _onDownloadTap() async {
    if (_isDownloading) return;

    // If already downloaded, show a message
    if (_isDownloaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.download_done, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                  'Episode already downloaded (${_downloadedFileSize.isNotEmpty ? _downloadedFileSize : 'Unknown size'})'),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _isDownloading = true;
    });

    try {
      final episodeId = widget.episode['id']?.toString();
      final episodeTitle = widget.episode['title'] ?? 'Unknown Episode';
      final audioUrl =
          widget.episode['audioUrl'] ?? widget.episode['enclosureUrl'];

      if (episodeId == null || audioUrl == null || audioUrl.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to download: Episode data incomplete'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await _downloadManager.downloadEpisodeWithValidation(
        episodeId: episodeId,
        episodeTitle: episodeTitle,
        audioUrl: audioUrl,
        context: context,
        onDownloadComplete: () async {
          if (mounted) {
            // Refresh download status and get file size
            final episodeId = widget.episode['id']?.toString();
            bool isDownloaded = false;
            String downloadedFileSize = '';
            if (episodeId != null) {
              isDownloaded =
                  await _downloadManager.isEpisodeDownloaded(episodeId);
              if (isDownloaded) {
                downloadedFileSize = await _getDownloadedFileSize(episodeId);
              }
            }

            setState(() {
              _isDownloading = false;
              _isDownloaded = isDownloaded;
              _downloadedFileSize = downloadedFileSize;
              _episodeFileSize =
                  ''; // Clear episode file size since it's now downloaded
            });
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.download_done, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text('$episodeTitle downloaded successfully'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        },
        onDownloadError: () {
          if (mounted) {
            setState(() {
              _isDownloading = false;
            });
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text('Download failed for $episodeTitle'),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onUpNextTap() {
    final playerProvider =
        Provider.of<PodcastPlayerProvider>(context, listen: false);
    final episodeModel = Episode.fromJson(widget.episode);

    if (_isInQueue) {
      // Remove from queue - find the episode index in the queue
      final queueIndex = playerProvider.episodeQueue.indexWhere(
        (episode) => episode.id == episodeModel.id,
      );
      if (queueIndex != -1) {
        playerProvider.removeFromQueue(queueIndex);
        if (mounted) {
          setState(() {
            _isInQueue = false;
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Episode removed from queue'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } else {
      // Add to queue
      playerProvider.addToQueue(episodeModel);
      if (mounted) {
        setState(() {
          _isInQueue = true;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Episode added to queue'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _onMarkPlayedTap() async {
    try {
      final episodeId = widget.episode['id']?.toString();
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

      await _progressService.markCompleted(episodeId);

      if (mounted) {
        setState(() {
          _isMarkedAsPlayed = true;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('$episodeTitle marked as played'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error marking as played: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onArchiveTap() async {
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

    if (_isArchived) {
      // Unarchive
      _confirmUnarchive(episodeId, episodeTitle);
    } else {
      // Archive
      _confirmArchive(episodeId, episodeTitle);
    }
  }

  void _confirmArchive(int episodeId, String episodeTitle) {
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
              _executeArchive(episodeId, episodeTitle, true);
            },
            child: const Text('Archive'),
          ),
        ],
      ),
    );
  }

  void _confirmUnarchive(int episodeId, String episodeTitle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unarchive Episode'),
        content: Text('Are you sure you want to unarchive "$episodeTitle"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _executeArchive(episodeId, episodeTitle, false);
            },
            child: const Text('Unarchive'),
          ),
        ],
      ),
    );
  }

  void _executeArchive(int episodeId, String episodeTitle, bool archive) async {
    try {
      final episodeIdStr = episodeId.toString();

      // Debug: Log episode data
      debugPrint('=== ARCHIVE DEBUG ===');
      debugPrint('Episode ID: $episodeId');
      debugPrint('Episode Title: $episodeTitle');
      debugPrint('Archive action: $archive');
      debugPrint('Episode data: ${widget.episode}');
      debugPrint('Episode data keys: ${widget.episode.keys.toList()}');

      if (archive) {
        // Archive episode
        debugPrint('Attempting to archive episode...');
        final result =
            await _archiveService.archiveEpisodeFromData(widget.episode);

        debugPrint('Archive result: $result');

        if (result['success'] == true) {
          if (mounted) {
            setState(() {
              _isArchived = true;
            });
          }

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
        } else {
          debugPrint('Archive failed: ${result['message']}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(result['message'] ?? 'Failed to archive episode'),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        // Unarchive episode
        debugPrint('Attempting to unarchive episode...');
        final result = await _archiveService.unarchiveEpisode(episodeIdStr);

        debugPrint('Unarchive result: $result');

        if (result['success'] == true) {
          if (mounted) {
            setState(() {
              _isArchived = false;
            });
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.unarchive, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text('$episodeTitle unarchived successfully'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          debugPrint('Unarchive failed: ${result['message']}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(result['message'] ?? 'Failed to unarchive episode'),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Archive error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                  'Error ${archive ? 'archiving' : 'unarchiving'} episode: $e'),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _playEpisode(
      BuildContext context, PodcastPlayerProvider playerProvider) {
    debugPrint('🎯 === EPISODE DETAIL MODAL _playEpisode START ===');
    // Debug: Log the episode data to see what's available
    debugPrint('=== PLAYING EPISODE ===');
    debugPrint('Episode data: ${widget.episode}');
    debugPrint('Episode keys: ${widget.episode.keys.toList()}');
    debugPrint('Audio URL fields:');
    debugPrint('  - enclosureUrl: ${widget.episode['enclosureUrl']}');
    debugPrint('  - audioUrl: ${widget.episode['audioUrl']}');
    debugPrint('  - url: ${widget.episode['url']}');
    debugPrint('  - mp3: ${widget.episode['mp3']}');
    debugPrint('  - m4a: ${widget.episode['m4a']}');

    try {
      // Convert episode map to Episode model
      final episodeModel = Episode.fromJson(widget.episode);
      debugPrint('Converted Episode model: ${episodeModel.toJson()}');
      debugPrint('Episode audioUrl: ${episodeModel.audioUrl}');

      debugPrint('🎯 About to call setEpisodeQueue...');
      // Set episode queue and current episode FIRST
      final episodeModels =
          widget.episodes.map((e) => Episode.fromJson(e)).toList();
      debugPrint('🎯 Episode models created: ${episodeModels.length} episodes');
      debugPrint('🎯 Episode index: ${widget.episodeIndex}');

      // Extract podcast ID and podcast data from episode data
      final podcastId = widget.episode['podcast']?['id']?.toString() ??
          widget.episodes.first['podcast']?['id']?.toString();

      // Get podcast data for setting current podcast information
      final podcastData =
          widget.episode['podcast'] ?? widget.episodes.first['podcast'] ?? {};

      playerProvider.setEpisodeQueue(episodeModels,
          startIndex: widget.episodeIndex, podcastId: podcastId);

      // Set current podcast data (same as podcast detail screen)
      playerProvider.setCurrentPodcastData(podcastData);
      debugPrint(
          '🎯 setEpisodeQueue and setCurrentPodcastData called successfully');

      // Ensure the current episode is set
      if (playerProvider.currentEpisode == null) {
        debugPrint('ERROR: Current episode not set after setEpisodeQueue');
        return;
      }

      debugPrint(
          'Current episode set: ${playerProvider.currentEpisode?.title}');

      debugPrint('🎯 About to call loadAndPlayEpisode...');
      // Start playing the episode
      playerProvider.loadAndPlayEpisode(episodeModel,
          clearQueue: false, context: context);
      debugPrint('🎯 loadAndPlayEpisode called successfully');

      debugPrint(
          '🎯 EpisodeDetailModal: Episode started playing, showing mini-player');
      debugPrint(
          '🎯 EpisodeDetailModal: Current episode: ${playerProvider.currentEpisode?.title}');
      debugPrint(
          '🎯 EpisodeDetailModal: Is playing: ${playerProvider.isPlaying}');

      // Set the correct mini-player positioning for the current screen
      // Check if we're on a screen without bottom navigation (like podcast detail)
      if (mounted) {
        final currentRoute = ModalRoute.of(context);
        if (currentRoute != null) {
          final routeName = currentRoute.settings.name;
          debugPrint('🎯 EpisodeDetailModal: Current route: $routeName');

          // Screens without bottom navigation
          final screensWithoutNav = [
            '/podcast-detail-screen',
            '/podcast-player',
            // Add other screens without bottom navigation here
          ];

          // Note: Mini-player positioning cache has been removed.
          // The mini-player now always auto-detects positioning for optimal performance.
          debugPrint(
              '🎯 EpisodeDetailModal: Mini-player will auto-detect positioning for $routeName');
        }
      }

      // Prepare episode data with podcast information for mini-player (same as podcast detail screen)
      final episodeWithPodcastInfo =
          episodeModel.toMapWithPodcastData(podcastData);
      final episodesWithPodcastInfo = episodeModels
          .map((e) => e.toMapWithPodcastData(podcastData))
          .toList();

      // Show the mini-player BEFORE closing the modal to ensure proper context
      // This ensures the mini-player appears with correct positioning and podcast data
      playerProvider.showFloatingMiniPlayer(
        context,
        episodeWithPodcastInfo,
        episodesWithPodcastInfo,
        widget.episodeIndex,
      );

      // Now close the episode detail modal
      if (mounted) {
        Navigator.of(context).pop();
      }
      debugPrint('🎯 === EPISODE DETAIL MODAL _playEpisode COMPLETED ===');
    } catch (e) {
      debugPrint('ERROR playing episode: $e');
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error playing episode: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Share episode using social sharing service (same as full-screen player)
  void _shareEpisode() async {
    try {
      final episodeTitle = widget.episode['title'] ?? 'Unknown Episode';
      final episodeDescription = widget.episode['description'] ?? '';
      final podcastTitle = widget.episode['podcastName'] ??
          widget.episode['podcast']?['title'] ??
          widget.episode['podcastTitle'] ??
          'Unknown Podcast';
      final audioUrl = widget.episode['audioUrl'] ?? '';

      await SocialSharingService().shareEpisode(
        episodeTitle: episodeTitle,
        podcastTitle: podcastTitle,
        episodeDescription: episodeDescription,
        episodeUrl: audioUrl.isNotEmpty ? audioUrl : null,
        customMessage: 'Check out this amazing episode!',
      );

      // Show success feedback (same as full-screen player)
      if (mounted) {
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
      }
    } catch (e) {
      debugPrint('Error sharing episode: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing episode: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Construct podcast data from episode data when podcast object is missing
  Map<String, dynamic> _constructPodcastDataFromEpisode(
      Map<String, dynamic> episodeData) {
    try {
      debugPrint('=== CONSTRUCTING PODCAST DATA FROM EPISODE ===');
      debugPrint('Episode data keys: ${episodeData.keys.toList()}');
      debugPrint('Episode coverImage: ${episodeData['coverImage']}');
      debugPrint('Episode image: ${episodeData['image']}');
      debugPrint('Episode feedImage: ${episodeData['feedImage']}');
      debugPrint('Episode feed_image: ${episodeData['feed_image']}');
      debugPrint('Episode artwork: ${episodeData['artwork']}');

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

      debugPrint('Constructed podcast ID: $podcastId');
      debugPrint('Constructed podcast title: $podcastTitle');
      debugPrint('Constructed podcast author: $podcastAuthor');
      debugPrint('Constructed podcast image: $podcastImage');

      // Only construct if we have at least some basic information
      if (podcastId != null ||
          podcastTitle != null ||
          podcastImage.isNotEmpty) {
        final constructedData = {
          'id': podcastId,
          'title': podcastTitle,
          'author': podcastAuthor,
          'creator': podcastAuthor,
          'coverImage': podcastImage,
          'cover_image': podcastImage,
          'image': podcastImage,
          'artwork': podcastImage,
        };
        debugPrint('Successfully constructed podcast data: $constructedData');
        debugPrint('=== END CONSTRUCTING PODCAST DATA ===');
        return constructedData;
      } else {
        debugPrint('No sufficient data to construct podcast object');
        debugPrint('=== END CONSTRUCTING PODCAST DATA ===');
      }
    } catch (e) {
      debugPrint('Error constructing podcast data from episode: $e');
      debugPrint('=== END CONSTRUCTING PODCAST DATA ===');
    }

    return {};
  }

  /// Get the file size of a downloaded episode in a human-readable format
  Future<String> _getDownloadedFileSize(String episodeId) async {
    try {
      final downloadInfo = _downloadManager.getDownloadInfo(episodeId);
      if (downloadInfo != null && downloadInfo.fileSize > 0) {
        return _formatFileSize(downloadInfo.fileSize);
      }

      // Fallback: try to get file size directly from file system
      final filePath =
          await _downloadManager.offlinePlayer.getOfflineEpisodePath(episodeId);
      if (filePath != null) {
        final file = File(filePath);
        if (await file.exists()) {
          final fileSize = await file.length();
          return _formatFileSize(fileSize);
        }
      }
    } catch (e) {
      debugPrint('Error getting downloaded file size: $e');
    }

    return '';
  }

  /// Format file size in bytes to human-readable format
  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '${bytes}B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)}KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
    }
  }

  /// Get episode file size from audio URL using HTTP HEAD request
  Future<String> _getEpisodeFileSizeFromUrl() async {
    try {
      final audioUrl =
          widget.episode['audioUrl'] ?? widget.episode['enclosureUrl'];
      if (audioUrl == null || audioUrl.isEmpty) {
        return '';
      }

      // Use Dio to make a HEAD request to get content-length
      final dio = Dio();
      final response = await dio
          .head(
            audioUrl,
            options: Options(
              headers: {
                'User-Agent': 'Pelevo Podcast App',
              },
              followRedirects: true,
              maxRedirects: 5,
            ),
          )
          .timeout(const Duration(seconds: 10));

      final contentLength = response.headers.value('content-length');
      if (contentLength != null && contentLength.isNotEmpty) {
        final fileSize = int.tryParse(contentLength);
        if (fileSize != null && fileSize > 0) {
          return _formatFileSize(fileSize);
        }
      }
    } catch (e) {
      debugPrint('Error getting episode file size from URL: $e');
    }

    return '';
  }
}
