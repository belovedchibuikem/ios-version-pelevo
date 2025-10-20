import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:provider/provider.dart';
import '../../../providers/history_provider.dart';
import 'package:dio/dio.dart';

import '../../../core/app_export.dart';
import '../../../core/navigation_service.dart';
import '../../../models/download.dart';
import '../../../models/subscription.dart';
import '../../../models/play_history.dart';
import '../../../models/playlist.dart';
import '../../../services/library_api_service.dart';
import '../../../services/subscription_helper.dart';
import '../../../services/download_manager.dart';
import '../../../widgets/episode_list_item.dart';
import '../../../widgets/episode_detail_modal.dart';
import '../../../data/models/episode.dart' as episode_model;
import '../../../providers/podcast_player_provider.dart';
import '../../../core/utils/mini_player_positioning.dart';

// lib/presentation/library_screen/widgets/tab_content_widget.dart

class TabContentWidget extends StatefulWidget {
  final String tabType;
  final List<Map<String, dynamic>> items;
  final String searchQuery;
  final VoidCallback? onRefresh;

  const TabContentWidget({
    super.key,
    required this.tabType,
    required this.items,
    required this.searchQuery,
    this.onRefresh,
  });

  @override
  State<TabContentWidget> createState() => _TabContentWidgetState();
}

class _TabContentWidgetState extends State<TabContentWidget> {
  final LibraryApiService _apiService = LibraryApiService();
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;

  int _currentPage = 1;
  bool _hasMore = true;

  List<Download> _downloads = [];
  List<Subscription> _subscriptions = [];
  List<PlayHistory> _playHistory = [];
  List<Playlist> _playlists = [];

  final DownloadManager _downloadManager = DownloadManager();

  @override
  void initState() {
    super.initState();
    _loadData();
    _initializeDownloadManager();

    // Load history data if this is the history tab
    if (widget.tabType == 'history') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final historyProvider =
            Provider.of<HistoryProvider>(context, listen: false);
        if (historyProvider.playHistory.isEmpty) {
          historyProvider.loadPlayHistory(refresh: true);
        }
      });
    }
  }

  Future<void> _initializeDownloadManager() async {
    await _downloadManager.initialize();
  }

  @override
  void dispose() {
    // Cancel any ongoing operations if needed
    super.dispose();
  }

  Future<void> _loadData({bool loadMore = false}) async {
    if (_isLoading || _isLoadingMore) return;

    if (loadMore) {
      if (mounted) {
        setState(() => _isLoadingMore = true);
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _error = null;
          _currentPage = 1;
          _hasMore = true;
        });
      }
    }

    try {
      switch (widget.tabType) {
        case 'downloads':
          {
            final response = await _apiService.getDownloads(
              page: loadMore ? _currentPage : 1,
              context: context,
              onRetry: () => _loadData(loadMore: loadMore),
            );
            final newItems = response['data'] as List<Download>;
            if (loadMore) {
              _downloads.addAll(newItems);
            } else {
              _downloads = newItems;
            }
            _hasMore = response['hasMore'] as bool? ?? false;
            break;
          }
        case 'subscriptions':
          {
            final response = await _apiService.getSubscriptions(
              page: loadMore ? _currentPage : 1,
              context: context,
              onRetry: () => _loadData(loadMore: loadMore),
            );
            final newItems = response['data'] as List<Subscription>;
            if (loadMore) {
              _subscriptions.addAll(newItems);
            } else {
              _subscriptions = newItems;
            }
            _hasMore = response['hasMore'] as bool? ?? false;
            break;
          }
        case 'history':
          {
            // History is handled separately in build method using HistoryProvider
            // No need to load data here to avoid setState during build
            break;
          }
        case 'playlists':
          {
            final response = await _apiService.getPlaylists(
                page: loadMore ? _currentPage : 1);
            final newItems = response['data'] as List<Playlist>;
            if (loadMore) {
              _playlists.addAll(newItems);
            } else {
              _playlists = newItems;
            }
            _hasMore = response['hasMore'] as bool? ?? false;
            break;
          }
      }
      if (mounted) {
        if (loadMore) {
          setState(() => _isLoadingMore = false);
        } else {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // For history tab, use HistoryProvider directly
    if (widget.tabType == 'history') {
      return Consumer<HistoryProvider>(
        builder: (context, historyProvider, child) {
          if (historyProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (historyProvider.error != null) {
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
                    'Error loading history',
                    style: AppTheme.lightTheme.textTheme.titleMedium,
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    historyProvider.error!,
                    style: AppTheme.lightTheme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 2.h),
                  ElevatedButton(
                    onPressed: () =>
                        historyProvider.loadPlayHistory(refresh: true),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final items = widget.searchQuery.isEmpty
              ? historyProvider.filteredHistory
              : historyProvider.filteredHistory.where((history) {
                  final query = widget.searchQuery.toLowerCase();
                  return history.episode?.title
                              .toLowerCase()
                              .contains(query) ==
                          true ||
                      history.episode?.podcast?.author
                              ?.toLowerCase()
                              .contains(query) ==
                          true ||
                      history.podcastindexEpisodeId
                              .toLowerCase()
                              .contains(query) ==
                          true;
                }).toList();

          if (items.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: () async {
              widget.onRefresh?.call();
              await historyProvider.loadPlayHistory(refresh: true);
            },
            child: ListView.separated(
              padding: EdgeInsets.only(
                left: 4.w,
                right: 4.w,
                top: 4.w,
                bottom: MiniPlayerPositioning.bottomPaddingForScrollables(),
              ),
              itemCount: items.length + (historyProvider.hasMore ? 1 : 0),
              separatorBuilder: (context, index) => SizedBox(height: 2.h),
              itemBuilder: (context, index) {
                if (index == items.length && historyProvider.hasMore) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: historyProvider.isLoadingMore
                          ? CircularProgressIndicator()
                          : ElevatedButton(
                              onPressed: () =>
                                  historyProvider.loadMoreHistory(),
                              child: const Text('Load More'),
                            ),
                    ),
                  );
                }

                final history = items[index];
                return _buildHistoryItem(context, history);
              },
            ),
          );
        },
      );
    }

    // For other tabs, use existing logic
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
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
              'Error loading data',
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
              onPressed: () => _loadData(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final allItems = _getItems();
    final items = widget.searchQuery.isEmpty
        ? allItems
        : allItems.where((item) {
            final query = widget.searchQuery.toLowerCase();
            switch (widget.tabType) {
              case 'downloads':
                final d = item as Download;
                return d.episode?.title.toLowerCase().contains(query) == true ||
                    d.episode?.podcast?.author?.toLowerCase().contains(query) ==
                        true;
              case 'subscriptions':
                final s = item as Subscription;
                return s.podcast?.title.toLowerCase().contains(query) == true ||
                    s.podcast?.author?.toLowerCase().contains(query) == true;
              case 'playlists':
                final p = item as Playlist;
                return p.name.toLowerCase().contains(query) ||
                    (p.description?.toLowerCase().contains(query) ?? false);
              default:
                return false;
            }
          }).toList();

    if (items.isEmpty) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: () async {
        widget.onRefresh?.call();
        await _loadData();
      },
      child: ListView.separated(
        padding: EdgeInsets.only(
          left: 4.w,
          right: 4.w,
          top: 4.w,
          bottom: MiniPlayerPositioning.bottomPaddingForScrollables(),
        ),
        itemCount: items.length + (_hasMore ? 1 : 0),
        separatorBuilder: (context, index) => SizedBox(height: 2.h),
        itemBuilder: (context, index) {
          if (index == items.length && _hasMore) {
            // Load More Button
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: _isLoadingMore
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: () {
                          if (mounted) {
                            setState(() => _currentPage++);
                            _loadData(loadMore: true);
                          }
                        },
                        child: const Text('Load More'),
                      ),
              ),
            );
          }

          final item = items[index];

          switch (widget.tabType) {
            case 'downloads':
              return _buildDownloadedItem(context, item as Download);
            case 'subscriptions':
              return _buildSubscriptionItem(context, item as Subscription);
            case 'history':
              return _buildHistoryItem(context, item as PlayHistory);
            case 'playlists':
              return _buildPlaylistItem(context, item as Playlist);
            default:
              return const SizedBox.shrink();
          }
        },
      ),
    );
  }

  List<dynamic> _getItems() {
    switch (widget.tabType) {
      case 'downloads':
        return _downloads;
      case 'subscriptions':
        return _subscriptions;
      case 'history':
        // History is handled separately in build method
        return [];
      case 'playlists':
        return _playlists;
      default:
        return [];
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    String title;
    String description;
    String actionText;

    switch (widget.tabType) {
      case 'downloads':
        title = 'No Downloads Yet';
        description =
            'Download episodes to listen offline and save on data usage';
        actionText = 'Browse Podcasts';
        break;
      case 'subscriptions':
        title = 'No Subscriptions';
        description =
            'Subscribe to podcasts to get notified about new episodes';
        actionText = 'Discover Podcasts';
        break;
      case 'history':
        title = 'No Listening History';
        description = 'Your recently played episodes will appear here';
        actionText = 'Start Listening';
        break;
      case 'playlists':
        title = 'No Playlists';
        description = 'Create playlists to organize your favorite episodes';
        actionText = 'Create Playlist';
        break;
      default:
        title = 'No Content';
        description = 'Nothing to show here yet';
        actionText = 'Explore';
    }

    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: _getEmptyStateIcon(),
              size: 80,
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: 3.h),
            Text(
              title,
              style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            Text(
              description,
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
              child: Text(actionText),
            ),
          ],
        ),
      ),
    );
  }

  String _getEmptyStateIcon() {
    switch (widget.tabType) {
      case 'downloads':
        return 'download';
      case 'subscriptions':
        return 'rss_feed';
      case 'history':
        return 'history';
      case 'playlists':
        return 'playlist_play';
      default:
        return 'library_books';
    }
  }

  Widget _buildDownloadedItem(BuildContext context, Download download) {
    final episode = download.episode;
    if (episode == null) return const SizedBox.shrink();

    // Create podcast data from episode's podcast information
    final podcastData = episode.podcast != null
        ? {
            'id': episode.podcast!.id?.toString(),
            'feedId': episode.podcast!.id?.toString(),
            'title': episode.podcast!.title ?? 'Unknown Podcast',
            'author': episode.podcast!.author ?? 'Unknown Author',
            'creator': episode.podcast!.author ?? 'Unknown Author',
            'description': episode.podcast!.description ?? '',
            'coverImage': episode.podcast!.image ?? episode.image ?? '',
            'cover_image': episode.podcast!.image ?? episode.image ?? '',
            'image': episode.podcast!.image ?? episode.image ?? '',
            'artwork': episode.podcast!.image ?? episode.image ?? '',
          }
        : null;

    // Convert to our enhanced Episode model with progress tracking
    final enhancedEpisode = episode_model.Episode(
      id: episode.id,
      title: episode.title,
      description: episode.description ?? '',
      audioUrl:
          download.filePath, // Use local file path for downloaded episodes
      coverImage: episode.podcast?.image ?? episode.image ?? '',
      duration: episode.durationFormatted,
      releaseDate: episode.pubDate ?? DateTime.now(),
      podcastName: episode.podcast?.title ?? 'Unknown Podcast',
      creator: episode.podcast?.author ?? 'Unknown Author',
      isDownloaded: true,
      podcastId: episode.podcast?.id?.toString(),
      // Progress tracking fields - get from playback history if available
      lastPlayedPosition: null, // Will be populated from playback history
      totalDuration: episode.duration != null
          ? episode.duration! * 1000
          : null, // Convert to milliseconds
      lastPlayedAt: null, // Will be populated from playback history
      isCompleted: false, // Will be populated from playback history
    );

    return Consumer<PodcastPlayerProvider>(
      builder: (context, playerProvider, child) {
        // Check if this episode is currently playing
        final isCurrentlyPlaying =
            playerProvider.currentEpisode?.id == download.episodeId;
        final isPlaying = isCurrentlyPlaying && playerProvider.isPlaying;

        // If currently playing, use real-time data
        if (isCurrentlyPlaying) {
          final realTimeData =
              enhancedEpisode.toMapWithPodcastData(podcastData);
          realTimeData.addAll({
            'hasTranscript': false,
            'lastPlayedPosition': playerProvider.position.inMilliseconds,
            'totalDuration': playerProvider.duration.inMilliseconds,
            'lastPlayedAt': DateTime.now().toIso8601String(),
            'isCompleted': playerProvider.progressPercentage >= 1.0,
            'isCurrentlyPlaying': true,
            'isPlaying': isPlaying,
          });

          return EpisodeListItem(
            episode: realTimeData,
            onPlay: () =>
                _playDownloadedEpisode(context, download, enhancedEpisode),
            onLongPress: () => _showDownloadOptions(context, download),
            onShowDetails: () => _showDownloadDetails(
                context, download, enhancedEpisode, podcastData),
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
              // Show a minimal loading state that doesn't block the UI
              final loadingEpisodeData =
                  enhancedEpisode.toMapWithPodcastData(podcastData);
              loadingEpisodeData.addAll({
                'hasTranscript': false,
                'lastPlayedPosition': enhancedEpisode.lastPlayedPosition,
                'totalDuration': enhancedEpisode.totalDuration,
                'lastPlayedAt': enhancedEpisode.lastPlayedAt?.toIso8601String(),
                'isCompleted': enhancedEpisode.isCompleted,
                'isCurrentlyPlaying': false,
                'isPlaying': false,
              });
              return EpisodeListItem(
                episode: loadingEpisodeData,
                onPlay: () =>
                    _playDownloadedEpisode(context, download, enhancedEpisode),
                onLongPress: () => _showDownloadOptions(context, download),
                onShowDetails: () => _showDownloadDetails(
                    context, download, enhancedEpisode, podcastData),
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
              // Show episode with history progress data on error
              final errorEpisodeData =
                  enhancedEpisode.toMapWithPodcastData(podcastData);
              errorEpisodeData.addAll({
                'hasTranscript': false,
                'lastPlayedPosition': enhancedEpisode.lastPlayedPosition,
                'totalDuration': enhancedEpisode.totalDuration,
                'lastPlayedAt': enhancedEpisode.lastPlayedAt?.toIso8601String(),
                'isCompleted': enhancedEpisode.isCompleted,
                'isCurrentlyPlaying': false,
                'isPlaying': false,
              });
              return EpisodeListItem(
                episode: errorEpisodeData,
                onPlay: () =>
                    _playDownloadedEpisode(context, download, enhancedEpisode),
                onLongPress: () => _showDownloadOptions(context, download),
                onShowDetails: () => _showDownloadDetails(
                    context, download, enhancedEpisode, podcastData),
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

            // Use the most recent progress data, fallback to history data if storage data is null
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

            final finalEpisodeData =
                enhancedEpisode.toMapWithPodcastData(podcastData);
            finalEpisodeData.addAll({
              'hasTranscript': false,
              'lastPlayedPosition': finalProgressData['lastPlayedPosition'],
              'totalDuration': finalProgressData['totalDuration'],
              'lastPlayedAt': finalProgressData['lastPlayedAt'],
              'isCompleted': finalProgressData['isCompleted'],
              'isCurrentlyPlaying': false,
              'isPlaying': false,
            });
            return EpisodeListItem(
              episode: finalEpisodeData,
              onPlay: () =>
                  _playDownloadedEpisode(context, download, enhancedEpisode),
              onLongPress: () => _showDownloadOptions(context, download),
              onShowDetails: () => _showDownloadDetails(
                  context, download, enhancedEpisode, podcastData),
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

  Widget _buildSubscriptionItem(
      BuildContext context, Subscription subscription) {
    final podcast = subscription.podcast;
    if (podcast == null) return const SizedBox.shrink();

    return Card(
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/podcast-detail-screen',
            arguments: podcast.toJson(),
          );
        },
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppTheme.lightTheme.colorScheme.surfaceContainer,
                ),
                child: CustomImageWidget(
                  imageUrl: podcast.image ?? '',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      podcast.title,
                      style: AppTheme.lightTheme.textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      podcast.author ?? 'Unknown',
                      style: AppTheme.lightTheme.textTheme.bodySmall,
                    ),
                    SizedBox(height: 1.h),
                    Row(
                      children: [
                        if (podcast.episodeCount != null &&
                            podcast.episodeCount! > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.lightTheme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${podcast.episodeCount} episodes',
                              style: AppTheme.lightTheme.textTheme.bodySmall
                                  ?.copyWith(
                                color:
                                    AppTheme.lightTheme.colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        const Spacer(),
                        Switch(
                          value: subscription.isActive,
                          onChanged: (value) async {
                            if (value) {
                              await _subscribeToPodcast(podcast.id.toString());
                            } else {
                              await _unsubscribeFromPodcast(
                                  podcast.id.toString());
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, PlayHistory history) {
    final episode = history.episode;
    if (episode == null) {
      // Show a placeholder for episodes that don't exist in the database
      return Card(
        child: ListTile(
          leading: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: AppTheme.lightTheme.colorScheme.surfaceContainer,
            ),
            child: Icon(
              Icons.audio_file,
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
          title: Text(
            'Episode ${history.podcastindexEpisodeId}',
            style: AppTheme.lightTheme.textTheme.titleMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Episode not found in database',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.error,
                ),
              ),
              SizedBox(height: 1.h),
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'access_time',
                    size: 16,
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    history.timeAgo,
                    style: AppTheme.lightTheme.textTheme.bodySmall,
                  ),
                  const Spacer(),
                  Text(
                    '${history.formattedProgressTime} / ${history.formattedTotalTime}',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
            onSelected: (value) =>
                _handleHistoryAction(context, history, value),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'remove',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20),
                    SizedBox(width: 8),
                    Text('Remove from History'),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Create podcast data from episode's podcast information
    debugPrint('🔍 _buildHistoryItem Debug:');
    debugPrint('  - Episode: ${episode.title}');
    debugPrint('  - Episode podcast: ${episode.podcast?.title}');
    debugPrint('  - Episode podcast image: ${episode.podcast?.image}');
    debugPrint('  - Episode image: ${episode.image}');

    // Create podcast data - handle case where episode.podcast is null
    final podcastData = episode.podcast != null
        ? {
            'id': episode.podcast!.id?.toString(),
            'feedId': episode.podcast!.id?.toString(),
            'title': episode.podcast!.title ?? 'Unknown Podcast',
            'author': episode.podcast!.author ?? 'Unknown Author',
            'creator': episode.podcast!.author ?? 'Unknown Author',
            'description': episode.podcast!.description ?? '',
            'coverImage': episode.podcast!.image ?? episode.image ?? '',
            'cover_image': episode.podcast!.image ?? episode.image ?? '',
            'image': episode.podcast!.image ?? episode.image ?? '',
            'artwork': episode.podcast!.image ?? episode.image ?? '',
          }
        : {
            // Fallback podcast data when episode.podcast is null
            'id': null,
            'feedId': null,
            'title': 'Unknown Podcast',
            'author': 'Unknown Author',
            'creator': 'Unknown Author',
            'description': '',
            'coverImage': episode.image ?? '',
            'cover_image': episode.image ?? '',
            'image': episode.image ?? '',
            'artwork': episode.image ?? '',
          };

    debugPrint('  - Created podcastData: $podcastData');

    // Convert to our enhanced Episode model with progress tracking
    final enhancedEpisode = episode_model.Episode(
      id: episode.id,
      title: episode.title,
      description: episode.description ?? '',
      audioUrl: episode.enclosureUrl, // Use enclosureUrl from the model
      coverImage: episode.podcast?.image ?? episode.image ?? '',
      duration:
          episode.duration?.toString() ?? '0', // Convert duration to string
      releaseDate: episode.datePublished != null
          ? DateTime.fromMillisecondsSinceEpoch(episode.datePublished! * 1000)
          : DateTime.now(),
      podcastName: episode.podcast?.title ?? 'Unknown Podcast',
      creator: episode.podcast?.author ?? 'Unknown Author',
      isDownloaded: false,
      podcastId: episode.podcast?.id?.toString(),
      // Progress tracking fields from history
      lastPlayedPosition:
          history.progressSeconds * 1000, // Convert seconds to milliseconds
      totalDuration: episode.duration != null
          ? episode.duration! * 1000
          : null, // Convert to milliseconds
      lastPlayedAt: history.lastPlayedAt,
      isCompleted: history.progressPercentage >= 100,
    );

    return Consumer<PodcastPlayerProvider>(
      builder: (context, playerProvider, child) {
        // Check if this episode is currently playing
        final isCurrentlyPlaying =
            playerProvider.currentEpisode?.id == history.episode?.id;
        final isPlaying = isCurrentlyPlaying && playerProvider.isPlaying;

        // If currently playing, use real-time data
        if (isCurrentlyPlaying) {
          final realTimeData =
              enhancedEpisode.toMapWithPodcastData(podcastData);
          realTimeData.addAll({
            'hasTranscript': false,
            'lastPlayedPosition': playerProvider.position.inMilliseconds,
            'totalDuration': playerProvider.duration.inMilliseconds,
            'lastPlayedAt': DateTime.now().toIso8601String(),
            'isCompleted': playerProvider.progressPercentage >= 1.0,
            'isCurrentlyPlaying': true,
            'isPlaying': isPlaying,
          });

          return EpisodeListItem(
            episode: realTimeData,
            onPlay: () =>
                _playHistoryEpisode(context, history, enhancedEpisode),
            onLongPress: () => _showHistoryOptions(context, history),
            onShowDetails: () => _showHistoryDetails(
                context, history, enhancedEpisode, podcastData),
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
              // Show a minimal loading state that doesn't block the UI
              final loadingEpisodeData =
                  enhancedEpisode.toMapWithPodcastData(podcastData);
              loadingEpisodeData.addAll({
                'hasTranscript': false,
                'lastPlayedPosition': enhancedEpisode.lastPlayedPosition,
                'totalDuration': enhancedEpisode.totalDuration,
                'lastPlayedAt': enhancedEpisode.lastPlayedAt?.toIso8601String(),
                'isCompleted': enhancedEpisode.isCompleted,
                'isCurrentlyPlaying': false,
                'isPlaying': false,
              });
              return EpisodeListItem(
                episode: loadingEpisodeData,
                onPlay: () =>
                    _playHistoryEpisode(context, history, enhancedEpisode),
                onLongPress: () => _showHistoryOptions(context, history),
                onShowDetails: () => _showHistoryDetails(
                    context, history, enhancedEpisode, podcastData),
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
              // Show episode with history progress data on error
              final errorEpisodeData =
                  enhancedEpisode.toMapWithPodcastData(podcastData);
              errorEpisodeData.addAll({
                'hasTranscript': false,
                'lastPlayedPosition': enhancedEpisode.lastPlayedPosition,
                'totalDuration': enhancedEpisode.totalDuration,
                'lastPlayedAt': enhancedEpisode.lastPlayedAt?.toIso8601String(),
                'isCompleted': enhancedEpisode.isCompleted,
                'isCurrentlyPlaying': false,
                'isPlaying': false,
              });
              return EpisodeListItem(
                episode: errorEpisodeData,
                onPlay: () =>
                    _playHistoryEpisode(context, history, enhancedEpisode),
                onLongPress: () => _showHistoryOptions(context, history),
                onShowDetails: () => _showHistoryDetails(
                    context, history, enhancedEpisode, podcastData),
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

            // Use the most recent progress data, fallback to history data if storage data is null
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

            final finalEpisodeData =
                enhancedEpisode.toMapWithPodcastData(podcastData);
            finalEpisodeData.addAll({
              'hasTranscript': false,
              'lastPlayedPosition': finalProgressData['lastPlayedPosition'],
              'totalDuration': finalProgressData['totalDuration'],
              'lastPlayedAt': finalProgressData['lastPlayedAt'],
              'isCompleted': finalProgressData['isCompleted'],
              'isCurrentlyPlaying': false,
              'isPlaying': false,
            });
            return EpisodeListItem(
              episode: finalEpisodeData,
              onPlay: () =>
                  _playHistoryEpisode(context, history, enhancedEpisode),
              onLongPress: () => _showHistoryOptions(context, history),
              onShowDetails: () => _showHistoryDetails(
                  context, history, enhancedEpisode, podcastData),
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'played':
        return Colors.blue;
      case 'paused':
        return Colors.orange;
      case 'abandoned':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'played':
        return Icons.play_circle;
      case 'paused':
        return Icons.pause_circle;
      case 'abandoned':
        return Icons.stop_circle;
      default:
        return Icons.circle;
    }
  }

  void _handleHistoryAction(
      BuildContext context, PlayHistory history, String action) {
    switch (action) {
      case 'play':
        if (history.episode != null) {
          // Create podcast object from episode's podcast data
          final podcastData = {
            'id': history.episode!.podcast?.id ?? history.episode!.id,
            'title': history.episode!.podcast?.title ?? 'Unknown Podcast',
            'author': history.episode!.podcast?.author ?? 'Unknown Author',
            'description': history.episode!.podcast?.description ?? '',
            'image':
                history.episode!.podcast?.image ?? history.episode!.image ?? '',
          };

          // Create properly formatted episode data
          final episodeData = {
            'id': history.episode!.id,
            'title': history.episode!.title,
            'description': history.episode!.description ?? '',
            'duration': history.episode!.duration ?? 0,
            'image': history.episode!.image ?? '',
            'audioUrl': history.episode!.enclosureUrl ?? '',
            'datePublished': history.episode!.datePublished,
            'podcast': history.episode!.podcast?.toJson(),
          };

          // Get the player provider and start immediate playback
          final playerProvider =
              Provider.of<PodcastPlayerProvider>(context, listen: false);

          // Convert episode to Episode model
          final episodeModel = episode_model.Episode(
            id: history.episode!.id,
            title: history.episode!.title,
            description: history.episode!.description ?? '',
            audioUrl: history.episode!.enclosureUrl ?? '',
            coverImage: history.episode!.image ?? '',
            duration: history.episode!.duration?.toString() ?? '0',
            releaseDate: history.episode!.datePublished != null
                ? DateTime.fromMillisecondsSinceEpoch(
                    history.episode!.datePublished! * 1000)
                : DateTime.now(),
            podcastName: history.episode!.podcast?.title ?? 'Unknown Podcast',
            creator: history.episode!.podcast?.author ?? 'Unknown Author',
            isDownloaded: false,
          );

          // Set episode queue for auto-play functionality
          playerProvider.setEpisodeQueue([episodeModel], startIndex: 0);

          // Load and play the episode directly
          playerProvider.loadAndPlayEpisode(episodeModel, clearQueue: false);

          // Show the floating mini-player
          playerProvider.showFloatingMiniPlayer(
            context,
            episodeData,
            [episodeData],
            0,
          );

          debugPrint('✅ History episode playback started successfully');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cannot play episode - episode data not found'),
              backgroundColor: AppTheme.lightTheme.colorScheme.error,
            ),
          );
        }
        break;
      case 'complete':
        // Mark as completed
        Provider.of<HistoryProvider>(context, listen: false)
            .markEpisodeCompleted(history.id);
        break;
      case 'remove':
        // Show confirmation dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Remove from History'),
            content: Text(
                'Are you sure you want to remove this episode from your history?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Provider.of<HistoryProvider>(context, listen: false)
                      .deletePlayHistory(history.id);
                  Navigator.pop(context);
                },
                child: Text('Remove'),
              ),
            ],
          ),
        );
        break;
    }
  }

  Widget _buildPlaylistItem(BuildContext context, Playlist playlist) {
    return Card(
      child: ListTile(
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: AppTheme.lightTheme.colorScheme.primary.withOpacity(0.1),
          ),
          child: Icon(
            Icons.playlist_play,
            color: AppTheme.lightTheme.colorScheme.primary,
            size: 30,
          ),
        ),
        title: Text(
          playlist.name,
          style: AppTheme.lightTheme.textTheme.titleMedium,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (playlist.description != null)
              Text(
                playlist.description!,
                style: AppTheme.lightTheme.textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            SizedBox(height: 1.h),
            Row(
              children: [
                CustomIconWidget(
                  iconName: 'music_note',
                  size: 16,
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: 1.w),
                Text(
                  '${playlist.itemsCount} episodes',
                  style: AppTheme.lightTheme.textTheme.bodySmall,
                ),
                const Spacer(),
                Text(
                  'Created ${_formatDate(playlist.createdAt)}',
                  style: AppTheme.lightTheme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          icon: CustomIconWidget(
            iconName: 'more_vert',
            size: 24,
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete),
                  SizedBox(width: 8),
                  Text('Delete'),
                ],
              ),
            ),
          ],
          onSelected: (value) async {
            if (value == 'edit') {
              // TODO: Implement edit playlist
            } else if (value == 'delete') {
              await _deletePlaylist(playlist.id);
            }
          },
        ),
        onTap: () {
          Navigator.pushNamed(context, '/playlist-detail',
              arguments: playlist.toJson());
        },
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

  // API Methods
  Future<void> _removeDownload(int downloadId) async {
    try {
      await _downloadManager.deleteDownloadedEpisode(
          downloadId.toString(), context);
      if (mounted) {
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing download: $e')),
        );
      }
    }
  }

  Future<void> _subscribeToPodcast(String podcastId) async {
    await handleSubscribeAction(
      context: context,
      podcastId: podcastId,
      isCurrentlySubscribed: false,
      onStateChanged: (bool subscribed) async {
        if (subscribed && mounted) {
          await _loadData();
        }
      },
    );
  }

  Future<void> _unsubscribeFromPodcast(String podcastId) async {
    await handleSubscribeAction(
      context: context,
      podcastId: podcastId,
      isCurrentlySubscribed: true,
      onStateChanged: (bool subscribed) async {
        if (!subscribed && mounted) {
          await _loadData();
        }
      },
    );
  }

  Future<void> _deletePlaylist(int playlistId) async {
    try {
      await _apiService.deletePlaylist(playlistId);
      if (mounted) {
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting playlist: $e')),
        );
      }
    }
  }

  /// Play downloaded episode with new player system
  void _playDownloadedEpisode(BuildContext context, Download download,
      episode_model.Episode enhancedEpisode) {
    try {
      // Create properly formatted episode data for the new player system
      final episodeData = {
        'id': enhancedEpisode.id,
        'title': enhancedEpisode.title,
        'description': enhancedEpisode.description,
        'duration': enhancedEpisode.duration,
        'image': enhancedEpisode.coverImage,
        'audioUrl':
            download.filePath, // Use local file path for downloaded episodes
        'enclosureUrl':
            download.filePath, // Also set enclosureUrl for compatibility
        'datePublished': enhancedEpisode.releaseDate.toIso8601String(),
        'podcast': {
          'id': download.episode?.podcast?.id ?? download.episode?.id,
          'title': download.episode?.podcast?.title ?? 'Unknown Podcast',
          'author': download.episode?.podcast?.author ?? 'Unknown Author',
          'description': download.episode?.podcast?.description ?? '',
          'image':
              download.episode?.podcast?.image ?? download.episode?.image ?? '',
        },
        'isDownloaded': true,
        'filePath': download.filePath,
      };

      // Get the player provider and start immediate playback
      final playerProvider =
          Provider.of<PodcastPlayerProvider>(context, listen: false);

      // Convert episode to Episode model
      final episodeModel = episode_model.Episode(
        id: enhancedEpisode.id,
        title: enhancedEpisode.title,
        description: enhancedEpisode.description,
        audioUrl: download.filePath, // Use local file path
        coverImage: enhancedEpisode.coverImage,
        duration: enhancedEpisode.duration,
        releaseDate: enhancedEpisode.releaseDate,
        podcastName: enhancedEpisode.podcastName,
        creator: enhancedEpisode.creator,
        isDownloaded: true,
      );

      // Set episode queue for auto-play functionality
      playerProvider.setEpisodeQueue([episodeModel], startIndex: 0);

      // Load and play the episode directly
      playerProvider.loadAndPlayEpisode(episodeModel, clearQueue: false);

      // Show the floating mini-player
      playerProvider.showFloatingMiniPlayer(
        context,
        episodeData,
        [episodeData],
        0,
      );

      debugPrint('✅ Downloaded episode playback started successfully');
    } catch (e) {
      debugPrint('Error playing downloaded episode: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error playing episode: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Show download options menu
  void _showDownloadOptions(BuildContext context, Download download) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.play_arrow),
              title: Text('Play'),
              onTap: () {
                Navigator.pop(context);
                // Create enhanced episode and play
                final episode = download.episode;
                if (episode != null) {
                  final enhancedEpisode = episode_model.Episode(
                    id: episode.id,
                    title: episode.title,
                    description: episode.description ?? '',
                    audioUrl: download.filePath,
                    coverImage: episode.image ?? '',
                    duration: episode.durationFormatted,
                    releaseDate: episode.pubDate ?? DateTime.now(),
                    podcastName: episode.podcast?.title ?? 'Unknown Podcast',
                    creator: episode.podcast?.author ?? 'Unknown Author',
                    isDownloaded: true,
                  );
                  _playDownloadedEpisode(context, download, enhancedEpisode);
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.delete),
              title: Text('Delete Download'),
              onTap: () async {
                Navigator.pop(context);
                await _removeDownload(download.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Show download details using EpisodeDetailModal
  void _showDownloadDetails(BuildContext context, Download download,
      episode_model.Episode enhancedEpisode,
      [Map<String, dynamic>? podcastData]) {
    // Convert episode to map format for EpisodeDetailModal using the enhanced method
    final episodeMap = enhancedEpisode.toMapWithPodcastData(podcastData);
    episodeMap.addAll({
      'hasTranscript': false,
      'lastPlayedPosition': enhancedEpisode.lastPlayedPosition,
      'totalDuration': enhancedEpisode.totalDuration,
      'lastPlayedAt': enhancedEpisode.lastPlayedAt?.toIso8601String(),
      'isCompleted': enhancedEpisode.isCompleted,
      'isCurrentlyPlaying': false,
      'isPlaying': false,
    });

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

  /// Play history episode with new player system
  void _playHistoryEpisode(BuildContext context, PlayHistory history,
      episode_model.Episode enhancedEpisode) {
    try {
      if (history.episode != null) {
        // Create podcast object from episode's podcast data
        final podcastData = {
          'id': history.episode!.podcast?.id ?? history.episode!.id,
          'title': history.episode!.podcast?.title ?? 'Unknown Podcast',
          'author': history.episode!.podcast?.author ?? 'Unknown Author',
          'description': history.episode!.podcast?.description ?? '',
          'image':
              history.episode!.podcast?.image ?? history.episode!.image ?? '',
        };

        // Create properly formatted episode data
        final episodeData = {
          'id': enhancedEpisode.id,
          'title': enhancedEpisode.title,
          'description': enhancedEpisode.description,
          'duration': enhancedEpisode.duration,
          'image': enhancedEpisode.coverImage,
          'audioUrl': enhancedEpisode.audioUrl,
          'datePublished': enhancedEpisode.releaseDate.toIso8601String(),
          'podcast': podcastData,
          'playHistory': history,
        };

        // Get the player provider and start immediate playback
        final playerProvider =
            Provider.of<PodcastPlayerProvider>(context, listen: false);

        // Convert episode to Episode model
        final episodeModel = episode_model.Episode(
          id: enhancedEpisode.id,
          title: enhancedEpisode.title,
          description: enhancedEpisode.description,
          audioUrl: enhancedEpisode.audioUrl,
          coverImage: enhancedEpisode.coverImage,
          duration: enhancedEpisode.duration,
          releaseDate: enhancedEpisode.releaseDate,
          podcastName: enhancedEpisode.podcastName,
          creator: enhancedEpisode.creator,
          isDownloaded: false,
        );

        // Set episode queue for auto-play functionality
        playerProvider.setEpisodeQueue([episodeModel], startIndex: 0);

        // Load and play the episode directly
        playerProvider.loadAndPlayEpisode(episodeModel, clearQueue: false);

        // Show the floating mini-player
        playerProvider.showFloatingMiniPlayer(
          context,
          episodeData,
          [episodeData],
          0,
        );

        debugPrint('✅ History episode playback started successfully');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot play episode - episode data not found'),
            backgroundColor: AppTheme.lightTheme.colorScheme.error,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error playing history episode: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error playing episode: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Show history options menu
  void _showHistoryOptions(BuildContext context, PlayHistory history) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.play_arrow),
              title: Text('Play'),
              onTap: () {
                Navigator.pop(context);
                if (history.episode != null) {
                  final enhancedEpisode = episode_model.Episode(
                    id: history.episode!.id,
                    title: history.episode!.title,
                    description: history.episode!.description ?? '',
                    audioUrl: history.episode!
                        .enclosureUrl, // Use enclosureUrl from the model
                    coverImage: history.episode!.image ?? '',
                    duration: history.episode!.duration?.toString() ??
                        '0', // Convert duration to string
                    releaseDate: history.episode!.datePublished != null
                        ? DateTime.fromMillisecondsSinceEpoch(
                            history.episode!.datePublished! * 1000)
                        : DateTime.now(),
                    podcastName:
                        history.episode!.podcast?.title ?? 'Unknown Podcast',
                    creator:
                        history.episode!.podcast?.author ?? 'Unknown Author',
                    isDownloaded: false,
                  );
                  _playHistoryEpisode(context, history, enhancedEpisode);
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.delete),
              title: Text('Remove from History'),
              onTap: () async {
                Navigator.pop(context);
                // Handle remove action
                Provider.of<HistoryProvider>(context, listen: false)
                    .deletePlayHistory(history.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Show history details using EpisodeDetailModal
  void _showHistoryDetails(BuildContext context, PlayHistory history,
      episode_model.Episode enhancedEpisode,
      [Map<String, dynamic>? podcastData]) {
    // Debug logging to check podcast data
    debugPrint('🔍 _showHistoryDetails Debug:');
    debugPrint('  - History episode: ${history.episode?.title}');
    debugPrint(
        '  - History episode podcast: ${history.episode?.podcast?.title}');
    debugPrint('  - PodcastData passed: $podcastData');
    debugPrint(
        '  - Enhanced episode podcastName: ${enhancedEpisode.podcastName}');

    // Convert episode to map format for EpisodeDetailModal using the enhanced method
    final episodeMap = enhancedEpisode.toMapWithPodcastData(podcastData);

    // Debug the final episode map
    debugPrint('  - Final episodeMap podcast: ${episodeMap['podcast']}');
    debugPrint('  - Final episodeMap coverImage: ${episodeMap['coverImage']}');
    episodeMap.addAll({
      'hasTranscript': false,
      'lastPlayedPosition': enhancedEpisode.lastPlayedPosition,
      'totalDuration': enhancedEpisode.totalDuration,
      'lastPlayedAt': enhancedEpisode.lastPlayedAt?.toIso8601String(),
      'isCompleted': enhancedEpisode.isCompleted,
      'isCurrentlyPlaying': false,
      'isPlaying': false,
    });

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

  /// Enhance episode data with real-time progress from player provider
  Future<Map<String, dynamic>> _enhanceEpisodeWithProgress(
    Map<String, dynamic> episodeData,
    BuildContext context,
  ) async {
    try {
      final playerProvider =
          Provider.of<PodcastPlayerProvider>(context, listen: false);

      // Check if this episode is currently playing
      final isCurrentlyPlaying =
          playerProvider.currentEpisode?.id == episodeData['id'];
      final isPlaying = isCurrentlyPlaying && playerProvider.isPlaying;

      // Get progress data from player provider if available
      int? lastPlayedPosition;
      int? totalDuration;
      DateTime? lastPlayedAt;
      bool isCompleted = false;

      if (isCurrentlyPlaying) {
        // Use real-time data from player
        lastPlayedPosition = playerProvider.position.inMilliseconds;
        totalDuration = playerProvider.duration.inMilliseconds;
        lastPlayedAt = DateTime.now();
        isCompleted = playerProvider.progressPercentage >= 1.0;
      } else {
        // Load saved progress from local storage
        final episodeId = episodeData['id'];
        if (episodeId != null) {
          final progress = await playerProvider.loadEpisodeProgress(episodeId);
          if (progress != null) {
            lastPlayedPosition = progress['position'];
            totalDuration = progress['duration'];
            lastPlayedAt = progress['lastPlayed'] != null
                ? DateTime.fromMillisecondsSinceEpoch(progress['lastPlayed'])
                : null;
            isCompleted = progress['completed'] ?? false;
          } else {
            // Fallback to episode data if no progress found
            lastPlayedPosition = episodeData['lastPlayedPosition'];
            totalDuration = episodeData['totalDuration'];
            lastPlayedAt = episodeData['lastPlayedAt'] != null
                ? DateTime.tryParse(episodeData['lastPlayedAt'])
                : null;
            isCompleted = episodeData['isCompleted'] ?? false;
          }
        } else {
          // Fallback to episode data if no episode ID
          lastPlayedPosition = episodeData['lastPlayedPosition'];
          totalDuration = episodeData['totalDuration'];
          lastPlayedAt = episodeData['lastPlayedAt'] != null
              ? DateTime.tryParse(episodeData['lastPlayedAt'])
              : null;
          isCompleted = episodeData['isCompleted'] ?? false;
        }
      }

      return {
        ...episodeData,
        'lastPlayedPosition': lastPlayedPosition,
        'totalDuration': totalDuration,
        'lastPlayedAt': lastPlayedAt?.toIso8601String(),
        'isCompleted': isCompleted,
        'isCurrentlyPlaying': isCurrentlyPlaying,
        'isPlaying': isPlaying,
      };
    } catch (e) {
      debugPrint('Error enhancing episode with progress: $e');
      return episodeData;
    }
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
}
